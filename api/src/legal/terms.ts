import { html, type Html, type PageLanguage } from './html.js';
import type { Operator } from './operator.js';

// DRAFT: to be reviewed by a qualified lawyer before publishing.

export function termsOfService(lang: PageLanguage, op: Operator): Html {
  return lang === 'sw' ? sw(op) : en(op);
}

function en(op: Operator): Html {
  return html`
    <p>
      These terms are an agreement between you and ${op.name} (registration
      number ${op.registration}), ${op.address} ("we"), for your use of the
      Fanikisha app and service. By creating an account you accept them.
    </p>

    <h2>1. The service</h2>
    <p>
      Fanikisha helps you plan savings: you set goals, record the money you
      save, and Fanikisha suggests how to share each amount between your goals.
      Fanikisha does not hold, receive or move money; the amounts you record are
      your own records. The suggestions are calculations based on what you
      enter, not financial advice.
    </p>

    <h2>2. Who can use it</h2>
    <p>
      You must be 18 or older and give accurate information when you create your
      account.
    </p>

    <h2>3. Your account</h2>
    <p>
      Keep your password safe and do not share your account. You are responsible
      for what is done with it. Tell us at ${op.email} if you think someone else
      has used it.
    </p>

    <h2>4. Fair use</h2>
    <p>
      Do not use Fanikisha for anything unlawful, try to access other people's
      accounts or data, disrupt or overload the service, or collect data from it
      by automated means.
    </p>

    <h2>5. Your data</h2>
    <p>
      Your data stays yours. How we handle it is explained in our
      <a href="/privacy?lang=en">privacy policy</a>.
    </p>

    <h2>6. Availability and changes</h2>
    <p>
      We work to keep Fanikisha available and accurate, but we cannot guarantee
      it will always be available or free of errors. We may change or improve
      features over time.
    </p>

    <h2>7. Responsibility</h2>
    <p>
      Fanikisha is provided as it is. To the extent Tanzanian law allows, we are
      not responsible for decisions you make based on the app, or for losses
      caused by interruptions or errors in the service.
    </p>

    <h2>8. Ending</h2>
    <p>
      You can stop using Fanikisha and delete your account at any time (Profile
      → Delete account). We may suspend or close an account that breaks these
      terms, and will tell you why where we can.
    </p>

    <h2>9. Changes to these terms</h2>
    <p>
      If we change these terms, we will update the date above and tell you in
      the app before important changes take effect.
    </p>

    <h2>10. Law</h2>
    <p>
      These terms are governed by the laws of the United Republic of Tanzania,
      and its courts can settle disputes about them.
    </p>

    <h2>Contact</h2>
    <p>${op.name}, ${op.address}. Email: ${op.email}.</p>
  `;
}

function sw(op: Operator): Html {
  return html`
    <p>
      Masharti haya ni makubaliano kati yako na ${op.name} (namba ya usajili
      ${op.registration}), ${op.address} ("sisi"), kuhusu matumizi yako ya
      programu na huduma ya Fanikisha. Kwa kufungua akaunti unayakubali.
    </p>

    <h2>1. Huduma</h2>
    <p>
      Fanikisha hukusaidia kupanga akiba: unaweka malengo, unarekodi pesa
      unazoweka akiba, na Fanikisha hupendekeza jinsi ya kugawa kila kiasi kati
      ya malengo yako. Fanikisha haishiki, haipokei wala haihamishi pesa; kiasi
      unachorekodi ni kumbukumbu zako mwenyewe. Mapendekezo ni hesabu
      zinazotokana na unachoweka, si ushauri wa kifedha.
    </p>

    <h2>2. Nani anaweza kuitumia</h2>
    <p>
      Lazima uwe na umri wa miaka 18 au zaidi na utoe taarifa sahihi unapofungua
      akaunti.
    </p>

    <h2>3. Akaunti yako</h2>
    <p>
      Linda nenosiri lako na usimpe mtu mwingine akaunti yako. Unawajibika kwa
      yanayofanywa nayo. Tujulishe kupitia ${op.email} ikiwa unadhani mtu
      mwingine ameitumia.
    </p>

    <h2>4. Matumizi ya haki</h2>
    <p>
      Usitumie Fanikisha kwa jambo lolote lisilo halali, usijaribu kuingia
      kwenye akaunti au taarifa za watu wengine, usivuruge wala kuilemea huduma,
      na usikusanye taarifa kutoka kwake kwa njia za kiotomatiki.
    </p>

    <h2>5. Taarifa zako</h2>
    <p>
      Taarifa zako zinabaki kuwa zako. Jinsi tunavyozishughulikia imeelezwa
      kwenye <a href="/privacy?lang=sw">sera yetu ya faragha</a>.
    </p>

    <h2>6. Upatikanaji na mabadiliko</h2>
    <p>
      Tunajitahidi Fanikisha ipatikane na iwe sahihi, lakini hatuwezi
      kuhakikisha kuwa itapatikana wakati wote au haitakuwa na makosa. Tunaweza
      kubadilisha au kuboresha huduma kadri muda unavyokwenda.
    </p>

    <h2>7. Uwajibikaji</h2>
    <p>
      Fanikisha inatolewa kama ilivyo. Kwa kadri sheria za Tanzania
      zinavyoruhusu, hatuwajibiki kwa maamuzi unayofanya kutokana na programu,
      wala kwa hasara zinazotokana na kukatika au makosa ya huduma.
    </p>

    <h2>8. Kusitisha</h2>
    <p>
      Unaweza kuacha kutumia Fanikisha na kufuta akaunti yako wakati wowote
      (Wasifu → Futa akaunti). Tunaweza kusimamisha au kufunga akaunti
      inayovunja masharti haya, na tutakueleza sababu pale tunapoweza.
    </p>

    <h2>9. Mabadiliko ya masharti haya</h2>
    <p>
      Tukibadilisha masharti haya, tutasasisha tarehe iliyo juu na kukujulisha
      ndani ya programu kabla mabadiliko muhimu hayajaanza kutumika.
    </p>

    <h2>10. Sheria</h2>
    <p>
      Masharti haya yanaongozwa na sheria za Jamhuri ya Muungano wa Tanzania, na
      mahakama zake zinaweza kuamua migogoro inayoyahusu.
    </p>

    <h2>Mawasiliano</h2>
    <p>${op.name}, ${op.address}. Barua pepe: ${op.email}.</p>
  `;
}
