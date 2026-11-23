import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fanikisha'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Level up your saving habit'**
  String get tagline;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get actionLogOut;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Fanikisha. Check your internet connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again in a moment.'**
  String get errorServer;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please log in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Save for what your business needs next'**
  String get welcomeHeadline;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Set goals for stock, equipment or rent. Each time you save, Fanikisha shares the money between your goals so the most urgent ones fill first.'**
  String get welcomeBody;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcomeCreateAccount;

  /// No description provided for @welcomeLogIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeLogIn;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDoNotMatch;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameInvalid;

  /// No description provided for @businessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business name (optional)'**
  String get businessNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'International format, e.g. +255712345678'**
  String get phoneHelper;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use international format, e.g. +255712345678'**
  String get phoneInvalid;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @loginWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get loginWrongCredentials;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Fanikisha?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registerLogIn;

  /// No description provided for @splashRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your account.'**
  String get splashRestoreFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardTotalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total saved'**
  String get dashboardTotalSaved;

  /// No description provided for @dashboardGeneralSavings.
  ///
  /// In en, this message translates to:
  /// **'General savings: {amount}'**
  String dashboardGeneralSavings(String amount);

  /// No description provided for @dashboardDepositCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No deposits yet} =1{1 deposit} other{{count} deposits}}'**
  String dashboardDepositCount(int count);

  /// No description provided for @dashboardSaveMoney.
  ///
  /// In en, this message translates to:
  /// **'Save money'**
  String get dashboardSaveMoney;

  /// No description provided for @dashboardActiveGoals.
  ///
  /// In en, this message translates to:
  /// **'Active goals'**
  String get dashboardActiveGoals;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardNoGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get dashboardNoGoalsTitle;

  /// No description provided for @dashboardNoGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Create a goal, such as new stock or equipment, and Fanikisha will help you save for it.'**
  String get dashboardNoGoalsBody;

  /// No description provided for @dashboardCreateGoal.
  ///
  /// In en, this message translates to:
  /// **'Create a goal'**
  String get dashboardCreateGoal;

  /// No description provided for @goalDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} a day to finish on time'**
  String goalDailyTarget(String amount);

  /// No description provided for @goalDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String goalDaysLeft(int count);

  /// No description provided for @goalSavedOf.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target}'**
  String goalSavedOf(String saved, String target);

  /// No description provided for @goalStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalStatusCompleted;

  /// No description provided for @goalStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get goalStatusArchived;

  /// No description provided for @priority1.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priority1;

  /// No description provided for @priority2.
  ///
  /// In en, this message translates to:
  /// **'Fairly low'**
  String get priority2;

  /// No description provided for @priority3.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priority3;

  /// No description provided for @priority4.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priority4;

  /// No description provided for @priority5.
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get priority5;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTitle;

  /// No description provided for @goalsFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalsFilterActive;

  /// No description provided for @goalsFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalsFilterCompleted;

  /// No description provided for @goalsFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get goalsFilterArchived;

  /// No description provided for @goalsEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'You have no active goals.'**
  String get goalsEmptyActive;

  /// No description provided for @goalsEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed goals yet. Keep saving!'**
  String get goalsEmptyCompleted;

  /// No description provided for @goalsEmptyArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived goals.'**
  String get goalsEmptyArchived;

  /// No description provided for @goalsNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNew;

  /// No description provided for @goalDetailSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get goalDetailSaved;

  /// No description provided for @goalDetailTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalDetailTarget;

  /// No description provided for @goalDetailRemaining.
  ///
  /// In en, this message translates to:
  /// **'Still needed'**
  String get goalDetailRemaining;

  /// No description provided for @goalDetailDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Needed per day'**
  String get goalDetailDailyTarget;

  /// No description provided for @goalDetailTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get goalDetailTargetDate;

  /// No description provided for @goalDetailPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get goalDetailPriority;

  /// No description provided for @goalDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get goalDetailCategory;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEdit;

  /// No description provided for @goalArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive goal'**
  String get goalArchive;

  /// No description provided for @goalArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this goal?'**
  String get goalArchiveConfirmTitle;

  /// No description provided for @goalArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It will stop receiving new savings. The {amount} already saved stays recorded.'**
  String goalArchiveConfirmBody(String amount);

  /// No description provided for @goalArchiveConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get goalArchiveConfirmButton;

  /// No description provided for @goalFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalFormNewTitle;

  /// No description provided for @goalFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalFormEditTitle;

  /// No description provided for @goalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'What are you saving for?'**
  String get goalNameLabel;

  /// No description provided for @goalNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. New fridge for the shop'**
  String get goalNameHint;

  /// No description provided for @goalCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get goalCategoryLabel;

  /// No description provided for @goalCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Stock, Equipment, Rent'**
  String get goalCategoryHint;

  /// No description provided for @goalTargetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalTargetAmountLabel;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get amountInvalid;

  /// No description provided for @goalTargetDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get goalTargetDateLabel;

  /// No description provided for @goalTargetDateMissing.
  ///
  /// In en, this message translates to:
  /// **'Choose a target date'**
  String get goalTargetDateMissing;

  /// No description provided for @goalPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'How important is it?'**
  String get goalPriorityLabel;

  /// No description provided for @goalPriorityHelper.
  ///
  /// In en, this message translates to:
  /// **'More important goals get a bigger share of each deposit.'**
  String get goalPriorityHelper;

  /// No description provided for @goalFormCreate.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get goalFormCreate;

  /// No description provided for @goalFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get goalFormSave;

  /// No description provided for @depositTitle.
  ///
  /// In en, this message translates to:
  /// **'Save money'**
  String get depositTitle;

  /// No description provided for @depositAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get depositAmountLabel;

  /// No description provided for @depositNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get depositNoteLabel;

  /// No description provided for @depositNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monday\'s sales'**
  String get depositNoteHint;

  /// No description provided for @depositPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'How it will be shared'**
  String get depositPreviewTitle;

  /// No description provided for @depositPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount to see how it will be shared between your goals.'**
  String get depositPreviewEmpty;

  /// No description provided for @depositPreviewNoGoals.
  ///
  /// In en, this message translates to:
  /// **'You have no active goals, so this will go to general savings.'**
  String get depositPreviewNoGoals;

  /// No description provided for @generalSavings.
  ///
  /// In en, this message translates to:
  /// **'General savings'**
  String get generalSavings;

  /// No description provided for @depositSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String depositSubmit(String amount);

  /// No description provided for @depositSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get depositSuccessTitle;

  /// No description provided for @depositSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} has been added to your savings.'**
  String depositSuccessBody(String amount);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No savings yet. Your deposits will appear here.'**
  String get historyEmpty;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLogOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of Fanikisha on this device?'**
  String get profileLogOutConfirm;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Your other devices have been logged out.'**
  String get changePasswordDone;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get languageSwahili;

  /// No description provided for @verifyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify phone number'**
  String get verifyPhoneTitle;

  /// No description provided for @verifyPhoneSending.
  ///
  /// In en, this message translates to:
  /// **'Sending a code to {phone}…'**
  String verifyPhoneSending(String phone);

  /// No description provided for @verifyPhoneSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}.'**
  String verifyPhoneSentTo(String phone);

  /// No description provided for @verifyPhoneCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verifyPhoneCodeLabel;

  /// No description provided for @verifyPhoneSubmit.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyPhoneSubmit;

  /// No description provided for @verifyPhoneResend.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get verifyPhoneResend;

  /// No description provided for @verifyPhoneResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String verifyPhoneResendIn(int seconds);

  /// No description provided for @verifyPhoneDone.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get verifyPhoneDone;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get phoneVerified;

  /// No description provided for @verifyPhoneBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number'**
  String get verifyPhoneBannerTitle;

  /// No description provided for @verifyPhoneBannerBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need it to save with mobile money.'**
  String get verifyPhoneBannerBody;

  /// No description provided for @verifyPhoneAction.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get verifyPhoneAction;

  /// No description provided for @phoneErrorNoPhone.
  ///
  /// In en, this message translates to:
  /// **'Add a phone number to your profile first.'**
  String get phoneErrorNoPhone;

  /// No description provided for @phoneErrorResendTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before asking for a new code.'**
  String phoneErrorResendTooSoon(int seconds);

  /// No description provided for @phoneErrorDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many codes today. Please try again tomorrow.'**
  String get phoneErrorDailyLimit;

  /// No description provided for @phoneErrorSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the SMS. Please try again later.'**
  String get phoneErrorSmsFailed;

  /// No description provided for @phoneErrorCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Send a new one.'**
  String get phoneErrorCodeExpired;

  /// No description provided for @phoneErrorCodeIncorrect.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{That code is not correct. 1 try left.} other{That code is not correct. {count} tries left.}}'**
  String phoneErrorCodeIncorrect(int count);

  /// No description provided for @phoneErrorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Send a new one.'**
  String get phoneErrorTooManyAttempts;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
