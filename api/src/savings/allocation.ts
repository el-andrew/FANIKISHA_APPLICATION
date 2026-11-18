/**
 * Splits a deposit across a user's active savings goals.
 *
 * Each goal's share is proportional to `priority × urgency`, where urgency is
 * how many shillings per day the goal still needs to reach its target on time
 * (`remaining / daysLeft`). This is the same weighting as the original 2022
 * Fanikisha formula (priority weight × duration weight, normalised); the
 * constant factors in that formula cancel out once the shares are normalised.
 *
 * Unlike the original, this version:
 * - works in whole shillings, and the parts always add up to the deposit
 *   (largest-remainder rounding);
 * - never gives a goal more than it still needs. The excess is shared out
 *   among the remaining goals, and anything no goal needs is returned as
 *   `unallocated`;
 * - is a pure function, so it can be tested without a database.
 */

export interface AllocatableGoal {
  id: string;
  /** 1 (low) to 5 (high). */
  priority: number;
  /** Shillings still needed to reach the target. */
  remaining: number;
  /** Whole days until the target date, at least 1. */
  daysLeft: number;
}

export interface GoalAllocation {
  goalId: string;
  amount: number;
}

export interface AllocationResult {
  /** One entry per goal that received money, in the order goals were given. */
  allocations: GoalAllocation[];
  /** The part of the deposit no goal needed. */
  unallocated: number;
}

const MS_PER_DAY = 86_400_000;

/**
 * Whole days from `today` until `targetDate`, comparing calendar dates in UTC.
 * Overdue goals and goals due today count as 1 day, so they become the most
 * urgent rather than causing a division by zero.
 */
export function daysUntil(targetDate: Date, today: Date): number {
  const target = Date.UTC(
    targetDate.getUTCFullYear(),
    targetDate.getUTCMonth(),
    targetDate.getUTCDate(),
  );
  const start = Date.UTC(
    today.getUTCFullYear(),
    today.getUTCMonth(),
    today.getUTCDate(),
  );
  return Math.max(1, Math.round((target - start) / MS_PER_DAY));
}

export function allocateDeposit(
  amount: number,
  goals: readonly AllocatableGoal[],
): AllocationResult {
  assertPositiveInteger(amount, 'amount');
  for (const goal of goals) validateGoal(goal);

  const given = new Map<string, number>();
  let pool = amount;
  let open = goals.filter((goal) => goal.remaining > 0);

  while (pool > 0 && open.length > 0) {
    const weights = open.map(
      (goal) => goal.priority * (goal.remaining / goal.daysLeft),
    );
    const totalWeight = weights.reduce((sum, w) => sum + w, 0);
    const ideal = weights.map((w) => (pool * w) / totalWeight);

    // Goals whose fair share covers everything they still need are filled
    // completely; the rest of the pool is then shared among the others.
    const filled = open.filter((goal, i) => ideal[i] >= goal.remaining);
    if (filled.length > 0) {
      for (const goal of filled) {
        given.set(goal.id, goal.remaining);
        pool -= goal.remaining;
      }
      open = open.filter((goal) => !filled.includes(goal));
      continue;
    }

    // Every share is below what its goal needs: round down, then hand the
    // leftover shillings to the largest fractional parts (ties: higher
    // priority first, then the order the goals were given in). Because each
    // ideal share is strictly below an integer `remaining`, adding one
    // shilling never exceeds it.
    const shares = ideal.map(Math.floor);
    let leftover = pool - shares.reduce((sum, s) => sum + s, 0);
    const order = open
      .map((goal, i) => ({ i, fraction: ideal[i] - shares[i], goal }))
      .sort(
        (a, b) =>
          b.fraction - a.fraction ||
          b.goal.priority - a.goal.priority ||
          a.i - b.i,
      );
    for (const { i } of order) {
      if (leftover === 0) break;
      shares[i] += 1;
      leftover -= 1;
    }
    open.forEach((goal, i) => {
      if (shares[i] > 0) given.set(goal.id, shares[i]);
    });
    pool = 0;
  }

  return {
    allocations: goals
      .filter((goal) => given.has(goal.id))
      .map((goal) => ({ goalId: goal.id, amount: given.get(goal.id)! })),
    unallocated: pool,
  };
}

function validateGoal(goal: AllocatableGoal): void {
  if (
    !Number.isInteger(goal.priority) ||
    goal.priority < 1 ||
    goal.priority > 5
  ) {
    throw new RangeError(
      `Goal ${goal.id}: priority must be an integer from 1 to 5`,
    );
  }
  if (!Number.isSafeInteger(goal.remaining) || goal.remaining < 0) {
    throw new RangeError(
      `Goal ${goal.id}: remaining must be a non-negative integer`,
    );
  }
  if (!Number.isInteger(goal.daysLeft) || goal.daysLeft < 1) {
    throw new RangeError(
      `Goal ${goal.id}: daysLeft must be an integer of at least 1`,
    );
  }
}

function assertPositiveInteger(value: number, name: string): void {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new RangeError(
      `${name} must be a positive whole number of shillings`,
    );
  }
}
