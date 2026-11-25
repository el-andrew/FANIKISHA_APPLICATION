import { escapeHtml, html, page } from './html.js';

describe('legal page HTML', () => {
  it('escapes every interpolated value', () => {
    const evil = '<script>alert("x")</script> & \'quotes\'';
    expect(escapeHtml(evil)).toBe(
      '&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; &#39;quotes&#39;',
    );
    expect(html`<p>${evil}</p>`.value).not.toContain('<script>');
  });

  it('builds a page with a link to the other language', () => {
    const out = page({
      title: 'Privacy policy',
      lang: 'en',
      path: '/privacy',
      body: html`<p>Hi</p>`,
    });
    expect(out).toContain('<html lang="en">');
    expect(out).toContain('href="/privacy?lang=sw"');
    expect(out).toContain('<p>Hi</p>');
  });
});
