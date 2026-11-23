// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appName => 'Fanikisha';

  @override
  String get tagline => 'Imarisha tabia yako ya kuweka akiba';

  @override
  String get actionRetry => 'Jaribu tena';

  @override
  String get actionCancel => 'Ghairi';

  @override
  String get actionDone => 'Sawa';

  @override
  String get actionLogOut => 'Toka';

  @override
  String get errorNetwork =>
      'Imeshindwa kufikia Fanikisha. Angalia mtandao wako kisha ujaribu tena.';

  @override
  String get errorServer =>
      'Hitilafu imetokea upande wetu. Tafadhali jaribu tena baada ya muda mfupi.';

  @override
  String get errorSessionExpired =>
      'Muda wako wa kuingia umekwisha. Tafadhali ingia tena.';

  @override
  String get errorUnknown => 'Hitilafu imetokea. Tafadhali jaribu tena.';

  @override
  String get fieldRequired => 'Inahitajika';

  @override
  String get welcomeHeadline =>
      'Weka akiba kwa mahitaji yajayo ya biashara yako';

  @override
  String get welcomeBody =>
      'Weka malengo ya bidhaa, vifaa au kodi. Kila unapoweka akiba, Fanikisha hugawa pesa kati ya malengo yako ili yale ya haraka zaidi yajae kwanza.';

  @override
  String get welcomeCreateAccount => 'Fungua akaunti';

  @override
  String get welcomeLogIn => 'Nina akaunti tayari';

  @override
  String get emailLabel => 'Barua pepe';

  @override
  String get emailInvalid => 'Weka barua pepe sahihi';

  @override
  String get passwordLabel => 'Nenosiri';

  @override
  String get passwordTooShort => 'Tumia angalau herufi 8';

  @override
  String get passwordShow => 'Onyesha nenosiri';

  @override
  String get passwordHide => 'Ficha nenosiri';

  @override
  String get confirmPasswordLabel => 'Thibitisha nenosiri';

  @override
  String get passwordsDoNotMatch => 'Manenosiri hayalingani';

  @override
  String get fullNameLabel => 'Jina kamili';

  @override
  String get fullNameInvalid => 'Weka jina lako kamili';

  @override
  String get businessNameLabel => 'Jina la biashara (si lazima)';

  @override
  String get phoneLabel => 'Namba ya simu (si lazima)';

  @override
  String get phoneHelper => 'Mfumo wa kimataifa, mfano +255712345678';

  @override
  String get phoneInvalid => 'Tumia mfumo wa kimataifa, mfano +255712345678';

  @override
  String get loginTitle => 'Karibu tena';

  @override
  String get loginButton => 'Ingia';

  @override
  String get loginWrongCredentials => 'Barua pepe au nenosiri si sahihi';

  @override
  String get loginNoAccount => 'Mgeni kwenye Fanikisha?';

  @override
  String get loginCreateAccount => 'Fungua akaunti';

  @override
  String get registerTitle => 'Fungua akaunti yako';

  @override
  String get registerButton => 'Fungua akaunti';

  @override
  String get registerHaveAccount => 'Una akaunti tayari?';

  @override
  String get registerLogIn => 'Ingia';

  @override
  String get splashRestoreFailed => 'Tumeshindwa kupakia akaunti yako.';

  @override
  String get navHome => 'Mwanzo';

  @override
  String get navGoals => 'Malengo';

  @override
  String get navHistory => 'Historia';

  @override
  String get navProfile => 'Wasifu';

  @override
  String dashboardGreeting(String name) {
    return 'Habari, $name';
  }

  @override
  String get dashboardTotalSaved => 'Jumla ya akiba';

  @override
  String dashboardGeneralSavings(String amount) {
    return 'Akiba ya jumla: $amount';
  }

  @override
  String dashboardDepositCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Akiba $count zimewekwa',
      one: 'Akiba 1 imewekwa',
      zero: 'Bado hujaweka akiba',
    );
    return '$_temp0';
  }

  @override
  String get dashboardSaveMoney => 'Weka akiba';

  @override
  String get dashboardActiveGoals => 'Malengo yanayoendelea';

  @override
  String get dashboardSeeAll => 'Yote';

  @override
  String get dashboardNoGoalsTitle => 'Bado huna malengo';

  @override
  String get dashboardNoGoalsBody =>
      'Weka lengo, kama bidhaa mpya au vifaa, na Fanikisha itakusaidia kuweka akiba kwa ajili yake.';

  @override
  String get dashboardCreateGoal => 'Weka lengo';

  @override
  String goalDailyTarget(String amount) {
    return 'Weka $amount kwa siku ili kufikia lengo kwa wakati';
  }

  @override
  String goalDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zimebaki siku $count',
      one: 'Imebaki siku 1',
    );
    return '$_temp0';
  }

  @override
  String goalSavedOf(String saved, String target) {
    return '$saved kati ya $target';
  }

  @override
  String get goalStatusCompleted => 'Limekamilika';

  @override
  String get goalStatusArchived => 'Limehifadhiwa';

  @override
  String get priority1 => 'Chini';

  @override
  String get priority2 => 'Chini kiasi';

  @override
  String get priority3 => 'Wastani';

  @override
  String get priority4 => 'Juu';

  @override
  String get priority5 => 'Juu sana';

  @override
  String get goalsTitle => 'Malengo';

  @override
  String get goalsFilterActive => 'Yanayoendelea';

  @override
  String get goalsFilterCompleted => 'Yaliyokamilika';

  @override
  String get goalsFilterArchived => 'Yaliyohifadhiwa';

  @override
  String get goalsEmptyActive => 'Huna malengo yanayoendelea.';

  @override
  String get goalsEmptyCompleted =>
      'Bado hakuna lengo lililokamilika. Endelea kuweka akiba!';

  @override
  String get goalsEmptyArchived => 'Hakuna malengo yaliyohifadhiwa.';

  @override
  String get goalsNew => 'Lengo jipya';

  @override
  String get goalDetailSaved => 'Akiba';

  @override
  String get goalDetailTarget => 'Lengo';

  @override
  String get goalDetailRemaining => 'Kiasi kilichobaki';

  @override
  String get goalDetailDailyTarget => 'Kinachohitajika kwa siku';

  @override
  String get goalDetailTargetDate => 'Tarehe ya lengo';

  @override
  String get goalDetailPriority => 'Kipaumbele';

  @override
  String get goalDetailCategory => 'Aina';

  @override
  String get goalEdit => 'Badilisha lengo';

  @override
  String get goalArchive => 'Hifadhi lengo';

  @override
  String get goalArchiveConfirmTitle => 'Hifadhi lengo hili?';

  @override
  String goalArchiveConfirmBody(String amount) {
    return 'Halitapokea akiba mpya tena. $amount iliyokwisha wekwa itabaki kwenye kumbukumbu.';
  }

  @override
  String get goalArchiveConfirmButton => 'Hifadhi';

  @override
  String get goalFormNewTitle => 'Lengo jipya';

  @override
  String get goalFormEditTitle => 'Badilisha lengo';

  @override
  String get goalNameLabel => 'Unaweka akiba kwa ajili ya nini?';

  @override
  String get goalNameHint => 'mfano Friji mpya ya duka';

  @override
  String get goalCategoryLabel => 'Aina (si lazima)';

  @override
  String get goalCategoryHint => 'mfano Bidhaa, Vifaa, Kodi';

  @override
  String get goalTargetAmountLabel => 'Kiasi cha lengo';

  @override
  String get amountInvalid => 'Weka kiasi kikubwa kuliko sifuri';

  @override
  String get goalTargetDateLabel => 'Tarehe ya lengo';

  @override
  String get goalTargetDateMissing => 'Chagua tarehe ya lengo';

  @override
  String get goalPriorityLabel => 'Lina umuhimu kiasi gani?';

  @override
  String get goalPriorityHelper =>
      'Malengo muhimu zaidi hupata sehemu kubwa ya kila akiba.';

  @override
  String get goalFormCreate => 'Weka lengo';

  @override
  String get goalFormSave => 'Hifadhi mabadiliko';

  @override
  String get depositTitle => 'Weka akiba';

  @override
  String get depositAmountLabel => 'Kiasi';

  @override
  String get depositNoteLabel => 'Maelezo (si lazima)';

  @override
  String get depositNoteHint => 'mfano Mauzo ya Jumatatu';

  @override
  String get depositPreviewTitle => 'Itakavyogawanywa';

  @override
  String get depositPreviewEmpty =>
      'Weka kiasi ili kuona kitakavyogawanywa kati ya malengo yako.';

  @override
  String get depositPreviewNoGoals =>
      'Huna malengo yanayoendelea, kwa hiyo kiasi hiki kitaenda kwenye akiba ya jumla.';

  @override
  String get generalSavings => 'Akiba ya jumla';

  @override
  String depositSubmit(String amount) {
    return 'Weka $amount';
  }

  @override
  String get depositSuccessTitle => 'Imewekwa!';

  @override
  String depositSuccessBody(String amount) {
    return '$amount imeongezwa kwenye akiba yako.';
  }

  @override
  String get historyTitle => 'Historia';

  @override
  String get historyEmpty =>
      'Bado hujaweka akiba. Akiba zako zitaonekana hapa.';

  @override
  String get profileTitle => 'Wasifu';

  @override
  String get profileEdit => 'Badilisha wasifu';

  @override
  String get profileSave => 'Hifadhi wasifu';

  @override
  String get profileUpdated => 'Wasifu umesasishwa';

  @override
  String get profileChangePassword => 'Badilisha nenosiri';

  @override
  String get profileLanguage => 'Lugha';

  @override
  String get profileLogOutConfirm => 'Toka kwenye Fanikisha kwenye kifaa hiki?';

  @override
  String get changePasswordCurrent => 'Nenosiri la sasa';

  @override
  String get changePasswordNew => 'Nenosiri jipya';

  @override
  String get changePasswordSubmit => 'Badilisha nenosiri';

  @override
  String get changePasswordDone =>
      'Nenosiri limebadilishwa. Vifaa vyako vingine vimetolewa.';

  @override
  String get languageSystem => 'Kama ya kifaa';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get verifyPhoneTitle => 'Thibitisha namba ya simu';

  @override
  String verifyPhoneSending(String phone) {
    return 'Tunatuma namba ya uthibitisho kwenda $phone…';
  }

  @override
  String verifyPhoneSentTo(String phone) {
    return 'Tumetuma namba ya tarakimu 6 kwenda $phone.';
  }

  @override
  String get verifyPhoneCodeLabel => 'Namba ya uthibitisho';

  @override
  String get verifyPhoneSubmit => 'Thibitisha';

  @override
  String get verifyPhoneResend => 'Tuma namba mpya';

  @override
  String verifyPhoneResendIn(int seconds) {
    return 'Tuma namba mpya baada ya sekunde $seconds';
  }

  @override
  String get verifyPhoneDone => 'Namba ya simu imethibitishwa';

  @override
  String get phoneVerified => 'Imethibitishwa';

  @override
  String get verifyPhoneBannerTitle => 'Thibitisha namba yako ya simu';

  @override
  String get verifyPhoneBannerBody =>
      'Utaihitaji ili kuweka akiba kwa pesa za simu.';

  @override
  String get verifyPhoneAction => 'Thibitisha sasa';

  @override
  String get phoneErrorNoPhone =>
      'Kwanza ongeza namba ya simu kwenye wasifu wako.';

  @override
  String phoneErrorResendTooSoon(int seconds) {
    return 'Tafadhali subiri sekunde $seconds kabla ya kuomba namba mpya.';
  }

  @override
  String get phoneErrorDailyLimit =>
      'Umeomba namba nyingi mno leo. Tafadhali jaribu tena kesho.';

  @override
  String get phoneErrorSmsFailed =>
      'Tumeshindwa kutuma SMS. Tafadhali jaribu tena baadaye.';

  @override
  String get phoneErrorCodeExpired =>
      'Muda wa namba hii umekwisha. Omba namba mpya.';

  @override
  String phoneErrorCodeIncorrect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Namba si sahihi. Zimebaki nafasi $count.',
      one: 'Namba si sahihi. Imebaki nafasi 1.',
    );
    return '$_temp0';
  }

  @override
  String get phoneErrorTooManyAttempts =>
      'Umekosea mara nyingi mno. Omba namba mpya.';

  @override
  String get forgotPasswordLink => 'Umesahau nenosiri?';

  @override
  String get forgotPasswordTitle => 'Badilisha nenosiri lako';

  @override
  String get forgotPasswordIntro =>
      'Weka barua pepe ya akaunti yako. Tutatuma namba kwa SMS kwenda namba ya simu uliyoithibitisha.';

  @override
  String get forgotPasswordSend => 'Tuma namba';

  @override
  String forgotPasswordSent(String email) {
    return 'Kama $email ina akaunti yenye namba ya simu iliyothibitishwa, tumetuma namba kwa SMS kwenda namba hiyo.';
  }

  @override
  String get forgotPasswordNoPhone =>
      'Akaunti yako haina namba ya simu iliyothibitishwa? Basi haiwezi kubadilishwa nenosiri kwa SMS kwa sasa.';

  @override
  String get forgotPasswordSubmit => 'Badilisha nenosiri';

  @override
  String get forgotPasswordOtherEmail => 'Tumia barua pepe nyingine';

  @override
  String get errorWrongPassword => 'Nenosiri si sahihi.';

  @override
  String get deleteAccount => 'Futa akaunti';

  @override
  String get deleteAccountTitle => 'Futa akaunti yako?';

  @override
  String get deleteAccountBody =>
      'Hii itafuta kabisa akaunti yako, malengo yako na historia yako ya akiba, na kukutoa kwenye vifaa vyote. Haiwezi kurudishwa.';

  @override
  String get deleteAccountPassword => 'Weka nenosiri lako kuthibitisha';

  @override
  String get deleteAccountSubmit => 'Futa akaunti yangu';

  @override
  String get deleteAccountDone => 'Akaunti yako imefutwa.';

  @override
  String offlineSavedToday(String time) {
    return 'Huna mtandao. Unaona taarifa zilizohifadhiwa saa $time.';
  }

  @override
  String offlineSavedEarlier(String date) {
    return 'Huna mtandao. Unaona taarifa zilizohifadhiwa tarehe $date.';
  }

  @override
  String get legalAgreement =>
      'Kwa kufungua akaunti, unakubali masharti ya huduma na sera ya faragha.';

  @override
  String get legalTerms => 'Masharti ya huduma';

  @override
  String get legalPrivacy => 'Sera ya faragha';
}
