import { z } from 'zod';

export const sendCodeSchema = z.object({
  /** The language of the SMS; the app sends its own. */
  language: z.enum(['en', 'sw']).default('en'),
});
export type SendCodeInput = z.infer<typeof sendCodeSchema>;

export const confirmCodeSchema = z.object({
  code: z.string().regex(/^\d{6}$/, 'must be 6 digits'),
});
export type ConfirmCodeInput = z.infer<typeof confirmCodeSchema>;
