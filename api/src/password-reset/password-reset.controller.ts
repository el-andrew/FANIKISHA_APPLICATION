import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Public } from '@nestjs/authentication';
import { Throttle } from '@nestjs/throttler';
import {
  confirmResetSchema,
  requestResetSchema,
  type ConfirmResetInput,
  type RequestResetInput,
} from './password-reset.schemas.js';
import { PasswordResetService } from './password-reset.service.js';

@Public()
@Controller('auth/password-reset')
export class PasswordResetController {
  constructor(private readonly reset: PasswordResetService) {}

  /** Always answers 202, whether or not a code was sent. */
  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  request(@Body({ schema: requestResetSchema }) body: RequestResetInput) {
    this.reset.requestReset(body.email, body.language);
  }

  /** Sets the new password and signs the user in. */
  @Post('confirm')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  confirm(@Body({ schema: confirmResetSchema }) body: ConfirmResetInput) {
    return this.reset.confirmReset(body);
  }
}
