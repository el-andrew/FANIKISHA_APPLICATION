import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import type { AuthUser } from '../auth/auth.types.js';
import { idempotencyKeySchema } from '../savings/savings.schemas.js';
import {
  createEntrySchema,
  entryIdSchema,
  listEntriesQuerySchema,
  summaryQuerySchema,
  updateEntrySchema,
  type CreateEntryInput,
  type ListEntriesQuery,
  type SummaryQuery,
  type UpdateEntryInput,
} from './business.schemas.js';
import { BusinessService } from './business.service.js';

/** The owner's daily sales and expenses. */
@Controller('business')
export class BusinessController {
  constructor(private readonly business: BusinessService) {}

  @Post('entries')
  create(
    @CurrentUser() user: AuthUser,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body({ schema: createEntrySchema }) body: CreateEntryInput,
  ) {
    const key = idempotencyKeySchema.safeParse(idempotencyKey);
    if (!key.success) {
      throw new BadRequestException(
        'An Idempotency-Key header of 8 to 100 letters, digits, - or _ is required',
      );
    }
    return this.business.create(user.id, key.data, body);
  }

  @Get('entries')
  list(
    @CurrentUser() user: AuthUser,
    @Query({ schema: listEntriesQuerySchema }) query: ListEntriesQuery,
  ) {
    return this.business.list(user.id, query);
  }

  @Get('entries/:id')
  get(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: entryIdSchema }) id: string,
  ) {
    return this.business.get(user.id, id);
  }

  @Patch('entries/:id')
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: entryIdSchema }) id: string,
    @Body({ schema: updateEntrySchema }) body: UpdateEntryInput,
  ) {
    return this.business.update(user.id, id, body);
  }

  @Delete('entries/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: entryIdSchema }) id: string,
  ) {
    await this.business.remove(user.id, id);
  }

  /** Sales, expenses and profit for a period, with daily totals. */
  @Get('summary')
  summary(
    @CurrentUser() user: AuthUser,
    @Query({ schema: summaryQuerySchema }) query: SummaryQuery,
  ) {
    return this.business.summary(user.id, query);
  }
}
