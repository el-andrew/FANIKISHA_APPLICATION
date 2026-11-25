import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Env } from '../config/env.js';
import { BeemSmsSender } from './beem-sms.sender.js';
import { LogSmsSender } from './log-sms.sender.js';
import { SMS_SENDER, type SmsSender } from './sms-sender.js';

@Global()
@Module({
  providers: [
    {
      provide: SMS_SENDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): SmsSender =>
        config.get('SMS_PROVIDER', { infer: true }) === 'beem'
          ? new BeemSmsSender({
              // Presence is enforced by the environment validation.
              apiKey: config.get('BEEM_API_KEY', { infer: true })!,
              secretKey: config.get('BEEM_SECRET_KEY', { infer: true })!,
              senderId: config.get('BEEM_SENDER_ID', { infer: true })!,
              apiUrl: config.get('BEEM_API_URL', { infer: true }),
            })
          : new LogSmsSender(),
    },
  ],
  exports: [SMS_SENDER],
})
export class SmsModule {}
