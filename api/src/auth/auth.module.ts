import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { JwtAuthProvider } from './jwt-auth.provider.js';
import { PrismaRefreshTokenStore } from './prisma-refresh-token.store.js';

@Module({
  controllers: [AuthController],
  providers: [AuthService, JwtAuthProvider, PrismaRefreshTokenStore],
})
export class AuthModule {}
