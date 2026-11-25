import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import type { AuthUser } from '../auth/auth.types.js';
import { idempotencyKeySchema } from '../savings/savings.schemas.js';
import {
  activityQuerySchema,
  transferSchema,
  withdrawalSchema,
  type ActivityQuery,
  type TransferInput,
  type WithdrawalInput,
} from './movements.schemas.js';
import { MovementsService } from './movements.service.js';

function requireKey(header: string | undefined): string {
  const key = idempotencyKeySchema.safeParse(header);
  if (!key.success) {
    throw new BadRequestException(
      'An Idempotency-Key header of 8 to 100 letters, digits, - or _ is required',
    );
  }
  return key.data;
}

@Controller('savings')
export class MovementsController {
  constructor(private readonly movements: MovementsService) {}

  /** Records money taken out of a goal or general savings. */
  @Post('withdrawals')
  withdraw(
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') key: string | undefined,
    @Body({ schema: withdrawalSchema }) body: WithdrawalInput,
  ) {
    return this.movements.withdraw(user.id, requireKey(key), body);
  }

  /** Moves money between goals and general savings. */
  @Post('transfers')
  transfer(
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') key: string | undefined,
    @Body({ schema: transferSchema }) body: TransferInput,
  ) {
    return this.movements.transfer(user.id, requireKey(key), body);
  }

  /** Deposits, withdrawals and transfers, newest first. */
  @Get('activity')
  activity(
    @CurrentUser() user: AuthUser,
    @Query({ schema: activityQuerySchema }) query: ActivityQuery,
  ) {
    return this.movements.activity(user.id, query);
  }
}
