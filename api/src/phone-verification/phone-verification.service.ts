import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { refuse } from '../sms-codes/sms-code.errors.js';
import { SmsCodeService } from '../sms-codes/sms-code.service.js';
import { smsTexts, type SmsLanguage } from '../sms-codes/verification-code.js';
import { toUserDto, type UserDto } from '../users/user.mapper.js';

export interface SentCode {
  phone: string;
  expiresAt: string;
  /** When a new code may be requested. */
  resendAvailableAt: string;
}

/** Confirms that a user's phone number is theirs with a one-time SMS code. */
@Injectable()
export class PhoneVerificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly codes: SmsCodeService,
  ) {}

  async sendCode(userId: string, language: SmsLanguage): Promise<SentCode> {
    const phone = await this.unverifiedPhone(userId);
    const issued = await this.codes.issue({
      userId,
      phone,
      purpose: 'VERIFY_PHONE',
      message: (code) => smsTexts.verifyPhone(code, language),
    });
    return {
      phone,
      expiresAt: issued.expiresAt.toISOString(),
      resendAvailableAt: issued.resendAvailableAt.toISOString(),
    };
  }

  async confirmCode(userId: string, code: string): Promise<UserDto> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.phone) {
      throw refuse('no_phone', 'Add a phone number to your profile first');
    }
    if (user.phoneVerifiedAt) return toUserDto(user);
    const phone = user.phone;

    const verified = await this.codes.consume({
      userId,
      phone,
      purpose: 'VERIFY_PHONE',
      code,
      onSuccess: async (tx) => {
        // The number must still be the one the code was sent to.
        const updated = await tx.user.updateMany({
          where: { id: userId, phone },
          data: { phoneVerifiedAt: new Date() },
        });
        if (updated.count === 0) {
          throw refuse(
            'code_expired',
            'This code has expired. Please ask for a new one',
          );
        }
        return tx.user.findUniqueOrThrow({ where: { id: userId } });
      },
    });
    return toUserDto(verified);
  }

  private async unverifiedPhone(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.phone) {
      throw refuse('no_phone', 'Add a phone number to your profile first');
    }
    if (user.phoneVerifiedAt) {
      throw refuse('already_verified', 'This phone number is already verified');
    }
    return user.phone;
  }
}
