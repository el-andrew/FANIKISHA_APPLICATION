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
  /// **'Total savings'**
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
  /// **'Enter an amount to see the split.'**
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
  /// **'Verify your phone'**
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

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your account\'s email. We\'ll text a code to the phone number you verified on it.'**
  String get forgotPasswordIntro;

  /// No description provided for @forgotPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotPasswordSend;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account with a verified phone number, we\'ve texted a code to that number.'**
  String forgotPasswordSent(String email);

  /// No description provided for @forgotPasswordNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No verified phone number on your account? Then it can\'t be reset by SMS yet.'**
  String get forgotPasswordNoPhone;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordOtherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get forgotPasswordOtherEmail;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is not correct.'**
  String get errorWrongPassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, your goals and your savings history, and signs you out on every device. It can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteAccountPassword;

  /// No description provided for @deleteAccountSubmit.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountSubmit;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountDone;

  /// No description provided for @offlineSavedToday.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing what was saved at {time}.'**
  String offlineSavedToday(String time);

  /// No description provided for @offlineSavedEarlier.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing what was saved on {date}.'**
  String offlineSavedEarlier(String date);

  /// No description provided for @legalAgreement.
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you accept the terms of service and the privacy policy.'**
  String get legalAgreement;

  /// No description provided for @legalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get legalTerms;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legalPrivacy;

  /// No description provided for @navBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get navBusiness;

  /// No description provided for @businessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessTitle;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @period7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get period7Days;

  /// No description provided for @period30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get period30Days;

  /// No description provided for @businessSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get businessSales;

  /// No description provided for @businessExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get businessExpenses;

  /// No description provided for @businessProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get businessProfit;

  /// No description provided for @businessLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get businessLoss;

  /// No description provided for @businessTopExpenses.
  ///
  /// In en, this message translates to:
  /// **'Biggest expenses'**
  String get businessTopExpenses;

  /// No description provided for @businessRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent entries'**
  String get businessRecent;

  /// No description provided for @businessEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sales or expenses yet. Record them each day to see your profit.'**
  String get businessEmpty;

  /// No description provided for @businessAdd.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get businessAdd;

  /// No description provided for @entryNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get entryNewTitle;

  /// No description provided for @entryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get entryEditTitle;

  /// No description provided for @entrySale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get entrySale;

  /// No description provided for @entryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get entryExpense;

  /// No description provided for @entryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get entryAmount;

  /// No description provided for @entryCategory.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get entryCategory;

  /// No description provided for @entryNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get entryNote;

  /// No description provided for @entryDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get entryDate;

  /// No description provided for @entrySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get entrySave;

  /// No description provided for @entryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get entryDelete;

  /// No description provided for @entryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get entryDeleteConfirm;

  /// No description provided for @entryDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get entryDeleteAction;

  /// No description provided for @entryUncategorised.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get entryUncategorised;

  /// No description provided for @categoryStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get categoryStock;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryWages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get categoryWages;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Electricity & water'**
  String get categoryUtilities;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @todayRuleSales.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of today\'s sales ({amount})'**
  String todayRuleSales(int percent, String amount);

  /// No description provided for @todayRuleProfit.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of today\'s profit ({amount})'**
  String todayRuleProfit(int percent, String amount);

  /// No description provided for @todaySavedOf.
  ///
  /// In en, this message translates to:
  /// **'Saved today: {saved} of {target}'**
  String todaySavedOf(String saved, String target);

  /// No description provided for @todayReached.
  ///
  /// In en, this message translates to:
  /// **'Today\'s target reached. Well done!'**
  String get todayReached;

  /// No description provided for @todayNoSales.
  ///
  /// In en, this message translates to:
  /// **'Record today\'s sales to see how much to save.'**
  String get todayNoSales;

  /// No description provided for @todayNoProfit.
  ///
  /// In en, this message translates to:
  /// **'No profit yet today, so nothing to save from it.'**
  String get todayNoProfit;

  /// No description provided for @todayRecordSales.
  ///
  /// In en, this message translates to:
  /// **'Record sales'**
  String get todayRecordSales;

  /// No description provided for @ruleSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Save a share of daily sales'**
  String get ruleSetupTitle;

  /// No description provided for @ruleSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Set a rule, such as 10% of each day\'s sales, and Fanikisha will tell you how much to save every day.'**
  String get ruleSetupBody;

  /// No description provided for @ruleSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Set a rule'**
  String get ruleSetupAction;

  /// No description provided for @ruleTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving rule'**
  String get ruleTitle;

  /// No description provided for @ruleBasisLabel.
  ///
  /// In en, this message translates to:
  /// **'Save a share of each day\'s'**
  String get ruleBasisLabel;

  /// No description provided for @rulePercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get rulePercentLabel;

  /// No description provided for @rulePercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 100'**
  String get rulePercentInvalid;

  /// No description provided for @ruleExampleSales.
  ///
  /// In en, this message translates to:
  /// **'With {sales} in sales, you would save {saving}.'**
  String ruleExampleSales(String sales, String saving);

  /// No description provided for @ruleExampleProfit.
  ///
  /// In en, this message translates to:
  /// **'With {profit} in profit, you would save {saving}.'**
  String ruleExampleProfit(String profit, String saving);

  /// No description provided for @ruleSave.
  ///
  /// In en, this message translates to:
  /// **'Save rule'**
  String get ruleSave;

  /// No description provided for @ruleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove rule'**
  String get ruleRemove;

  /// No description provided for @ruleSaved.
  ///
  /// In en, this message translates to:
  /// **'Saving rule saved'**
  String get ruleSaved;

  /// No description provided for @ruleEdit.
  ///
  /// In en, this message translates to:
  /// **'Change rule'**
  String get ruleEdit;

  /// No description provided for @moveMoney.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get moveMoney;

  /// No description provided for @withdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawMoney;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Take money out'**
  String get withdrawTitle;

  /// No description provided for @moveFrom.
  ///
  /// In en, this message translates to:
  /// **'From {place}: {amount} available'**
  String moveFrom(String place, String amount);

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @moveSubmit.
  ///
  /// In en, this message translates to:
  /// **'Move {amount}'**
  String moveSubmit(String amount);

  /// No description provided for @withdrawSubmit.
  ///
  /// In en, this message translates to:
  /// **'Take out {amount}'**
  String withdrawSubmit(String amount);

  /// No description provided for @withdrawNote.
  ///
  /// In en, this message translates to:
  /// **'What was it for? (optional)'**
  String get withdrawNote;

  /// No description provided for @withdrawExplain.
  ///
  /// In en, this message translates to:
  /// **'Fanikisha doesn\'t hold your money: this records that you took it out of your savings.'**
  String get withdrawExplain;

  /// No description provided for @amountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'That\'s more than the {amount} available'**
  String amountTooHigh(String amount);

  /// No description provided for @amountAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get amountAll;

  /// No description provided for @moveDone.
  ///
  /// In en, this message translates to:
  /// **'Money moved'**
  String get moveDone;

  /// No description provided for @withdrawDone.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal recorded'**
  String get withdrawDone;

  /// No description provided for @moveNoDestination.
  ///
  /// In en, this message translates to:
  /// **'There\'s nowhere to move it yet. Create another goal first.'**
  String get moveNoDestination;

  /// No description provided for @activityWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Taken out of {place}'**
  String activityWithdrawal(String place);

  /// No description provided for @activityTransfer.
  ///
  /// In en, this message translates to:
  /// **'Moved from {from} to {to}'**
  String activityTransfer(String from, String to);

  /// No description provided for @goalLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left in this goal'**
  String goalLeft(String amount);

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Evenings around {time}, when a goal falls behind or today\'s saving is due'**
  String remindersOnSubtitle(String time);

  /// No description provided for @remindersOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get remindersOffSubtitle;

  /// No description provided for @remindersTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get remindersTime;

  /// No description provided for @remindersBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for Fanikisha. Allow them in your phone\'s settings, then try again.'**
  String get remindersBlocked;

  /// No description provided for @remindersTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening reminders'**
  String get remindersTipTitle;

  /// No description provided for @remindersTipBody.
  ///
  /// In en, this message translates to:
  /// **'Get an evening reminder when a goal falls behind or today\'s saving is still to do.'**
  String get remindersTipBody;

  /// No description provided for @remindersTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get remindersTurnOn;

  /// No description provided for @remindersOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminders on: evenings around {time}'**
  String remindersOnMessage(String time);

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Saving reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'When a goal falls behind or today\'s saving is due'**
  String get reminderChannelDescription;

  /// No description provided for @reminderSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} today'**
  String reminderSaveTitle(String amount);

  /// No description provided for @reminderSaveBodySales.
  ///
  /// In en, this message translates to:
  /// **'That\'s {percent}% of today\'s sales, as your rule says.'**
  String reminderSaveBodySales(String percent);

  /// No description provided for @reminderSaveBodyProfit.
  ///
  /// In en, this message translates to:
  /// **'That\'s {percent}% of today\'s profit, as your rule says.'**
  String reminderSaveBodyProfit(String percent);

  /// No description provided for @reminderBehindTitle.
  ///
  /// In en, this message translates to:
  /// **'{goal} is falling behind'**
  String reminderBehindTitle(String goal);

  /// No description provided for @reminderBehindBody.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} a day to reach it by {date}.'**
  String reminderBehindBody(String amount, String date);

  /// No description provided for @reminderOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'{goal} is past its target date'**
  String reminderOverdueTitle(String goal);

  /// No description provided for @reminderOverdueBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} still to save. Keep going, or pick a new date.'**
  String reminderOverdueBody(String amount);

  /// No description provided for @reminderRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'How did business go today?'**
  String get reminderRecordTitle;

  /// No description provided for @reminderRecordBodySales.
  ///
  /// In en, this message translates to:
  /// **'Record today\'s sales to see what your {percent}% rule saves.'**
  String reminderRecordBodySales(String percent);

  /// No description provided for @reminderRecordBodyProfit.
  ///
  /// In en, this message translates to:
  /// **'Record today\'s sales and expenses to see what your {percent}% rule saves.'**
  String reminderRecordBodyProfit(String percent);

  /// No description provided for @splashSlowStart.
  ///
  /// In en, this message translates to:
  /// **'Starting up… this can take up to a minute.'**
  String get splashSlowStart;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @balanceShow.
  ///
  /// In en, this message translates to:
  /// **'Show balance'**
  String get balanceShow;

  /// No description provided for @balanceHide.
  ///
  /// In en, this message translates to:
  /// **'Hide balance'**
  String get balanceHide;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get actionMove;

  /// No description provided for @actionWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get actionWithdraw;

  /// No description provided for @actionRecordSale.
  ///
  /// In en, this message translates to:
  /// **'Record sale'**
  String get actionRecordSale;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get homeRecentActivity;

  /// No description provided for @goalOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get goalOnTrack;

  /// No description provided for @goalBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind'**
  String get goalBehind;

  /// No description provided for @todayChipSales.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of sales'**
  String todayChipSales(String percent);

  /// No description provided for @todayChipProfit.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of profit'**
  String todayChipProfit(String percent);

  /// No description provided for @todayOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String todayOfTarget(String target);

  /// No description provided for @chooseSourceMove.
  ///
  /// In en, this message translates to:
  /// **'Move money from'**
  String get chooseSourceMove;

  /// No description provided for @chooseSourceWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Take money out of'**
  String get chooseSourceWithdraw;

  /// No description provided for @nothingToMove.
  ///
  /// In en, this message translates to:
  /// **'There\'s no saved money to move yet.'**
  String get nothingToMove;

  /// No description provided for @activitySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get activitySaved;

  /// After today's target is reached: the target, next to what was saved.
  ///
  /// In en, this message translates to:
  /// **'target {target}'**
  String todayTargetWas(String target);

  /// No description provided for @homeNoActivity.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get homeNoActivity;

  /// No description provided for @goalBehindBy.
  ///
  /// In en, this message translates to:
  /// **'{amount} behind pace'**
  String goalBehindBy(String amount);

  /// No description provided for @goalPercentSaved.
  ///
  /// In en, this message translates to:
  /// **'{percent}% saved'**
  String goalPercentSaved(String percent);

  /// No description provided for @goalShouldBe.
  ///
  /// In en, this message translates to:
  /// **'Should be {percent}% by today'**
  String goalShouldBe(String percent);

  /// No description provided for @goalToFinish.
  ///
  /// In en, this message translates to:
  /// **'To finish on time, save'**
  String get goalToFinish;

  /// No description provided for @goalPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} a day'**
  String goalPerDay(String amount);

  /// No description provided for @goalDaysLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day left} other{days left}}'**
  String goalDaysLeftLabel(int count);

  /// No description provided for @actionMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get actionMore;

  /// No description provided for @depositQuickAmounts.
  ///
  /// In en, this message translates to:
  /// **'Quick amounts'**
  String get depositQuickAmounts;
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
