import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { SMS_SENDER, type SmsSender } from '../src/sms/sms-sender.js';

/** Records messages instead of sending them; tests read codes from it. */
export class FakeSms implements SmsSender {
  readonly sent: { phone: string; message: string }[] = [];
  failNext = false;

  send(phone: string, message: string): Promise<void> {
    if (this.failNext) {
      this.failNext = false;
      return Promise.reject(new Error('provider down'));
    }
    this.sent.push({ phone, message });
    return Promise.resolve();
  }

  /** The code in the latest message to [phone]. */
  lastCode(phone: string): string {
    const message = this.sent.filter((m) => m.phone === phone).at(-1)?.message;
    const code = message?.match(/\b(\d{6})\b/)?.[1];
    if (!code) throw new Error(`No code was sent to ${phone}`);
    return code;
  }
}

export async function createTestApp(
  sms: SmsSender = new FakeSms(),
): Promise<INestApplication<App>> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(SMS_SENDER)
    .useValue(sms)
    .compile();
  const app = moduleRef.createNestApplication<INestApplication<App>>();
  configureApp(app);
  await app.init();
  return app;
}

export async function resetDatabase(app: INestApplication): Promise<void> {
  await app
    .get(PrismaService)
    .$executeRawUnsafe(
      `TRUNCATE users, goals, deposits, allocations, business_entries, sms_codes, refresh_tokens, revoked_refresh_token_families CASCADE`,
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
