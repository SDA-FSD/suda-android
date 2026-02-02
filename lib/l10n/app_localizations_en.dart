// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get agreementHeading =>
      'Please review and agree to the terms below to continue.';

  @override
  String get agreementTermsLabel => 'I agree to the Terms of Use.';

  @override
  String get agreementPrivacyLabel => 'I agree to the Privacy Policy.';

  @override
  String get agreementTermsTitle => 'Terms of Use';

  @override
  String get agreementPrivacyTitle => 'Privacy Policy';

  @override
  String get agreementDetailsLink => 'View details';

  @override
  String get agreementButtonConfirm => 'Confirm and continue';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsLanguageLevel => 'Language Level';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsOpenSource => 'Open Source Licenses';

  @override
  String loginWelcome(String name) {
    return 'Welcome, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'By continuing, you agree to our $terms and $privacy.';
  }

  @override
  String get loginTermsTitle => 'Terms of Use';

  @override
  String get loginPrivacyTitle => 'Privacy Policy';

  @override
  String get loginErrorIdToken =>
      'Failed to get Google ID Token. Please try again.';

  @override
  String loginErrorFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get accountName => 'Name';

  @override
  String get accountInfo => 'Account';

  @override
  String get accountDelete => 'Delete Account';

  @override
  String get accountDeleteTitle => 'Delete Account?';

  @override
  String get accountDeleteConfirmText =>
      'All your progress and data will be permanently lost. Are you sure?';

  @override
  String get accountGoBack => 'Go Back';

  @override
  String get accountDeleteAction => 'Delete';

  @override
  String get languageLevelTitle => 'Choose your English level';

  @override
  String get languageLevelDescription =>
      'SUDA citizens will chat with you at your level.';

  @override
  String get feedbackPlaceholder =>
      'Please share your thoughts, suggestions, or any issues you\'ve encountered...';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackSuccess => 'Thank you for your feedback.';

  @override
  String get microphonePermissionDenied =>
      'Cannot start without microphone permission.';

  @override
  String get holdMicrophoneToSpeak => 'Hold microphone to speak';

  @override
  String get yourTurnFirst => 'Your turn first!';

  @override
  String get sayLineBelowToStart => 'Say the line below to start.';

  @override
  String get roleplayExitWait => 'Wait!';

  @override
  String get roleplayExitMessage =>
      'If you leave now, you\'ll miss your reward. Are you sure you want to leave?';

  @override
  String get roleplayExitKeepPlaying => 'Keep Playing';

  @override
  String get roleplayExitExit => 'Exit';

  @override
  String get roleplayEndedFailed => 'Mission Failed...';

  @override
  String get roleplayEndedTimesup => 'Time has run out...';

  @override
  String get roleplayEndedComplete => 'Roleplay Completed';

  @override
  String get roleplayEndedEnding => 'Moving to ending...';

  @override
  String get endingFailTitle => 'You didn\'t complete all the missions!';

  @override
  String get endingFailSubtitle => 'Try again and uncover the full story.';

  @override
  String get endingReport => 'Report';

  @override
  String get endingHowWas => 'How was the Roleplay?';

  @override
  String get endingNext => 'Next';

  @override
  String get reportTitle => 'Report Issue';
}
