import { businessToday, toDateOnly } from './dates.js';

describe('businessToday', () => {
  it('uses the Tanzanian calendar date, not the UTC one', () => {
    // 01:20 on 19 November in Dar es Salaam is still the 18th in UTC.
    expect(toDateOnly(businessToday(new Date('2026-11-18T22:20:00Z')))).toBe(
      '2026-11-19',
    );
  });

  it('matches UTC during the Tanzanian daytime', () => {
    expect(toDateOnly(businessToday(new Date('2026-11-18T09:00:00Z')))).toBe(
      '2026-11-18',
    );
  });
});
