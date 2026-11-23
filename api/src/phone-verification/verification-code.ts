import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';

/** A new 6-digit code from a cryptographically secure source. */
export function generateCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

/**
 * Hashes codes with a server-side key, bound to the verification record, so
 * stored hashes are useless without the key and can't be reused elsewhere.
 */
export class CodeHasher {
  private readonly key: Buffer;

  constructor(serverSecret: string) {
    // A key of its own, derived from the server secret.
    this.key = createHmac('sha256', serverSecret)
      .update('fanikisha:phone-verification')
      .digest();
  }

  hash(verificationId: string, code: string): string {
    return createHmac('sha256', this.key)
      .update(`${verificationId}:${code}`)
      .digest('hex');
  }

  matches(verificationId: string, code: string, storedHash: string): boolean {
    const actual = Buffer.from(this.hash(verificationId, code), 'hex');
    const expected = Buffer.from(storedHash, 'hex');
    return (
      actual.length === expected.length && timingSafeEqual(actual, expected)
    );
  }
}

export function smsText(code: string, language: 'en' | 'sw'): string {
  return language === 'sw'
    ? `Namba yako ya uthibitisho ya Fanikisha ni ${code}. Itaisha baada ya dakika 10. Usimpe mtu yeyote namba hii.`
    : `Your Fanikisha verification code is ${code}. It expires in 10 minutes. Never share this code.`;
}
