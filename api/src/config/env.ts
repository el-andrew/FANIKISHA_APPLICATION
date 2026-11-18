import { z } from 'zod';

/** Environment variables the API needs. Startup fails if any is missing or invalid. */
export const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.url(),
  JWT_SECRET: z.string().refine((s) => Buffer.byteLength(s, 'utf8') >= 32, {
    message: 'must be at least 32 bytes',
  }),
  JWT_ISSUER: z.string().min(1).default('fanikisha-api'),
  JWT_AUDIENCE: z.string().min(1).default('fanikisha-mobile'),
});

export type Env = z.infer<typeof envSchema>;

export function validateEnv(config: Record<string, unknown>): Env {
  const result = envSchema.safeParse(config);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `  ${issue.path.join('.')}: ${issue.message}`)
      .join('\n');
    throw new Error(`Invalid environment configuration:\n${problems}`);
  }
  return result.data;
}
