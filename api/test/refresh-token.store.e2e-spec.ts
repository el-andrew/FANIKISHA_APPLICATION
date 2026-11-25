import type { AuthenticationStorage } from '@nestjs/authentication';
import { authenticationStoreContract } from '@nestjs/authentication/testing';
import type { ConfigService } from '@nestjs/config';
import { PrismaRefreshTokenStore } from '../src/auth/prisma-refresh-token.store.js';
import type { Env } from '../src/config/env.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

/**
 * Runs @nestjs/authentication's own conformance suite against the Postgres
 * store, including the concurrency cases that catch read-then-write races.
 */
const config = {
  get: () => process.env.DATABASE_URL,
} as unknown as ConfigService<Env, true>;
const prisma = new PrismaService(config);
const storage = {
  registerSource: () => {},
} as unknown as AuthenticationStorage;

afterAll(async () => {
  await prisma.$disconnect();
});

describe('PrismaRefreshTokenStore', () => {
  const cases = authenticationStoreContract(
    () => ({ refreshTokens: new PrismaRefreshTokenStore(prisma, storage) }),
    { contracts: ['refreshTokens'], concurrent: true },
  );

  it.each(cases.map((c) => [c.name, c] as const))('%s', async (_name, c) => {
    await c.run();
  });
});
