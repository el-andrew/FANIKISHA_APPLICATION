import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import type { BusinessEntry } from '../generated/prisma/client.js';
import { businessToday, toDateOnly } from '../common/dates.js';
import { toAmount } from '../common/money.js';
import { isUniqueViolation } from '../common/prisma-errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  CreateEntryInput,
  ListEntriesQuery,
  SummaryQuery,
  UpdateEntryInput,
} from './business.schemas.js';
import { toEntryDto, type EntryDto } from './entry.mapper.js';

/** The longest period a summary covers. */
export const MAX_SUMMARY_DAYS = 366;
const DAY_MS = 86_400_000;

export interface DayTotals {
  date: string;
  sales: number;
  expenses: number;
}

export interface BusinessSummary {
  from: string;
  to: string;
  sales: number;
  expenses: number;
  /** Sales minus expenses; negative for a loss. */
  profit: number;
  /** Every day in the period, oldest first, including days with nothing. */
  days: DayTotals[];
  /** Expenses by category, largest first; uncategorised as `null`. */
  expenseCategories: { category: string | null; amount: number }[];
}

@Injectable()
export class BusinessService {
  constructor(private readonly prisma: PrismaService) {}

  /** Records a sale or expense. A retried request returns the original. */
  async create(
    userId: string,
    idempotencyKey: string,
    input: CreateEntryInput,
  ): Promise<EntryDto> {
    const occurredOn = input.occurredOn ?? businessToday();
    assertNotFuture(occurredOn);
    const existing = await this.findByKey(userId, idempotencyKey);
    if (existing) return replay(existing, input);
    try {
      const entry = await this.prisma.businessEntry.create({
        data: {
          userId,
          type: input.type,
          amount: BigInt(input.amount),
          category: input.category,
          note: input.note,
          occurredOn,
          idempotencyKey,
        },
      });
      return toEntryDto(entry);
    } catch (error) {
      if (isUniqueViolation(error)) {
        const winner = await this.findByKey(userId, idempotencyKey);
        if (winner) return replay(winner, input);
      }
      throw error;
    }
  }

  async list(
    userId: string,
    query: ListEntriesQuery,
  ): Promise<{ items: EntryDto[]; nextCursor: string | null }> {
    const entries = await this.prisma.businessEntry.findMany({
      where: {
        userId,
        type: query.type,
        occurredOn: { gte: query.from, lte: query.to },
      },
      orderBy: [{ occurredOn: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }],
      take: query.limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
    });
    const hasMore = entries.length > query.limit;
    const page = hasMore ? entries.slice(0, query.limit) : entries;
    return {
      items: page.map(toEntryDto),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  async get(userId: string, id: string): Promise<EntryDto> {
    return toEntryDto(await this.findOwned(userId, id));
  }

  async update(
    userId: string,
    id: string,
    input: UpdateEntryInput,
  ): Promise<EntryDto> {
    await this.findOwned(userId, id);
    if (input.occurredOn) assertNotFuture(input.occurredOn);
    const entry = await this.prisma.businessEntry.update({
      where: { id },
      data: {
        type: input.type,
        amount: input.amount === undefined ? undefined : BigInt(input.amount),
        category: input.category,
        note: input.note,
        occurredOn: input.occurredOn,
      },
    });
    return toEntryDto(entry);
  }

  async remove(userId: string, id: string): Promise<void> {
    await this.findOwned(userId, id);
    await this.prisma.businessEntry.delete({ where: { id } });
  }

  async summary(userId: string, query: SummaryQuery): Promise<BusinessSummary> {
    const { from, to } = query;
    const length = Math.round((to.getTime() - from.getTime()) / DAY_MS) + 1;
    if (length < 1) {
      throw new BadRequestException('"from" must not be after "to"');
    }
    if (length > MAX_SUMMARY_DAYS) {
      throw new BadRequestException(
        `A summary covers at most ${MAX_SUMMARY_DAYS} days`,
      );
    }

    const where = { userId, occurredOn: { gte: from, lte: to } };
    const [byDay, byCategory] = await Promise.all([
      this.prisma.businessEntry.groupBy({
        by: ['occurredOn', 'type'],
        where,
        _sum: { amount: true },
      }),
      this.prisma.businessEntry.groupBy({
        by: ['category'],
        where: { ...where, type: 'EXPENSE' },
        _sum: { amount: true },
      }),
    ]);

    const days: DayTotals[] = Array.from({ length }, (_, i) => ({
      date: toDateOnly(new Date(from.getTime() + i * DAY_MS)),
      sales: 0,
      expenses: 0,
    }));
    const dayIndex = new Map(days.map((d, i) => [d.date, i]));
    for (const row of byDay) {
      const day = days[dayIndex.get(toDateOnly(row.occurredOn))!];
      const amount = toAmount(row._sum.amount ?? 0n);
      if (row.type === 'SALE') day.sales += amount;
      else day.expenses += amount;
    }

    const sales = days.reduce((s, d) => s + d.sales, 0);
    const expenses = days.reduce((s, d) => s + d.expenses, 0);
    return {
      from: toDateOnly(from),
      to: toDateOnly(to),
      sales,
      expenses,
      profit: sales - expenses,
      days,
      expenseCategories: byCategory
        .map((row) => ({
          category: row.category,
          amount: toAmount(row._sum.amount ?? 0n),
        }))
        .sort((a, b) => b.amount - a.amount),
    };
  }

  private findByKey(userId: string, idempotencyKey: string) {
    return this.prisma.businessEntry.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey } },
    });
  }

  /** Other users' entries are reported as not found. */
  private async findOwned(userId: string, id: string): Promise<BusinessEntry> {
    const entry = await this.prisma.businessEntry.findFirst({
      where: { id, userId },
    });
    if (!entry) throw new NotFoundException('Entry not found');
    return entry;
  }
}

function assertNotFuture(day: Date): void {
  if (day > businessToday()) {
    throw new BadRequestException('An entry cannot be in the future');
  }
}

/** A retried request must match the original. */
function replay(existing: BusinessEntry, input: CreateEntryInput): EntryDto {
  if (
    existing.type !== input.type ||
    toAmount(existing.amount) !== input.amount
  ) {
    throw new UnprocessableEntityException(
      'This Idempotency-Key was already used for a different entry',
    );
  }
  return toEntryDto(existing);
}
