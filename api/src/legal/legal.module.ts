import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module.js';
import { LegalController } from './legal.controller.js';

@Module({
  imports: [UsersModule],
  controllers: [LegalController],
})
export class LegalModule {}
