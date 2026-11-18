import { z } from 'zod';
import { amountSchema } from '../common/money.js';
import { dateOnlySchema } from '../common/dates.js';

const name = z.string().trim().min(1).max(80);
const category = z.string().trim().min(1).max(40);
const priority = z.int().min(1).max(5);

export const createGoalSchema = z.object({
  name,
  category: category.optional(),
  targetAmount: amountSchema,
  /** 1 (low) to 5 (high). */
  priority,
  /** Defaults to today. */
  startDate: dateOnlySchema.optional(),
  targetDate: dateOnlySchema,
});
export type CreateGoalInput = z.infer<typeof createGoalSchema>;

export const updateGoalSchema = z
  .object({
    name,
    category: category.nullable(),
    targetAmount: amountSchema,
    priority,
    targetDate: dateOnlySchema,
  })
  .partial()
  .refine((body) => Object.keys(body).length > 0, {
    message: 'Provide at least one field to update',
  });
export type UpdateGoalInput = z.infer<typeof updateGoalSchema>;

export const listGoalsQuerySchema = z.object({
  status: z.enum(['ACTIVE', 'COMPLETED', 'ARCHIVED']).optional(),
});
export type ListGoalsQuery = z.infer<typeof listGoalsQuerySchema>;

export const goalIdSchema = z.uuid();
