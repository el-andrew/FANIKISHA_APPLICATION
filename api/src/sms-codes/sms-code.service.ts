import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import type { Env } from '../config/env.js';
import type { Prisma, SmsCodePurpose } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { SMS_SENDER, type SmsSender } from '../sms/sms-sender.js';
import { refuse } from './sms-code.errors.js';
import { CodeHasher, generateCode } from './verification-code.js';

export const CODE_TTL_MS = 10 * 60_000;
export const MAX_ATTEMPTS = 5;
export const RESEND_COOLDOWN_MS = 60_000;
export const MAX_SENDS_PER_DAY = 5;
const DAY_MS = 24 * 60 * 60_000;

export interface IssuedCode {
  expiresAt: Date;
  /** When a new code may be requested. */
  resendAvailableAt: Date;
}

/**
 * One-time codes sent by SMS, for any purpose (phone verification, password
 * reset).
 *
 * Limits, per purpose: one code a minute and five a day per account and per
 * number; five guesses per code, counted atomically; codes expire after ten
 * minutes, and a new code replaces the previous one. Codes are stored only
 * as keyed hashes.
 */
@Injectable()
export class SmsCodeService {
  private static readonly logger = new Logger('SmsCodes');
  private readonly hasher: CodeHasher;

  constructor(
    private readonly prisma: PrismaService,
    @Inject(SMS_SENDER) private readonly sms: SmsSender,
    config: ConfigService<Env, true>,
  ) {
    this.hasher = new CodeHasher(config.get('JWT_SECRET', { infer: true }));
  }

  /** Creates a code and texts it to [phone], or throws if a limit is reached. */
  async issue(params: {
    userId: string;
    phone: string;
    purpose: SmsCodePurpose;
    message: (code: string) => string;
  }): Promise<IssuedCode> {
    const { userId, phone, purpose } = params;
    const now = new Date();
    const code = generateCode();
    const id = randomUUID();

    await this.prisma.$transaction(async (tx) => {
      // One request per user at a time, so the limits can't be raced.
      await tx.$queryRaw`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`;
      const recent = await tx.smsCode.findMany({
        where: {
          purpose,
          OR: [{ userId }, { phone }],
          createdAt: { gte: new Date(now.getTime() - DAY_MS) },
        },
        orderBy: { createdAt: 'desc' },
        select: { userId: true, phone: true, createdAt: true },
      });
      const mine = recent.filter((c) => c.userId === userId);
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
        recent.filter((c) => c.phone === phone).length >= MAX_SENDS_PER_DAY
      ) {
        throw refuse(
          'daily_limit',
          'Too many codes requested today. Please try again tomorrow',
        );
      }

      // A new code replaces any earlier one for the same purpose.
      await tx.smsCode.updateMany({
        where: { userId, purpose, consumedAt: null },
        data: { consumedAt: now },
      });
      await tx.smsCode.create({
        data: {
          id,
          userId,
          purpose,
          phone,
          codeHash: this.hasher.hash(id, code),
          expiresAt: new Date(now.getTime() + CODE_TTL_MS),
          createdAt: now,
        },
      });
    });

    try {
      await this.sms.send(phone, params.message(code));
    } catch (error) {
      // Not sent, so it doesn't count against the limits.
      await this.prisma.smsCode.delete({ where: { id } });
      SmsCodeService.logger.error(
        `Could not send an SMS code: ${(error as Error).message}`,
      );
      throw refuse(
        'sms_failed',
        'We could not send the SMS. Please try again later',
      );
    }

    return {
      expiresAt: new Date(now.getTime() + CODE_TTL_MS),
      resendAvailableAt: new Date(now.getTime() + RESEND_COOLDOWN_MS),
    };
  }

  /**
   * Checks [code] against the latest code sent to [phone] for [purpose]. If
   * it matches, marks it used and runs [onSuccess] in the same transaction.
   */
  async consume<T>(params: {
    userId: string;
    phone: string;
    purpose: SmsCodePurpose;
    code: string;
    onSuccess: (tx: Prisma.TransactionClient) => Promise<T>;
  }): Promise<T> {
    const { userId, phone, purpose, code } = params;
    const now = new Date();
    const expired = () =>
      refuse('code_expired', 'This code has expired. Please ask for a new one');

    const latest = await this.prisma.smsCode.findFirst({
      where: { userId, phone, purpose, consumedAt: null },
      orderBy: { createdAt: 'desc' },
    });
    if (!latest || latest.expiresAt <= now) throw expired();

    // Count the attempt before checking it, in one conditional UPDATE, so
    // parallel guesses can't exceed the limit.
    const counted = await this.prisma.$queryRaw<{ attempts: number }[]>`
      UPDATE sms_codes SET attempts = attempts + 1
      WHERE id = ${latest.id}::uuid
        AND attempts < ${MAX_ATTEMPTS}
        AND consumed_at IS NULL
      RETURNING attempts`;
    const tooMany = () =>
      refuse(
        'too_many_attempts',
        'Too many wrong codes. Please ask for a new one',
      );
    if (counted.length === 0) throw tooMany();

    if (!this.hasher.matches(latest.id, code, latest.codeHash)) {
      const left = MAX_ATTEMPTS - counted[0].attempts;
      if (left === 0) throw tooMany();
      throw refuse(
        'code_incorrect',
        `That code is not correct. ${left} ${left === 1 ? 'try' : 'tries'} left`,
        { triesLeft: left },
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const used = await tx.smsCode.updateMany({
        where: { id: latest.id, consumedAt: null },
        data: { consumedAt: now },
      });
      if (used.count === 0) throw expired();
      return params.onSuccess(tx);
    });
  }
}
