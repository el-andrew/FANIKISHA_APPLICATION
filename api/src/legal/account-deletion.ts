import { html, type Html, type PageLanguage } from './html.js';
import type { Operator } from './operator.js';

const text = {
  en: {
    title: 'Delete your Fanikisha account',
    intro:
      'Deleting your account permanently removes your account, your goals and your savings history, and signs you out on every device. It cannot be undone.',
    inApp: 'In the app: open Profile, then Delete account.',
    here: 'Or delete it here by entering your email and password:',
    email: 'Email',
    password: 'Password',
    submit: 'Delete my account',
    forgot: (email: string) =>
      html`Forgot your password? Reset it in the app (Log in → Forgot
      password?), or write to ${email} from your account's email address and we
      will delete it for you.`,
    wrong: 'That email and password do not match an account.',
    invalid: 'Enter your email and password.',
    doneTitle: 'Your account has been deleted',
    done: 'Your account and all its data have been deleted.',
  },
  sw: {
    title: 'Futa akaunti yako ya Fanikisha',
    intro:
      'Kufuta akaunti yako huondoa kabisa akaunti yako, malengo yako na historia yako ya akiba, na kukutoa kwenye vifaa vyote. Haiwezi kurudishwa.',
    inApp: 'Ndani ya programu: fungua Wasifu, kisha Futa akaunti.',
    here: 'Au ifute hapa kwa kuweka barua pepe na nenosiri lako:',
    email: 'Barua pepe',
    password: 'Nenosiri',
    submit: 'Futa akaunti yangu',
    forgot: (email: string) =>
      html`Umesahau nenosiri? Libadilishe ndani ya programu (Ingia → Umesahau
      nenosiri?), au andika kwenda ${email} ukitumia barua pepe ya akaunti yako
      na tutaifuta kwa ajili yako.`,
    wrong: 'Barua pepe na nenosiri hilo havilingani na akaunti yoyote.',
    invalid: 'Weka barua pepe na nenosiri lako.',
    doneTitle: 'Akaunti yako imefutwa',
    done: 'Akaunti yako na taarifa zake zote zimefutwa.',
  },
} as const;

export function deletionTitle(lang: PageLanguage, done = false): string {
  return done ? text[lang].doneTitle : text[lang].title;
}

export function deletionForm(
  lang: PageLanguage,
  op: Operator,
  options: { error?: 'wrong' | 'invalid'; email?: string } = {},
): Html {
  const t = text[lang];
  return html`
    <p>${t.intro}</p>
    <p>${t.inApp}</p>
    <p>${t.here}</p>
    ${options.error ? html`<p class="notice" role="alert">${t[options.error]}</p>` : html``}
    <form method="post" action="/account-deletion">
      <input type="hidden" name="lang" value="${lang}" />
      <label
        >${t.email}
        <input
          type="email"
          name="email"
          autocomplete="email"
          required
          value="${options.email ?? ''}"
        />
      </label>
      <label
        >${t.password}
        <input
          type="password"
          name="password"
          autocomplete="current-password"
          required
        />
      </label>
      <button type="submit">${t.submit}</button>
    </form>
    <p class="meta">${t.forgot(op.email)}</p>
  `;
}

export function deletionDone(lang: PageLanguage): Html {
  return html`<p class="done" role="status">${text[lang].done}</p>`;
}
