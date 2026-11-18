import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import type { AuthUser } from '../auth/auth.types.js';
import {
  changePasswordSchema,
  updateProfileSchema,
  type ChangePasswordInput,
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
  async changePassword(
    @CurrentUser() user: AuthUser,
    @Body({ schema: changePasswordSchema }) body: ChangePasswordInput,
  ) {
    await this.users.changePassword(user.id, body);
  }
}
