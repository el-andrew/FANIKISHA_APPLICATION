import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import {
  Prisma,
  type Goal,
  type Movement,
  type MovementKind,
} from '../generated/prisma/client.js';
import { toAmount } from '../common/money.js';
import { isUniqueViolation } from '../common/prisma-errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  depositInclude,
  toDepositDto,
  type DepositDto,
} from '../savings/deposit.mapper.js';
import type {
  ActivityQuery,
  TransferInput,
  WithdrawalInput,
} from './movements.schemas.js';

/** A goal, or general savings when `goalId` is null. */
export interface Place {
  goalId: string | null;
  goalName: string | null;
}

export interface MovementDto {
  id: string;
  kind: MovementKind;
  amount: number;
  from: Place;
  /** Transfers only. */
  to: Place | null;
  note: string | null;
  createdAt: string;
}

export type ActivityItem = ({ kind: 'DEPOSIT' } & DepositDto) | MovementDto;

const movementInclude = {
  fromGoal: { select: { name: true } },
  toGoal: { select: { name: true } },
} as const;

type MovementRow = Movement & {
  fromGoal: { name: string } | null;
  toGoal: { name: string } | null;
};

function toMovementDto(m: MovementRow): MovementDto {
  return {
    id: m.id,
    kind: m.kind,
    amount: toAmount(m.amount),
    from: { goalId: m.fromGoalId, goalName: m.fromGoal?.name ?? null },
    to:
      m.kind === 'TRANSFER'
        ? { goalId: m.toGoalId, goalName: m.toGoal?.name ?? null }
        : null,
    note: m.note,
    createdAt: m.createdAt.toISOString(),
  };
}

/**
 * Money leaving savings, or moving between goals and general savings. Each
 * runs in one transaction that locks the account and the goals involved
 * (the same order as deposits, so they cannot deadlock), and never takes
 * more than the source holds.
 */
@Injectable()
export class MovementsService {
  constructor(private readonly prisma: PrismaService) {}

  withdraw(userId: string, key: string, input: WithdrawalInput) {
    return this.move(userId, key, 'WITHDRAWAL', input.from, null, input);
  }

  transfer(userId: string, key: string, input: TransferInput) {
    return this.move(userId, key, 'TRANSFER', input.from, input.to, input);
  }

  /** Deposits, withdrawals and transfers, newest first. */
  async activity(
    userId: string,
    query: ActivityQuery,
  ): Promise<{ items: ActivityItem[]; nextCursor: string | null }> {
    const after = query.cursor ? decodeCursor(query.cursor) : null;
    // Times are compared as the database's own text, so no time zone
    // conversion can shift the cursor.
    const rows = await this.prisma.$queryRaw<
      { id: string; kind: string; created: string }[]
    >`
      SELECT id, kind, created FROM (
        SELECT id::text, 'DEPOSIT' AS kind, created_at::text AS created, created_at
          FROM deposits WHERE user_id = ${userId}::uuid
        UNION ALL
        SELECT id::text, kind::text, created_at::text, created_at
          FROM movements WHERE user_id = ${userId}::uuid
      ) feed
      WHERE ${
        after
          ? Prisma.sql`(created_at, id) < (${after.created}::timestamp, ${after.id})`
          : Prisma.sql`TRUE`
      }
      ORDER BY created_at DESC, id DESC
      LIMIT ${query.limit + 1}`;

    const hasMore = rows.length > query.limit;
    const page = hasMore ? rows.slice(0, query.limit) : rows;
    const depositIds = page
      .filter((r) => r.kind === 'DEPOSIT')
      .map((r) => r.id);
    const movementIds = page
      .filter((r) => r.kind !== 'DEPOSIT')
      .map((r) => r.id);
    const [deposits, movements] = await Promise.all([
      this.prisma.deposit.findMany({
        where: { id: { in: depositIds }, userId },
        include: depositInclude,
      }),
      this.prisma.movement.findMany({
        where: { id: { in: movementIds }, userId },
        include: movementInclude,
      }),
    ]);
    const depositById = new Map(deposits.map((d) => [d.id, d]));
    const movementById = new Map(movements.map((m) => [m.id, m]));

    const last = page[page.length - 1];
    return {
      items: page.map((row) =>
        row.kind === 'DEPOSIT'
          ? {
              kind: 'DEPOSIT' as const,
              ...toDepositDto(depositById.get(row.id)!),
            }
          : toMovementDto(movementById.get(row.id)!),
      ),
      nextCursor: hasMore ? encodeCursor(last.created, last.id) : null,
    };
  }

  private async move(
    userId: string,
    key: string,
    kind: MovementKind,
    from: string | null,
    to: string | null,
    input: { amount: number; note?: string },
  ): Promise<MovementDto> {
    const existing = await this.findByKey(userId, key);
    if (existing) return replay(existing, kind, from, to, input.amount);
    try {
      return await this.prisma.$transaction(async (tx) => {
        await tx.$queryRaw`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`;
        const goalIds = [from, to].filter((id): id is string => id !== null);
        if (goalIds.length > 0) {
          await tx.$queryRaw`SELECT id FROM goals WHERE id IN (${Prisma.join(
            goalIds.map((id) => Prisma.sql`${id}::uuid`),
          )}) AND user_id = ${userId}::uuid FOR UPDATE`;
        }
        const goals = await tx.goal.findMany({
          where: { id: { in: goalIds }, userId },
        });
        const goal = (id: string) => {
          const found = goals.find((g) => g.id === id);
          if (!found) throw new NotFoundException('Goal not found');
          return found;
        };
        const user = await tx.user.findUniqueOrThrow({
          where: { id: userId },
          select: { generalSavings: true },
        });

        const amount = BigInt(input.amount);
        const source: Goal | null = from ? goal(from) : null;
        const available = source ? source.savedAmount : user.generalSavings;
        if (available < amount) {
          throw new HttpException(
            {
              statusCode: 400,
              message: `Only ${toAmount(available)} TZS is available there`,
              code: 'insufficient_funds',
              available: toAmount(available),
            },
            HttpStatus.BAD_REQUEST,
          );
        }
        const target: Goal | null = kind === 'TRANSFER' && to ? goal(to) : null;
        if (target?.status === 'ARCHIVED') {
          throw new BadRequestException(
            'Money cannot be moved into an archived goal',
          );
        }

        // Take the money from its source…
        if (source) {
          await tx.goal.update({
            where: { id: source.id },
            data: { savedAmount: source.savedAmount - amount },
          });
        } else {
          await tx.user.update({
            where: { id: userId },
            data: { generalSavings: user.generalSavings - amount },
          });
        }
        // …and, for a transfer, put it in its destination.
        if (kind === 'TRANSFER') {
          if (target) {
            const savedAmount = target.savedAmount + amount;
            const completes =
              target.status === 'ACTIVE' && savedAmount >= target.targetAmount;
            await tx.goal.update({
              where: { id: target.id },
              data: {
                savedAmount,
                ...(completes
                  ? { status: 'COMPLETED', completedAt: new Date() }
                  : {}),
              },
            });
          } else {
            await tx.user.update({
              where: { id: userId },
              data: { generalSavings: { increment: amount } },
            });
          }
        }

        const movement = await tx.movement.create({
          data: {
            userId,
            kind,
            amount,
            fromGoalId: from,
            toGoalId: kind === 'TRANSFER' ? to : null,
            note: input.note,
            idempotencyKey: key,
          },
          include: movementInclude,
        });
        return toMovementDto(movement);
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        const winner = await this.findByKey(userId, key);
        if (winner) return replay(winner, kind, from, to, input.amount);
      }
      throw error;
    }
  }

  private findByKey(userId: string, idempotencyKey: string) {
    return this.prisma.movement.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey } },
      include: movementInclude,
    });
  }
}

function replay(
  existing: MovementRow,
  kind: MovementKind,
  from: string | null,
  to: string | null,
  amount: number,
): MovementDto {
  const same =
    existing.kind === kind &&
    existing.fromGoalId === from &&
    (kind === 'WITHDRAWAL' || existing.toGoalId === to) &&
    toAmount(existing.amount) === amount;
  if (!same) {
    throw new UnprocessableEntityException(
      'This Idempotency-Key was already used for a different request',
    );
  }
  return toMovementDto(existing);
}

function encodeCursor(created: string, id: string): string {
  return Buffer.from(`${created}|${id}`).toString('base64url');
}

function decodeCursor(cursor: string): { created: string; id: string } {
  const [created, id] = Buffer.from(cursor, 'base64url').toString().split('|');
  if (!created || !id || !/^[0-9a-f-]{36}$/.test(id)) {
    throw new BadRequestException('Invalid cursor');
  }
  return { created, id };
}
