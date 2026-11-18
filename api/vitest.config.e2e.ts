import { config } from 'dotenv';
import { defineConfig } from 'vitest/config';

// Values from .env.test, unless the environment (e.g. CI) already sets them.
const env =
  config({ path: '.env.test', quiet: true, processEnv: {} }).parsed ?? {};

export default defineConfig({
  resolve: { tsconfigPaths: true },
  test: {
    globals: true,
    root: './',
    include: ['**/*.e2e-spec.ts'],
    env: { ...env, ...pickDefined(process.env, Object.keys(env)) },
    globalSetup: ['./test/global-setup.ts'],
    // The suites share one database.
    fileParallelism: false,
    hookTimeout: 60_000,
    testTimeout: 30_000,
  },
});

function pickDefined(source: NodeJS.ProcessEnv, keys: string[]) {
  return Object.fromEntries(
    keys.filter((k) => source[k] !== undefined).map((k) => [k, source[k]!]),
  );
}
