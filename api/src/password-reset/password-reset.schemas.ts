import { z } from 'zod';
import { emailSchema, passwordSchema } from '../auth/auth.schemas.js';

export const requestResetSchema = z.object({
  email: emailSchema,
  /** The language of the SMS; the app sends its own. */
  language: z.enum(['en', 'sw']).default('en'),
});
export type RequestResetInput = z.infer<typeof requestResetSchema>;

export const confirmResetSchema = z.object({
  email: emailSchema,
  code: z.string().regex(/^\d{6}$/, 'must be 6 digits'),
  newPassword: passwordSchema,
});
export type ConfirmResetInput = z.infer<typeof confirmResetSchema>;
