import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PasswordHasher, TokenService } from '@nestjs/authentication';
import { isUniqueViolation } from '../common/prisma-errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toUserDto, type UserDto } from './user.mapper.js';
import type {
  ChangePasswordInput,
  DeleteAccountInput,
  UpdateProfileInput,
} from './users.schemas.js';

/**
 * A wrong password on a signed-in request. 403, not 401: a 401 tells the app
 * its session expired, and it would refresh tokens and retry for nothing.
 */
function wrongPassword(): ForbiddenException {
  return new ForbiddenException({
    statusCode: 403,
    message: 'That password is not correct',
    code: 'wrong_password',
  });
}

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
      const user = await this.prisma.$transaction(async (tx) => {
        const current = await tx.user.findUnique({ where: { id: userId } });
        if (!current) throw new NotFoundException('User not found');
        // A new (or removed) number has to be verified again.
        const phoneChanged =
          input.phone !== undefined && input.phone !== current.phone;
        return tx.user.update({
          where: { id: userId },
          data: {
            ...input,
            ...(phoneChanged ? { phoneVerifiedAt: null } : {}),
          },
        });
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
    await this.checkPassword(userId, input.currentPassword);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: await this.hasher.hash(input.newPassword) },
    });
    await this.tokens.revokeAll(userId);
  }

  /**
   * Deletes the account and everything in it (goals, deposits, SMS codes),
   * and signs it out everywhere. Cannot be undone.
   */
  async deleteAccount(
    userId: string,
    input: DeleteAccountInput,
  ): Promise<void> {
    await this.checkPassword(userId, input.password);
    // Refresh tokens are kept by the authentication store, outside the user's
    // foreign keys: revoke them, then remove them.
    await this.tokens.revokeAll(userId);
    await this.prisma.$transaction([
      this.prisma.refreshToken.deleteMany({ where: { userId } }),
      this.prisma.user.delete({ where: { id: userId } }),
    ]);
  }

  private async checkPassword(userId: string, password: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const valid = await this.hasher.verify(password, user?.passwordHash);
    if (!user || !valid) throw wrongPassword();
  }
}
