import { execSync } from 'node:child_process';
import { config } from 'dotenv';

/** Applies migrations to the test database once, before any suite runs. */
export default function setup(): void {
  config({ path: '.env.test', quiet: true });
  const url = process.env.DATABASE_URL ?? '';
  // The suites delete every row: never let them near a real database.
  if (!/test/i.test(new URL(url).pathname)) {
    throw new Error(
      'Refusing to run end-to-end tests: DATABASE_URL must name a database containing "test".',
    );
  }
  execSync('npx prisma migrate deploy', { stdio: 'inherit', env: process.env });
}
