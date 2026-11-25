import { HttpException, HttpStatus } from '@nestjs/common';

/** Why a code request was refused; the app translates these. */
export type SmsCodeErrorCode =
  | 'no_phone'
  | 'already_verified'
  | 'resend_too_soon'
  | 'daily_limit'
  | 'sms_failed'
  | 'code_expired'
  | 'code_incorrect'
  | 'too_many_attempts';

const STATUS: Record<SmsCodeErrorCode, HttpStatus> = {
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
export function refuse(
  code: SmsCodeErrorCode,
  message: string,
  details: Record<string, number> = {},
): HttpException {
  const status = STATUS[code];
  return new HttpException(
    { statusCode: status, message, code, ...details },
    status,
  );
}
