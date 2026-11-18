import { z } from 'zod';
import { passwordSchema, phoneSchema } from '../auth/auth.schemas.js';

export const updateProfileSchema = z
  .object({
    fullName: z.string().trim().min(2).max(100),
    phone: phoneSchema.nullable(),
    businessName: z.string().trim().min(1).max(120).nullable(),
  })
  .partial()
  .refine((body) => Object.keys(body).length > 0, {
    message: 'Provide at least one field to update',
  });
export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(128),
  newPassword: passwordSchema,
});
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
