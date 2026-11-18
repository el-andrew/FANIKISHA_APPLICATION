import { toAmount } from '../common/money.js';

export interface DepositDto {
  id: string;
  amount: number;
  /** The part no active goal needed: kept as general savings. */
  unallocatedAmount: number;
  note: string | null;
  createdAt: string;
  allocations: { goalId: string; goalName: string; amount: number }[];
}

export interface DepositWithAllocations {
  id: string;
  amount: bigint;
  unallocatedAmount: bigint;
  note: string | null;
  createdAt: Date;
  allocations: { goalId: string; amount: bigint; goal: { name: string } }[];
}

/** Prisma `include` that loads what `toDepositDto` needs. */
export const depositInclude = {
  allocations: {
    include: { goal: { select: { name: true } } },
    orderBy: { amount: 'desc' },
  },
} as const;

export function toDepositDto(deposit: DepositWithAllocations): DepositDto {
  return {
    id: deposit.id,
    amount: toAmount(deposit.amount),
    unallocatedAmount: toAmount(deposit.unallocatedAmount),
    note: deposit.note,
    createdAt: deposit.createdAt.toISOString(),
    allocations: deposit.allocations.map((a) => ({
      goalId: a.goalId,
      goalName: a.goal.name,
      amount: toAmount(a.amount),
    })),
  };
}
