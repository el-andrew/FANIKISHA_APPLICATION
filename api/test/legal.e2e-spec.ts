import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp, registerUser, resetDatabase } from './helpers.js';

let app: INestApplication<App>;
const http = () => request(app.getHttpServer());

beforeAll(async () => {
  app = await createTestApp();
});

beforeEach(async () => {
  await resetDatabase(app);
});

afterAll(async () => {
  await app.close();
});

describe('legal pages', () => {
  it('serves the privacy policy and terms in English and Kiswahili', async () => {
    const privacy = await http().get('/privacy').expect(200);
    expect(privacy.headers['content-type']).toMatch(/text\/html/);
    expect(privacy.text).toContain('<h1>Privacy policy</h1>');
    expect(privacy.text).toContain('Beem Africa');

    const sera = await http().get('/privacy?lang=sw').expect(200);
    expect(sera.text).toContain('<h1>Sera ya faragha</h1>');

    const terms = await http().get('/terms').expect(200);
    expect(terms.text).toContain('<h1>Terms of service</h1>');
    const masharti = await http().get('/terms?lang=sw').expect(200);
    expect(masharti.text).toContain('<h1>Masharti ya huduma</h1>');
  });

  it('falls back to English for an unknown language', async () => {
    const res = await http().get('/privacy?lang=fr').expect(200);
    expect(res.text).toContain('<html lang="en">');
  });

  it('lives outside the versioned API and needs no sign-in', async () => {
    await http().get('/v1/privacy').expect(404);
    await http().get('/account-deletion').expect(200);
  });
});

describe('account deletion page', () => {
  const submit = (fields: Record<string, string>) =>
    http().post('/account-deletion').type('form').send(fields);

  it('shows a form that posts to itself', async () => {
    const res = await http().get('/account-deletion?lang=sw').expect(200);
    expect(res.text).toContain(
      '<form method="post" action="/account-deletion">',
    );
    expect(res.text).toContain('Futa akaunti yangu');
  });

  it('deletes nothing when the password is wrong', async () => {
    const user = await registerUser(app);
    const res = await submit({
      email: user.email,
      password: 'wrong',
      lang: 'en',
    });
    expect(res.status).toBe(401);
    expect(res.text).toContain('do not match an account');
    expect(
      await app.get(PrismaService).user.count({ where: { id: user.id } }),
    ).toBe(1);
  });

  it('gives the same answer for an email with no account', async () => {
    const res = await submit({
      email: 'nobody@example.com',
      password: 'whatever',
      lang: 'en',
    });
    expect(res.status).toBe(401);
    expect(res.text).toContain('do not match an account');
  });

  it('deletes the account with the right email and password', async () => {
    const user = await registerUser(app);
    const res = await submit({
      email: user.email.toUpperCase(),
      password: user.password,
      lang: 'sw',
    });
    expect(res.status).toBe(200);
    expect(res.text).toContain('Akaunti yako imefutwa');
    expect(
      await app.get(PrismaService).user.count({ where: { id: user.id } }),
    ).toBe(0);
    await http()
      .post('/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(401);
  });

  it('asks again for a missing password, keeping the email', async () => {
    const res = await submit({ email: 'a@b.co', password: '', lang: 'en' });
    expect(res.status).toBe(400);
    expect(res.text).toContain('value="a@b.co"');
  });
});
