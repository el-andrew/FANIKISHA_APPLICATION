import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import type { AuthUser } from '../auth/auth.types.js';
import {
  createDepositSchema,
  depositIdSchema,
  idempotencyKeySchema,
  listDepositsQuerySchema,
  type CreateDepositInput,
  type ListDepositsQuery,
} from './savings.schemas.js';
import { SavingsService } from './savings.service.js';

@Controller('savings')
export class SavingsController {
  constructor(private readonly savings: SavingsService) {}

  @Get('summary')
  summary(@CurrentUser() user: AuthUser) {
    return this.savings.getSummary(user.id);
  }

  @Post('deposits')
  createDeposit(
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body({ schema: createDepositSchema }) body: CreateDepositInput,
  ) {
    const key = idempotencyKeySchema.safeParse(idempotencyKey);
    if (!key.success) {
      throw new BadRequestException(
        'An Idempotency-Key header of 8 to 100 letters, digits, - or _ is required',
      );
    }
    return this.savings.createDeposit(user.id, key.data, body);
  }

  @Get('deposits')
  listDeposits(
    @CurrentUser() user: AuthUser,
    @Query({ schema: listDepositsQuerySchema }) query: ListDepositsQuery,
  ) {
    return this.savings.listDeposits(user.id, query);
  }

  @Get('deposits/:id')
  getDeposit(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: depositIdSchema }) id: string,
  ) {
    return this.savings.getDeposit(user.id, id);
  }
}
