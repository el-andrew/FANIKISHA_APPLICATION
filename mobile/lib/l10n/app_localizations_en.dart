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
  String get dashboardTotalSaved => 'Total savings';

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
  String get goalsEmptyActive => 'No active goals.';

  @override
  String get goalsEmptyCompleted => 'No completed goals yet.';

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
  String get depositPreviewEmpty => 'Enter an amount to see the split.';

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
  String get verifyPhoneBannerTitle => 'Verify your phone';

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

  @override
  String get legalAgreement =>
      'By creating an account, you accept the terms of service and the privacy policy.';

  @override
  String get legalTerms => 'Terms of service';

  @override
  String get legalPrivacy => 'Privacy policy';

  @override
  String get navBusiness => 'Business';

  @override
  String get businessTitle => 'Business';

  @override
  String get periodToday => 'Today';

  @override
  String get period7Days => '7 days';

  @override
  String get period30Days => '30 days';

  @override
  String get businessSales => 'Sales';

  @override
  String get businessExpenses => 'Expenses';

  @override
  String get businessProfit => 'Profit';

  @override
  String get businessLoss => 'Loss';

  @override
  String get businessTopExpenses => 'Biggest expenses';

  @override
  String get businessRecent => 'Recent entries';

  @override
  String get businessEmpty => 'No entries yet.';

  @override
  String get businessAdd => 'Add entry';

  @override
  String get entryNewTitle => 'New entry';

  @override
  String get entryEditTitle => 'Edit entry';

  @override
  String get entrySale => 'Sale';

  @override
  String get entryExpense => 'Expense';

  @override
  String get entryAmount => 'Amount';

  @override
  String get entryCategory => 'Category (optional)';

  @override
  String get entryNote => 'Note (optional)';

  @override
  String get entryDate => 'Date';

  @override
  String get entrySave => 'Save';

  @override
  String get entryDelete => 'Delete entry';

  @override
  String get entryDeleteConfirm => 'Delete this entry?';

  @override
  String get entryDeleteAction => 'Delete';

  @override
  String get entryUncategorised => 'Other';

  @override
  String get categoryStock => 'Stock';

  @override
  String get categoryRent => 'Rent';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryWages => 'Wages';

  @override
  String get categoryUtilities => 'Electricity & water';

  @override
  String get todayTitle => 'Today';

  @override
  String todayRuleSales(int percent, String amount) {
    return '$percent% of today\'s sales ($amount)';
  }

  @override
  String todayRuleProfit(int percent, String amount) {
    return '$percent% of today\'s profit ($amount)';
  }

  @override
  String todaySavedOf(String saved, String target) {
    return 'Saved today: $saved of $target';
  }

  @override
  String get todayReached => 'Today\'s target reached. Well done!';

  @override
  String get todayNoSales => 'Record today\'s sales to see how much to save.';

  @override
  String get todayNoProfit =>
      'No profit yet today, so nothing to save from it.';

  @override
  String get todayRecordSales => 'Record sales';

  @override
  String get ruleSetupTitle => 'Save a share of daily sales';

  @override
  String get ruleSetupBody =>
      'Set a rule, such as 10% of each day\'s sales, and Fanikisha will tell you how much to save every day.';

  @override
  String get ruleSetupAction => 'Set a rule';

  @override
  String get ruleTitle => 'Saving rule';

  @override
  String get ruleBasisLabel => 'Save a share of each day\'s';

  @override
  String get rulePercentLabel => 'Percentage';

  @override
  String get rulePercentInvalid => 'Enter a whole number from 1 to 100';

  @override
  String ruleExampleSales(String sales, String saving) {
    return 'With $sales in sales, you would save $saving.';
  }

  @override
  String ruleExampleProfit(String profit, String saving) {
    return 'With $profit in profit, you would save $saving.';
  }

  @override
  String get ruleSave => 'Save rule';

  @override
  String get ruleRemove => 'Remove rule';

  @override
  String get ruleSaved => 'Saving rule saved';

  @override
  String get ruleEdit => 'Change rule';

  @override
  String get moveMoney => 'Move money';

  @override
  String get withdrawMoney => 'Withdraw';

  @override
  String get withdrawTitle => 'Take money out';

  @override
  String moveFrom(String place, String amount) {
    return 'From $place: $amount available';
  }

  @override
  String get moveTo => 'Move to';

  @override
  String moveSubmit(String amount) {
    return 'Move $amount';
  }

  @override
  String withdrawSubmit(String amount) {
    return 'Take out $amount';
  }

  @override
  String get withdrawNote => 'What was it for? (optional)';

  @override
  String get withdrawExplain =>
      'Fanikisha doesn\'t hold your money: this records that you took it out of your savings.';

  @override
  String amountTooHigh(String amount) {
    return 'That\'s more than the $amount available';
  }

  @override
  String get amountAll => 'All';

  @override
  String get moveDone => 'Money moved';

  @override
  String get withdrawDone => 'Withdrawal recorded';

  @override
  String get moveNoDestination =>
      'There\'s nowhere to move it yet. Create another goal first.';

  @override
  String activityWithdrawal(String place) {
    return 'Taken out of $place';
  }

  @override
  String activityTransfer(String from, String to) {
    return 'Moved from $from to $to';
  }

  @override
  String goalLeft(String amount) {
    return '$amount left in this goal';
  }

  @override
  String get remindersTitle => 'Reminders';

  @override
  String remindersOnSubtitle(String time) {
    return 'Evenings around $time, when a goal falls behind or today\'s saving is due';
  }

  @override
  String get remindersOffSubtitle => 'Off';

  @override
  String get remindersTime => 'Reminder time';

  @override
  String get remindersBlocked =>
      'Notifications are blocked for Fanikisha. Allow them in your phone\'s settings, then try again.';

  @override
  String get remindersTipTitle => 'Evening reminders';

  @override
  String get remindersTipBody =>
      'Get an evening reminder when a goal falls behind or today\'s saving is still to do.';

  @override
  String get remindersTurnOn => 'Turn on';

  @override
  String remindersOnMessage(String time) {
    return 'Reminders on: evenings around $time';
  }

  @override
  String get actionNotNow => 'Not now';

  @override
  String get reminderChannelName => 'Saving reminders';

  @override
  String get reminderChannelDescription =>
      'When a goal falls behind or today\'s saving is due';

  @override
  String reminderSaveTitle(String amount) {
    return 'Save $amount today';
  }

  @override
  String reminderSaveBodySales(String percent) {
    return 'That\'s $percent% of today\'s sales, as your rule says.';
  }

  @override
  String reminderSaveBodyProfit(String percent) {
    return 'That\'s $percent% of today\'s profit, as your rule says.';
  }

  @override
  String reminderBehindTitle(String goal) {
    return '$goal is falling behind';
  }

  @override
  String reminderBehindBody(String amount, String date) {
    return 'Save $amount a day to reach it by $date.';
  }

  @override
  String reminderOverdueTitle(String goal) {
    return '$goal is past its target date';
  }

  @override
  String reminderOverdueBody(String amount) {
    return '$amount still to save. Keep going, or pick a new date.';
  }

  @override
  String get reminderRecordTitle => 'How did business go today?';

  @override
  String reminderRecordBodySales(String percent) {
    return 'Record today\'s sales to see what your $percent% rule saves.';
  }

  @override
  String reminderRecordBodyProfit(String percent) {
    return 'Record today\'s sales and expenses to see what your $percent% rule saves.';
  }

  @override
  String get splashSlowStart => 'Starting up… this can take up to a minute.';

  @override
  String get navAccount => 'Account';

  @override
  String get balanceShow => 'Show balance';

  @override
  String get balanceHide => 'Hide balance';

  @override
  String get actionSave => 'Save';

  @override
  String get actionMove => 'Move';

  @override
  String get actionWithdraw => 'Withdraw';

  @override
  String get actionRecordSale => 'Record sale';

  @override
  String get homeRecentActivity => 'Recent activity';

  @override
  String get goalOnTrack => 'On track';

  @override
  String get goalBehind => 'Behind';

  @override
  String todayChipSales(String percent) {
    return '$percent% of sales';
  }

  @override
  String todayChipProfit(String percent) {
    return '$percent% of profit';
  }

  @override
  String todayOfTarget(String target) {
    return 'of $target';
  }

  @override
  String get chooseSourceMove => 'Move money from';

  @override
  String get chooseSourceWithdraw => 'Take money out of';

  @override
  String get nothingToMove => 'There\'s no saved money to move yet.';

  @override
  String get activitySaved => 'Saved';

  @override
  String todayTargetWas(String target) {
    return 'target $target';
  }

  @override
  String get homeNoActivity => 'Nothing yet';

  @override
  String goalBehindBy(String amount) {
    return '$amount behind pace';
  }

  @override
  String goalPercentSaved(String percent) {
    return '$percent% saved';
  }

  @override
  String goalShouldBe(String percent) {
    return 'Should be $percent% by today';
  }

  @override
  String get goalToFinish => 'To finish on time, save';

  @override
  String goalPerDay(String amount) {
    return '$amount a day';
  }

  @override
  String goalDaysLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days left',
      one: 'day left',
    );
    return '$_temp0';
  }

  @override
  String get actionMore => 'More options';

  @override
  String get depositQuickAmounts => 'Quick amounts';

  @override
  String get businessEachDay => 'Each day';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String get depositAmountTzs => 'Amount in TZS';
}
