import {
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import type { Env } from '../config/env.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { SMS_SENDER, type SmsSender } from '../sms/sms-sender.js';
import { toUserDto, type UserDto } from '../users/user.mapper.js';
import { CodeHasher, generateCode, smsText } from './verification-code.js';

export const CODE_TTL_MS = 10 * 60_000;
export const MAX_ATTEMPTS = 5;
export const RESEND_COOLDOWN_MS = 60_000;
export const MAX_SENDS_PER_DAY = 5;
const DAY_MS = 24 * 60 * 60_000;

export interface SentCode {
  phone: string;
  expiresAt: string;
  /** When a new code may be requested. */
  resendAvailableAt: string;
}

/** Why a verification request was refused; the app translates these. */
export type VerificationErrorCode =
  | 'no_phone'
  | 'already_verified'
  | 'resend_too_soon'
  | 'daily_limit'
  | 'sms_failed'
  | 'code_expired'
  | 'code_incorrect'
  | 'too_many_attempts';

const STATUS: Record<VerificationErrorCode, HttpStatus> = {
  no_phone: HttpStatus.BAD_REQUEST,
  already_verified: HttpStatus.CONFLICT,
  resend_too_soon: HttpStatus.TOO_MANY_REQUESTS,
  daily_limit: HttpStatus.TOO_MANY_REQUESTS,
  sms_failed: HttpStatus.SERVICE_UNAVAILABLE,
  code_expired: HttpStatus.BAD_REQUEST,
  code_incorrect: HttpStatus.BAD_REQUEST,
  too_many_attempts: HttpStatus.TOO_MANY_REQUESTS,
};

/** An error with an English `message` and a machine-readable `code`. */
function refuse(
  code: VerificationErrorCode,
  message: string,
  details: Record<string, number> = {},
): HttpException {
  const status = STATUS[code];
  return new HttpException(
    { statusCode: status, message, code, ...details },
    status,
  );
}

/**
 * Confirms that a user's phone number is theirs with a one-time SMS code.
 *
 * Limits protect users and the SMS budget: one code a minute and five a day
 * per account and per number; five guesses per code; codes expire after ten
 * minutes, and a new code replaces the previous one.
 */
@Injectable()
export class PhoneVerificationService {
  private static readonly logger = new Logger('PhoneVerification');
  private readonly hasher: CodeHasher;

  constructor(
    private readonly prisma: PrismaService,
    @Inject(SMS_SENDER) private readonly sms: SmsSender,
    config: ConfigService<Env, true>,
  ) {
    this.hasher = new CodeHasher(config.get('JWT_SECRET', { infer: true }));
  }

  async sendCode(userId: string, language: 'en' | 'sw'): Promise<SentCode> {
    const now = new Date();
    const code = generateCode();
    const id = randomUUID();

    const phone = await this.prisma.$transaction(async (tx) => {
      // One request per user at a time, so the limits below can't be raced.
      await tx.$queryRaw`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`;
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user) throw new NotFoundException('User not found');
      if (!user.phone) {
        throw refuse('no_phone', 'Add a phone number to your profile first');
      }
      if (user.phoneVerifiedAt) {
        throw refuse(
          'already_verified',
          'This phone number is already verified',
        );
      }

      const recent = await tx.phoneVerification.findMany({
        where: {
          OR: [{ userId }, { phone: user.phone }],
          createdAt: { gte: new Date(now.getTime() - DAY_MS) },
        },
        orderBy: { createdAt: 'desc' },
        select: { userId: true, phone: true, createdAt: true },
      });
      const mine = recent.filter((v) => v.userId === userId);
      const lastSent = mine[0]?.createdAt;
      if (lastSent && now.getTime() - lastSent.getTime() < RESEND_COOLDOWN_MS) {
        const wait = Math.ceil(
          (RESEND_COOLDOWN_MS - (now.getTime() - lastSent.getTime())) / 1000,
        );
        throw refuse(
          'resend_too_soon',
          `Please wait ${wait} seconds before asking for a new code`,
          { retryAfterSeconds: wait },
        );
      }
      if (
        mine.length >= MAX_SENDS_PER_DAY ||
        recent.filter((v) => v.phone === user.phone).length >= MAX_SENDS_PER_DAY
      ) {
        throw refuse(
          'daily_limit',
          'Too many codes requested today. Please try again tomorrow',
        );
      }

      // A new code replaces any earlier one.
      await tx.phoneVerification.updateMany({
        where: { userId, consumedAt: null },
        data: { consumedAt: now },
      });
      await tx.phoneVerification.create({
        data: {
          id,
          userId,
          phone: user.phone,
          codeHash: this.hasher.hash(id, code),
          expiresAt: new Date(now.getTime() + CODE_TTL_MS),
          createdAt: now,
        },
      });
      return user.phone;
    });

    try {
      await this.sms.send(phone, smsText(code, language));
    } catch (error) {
      // Not sent, so it doesn't count against the user's limits.
      await this.prisma.phoneVerification.delete({ where: { id } });
      PhoneVerificationService.logger.error(
        `Could not send a verification SMS: ${(error as Error).message}`,
      );
      throw refuse(
        'sms_failed',
        'We could not send the SMS. Please try again later',
      );
    }

    return {
      phone,
      expiresAt: new Date(now.getTime() + CODE_TTL_MS).toISOString(),
      resendAvailableAt: new Date(
        now.getTime() + RESEND_COOLDOWN_MS,
      ).toISOString(),
    };
  }

  async confirmCode(userId: string, code: string): Promise<UserDto> {
    const now = new Date();
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.phone) {
      throw refuse('no_phone', 'Add a phone number to your profile first');
    }
    if (user.phoneVerifiedAt) return toUserDto(user);

    const verification = await this.prisma.phoneVerification.findFirst({
      where: { userId, phone: user.phone, consumedAt: null },
      orderBy: { createdAt: 'desc' },
    });
    if (!verification || verification.expiresAt <= now) {
      throw refuse(
        'code_expired',
        'This code has expired. Please ask for a new one',
      );
    }

    // Count the attempt before checking it, in one conditional UPDATE, so
    // parallel guesses can't exceed the limit.
    const counted = await this.prisma.$queryRaw<{ attempts: number }[]>`
      UPDATE phone_verifications SET attempts = attempts + 1
      WHERE id = ${verification.id}::uuid
        AND attempts < ${MAX_ATTEMPTS}
        AND consumed_at IS NULL
      RETURNING attempts`;
    if (counted.length === 0) {
      throw refuse(
        'too_many_attempts',
        'Too many wrong codes. Please ask for a new one',
      );
    }

    if (!this.hasher.matches(verification.id, code, verification.codeHash)) {
      const left = MAX_ATTEMPTS - counted[0].attempts;
      if (left === 0) {
        throw refuse(
          'too_many_attempts',
          'Too many wrong codes. Please ask for a new one',
        );
      }
      throw refuse(
        'code_incorrect',
        `That code is not correct. ${left} ${left === 1 ? 'try' : 'tries'} left`,
        { triesLeft: left },
      );
    }

    const verified = await this.prisma.$transaction(async (tx) => {
      const consumed = await tx.phoneVerification.updateMany({
        where: { id: verification.id, consumedAt: null },
        data: { consumedAt: now },
      });
      // The number must still be the one the code was sent to.
      const updated = await tx.user.updateMany({
        where: { id: userId, phone: verification.phone },
        data: { phoneVerifiedAt: now },
      });
      if (consumed.count === 0 || updated.count === 0) {
        throw refuse(
          'code_expired',
          'This code has expired. Please ask for a new one',
        );
      }
      return tx.user.findUniqueOrThrow({ where: { id: userId } });
    });
    return toUserDto(verified);
  }
}
