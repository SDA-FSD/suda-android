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

  /// No description provided for @settingsLanguageLevel.
  ///
  /// In en, this message translates to:
  /// **'Language Level'**
  String get settingsLanguageLevel;

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

  /// No description provided for @languageLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your English level'**
  String get languageLevelTitle;

  /// No description provided for @languageLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'SUDA citizens will chat with you at your level.'**
  String get languageLevelDescription;

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

  /// No description provided for @roleplayEndedFailed.
  ///
  /// In en, this message translates to:
  /// **'Mission Failed...'**
  String get roleplayEndedFailed;

  /// No description provided for @roleplayEndedTimesup.
  ///
  /// In en, this message translates to:
  /// **'Time has run out...'**
  String get roleplayEndedTimesup;

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

  /// No description provided for @profileHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get profileHistoryEmpty;

  /// No description provided for @noTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'No tickets left…'**
  String get noTicketsTitle;

  /// No description provided for @noTicketsBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit.\nCome back tomorrow!'**
  String get noTicketsBody;

  /// No description provided for @surveyPromptLine1.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s limit.'**
  String get surveyPromptLine1;

  /// No description provided for @surveyPromptLine2.
  ///
  /// In en, this message translates to:
  /// **'Answer a quick question to earn 1 extra ticket!'**
  String get surveyPromptLine2;

  /// No description provided for @pushTicketPromptLine2.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications and get 1 extra ticket!'**
  String get pushTicketPromptLine2;

  /// No description provided for @surveyAnswerNowButton.
  ///
  /// In en, this message translates to:
  /// **'Answer now ✅'**
  String get surveyAnswerNowButton;

  /// No description provided for @pushTicketTurnOnButton.
  ///
  /// In en, this message translates to:
  /// **'Turn on 🔔'**
  String get pushTicketTurnOnButton;

  /// No description provided for @shareTicketPromptLine2.
  ///
  /// In en, this message translates to:
  /// **'Share the app link with a friend to get 1 extra ticket!'**
  String get shareTicketPromptLine2;

  /// No description provided for @shareTicketButton.
  ///
  /// In en, this message translates to:
  /// **'Share link 💬'**
  String get shareTicketButton;

  /// No description provided for @reviewTicketPromptLine2.
  ///
  /// In en, this message translates to:
  /// **'Leave a store review to get 1 extra ticket!'**
  String get reviewTicketPromptLine2;

  /// No description provided for @reviewTicketButton.
  ///
  /// In en, this message translates to:
  /// **'Leave Stars ⭐'**
  String get reviewTicketButton;

  /// No description provided for @surveyMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get surveyMaybeLater;

  /// No description provided for @surveyStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Which age group are you in?'**
  String get surveyStep1Title;

  /// No description provided for @surveyStep2Title.
  ///
  /// In en, this message translates to:
  /// **'What is your gender?'**
  String get surveyStep2Title;

  /// No description provided for @surveyStep3Title.
  ///
  /// In en, this message translates to:
  /// **'How did you find SUDA?'**
  String get surveyStep3Title;

  /// No description provided for @surveyGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get surveyGenderFemale;

  /// No description provided for @surveyGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get surveyGenderMale;

  /// No description provided for @surveyGenderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get surveyGenderPreferNotToSay;

  /// No description provided for @surveySuccessToast.
  ///
  /// In en, this message translates to:
  /// **'1 Ticket added! 🎉'**
  String get surveySuccessToast;

  /// No description provided for @dailyTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for Checking In!'**
  String get dailyTicketTitle;

  /// No description provided for @dailyTicketContent.
  ///
  /// In en, this message translates to:
  /// **'Claim your daily free ticket!\nIt expires if you don\'t use it today.'**
  String get dailyTicketContent;

  /// No description provided for @dailyTicketButton.
  ///
  /// In en, this message translates to:
  /// **'Claim Ticket 🎟️'**
  String get dailyTicketButton;

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
