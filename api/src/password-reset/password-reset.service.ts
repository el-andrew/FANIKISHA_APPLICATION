import { HttpException, Injectable, Logger } from '@nestjs/common';
import { PasswordHasher, TokenService } from '@nestjs/authentication';
import type { AuthResponse } from '../auth/auth.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { refuse } from '../sms-codes/sms-code.errors.js';
import { SmsCodeService } from '../sms-codes/sms-code.service.js';
import { smsTexts, type SmsLanguage } from '../sms-codes/verification-code.js';
import { toUserDto } from '../users/user.mapper.js';
import type { ConfirmResetInput } from './password-reset.schemas.js';

/**
 * Resets a forgotten password with a code texted to the account's verified
 * phone number. Only verified numbers are used: a code sent to an
 * unconfirmed (perhaps mistyped) number could hand the account to a stranger.
 */
@Injectable()
export class PasswordResetService {
  private static readonly logger = new Logger('PasswordReset');

  constructor(
    private readonly prisma: PrismaService,
    private readonly codes: SmsCodeService,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  /**
   * Texts a reset code if [email] belongs to an account with a verified
   * phone. Returns the same way, and as quickly, whether or not it does, so
   * the endpoint does not reveal who has an account.
   */
  requestReset(email: string, language: SmsLanguage): void {
    void this.sendInBackground(email, language);
  }

  async confirmReset(input: ConfirmResetInput): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({
      where: { email: input.email },
    });
    if (!user?.phone || !user.phoneVerifiedAt) {
      // Same answer as for a wrong or old code: nothing about the account.
      throw refuse(
        'code_expired',
        'This code has expired. Please ask for a new one',
      );
    }
    const passwordHash = await this.hasher.hash(input.newPassword);

    const updated = await this.codes.consume({
      userId: user.id,
      phone: user.phone,
      purpose: 'RESET_PASSWORD',
      code: input.code,
      onSuccess: (tx) =>
        tx.user.update({ where: { id: user.id }, data: { passwordHash } }),
    });

    // Whoever had the old password is signed out everywhere.
    await this.tokens.revokeAll(user.id);
    const tokens = await this.tokens.issue(user.id, {
      method: 'password-reset',
      claims: { amr: ['sms'] },
    });
    return { user: toUserDto(updated), ...tokens };
  }

  private async sendInBackground(
    email: string,
    language: SmsLanguage,
  ): Promise<void> {
    try {
      const user = await this.prisma.user.findUnique({ where: { email } });
      if (!user?.phone || !user.phoneVerifiedAt) return;
      await this.codes.issue({
        userId: user.id,
        phone: user.phone,
        purpose: 'RESET_PASSWORD',
        message: (code) => smsTexts.resetPassword(code, language),
      });
    } catch (error) {
      // Limits and SMS failures can't be reported without revealing that
      // the account exists; the user can try again later.
      const reason =
        error instanceof HttpException
          ? JSON.stringify(error.getResponse())
          : (error as Error).message;
      PasswordResetService.logger.warn(`Reset code not sent: ${reason}`);
    }
  }
}
