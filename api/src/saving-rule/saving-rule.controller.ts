import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Put,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import type { AuthUser } from '../auth/auth.types.js';
import {
  savingRuleSchema,
  type SavingRuleInput,
} from './saving-rule.schemas.js';
import { SavingRuleService } from './saving-rule.service.js';

@Controller('savings')
export class SavingRuleController {
  constructor(private readonly rules: SavingRuleService) {}

  @Get('rule')
  get(@CurrentUser() user: AuthUser) {
    return this.rules.get(user.id);
  }

  @Put('rule')
  set(
    @CurrentUser() user: AuthUser,
    @Body({ schema: savingRuleSchema }) body: SavingRuleInput,
  ) {
    return this.rules.set(user.id, body);
  }

  @Delete('rule')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@CurrentUser() user: AuthUser) {
    await this.rules.remove(user.id);
  }

  /** Today's sales, the rule's target and what is left to save. */
  @Get('today')
  today(@CurrentUser() user: AuthUser) {
    return this.rules.today(user.id);
  }
}
