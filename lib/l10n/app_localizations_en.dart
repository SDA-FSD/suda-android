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
  String get settingsNotification => 'Notification';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsLanguageLevel => 'Language Level';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsDesc =>
      'Receive reminders and important updates.';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsAnnouncements => 'Announcements';

  @override
  String get announcementsEmpty => 'No announcements yet';

  @override
  String get noticesEmpty => 'No posts yet';

  @override
  String get deletedPost => 'This post has been deleted.';

  @override
  String get postNoLongerAvailable => 'This post is no longer available.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsFsdLaboratory => 'FSD Laboratory';

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
  String get loginCatchphrase => 'Start talking. That\'s how you learn.';

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
  String get accountDeleteProfileImageTitle => 'Delete profile image?';

  @override
  String get accountDeleteProfileImageContent =>
      'Once deleted, your profile image cannot be recovered.';

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

  @override
  String get profileHistory => 'History';

  @override
  String get profileSaved => 'Saved';

  @override
  String get profileHistoryEmpty => 'No history yet';

  @override
  String get profileSavedEmpty => 'No saved expressions yet.';

  @override
  String get profileSavedRemoveTitle => 'Remove from Saved?';

  @override
  String get profileSavedRemoveContent =>
      'You can find it again in History later.';

  @override
  String get profileSavedRemoveOk => 'Remove';

  @override
  String get profileSavedRemoveCancel => 'Practice more';

  @override
  String get noTicketsTitle => 'No tickets left…';

  @override
  String get noTicketsBody =>
      'You\'ve reached today\'s limit.\nCome back tomorrow!';

  @override
  String get surveyPromptLine1 => 'You\'ve reached today\'s limit.';

  @override
  String get surveyPromptLine2 =>
      'Answer a quick question to earn 1 extra ticket!';

  @override
  String get pushTicketPromptLine2 =>
      'Turn on notifications and get 1 extra ticket!';

  @override
  String get surveyAnswerNowButton => 'Answer now ✅';

  @override
  String get pushTicketTurnOnButton => 'Turn on 🔔';

  @override
  String get shareTicketPromptLine2 =>
      'Share the app link with a friend to get 1 extra ticket!';

  @override
  String get shareTicketButton => 'Share link 💬';

  @override
  String get reviewTicketPromptLine2 =>
      'Leave a store review to get 1 extra ticket!';

  @override
  String get reviewTicketButton => 'Leave Stars ⭐';

  @override
  String get surveyMaybeLater => 'Maybe later';

  @override
  String get surveyStep1Title => 'Which age group are you in?';

  @override
  String get surveyStep2Title => 'What is your gender?';

  @override
  String get surveyStep3Title => 'How did you find SUDA?';

  @override
  String get surveyGenderFemale => 'Female';

  @override
  String get surveyGenderMale => 'Male';

  @override
  String get surveyGenderPreferNotToSay => 'Prefer not to say';

  @override
  String get surveySuccessToast => '1 Ticket added! 🎉';

  @override
  String get dailyTicketTitle => 'Thanks for Checking In!';

  @override
  String get dailyTicketContent =>
      'Claim your daily free ticket!\nIt expires if you don\'t use it today.';

  @override
  String get dailyTicketButton => 'Claim Ticket';

  @override
  String get notificationPermissionBlockedTitle => 'Notifications are off';

  @override
  String get notificationPermissionBlockedMessage =>
      'Enable notifications in your device settings to receive push notifications.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notification yet';

  @override
  String get notificationSendToday => 'Today';

  @override
  String get notificationSendOneDayAgo => '1 day ago';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'You can sign up again 2 days after deleting your account. Please try again later.';

  @override
  String get expressionSavedToProfile => 'Saved to your Profile';

  @override
  String get expressionUnsavedToProfile => 'Unsaved';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'We couldn’t provide feedback this time. Try expanding your response to 30 words or more!';
}
