export type SavingBasis = 'SALES' | 'PROFIT';

export interface Rule {
  basis: SavingBasis;
  /** 1 to 100. */
  percent: number;
}

/**
 * How much the rule asks to save for a day: the percentage of the day's
 * sales, or of its profit. A day with a loss asks for nothing. Rounded down
 * to whole shillings.
 */
export function dailyTarget(
  rule: Rule,
  sales: number,
  expenses: number,
): number {
  const base = rule.basis === 'SALES' ? sales : Math.max(0, sales - expenses);
  return Math.floor((base * rule.percent) / 100);
}
