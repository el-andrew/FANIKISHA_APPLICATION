import { validateEnv } from './env.js';

const base = {
  DATABASE_URL: 'postgresql://u@localhost:5432/db',
  JWT_SECRET: 'x'.repeat(32),
};

describe('validateEnv', () => {
  it('prints SMS to the log by default outside production', () => {
    expect(validateEnv(base).SMS_PROVIDER).toBe('log');
  });

  it('refuses to run production without a real SMS provider', () => {
    expect(() => validateEnv({ ...base, NODE_ENV: 'production' })).toThrow(
      /SMS_PROVIDER/,
    );
  });

  it('requires the Beem credentials and sender ID for Beem', () => {
    expect(() => validateEnv({ ...base, SMS_PROVIDER: 'beem' })).toThrow(
      /BEEM_API_KEY[\s\S]*BEEM_SECRET_KEY[\s\S]*BEEM_SENDER_ID/,
    );
    const env = validateEnv({
      ...base,
      NODE_ENV: 'production',
      SMS_PROVIDER: 'beem',
      BEEM_API_KEY: 'key',
      BEEM_SECRET_KEY: 'secret',
      BEEM_SENDER_ID: 'FANIKISHA',
    });
    expect(env.BEEM_API_URL).toBe('https://apisms.beem.africa/v1/send');
  });

  it('rejects sender IDs longer than Beem allows', () => {
    expect(() =>
      validateEnv({
        ...base,
        SMS_PROVIDER: 'beem',
        BEEM_API_KEY: 'k',
        BEEM_SECRET_KEY: 's',
        BEEM_SENDER_ID: 'FANIKISHA-APP',
      }),
    ).toThrow(/BEEM_SENDER_ID/);
  });
});
