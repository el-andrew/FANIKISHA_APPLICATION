import type { Goal, GoalStatus } from '../generated/prisma/client.js';
import { toDateOnly, businessToday } from '../common/dates.js';
import { toAmount } from '../common/money.js';
import { daysUntil } from '../savings/allocation.js';

export interface GoalDto {
  id: string;
  name: string;
  category: string | null;
  targetAmount: number;
  savedAmount: number;
  remainingAmount: number;
  /** 0 to 100, one decimal place. */
  progressPercent: number;
  priority: number;
  startDate: string;
  targetDate: string;
  daysLeft: number;
  /** Shillings per day needed from today to finish on time. */
  dailyTargetAmount: number;
  status: GoalStatus;
  completedAt: string | null;
  createdAt: string;
}

export function toGoalDto(goal: Goal, now: Date = new Date()): GoalDto {
  const target = toAmount(goal.targetAmount);
  const saved = toAmount(goal.savedAmount);
  // A completed goal stays complete even after its money is taken out:
  // reaching the target was the achievement.
  const completed = goal.status === 'COMPLETED';
  const remaining = completed ? 0 : Math.max(0, target - saved);
  const daysLeft = daysUntil(goal.targetDate, businessToday(now));
  return {
    id: goal.id,
    name: goal.name,
    category: goal.category,
    targetAmount: target,
    savedAmount: saved,
    remainingAmount: remaining,
    progressPercent: completed
      ? 100
      : Math.min(100, Math.floor((saved / target) * 1000) / 10),
    priority: goal.priority,
    startDate: toDateOnly(goal.startDate),
    targetDate: toDateOnly(goal.targetDate),
    daysLeft,
    dailyTargetAmount: Math.ceil(remaining / daysLeft),
    status: goal.status,
    completedAt: goal.completedAt?.toISOString() ?? null,
    createdAt: goal.createdAt.toISOString(),
  };
}
