import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import {
  createTestApp,
  daysFromNow,
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

let keyCounter = 0;
function record(
  user: TestUser,
  body: Record<string, unknown>,
  key = `entry-${String(++keyCounter).padStart(6, '0')}`,
) {
  return http()
    .post('/v1/business/entries')
    .set(auth(user))
    .set('idempotency-key', key)
    .send(body);
}

/** The business day `offset` days from today, as the API sees it (Tanzania). */
function businessDay(offset = 0): string {
  const today = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Africa/Dar_es_Salaam',
  }).format(new Date());
  const d = new Date(`${today}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + offset);
  return d.toISOString().slice(0, 10);
}

describe('business entries', () => {
  it('records sales and expenses, dated today by default', async () => {
    const user = await registerUser(app);
    const sale = await record(user, { type: 'SALE', amount: 50_000 }).expect(
      201,
    );
    expect(sale.body).toMatchObject({
      type: 'SALE',
      amount: 50_000,
      category: null,
      occurredOn: businessDay(),
    });

    const expense = await record(user, {
      type: 'EXPENSE',
      amount: 12_000,
      category: 'Stock',
      note: 'Sugar and flour',
      occurredOn: businessDay(-1),
    }).expect(201);
    expect(expense.body).toMatchObject({
      category: 'Stock',
      note: 'Sugar and flour',
      occurredOn: businessDay(-1),
    });

    const list = await http()
      .get('/v1/business/entries')
      .set(auth(user))
      .expect(200);
    expect(list.body.items.map((e: { id: string }) => e.id)).toEqual([
      sale.body.id,
      expense.body.id,
    ]);
  });

  it('records a retried request once', async () => {
    const user = await registerUser(app);
    const first = await record(
      user,
      { type: 'SALE', amount: 9_000 },
      'retry-000001',
    ).expect(201);
    const again = await record(
      user,
      { type: 'SALE', amount: 9_000 },
      'retry-000001',
    ).expect(201);
    expect(again.body.id).toBe(first.body.id);
    await record(user, { type: 'SALE', amount: 9_500 }, 'retry-000001').expect(
      422,
    );
  });

  it('requires an Idempotency-Key and refuses future dates', async () => {
    const user = await registerUser(app);
    await http()
      .post('/v1/business/entries')
      .set(auth(user))
      .send({ type: 'SALE', amount: 1_000 })
      .expect(400);
    await record(user, {
      type: 'SALE',
      amount: 1_000,
      occurredOn: daysFromNow(3),
    }).expect(400);
  });

  it('filters by type and date, and pages', async () => {
    const user = await registerUser(app);
    for (let i = 0; i < 4; i++) {
      await record(user, {
        type: 'SALE',
        amount: 1_000 * (i + 1),
        occurredOn: businessDay(-i),
      }).expect(201);
    }
    await record(user, { type: 'EXPENSE', amount: 500 }).expect(201);

    const sales = await http()
      .get('/v1/business/entries?type=SALE')
      .set(auth(user))
      .expect(200);
    expect(sales.body.items).toHaveLength(4);

    const recent = await http()
      .get(`/v1/business/entries?from=${businessDay(-1)}&type=SALE`)
      .set(auth(user))
      .expect(200);
    expect(recent.body.items.map((e: { amount: number }) => e.amount)).toEqual([
      1_000, 2_000,
    ]);

    const page1 = await http()
      .get('/v1/business/entries?limit=3')
      .set(auth(user))
      .expect(200);
    expect(page1.body.items).toHaveLength(3);
    const page2 = await http()
      .get(`/v1/business/entries?limit=3&cursor=${page1.body.nextCursor}`)
      .set(auth(user))
      .expect(200);
    expect(page2.body.items).toHaveLength(2);
    expect(page2.body.nextCursor).toBeNull();
  });

  it('corrects and deletes entries', async () => {
    const user = await registerUser(app);
    const entry = await record(user, { type: 'SALE', amount: 10_000 }).expect(
      201,
    );

    const fixed = await http()
      .patch(`/v1/business/entries/${entry.body.id}`)
      .set(auth(user))
      .send({ amount: 11_000, note: 'Corrected', category: null })
      .expect(200);
    expect(fixed.body).toMatchObject({ amount: 11_000, note: 'Corrected' });

    await http()
      .delete(`/v1/business/entries/${entry.body.id}`)
      .set(auth(user))
      .expect(204);
    await http()
      .get(`/v1/business/entries/${entry.body.id}`)
      .set(auth(user))
      .expect(404);
  });

  it("keeps each owner's entries private", async () => {
    const owner = await registerUser(app);
    const other = await registerUser(app);
    const entry = await record(owner, { type: 'SALE', amount: 10_000 }).expect(
      201,
    );

    await http()
      .get(`/v1/business/entries/${entry.body.id}`)
      .set(auth(other))
      .expect(404);
    await http()
      .patch(`/v1/business/entries/${entry.body.id}`)
      .set(auth(other))
      .send({ amount: 1 })
      .expect(404);
    await http()
      .delete(`/v1/business/entries/${entry.body.id}`)
      .set(auth(other))
      .expect(404);
    const list = await http()
      .get('/v1/business/entries')
      .set(auth(other))
      .expect(200);
    expect(list.body.items).toEqual([]);
  });
});

describe('business summary', () => {
  it('adds up sales, expenses and profit per day', async () => {
    const user = await registerUser(app);
    await record(user, {
      type: 'SALE',
      amount: 40_000,
      occurredOn: businessDay(-2),
    }).expect(201);
    await record(user, {
      type: 'SALE',
      amount: 10_000,
      occurredOn: businessDay(-2),
    }).expect(201);
    await record(user, {
      type: 'EXPENSE',
      amount: 15_000,
      category: 'Stock',
      occurredOn: businessDay(-2),
    }).expect(201);
    await record(user, {
      type: 'EXPENSE',
      amount: 5_000,
      category: 'Transport',
    }).expect(201);
    await record(user, { type: 'EXPENSE', amount: 2_000 }).expect(201);
    // Outside the period: not counted.
    await record(user, {
      type: 'SALE',
      amount: 99_000,
      occurredOn: businessDay(-10),
    }).expect(201);

    const res = await http()
      .get(`/v1/business/summary?from=${businessDay(-2)}&to=${businessDay()}`)
      .set(auth(user))
      .expect(200);

    expect(res.body).toMatchObject({
      from: businessDay(-2),
      to: businessDay(),
      sales: 50_000,
      expenses: 22_000,
      profit: 28_000,
    });
    expect(res.body.days).toEqual([
      { date: businessDay(-2), sales: 50_000, expenses: 15_000 },
      { date: businessDay(-1), sales: 0, expenses: 0 },
      { date: businessDay(), sales: 0, expenses: 7_000 },
    ]);
    expect(res.body.expenseCategories).toEqual([
      { category: 'Stock', amount: 15_000 },
      { category: 'Transport', amount: 5_000 },
      { category: null, amount: 2_000 },
    ]);
  });

  it('shows a loss as negative profit', async () => {
    const user = await registerUser(app);
    await record(user, { type: 'EXPENSE', amount: 8_000 }).expect(201);
    const res = await http()
      .get(`/v1/business/summary?from=${businessDay()}&to=${businessDay()}`)
      .set(auth(user))
      .expect(200);
    expect(res.body.profit).toBe(-8_000);
  });

  it('checks the period', async () => {
    const user = await registerUser(app);
    await http()
      .get(`/v1/business/summary?from=${businessDay()}&to=${businessDay(-1)}`)
      .set(auth(user))
      .expect(400);
    await http()
      .get(`/v1/business/summary?from=${businessDay(-400)}&to=${businessDay()}`)
      .set(auth(user))
      .expect(400);
    await http().get('/v1/business/summary').set(auth(user)).expect(400);
  });
});
