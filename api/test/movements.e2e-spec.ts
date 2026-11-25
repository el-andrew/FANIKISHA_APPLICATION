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

let counter = 0;
const nextKey = () => `move-test-${String(++counter).padStart(6, '0')}`;

async function goal(user: TestUser, name: string, target: number) {
  const res = await http()
    .post('/v1/goals')
    .set(auth(user))
    .send({
      name,
      targetAmount: target,
      priority: 3,
      targetDate: daysFromNow(60),
    })
    .expect(201);
  return res.body.id as string;
}

const deposit = (user: TestUser, amount: number) =>
  http()
    .post('/v1/savings/deposits')
    .set(auth(user))
    .set('idempotency-key', nextKey())
    .send({ amount });

const transfer = (
  user: TestUser,
  from: string | null,
  to: string | null,
  amount: number,
  key = nextKey(),
) =>
  http()
    .post('/v1/savings/transfers')
    .set(auth(user))
    .set('idempotency-key', key)
    .send({ from, to, amount });

const withdraw = (
  user: TestUser,
  from: string | null,
  amount: number,
  key = nextKey(),
) =>
  http()
    .post('/v1/savings/withdrawals')
    .set(auth(user))
    .set('idempotency-key', key)
    .send({ from, amount, note: 'Bought it' });

const getGoal = async (user: TestUser, id: string) =>
  (await http().get(`/v1/goals/${id}`).set(auth(user)).expect(200)).body;

const summary = async (user: TestUser) =>
  (await http().get('/v1/savings/summary').set(auth(user)).expect(200)).body;

describe('moving money', () => {
  it('moves money between goals, keeping the total the same', async () => {
    const user = await registerUser(app);
    const fridge = await goal(user, 'Fridge', 100_000);
    await deposit(user, 60_000).expect(201);
    const van = await goal(user, 'Van', 500_000);

    const res = await transfer(user, fridge, van, 25_000).expect(201);
    expect(res.body).toMatchObject({
      kind: 'TRANSFER',
      amount: 25_000,
      from: { goalId: fridge, goalName: 'Fridge' },
      to: { goalId: van, goalName: 'Van' },
    });
    expect((await getGoal(user, fridge)).savedAmount).toBe(35_000);
    expect((await getGoal(user, van)).savedAmount).toBe(25_000);
    expect((await summary(user)).balance).toBe(60_000);
  });

  it('never takes more than is there', async () => {
    const user = await registerUser(app);
    const fridge = await goal(user, 'Fridge', 100_000);
    await deposit(user, 30_000).expect(201);
    const van = await goal(user, 'Van', 500_000);

    const res = await transfer(user, fridge, van, 30_001).expect(400);
    expect(res.body).toMatchObject({
      code: 'insufficient_funds',
      available: 30_000,
    });
    await withdraw(user, null, 1).expect(400);
  });

  it('completes a goal that a move fills', async () => {
    const user = await registerUser(app);
    const big = await goal(user, 'Big', 1_000_000);
    await deposit(user, 80_000).expect(201);
    const small = await goal(user, 'Small', 50_000);

    await transfer(user, big, small, 50_000).expect(201);
    expect(await getGoal(user, small)).toMatchObject({
      status: 'COMPLETED',
      savedAmount: 50_000,
    });
  });

  it('keeps a goal completed after its money is taken out', async () => {
    const user = await registerUser(app);
    const blender = await goal(user, 'Blender', 40_000);
    await deposit(user, 40_000).expect(201);
    expect((await getGoal(user, blender)).status).toBe('COMPLETED');

    const res = await withdraw(user, blender, 40_000).expect(201);
    expect(res.body).toMatchObject({
      kind: 'WITHDRAWAL',
      from: { goalId: blender, goalName: 'Blender' },
      to: null,
      note: 'Bought it',
    });
    expect(await getGoal(user, blender)).toMatchObject({
      status: 'COMPLETED',
      savedAmount: 0,
      progressPercent: 100,
      remainingAmount: 0,
    });
    expect(await summary(user)).toMatchObject({
      balance: 0,
      totalDeposited: 40_000,
      totalWithdrawn: 40_000,
    });

    // Renaming it later does not reopen it.
    await http()
      .patch(`/v1/goals/${blender}`)
      .set(auth(user))
      .send({ name: 'Kitchen blender' })
      .expect(200)
      .expect((r) => expect(r.body.status).toBe('COMPLETED'));
  });

  it('uses general savings like a goal', async () => {
    const user = await registerUser(app);
    await deposit(user, 20_000).expect(201); // no goals: all general savings
    expect((await summary(user)).unallocatedAmount).toBe(20_000);

    const stock = await goal(user, 'Stock', 100_000);
    await transfer(user, null, stock, 15_000).expect(201);
    await withdraw(user, null, 5_000).expect(201);
    expect(await summary(user)).toMatchObject({
      unallocatedAmount: 0,
      balance: 15_000,
    });

    await transfer(user, stock, null, 2_000).expect(201);
    expect((await summary(user)).unallocatedAmount).toBe(2_000);
  });

  it('frees money from archived goals but puts none into them', async () => {
    const user = await registerUser(app);
    const old = await goal(user, 'Old plan', 100_000);
    await deposit(user, 10_000).expect(201);
    await http().delete(`/v1/goals/${old}`).set(auth(user)).expect(200);
    const fresh = await goal(user, 'New plan', 100_000);

    await transfer(user, old, fresh, 10_000).expect(201);
    await transfer(user, fresh, old, 1_000).expect(400);
  });

  it('checks the request', async () => {
    const user = await registerUser(app);
    const a = await goal(user, 'A', 100_000);
    await transfer(user, a, a, 1_000).expect(400);
    await transfer(user, null, null, 1_000).expect(400);
    await http()
      .post('/v1/savings/withdrawals')
      .set(auth(user))
      .send({ from: a, amount: 1_000 })
      .expect(400); // no Idempotency-Key
  });

  it("can't touch another user's goals", async () => {
    const owner = await registerUser(app);
    const other = await registerUser(app);
    const theirs = await goal(owner, 'Theirs', 100_000);
    await deposit(owner, 10_000).expect(201);
    const mine = await goal(other, 'Mine', 100_000);

    await transfer(other, theirs, mine, 1_000).expect(404);
    await withdraw(other, theirs, 1_000).expect(404);
    expect((await getGoal(owner, theirs)).savedAmount).toBe(10_000);
  });

  it('records a retried request once', async () => {
    const user = await registerUser(app);
    const a = await goal(user, 'A', 100_000);
    await deposit(user, 50_000).expect(201);

    const first = await withdraw(user, a, 10_000, 'same-key-0001').expect(201);
    const again = await withdraw(user, a, 10_000, 'same-key-0001').expect(201);
    expect(again.body.id).toBe(first.body.id);
    expect((await getGoal(user, a)).savedAmount).toBe(40_000);
    await withdraw(user, a, 11_000, 'same-key-0001').expect(422);
  });

  it('never overdraws when withdrawals arrive at once', async () => {
    const user = await registerUser(app);
    const a = await goal(user, 'A', 1_000_000);
    await deposit(user, 50_000).expect(201);

    const results = await Promise.all(
      Array.from({ length: 10 }, () => withdraw(user, a, 10_000)),
    );
    expect(results.filter((r) => r.status === 201)).toHaveLength(5);
    expect(results.filter((r) => r.status === 400)).toHaveLength(5);
    expect((await getGoal(user, a)).savedAmount).toBe(0);
  });

  it('runs deposits and moves together without deadlocks', async () => {
    const user = await registerUser(app);
    const a = await goal(user, 'A', 10_000_000);
    const b = await goal(user, 'B', 10_000_000);
    await deposit(user, 100_000).expect(201);

    const results = await Promise.all(
      Array.from({ length: 12 }, (_, i) =>
        i % 2 === 0 ? deposit(user, 1_000) : transfer(user, a, b, 1_000),
      ),
    );
    expect(results.map((r) => r.status).every((s) => s === 201)).toBe(true);
    expect((await summary(user)).balance).toBe(106_000);
  });
});

describe('activity', () => {
  it('lists deposits, transfers and withdrawals, newest first, page by page', async () => {
    const user = await registerUser(app);
    const a = await goal(user, 'A', 1_000_000);
    await deposit(user, 30_000).expect(201);
    const b = await goal(user, 'B', 1_000_000);
    await transfer(user, a, b, 5_000).expect(201);
    await withdraw(user, b, 1_000).expect(201);
    await deposit(user, 2_000).expect(201);

    const page1 = await http()
      .get('/v1/savings/activity?limit=2')
      .set(auth(user))
      .expect(200);
    expect(page1.body.items.map((i: { kind: string }) => i.kind)).toEqual([
      'DEPOSIT',
      'WITHDRAWAL',
    ]);
    expect(page1.body.items[0]).toMatchObject({
      amount: 2_000,
      allocations: expect.any(Array),
    });

    const page2 = await http()
      .get(`/v1/savings/activity?limit=2&cursor=${page1.body.nextCursor}`)
      .set(auth(user))
      .expect(200);
    expect(page2.body.items.map((i: { kind: string }) => i.kind)).toEqual([
      'TRANSFER',
      'DEPOSIT',
    ]);
    expect(page2.body.nextCursor).toBeNull();
  });

  it('rejects a tampered cursor', async () => {
    const user = await registerUser(app);
    await http()
      .get('/v1/savings/activity?cursor=not-a-cursor')
      .set(auth(user))
      .expect(400);
  });
});
