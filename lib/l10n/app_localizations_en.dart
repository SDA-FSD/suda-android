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
  String get agreementAllLabel => 'Agree to all required terms';

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
  String get settingsRestorePurchases => 'Restore Purchases';

  @override
  String get restorePurchasesNothing => 'No purchases to restore.';

  @override
  String get restorePurchasesCompleted => 'Purchases restored.';

  @override
  String get settingsNotification => 'Notification';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Language Level';

  @override
  String get settingsAppLanguage => 'App Language';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsDesc =>
      'Receive reminders and important updates.';

  @override
  String get pushPracticeReminders => 'Practice Reminders';

  @override
  String get pushPracticeRemindersDesc =>
      'Get reminders to keep up your English speaking practice.';

  @override
  String get pushEnergyUpdates => 'Energy Updates';

  @override
  String get pushEnergyUpdatesDesc =>
      'Get notified when your Energy is fully recharged.';

  @override
  String get pushLearningUpdates => 'Learning Updates';

  @override
  String get pushLearningUpdatesDesc =>
      'Get updates about new roleplays and learning features.';

  @override
  String get pushNewsEvents => 'News & Events';

  @override
  String get pushNewsEventsDesc =>
      'Get the latest news, events, and announcements from SUDA.';

  @override
  String get pushRankingUpdates => 'Ranking Updates';

  @override
  String get pushRankingUpdatesDesc =>
      'Get updates on weekly rankings, results, and rewards.';

  @override
  String get pushSocialUpdates => 'Social Updates';

  @override
  String get pushSocialUpdatesDesc =>
      'Get updates on friend requests and other social activity.';

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
  String get accountChangePicture => 'Change Picture';

  @override
  String get changeProfileImageTitle => 'Choose your Profile Picture';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendRequestsTab => 'Friend Requests';

  @override
  String get friendsEmpty => 'No friends yet';

  @override
  String get friendRequestsEmpty => 'No friend requests yet.';

  @override
  String get friendRequestAccept => 'Accept';

  @override
  String get friendRequestDecline => 'Decline';

  @override
  String get friendsShareLink => 'Share Link';

  @override
  String get friendsShareBody => 'Practice speaking English with me on SUDA.';

  @override
  String get characterAge => 'Age';

  @override
  String get characterNationality => 'Nationality';

  @override
  String get characterOccupation => 'Occupation';

  @override
  String get characterInterests => 'Interests';

  @override
  String get characterCollection => 'Collection';

  @override
  String get characterSecret => 'Secret';

  @override
  String characterSeriesWith(String name) {
    return 'Series with $name';
  }

  @override
  String get characterSetAsProfile => 'Set as Profile';

  @override
  String get characterChangePictureTitle => 'Change Profile Picture?';

  @override
  String get characterChange => 'Change';

  @override
  String get characterCancel => 'Cancel';

  @override
  String get characterChangeFailed =>
      'Couldn\'t change your profile picture. Please try again.';

  @override
  String get characterSecretLocked =>
      'Complete the collection to unlock the Secret.';

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
  String get changePlanOldPurchaseMissing =>
      'Couldn\'t find an active subscription to change. Try again after your subscription is active.';

  @override
  String get changePlanChangeRequested =>
      'Plan change requested. It may apply on your next billing date.';

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
  String get firstAppLanguageTitle => 'Choose your app language';

  @override
  String get firstAppLanguageContinue => 'Continue';

  @override
  String get requestFailed =>
      'Couldn\'t complete the request. Please try again.';

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
  String get firstProfileImageTitle => 'Choose your Profile Picture';

  @override
  String get firstUsernameTitle => 'What should we\ncall you?';

  @override
  String tutorialIntroTitle(String name) {
    return '$name,\nready to warm up?';
  }

  @override
  String get tutorialIntroStart => 'Start Tutorial';

  @override
  String get tutorialRoleplayTitle => 'Your First Conversation';

  @override
  String get tutorialRoleplaySkip => 'Skip';

  @override
  String get tutorialRoleplaySkipTitle => 'Skip the tutorial?';

  @override
  String get tutorialRoleplaySkipBody =>
      'If you skip, you won\'t be able to return to the tutorial.';

  @override
  String get tutorialRoleplaySkipConfirm => 'Skip Tutorial';

  @override
  String get tutorialRoleplaySkipKeepGoing => 'Keep Going';

  @override
  String get tutorialRoleplayMissions => 'Missions';

  @override
  String get tutorialRoleplayMission1 => 'Greet the taxi driver';

  @override
  String get tutorialRoleplayMission2 => 'Tell the driver where you\'re going';

  @override
  String get tutorialRoleplayMission3 => 'Say why you\'re going there';

  @override
  String get tutorialRoleplayGuideMissionMain => 'Check your missions first!';

  @override
  String get tutorialRoleplayGuideMissionTapContinue => 'Tap to continue';

  @override
  String get tutorialRoleplaySceneCaption =>
      'Today, you\'re moving to a new neighborhood.\nSay hello to Betty, your taxi driver!';

  @override
  String get tutorialRoleplayResultSubtitle => 'First conversation complete!';

  @override
  String get tutorialRoleplayResultContinue => 'Keep It Going!';

  @override
  String get tutorialRoleplayGreetingSuccess =>
      'First greeting complete!\nGreat job!';

  @override
  String get tutorialRoleplayBettyLine1 =>
      'Hi there! I\'m Betty. Lovely to meet you!';

  @override
  String get tutorialRoleplayBettyLine1Translation => '';

  @override
  String get tutorialRoleplayHoldHello =>
      'Press and hold the mic button. Say ‘Hello’ and release.';

  @override
  String get tutorialRoleplayMicHolding => '‘Hello’';

  @override
  String get tutorialRoleplayMicTooShort =>
      'Hold the mic longer and say ‘Hello’';

  @override
  String get tutorialRoleplayMicNoSpeech =>
      'Didn\'t catch that. Try saying \'Hello\' again.';

  @override
  String get tutorialRoleplayHintGuide =>
      'Not sure what to say?\nTap the light bulb for a hint.';

  @override
  String get tutorialRoleplayHintDestinationNative => '';

  @override
  String get tutorialRoleplayHintReasonNative => '';

  @override
  String get tutorialRoleplayHintAnswerGuide =>
      'Try answering with this sentence.';

  @override
  String get tutorialRoleplayFreeAnswerGuide =>
      'Answer in your own words.\nNeed help? Tap the light bulb.';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get feedbackPlaceholder =>
      'Please share your thoughts, suggestions, or any issues you\'ve encountered...';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackSuccess => 'Thank you for your feedback.';

  @override
  String get speechFeedbackUnavailable => 'No feedback available.';

  @override
  String get speechFeedbackNoRecording => 'No recording available.';

  @override
  String get microphonePermissionDenied =>
      'Cannot start without microphone permission.';

  @override
  String get holdMicrophoneToSpeak => 'Hold microphone to speak';

  @override
  String get roleplayNoWordsRecognized => 'No words recognized. Try again.';

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
  String get roleplayAutoHintGuide => 'Turn on Auto Hint';

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
  String get profileProgress => 'Progress';

  @override
  String get profileDayStreak => 'Day Streak';

  @override
  String get profileWordsSpoken => 'Words Spoken';

  @override
  String get profileSudaNeighbors => 'SUDA Neighbors';

  @override
  String get profileSudaNeighborsEmpty =>
      'Open Reward Boxes to collect new characters!';

  @override
  String profileLevelProgressReach(int level) {
    return 'Reach Lv. $level to unlock!';
  }

  @override
  String get profileLevelProgressReachBody =>
      'Earn Likes and level up to claim your Reward Box.';

  @override
  String get profileLevelProgressGotIt => 'Got it';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileAchievementWeeklyChampion => 'Weekly Champion';

  @override
  String get profileAchievementWeeklyRunnerUp => 'Weekly Runner-up';

  @override
  String get profileAchievementWeeklyThird => 'Weekly 3rd Place';

  @override
  String get profileAchievementWeeklyChampionHint =>
      'Finish 1st in the Weekly Ranking.';

  @override
  String get profileAchievementWeeklyRunnerUpHint =>
      'Finish 2nd in the Weekly Ranking.';

  @override
  String get profileAchievementWeeklyThirdHint =>
      'Finish 3rd in the Weekly Ranking.';

  @override
  String profileAchievementCount(int count) {
    return 'x $count';
  }

  @override
  String get achievementClaim => 'Claim';

  @override
  String get achievementPocketGuide => 'Pocket Guide';

  @override
  String achievementPocketGuideHint(int count) {
    return 'Use the translator $count times during Roleplays.';
  }

  @override
  String get achievementHintSeeker => 'Hint Seeker';

  @override
  String achievementHintSeekerHint(int count) {
    return 'Use hints $count times during Roleplays.';
  }

  @override
  String get achievementTalkative => 'Talkative';

  @override
  String achievementTalkativeHint(int count) {
    return 'Speak a total of $count words.';
  }

  @override
  String get achievementSceneStealer => 'Scene Stealer';

  @override
  String achievementSceneStealerHint(int count) {
    return 'Complete $count Roleplays.';
  }

  @override
  String get achievementOnARoll => 'On a Roll';

  @override
  String achievementOnARollHint(int count) {
    return 'Practice for $count days in a row.';
  }

  @override
  String get otherUserFriends => 'Friends';

  @override
  String get otherUserRequested => 'Requested';

  @override
  String get otherUserAddFriend => 'Add Friend';

  @override
  String get otherUserUnfriendTitle => 'Unfriend this user?';

  @override
  String get otherUserUnfriendBody =>
      'You and this user will no longer be friends.';

  @override
  String get otherUserUnfriendOk => 'Unfriend';

  @override
  String get otherUserUnfriendCancel => 'Cancel';

  @override
  String get otherUserCancelRequestTitle => 'Cancel friend request?';

  @override
  String get otherUserCancelRequestBody =>
      'You won\'t be able to send another request to this user for 48 hours.';

  @override
  String get otherUserCancelRequestOk => 'Cancel Request';

  @override
  String get otherUserKeepRequest => 'Keep Request';

  @override
  String get otherUserSendRequestTitle => 'Send friend request?';

  @override
  String get otherUserSendRequestBody =>
      'You\'ll become friends when they accept your request.';

  @override
  String get otherUserSendRequestOk => 'Send Request';

  @override
  String get otherUserSendRequestCancel => 'Cancel';

  @override
  String get otherUserFriendBlockedBody =>
      'You can’t send a friend request to this user right now.';

  @override
  String get otherUserFriendOk => 'OK';

  @override
  String get otherUserFriendLimitSelf =>
      'You’ve reached the 30-friend limit. Remove a friend to add someone new.';

  @override
  String get otherUserFriendLimitThem =>
      'They’ve reached the 30-friend limit and can’t add any more friends.';

  @override
  String get otherUserNeighborsEmpty => 'No characters collected yet.';

  @override
  String get otherUserAchievementsEmpty => 'No achievements earned yet.';

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
  String get energyEnablePushTitle => 'Enable Notifications';

  @override
  String get energyEnablePushSubtitle =>
      'Turn on notifications and fully refill your Energy.';

  @override
  String get energyEnablePushPrice => 'Free';

  @override
  String get energyEnablePushOfferBadge => 'ONE-TIME OFFER';

  @override
  String get energyEnablePushCompleted => 'Energy refilled!';

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
  String get iapPurchaseProcessing => 'Your purchase is being processed.';

  @override
  String get iapPurchaseCompleted => 'Purchase complete.';

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
  String get paywallHeroTitle2 => 'Improve\nFaster';

  @override
  String get paywallHeroBody =>
      'Practice longer with Premium and get AI feedback to build your English confidence.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitMaxEnergy => 'Up to 30 Max Energy';

  @override
  String get paywallBenefitAiFeedback => 'AI Sentence Feedback';

  @override
  String get paywallBenefitProfileBadge => 'Premium Profile Badge';

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
  String get paywallFallbackMonthlyTimes12 => '\$167.88';

  @override
  String get paywallCompletedTitle => 'Congratulations!';

  @override
  String get paywallCompletedBody => 'Your Premium benefits are now active.';

  @override
  String get paywallCompletedContinue => 'Continue';

  @override
  String get roleplayChooseYourRole => 'Choose your role';

  @override
  String get roleplaySimilarRoleplays => 'Similar Roleplays';

  @override
  String get roleplayBeingPrepared => 'This roleplay is being prepared.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Complete all endings of the previous role to unlock this role.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% Complete';
  }

  @override
  String get roleplayTurnGradeA => 'wow!';

  @override
  String get roleplayTurnGradeB => 'ok!';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'oh…';

  @override
  String get tutorialSlide1Title =>
      'Use the **Translator** when you don\'t understand';

  @override
  String get tutorialSlide2Title =>
      'If pronunciation is hard, **listen** first, then **repeat**';

  @override
  String get tutorialSlide3Title =>
      'Check your **AI Feedback** after each conversation';

  @override
  String get tutorialSlideReady => 'I\'m Ready! >';

  @override
  String get tutorialSlideContinue => 'Continue >';

  @override
  String get tutorialSlide1Translation => 'What would you like?';

  @override
  String get tutorialSlide2HintLine => 'Just a latte, please.';

  @override
  String get tutorialSlide3SaidLabel => 'What You Said';

  @override
  String get tutorialSlide3BetterLabel => 'Better Expression';

  @override
  String get tutorialSlide3Feedback =>
      '\"I want coffee\" gets your point across! But when ordering, \"I\'d like\" sounds more polite and natural.';

  @override
  String rankCountdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String rankCountdownHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String rankCountdownMinutes(int count) {
    return '$count min';
  }

  @override
  String get rankWeeklyTitle => 'Weekly Ranking';

  @override
  String get rankAnnounceTitle => 'This Week\'s Results';

  @override
  String get rankTop3RewardsTitle => 'Top 3 Rewards';

  @override
  String get rankTop3RewardsDesc =>
      'Earn Likes each week and compete with other learners for the top spots!';

  @override
  String get rankTop3Place1 => '1st';

  @override
  String get rankTop3Place2 => '2nd';

  @override
  String get rankTop3Place3 => '3rd';

  @override
  String get rankTop3Badge1 => '1st Place Badge';

  @override
  String get rankTop3Badge2 => '2nd Place Badge';

  @override
  String get rankTop3Badge3 => '3rd Place Badge';

  @override
  String get rankTop3Likes100 => '+100 Likes';

  @override
  String get rankTop3Likes60 => '+60 Likes';

  @override
  String get rankTop3Likes50 => '+50 Likes';

  @override
  String get rankTop3Box3 => '×3 Reward Box';

  @override
  String get rankTop3Box2 => '×2 Reward Box';

  @override
  String get rankTop3Box1 => '×1 Reward Box';

  @override
  String get rankTop3Okay => 'Okay';

  @override
  String get rankNotRankedYetTitle => 'You\'re not ranked yet';

  @override
  String get rankNotRankedYetBody => 'Earn Likes to join this week\'s ranking.';

  @override
  String get rankAnnounceNextStartsIn => 'Next Ranking Starts in:';

  @override
  String get rankAnnounceYou => 'You:';

  @override
  String get rankAnnounceRank => 'Rank';

  @override
  String get rankAnnounceLike => 'Like';

  @override
  String get rankPlayNow => 'play now';

  @override
  String get rankingRewardClaimCongratulations => 'Congratulations!';

  @override
  String rankingRewardClaimFinishedPlace(int place) {
    return 'You finished #$place in this week\'s ranking!';
  }

  @override
  String get rankingRewardClaimYourRewards => 'Your Rewards';

  @override
  String get rankingRewardClaim => 'Claim';

  @override
  String get rankingRewardClaimError =>
      'Something went wrong. Please try again.';

  @override
  String get rewardUnboxingTapToOpen => 'Tap the box to open';

  @override
  String get rewardUnboxingNewCharacter => 'New Character!';

  @override
  String rewardUnboxingYouGot(String characterName) {
    return 'You got $characterName!';
  }

  @override
  String get rewardUnboxingSetAsProfile => 'Set as Profile';

  @override
  String get rewardUnboxingViewCharacter => 'View Character';
}
