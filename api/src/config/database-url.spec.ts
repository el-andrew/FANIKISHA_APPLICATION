import { resolve } from 'node:path';
import { databaseUrl } from './database-url.js';

const url =
  'postgresql://postgres.abc:p%40ss@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

const params = (u: string) => Object.fromEntries(new URL(u).searchParams);

describe('databaseUrl', () => {
  it('leaves the address alone without a certificate', () => {
    expect(databaseUrl(url, undefined, 'node-postgres')).toBe(url);
    expect(databaseUrl(url, undefined, 'prisma-cli')).toBe(url);
  });

  it('verifies the server for node-postgres', () => {
    const result = databaseUrl(url, 'certs/root.crt', 'node-postgres');
    expect(params(result)).toEqual({
      sslmode: 'verify-full',
      sslrootcert: resolve('certs/root.crt'),
    });
  });

  it('verifies the server for the Prisma CLI', () => {
    const result = databaseUrl(url, 'certs/root.crt', 'prisma-cli');
    expect(params(result)).toEqual({
      sslmode: 'require',
      sslcert: resolve('certs/root.crt'),
      sslaccept: 'strict',
    });
  });

  it('replaces weaker SSL settings already in the address', () => {
    const result = databaseUrl(
      `${url}?sslmode=require&uselibpqcompat=true&application_name=api`,
      'certs/root.crt',
      'node-postgres',
    );
    expect(params(result)).toEqual({
      application_name: 'api',
      sslmode: 'verify-full',
      sslrootcert: resolve('certs/root.crt'),
    });
  });

  it('keeps the credentials and host intact', () => {
    const result = new URL(databaseUrl(url, 'c.crt', 'prisma-cli'));
    expect(result.username).toBe('postgres.abc');
    expect(decodeURIComponent(result.password)).toBe('p@ss');
    expect(result.host).toBe('aws-0-eu-central-1.pooler.supabase.com:5432');
  });
});
