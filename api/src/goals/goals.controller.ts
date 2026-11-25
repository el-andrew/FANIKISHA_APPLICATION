import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '@nestjs/authentication';
import type { AuthUser } from '../auth/auth.types.js';
import {
  createGoalSchema,
  goalIdSchema,
  listGoalsQuerySchema,
  updateGoalSchema,
  type CreateGoalInput,
  type ListGoalsQuery,
  type UpdateGoalInput,
} from './goals.schemas.js';
import { GoalsService } from './goals.service.js';

@Controller('goals')
export class GoalsController {
  constructor(private readonly goals: GoalsService) {}

  @Get()
  list(
    @CurrentUser() user: AuthUser,
    @Query({ schema: listGoalsQuerySchema }) query: ListGoalsQuery,
  ) {
    return this.goals.list(user.id, query);
  }

  @Post()
  create(
    @CurrentUser() user: AuthUser,
    @Body({ schema: createGoalSchema }) body: CreateGoalInput,
  ) {
    return this.goals.create(user.id, body);
  }

  @Get(':id')
  get(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: goalIdSchema }) id: string,
  ) {
    return this.goals.get(user.id, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: goalIdSchema }) id: string,
    @Body({ schema: updateGoalSchema }) body: UpdateGoalInput,
  ) {
    return this.goals.update(user.id, id, body);
  }

  /** Archives rather than deletes, so the savings history stays intact. */
  @Delete(':id')
  archive(
    @CurrentUser() user: AuthUser,
    @Param('id', { schema: goalIdSchema }) id: string,
  ) {
    return this.goals.archive(user.id, id);
  }
}
