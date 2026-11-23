import { CodeHasher, generateCode, smsTexts } from './verification-code.js';

describe('verification codes', () => {
  it('are six digits, including leading zeros', () => {
    for (let i = 0; i < 1_000; i++) {
      expect(generateCode()).toMatch(/^\d{6}$/);
    }
  });

  it('hash per verification and secret', () => {
    const hasher = new CodeHasher('a-server-secret-of-at-least-32-bytes!!');
    const hash = hasher.hash('id-1', '123456');
    expect(hasher.matches('id-1', '123456', hash)).toBe(true);
    expect(hasher.matches('id-1', '123457', hash)).toBe(false);
    expect(hasher.matches('id-2', '123456', hash)).toBe(false);
    const other = new CodeHasher('another-server-secret-of-32-bytes!!!!!');
    expect(other.matches('id-1', '123456', hash)).toBe(false);
  });

  it('writes each SMS in the requested language', () => {
    expect(smsTexts.verifyPhone('012345', 'en')).toContain('012345');
    expect(smsTexts.verifyPhone('012345', 'sw')).toMatch(
      /^Namba yako .*012345/,
    );
    expect(smsTexts.resetPassword('012345', 'en')).toMatch(
      /password reset code is 012345/,
    );
    expect(smsTexts.resetPassword('012345', 'sw')).toMatch(/nenosiri .*012345/);
  });
});
