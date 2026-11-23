import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import {
  createTestApp,
  FakeSms,
  registerUser,
  resetDatabase,
  type TestUser,
} from './helpers.js';

let app: INestApplication<App>;
let sms: FakeSms;
const http = () => request(app.getHttpServer());
const PHONE = '+255712345678';

beforeAll(async () => {
  sms = new FakeSms();
  app = await createTestApp(sms);
});

beforeEach(async () => {
  await resetDatabase(app);
  sms.sent.length = 0;
});

afterAll(async () => {
  await app.close();
});

/** A user whose phone number is verified. */
async function verifiedUser(): Promise<TestUser> {
  const user = await registerUser(app, { phone: PHONE });
  await app
    .get(PrismaService)
    .user.update({
      where: { id: user.id },
      data: { phoneVerifiedAt: new Date() },
    });
  return user;
}

const requestReset = (email: string, language = 'en') =>
  http().post('/v1/auth/password-reset').send({ email, language });

const confirmReset = (
  email: string,
  code: string,
  newPassword = 'a brand new password',
) =>
  http()
    .post('/v1/auth/password-reset/confirm')
    .send({ email, code, newPassword });

/** The reset code is sent in the background; wait for it. */
async function codeSentTo(phone: string): Promise<string> {
  for (let i = 0; i < 50; i++) {
    if (sms.sent.some((m) => m.phone === phone)) return sms.lastCode(phone);
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  throw new Error(`No code was sent to ${phone}`);
}

/** Gives a background send time to happen, when we expect none. */
const settle = () => new Promise((resolve) => setTimeout(resolve, 200));

describe('password reset', () => {
  it('resets the password with a code sent to the verified phone', async () => {
    const user = await verifiedUser();

    await requestReset(user.email).expect(202);
    const code = await codeSentTo(PHONE);
    expect(sms.sent[0].message).toMatch(/password reset code is \d{6}/);

    const res = await confirmReset(user.email, code).expect(200);
    expect(res.body).toMatchObject({
      user: { id: user.id },
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
    });

    await http()
      .post('/v1/auth/login')
      .send({ email: user.email, password: user.password })
      .expect(401);
    await http()
      .post('/v1/auth/login')
      .send({ email: user.email, password: 'a brand new password' })
      .expect(200);
  });

  it('signs out every device that had the old password', async () => {
    const user = await verifiedUser();
    await requestReset(user.email).expect(202);
    await confirmReset(user.email, await codeSentTo(PHONE)).expect(200);

    await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(401);
  });

  it('answers the same way whether or not the account exists', async () => {
    const unknown = await requestReset('nobody@example.com').expect(202);
    const user = await verifiedUser();
    const known = await requestReset(user.email).expect(202);
    expect(known.body).toEqual(unknown.body);
  });

  it('sends nothing for an account without a verified phone', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await requestReset(user.email).expect(202);
    await settle();
    expect(sms.sent).toHaveLength(0);
    await confirmReset(user.email, '123456').expect(400);
  });

  it('sends the SMS in Kiswahili when asked', async () => {
    const user = await verifiedUser();
    await requestReset(user.email, 'sw').expect(202);
    await codeSentTo(PHONE);
    expect(sms.sent[0].message).toMatch(/^Namba yako ya kubadilisha nenosiri/);
  });

  it('rejects wrong codes, and says nothing about unknown emails', async () => {
    const user = await verifiedUser();
    await requestReset(user.email).expect(202);
    const right = await codeSentTo(PHONE);
    const wrong = right === '000000' ? '111111' : '000000';

    const res = await confirmReset(user.email, wrong).expect(400);
    expect(res.body).toMatchObject({ code: 'code_incorrect', triesLeft: 4 });

    const unknown = await confirmReset('nobody@example.com', right).expect(400);
    expect(unknown.body.code).toBe('code_expired');
  });

  it('keeps reset codes and phone verification codes apart', async () => {
    // An unverified user's verification code can't reset the password.
    const user = await registerUser(app, { phone: PHONE });
    await http()
      .post('/v1/me/phone/verification')
      .set('authorization', `Bearer ${user.accessToken}`)
      .send({})
      .expect(202);
    const verifyCode = sms.lastCode(PHONE);
    await app
      .get(PrismaService)
      .user.update({
        where: { id: user.id },
        data: { phoneVerifiedAt: new Date() },
      });

    await confirmReset(user.email, verifyCode).expect(400);
  });

  it('checks the new password', async () => {
    const user = await verifiedUser();
    await requestReset(user.email).expect(202);
    const code = await codeSentTo(PHONE);
    const res = await confirmReset(user.email, code, 'short').expect(400);
    expect(res.body.message).toEqual(
      expect.arrayContaining([expect.stringMatching(/^newPassword:/)]),
    );
  });
});
