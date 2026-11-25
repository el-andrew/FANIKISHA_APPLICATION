import { z } from 'zod';
import { dateOnlySchema } from '../common/dates.js';
import { amountSchema } from '../common/money.js';

const entryType = z.enum(['SALE', 'EXPENSE']);
const category = z.string().trim().min(1).max(40);
const note = z.string().trim().min(1).max(200);

export const createEntrySchema = z.object({
  type: entryType,
  amount: amountSchema,
  category: category.optional(),
  note: note.optional(),
  /** Defaults to today in Tanzania. */
  occurredOn: dateOnlySchema.optional(),
});
export type CreateEntryInput = z.infer<typeof createEntrySchema>;

export const updateEntrySchema = z
  .object({
    type: entryType,
    amount: amountSchema,
    category: category.nullable(),
    note: note.nullable(),
    occurredOn: dateOnlySchema,
  })
  .partial()
  .refine((body) => Object.keys(body).length > 0, {
    message: 'Provide at least one field to update',
  });
export type UpdateEntryInput = z.infer<typeof updateEntrySchema>;

export const listEntriesQuerySchema = z.object({
  from: dateOnlySchema.optional(),
  to: dateOnlySchema.optional(),
  type: entryType.optional(),
  limit: z.coerce.number().int().min(1).max(100).default(30),
  /** The `nextCursor` from the previous page. */
  cursor: z.uuid().optional(),
});
export type ListEntriesQuery = z.infer<typeof listEntriesQuerySchema>;

export const summaryQuerySchema = z.object({
  from: dateOnlySchema,
  to: dateOnlySchema,
});
export type SummaryQuery = z.infer<typeof summaryQuerySchema>;

export const entryIdSchema = z.uuid();
