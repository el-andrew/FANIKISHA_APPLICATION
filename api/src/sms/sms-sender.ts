/** Sends text messages. Swap the implementation to change SMS provider. */
export interface SmsSender {
  /**
   * Sends [message] to [phone] (E.164, e.g. +255712345678). Resolves once the
   * provider has accepted it; rejects with {@link SmsDeliveryError} otherwise.
   */
  send(phone: string, message: string): Promise<void>;
}

/** Injection token for the configured {@link SmsSender}. */
export const SMS_SENDER = Symbol('SMS_SENDER');

export class SmsDeliveryError extends Error {
  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = 'SmsDeliveryError';
  }
}
