import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import { Throttle } from '@nestjs/throttler';
import type { AuthUser } from '../auth/auth.types.js';
import {
  changePasswordSchema,
  deleteAccountSchema,
  updateProfileSchema,
  type ChangePasswordInput,
  type DeleteAccountInput,
  type UpdateProfileInput,
} from './users.schemas.js';
import { UsersService } from './users.service.js';

@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  getProfile(@CurrentUser() user: AuthUser) {
    return this.users.getProfile(user.id);
  }

  @Patch()
  updateProfile(
    @CurrentUser() user: AuthUser,
    @Body({ schema: updateProfileSchema }) body: UpdateProfileInput,
  ) {
    return this.users.updateProfile(user.id, body);
  }

  @Post('password')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  async changePassword(
    @CurrentUser() user: AuthUser,
    @Body({ schema: changePasswordSchema }) body: ChangePasswordInput,
  ) {
    await this.users.changePassword(user.id, body);
  }

  /** Deletes the account and all its data. Needs the password. */
  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  async deleteAccount(
    @CurrentUser() user: AuthUser,
    @Body({ schema: deleteAccountSchema }) body: DeleteAccountInput,
  ) {
    await this.users.deleteAccount(user.id, body);
  }
}
