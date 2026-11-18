import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { PasswordHasher, TokenService } from '@nestjs/authentication';
import { isUniqueViolation } from '../common/prisma-errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toUserDto, type UserDto } from './user.mapper.js';
import type {
  ChangePasswordInput,
  UpdateProfileInput,
} from './users.schemas.js';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  async getProfile(userId: string): Promise<UserDto> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    return toUserDto(user);
  }

  async updateProfile(
    userId: string,
    input: UpdateProfileInput,
  ): Promise<UserDto> {
    try {
      const user = await this.prisma.user.update({
        where: { id: userId },
        data: input,
      });
      return toUserDto(user);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException('This phone number is already in use');
      }
      throw error;
    }
  }

  /** Changes the password and signs the user out on every device. */
  async changePassword(
    userId: string,
    input: ChangePasswordInput,
  ): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const valid = await this.hasher.verify(
      input.currentPassword,
      user?.passwordHash,
    );
    if (!user || !valid) {
      throw new UnauthorizedException('Current password is incorrect');
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: await this.hasher.hash(input.newPassword) },
    });
    await this.tokens.revokeAll(userId);
  }
}
