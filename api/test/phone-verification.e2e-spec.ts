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
const auth = (user: TestUser) => ({
  authorization: `Bearer ${user.accessToken}`,
});
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

const sendCode = (user: TestUser, language = 'en') =>
  http().post('/v1/me/phone/verification').set(auth(user)).send({ language });

const confirm = (user: TestUser, code: string) =>
  http()
    .post('/v1/me/phone/verification/confirm')
    .set(auth(user))
    .send({ code });

/** Lets the next code be requested without waiting out the cooldown. */
async function skipCooldown() {
  await app.get(PrismaService)
    .$executeRaw`UPDATE sms_codes SET created_at = created_at - interval '2 minutes'`;
}

describe('phone verification', () => {
  it('texts a code and marks the number verified when it is entered', async () => {
    const user = await registerUser(app, { phone: PHONE });

    const sent = await sendCode(user).expect(202);
    expect(sent.body).toMatchObject({
      phone: PHONE,
      expiresAt: expect.any(String),
      resendAvailableAt: expect.any(String),
    });
    expect(sms.sent).toHaveLength(1);
    expect(sms.sent[0].message).toMatch(
      /Your Fanikisha verification code is \d{6}/,
    );

    const verified = await confirm(user, sms.lastCode(PHONE)).expect(200);
    expect(verified.body).toMatchObject({ phone: PHONE, phoneVerified: true });

    const me = await http().get('/v1/me').set(auth(user)).expect(200);
    expect(me.body.phoneVerified).toBe(true);
    await sendCode(user).expect(409);
  });

  it('sends the SMS in Kiswahili when asked', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user, 'sw').expect(202);
    expect(sms.sent[0].message).toMatch(/^Namba yako ya uthibitisho/);
  });

  it('needs a phone number on the profile', async () => {
    const user = await registerUser(app);
    await sendCode(user).expect(400);
    expect(sms.sent).toHaveLength(0);
  });

  it('never stores the code itself', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    const row = await app.get(PrismaService).smsCode.findFirstOrThrow();
    expect(row.codeHash).not.toContain(sms.lastCode(PHONE));
    expect(row.codeHash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('allows five wrong guesses per code, counted under concurrency', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    const right = sms.lastCode(PHONE);
    const wrong = right === '000000' ? '111111' : '000000';

    const responses = await Promise.all(
      Array.from({ length: 10 }, () => confirm(user, wrong)),
    );
    const statuses = responses.map((r) => r.status);
    expect(statuses.filter((s) => s === 400)).toHaveLength(4);
    expect(statuses.filter((s) => s === 429)).toHaveLength(6);

    // Even the right code is refused now: a new one is needed.
    await confirm(user, right).expect(429);
    const row = await app.get(PrismaService).smsCode.findFirstOrThrow();
    expect(row.attempts).toBe(5);
  });

  it('says how many tries are left', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    const wrong = sms.lastCode(PHONE) === '000000' ? '111111' : '000000';
    const res = await confirm(user, wrong).expect(400);
    expect(res.body).toMatchObject({
      message: 'That code is not correct. 4 tries left',
      code: 'code_incorrect',
      triesLeft: 4,
    });
  });

  it('rejects expired codes', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    // Through Prisma, which stores UTC like the app does (the test database
    // may run in another time zone, so SQL's now() would not match).
    await app.get(PrismaService).smsCode.updateMany({
      data: { expiresAt: new Date(Date.now() - 1000) },
    });
    await confirm(user, sms.lastCode(PHONE)).expect(400);
  });

  it('makes earlier codes useless once a new one is sent', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    const first = sms.lastCode(PHONE);
    await skipCooldown();
    await sendCode(user).expect(202);
    const second = sms.lastCode(PHONE);

    if (first !== second) await confirm(user, first).expect(400);
    await confirm(user, second).expect(200);
  });

  it('waits a minute between codes and allows five a day', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    const tooSoon = await sendCode(user).expect(429);
    expect(tooSoon.body).toMatchObject({
      code: 'resend_too_soon',
      message: expect.stringMatching(/Please wait \d+ seconds/),
      retryAfterSeconds: expect.any(Number),
    });

    for (let i = 0; i < 4; i++) {
      await skipCooldown();
      await sendCode(user).expect(202);
    }
    await skipCooldown();
    await sendCode(user).expect(429);
    expect(sms.sent).toHaveLength(5);
  });

  it('does not count a code the SMS provider failed to send', async () => {
    const user = await registerUser(app, { phone: PHONE });
    sms.failNext = true;
    await sendCode(user).expect(503);
    expect(await app.get(PrismaService).smsCode.count()).toBe(0);
    await sendCode(user).expect(202);
  });

  it('requires verifying again after the number changes', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    await confirm(user, sms.lastCode(PHONE)).expect(200);

    const updated = await http()
      .patch('/v1/me')
      .set(auth(user))
      .send({ phone: '+255700000002' })
      .expect(200);
    expect(updated.body.phoneVerified).toBe(false);

    // Saving the same number again keeps it verified.
    await skipCooldown();
    await sendCode(user).expect(202);
    await confirm(user, sms.lastCode('+255700000002')).expect(200);
    const same = await http()
      .patch('/v1/me')
      .set(auth(user))
      .send({ phone: '+255700000002', fullName: 'New Name' })
      .expect(200);
    expect(same.body.phoneVerified).toBe(true);
  });

  it('refuses a code sent to the old number after a change', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await sendCode(user).expect(202);
    const code = sms.lastCode(PHONE);
    await http()
      .patch('/v1/me')
      .set(auth(user))
      .send({ phone: '+255700000003' })
      .expect(200);
    await confirm(user, code).expect(400);
  });

  it("keeps each user's codes to themselves", async () => {
    const owner = await registerUser(app, { phone: PHONE });
    const other = await registerUser(app, { phone: '+255700000004' });
    await sendCode(owner).expect(202);
    await confirm(other, sms.lastCode(PHONE)).expect(400);
  });

  it('validates the code format', async () => {
    const user = await registerUser(app, { phone: PHONE });
    await confirm(user, '12ab').expect(400);
  });
});
