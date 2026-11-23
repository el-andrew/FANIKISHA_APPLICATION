// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Fanikisha';

  @override
  String get tagline => 'Level up your saving habit';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDone => 'Done';

  @override
  String get actionLogOut => 'Log out';

  @override
  String get errorNetwork =>
      'Can\'t reach Fanikisha. Check your internet connection and try again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Please try again in a moment.';

  @override
  String get errorSessionExpired =>
      'Your session has ended. Please log in again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get welcomeHeadline => 'Save for what your business needs next';

  @override
  String get welcomeBody =>
      'Set goals for stock, equipment or rent. Each time you save, Fanikisha shares the money between your goals so the most urgent ones fill first.';

  @override
  String get welcomeCreateAccount => 'Create an account';

  @override
  String get welcomeLogIn => 'I already have an account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordTooShort => 'Use at least 8 characters';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords don\'t match';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameInvalid => 'Enter your full name';

  @override
  String get businessNameLabel => 'Business name (optional)';

  @override
  String get phoneLabel => 'Phone number (optional)';

  @override
  String get phoneHelper => 'International format, e.g. +255712345678';

  @override
  String get phoneInvalid => 'Use international format, e.g. +255712345678';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginWrongCredentials => 'Incorrect email or password';

  @override
  String get loginNoAccount => 'New to Fanikisha?';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerButton => 'Create account';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerLogIn => 'Log in';

  @override
  String get splashRestoreFailed => 'We couldn\'t load your account.';

  @override
  String get navHome => 'Home';

  @override
  String get navGoals => 'Goals';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardTotalSaved => 'Total saved';

  @override
  String dashboardGeneralSavings(String amount) {
    return 'General savings: $amount';
  }

  @override
  String dashboardDepositCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deposits',
      one: '1 deposit',
      zero: 'No deposits yet',
    );
    return '$_temp0';
  }

  @override
  String get dashboardSaveMoney => 'Save money';

  @override
  String get dashboardActiveGoals => 'Active goals';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get dashboardNoGoalsTitle => 'No goals yet';

  @override
  String get dashboardNoGoalsBody =>
      'Create a goal, such as new stock or equipment, and Fanikisha will help you save for it.';

  @override
  String get dashboardCreateGoal => 'Create a goal';

  @override
  String goalDailyTarget(String amount) {
    return 'Save $amount a day to finish on time';
  }

  @override
  String goalDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String goalSavedOf(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String get goalStatusCompleted => 'Completed';

  @override
  String get goalStatusArchived => 'Archived';

  @override
  String get priority1 => 'Low';

  @override
  String get priority2 => 'Fairly low';

  @override
  String get priority3 => 'Medium';

  @override
  String get priority4 => 'High';

  @override
  String get priority5 => 'Very high';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsFilterActive => 'Active';

  @override
  String get goalsFilterCompleted => 'Completed';

  @override
  String get goalsFilterArchived => 'Archived';

  @override
  String get goalsEmptyActive => 'You have no active goals.';

  @override
  String get goalsEmptyCompleted => 'No completed goals yet. Keep saving!';

  @override
  String get goalsEmptyArchived => 'No archived goals.';

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalDetailSaved => 'Saved';

  @override
  String get goalDetailTarget => 'Target';

  @override
  String get goalDetailRemaining => 'Still needed';

  @override
  String get goalDetailDailyTarget => 'Needed per day';

  @override
  String get goalDetailTargetDate => 'Target date';

  @override
  String get goalDetailPriority => 'Priority';

  @override
  String get goalDetailCategory => 'Category';

  @override
  String get goalEdit => 'Edit goal';

  @override
  String get goalArchive => 'Archive goal';

  @override
  String get goalArchiveConfirmTitle => 'Archive this goal?';

  @override
  String goalArchiveConfirmBody(String amount) {
    return 'It will stop receiving new savings. The $amount already saved stays recorded.';
  }

  @override
  String get goalArchiveConfirmButton => 'Archive';

  @override
  String get goalFormNewTitle => 'New goal';

  @override
  String get goalFormEditTitle => 'Edit goal';

  @override
  String get goalNameLabel => 'What are you saving for?';

  @override
  String get goalNameHint => 'e.g. New fridge for the shop';

  @override
  String get goalCategoryLabel => 'Category (optional)';

  @override
  String get goalCategoryHint => 'e.g. Stock, Equipment, Rent';

  @override
  String get goalTargetAmountLabel => 'Target amount';

  @override
  String get amountInvalid => 'Enter an amount greater than zero';

  @override
  String get goalTargetDateLabel => 'Target date';

  @override
  String get goalTargetDateMissing => 'Choose a target date';

  @override
  String get goalPriorityLabel => 'How important is it?';

  @override
  String get goalPriorityHelper =>
      'More important goals get a bigger share of each deposit.';

  @override
  String get goalFormCreate => 'Create goal';

  @override
  String get goalFormSave => 'Save changes';

  @override
  String get depositTitle => 'Save money';

  @override
  String get depositAmountLabel => 'Amount';

  @override
  String get depositNoteLabel => 'Note (optional)';

  @override
  String get depositNoteHint => 'e.g. Monday\'s sales';

  @override
  String get depositPreviewTitle => 'How it will be shared';

  @override
  String get depositPreviewEmpty =>
      'Enter an amount to see how it will be shared between your goals.';

  @override
  String get depositPreviewNoGoals =>
      'You have no active goals, so this will go to general savings.';

  @override
  String get generalSavings => 'General savings';

  @override
  String depositSubmit(String amount) {
    return 'Save $amount';
  }

  @override
  String get depositSuccessTitle => 'Saved!';

  @override
  String depositSuccessBody(String amount) {
    return '$amount has been added to your savings.';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No savings yet. Your deposits will appear here.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLogOutConfirm => 'Log out of Fanikisha on this device?';

  @override
  String get changePasswordCurrent => 'Current password';

  @override
  String get changePasswordNew => 'New password';

  @override
  String get changePasswordSubmit => 'Change password';

  @override
  String get changePasswordDone =>
      'Password changed. Your other devices have been logged out.';

  @override
  String get languageSystem => 'Same as device';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get verifyPhoneTitle => 'Verify phone number';

  @override
  String verifyPhoneSending(String phone) {
    return 'Sending a code to $phone…';
  }

  @override
  String verifyPhoneSentTo(String phone) {
    return 'We sent a 6-digit code to $phone.';
  }

  @override
  String get verifyPhoneCodeLabel => 'Verification code';

  @override
  String get verifyPhoneSubmit => 'Verify';

  @override
  String get verifyPhoneResend => 'Send a new code';

  @override
  String verifyPhoneResendIn(int seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get verifyPhoneDone => 'Phone number verified';

  @override
  String get phoneVerified => 'Verified';

  @override
  String get verifyPhoneBannerTitle => 'Verify your phone number';

  @override
  String get verifyPhoneBannerBody =>
      'You\'ll need it to save with mobile money.';

  @override
  String get verifyPhoneAction => 'Verify now';

  @override
  String get phoneErrorNoPhone => 'Add a phone number to your profile first.';

  @override
  String phoneErrorResendTooSoon(int seconds) {
    return 'Please wait $seconds seconds before asking for a new code.';
  }

  @override
  String get phoneErrorDailyLimit =>
      'Too many codes today. Please try again tomorrow.';

  @override
  String get phoneErrorSmsFailed =>
      'We couldn\'t send the SMS. Please try again later.';

  @override
  String get phoneErrorCodeExpired => 'This code has expired. Send a new one.';

  @override
  String phoneErrorCodeIncorrect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'That code is not correct. $count tries left.',
      one: 'That code is not correct. 1 try left.',
    );
    return '$_temp0';
  }

  @override
  String get phoneErrorTooManyAttempts =>
      'Too many wrong codes. Send a new one.';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordIntro =>
      'Enter your account\'s email. We\'ll text a code to the phone number you verified on it.';

  @override
  String get forgotPasswordSend => 'Send code';

  @override
  String forgotPasswordSent(String email) {
    return 'If $email has an account with a verified phone number, we\'ve texted a code to that number.';
  }

  @override
  String get forgotPasswordNoPhone =>
      'No verified phone number on your account? Then it can\'t be reset by SMS yet.';

  @override
  String get forgotPasswordSubmit => 'Reset password';

  @override
  String get forgotPasswordOtherEmail => 'Use a different email';

  @override
  String get errorWrongPassword => 'That password is not correct.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account, your goals and your savings history, and signs you out on every device. It can\'t be undone.';

  @override
  String get deleteAccountPassword => 'Enter your password to confirm';

  @override
  String get deleteAccountSubmit => 'Delete my account';

  @override
  String get deleteAccountDone => 'Your account has been deleted.';

  @override
  String offlineSavedToday(String time) {
    return 'You\'re offline. Showing what was saved at $time.';
  }

  @override
  String offlineSavedEarlier(String date) {
    return 'You\'re offline. Showing what was saved on $date.';
  }
}
