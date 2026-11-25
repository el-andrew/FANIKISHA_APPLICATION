import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

// Behind one proxy, as on Render. Set before the app (and its validated
// configuration) is loaded.
process.env.TRUST_PROXY_HOPS = '1';

describe('client addresses behind a proxy', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const { Test } = await import('@nestjs/testing');
    const { AppModule } = await import('../src/app.module.js');
    const { configureApp } = await import('../src/app.setup.js');
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication<INestApplication<App>>();
    // Shows the address rate limits are counted against.
    const express = app.getHttpAdapter().getInstance() as {
      get(
        path: string,
        handler: (
          req: { ip?: string },
          res: { json(body: unknown): void },
        ) => void,
      ): void;
    };
    express.get('/test/ip', (req, res) => res.json({ ip: req.ip }));
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  const ipFor = async (forwardedFor?: string) => {
    const req = request(app.getHttpServer()).get('/test/ip');
    if (forwardedFor) void req.set('X-Forwarded-For', forwardedFor);
    return ((await req.expect(200)).body as { ip: string }).ip;
  };

  it('uses the address the proxy saw', async () => {
    expect(await ipFor('203.0.113.7')).toBe('203.0.113.7');
  });

  it('ignores addresses the client made up', async () => {
    // The client sent "6.6.6.6"; the proxy appended the real address.
    expect(await ipFor('6.6.6.6, 203.0.113.7')).toBe('203.0.113.7');
    expect(await ipFor('6.6.6.6, 1.1.1.1, 203.0.113.7')).toBe('203.0.113.7');
  });

  it('without the header, the connecting address', async () => {
    expect(await ipFor()).toMatch(/127\.0\.0\.1$/);
  });
});
