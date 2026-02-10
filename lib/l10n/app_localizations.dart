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

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

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
