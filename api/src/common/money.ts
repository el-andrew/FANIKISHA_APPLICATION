import { z } from 'zod';

/** Largest amount the API accepts in one value: 1 trillion TZS. */
export const MAX_AMOUNT = 1_000_000_000_000;

/** A positive whole number of Tanzanian shillings. */
export const amountSchema = z
  .number()
  .int('must be a whole number of shillings')
  .positive()
  .max(MAX_AMOUNT);

/**
 * Converts a BIGINT column to a JSON-safe number. Amounts are capped far below
 * Number.MAX_SAFE_INTEGER, so this only throws if the database holds a value
 * the API could never have written.
 */
export function toAmount(value: bigint): number {
  const n = Number(value);
  if (!Number.isSafeInteger(n)) {
    throw new RangeError(`Amount ${value} is outside the safe integer range`);
  }
  return n;
}
