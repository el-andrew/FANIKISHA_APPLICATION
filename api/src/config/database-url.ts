import { resolve } from 'node:path';

/**
 * The program connecting. node-postgres (the API at run time) and the Prisma
 * CLI (migrations) read different SSL parameters from a connection string,
 * and each one ignores or misreads the other's.
 */
export type DatabaseClient = 'node-postgres' | 'prisma-cli';

const sslParams = [
  'sslmode',
  'sslrootcert',
  'sslcert',
  'sslkey',
  'sslaccept',
  'uselibpqcompat',
];

/**
 * [url] set up to encrypt the connection and verify the server's certificate
 * against the root certificate at [caCertPath] (relative to the API folder),
 * in the parameters [client] understands. Without [caCertPath], [url] is
 * returned unchanged (a local database, or one on a private network).
 */
export function databaseUrl(
  url: string,
  caCertPath: string | undefined,
  client: DatabaseClient,
): string {
  if (!caCertPath) return url;
  const parsed = new URL(url);
  for (const name of sslParams) parsed.searchParams.delete(name);
  const ca = resolve(caCertPath);
  if (client === 'node-postgres') {
    // pg 8 treats verify-full as: encrypt, check the chain and the host name.
    parsed.searchParams.set('sslmode', 'verify-full');
    parsed.searchParams.set('sslrootcert', ca);
  } else {
    // Prisma reads the root certificate from `sslcert`, and only checks it
    // with sslaccept=strict; without that it accepts any certificate.
    parsed.searchParams.set('sslmode', 'require');
    parsed.searchParams.set('sslcert', ca);
    parsed.searchParams.set('sslaccept', 'strict');
  }
  return parsed.toString();
}
