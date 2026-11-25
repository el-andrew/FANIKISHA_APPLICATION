import { z } from 'zod';
import { amountSchema } from '../common/money.js';

/** A goal id, or null for general savings. */
const place = z.uuid().nullable();
const note = z.string().trim().min(1).max(200);

export const withdrawalSchema = z.object({
  from: place,
  amount: amountSchema,
  note: note.optional(),
});
export type WithdrawalInput = z.infer<typeof withdrawalSchema>;

export const transferSchema = z
  .object({
    from: place,
    to: place,
    amount: amountSchema,
    note: note.optional(),
  })
  .refine((t) => t.from !== t.to, {
    message: 'Choose a different place to move the money to',
    path: ['to'],
  });
export type TransferInput = z.infer<typeof transferSchema>;

export const activityQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  /** The `nextCursor` from the previous page. */
  cursor: z.string().max(200).optional(),
});
export type ActivityQuery = z.infer<typeof activityQuerySchema>;
