import {
  StandardSchemaValidationPipe,
  type INestApplication,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import type { Env } from './config/env.js';

/** Shared by main.ts and the end-to-end tests, so both run the same app. */
export function configureApp(app: INestApplication): void {
  const hops = app
    .get<ConfigService<Env, true>>(ConfigService)
    .get('TRUST_PROXY_HOPS', { infer: true });
  if (hops > 0) {
    // Express then takes the client's address from X-Forwarded-For, but only
    // the entry added by the last trusted proxy: earlier entries are
    // whatever the client sent.
    const express = app.getHttpAdapter().getInstance() as {
      set(setting: string, value: unknown): void;
    };
    express.set('trust proxy', hops);
  }
  app.use(helmet());
  // Web pages and the health check live outside the versioned API.
  app.setGlobalPrefix('v1', {
    exclude: ['health', 'privacy', 'terms', 'account-deletion'],
  });
  app.useGlobalPipes(new StandardSchemaValidationPipe());
  app.enableShutdownHooks();
}
