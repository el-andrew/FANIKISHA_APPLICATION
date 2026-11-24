import { businessDayBounds, businessToday, toDateOnly } from './dates.js';

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

describe('businessDayBounds', () => {
  it('runs from midnight to midnight in Tanzania', () => {
    const { start, end } = businessDayBounds(new Date('2026-11-24T00:00:00Z'));
    expect(start.toISOString()).toBe('2026-11-23T21:00:00.000Z');
    expect(end.toISOString()).toBe('2026-11-24T21:00:00.000Z');
  });

  it('contains every moment businessToday() calls that day', () => {
    for (const iso of [
      '2026-11-23T21:00:00Z',
      '2026-11-24T12:00:00Z',
      '2026-11-24T20:59:59Z',
    ]) {
      const now = new Date(iso);
      const { start, end } = businessDayBounds(businessToday(now));
      expect(now >= start && now < end).toBe(true);
    }
  });
});
