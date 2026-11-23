import { z } from 'zod';
import { amountSchema } from '../common/money.js';

export const createDepositSchema = z.object({
  amount: amountSchema,
  note: z.string().trim().min(1).max(200).optional(),
});
export type CreateDepositInput = z.infer<typeof createDepositSchema>;

export const previewDepositSchema = z.object({ amount: amountSchema });
export type PreviewDepositInput = z.infer<typeof previewDepositSchema>;

/**
 * Sent as the `Idempotency-Key` header, normally a UUID the app generates
 * once per deposit and reuses on retries.
 */
export const idempotencyKeySchema = z
  .string()
  .regex(/^[A-Za-z0-9_-]{8,100}$/, 'must be 8 to 100 letters, digits, - or _');

export const listDepositsQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  /** The `nextCursor` from the previous page. */
  cursor: z.uuid().optional(),
});
export type ListDepositsQuery = z.infer<typeof listDepositsQuerySchema>;

export const depositIdSchema = z.uuid();
