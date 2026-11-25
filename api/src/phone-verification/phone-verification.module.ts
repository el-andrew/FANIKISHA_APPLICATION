import { Module } from '@nestjs/common';
import { PhoneVerificationController } from './phone-verification.controller.js';
import { PhoneVerificationService } from './phone-verification.service.js';

@Module({
  controllers: [PhoneVerificationController],
  providers: [PhoneVerificationService],
})
export class PhoneVerificationModule {}
