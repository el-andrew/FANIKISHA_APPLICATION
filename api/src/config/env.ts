import { z } from 'zod';

const secret = z.string().refine((s) => Buffer.byteLength(s, 'utf8') >= 32, {
  message: 'must be at least 32 bytes',
});

/** Environment variables the API needs. Startup fails if any is missing or invalid. */
export const envSchema = z
  .object({
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development'),
    PORT: z.coerce.number().int().positive().default(3000),
    /**
     * How many reverse proxies sit in front of the API (1 on Render). Client
     * addresses, used for rate limits, are read from `X-Forwarded-For` only
     * past that many hops, so a client can't pick its own address. 0 when
     * the API is reached directly.
     */
    TRUST_PROXY_HOPS: z.coerce.number().int().min(0).max(5).default(0),
    DATABASE_URL: z.url(),
    JWT_SECRET: secret,
    JWT_ISSUER: z.string().min(1).default('fanikisha-api'),
    JWT_AUDIENCE: z.string().min(1).default('fanikisha-mobile'),

    /**
     * How SMS messages are sent: `beem` for real messages, `log` to print
     * them to the server log during development.
     */
    SMS_PROVIDER: z.enum(['beem', 'log']).default('log'),
    BEEM_API_KEY: z.string().min(1).optional(),
    BEEM_SECRET_KEY: z.string().min(1).optional(),
    /** A sender ID registered and activated on the Beem account (max 11 characters). */
    BEEM_SENDER_ID: z.string().min(1).max(11).optional(),
    BEEM_API_URL: z.url().default('https://apisms.beem.africa/v1/send'),

    /**
     * Who runs Fanikisha, as named in the privacy policy and terms. The
     * placeholders are fine in development; production requires real values.
     */
    OPERATOR_NAME: z.string().min(1).default('[BUSINESS NAME]'),
    OPERATOR_REGISTRATION: z
      .string()
      .min(1)
      .default('[BUSINESS REGISTRATION NUMBER]'),
    OPERATOR_ADDRESS: z.string().min(1).default('[BUSINESS ADDRESS]'),
    OPERATOR_EMAIL: z.string().min(1).default('[CONTACT EMAIL]'),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV === 'production' && env.SMS_PROVIDER !== 'beem') {
      ctx.addIssue({
        code: 'custom',
        path: ['SMS_PROVIDER'],
        message: 'must be "beem" in production (the log provider prints codes)',
      });
    }
    if (env.NODE_ENV === 'production') {
      for (const key of [
        'OPERATOR_NAME',
        'OPERATOR_REGISTRATION',
        'OPERATOR_ADDRESS',
        'OPERATOR_EMAIL',
      ] as const) {
        if (env[key].startsWith('[')) {
          ctx.addIssue({
            code: 'custom',
            path: [key],
            message:
              'must be set in production (it is published in the privacy policy and terms)',
          });
        }
      }
    }
    if (env.SMS_PROVIDER === 'beem') {
      for (const key of [
        'BEEM_API_KEY',
        'BEEM_SECRET_KEY',
        'BEEM_SENDER_ID',
      ] as const) {
        if (!env[key]) {
          ctx.addIssue({
            code: 'custom',
            path: [key],
            message: 'is required when SMS_PROVIDER is "beem"',
          });
        }
      }
    }
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
