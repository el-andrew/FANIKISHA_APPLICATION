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

describe('health', () => {
  it('reports the API and database as up', async () => {
    await http().get('/health').expect(200, { status: 'ok', database: 'up' });
  });
});

describe('authentication', () => {
  it('registers a user without exposing the password hash', async () => {
    const res = await http()
      .post('/v1/auth/register')
      .send({
        email: 'Asha@Example.com',
        password: 'a strong password',
        fullName: 'Asha Mwakyusa',
        phone: '+255712345678',
        businessName: 'Asha Duka',
      })
      .expect(201);

    expect(res.body.user).toMatchObject({
      email: 'asha@example.com',
      phone: '+255712345678',
      businessName: 'Asha Duka',
    });
    expect(res.body.user).not.toHaveProperty('passwordHash');
    expect(res.body).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
      expiresIn: 900,
    });
  });

  it('rejects a second account with the same email, ignoring case', async () => {
    await registerUser(app, { email: 'owner@example.com' });
    await http()
      .post('/v1/auth/register')
      .send({
        email: 'OWNER@example.com',
        password: 'another password',
        fullName: 'Someone Else',
      })
      .expect(409);
  });

  it('rejects invalid registration data with field messages', async () => {
    const res = await http()
      .post('/v1/auth/register')
      .send({ email: 'not-an-email', password: 'short', fullName: 'A' })
      .expect(400);
    expect(res.body.message).toEqual(
      expect.arrayContaining([
        expect.stringMatching(/^email:/),
        expect.stringMatching(/^password:/),
        expect.stringMatching(/^fullName:/),
      ]),
    );
  });

  it('logs in with the right password only', async () => {
    const user = await registerUser(app);
    await http()
      .post('/v1/auth/login')
      .send({ email: user.email, password: 'wrong password' })
      .expect(401);
    await http()
      .post('/v1/auth/login')
      .send({ email: 'nobody@example.com', password: user.password })
      .expect(401);
    const res = await http()
      .post('/v1/auth/login')
      .send({ email: user.email.toUpperCase(), password: user.password })
      .expect(200);
    expect(res.body.user.id).toBe(user.id);
  });

  it('requires a valid access token on protected routes', async () => {
    await http().get('/v1/me').expect(401);
    await http()
      .get('/v1/me')
      .set('authorization', 'Bearer not-a-token')
      .expect(401);
    const user = await registerUser(app);
    const res = await http().get('/v1/me').set(auth(user)).expect(200);
    expect(res.body.id).toBe(user.id);
  });

  it('rotates refresh tokens and signs the device out when one is reused', async () => {
    const user = await registerUser(app);
    const first = await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(200);
    expect(first.body.refreshToken).not.toBe(user.refreshToken);

    // Replaying the spent token looks like theft: the whole family is revoked.
    await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(401);
    await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: first.body.refreshToken })
      .expect(401);
  });

  it('logs out by revoking the refresh token', async () => {
    const user = await registerUser(app);
    await http()
      .post('/v1/auth/logout')
      .send({ refreshToken: user.refreshToken })
      .expect(204);
    await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(401);
  });
});

describe('profile', () => {
  it('updates the profile', async () => {
    const user = await registerUser(app);
    const res = await http()
      .patch('/v1/me')
      .set(auth(user))
      .send({ businessName: 'Mama Lishe Kitchen', phone: '+255700000001' })
      .expect(200);
    expect(res.body).toMatchObject({
      businessName: 'Mama Lishe Kitchen',
      phone: '+255700000001',
    });
  });

  it('changes the password and signs out every device', async () => {
    const user = await registerUser(app);
    await http()
      .post('/v1/me/password')
      .set(auth(user))
      .send({ currentPassword: 'wrong', newPassword: 'brand new password' })
      .expect(401);
    await http()
      .post('/v1/me/password')
      .set(auth(user))
      .send({
        currentPassword: user.password,
        newPassword: 'brand new password',
      })
      .expect(204);

    await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(401);
    await http()
      .post('/v1/auth/login')
      .send({ email: user.email, password: 'brand new password' })
      .expect(200);
  });
});

describe('goals', () => {
  const newGoal = (overrides: Record<string, unknown> = {}) => ({
    name: 'New fridge',
    targetAmount: 1_200_000,
    priority: 4,
    targetDate: daysFromNow(120),
    ...overrides,
  });

  it('creates, lists, reads and updates goals', async () => {
    const user = await registerUser(app);
    const created = await http()
      .post('/v1/goals')
      .set(auth(user))
      .send(newGoal({ category: 'Equipment' }))
      .expect(201);
    expect(created.body).toMatchObject({
      name: 'New fridge',
      category: 'Equipment',
      targetAmount: 1_200_000,
      savedAmount: 0,
      progressPercent: 0,
      status: 'ACTIVE',
      daysLeft: expect.any(Number),
      dailyTargetAmount: expect.any(Number),
    });

    const list = await http().get('/v1/goals').set(auth(user)).expect(200);
    expect(list.body).toHaveLength(1);

    const updated = await http()
      .patch(`/v1/goals/${created.body.id}`)
      .set(auth(user))
      .send({ priority: 5, name: 'Display fridge' })
      .expect(200);
    expect(updated.body).toMatchObject({ priority: 5, name: 'Display fridge' });
  });

  it('rejects a target date that is not after the start date', async () => {
    const user = await registerUser(app);
    await http()
      .post('/v1/goals')
      .set(auth(user))
      .send(newGoal({ startDate: daysFromNow(10), targetDate: daysFromNow(5) }))
      .expect(400);
  });

  it("hides other users' goals", async () => {
    const owner = await registerUser(app);
    const other = await registerUser(app);
    const goal = await http()
      .post('/v1/goals')
      .set(auth(owner))
      .send(newGoal())
      .expect(201);

    await http().get(`/v1/goals/${goal.body.id}`).set(auth(other)).expect(404);
    await http()
      .patch(`/v1/goals/${goal.body.id}`)
      .set(auth(other))
      .send({ priority: 1 })
      .expect(404);
    const list = await http().get('/v1/goals').set(auth(other)).expect(200);
    expect(list.body).toEqual([]);
  });

  it('archives a goal so it receives no further deposits', async () => {
    const user = await registerUser(app);
    const goal = await http()
      .post('/v1/goals')
      .set(auth(user))
      .send(newGoal())
      .expect(201);
    const archived = await http()
      .delete(`/v1/goals/${goal.body.id}`)
      .set(auth(user))
      .expect(200);
    expect(archived.body.status).toBe('ARCHIVED');

    const deposit = await http()
      .post('/v1/savings/deposits')
      .set(auth(user))
      .set('idempotency-key', 'after-archive-1')
      .send({ amount: 10_000 })
      .expect(201);
    expect(deposit.body.allocations).toEqual([]);
    expect(deposit.body.unallocatedAmount).toBe(10_000);
  });
});

describe('deposits', () => {
  async function createGoal(
    user: TestUser,
    name: string,
    targetAmount: number,
    priority: number,
    days: number,
  ): Promise<string> {
    const res = await http()
      .post('/v1/goals')
      .set(auth(user))
      .send({ name, targetAmount, priority, targetDate: daysFromNow(days) })
      .expect(201);
    return res.body.id;
  }

  function deposit(user: TestUser, key: string, amount: number, note?: string) {
    return http()
      .post('/v1/savings/deposits')
      .set(auth(user))
      .set('idempotency-key', key)
      .send({ amount, note });
  }

  it('splits a deposit across goals by priority and urgency', async () => {
    const user = await registerUser(app);
    const high = await createGoal(user, 'Rent', 300_000, 5, 30);
    const low = await createGoal(user, 'Holiday', 300_000, 1, 30);

    const res = await deposit(
      user,
      'split-0001',
      60_000,
      'Weekly sales',
    ).expect(201);
    expect(res.body).toMatchObject({ amount: 60_000, unallocatedAmount: 0 });
    const byGoal = Object.fromEntries(
      res.body.allocations.map((a: { goalId: string; amount: number }) => [
        a.goalId,
        a.amount,
      ]),
    );
    expect(byGoal).toEqual({ [high]: 50_000, [low]: 10_000 });

    const rent = await http()
      .get(`/v1/goals/${high}`)
      .set(auth(user))
      .expect(200);
    expect(rent.body.savedAmount).toBe(50_000);
  });

  it('previews a split without saving anything', async () => {
    const user = await registerUser(app);
    const goal = await createGoal(user, 'Rent', 300_000, 5, 30);

    const preview = await http()
      .post('/v1/savings/deposits/preview')
      .set(auth(user))
      .send({ amount: 40_000 })
      .expect(200);
    expect(preview.body).toEqual({
      amount: 40_000,
      unallocatedAmount: 0,
      allocations: [{ goalId: goal, goalName: 'Rent', amount: 40_000 }],
    });

    const summary = await http()
      .get('/v1/savings/summary')
      .set(auth(user))
      .expect(200);
    expect(summary.body.depositCount).toBe(0);
  });

  it('records a retried request only once', async () => {
    const user = await registerUser(app);
    await createGoal(user, 'Rent', 300_000, 3, 30);

    const first = await deposit(user, 'retry-0001', 20_000).expect(201);
    const retry = await deposit(user, 'retry-0001', 20_000).expect(201);
    expect(retry.body.id).toBe(first.body.id);

    await deposit(user, 'retry-0001', 25_000).expect(422);

    const summary = await http()
      .get('/v1/savings/summary')
      .set(auth(user))
      .expect(200);
    expect(summary.body).toMatchObject({
      totalDeposited: 20_000,
      depositCount: 1,
    });
  });

  it('requires an Idempotency-Key header', async () => {
    const user = await registerUser(app);
    await http()
      .post('/v1/savings/deposits')
      .set(auth(user))
      .send({ amount: 1_000 })
      .expect(400);
  });

  it('completes a goal when it is filled and keeps the excess as general savings', async () => {
    const user = await registerUser(app);
    const goal = await createGoal(user, 'Scale', 15_000, 3, 10);

    const res = await deposit(user, 'fill-0001', 20_000).expect(201);
    expect(res.body.allocations).toEqual([
      { goalId: goal, goalName: 'Scale', amount: 15_000 },
    ]);
    expect(res.body.unallocatedAmount).toBe(5_000);

    const completed = await http()
      .get(`/v1/goals/${goal}`)
      .set(auth(user))
      .expect(200);
    expect(completed.body).toMatchObject({
      status: 'COMPLETED',
      progressPercent: 100,
      completedAt: expect.any(String),
    });

    const summary = await http()
      .get('/v1/savings/summary')
      .set(auth(user))
      .expect(200);
    expect(summary.body).toEqual({
      totalDeposited: 20_000,
      unallocatedAmount: 5_000,
      depositCount: 1,
      activeGoals: 0,
      completedGoals: 1,
    });
  });

  it('loses no money when deposits arrive at the same time', async () => {
    const user = await registerUser(app);
    const a = await createGoal(user, 'Stock', 10_000_000, 4, 90);
    const b = await createGoal(user, 'Van', 10_000_000, 2, 365);

    await Promise.all(
      Array.from({ length: 10 }, (_, i) =>
        deposit(user, `race-${String(i).padStart(4, '0')}`, 7_777).expect(201),
      ),
    );

    const goals = await http().get('/v1/goals').set(auth(user)).expect(200);
    const saved = goals.body
      .filter((g: { id: string }) => [a, b].includes(g.id))
      .reduce(
        (sum: number, g: { savedAmount: number }) => sum + g.savedAmount,
        0,
      );
    expect(saved).toBe(77_770);
  });

  it('pages through deposits newest first', async () => {
    const user = await registerUser(app);
    for (let i = 1; i <= 5; i++) {
      await deposit(user, `page-000${i}`, i * 1_000).expect(201);
    }
    const page1 = await http()
      .get('/v1/savings/deposits?limit=2')
      .set(auth(user))
      .expect(200);
    expect(page1.body.items.map((d: { amount: number }) => d.amount)).toEqual([
      5_000, 4_000,
    ]);
    const page2 = await http()
      .get(`/v1/savings/deposits?limit=2&cursor=${page1.body.nextCursor}`)
      .set(auth(user))
      .expect(200);
    expect(page2.body.items.map((d: { amount: number }) => d.amount)).toEqual([
      3_000, 2_000,
    ]);
  });

  it("hides other users' deposits", async () => {
    const owner = await registerUser(app);
    const other = await registerUser(app);
    const res = await deposit(owner, 'private-0001', 5_000).expect(201);

    await http()
      .get(`/v1/savings/deposits/${res.body.id}`)
      .set(auth(other))
      .expect(404);
    const list = await http()
      .get('/v1/savings/deposits')
      .set(auth(other))
      .expect(200);
    expect(list.body.items).toEqual([]);
  });
});
