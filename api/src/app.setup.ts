import {
  StandardSchemaValidationPipe,
  type INestApplication,
} from '@nestjs/common';
import helmet from 'helmet';

/** Shared by main.ts and the end-to-end tests, so both run the same app. */
export function configureApp(app: INestApplication): void {
  app.use(helmet());
  app.setGlobalPrefix('v1', { exclude: ['health'] });
  app.useGlobalPipes(new StandardSchemaValidationPipe());
  app.enableShutdownHooks();
}
