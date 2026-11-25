import { z } from 'zod';

/** International format, e.g. +255712345678. */
export const phoneSchema = z
  .string()
  .regex(
    /^\+[1-9]\d{7,14}$/,
    'must be in international format, e.g. +255712345678',
  );

export const emailSchema = z
  .email()
  .max(254)
  .transform((email) => email.toLowerCase());

export const passwordSchema = z
  .string()
  .min(8, 'must be at least 8 characters')
  .max(128);

export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  fullName: z.string().trim().min(2).max(100),
  phone: phoneSchema.optional(),
  businessName: z.string().trim().min(1).max(120).optional(),
});
export type RegisterInput = z.infer<typeof registerSchema>;

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1).max(128),
});
export type LoginInput = z.infer<typeof loginSchema>;

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1).max(512),
});
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
