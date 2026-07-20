import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';

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
    Locale('ko'),
    Locale('pt'),
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

  /// No description provided for @firstCefrLevelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get firstCefrLevelConfirm;

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
      <String>['en', 'ko', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
