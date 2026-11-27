import { Logger } from '@nestjs/common';
import type { MockInstance } from 'vitest';
import { BeemSmsSender } from './beem-sms.sender.js';
import { SmsDeliveryError } from './sms-sender.js';

function sender(response: { status?: number; body?: unknown } | Error) {
  const fetch = vi.fn(async () => {
    if (response instanceof Error) throw response;
    const raw =
      typeof response.body === 'string'
        ? response.body
        : JSON.stringify(response.body ?? {});
    return new Response(raw, {
      status: response.status ?? 200,
      headers: { 'Content-Type': 'application/json' },
    });
  });
  const beem = new BeemSmsSender({
    apiKey: 'key',
    secretKey: 'secret',
    senderId: 'FANIKISHA',
    apiUrl: 'https://apisms.beem.africa/v1/send',
    fetch: fetch as unknown as typeof globalThis.fetch,
  });
  return { beem, fetch };
}

const accepted = {
  successful: true,
  code: 100,
  message: 'Message Submitted Successfully',
};

describe('BeemSmsSender', () => {
  it('sends the request Beem documents', async () => {
    const { beem, fetch } = sender({ body: accepted });
    await beem.send('+255712345678', 'Your code is 123456');

    const [url, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe('https://apisms.beem.africa/v1/send');
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>).Authorization).toBe(
      `Basic ${Buffer.from('key:secret').toString('base64')}`,
    );
    expect(JSON.parse(init.body as string)).toEqual({
      source_addr: 'FANIKISHA',
      schedule_time: '',
      encoding: 0,
      message: 'Your code is 123456',
      recipients: [{ recipient_id: 1, dest_addr: '255712345678' }],
    });
  });

  it('fails when Beem refuses the message', async () => {
    const { beem } = sender({
      status: 400,
      body: { code: 111, message: 'Invalid Sender ID' },
    });
    await expect(beem.send('+255712345678', 'x')).rejects.toBeInstanceOf(
      SmsDeliveryError,
    );
  });

  describe('logs why Beem refused', () => {
    let error: MockInstance<Logger['error']>;
    const logged = () => error.mock.calls.map((call) => String(call[0]));

    beforeEach(() => {
      error = vi.spyOn(Logger.prototype, 'error').mockImplementation(() => {});
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('with the code and message at the top level', async () => {
      const { beem } = sender({
        status: 400,
        body: { code: 111, message: 'Invalid Sender ID' },
      });
      await expect(beem.send('+255712345678', 'x')).rejects.toThrow('code 111');
      expect(logged()).toEqual([
        'Beem refused an SMS: HTTP 400, code 111: Invalid Sender ID',
      ]);
    });

    it('with the code and message inside "data"', async () => {
      const { beem } = sender({
        status: 400,
        body: { data: { code: 102, message: 'Insufficient balance' } },
      });
      await expect(beem.send('+255712345678', 'x')).rejects.toThrow('code 102');
      expect(logged()).toEqual([
        'Beem refused an SMS: HTTP 400, code 102: Insufficient balance',
      ]);
    });

    it('with its raw answer otherwise, without the phone number', async () => {
      const { beem } = sender({
        status: 400,
        body: { error: 'Bad number 255712345678' },
      });
      await expect(beem.send('+255712345678', 'x')).rejects.toBeInstanceOf(
        SmsDeliveryError,
      );
      expect(logged()).toEqual([
        'Beem refused an SMS: HTTP 400, answer: {"error":"Bad number [phone]"}',
      ]);
    });

    it('when the answer is not JSON', async () => {
      const { beem } = sender({
        status: 400,
        body: '<html>Bad Request</html>',
      });
      await expect(beem.send('+255712345678', 'x')).rejects.toBeInstanceOf(
        SmsDeliveryError,
      );
      expect(logged()).toEqual([
        'Beem refused an SMS: HTTP 400, answer: <html>Bad Request</html>',
      ]);
    });
  });

  it('fails when Beem answers 200 without accepting', async () => {
    const { beem } = sender({ body: { successful: false, code: 102 } });
    await expect(beem.send('+255712345678', 'x')).rejects.toBeInstanceOf(
      SmsDeliveryError,
    );
  });

  it('fails when Beem cannot be reached', async () => {
    const { beem } = sender(new TypeError('fetch failed'));
    await expect(beem.send('+255712345678', 'x')).rejects.toBeInstanceOf(
      SmsDeliveryError,
    );
  });
});
