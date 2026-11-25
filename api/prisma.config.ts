import 'dotenv/config';
import { defineConfig } from 'prisma/config';
import { databaseUrl } from './src/config/database-url.js';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    // Migrations verify the server's certificate too (DATABASE_CA_CERT).
    url: process.env['DATABASE_URL']
      ? databaseUrl(
          process.env['DATABASE_URL'],
          process.env['DATABASE_CA_CERT'],
          'prisma-cli',
        )
      : undefined,
  },
});
