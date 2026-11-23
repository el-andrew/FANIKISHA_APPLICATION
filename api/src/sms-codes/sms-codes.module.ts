import { Global, Module } from '@nestjs/common';
import { SmsCodeService } from './sms-code.service.js';

@Global()
@Module({
  providers: [SmsCodeService],
  exports: [SmsCodeService],
})
export class SmsCodesModule {}
