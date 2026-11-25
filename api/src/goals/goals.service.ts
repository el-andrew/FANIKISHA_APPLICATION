import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { Goal, GoalStatus } from '../generated/prisma/client.js';
import { businessToday } from '../common/dates.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toGoalDto, type GoalDto } from './goal.mapper.js';
import type {
  CreateGoalInput,
  ListGoalsQuery,
  UpdateGoalInput,
} from './goals.schemas.js';

@Injectable()
export class GoalsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: ListGoalsQuery): Promise<GoalDto[]> {
    const goals = await this.prisma.goal.findMany({
      where: { userId, status: query.status },
      orderBy: [{ status: 'asc' }, { targetDate: 'asc' }, { createdAt: 'asc' }],
    });
    return goals.map((goal) => toGoalDto(goal));
  }

  async get(userId: string, goalId: string): Promise<GoalDto> {
    return toGoalDto(await this.findOwned(userId, goalId));
  }

  async create(userId: string, input: CreateGoalInput): Promise<GoalDto> {
    const startDate = input.startDate ?? businessToday();
    assertDateOrder(startDate, input.targetDate);
    const goal = await this.prisma.goal.create({
      data: {
        userId,
        name: input.name,
        category: input.category,
        targetAmount: BigInt(input.targetAmount),
        priority: input.priority,
        startDate,
        targetDate: input.targetDate,
      },
    });
    return toGoalDto(goal);
  }

  async update(
    userId: string,
    goalId: string,
    input: UpdateGoalInput,
  ): Promise<GoalDto> {
    return this.prisma.$transaction(async (tx) => {
      // Lock the row so a deposit cannot change savedAmount between the
      // check below and the write.
      await tx.$queryRaw`SELECT id FROM goals WHERE id = ${goalId}::uuid AND user_id = ${userId}::uuid FOR UPDATE`;
      const goal = await tx.goal.findFirst({ where: { id: goalId, userId } });
      if (!goal) throw new NotFoundException('Goal not found');
      if (goal.status === 'ARCHIVED') {
        throw new BadRequestException('Archived goals cannot be changed');
      }

      const targetAmount =
        input.targetAmount !== undefined
          ? BigInt(input.targetAmount)
          : goal.targetAmount;
      if (targetAmount < goal.savedAmount) {
        throw new BadRequestException(
          'Target amount cannot be less than the amount already saved',
        );
      }
      if (input.targetDate) assertDateOrder(goal.startDate, input.targetDate);

      // Only a new target changes completion: raising the target of a
      // completed goal reopens it. Other edits leave it as it is, even if its
      // money has since been taken out.
      const status: GoalStatus =
        input.targetAmount === undefined
          ? goal.status
          : goal.savedAmount >= targetAmount
            ? 'COMPLETED'
            : 'ACTIVE';
      const updated = await tx.goal.update({
        where: { id: goal.id },
        data: {
          name: input.name,
          category: input.category,
          priority: input.priority,
          targetDate: input.targetDate,
          targetAmount,
          status,
          completedAt:
            status === 'COMPLETED' ? (goal.completedAt ?? new Date()) : null,
        },
      });
      return toGoalDto(updated);
    });
  }

  /**
   * Stops a goal from receiving new deposits. Money already saved stays
   * recorded against it; withdrawals are a later feature.
   */
  async archive(userId: string, goalId: string): Promise<GoalDto> {
    const goal = await this.findOwned(userId, goalId);
    const updated = await this.prisma.goal.update({
      where: { id: goal.id },
      data: { status: 'ARCHIVED' },
    });
    return toGoalDto(updated);
  }

  /** Other users' goals are reported as not found, never as forbidden. */
  private async findOwned(userId: string, goalId: string): Promise<Goal> {
    const goal = await this.prisma.goal.findFirst({
      where: { id: goalId, userId },
    });
    if (!goal) throw new NotFoundException('Goal not found');
    return goal;
  }
}

function assertDateOrder(startDate: Date, targetDate: Date): void {
  if (targetDate <= startDate) {
    throw new BadRequestException('Target date must be after the start date');
  }
}
