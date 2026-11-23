import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import { Throttle } from '@nestjs/throttler';
import type { AuthUser } from '../auth/auth.types.js';
import {
  confirmCodeSchema,
  sendCodeSchema,
  type ConfirmCodeInput,
  type SendCodeInput,
} from './phone-verification.schemas.js';
import { PhoneVerificationService } from './phone-verification.service.js';

@Controller('me/phone/verification')
export class PhoneVerificationController {
  constructor(private readonly verification: PhoneVerificationService) {}

  /** Texts a code to the user's phone number. */
  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  send(
    @CurrentUser() user: AuthUser,
    @Body({ schema: sendCodeSchema }) body: SendCodeInput,
  ) {
    return this.verification.sendCode(user.id, body.language);
  }

  /** Checks the code; on success the phone number is marked verified. */
  @Post('confirm')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  confirm(
    @CurrentUser() user: AuthUser,
    @Body({ schema: confirmCodeSchema }) body: ConfirmCodeInput,
  ) {
    return this.verification.confirmCode(user.id, body.code);
  }
}
