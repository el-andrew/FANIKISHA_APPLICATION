import { validateEnv } from './env.js';

const base = {
  DATABASE_URL: 'postgresql://u@localhost:5432/db',
  JWT_SECRET: 'x'.repeat(32),
};

const operator = {
  OPERATOR_NAME: 'Fanikisha Ltd',
  OPERATOR_REGISTRATION: '123456789',
  OPERATOR_ADDRESS: 'Dar es Salaam, Tanzania',
  OPERATOR_EMAIL: 'privacy@example.com',
};

describe('validateEnv', () => {
  it('checks the database certificate file exists', () => {
    expect(() =>
      validateEnv({ ...base, DATABASE_CA_CERT: 'certs/missing.crt' }),
    ).toThrow(/DATABASE_CA_CERT: file not found/);
    expect(
      validateEnv({ ...base, DATABASE_CA_CERT: 'certs/supabase-root-2021.crt' })
        .DATABASE_CA_CERT,
    ).toBe('certs/supabase-root-2021.crt');
  });

  it('trusts no proxy unless told how many there are', () => {
    expect(validateEnv(base).TRUST_PROXY_HOPS).toBe(0);
    expect(
      validateEnv({ ...base, TRUST_PROXY_HOPS: '1' }).TRUST_PROXY_HOPS,
    ).toBe(1);
    expect(() => validateEnv({ ...base, TRUST_PROXY_HOPS: 'true' })).toThrow(
      /TRUST_PROXY_HOPS/,
    );
  });

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
      ...operator,
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
  it('refuses to publish placeholder operator details in production', () => {
    expect(() =>
      validateEnv({
        ...base,
        NODE_ENV: 'production',
        SMS_PROVIDER: 'beem',
        BEEM_API_KEY: 'k',
        BEEM_SECRET_KEY: 's',
        BEEM_SENDER_ID: 'FANIKISHA',
      }),
    ).toThrow(/OPERATOR_NAME[\s\S]*OPERATOR_EMAIL/);
  });
});
