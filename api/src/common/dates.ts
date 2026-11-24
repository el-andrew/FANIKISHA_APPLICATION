import { z } from 'zod';

/**
 * The calendar Fanikisha's users live by. "Today" for goal dates and urgency
 * is today in Tanzania (UTC+3), not in UTC: otherwise, between midnight and
 * 03:00 local time, the app would still think it was yesterday.
 */
export const BUSINESS_TIME_ZONE = 'Africa/Dar_es_Salaam';

/** A calendar date as `YYYY-MM-DD`, parsed to a Date at midnight UTC. */
export const dateOnlySchema = z.iso
  .date()
  .transform((value) => new Date(`${value}T00:00:00.000Z`));

/** Formats a DATE column as `YYYY-MM-DD`. */
export function toDateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}

const businessDateFormat = new Intl.DateTimeFormat('en-CA', {
  timeZone: BUSINESS_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/**
 * Today's date in {@link BUSINESS_TIME_ZONE}, as midnight UTC: the same
 * representation as the DATE columns, so the two compare directly.
 */
export function businessToday(now: Date = new Date()): Date {
  // en-CA formats as YYYY-MM-DD.
  return new Date(`${businessDateFormat.format(now)}T00:00:00.000Z`);
}

/** Tanzania is UTC+3 all year: it has no daylight saving time. */
const BUSINESS_UTC_OFFSET_MS = 3 * 60 * 60 * 1000;

/**
 * The instants a business day starts and ends at, for comparing timestamps
 * (such as when a deposit was made) with a day in Tanzania. `end` is
 * exclusive.
 */
export function businessDayBounds(day: Date): { start: Date; end: Date } {
  const start = new Date(day.getTime() - BUSINESS_UTC_OFFSET_MS);
  return { start, end: new Date(start.getTime() + 86_400_000) };
}
