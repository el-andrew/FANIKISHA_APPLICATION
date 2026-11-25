import { Module } from '@nestjs/common';
import { BusinessModule } from '../business/business.module.js';
import { SavingRuleController } from './saving-rule.controller.js';
import { SavingRuleService } from './saving-rule.service.js';

@Module({
  imports: [BusinessModule],
  controllers: [SavingRuleController],
  providers: [SavingRuleService],
})
export class SavingRuleModule {}
