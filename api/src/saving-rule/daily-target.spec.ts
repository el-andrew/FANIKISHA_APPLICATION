import { dailyTarget } from './daily-target.js';

describe('dailyTarget', () => {
  it("takes a share of the day's sales", () => {
    expect(dailyTarget({ basis: 'SALES', percent: 10 }, 120_000, 35_000)).toBe(
      12_000,
    );
  });

  it("takes a share of the day's profit", () => {
    expect(dailyTarget({ basis: 'PROFIT', percent: 20 }, 120_000, 35_000)).toBe(
      17_000,
    );
  });

  it('asks for nothing on a day with a loss', () => {
    expect(dailyTarget({ basis: 'PROFIT', percent: 50 }, 10_000, 30_000)).toBe(
      0,
    );
  });

  it('rounds down to whole shillings', () => {
    expect(dailyTarget({ basis: 'SALES', percent: 15 }, 1_999, 0)).toBe(299);
  });
});
