import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import {
  createTestApp,
  registerUser,
  resetDatabase,
  type TestUser,
} from './helpers.js';

let app: INestApplication<App>;
const http = () => request(app.getHttpServer());
const auth = (user: TestUser) => ({
  authorization: `Bearer ${user.accessToken}`,
});

beforeAll(async () => {
  app = await createTestApp();
});

beforeEach(async () => {
  await resetDatabase(app);
});

afterAll(async () => {
  await app.close();
});

let key = 0;
const nextKey = () => `rule-test-${String(++key).padStart(6, '0')}`;

const recordEntry = (user: TestUser, type: string, amount: number) =>
  http()
    .post('/v1/business/entries')
    .set(auth(user))
    .set('idempotency-key', nextKey())
    .send({ type, amount })
    .expect(201);

const deposit = (user: TestUser, amount: number) =>
  http()
    .post('/v1/savings/deposits')
    .set(auth(user))
    .set('idempotency-key', nextKey())
    .send({ amount })
    .expect(201);

const setRule = (user: TestUser, basis: string, percent: number) =>
  http().put('/v1/savings/rule').set(auth(user)).send({ basis, percent });

const today = (user: TestUser) =>
  http().get('/v1/savings/today').set(auth(user)).expect(200);

describe('saving rule', () => {
  it('starts with no rule and no target', async () => {
    const user = await registerUser(app);
    await http()
      .get('/v1/savings/rule')
      .set(auth(user))
      .expect(200, { rule: null });
    const res = await today(user);
    expect(res.body).toMatchObject({ rule: null, target: 0, remaining: 0 });
  });

  it("turns today's sales into a saving target", async () => {
    const user = await registerUser(app);
    await setRule(user, 'SALES', 10).expect(200, {
      rule: { basis: 'SALES', percent: 10 },
    });
    await recordEntry(user, 'SALE', 100_000);
    await recordEntry(user, 'SALE', 20_000);
    await recordEntry(user, 'EXPENSE', 35_000);
    await deposit(user, 5_000);

    const res = await today(user);
    expect(res.body).toMatchObject({
      sales: 120_000,
      expenses: 35_000,
      profit: 85_000,
      rule: { basis: 'SALES', percent: 10 },
      target: 12_000,
      savedToday: 5_000,
      remaining: 7_000,
    });
  });

  it('can save a share of profit instead, and never asks for less than zero', async () => {
    const user = await registerUser(app);
    await setRule(user, 'PROFIT', 20).expect(200);
    await recordEntry(user, 'SALE', 120_000);
    await recordEntry(user, 'EXPENSE', 35_000);
    expect((await today(user)).body.target).toBe(17_000);

    await deposit(user, 20_000);
    expect((await today(user)).body).toMatchObject({
      savedToday: 20_000,
      remaining: 0,
    });
  });

  it('changes and removes the rule', async () => {
    const user = await registerUser(app);
    await setRule(user, 'SALES', 10).expect(200);
    await setRule(user, 'SALES', 15).expect(200);
    await http()
      .get('/v1/savings/rule')
      .set(auth(user))
      .expect(200, { rule: { basis: 'SALES', percent: 15 } });

    await http().delete('/v1/savings/rule').set(auth(user)).expect(204);
    await http()
      .get('/v1/savings/rule')
      .set(auth(user))
      .expect(200, { rule: null });
  });

  it('checks the percentage', async () => {
    const user = await registerUser(app);
    await setRule(user, 'SALES', 0).expect(400);
    await setRule(user, 'SALES', 101).expect(400);
    await setRule(user, 'SALES', 12.5).expect(400);
    await setRule(user, 'TURNOVER', 10).expect(400);
  });

  it("counts only the owner's own sales and deposits", async () => {
    const owner = await registerUser(app);
    const other = await registerUser(app);
    await setRule(owner, 'SALES', 10).expect(200);
    await setRule(other, 'SALES', 10).expect(200);
    await recordEntry(owner, 'SALE', 50_000);
    await deposit(owner, 1_000);

    expect((await today(other)).body).toMatchObject({
      sales: 0,
      target: 0,
      savedToday: 0,
    });
  });
});
