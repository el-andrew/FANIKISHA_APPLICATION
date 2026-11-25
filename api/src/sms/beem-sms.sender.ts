import { Logger } from '@nestjs/common';
import { SmsDeliveryError, type SmsSender } from './sms-sender.js';

export interface BeemOptions {
  apiKey: string;
  secretKey: string;
  /** Registered and activated on the Beem account. */
  senderId: string;
  /** `https://apisms.beem.africa/v1/send` in production. */
  apiUrl: string;
  /** For tests. */
  fetch?: typeof fetch;
  timeoutMs?: number;
}

interface BeemResponse {
  successful?: boolean;
  code?: number;
  message?: string;
}

/**
 * Sends SMS through Beem's SMS API (https://docs.beem.africa).
 * Authenticates with HTTP Basic auth (API key and secret); numbers are sent
 * in international format without the leading `+`.
 */
export class BeemSmsSender implements SmsSender {
  private static readonly logger = new Logger('BeemSmsSender');
  private readonly authorization: string;
  private readonly fetch: typeof fetch;

  constructor(private readonly options: BeemOptions) {
    this.authorization = `Basic ${Buffer.from(
      `${options.apiKey}:${options.secretKey}`,
    ).toString('base64')}`;
    this.fetch = options.fetch ?? globalThis.fetch;
  }

  async send(phone: string, message: string): Promise<void> {
    let response: Response;
    try {
      response = await this.fetch(this.options.apiUrl, {
        method: 'POST',
        headers: {
          Authorization: this.authorization,
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({
          source_addr: this.options.senderId,
          schedule_time: '',
          encoding: 0,
          message,
          recipients: [
            { recipient_id: 1, dest_addr: phone.replace(/^\+/, '') },
          ],
        }),
        signal: AbortSignal.timeout(this.options.timeoutMs ?? 10_000),
      });
    } catch (error) {
      throw new SmsDeliveryError('Beem could not be reached', { cause: error });
    }

    const body = (await response.json().catch(() => ({}))) as BeemResponse;
    // Beem answers 200 with code 100 when the message was accepted.
    if (!response.ok || body.successful !== true || body.code !== 100) {
      BeemSmsSender.logger.error(
        `Beem refused an SMS: HTTP ${response.status}, code ${body.code}: ${body.message}`,
      );
      throw new SmsDeliveryError(
        `Beem refused the message (code ${body.code ?? response.status})`,
      );
    }
  }
}
