import { html, type Html, type PageLanguage } from './html.js';
import type { Operator } from './operator.js';

// DRAFT: to be checked against Tanzania's Personal Data Protection Act, 2022
// before publishing. Every statement here describes what the code actually
// does; update this text whenever that changes. Facts not decided yet are
// left as [PLACEHOLDERS].

export function privacyPolicy(lang: PageLanguage, op: Operator): Html {
  return lang === 'sw' ? sw(op) : en(op);
}

function en(op: Operator): Html {
  return html`
    <p>
      This policy explains what personal data the Fanikisha app and service
      collect, why, and the choices you have. Fanikisha is run by ${op.name}
      (registration number ${op.registration}), ${op.address} ("we"). We are
      responsible for your personal data.
    </p>

    <h2>What Fanikisha is</h2>
    <p>
      Fanikisha helps owners of small and medium businesses plan their savings.
      You set savings goals and record the money you save; Fanikisha suggests
      how to share each amount between your goals. Fanikisha does not hold,
      receive or move your money.
    </p>

    <h2>Data we collect</h2>
    <ul>
      <li>
        <strong>Your account:</strong> your full name, email address, password,
        and, if you give them, your business name and phone number. Your
        password is stored only as a one-way hash (scrypt); we cannot read it.
      </li>
      <li>
        <strong>Phone verification and password reset:</strong> when you ask, we
        send a one-time code to your phone by SMS. We store only a protected
        hash of each code, never the code itself; codes expire after 10 minutes.
        We record when your phone number was verified, and when codes were sent,
        so we can limit how many are sent.
      </li>
      <li>
        <strong>Your savings plans:</strong> the goals you create (name,
        category, target amount, priority and dates), the deposits you record
        (amount, optional note and date) and how each deposit was shared between
        your goals.
      </li>
      <li>
        <strong>Sign-in records:</strong> to keep you signed in, we store
        sign-in tokens, as hashes, for up to 90 days.
      </li>
      <li>
        <strong>Technical data:</strong> your IP address is used briefly to
        limit repeated requests (for example, password guessing) and may appear
        in our server logs, which we keep for [LOG RETENTION PERIOD].
      </li>
    </ul>
    <p>
      We do not collect your location, contacts or photos. Fanikisha shows no
      advertising, uses no advertising or analytics trackers, and we do not sell
      your data.
    </p>

    <h2>Data kept on your phone</h2>
    <p>
      The app keeps your sign-in tokens in your phone's secure storage (Android
      Keystore or iOS Keychain), a copy of your most recent goals, savings
      summary and history so you can view them offline, and your language
      choice. The offline copy is removed when you log out or delete your
      account.
    </p>

    <h2>Why we use your data</h2>
    <ul>
      <li>
        To provide the service you signed up for: your account, goals, deposits
        and savings suggestions.
      </li>
      <li>
        To confirm your phone number and to let you reset a forgotten password.
      </li>
      <li>
        To keep the service and your account secure, and to prevent abuse.
      </li>
    </ul>
    <p>
      We use your data with your consent, given when you create your account,
      and as needed to provide the service. You can withdraw your consent at any
      time by deleting your account.
    </p>

    <h2>Who we share it with</h2>
    <ul>
      <li>
        <strong>Beem Africa</strong> (our SMS provider) receives your phone
        number and the text of the messages we send you, such as verification
        codes.
      </li>
      <li>
        <strong>[HOSTING PROVIDER]</strong> stores our servers and database in
        [HOSTING COUNTRY].
      </li>
      <li>Public authorities, only where Tanzanian law requires us to.</li>
    </ul>
    <p>
      [If the hosting country is outside Tanzania: describe here how the
      transfer is protected, as the Personal Data Protection Act requires.]
    </p>

    <h2>How long we keep it</h2>
    <p>
      We keep your data while you have an account. When you delete your account,
      your account, goals, deposits, SMS code records and sign-in tokens are
      deleted from our database straight away. Copies in our backups are deleted
      within [BACKUP RETENTION PERIOD].
    </p>

    <h2>How we protect it</h2>
    <p>
      Data travels between the app and our servers encrypted (HTTPS). Passwords,
      codes and sign-in tokens are stored only as hashes. Each account can see
      only its own data.
    </p>

    <h2>Your rights</h2>
    <ul>
      <li>
        <strong>See and correct</strong> your account details in the app, under
        Profile.
      </li>
      <li>
        <strong>Delete</strong> your account and its data: in the app (Profile →
        Delete account) or on our
        <a href="/account-deletion?lang=en">account deletion page</a>.
      </li>
      <li>
        <strong>Ask</strong> for a copy of your data, or about how we use it, by
        writing to ${op.email}.
      </li>
      <li>
        <strong>Complain</strong> to the Personal Data Protection Commission of
        Tanzania if you think we have mishandled your data.
      </li>
    </ul>

    <h2>Children</h2>
    <p>
      Fanikisha is for adults aged 18 and over. We do not knowingly collect data
      from children.
    </p>

    <h2>Changes to this policy</h2>
    <p>
      If we change this policy, we will update the date above and, for important
      changes, tell you in the app.
    </p>

    <h2>Contact</h2>
    <p>${op.name}, ${op.address}. Email: ${op.email}.</p>
  `;
}

function sw(op: Operator): Html {
  return html`
    <p>
      Sera hii inaeleza taarifa binafsi ambazo programu na huduma ya Fanikisha
      hukusanya, sababu za kuzikusanya, na machaguo uliyo nayo. Fanikisha
      inaendeshwa na ${op.name} (namba ya usajili ${op.registration}),
      ${op.address} ("sisi"). Tunawajibika kwa taarifa zako binafsi.
    </p>

    <h2>Fanikisha ni nini</h2>
    <p>
      Fanikisha huwasaidia wamiliki wa biashara ndogo na za kati kupanga akiba
      yao. Unaweka malengo ya akiba na kurekodi pesa unazoweka akiba; Fanikisha
      hupendekeza jinsi ya kugawa kila kiasi kati ya malengo yako. Fanikisha
      haishiki, haipokei wala haihamishi pesa zako.
    </p>

    <h2>Taarifa tunazokusanya</h2>
    <ul>
      <li>
        <strong>Akaunti yako:</strong> jina lako kamili, barua pepe, nenosiri,
        na, ukiyatoa, jina la biashara yako na namba ya simu. Nenosiri lako
        huhifadhiwa kwa njia ya hashi ya upande mmoja (scrypt) pekee; hatuwezi
        kulisoma.
      </li>
      <li>
        <strong>Uthibitisho wa simu na kubadilisha nenosiri:</strong> ukiomba,
        tunatuma namba ya mara moja kwenye simu yako kwa SMS. Tunahifadhi hashi
        iliyolindwa ya kila namba pekee, kamwe si namba yenyewe; namba huisha
        muda wake baada ya dakika 10. Tunarekodi lini namba yako ya simu
        ilithibitishwa, na lini namba zilitumwa, ili tuweze kudhibiti idadi
        inayotumwa.
      </li>
      <li>
        <strong>Mipango yako ya akiba:</strong> malengo unayoweka (jina, aina,
        kiasi cha lengo, kipaumbele na tarehe), akiba unazorekodi (kiasi,
        maelezo ukiyaweka, na tarehe) na jinsi kila akiba ilivyogawanywa kati ya
        malengo yako.
      </li>
      <li>
        <strong>Kumbukumbu za kuingia:</strong> ili uendelee kuwa umeingia,
        tunahifadhi tokeni za kuingia, kama hashi, kwa hadi siku 90.
      </li>
      <li>
        <strong>Taarifa za kiufundi:</strong> anwani yako ya IP hutumika kwa
        muda mfupi kudhibiti maombi yanayorudiwa (kwa mfano, kubahatisha
        nenosiri) na inaweza kuonekana kwenye kumbukumbu za seva zetu, ambazo
        tunazihifadhi kwa [MUDA WA KUHIFADHI KUMBUKUMBU].
      </li>
    </ul>
    <p>
      Hatukusanyi mahali ulipo, anwani za watu wako wala picha zako. Fanikisha
      haionyeshi matangazo, haitumii vifuatiliaji vya matangazo wala takwimu, na
      hatuuzi taarifa zako.
    </p>

    <h2>Taarifa zinazohifadhiwa kwenye simu yako</h2>
    <p>
      Programu huhifadhi tokeni zako za kuingia kwenye hifadhi salama ya simu
      yako (Android Keystore au iOS Keychain), nakala ya malengo yako ya
      karibuni, muhtasari wa akiba na historia ili uweze kuziona bila mtandao,
      na lugha uliyochagua. Nakala hiyo ya nje ya mtandao hufutwa unapotoka au
      unapofuta akaunti yako.
    </p>

    <h2>Kwa nini tunatumia taarifa zako</h2>
    <ul>
      <li>
        Kukupa huduma uliyojisajili kwayo: akaunti yako, malengo, akiba na
        mapendekezo ya akiba.
      </li>
      <li>
        Kuthibitisha namba yako ya simu na kukuwezesha kubadilisha nenosiri
        uliloisahau.
      </li>
      <li>
        Kulinda usalama wa huduma na akaunti yako, na kuzuia matumizi mabaya.
      </li>
    </ul>
    <p>
      Tunatumia taarifa zako kwa ridhaa yako, uliyoitoa ulipofungua akaunti, na
      kadri inavyohitajika kukupa huduma. Unaweza kuondoa ridhaa yako wakati
      wowote kwa kufuta akaunti yako.
    </p>

    <h2>Tunashirikiana nani</h2>
    <ul>
      <li>
        <strong>Beem Africa</strong> (mtoa huduma wetu wa SMS) hupokea namba
        yako ya simu na maandishi ya ujumbe tunaokutumia, kama namba za
        uthibitisho.
      </li>
      <li>
        <strong>[MTOA HUDUMA YA SEVA]</strong> huhifadhi seva na hifadhidata
        yetu nchini [NCHI YA SEVA].
      </li>
      <li>Mamlaka za umma, pale tu sheria za Tanzania zinapotutaka.</li>
    </ul>
    <p>
      [Ikiwa nchi ya seva iko nje ya Tanzania: eleza hapa jinsi uhamisho huo
      unavyolindwa, kama Sheria ya Ulinzi wa Taarifa Binafsi inavyotaka.]
    </p>

    <h2>Tunazihifadhi kwa muda gani</h2>
    <p>
      Tunahifadhi taarifa zako maadamu una akaunti. Unapofuta akaunti yako,
      akaunti, malengo, akiba, kumbukumbu za namba za SMS na tokeni za kuingia
      hufutwa kwenye hifadhidata yetu mara moja. Nakala zilizo kwenye hifadhi
      rudufu hufutwa ndani ya [MUDA WA HIFADHI RUDUFU].
    </p>

    <h2>Tunavyozilinda</h2>
    <p>
      Taarifa husafiri kati ya programu na seva zetu zikiwa zimesimbwa (HTTPS).
      Manenosiri, namba za uthibitisho na tokeni za kuingia huhifadhiwa kama
      hashi pekee. Kila akaunti inaweza kuona taarifa zake tu.
    </p>

    <h2>Haki zako</h2>
    <ul>
      <li>
        <strong>Kuona na kusahihisha</strong> taarifa za akaunti yako ndani ya
        programu, kwenye Wasifu.
      </li>
      <li>
        <strong>Kufuta</strong> akaunti yako na taarifa zake: ndani ya programu
        (Wasifu → Futa akaunti) au kwenye
        <a href="/account-deletion?lang=sw">ukurasa wetu wa kufuta akaunti</a>.
      </li>
      <li>
        <strong>Kuomba</strong> nakala ya taarifa zako, au kuuliza jinsi
        tunavyozitumia, kwa kuandika kwenda ${op.email}.
      </li>
      <li>
        <strong>Kulalamika</strong> kwa Tume ya Ulinzi wa Taarifa Binafsi
        Tanzania ikiwa unaona tumeshughulikia taarifa zako isivyofaa.
      </li>
    </ul>

    <h2>Watoto</h2>
    <p>
      Fanikisha ni kwa watu wazima wenye umri wa miaka 18 na zaidi. Hatukusanyi
      taarifa za watoto kwa kujua.
    </p>

    <h2>Mabadiliko ya sera hii</h2>
    <p>
      Tukibadilisha sera hii, tutasasisha tarehe iliyo juu na, kwa mabadiliko
      muhimu, tutakujulisha ndani ya programu.
    </p>

    <h2>Mawasiliano</h2>
    <p>${op.name}, ${op.address}. Barua pepe: ${op.email}.</p>
  `;
}
