import {
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { businessToday } from '../common/dates.js';
import { toAmount } from '../common/money.js';
import { isUniqueViolation } from '../common/prisma-errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { Goal } from '../generated/prisma/client.js';
import {
  allocateDeposit,
  daysUntil,
  type AllocationResult,
} from './allocation.js';
import {
  depositInclude,
  toDepositDto,
  type DepositDto,
} from './deposit.mapper.js';
import type {
  CreateDepositInput,
  ListDepositsQuery,
} from './savings.schemas.js';

export type DepositPreviewDto = Omit<DepositDto, 'id' | 'note' | 'createdAt'>;

export interface SavingsSummary {
  totalDeposited: number;
  /** Money saved that no goal needed. */
  unallocatedAmount: number;
  depositCount: number;
  activeGoals: number;
  completedGoals: number;
}

@Injectable()
export class SavingsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Records a deposit and splits it across the user's active goals, all in
   * one transaction. Repeating a request with the same idempotency key
   * returns the original deposit instead of saving the money twice.
   */
  async createDeposit(
    userId: string,
    idempotencyKey: string,
    input: CreateDepositInput,
  ): Promise<DepositDto> {
    const existing = await this.findByIdempotencyKey(userId, idempotencyKey);
    if (existing) return this.replay(existing, input);

    try {
      return await this.prisma.$transaction(async (tx) => {
        // Lock the user's active goals: concurrent deposits for the same user
        // run one after the other, so no increment is lost.
        await tx.$queryRaw`SELECT id FROM goals WHERE user_id = ${userId}::uuid AND status = 'ACTIVE' FOR UPDATE`;
        const goals = await tx.goal.findMany({
          where: { userId, status: 'ACTIVE' },
          orderBy: { createdAt: 'asc' },
        });

        const { allocations, unallocated } = planAllocation(
          input.amount,
          goals,
        );

        const deposit = await tx.deposit.create({
          data: {
            userId,
            amount: BigInt(input.amount),
            unallocatedAmount: BigInt(unallocated),
            note: input.note,
            idempotencyKey,
            allocations: {
              create: allocations.map((a) => ({
                goalId: a.goalId,
                amount: BigInt(a.amount),
              })),
            },
          },
          include: depositInclude,
        });

        const now = new Date();
        for (const allocation of allocations) {
          const goal = goals.find((g) => g.id === allocation.goalId)!;
          const savedAmount = goal.savedAmount + BigInt(allocation.amount);
          const completed = savedAmount >= goal.targetAmount;
          await tx.goal.update({
            where: { id: goal.id },
            data: {
              savedAmount,
              ...(completed ? { status: 'COMPLETED', completedAt: now } : {}),
            },
          });
        }

        return toDepositDto(deposit);
      });
    } catch (error) {
      // Two requests with the same key raced; the other one won.
      if (isUniqueViolation(error)) {
        const winner = await this.findByIdempotencyKey(userId, idempotencyKey);
        if (winner) return this.replay(winner, input);
      }
      throw error;
    }
  }

  /**
   * Shows how a deposit would be split right now, without saving anything.
   * The real split can differ if goals change before the deposit is made.
   */
  async previewDeposit(
    userId: string,
    amount: number,
  ): Promise<DepositPreviewDto> {
    const goals = await this.prisma.goal.findMany({
      where: { userId, status: 'ACTIVE' },
      orderBy: { createdAt: 'asc' },
    });
    const { allocations, unallocated } = planAllocation(amount, goals);
    return {
      amount,
      unallocatedAmount: unallocated,
      allocations: allocations.map((a) => ({
        goalId: a.goalId,
        goalName: goals.find((g) => g.id === a.goalId)!.name,
        amount: a.amount,
      })),
    };
  }

  async listDeposits(
    userId: string,
    query: ListDepositsQuery,
  ): Promise<{ items: DepositDto[]; nextCursor: string | null }> {
    const deposits = await this.prisma.deposit.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: query.limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      include: depositInclude,
    });
    const hasMore = deposits.length > query.limit;
    const page = hasMore ? deposits.slice(0, query.limit) : deposits;
    return {
      items: page.map(toDepositDto),
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  async getDeposit(userId: string, depositId: string): Promise<DepositDto> {
    const deposit = await this.prisma.deposit.findFirst({
      where: { id: depositId, userId },
      include: depositInclude,
    });
    if (!deposit) throw new NotFoundException('Deposit not found');
    return toDepositDto(deposit);
  }

  async getSummary(userId: string): Promise<SavingsSummary> {
    const [totals, goalCounts] = await Promise.all([
      this.prisma.deposit.aggregate({
        where: { userId },
        _sum: { amount: true, unallocatedAmount: true },
        _count: true,
      }),
      this.prisma.goal.groupBy({
        by: ['status'],
        where: { userId },
        _count: true,
      }),
    ]);
    const countOf = (status: string) =>
      goalCounts.find((g) => g.status === status)?._count ?? 0;
    return {
      totalDeposited: toAmount(totals._sum.amount ?? 0n),
      unallocatedAmount: toAmount(totals._sum.unallocatedAmount ?? 0n),
      depositCount: totals._count,
      activeGoals: countOf('ACTIVE'),
      completedGoals: countOf('COMPLETED'),
    };
  }

  private findByIdempotencyKey(userId: string, idempotencyKey: string) {
    return this.prisma.deposit.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey } },
      include: depositInclude,
    });
  }

  /** A retried request must match the original, or the key was reused by mistake. */
  private replay(
    existing: NonNullable<
      Awaited<ReturnType<SavingsService['findByIdempotencyKey']>>
    >,
    input: CreateDepositInput,
  ): DepositDto {
    if (
      toAmount(existing.amount) !== input.amount ||
      (existing.note ?? undefined) !== input.note
    ) {
      throw new UnprocessableEntityException(
        'This Idempotency-Key was already used for a different deposit',
      );
    }
    return toDepositDto(existing);
  }
}

/** Runs the allocation algorithm on a user's active goals. */
function planAllocation(amount: number, goals: Goal[]): AllocationResult {
  const today = businessToday();
  return allocateDeposit(
    amount,
    goals.map((goal) => ({
      id: goal.id,
      priority: goal.priority,
      remaining: Math.max(0, toAmount(goal.targetAmount - goal.savedAmount)),
      daysLeft: daysUntil(goal.targetDate, today),
    })),
  );
}
