import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { AuthenticationModule } from '@nestjs/authentication';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module.js';
import { validateEnv, type Env } from './config/env.js';
import { GoalsModule } from './goals/goals.module.js';
import { HealthController } from './health/health.controller.js';
import { PhoneVerificationModule } from './phone-verification/phone-verification.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { SavingsModule } from './savings/savings.module.js';
import { SmsModule } from './sms/sms.module.js';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: validateEnv,
      // Tests get their settings from the environment only, never from .env.
      ignoreEnvFile: process.env.NODE_ENV === 'test',
    }),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        throttlers: [{ ttl: 60_000, limit: 120 }],
        // Tests make many requests from one address.
        skipIf: () => config.get('NODE_ENV', { infer: true }) === 'test',
      }),
    }),
    AuthenticationModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        accessToken: {
          key: config.get('JWT_SECRET', { infer: true }),
          issuer: config.get('JWT_ISSUER', { infer: true }),
          audience: config.get('JWT_AUDIENCE', { infer: true }),
          ttl: '15m',
        },
        refreshToken: { ttl: '30d', absoluteTtl: '90d' },
        // Full-strength scrypt takes ~128 MiB per hash; tests use a cheaper setting.
        password:
          config.get('NODE_ENV', { infer: true }) === 'test'
            ? { logN: 10 }
            : undefined,
      }),
    }),
    PrismaModule,
    SmsModule,
    AuthModule,
    UsersModule,
    GoalsModule,
    SavingsModule,
    PhoneVerificationModule,
  ],
  controllers: [HealthController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
