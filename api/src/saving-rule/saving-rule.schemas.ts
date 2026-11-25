import { z } from 'zod';

export const savingRuleSchema = z.object({
  basis: z.enum(['SALES', 'PROFIT']),
  percent: z.int().min(1).max(100),
});
export type SavingRuleInput = z.infer<typeof savingRuleSchema>;
