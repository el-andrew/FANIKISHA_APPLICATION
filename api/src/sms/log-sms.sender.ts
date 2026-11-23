import { Logger } from '@nestjs/common';
import type { SmsSender } from './sms-sender.js';

/**
 * Development only: prints messages to the server log instead of sending
 * them. The configuration refuses this provider in production.
 */
export class LogSmsSender implements SmsSender {
  private static readonly logger = new Logger('SMS');

  send(phone: string, message: string): Promise<void> {
    LogSmsSender.logger.warn(`(not sent) to ${phone}: ${message}`);
    return Promise.resolve();
  }
}
