import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

export async function createTestApp(): Promise<INestApplication<App>> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();
  const app = moduleRef.createNestApplication<INestApplication<App>>();
  configureApp(app);
  await app.init();
  return app;
}

export async function resetDatabase(app: INestApplication): Promise<void> {
  await app
    .get(PrismaService)
    .$executeRawUnsafe(
      `TRUNCATE users, goals, deposits, allocations, refresh_tokens, revoked_refresh_token_families CASCADE`,
    );
}

let userCounter = 0;

export interface TestUser {
  id: string;
  email: string;
  password: string;
  accessToken: string;
  refreshToken: string;
}

export async function registerUser(
  app: INestApplication<App>,
  overrides: Record<string, unknown> = {},
): Promise<TestUser> {
  userCounter += 1;
  const body = {
    email: `owner${userCounter}@example.com`,
    password: 'a strong password',
    fullName: `Business Owner ${userCounter}`,
    ...overrides,
  };
  const res = await request(app.getHttpServer())
    .post('/v1/auth/register')
    .send(body)
    .expect(201);
  return {
    id: res.body.user.id,
    email: res.body.user.email,
    password: body.password as string,
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
  };
}

/** A date `days` from today as YYYY-MM-DD. */
export function daysFromNow(days: number): string {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}
