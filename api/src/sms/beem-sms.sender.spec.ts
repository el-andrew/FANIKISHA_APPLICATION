import { BeemSmsSender } from './beem-sms.sender.js';
import { SmsDeliveryError } from './sms-sender.js';

function sender(response: { status?: number; body?: unknown } | Error) {
  const fetch = vi.fn(async () => {
    if (response instanceof Error) throw response;
    return new Response(JSON.stringify(response.body ?? {}), {
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
