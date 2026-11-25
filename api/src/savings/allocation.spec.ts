import {
  allocateDeposit,
  daysUntil,
  type AllocatableGoal,
} from './allocation.js';

function goal(
  id: string,
  priority: number,
  remaining: number,
  daysLeft: number,
): AllocatableGoal {
  return { id, priority, remaining, daysLeft };
}

function amountFor(result: ReturnType<typeof allocateDeposit>, id: string) {
  return result.allocations.find((a) => a.goalId === id)?.amount ?? 0;
}

describe('allocateDeposit', () => {
  it('gives a single goal the whole deposit when it needs it', () => {
    const result = allocateDeposit(10_000, [goal('a', 3, 50_000, 30)]);
    expect(result).toEqual({
      allocations: [{ goalId: 'a', amount: 10_000 }],
      unallocated: 0,
    });
  });

  it('splits by priority when goals are equally urgent', () => {
    const result = allocateDeposit(6_000, [
      goal('high', 5, 100_000, 100),
      goal('low', 1, 100_000, 100),
    ]);
    expect(amountFor(result, 'high')).toBe(5_000);
    expect(amountFor(result, 'low')).toBe(1_000);
  });

  it('splits by urgency when goals have equal priority', () => {
    // 1,000 TZS/day needed versus 333.33 TZS/day: a 3:1 split.
    const result = allocateDeposit(4_000, [
      goal('soon', 3, 30_000, 30),
      goal('later', 3, 30_000, 90),
    ]);
    expect(amountFor(result, 'soon')).toBe(3_000);
    expect(amountFor(result, 'later')).toBe(1_000);
  });

  it('matches the original 2022 priority × duration weighting', () => {
    const goals = [
      goal('a', 5, 120_000, 60),
      goal('b', 3, 45_000, 15),
      goal('c', 1, 200_000, 400),
    ];
    // Original formula: priorityWeight = p / maxP,
    // durationWeight = perDay / sum(perDay), share = pw·dw / sum(pw·dw).
    const perDay = goals.map((g) => g.remaining / g.daysLeft);
    const totalPerDay = perDay.reduce((s, v) => s + v, 0);
    const pd = goals.map(
      (g, i) => (g.priority / 5) * (perDay[i] / totalPerDay),
    );
    const totalPd = pd.reduce((s, v) => s + v, 0);

    // Small enough that no goal hits its cap, so the shares are the
    // formula's alone.
    const deposit = 20_000;
    const result = allocateDeposit(deposit, goals);
    goals.forEach((g, i) => {
      const expected = (deposit * pd[i]) / totalPd;
      expect(Math.abs(amountFor(result, g.id) - expected)).toBeLessThan(1);
    });
  });

  it('fills a nearly complete goal and shares the excess with the others', () => {
    const result = allocateDeposit(10_000, [
      goal('almost', 5, 500, 1),
      goal('big', 2, 1_000_000, 365),
    ]);
    expect(amountFor(result, 'almost')).toBe(500);
    expect(amountFor(result, 'big')).toBe(9_500);
    expect(result.unallocated).toBe(0);
  });

  it('returns what no goal needs as unallocated', () => {
    const result = allocateDeposit(10_000, [
      goal('a', 3, 2_000, 10),
      goal('b', 1, 3_000, 10),
    ]);
    expect(amountFor(result, 'a')).toBe(2_000);
    expect(amountFor(result, 'b')).toBe(3_000);
    expect(result.unallocated).toBe(5_000);
  });

  it('leaves the whole deposit unallocated when there are no goals', () => {
    expect(allocateDeposit(7_500, [])).toEqual({
      allocations: [],
      unallocated: 7_500,
    });
  });

  it('skips goals that are already complete', () => {
    const result = allocateDeposit(1_000, [
      goal('done', 5, 0, 10),
      goal('open', 1, 5_000, 10),
    ]);
    expect(result.allocations).toEqual([{ goalId: 'open', amount: 1_000 }]);
  });

  it('rounds deterministically, favouring earlier goals on exact ties', () => {
    const result = allocateDeposit(100, [
      goal('a', 3, 10_000, 30),
      goal('b', 3, 10_000, 30),
      goal('c', 3, 10_000, 30),
    ]);
    expect(result.allocations).toEqual([
      { goalId: 'a', amount: 34 },
      { goalId: 'b', amount: 33 },
      { goalId: 'c', amount: 33 },
    ]);
  });

  it('rejects invalid input', () => {
    expect(() => allocateDeposit(0, [])).toThrow(RangeError);
    expect(() => allocateDeposit(10.5, [])).toThrow(RangeError);
    expect(() => allocateDeposit(100, [goal('a', 6, 100, 1)])).toThrow(
      RangeError,
    );
    expect(() => allocateDeposit(100, [goal('a', 3, -1, 1)])).toThrow(
      RangeError,
    );
    expect(() => allocateDeposit(100, [goal('a', 3, 100, 0)])).toThrow(
      RangeError,
    );
  });

  it('keeps its invariants across many random cases', () => {
    // Small deterministic PRNG so failures are reproducible.
    let seed = 42;
    const random = () => {
      seed = (seed * 1_103_515_245 + 12_345) % 2 ** 31;
      return seed / 2 ** 31;
    };
    const int = (min: number, max: number) =>
      min + Math.floor(random() * (max - min + 1));

    for (let run = 0; run < 2_000; run++) {
      const goals = Array.from({ length: int(0, 8) }, (_, i) =>
        goal(`g${i}`, int(1, 5), int(0, 5_000_000), int(1, 730)),
      );
      const deposit = int(1, 10_000_000);
      const result = allocateDeposit(deposit, goals);

      const total =
        result.allocations.reduce((s, a) => s + a.amount, 0) +
        result.unallocated;
      expect(total).toBe(deposit);

      for (const a of result.allocations) {
        const g = goals.find((x) => x.id === a.goalId)!;
        expect(Number.isInteger(a.amount)).toBe(true);
        expect(a.amount).toBeGreaterThan(0);
        expect(a.amount).toBeLessThanOrEqual(g.remaining);
      }

      const needed = goals.reduce((s, g) => s + g.remaining, 0);
      expect(result.unallocated).toBe(Math.max(0, deposit - needed));
    }
  });
});

describe('daysUntil', () => {
  const today = new Date('2026-03-10T15:30:00Z');

  it('counts whole calendar days', () => {
    expect(daysUntil(new Date('2026-03-20'), today)).toBe(10);
  });

  it('treats today, tomorrow and overdue dates as at least one day', () => {
    expect(daysUntil(new Date('2026-03-10'), today)).toBe(1);
    expect(daysUntil(new Date('2026-03-11'), today)).toBe(1);
    expect(daysUntil(new Date('2025-12-01'), today)).toBe(1);
  });
});
