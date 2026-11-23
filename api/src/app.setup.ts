import {
  StandardSchemaValidationPipe,
  type INestApplication,
} from '@nestjs/common';
import helmet from 'helmet';

/** Shared by main.ts and the end-to-end tests, so both run the same app. */
export function configureApp(app: INestApplication): void {
  app.use(helmet());
  // Web pages and the health check live outside the versioned API.
  app.setGlobalPrefix('v1', {
    exclude: ['health', 'privacy', 'terms', 'account-deletion'],
  });
  app.useGlobalPipes(new StandardSchemaValidationPipe());
  app.enableShutdownHooks();
}
