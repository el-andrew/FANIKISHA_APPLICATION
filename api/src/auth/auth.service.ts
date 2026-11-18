import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import {
  PasswordHasher,
  TokenService,
  type TokenPair,
} from '@nestjs/authentication';
import { isUniqueViolation } from '../common/prisma-errors.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toUserDto, type UserDto } from '../users/user.mapper.js';
import type { LoginInput, RegisterInput } from './auth.schemas.js';

export interface AuthResponse extends TokenPair {
  user: UserDto;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  async register(input: RegisterInput): Promise<AuthResponse> {
    const passwordHash = await this.hasher.hash(input.password);
    try {
      const user = await this.prisma.user.create({
        data: {
          email: input.email,
          phone: input.phone,
          fullName: input.fullName,
          businessName: input.businessName,
          passwordHash,
        },
      });
      return { user: toUserDto(user), ...(await this.issue(user.id)) };
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException(
          'An account with this email or phone number already exists',
        );
      }
      throw error;
    }
  }

  async login(input: LoginInput): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({
      where: { email: input.email },
    });
    // verify() checks a dummy hash for unknown users, so the response time
    // does not reveal which emails have accounts.
    const valid = await this.hasher.verify(input.password, user?.passwordHash);
    if (!user || !valid) {
      throw new UnauthorizedException('Incorrect email or password');
    }
    if (this.hasher.needsRehash(user.passwordHash)) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: await this.hasher.hash(input.password) },
      });
    }
    return { user: toUserDto(user), ...(await this.issue(user.id)) };
  }

  /** Exchanges a refresh token for a new pair. A reused token signs the device out. */
  refresh(refreshToken: string): Promise<TokenPair> {
    return this.tokens.refresh(refreshToken);
  }

  /** Signs out one device. Unknown tokens are ignored, as RFC 7009 recommends. */
  async logout(refreshToken: string): Promise<void> {
    await this.tokens.revoke(refreshToken);
  }

  private issue(userId: string): Promise<TokenPair> {
    return this.tokens.issue(userId, {
      method: 'password',
      claims: { amr: ['pwd'] },
    });
  }
}
