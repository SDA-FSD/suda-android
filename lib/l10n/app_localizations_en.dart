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
  String get settingsCefrLevel => 'Language Level';

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
  String get loginWelcomeTitle => 'Welcome to SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Step into a story and start speaking English!';

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
  String get accountSubscription => 'Subscription';

  @override
  String get accountFreePlanTitle => 'Free Plan';

  @override
  String get accountFreePlanSubtitle => 'Get Premium to unlock more features';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'You\'re enjoying Premium benefits';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get accountChangePlan => 'Change Plan';

  @override
  String get changePlanTitle => 'Change Plan';

  @override
  String get changePlanCurrentPlan => 'Current Plan';

  @override
  String get changePlanAvailablePlans => 'Available Plans';

  @override
  String changePlanRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Couldn\'t load the information. Please try again.';

  @override
  String get changePlanRetry => 'Try again';

  @override
  String get changePlanConfirmTitle => 'Change Plan?';

  @override
  String get changePlanConfirmBody =>
      'Plan changes take effect on your next billing date.';

  @override
  String get changePlanConfirmOk => 'Confirm';

  @override
  String get changePlanConfirmCancel => 'Keep Current Plan';

  @override
  String get cefrLevelTitle => 'Choose your English level';

  @override
  String get cefrLevelAbsoluteBeginner => 'Absolute Beginner';

  @override
  String get cefrLevelBeginner => 'Beginner';

  @override
  String get cefrLevelBasic => 'Basic';

  @override
  String get cefrLevelIntermediate => 'Intermediate';

  @override
  String get firstCefrLevelTitle => 'What is your English level?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'I know how to read English';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'I know basic greetings and simple phrases';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'I can use and understand short, simple sentences';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'I can share my opinion and join everyday conversation';

  @override
  String get firstCefrLevelSettingsHint => 'You can change it anytime';

  @override
  String get firstCefrLevelConfirm => 'Confirm';

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
  String get roleplayTypeMessagePlaceholder => 'Type your message ...';

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
  String get roleplayAutoHint => 'Auto Hint';

  @override
  String get roleplayHintLabel => 'Hint';

  @override
  String get roleplayHintShowAnswer => 'Tap to see the English answer';

  @override
  String get roleplayVoiceSpeed => 'Voice Speed';

  @override
  String get roleplayEndedFailed => 'Mission Failed...';

  @override
  String get roleplayEndedComplete => 'Roleplay Completed';

  @override
  String get roleplayEndedEnding => 'Moving to ending...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Not enough progress';

  @override
  String get roleplayFinishCompleted => 'Roleplay completed';

  @override
  String get roleplayFinishMovingToEnding => 'Moving to ending...';

  @override
  String get roleplayAnalyzing => 'Analyzing your roleplay...';

  @override
  String get roleplayOpeningAiCharacter => 'AI Character';

  @override
  String get roleplayOpeningScenario => 'Scenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI can make mistakes.\nPlease don\'t share personal or sensitive information.';

  @override
  String get endingFailTitle => 'You didn\'t complete all the missions!';

  @override
  String get endingFailSubtitle => 'Try again and uncover the full story.';

  @override
  String get roleplayTryAgainMessage =>
      'Unfortunately, your score wasn\'t high enough to earn the reward.';

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
  String get seriesOverviewTabEpisodes => 'Episode';

  @override
  String get seriesOverviewTabSimilarTopic => 'Similar Topic';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episode #$number';
  }

  @override
  String get seriesOverviewPlay => 'Play';

  @override
  String get seriesOverviewLocked => 'Locked';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Complete the previous episode to unlock.';

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
      'We couldn’t provide feedback this time. Try expanding your response to 7 words or more!';

  @override
  String get roleplayResultScoreMeaning => 'Meaning';

  @override
  String get roleplayResultScoreRelevance => 'Relevance';

  @override
  String get roleplayResultScoreVocabulary => 'Vocabulary';

  @override
  String get roleplayResultScoreGrammar => 'Grammar';

  @override
  String get closePopup => 'Close';

  @override
  String get reviewChatTapHint => 'Tap the chat bubble to play the audio.';

  @override
  String get reviewChatNoAudioToPlay => 'There\'s no audio to play.';

  @override
  String get seriesInformationTopicDifficulty => 'Topic Difficulty';

  @override
  String get seriesInformationLearningGoals => 'Learning Goals';

  @override
  String get energyInfoTitle => 'Energy';

  @override
  String get energyOutOfEnergyTitle => 'Out of Energy';

  @override
  String get energyInfoRechargeUntil => 'Next recharge in @@TIME@@';

  @override
  String get energyInfoFull => 'Your energy is full.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Unlimited Mode Active';

  @override
  String get energyInsufficient => 'You don\'t have enough energy.';

  @override
  String get endRoleplay => 'End Roleplay';

  @override
  String get energyPurchaseUnlimitedTitle => 'Unlimited Pass';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Starts immediately after purchase. Valid for 10 minutes.';

  @override
  String get energyPurchaseCapacityTitle => 'Max Energy Upgrade';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Permanently increase your max rechargeable Energy by 1.';

  @override
  String get energyGoPremiumTitle => 'Go Premium';

  @override
  String get energyGoPremiumExplore => 'Explore';

  @override
  String get profileGoPremiumTitle => 'Get SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Explore';

  @override
  String get energyPurchasePendingApproval =>
      'Your payment is pending approval';

  @override
  String get energyPurchaseNotCompleted => 'The purchase was not completed.';

  @override
  String get welcomeGiftTitle => 'Your Welcome Gift Has Arrived!';

  @override
  String get welcomeGiftBenefitLead => 'Enjoy unlimited play for 10 minutes!';

  @override
  String get welcomeGiftLine2 => 'Premium features unlocked';

  @override
  String get welcomeGiftLine3 => 'Unlimited play unlocked';

  @override
  String get welcomeGiftStartNow => 'Start Now';

  @override
  String get paywallHeroTitle1 => 'Practice More';

  @override
  String get paywallHeroTitle2 => 'Improve Faster';

  @override
  String get paywallHeroBody =>
      'Practice longer with Premium and get AI feedback to build your English confidence.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'More Daily Practice';

  @override
  String get paywallBenefitMaxEnergy => 'Up to 30 Max Energy';

  @override
  String get paywallBenefitAiFeedback => 'AI Sentence Feedback';

  @override
  String get paywallChoosePlan => 'Choose Your Plan';

  @override
  String get paywallAnnualPlanTitle => 'Annual Plan';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Save over 33% compared to the monthly plan.';

  @override
  String get paywallMonthlyPlanTitle => 'Monthly Plan';

  @override
  String get paywallMonthlyPlanSubtitle => 'Flexible monthly access.';

  @override
  String get paywallBestBadge => 'BEST';

  @override
  String get paywallCta => 'Start Now';

  @override
  String get paywallAutoRenewNotice =>
      'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current billing period.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/month';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/year';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Congratulations!';

  @override
  String get paywallCompletedBody => 'Your Premium benefits are now active.';

  @override
  String get paywallCompletedContinue => 'Continue';
}
