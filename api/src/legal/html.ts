export type PageLanguage = 'en' | 'sw';

/** Escapes text for HTML. Everything inserted into a page goes through it. */
export function escapeHtml(text: string): string {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

/** Marks a string as already-safe HTML (built from escaped parts). */
export class Html {
  constructor(readonly value: string) {}
}

/** Tagged template: interpolated values are escaped unless they are `Html`. */
export function html(
  strings: TemplateStringsArray,
  ...values: (string | number | Html | Html[])[]
): Html {
  let out = strings[0];
  values.forEach((value, i) => {
    const part = Array.isArray(value)
      ? value.map((v) => v.value).join('')
      : value instanceof Html
        ? value.value
        : escapeHtml(String(value));
    out += part + strings[i + 1];
  });
  return new Html(out);
}

const STYLE = `
  :root { color-scheme: light dark; --green: #215732; --muted: #5b625a; }
  @media (prefers-color-scheme: dark) { :root { --green: #a6d394; --muted: #b8beb5; } }
  body { font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
         margin: 0 auto; max-width: 42rem; padding: 1.5rem 1rem 4rem; }
  h1 { color: var(--green); line-height: 1.25; }
  h2 { margin-top: 2rem; font-size: 1.2rem; }
  .meta, .lang { color: var(--muted); font-size: .9rem; }
  .lang a { color: inherit; }
  form { display: grid; gap: .75rem; margin-top: 1rem; }
  label { display: grid; gap: .25rem; font-weight: 600; }
  input { font: inherit; padding: .6rem .7rem; border: 1px solid #8a9188; border-radius: .5rem; }
  button { font: inherit; font-weight: 600; padding: .7rem; border: 0; border-radius: .5rem;
           background: #b3261e; color: #fff; cursor: pointer; }
  .notice { padding: .8rem 1rem; border-radius: .5rem; background: #f9dedc; color: #410e0b; }
  .done { padding: .8rem 1rem; border-radius: .5rem; background: #d7f0cb; color: #0b2905; }
`;

/** A complete page with a language switch. */
export function page(options: {
  title: string;
  lang: PageLanguage;
  path: string;
  updated?: string;
  body: Html;
}): string {
  const other: PageLanguage = options.lang === 'en' ? 'sw' : 'en';
  const otherName = other === 'sw' ? 'Kiswahili' : 'English';
  return html`<!doctype html>
    <html lang="${options.lang}">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>${options.title} · Fanikisha</title>
        <style>
          ${new Html(STYLE)}
        </style>
      </head>
      <body>
        <p class="lang">
          <a href="${options.path}?lang=${other}">${otherName}</a>
        </p>
        <h1>${options.title}</h1>
        ${options.updated ? html`<p class="meta">${options.lang === 'sw' ? 'Ilisasishwa' : 'Last updated'}: ${options.updated}</p>` : new Html('')}
        ${options.body}
      </body>
    </html>`.value;
}
