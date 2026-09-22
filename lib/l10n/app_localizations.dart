import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('es', '419'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fil'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @agreementHeading.
  ///
  /// In en, this message translates to:
  /// **'Please review and agree to the terms below to continue.'**
  String get agreementHeading;

  /// No description provided for @agreementTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Use.'**
  String get agreementTermsLabel;

  /// No description provided for @agreementPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Privacy Policy.'**
  String get agreementPrivacyLabel;

  /// No description provided for @agreementTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get agreementTermsTitle;

  /// No description provided for @agreementPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get agreementPrivacyTitle;

  /// No description provided for @agreementDetailsLink.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get agreementDetailsLink;

  /// No description provided for @agreementButtonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm and continue'**
  String get agreementButtonConfirm;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get settingsRestorePurchases;

  /// No description provided for @restorePurchasesNothing.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore.'**
  String get restorePurchasesNothing;

  /// No description provided for @restorePurchasesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get restorePurchasesCompleted;

  /// No description provided for @settingsNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get settingsNotification;

  /// No description provided for @settingsTutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get settingsTutorial;

  /// No description provided for @settingsCefrLevel.
  ///
  /// In en, this message translates to:
  /// **'Language Level'**
  String get settingsCefrLevel;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders and important updates.'**
  String get pushNotificationsDesc;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get settingsAnnouncements;

  /// No description provided for @announcementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get announcementsEmpty;

  /// No description provided for @noticesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noticesEmpty;

  /// No description provided for @deletedPost.
  ///
  /// In en, this message translates to:
  /// **'This post has been deleted.'**
  String get deletedPost;

  /// No description provided for @postNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get postNoLongerAvailable;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsFsdLaboratory.
  ///
  /// In en, this message translates to:
  /// **'FSD Laboratory'**
  String get settingsFsdLaboratory;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// No description provided for @settingsOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get settingsOpenSource;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String loginWelcome(String name);

  /// No description provided for @loginTermsTemplate.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our {terms} and {privacy}.'**
  String loginTermsTemplate(String terms, String privacy);

  /// No description provided for @loginTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get loginTermsTitle;

  /// No description provided for @loginPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get loginPrivacyTitle;

  /// No description provided for @loginCatchphrase.
  ///
  /// In en, this message translates to:
  /// **'Start talking. That\'s how you learn.'**
  String get loginCatchphrase;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SUDA!'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Step into a story and start speaking English!'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginErrorIdToken.
  ///
  /// In en, this message translates to:
  /// **'Failed to get Google ID Token. Please try again.'**
  String get loginErrorIdToken;

  /// No description provided for @loginErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginErrorFailed(String error);

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @accountChangePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Picture'**
  String get accountChangePicture;

  /// No description provided for @changeProfileImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Profile Picture'**
  String get changeProfileImageTitle;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendRequestsTab.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequestsTab;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendsEmpty;

  /// No description provided for @friendRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friend requests yet.'**
  String get friendRequestsEmpty;

  /// No description provided for @friendRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendRequestAccept;

  /// No description provided for @friendRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendRequestDecline;

  /// No description provided for @characterAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get characterAge;

  /// No description provided for @characterNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get characterNationality;

  /// No description provided for @characterOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get characterOccupation;

  /// No description provided for @characterInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get characterInterests;

  /// No description provided for @characterCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get characterCollection;

  /// No description provided for @characterSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get characterSecret;

  /// No description provided for @characterSeriesWith.
  ///
  /// In en, this message translates to:
  /// **'Series with {name}'**
  String characterSeriesWith(String name);

  /// No description provided for @characterSetAsProfile.
  ///
  /// In en, this message translates to:
  /// **'Set as Profile'**
  String get characterSetAsProfile;

  /// No description provided for @characterChangePictureTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture?'**
  String get characterChangePictureTitle;

  /// No description provided for @characterChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get characterChange;

  /// No description provided for @characterCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get characterCancel;

  /// No description provided for @characterChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change your profile picture. Please try again.'**
  String get characterChangeFailed;

  /// No description provided for @characterSecretLocked.
  ///
  /// In en, this message translates to:
  /// **'Complete the collection to unlock the Secret.'**
  String get characterSecretLocked;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountInfo;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteConfirmText.
  ///
  /// In en, this message translates to:
  /// **'All your progress and data will be permanently lost. Are you sure?'**
  String get accountDeleteConfirmText;

  /// No description provided for @accountDeleteProfileImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile image?'**
  String get accountDeleteProfileImageTitle;

  /// No description provided for @accountDeleteProfileImageContent.
  ///
  /// In en, this message translates to:
  /// **'Once deleted, your profile image cannot be recovered.'**
  String get accountDeleteProfileImageContent;

  /// No description provided for @accountGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get accountGoBack;

  /// No description provided for @accountDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountDeleteAction;

  /// No description provided for @accountSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get accountSubscription;

  /// No description provided for @accountFreePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get accountFreePlanTitle;

  /// No description provided for @accountFreePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get Premium to unlock more features'**
  String get accountFreePlanSubtitle;

  /// No description provided for @accountPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get accountPremiumTitle;

  /// No description provided for @accountPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re enjoying Premium benefits'**
  String get accountPremiumSubtitle;

  /// No description provided for @accountPremiumRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String accountPremiumRenewsOn(String date);

  /// No description provided for @accountChangePlan.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get accountChangePlan;

  /// No description provided for @changePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlanTitle;

  /// No description provided for @changePlanCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get changePlanCurrentPlan;

  /// No description provided for @changePlanAvailablePlans.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get changePlanAvailablePlans;

  /// No description provided for @changePlanRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String changePlanRenewsOn(String date);

  /// No description provided for @changePlanLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the information. Please try again.'**
  String get changePlanLoadFailed;

  /// No description provided for @changePlanRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get changePlanRetry;

  /// No description provided for @changePlanConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Plan?'**
  String get changePlanConfirmTitle;

  /// No description provided for @changePlanConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Plan changes take effect on your next billing date.'**
  String get changePlanConfirmBody;

  /// No description provided for @changePlanConfirmOk.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get changePlanConfirmOk;

  /// No description provided for @changePlanConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep Current Plan'**
  String get changePlanConfirmCancel;

  /// No description provided for @changePlanOldPurchaseMissing.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find an active subscription to change. Try again after your subscription is active.'**
  String get changePlanOldPurchaseMissing;

  /// No description provided for @changePlanChangeRequested.
  ///
  /// In en, this message translates to:
  /// **'Plan change requested. It may apply on your next billing date.'**
  String get changePlanChangeRequested;

  /// No description provided for @cefrLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your English level'**
  String get cefrLevelTitle;

  /// No description provided for @cefrLevelAbsoluteBeginner.
  ///
  /// In en, this message translates to:
  /// **'Absolute Beginner'**
  String get cefrLevelAbsoluteBeginner;

  /// No description provided for @cefrLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get cefrLevelBeginner;

  /// No description provided for @cefrLevelBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get cefrLevelBasic;

  /// No description provided for @cefrLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get cefrLevelIntermediate;

  /// No description provided for @firstCefrLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your English level?'**
  String get firstCefrLevelTitle;

  /// No description provided for @firstCefrLevelDescriptionPreA1.
  ///
  /// In en, this message translates to:
  /// **'I know how to read English'**
  String get firstCefrLevelDescriptionPreA1;

  /// No description provided for @firstCefrLevelDescriptionA1.
  ///
  /// In en, this message translates to:
  /// **'I know basic greetings and simple phrases'**
  String get firstCefrLevelDescriptionA1;

  /// No description provided for @firstCefrLevelDescriptionA2.
  ///
  /// In en, this message translates to:
  /// **'I can use and understand short, simple sentences'**
  String get firstCefrLevelDescriptionA2;

  /// No description provided for @firstCefrLevelDescriptionB1.
  ///
  /// In en, this message translates to:
  /// **'I can share my opinion and join everyday conversation'**
  String get firstCefrLevelDescriptionB1;

  /// No description provided for @firstCefrLevelSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can change it anytime'**
  String get firstCefrLevelSettingsHint;

  /// No description provided for @firstProfileImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your Profile Picture'**
  String get firstProfileImageTitle;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @feedbackPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please share your thoughts, suggestions, or any issues you\'ve encountered...'**
  String get feedbackPlaceholder;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback.'**
  String get feedbackSuccess;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Cannot start without microphone permission.'**
  String get microphonePermissionDenied;

  /// No description provided for @holdMicrophoneToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Hold microphone to speak'**
  String get holdMicrophoneToSpeak;

  /// No description provided for @roleplayTypeMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your message ...'**
  String get roleplayTypeMessagePlaceholder;

  /// No description provided for @yourTurnFirst.
  ///
  /// In en, this message translates to:
  /// **'Your turn first!'**
  String get yourTurnFirst;

  /// No description provided for @sayLineBelowToStart.
  ///
  /// In en, this message translates to:
  /// **'Say the line below to start.'**
  String get sayLineBelowToStart;

  /// No description provided for @roleplayExitWait.
  ///
  /// In en, this message translates to:
  /// **'Wait!'**
  String get roleplayExitWait;

  /// No description provided for @roleplayExitMessage.
  ///
  /// In en, this message translates to:
  /// **'If you leave now, you\'ll miss your reward. Are you sure you want to leave?'**
  String get roleplayExitMessage;

  /// No description provided for @roleplayExitKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep Playing'**
  String get roleplayExitKeepPlaying;

  /// No description provided for @roleplayExitExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get roleplayExitExit;

  /// No description provided for @roleplayAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Auto Hint'**
  String get roleplayAutoHint;

  /// No description provided for @roleplayHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get roleplayHintLabel;

  /// No description provided for @roleplayHintShowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap to see the English answer'**
  String get roleplayHintShowAnswer;

  /// No description provided for @roleplayVoiceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Voice Speed'**
  String get roleplayVoiceSpeed;

  /// No description provided for @roleplayEndedFailed.
  ///
  /// In en, this message translates to:
  /// **'Mission Failed...'**
  String get roleplayEndedFailed;

  /// No description provided for @roleplayEndedComplete.
  ///
  /// In en, this message translates to:
  /// **'Roleplay Completed'**
  String get roleplayEndedComplete;

  /// No description provided for @roleplayEndedEnding.
  ///
  /// In en, this message translates to:
  /// **'Moving to ending...'**
  String get roleplayEndedEnding;

  /// No description provided for @roleplayFinishNotEnoughProgress.
  ///
  /// In en, this message translates to:
  /// **'Not enough progress'**
  String get roleplayFinishNotEnoughProgress;

  /// No description provided for @roleplayFinishCompleted.
  ///
  /// In en, this message translates to:
  /// **'Roleplay completed'**
  String get roleplayFinishCompleted;

  /// No description provided for @roleplayFinishMovingToEnding.
  ///
  /// In en, this message translates to:
  /// **'Moving to ending...'**
  String get roleplayFinishMovingToEnding;

  /// No description provided for @roleplayAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your roleplay...'**
  String get roleplayAnalyzing;

  /// No description provided for @roleplayOpeningAiCharacter.
  ///
  /// In en, this message translates to:
  /// **'AI Character'**
  String get roleplayOpeningAiCharacter;

  /// No description provided for @roleplayOpeningScenario.
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get roleplayOpeningScenario;

  /// No description provided for @roleplayOpeningAiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI can make mistakes.\nPlease don\'t share personal or sensitive information.'**
  String get roleplayOpeningAiDisclaimer;

  /// No description provided for @endingFailTitle.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t complete all the missions!'**
  String get endingFailTitle;

  /// No description provided for @endingFailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try again and uncover the full story.'**
  String get endingFailSubtitle;

  /// No description provided for @roleplayTryAgainMessage.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your score wasn\'t high enough to earn the reward.'**
  String get roleplayTryAgainMessage;

  /// No description provided for @endingReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get endingReport;

  /// No description provided for @endingHowWas.
  ///
  /// In en, this message translates to:
  /// **'How was the Roleplay?'**
  String get endingHowWas;

  /// No description provided for @endingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get endingNext;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportTitle;

  /// No description provided for @profileProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get profileProgress;

  /// No description provided for @profileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get profileDayStreak;

  /// No description provided for @profileWordsSpoken.
  ///
  /// In en, this message translates to:
  /// **'Words Spoken'**
  String get profileWordsSpoken;

  /// No description provided for @profileSudaNeighbors.
  ///
  /// In en, this message translates to:
  /// **'SUDA Neighbors'**
  String get profileSudaNeighbors;

  /// No description provided for @profileSudaNeighborsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Open Reward Boxes to collect new characters!'**
  String get profileSudaNeighborsEmpty;

  /// No description provided for @profileLevelProgressReach.
  ///
  /// In en, this message translates to:
  /// **'Reach Lv. {level} to unlock!'**
  String profileLevelProgressReach(int level);

  /// No description provided for @profileLevelProgressReachBody.
  ///
  /// In en, this message translates to:
  /// **'Earn Likes and level up to claim your Reward Box.'**
  String get profileLevelProgressReachBody;

  /// No description provided for @profileLevelProgressGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get profileLevelProgressGotIt;

  /// No description provided for @profileAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievements;

  /// No description provided for @profileAchievementWeeklyChampion.
  ///
  /// In en, this message translates to:
  /// **'Weekly Champion'**
  String get profileAchievementWeeklyChampion;

  /// No description provided for @profileAchievementWeeklyRunnerUp.
  ///
  /// In en, this message translates to:
  /// **'Weekly Runner-up'**
  String get profileAchievementWeeklyRunnerUp;

  /// No description provided for @profileAchievementWeeklyThird.
  ///
  /// In en, this message translates to:
  /// **'Weekly 3rd Place'**
  String get profileAchievementWeeklyThird;

  /// No description provided for @profileAchievementWeeklyChampionHint.
  ///
  /// In en, this message translates to:
  /// **'Finish 1st in the Weekly Ranking.'**
  String get profileAchievementWeeklyChampionHint;

  /// No description provided for @profileAchievementWeeklyRunnerUpHint.
  ///
  /// In en, this message translates to:
  /// **'Finish 2nd in the Weekly Ranking.'**
  String get profileAchievementWeeklyRunnerUpHint;

  /// No description provided for @profileAchievementWeeklyThirdHint.
  ///
  /// In en, this message translates to:
  /// **'Finish 3rd in the Weekly Ranking.'**
  String get profileAchievementWeeklyThirdHint;

  /// No description provided for @profileAchievementCount.
  ///
  /// In en, this message translates to:
  /// **'x {count}'**
  String profileAchievementCount(int count);

  /// No description provided for @otherUserFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get otherUserFriends;

  /// No description provided for @otherUserRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get otherUserRequested;

  /// No description provided for @otherUserAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get otherUserAddFriend;

  /// No description provided for @otherUserUnfriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfriend this user?'**
  String get otherUserUnfriendTitle;

  /// No description provided for @otherUserUnfriendBody.
  ///
  /// In en, this message translates to:
  /// **'You and this user will no longer be friends.'**
  String get otherUserUnfriendBody;

  /// No description provided for @otherUserUnfriendOk.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get otherUserUnfriendOk;

  /// No description provided for @otherUserUnfriendCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get otherUserUnfriendCancel;

  /// No description provided for @otherUserCancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel friend request?'**
  String get otherUserCancelRequestTitle;

  /// No description provided for @otherUserCancelRequestBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be able to send another request to this user for 48 hours.'**
  String get otherUserCancelRequestBody;

  /// No description provided for @otherUserCancelRequestOk.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get otherUserCancelRequestOk;

  /// No description provided for @otherUserKeepRequest.
  ///
  /// In en, this message translates to:
  /// **'Keep Request'**
  String get otherUserKeepRequest;

  /// No description provided for @otherUserSendRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Send friend request?'**
  String get otherUserSendRequestTitle;

  /// No description provided for @otherUserSendRequestBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll become friends when they accept your request.'**
  String get otherUserSendRequestBody;

  /// No description provided for @otherUserSendRequestOk.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get otherUserSendRequestOk;

  /// No description provided for @otherUserSendRequestCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get otherUserSendRequestCancel;

  /// No description provided for @otherUserFriendBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'You can’t send a friend request to this user right now.'**
  String get otherUserFriendBlockedBody;

  /// No description provided for @otherUserFriendOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get otherUserFriendOk;

  /// No description provided for @otherUserFriendLimitSelf.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the 30-friend limit. Remove a friend to add someone new.'**
  String get otherUserFriendLimitSelf;

  /// No description provided for @otherUserFriendLimitThem.
  ///
  /// In en, this message translates to:
  /// **'They’ve reached the 30-friend limit and can’t add any more friends.'**
  String get otherUserFriendLimitThem;

  /// No description provided for @otherUserNeighborsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No characters collected yet.'**
  String get otherUserNeighborsEmpty;

  /// No description provided for @otherUserAchievementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No achievements earned yet.'**
  String get otherUserAchievementsEmpty;

  /// No description provided for @profileHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get profileHistory;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @profileHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get profileHistoryEmpty;

  /// No description provided for @profileSavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved expressions yet.'**
  String get profileSavedEmpty;

  /// No description provided for @profileSavedRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Saved?'**
  String get profileSavedRemoveTitle;

  /// No description provided for @profileSavedRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'You can find it again in History later.'**
  String get profileSavedRemoveContent;

  /// No description provided for @profileSavedRemoveOk.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileSavedRemoveOk;

  /// No description provided for @profileSavedRemoveCancel.
  ///
  /// In en, this message translates to:
  /// **'Practice more'**
  String get profileSavedRemoveCancel;

  /// No description provided for @seriesOverviewTabEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get seriesOverviewTabEpisodes;

  /// No description provided for @seriesOverviewTabSimilarTopic.
  ///
  /// In en, this message translates to:
  /// **'Similar Topic'**
  String get seriesOverviewTabSimilarTopic;

  /// No description provided for @seriesOverviewEpisodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode #{number}'**
  String seriesOverviewEpisodeNumber(int number);

  /// No description provided for @seriesOverviewPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get seriesOverviewPlay;

  /// No description provided for @seriesOverviewLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get seriesOverviewLocked;

  /// No description provided for @seriesOverviewEpisodeLockedToast.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous episode to unlock.'**
  String get seriesOverviewEpisodeLockedToast;

  /// No description provided for @notificationPermissionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationPermissionBlockedTitle;

  /// No description provided for @notificationPermissionBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications in your device settings to receive push notifications.'**
  String get notificationPermissionBlockedMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notification yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationSendToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationSendToday;

  /// No description provided for @notificationSendOneDayAgo.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get notificationSendOneDayAgo;

  /// No description provided for @notificationSendDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String notificationSendDaysAgo(int count);

  /// No description provided for @reregistrationRestrictedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can sign up again 2 days after deleting your account. Please try again later.'**
  String get reregistrationRestrictedMessage;

  /// No description provided for @expressionSavedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Saved to your Profile'**
  String get expressionSavedToProfile;

  /// No description provided for @expressionUnsavedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get expressionUnsavedToProfile;

  /// No description provided for @roleplayResultFeedbackInsufficientWords.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t provide feedback this time. Try expanding your response to 7 words or more!'**
  String get roleplayResultFeedbackInsufficientWords;

  /// No description provided for @roleplayResultScoreMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get roleplayResultScoreMeaning;

  /// No description provided for @roleplayResultScoreRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get roleplayResultScoreRelevance;

  /// No description provided for @roleplayResultScoreVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get roleplayResultScoreVocabulary;

  /// No description provided for @roleplayResultScoreGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get roleplayResultScoreGrammar;

  /// No description provided for @closePopup.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closePopup;

  /// No description provided for @reviewChatTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the chat bubble to play the audio.'**
  String get reviewChatTapHint;

  /// No description provided for @reviewChatNoAudioToPlay.
  ///
  /// In en, this message translates to:
  /// **'There\'s no audio to play.'**
  String get reviewChatNoAudioToPlay;

  /// No description provided for @seriesInformationTopicDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Topic Difficulty'**
  String get seriesInformationTopicDifficulty;

  /// No description provided for @seriesInformationLearningGoals.
  ///
  /// In en, this message translates to:
  /// **'Learning Goals'**
  String get seriesInformationLearningGoals;

  /// No description provided for @energyInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energyInfoTitle;

  /// No description provided for @energyOutOfEnergyTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of Energy'**
  String get energyOutOfEnergyTitle;

  /// No description provided for @energyInfoRechargeUntil.
  ///
  /// In en, this message translates to:
  /// **'Next recharge in @@TIME@@'**
  String get energyInfoRechargeUntil;

  /// No description provided for @energyInfoFull.
  ///
  /// In en, this message translates to:
  /// **'Your energy is full.'**
  String get energyInfoFull;

  /// No description provided for @energyInfoUnlimitedEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Mode Active'**
  String get energyInfoUnlimitedEndsIn;

  /// No description provided for @energyInsufficient.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough energy.'**
  String get energyInsufficient;

  /// No description provided for @endRoleplay.
  ///
  /// In en, this message translates to:
  /// **'End Roleplay'**
  String get endRoleplay;

  /// No description provided for @energyEnablePushTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get energyEnablePushTitle;

  /// No description provided for @energyEnablePushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications and fully refill your Energy.'**
  String get energyEnablePushSubtitle;

  /// No description provided for @energyEnablePushPrice.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get energyEnablePushPrice;

  /// No description provided for @energyEnablePushOfferBadge.
  ///
  /// In en, this message translates to:
  /// **'ONE-TIME OFFER'**
  String get energyEnablePushOfferBadge;

  /// No description provided for @energyEnablePushCompleted.
  ///
  /// In en, this message translates to:
  /// **'Energy refilled!'**
  String get energyEnablePushCompleted;

  /// No description provided for @energyPurchaseUnlimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Pass'**
  String get energyPurchaseUnlimitedTitle;

  /// No description provided for @energyPurchaseUnlimitedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starts immediately after purchase. Valid for 10 minutes.'**
  String get energyPurchaseUnlimitedSubtitle;

  /// No description provided for @energyPurchaseCapacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Max Energy Upgrade'**
  String get energyPurchaseCapacityTitle;

  /// No description provided for @energyPurchaseCapacitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently increase your max rechargeable Energy by 1.'**
  String get energyPurchaseCapacitySubtitle;

  /// No description provided for @energyGoPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get energyGoPremiumTitle;

  /// No description provided for @energyGoPremiumExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get energyGoPremiumExplore;

  /// No description provided for @profileGoPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Get SUDA Premium'**
  String get profileGoPremiumTitle;

  /// No description provided for @profileGoPremiumExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get profileGoPremiumExplore;

  /// No description provided for @energyPurchasePendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your payment is pending approval'**
  String get energyPurchasePendingApproval;

  /// No description provided for @energyPurchaseNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'The purchase was not completed.'**
  String get energyPurchaseNotCompleted;

  /// No description provided for @iapPurchaseProcessing.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is being processed.'**
  String get iapPurchaseProcessing;

  /// No description provided for @iapPurchaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete.'**
  String get iapPurchaseCompleted;

  /// No description provided for @welcomeGiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Welcome Gift Has Arrived!'**
  String get welcomeGiftTitle;

  /// No description provided for @welcomeGiftBenefitLead.
  ///
  /// In en, this message translates to:
  /// **'Enjoy unlimited play for 10 minutes!'**
  String get welcomeGiftBenefitLead;

  /// No description provided for @welcomeGiftLine2.
  ///
  /// In en, this message translates to:
  /// **'Premium features unlocked'**
  String get welcomeGiftLine2;

  /// No description provided for @welcomeGiftLine3.
  ///
  /// In en, this message translates to:
  /// **'Unlimited play unlocked'**
  String get welcomeGiftLine3;

  /// No description provided for @welcomeGiftStartNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get welcomeGiftStartNow;

  /// No description provided for @paywallHeroTitle1.
  ///
  /// In en, this message translates to:
  /// **'Practice More'**
  String get paywallHeroTitle1;

  /// No description provided for @paywallHeroTitle2.
  ///
  /// In en, this message translates to:
  /// **'Improve\nFaster'**
  String get paywallHeroTitle2;

  /// No description provided for @paywallHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Practice longer with Premium and get AI feedback to build your English confidence.'**
  String get paywallHeroBody;

  /// No description provided for @paywallPremiumLabel.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get paywallPremiumLabel;

  /// No description provided for @paywallBenefitMaxEnergy.
  ///
  /// In en, this message translates to:
  /// **'Up to 30 Max Energy'**
  String get paywallBenefitMaxEnergy;

  /// No description provided for @paywallBenefitAiFeedback.
  ///
  /// In en, this message translates to:
  /// **'AI Sentence Feedback'**
  String get paywallBenefitAiFeedback;

  /// No description provided for @paywallBenefitProfileBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium Profile Badge'**
  String get paywallBenefitProfileBadge;

  /// No description provided for @paywallChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get paywallChoosePlan;

  /// No description provided for @paywallAnnualPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Annual Plan'**
  String get paywallAnnualPlanTitle;

  /// No description provided for @paywallAnnualPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save over 33% compared to the monthly plan.'**
  String get paywallAnnualPlanSubtitle;

  /// No description provided for @paywallMonthlyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get paywallMonthlyPlanTitle;

  /// No description provided for @paywallMonthlyPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flexible monthly access.'**
  String get paywallMonthlyPlanSubtitle;

  /// No description provided for @paywallBestBadge.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get paywallBestBadge;

  /// No description provided for @paywallCta.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get paywallCta;

  /// No description provided for @paywallAutoRenewNotice.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current billing period.'**
  String get paywallAutoRenewNotice;

  /// No description provided for @paywallPricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String paywallPricePerMonth(String price);

  /// No description provided for @paywallPricePerYear.
  ///
  /// In en, this message translates to:
  /// **'{price}/year'**
  String paywallPricePerYear(String price);

  /// No description provided for @paywallFallbackAnnualPerMonth.
  ///
  /// In en, this message translates to:
  /// **'\$8.33'**
  String get paywallFallbackAnnualPerMonth;

  /// No description provided for @paywallFallbackAnnual.
  ///
  /// In en, this message translates to:
  /// **'\$99.99'**
  String get paywallFallbackAnnual;

  /// No description provided for @paywallFallbackMonthly.
  ///
  /// In en, this message translates to:
  /// **'\$13.99'**
  String get paywallFallbackMonthly;

  /// No description provided for @paywallFallbackMonthlyTimes12.
  ///
  /// In en, this message translates to:
  /// **'\$167.88'**
  String get paywallFallbackMonthlyTimes12;

  /// No description provided for @paywallCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get paywallCompletedTitle;

  /// No description provided for @paywallCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Your Premium benefits are now active.'**
  String get paywallCompletedBody;

  /// No description provided for @paywallCompletedContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallCompletedContinue;

  /// No description provided for @roleplayChooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get roleplayChooseYourRole;

  /// No description provided for @roleplaySimilarRoleplays.
  ///
  /// In en, this message translates to:
  /// **'Similar Roleplays'**
  String get roleplaySimilarRoleplays;

  /// No description provided for @roleplayBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'This roleplay is being prepared.'**
  String get roleplayBeingPrepared;

  /// No description provided for @roleplayUnlockPreviousRole.
  ///
  /// In en, this message translates to:
  /// **'Complete all endings of the previous role to unlock this role.'**
  String get roleplayUnlockPreviousRole;

  /// No description provided for @seriesOverviewCompletionPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete'**
  String seriesOverviewCompletionPercent(int percent);

  /// No description provided for @roleplayTurnGradeA.
  ///
  /// In en, this message translates to:
  /// **'wow!'**
  String get roleplayTurnGradeA;

  /// No description provided for @roleplayTurnGradeB.
  ///
  /// In en, this message translates to:
  /// **'ok!'**
  String get roleplayTurnGradeB;

  /// No description provided for @roleplayTurnGradeC.
  ///
  /// In en, this message translates to:
  /// **'hmm…'**
  String get roleplayTurnGradeC;

  /// No description provided for @roleplayTurnGradeD.
  ///
  /// In en, this message translates to:
  /// **'oh…'**
  String get roleplayTurnGradeD;

  /// No description provided for @tutorialPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Check your **Mission**\nand start the conversation.'**
  String get tutorialPage1Title;

  /// No description provided for @tutorialPage1Tip.
  ///
  /// In en, this message translates to:
  /// **'*Tip: The more naturally you speak,\nthe bigger your reward!'**
  String get tutorialPage1Tip;

  /// No description provided for @tutorialPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Use the **Translator**\nwhen you don\'t understand.'**
  String get tutorialPage2Title;

  /// No description provided for @tutorialPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Use a **Hint**\nwhen you get stuck.'**
  String get tutorialPage3Title;

  /// No description provided for @tutorialPage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'You can turn auto hints\non or off anytime.'**
  String get tutorialPage3Subtitle;

  /// No description provided for @tutorialPage4Title.
  ///
  /// In en, this message translates to:
  /// **'If pronunciation is hard,\nlisten first, then repeat.'**
  String get tutorialPage4Title;

  /// No description provided for @tutorialPage4Tip.
  ///
  /// In en, this message translates to:
  /// **'*Tip: Try answering without looking at the translation\nto earn a higher score.'**
  String get tutorialPage4Tip;

  /// No description provided for @tutorialPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Can\'t speak out loud?'**
  String get tutorialPage5Title;

  /// No description provided for @tutorialPage5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to **Text Mode**.'**
  String get tutorialPage5Subtitle;

  /// No description provided for @tutorialPage6Title.
  ///
  /// In en, this message translates to:
  /// **'No one\'s judging.\nYou\'ve got this!'**
  String get tutorialPage6Title;

  /// No description provided for @rankCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days left}}'**
  String rankCountdownDays(int count);

  /// No description provided for @rankCountdownHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String rankCountdownHours(int count);

  /// No description provided for @rankCountdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String rankCountdownMinutes(int count);

  /// No description provided for @rankWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Ranking'**
  String get rankWeeklyTitle;

  /// No description provided for @rankAnnounceTitle.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Results'**
  String get rankAnnounceTitle;

  /// No description provided for @rankTop3RewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top 3 Rewards'**
  String get rankTop3RewardsTitle;

  /// No description provided for @rankTop3RewardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn Likes each week and compete with other learners for the top spots!'**
  String get rankTop3RewardsDesc;

  /// No description provided for @rankTop3Place1.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get rankTop3Place1;

  /// No description provided for @rankTop3Place2.
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get rankTop3Place2;

  /// No description provided for @rankTop3Place3.
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get rankTop3Place3;

  /// No description provided for @rankTop3Badge1.
  ///
  /// In en, this message translates to:
  /// **'1st Place Badge'**
  String get rankTop3Badge1;

  /// No description provided for @rankTop3Badge2.
  ///
  /// In en, this message translates to:
  /// **'2nd Place Badge'**
  String get rankTop3Badge2;

  /// No description provided for @rankTop3Badge3.
  ///
  /// In en, this message translates to:
  /// **'3rd Place Badge'**
  String get rankTop3Badge3;

  /// No description provided for @rankTop3Likes100.
  ///
  /// In en, this message translates to:
  /// **'+100 Likes'**
  String get rankTop3Likes100;

  /// No description provided for @rankTop3Likes60.
  ///
  /// In en, this message translates to:
  /// **'+60 Likes'**
  String get rankTop3Likes60;

  /// No description provided for @rankTop3Likes50.
  ///
  /// In en, this message translates to:
  /// **'+50 Likes'**
  String get rankTop3Likes50;

  /// No description provided for @rankTop3Box3.
  ///
  /// In en, this message translates to:
  /// **'×3 Reward Box'**
  String get rankTop3Box3;

  /// No description provided for @rankTop3Box2.
  ///
  /// In en, this message translates to:
  /// **'×2 Reward Box'**
  String get rankTop3Box2;

  /// No description provided for @rankTop3Box1.
  ///
  /// In en, this message translates to:
  /// **'×1 Reward Box'**
  String get rankTop3Box1;

  /// No description provided for @rankTop3Okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get rankTop3Okay;

  /// No description provided for @rankNotRankedYetTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re not ranked yet'**
  String get rankNotRankedYetTitle;

  /// No description provided for @rankNotRankedYetBody.
  ///
  /// In en, this message translates to:
  /// **'Earn Likes to join this week\'s ranking.'**
  String get rankNotRankedYetBody;

  /// No description provided for @rankAnnounceNextStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Next Ranking Starts in:'**
  String get rankAnnounceNextStartsIn;

  /// No description provided for @rankAnnounceYou.
  ///
  /// In en, this message translates to:
  /// **'You:'**
  String get rankAnnounceYou;

  /// No description provided for @rankAnnounceRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rankAnnounceRank;

  /// No description provided for @rankAnnounceLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get rankAnnounceLike;

  /// No description provided for @rankPlayNow.
  ///
  /// In en, this message translates to:
  /// **'play now'**
  String get rankPlayNow;

  /// No description provided for @rankingRewardClaimCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get rankingRewardClaimCongratulations;

  /// No description provided for @rankingRewardClaimFinishedPlace.
  ///
  /// In en, this message translates to:
  /// **'You finished #{place} in this week\'s ranking!'**
  String rankingRewardClaimFinishedPlace(int place);

  /// No description provided for @rankingRewardClaimYourRewards.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards'**
  String get rankingRewardClaimYourRewards;

  /// No description provided for @rankingRewardClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get rankingRewardClaim;

  /// No description provided for @rankingRewardClaimError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get rankingRewardClaimError;

  /// No description provided for @rewardUnboxingTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap the box to open'**
  String get rewardUnboxingTapToOpen;

  /// No description provided for @rewardUnboxingNewCharacter.
  ///
  /// In en, this message translates to:
  /// **'New Character!'**
  String get rewardUnboxingNewCharacter;

  /// No description provided for @rewardUnboxingYouGot.
  ///
  /// In en, this message translates to:
  /// **'You got {characterName}!'**
  String rewardUnboxingYouGot(String characterName);

  /// No description provided for @rewardUnboxingSetAsProfile.
  ///
  /// In en, this message translates to:
  /// **'Set as Profile'**
  String get rewardUnboxingSetAsProfile;

  /// No description provided for @rewardUnboxingViewCharacter.
  ///
  /// In en, this message translates to:
  /// **'View Character'**
  String get rewardUnboxingViewCharacter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fil',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'nl',
    'pl',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return AppLocalizationsEs419();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
