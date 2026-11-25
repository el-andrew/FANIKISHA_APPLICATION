import { Injectable } from '@nestjs/common';
import {
  businessDayBounds,
  businessToday,
  toDateOnly,
} from '../common/dates.js';
import { toAmount } from '../common/money.js';
import { BusinessService } from '../business/business.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { dailyTarget, type Rule } from './daily-target.js';
import type { SavingRuleInput } from './saving-rule.schemas.js';

export interface TodayDto {
  /** Today in Tanzania, YYYY-MM-DD. */
  date: string;
  sales: number;
  expenses: number;
  profit: number;
  rule: Rule | null;
  /** What the rule asks to save today; 0 without a rule. */
  target: number;
  /** Deposits made today. */
  savedToday: number;
  /** Still to save to reach the target; never negative. */
  remaining: number;
}

@Injectable()
export class SavingRuleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly business: BusinessService,
  ) {}

  async get(userId: string): Promise<{ rule: Rule | null }> {
    const rule = await this.prisma.savingRule.findUnique({ where: { userId } });
    return { rule: rule ? { basis: rule.basis, percent: rule.percent } : null };
  }

  async set(userId: string, input: SavingRuleInput): Promise<{ rule: Rule }> {
    const rule = await this.prisma.savingRule.upsert({
      where: { userId },
      create: { userId, ...input },
      update: input,
    });
    return { rule: { basis: rule.basis, percent: rule.percent } };
  }

  async remove(userId: string): Promise<void> {
    await this.prisma.savingRule.deleteMany({ where: { userId } });
  }

  /** Today's sales and the saving target the rule sets from them. */
  async today(userId: string): Promise<TodayDto> {
    const today = businessToday();
    const { start, end } = businessDayBounds(today);
    const [{ rule }, summary, deposits] = await Promise.all([
      this.get(userId),
      this.business.summary(userId, { from: today, to: today }),
      this.prisma.deposit.aggregate({
        where: { userId, createdAt: { gte: start, lt: end } },
        _sum: { amount: true },
      }),
    ]);
    const savedToday = toAmount(deposits._sum.amount ?? 0n);
    const target = rule
      ? dailyTarget(rule, summary.sales, summary.expenses)
      : 0;
    return {
      date: toDateOnly(today),
      sales: summary.sales,
      expenses: summary.expenses,
      profit: summary.profit,
      rule,
      target,
      savedToday,
      remaining: Math.max(0, target - savedToday),
    };
  }
}
