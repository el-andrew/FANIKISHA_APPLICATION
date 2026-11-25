import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Public } from '@nestjs/authentication';
import { Throttle } from '@nestjs/throttler';
import {
  loginSchema,
  refreshTokenSchema,
  registerSchema,
  type LoginInput,
  type RefreshTokenInput,
  type RegisterInput,
} from './auth.schemas.js';
import { AuthService } from './auth.service.js';

@Public()
@Controller('auth')
// Stricter than the global limit: these routes are what attackers guess passwords against.
@Throttle({ default: { limit: 10, ttl: 60_000 } })
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body({ schema: registerSchema }) body: RegisterInput) {
    return this.auth.register(body);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body({ schema: loginSchema }) body: LoginInput) {
    return this.auth.login(body);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body({ schema: refreshTokenSchema }) body: RefreshTokenInput) {
    return this.auth.refresh(body.refreshToken);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body({ schema: refreshTokenSchema }) body: RefreshTokenInput) {
    await this.auth.logout(body.refreshToken);
  }
}
