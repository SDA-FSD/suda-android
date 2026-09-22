// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get agreementHeading => '서비스 이용을 위하여 아래 항목에 동의해주세요.';

  @override
  String get agreementTermsLabel => '이용약관에 동의합니다.';

  @override
  String get agreementPrivacyLabel => '개인정보 처리방침에 동의합니다.';

  @override
  String get agreementTermsTitle => '이용약관';

  @override
  String get agreementPrivacyTitle => '개인정보 처리방침';

  @override
  String get agreementDetailsLink => '자세히 보기';

  @override
  String get agreementButtonConfirm => '동의하고 이용하기';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsRestorePurchases => '구매 복원';

  @override
  String get restorePurchasesNothing => '복원할 구매 내역이 없습니다.';

  @override
  String get restorePurchasesCompleted => '구매가 복원되었습니다.';

  @override
  String get settingsNotification => '알림';

  @override
  String get settingsTutorial => '튜토리얼';

  @override
  String get settingsCefrLevel => '언어 레벨';

  @override
  String get pushNotifications => '푸시알림';

  @override
  String get pushNotificationsDesc => '중요한 알림과 업데이트를 받아보세요.';

  @override
  String get settingsFeedback => '피드백';

  @override
  String get settingsAnnouncements => '공지사항';

  @override
  String get announcementsEmpty => '아직 공지사항이 없습니다';

  @override
  String get noticesEmpty => '아직 게시글이 없습니다';

  @override
  String get deletedPost => '삭제된 게시물입니다.';

  @override
  String get postNoLongerAvailable => '게시물이 삭제되었거나 존재하지 않습니다.';

  @override
  String get backToHome => '홈으로 가기';

  @override
  String get settingsSignOut => '로그아웃';

  @override
  String get settingsFsdLaboratory => 'FSD 실험실';

  @override
  String get settingsPrivacy => '개인정보처리방침';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsOpenSource => '오픈소스 라이선스';

  @override
  String loginWelcome(String name) {
    return '$name님, 환영합니다!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return '계속 진행하실 경우, $terms 및 $privacy에 동의한 것으로 간주합니다.';
  }

  @override
  String get loginTermsTitle => '이용약관';

  @override
  String get loginPrivacyTitle => '개인정보처리방침';

  @override
  String get loginCatchphrase => '수다 떨면서 외국어 배우기';

  @override
  String get loginWelcomeTitle => 'Welcome to SUDA!';

  @override
  String get loginWelcomeSubtitle => '이야기 속에서 자연스럽게 말해보세요!';

  @override
  String get loginErrorIdToken => 'Google ID 토큰을 가져오지 못했습니다. 다시 시도해 주세요.';

  @override
  String loginErrorFailed(String error) {
    return '로그인 실패: $error';
  }

  @override
  String get accountName => '이름';

  @override
  String get accountChangePicture => '프로필 사진 변경';

  @override
  String get changeProfileImageTitle => '프로필 사진을 선택하세요';

  @override
  String get accountInfo => '계정';

  @override
  String get accountDelete => '계정 삭제';

  @override
  String get accountDeleteTitle => '계정을 삭제하시겠습니까?';

  @override
  String get accountDeleteConfirmText =>
      '모든 진행 상황과 데이터가 영구적으로 손실됩니다. 정말로 계속하시겠습니까?';

  @override
  String get accountDeleteProfileImageTitle => '프로필 이미지를 삭제하시겠어요?';

  @override
  String get accountDeleteProfileImageContent => '삭제하면 프로필 이미지는 복구할 수 없습니다.';

  @override
  String get accountGoBack => '이전으로';

  @override
  String get accountDeleteAction => '삭제';

  @override
  String get accountSubscription => '구독';

  @override
  String get accountFreePlanTitle => '무료 플랜';

  @override
  String get accountFreePlanSubtitle => '프리미엄으로 업그레이드하고 더 많은 기능을 이용해 보세요';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => '현재 프리미엄 혜택을 이용하고 있습니다';

  @override
  String accountPremiumRenewsOn(String date) {
    return '갱신일: $date';
  }

  @override
  String get accountChangePlan => '플랜 변경';

  @override
  String get changePlanTitle => '요금제 변경';

  @override
  String get changePlanCurrentPlan => '현재 요금제';

  @override
  String get changePlanAvailablePlans => '변경 가능한 플랜';

  @override
  String changePlanRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String get changePlanLoadFailed => '정보를 불러오지 못했습니다. 다시 시도해 주세요.';

  @override
  String get changePlanRetry => '다시 시도';

  @override
  String get changePlanConfirmTitle => '플랜을 변경하시겠습니까?';

  @override
  String get changePlanConfirmBody => '플랜 변경은 다음 결제일부터 적용됩니다';

  @override
  String get changePlanConfirmOk => '변경하기';

  @override
  String get changePlanConfirmCancel => '현재 플랜 유지';

  @override
  String get changePlanOldPurchaseMissing =>
      '변경할 활성 구독을 찾지 못했습니다. 구독이 활성인 상태에서 다시 시도해 주세요.';

  @override
  String get changePlanChangeRequested => '플랜 변경을 요청했습니다. 다음 결제일부터 적용될 수 있습니다.';

  @override
  String get cefrLevelTitle => '영어 레벨을 선택하세요';

  @override
  String get cefrLevelAbsoluteBeginner => '완전 초급';

  @override
  String get cefrLevelBeginner => '초급';

  @override
  String get cefrLevelBasic => '기본';

  @override
  String get cefrLevelIntermediate => '중급';

  @override
  String get firstCefrLevelTitle => '현재 영어 레벨을 선택해 주세요.';

  @override
  String get firstCefrLevelDescriptionPreA1 => '영어를 읽을 수 있어요';

  @override
  String get firstCefrLevelDescriptionA1 => '기본적인 인사말과 간단한 표현을 알아요';

  @override
  String get firstCefrLevelDescriptionA2 => '짧고 간단한 문장을 이해하고 사용할 수 있어요';

  @override
  String get firstCefrLevelDescriptionB1 => '제 의견을 말하고 일상 대화에 참여할 수 있어요';

  @override
  String get firstCefrLevelSettingsHint => '언제든지 변경할 수 있습니다';

  @override
  String get firstProfileImageTitle => '프로필 이미지를 선택하세요';

  @override
  String get actionConfirm => '확인';

  @override
  String get feedbackPlaceholder => '생각, 제안사항 또는 겪으신 문제점을 공유해 주세요...';

  @override
  String get feedbackSend => '전송';

  @override
  String get feedbackSuccess => '피드백을 보내주셔서 감사합니다.';

  @override
  String get microphonePermissionDenied => '마이크 권한이 없어서 시작할 수 없습니다.';

  @override
  String get holdMicrophoneToSpeak => '마이크를 길게 누르고 말하세요';

  @override
  String get roleplayTypeMessagePlaceholder => '여기에 메시지를 입력하세요.';

  @override
  String get yourTurnFirst => '먼저 시작해주세요!';

  @override
  String get sayLineBelowToStart => '아래 문장을 말해서 시작하세요.';

  @override
  String get roleplayExitWait => '잠깐!';

  @override
  String get roleplayExitMessage => '지금 나가면 보상을 놓치게 됩니다. 정말 나가시겠습니까?';

  @override
  String get roleplayExitKeepPlaying => '계속 플레이';

  @override
  String get roleplayExitExit => '나가기';

  @override
  String get roleplayAutoHint => '자동 힌트';

  @override
  String get roleplayHintLabel => '답변힌트';

  @override
  String get roleplayHintShowAnswer => '영어 답변 보기';

  @override
  String get roleplayVoiceSpeed => '음성 속도';

  @override
  String get roleplayEndedFailed => '미션을 실패했습니다...';

  @override
  String get roleplayEndedComplete => '롤플레이를 완료했습니다';

  @override
  String get roleplayEndedEnding => '엔딩으로 이동합니다...';

  @override
  String get roleplayFinishNotEnoughProgress => '대화 진행이 부족합니다';

  @override
  String get roleplayFinishCompleted => '롤플레이를 완료했습니다';

  @override
  String get roleplayFinishMovingToEnding => '엔딩으로 이동합니다...';

  @override
  String get roleplayAnalyzing => '롤플레이를 분석 중입니다…';

  @override
  String get roleplayOpeningAiCharacter => 'AI 캐릭터';

  @override
  String get roleplayOpeningScenario => '시나리오';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI는 실수할 수 있습니다.\n개인정보나 민감한 정보는 입력하지 마세요.';

  @override
  String get endingFailTitle => '모든 미션을 완수하지 못했습니다!';

  @override
  String get endingFailSubtitle => '다시 시도하여 전체 스토리를 발견하세요.';

  @override
  String get roleplayTryAgainMessage =>
      '아쉽지만 대화 점수가 낮아 보상을 받을 수 없어요. 다시 도전해보세요!';

  @override
  String get endingReport => '리포트';

  @override
  String get endingHowWas => '롤플레이는 어떠셨나요?';

  @override
  String get endingNext => '다음';

  @override
  String get reportTitle => '문제 신고';

  @override
  String get profileProgress => '성장';

  @override
  String get profileDayStreak => '연속 학습일';

  @override
  String get profileWordsSpoken => '말한 단어';

  @override
  String get profileSudaNeighbors => 'SUDA 이웃';

  @override
  String get profileSudaNeighborsEmpty => '리워드 박스를 열고 새로운 캐릭터를 모아보세요!';

  @override
  String profileLevelProgressReach(int level) {
    return 'Lv. $level에 도달하면 열 수 있어요!';
  }

  @override
  String get profileLevelProgressReachBody => 'Like를 모아 레벨을 올리고 보상 상자를 받아보세요.';

  @override
  String get profileLevelProgressGotIt => '확인';

  @override
  String get profileAchievements => '업적';

  @override
  String get profileAchievementWeeklyChampion => '주간 챔피언';

  @override
  String get profileAchievementWeeklyRunnerUp => '주간 준우승';

  @override
  String get profileAchievementWeeklyThird => '주간 3위';

  @override
  String get profileAchievementWeeklyChampionHint => '주간 랭킹에서 1위를 달성하세요.';

  @override
  String get profileAchievementWeeklyRunnerUpHint => '주간 랭킹에서 2위를 달성하세요.';

  @override
  String get profileAchievementWeeklyThirdHint => '주간 랭킹에서 3위를 달성하세요.';

  @override
  String profileAchievementCount(int count) {
    return 'x $count';
  }

  @override
  String get otherUserFriends => '친구';

  @override
  String get otherUserRequested => '요청 보냄';

  @override
  String get otherUserAddFriend => '친구 추가';

  @override
  String get otherUserUnfriendTitle => '친구를 해제할까요?';

  @override
  String get otherUserUnfriendBody => '이 사용자와의 친구 관계가 해제됩니다.';

  @override
  String get otherUserUnfriendOk => '친구 해제';

  @override
  String get otherUserUnfriendCancel => '취소';

  @override
  String get otherUserCancelRequestTitle => '친구 요청을 취소할까요?';

  @override
  String get otherUserCancelRequestBody =>
      '취소하면 이 사용자에게 48시간 동안 다시 친구 요청을 보낼 수 없습니다.';

  @override
  String get otherUserCancelRequestOk => '요청 취소';

  @override
  String get otherUserKeepRequest => '요청 유지';

  @override
  String get otherUserSendRequestTitle => '친구 요청을 보낼까요?';

  @override
  String get otherUserSendRequestBody => '상대방이 요청을 수락하면 친구가 됩니다.';

  @override
  String get otherUserSendRequestOk => '요청 보내기';

  @override
  String get otherUserSendRequestCancel => '취소';

  @override
  String get otherUserFriendBlockedBody => '현재 이 사용자에게 친구 요청을 보낼 수 없습니다.';

  @override
  String get otherUserFriendOk => '확인';

  @override
  String get otherUserFriendLimitSelf =>
      '친구는 최대 30명까지 추가할 수 있어요. 새로운 친구를 추가하려면 기존 친구를 삭제해 주세요.';

  @override
  String get otherUserFriendLimitThem =>
      '상대방이 친구 30명 한도에 도달해 지금은 친구를 추가할 수 없어요.';

  @override
  String get otherUserNeighborsEmpty => '아직 획득한 캐릭터가 없습니다.';

  @override
  String get otherUserAchievementsEmpty => '아직 획득한 업적이 없습니다.';

  @override
  String get profileHistory => '히스토리';

  @override
  String get profileSaved => '저장된 표현';

  @override
  String get profileHistoryEmpty => '아직 롤플레이 결과가 없습니다';

  @override
  String get profileSavedEmpty => '아직 저장된 표현이 없습니다.';

  @override
  String get profileSavedRemoveTitle => '표현을 삭제할까요?';

  @override
  String get profileSavedRemoveContent => '이 표현은 히스토리에서 다시 찾아 저장할 수 있어요.';

  @override
  String get profileSavedRemoveOk => '삭제할래요';

  @override
  String get profileSavedRemoveCancel => '더 연습할래요';

  @override
  String get seriesOverviewTabEpisodes => '에피소드';

  @override
  String get seriesOverviewTabSimilarTopic => '비슷한 주제';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return '에피소드 #$number';
  }

  @override
  String get seriesOverviewPlay => 'Play';

  @override
  String get seriesOverviewLocked => 'Locked';

  @override
  String get seriesOverviewEpisodeLockedToast => '이전 에피소드를 먼저 플레이하세요.';

  @override
  String get notificationPermissionBlockedTitle => '알림이 꺼져 있습니다';

  @override
  String get notificationPermissionBlockedMessage =>
      '푸시 알림을 받으려면 기기 설정에서 알림을 켜 주세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get notificationsTitle => '알림';

  @override
  String get notificationsEmpty => '아직 알림이 없습니다';

  @override
  String get notificationSendToday => '오늘';

  @override
  String get notificationSendOneDayAgo => '1일 전';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get reregistrationRestrictedMessage =>
      '회원 탈퇴 후 2일 동안 재가입이 제한됩니다. 잠시 후 다시 시도해주세요.';

  @override
  String get expressionSavedToProfile => '프로필에 저장되었습니다';

  @override
  String get expressionUnsavedToProfile => '저장 해제되었습니다';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      '단어 수가 부족해 피드백을 드리기 어려워요. 7단어 이상으로 더 길게 말해보세요!';

  @override
  String get roleplayResultScoreMeaning => '의미';

  @override
  String get roleplayResultScoreRelevance => '연관성';

  @override
  String get roleplayResultScoreVocabulary => '어휘';

  @override
  String get roleplayResultScoreGrammar => '문법';

  @override
  String get closePopup => '닫기';

  @override
  String get reviewChatTapHint => '채팅 말풍선을 눌러 오디오를 재생하세요.';

  @override
  String get reviewChatNoAudioToPlay => '재생할 음성이 없습니다.';

  @override
  String get seriesInformationTopicDifficulty => '주제 난이도';

  @override
  String get seriesInformationLearningGoals => '학습목표';

  @override
  String get energyInfoTitle => '에너지';

  @override
  String get energyOutOfEnergyTitle => '에너지 부족';

  @override
  String get energyInfoRechargeUntil => '다음 충전까지 @@TIME@@ 남았어요!';

  @override
  String get energyInfoFull => '에너지가 가득 찼습니다.';

  @override
  String get energyInfoUnlimitedEndsIn => '무제한 모드 이용 중';

  @override
  String get energyInsufficient => '에너지가 부족해요.';

  @override
  String get endRoleplay => '롤플레이 종료하기';

  @override
  String get energyEnablePushTitle => '알림 설정 하기';

  @override
  String get energyEnablePushSubtitle => '푸시 알림을 켜고 에너지를 가득 리필하세요.';

  @override
  String get energyEnablePushPrice => '무료';

  @override
  String get energyEnablePushOfferBadge => '최초 1회 혜택';

  @override
  String get energyEnablePushCompleted => '에너지가 가득 채워졌어요!';

  @override
  String get energyPurchaseUnlimitedTitle => '무제한 패스';

  @override
  String get energyPurchaseUnlimitedSubtitle => '구매 즉시 10분 무제한 모드가 시작됩니다.';

  @override
  String get energyPurchaseCapacityTitle => '최대 에너지 확장';

  @override
  String get energyPurchaseCapacitySubtitle => '최대 에너지 보유량이 영구적으로 1 증가합니다.';

  @override
  String get energyGoPremiumTitle => '프리미엄 구독';

  @override
  String get energyGoPremiumExplore => '혜택 보기';

  @override
  String get profileGoPremiumTitle => 'SUDA Premium 구독';

  @override
  String get profileGoPremiumExplore => '혜택보기';

  @override
  String get energyPurchasePendingApproval => '결제 승인 대기중입니다.';

  @override
  String get energyPurchaseNotCompleted => '결제가 이루어지지 않았습니다.';

  @override
  String get iapPurchaseProcessing => '결제를 처리하고 있습니다.';

  @override
  String get iapPurchaseCompleted => '결제가 완료되었습니다.';

  @override
  String get welcomeGiftTitle => '웰컴 기프트 도착!';

  @override
  String get welcomeGiftBenefitLead => '10분동안 무료로 즐겨보세요!';

  @override
  String get welcomeGiftLine2 => '무제한 플레이 모드';

  @override
  String get welcomeGiftLine3 => '프리미엄 기능 전체 오픈';

  @override
  String get welcomeGiftStartNow => '지금 시작하기';

  @override
  String get paywallHeroTitle1 => '제한은 줄이고';

  @override
  String get paywallHeroTitle2 => '더 빠르게\n성장하세요';

  @override
  String get paywallHeroBody => '에너지 걱정 없이 더 오래 연습하고, AI 상세 피드백으로 실력을 향상시키세요.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitMaxEnergy => '최대 에너지 30개';

  @override
  String get paywallBenefitAiFeedback => 'AI 문장 피드백 제공';

  @override
  String get paywallBenefitProfileBadge => '프리미엄 프로필 뱃지';

  @override
  String get paywallChoosePlan => '플랜을 선택하세요';

  @override
  String get paywallAnnualPlanTitle => '연간 플랜';

  @override
  String get paywallAnnualPlanSubtitle => '월간 플랜 대비\n33% 이상 절약';

  @override
  String get paywallMonthlyPlanTitle => '월간 플랜';

  @override
  String get paywallMonthlyPlanSubtitle => '월 단위로 부담없이 이용';

  @override
  String get paywallBestBadge => 'BEST';

  @override
  String get paywallCta => '구독하기';

  @override
  String get paywallAutoRenewNotice =>
      '구독은 현재 결제 기간이 종료되기 최소 24시간 전에 취소하지 않으면\n자동으로 갱신됩니다.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/월';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/연';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '₩12,500';

  @override
  String get paywallFallbackAnnual => '₩150,000';

  @override
  String get paywallFallbackMonthly => '₩21,000';

  @override
  String get paywallFallbackMonthlyTimes12 => '₩252,000';

  @override
  String get paywallCompletedTitle => '축하합니다!';

  @override
  String get paywallCompletedBody => '이제 프리미엄 기능을\n사용할 수 있어요.';

  @override
  String get paywallCompletedContinue => '계속하기';

  @override
  String get roleplayChooseYourRole => '역할을 선택하세요';

  @override
  String get roleplaySimilarRoleplays => '비슷한 롤플레이';

  @override
  String get roleplayBeingPrepared => '이 롤플레이는 준비 중입니다.';

  @override
  String get roleplayUnlockPreviousRole =>
      '이 역할을 잠금 해제하려면 이전 역할의 모든 엔딩을 완료하세요.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% 진행완료';
  }

  @override
  String get roleplayTurnGradeA => '와!';

  @override
  String get roleplayTurnGradeB => '좋아!';

  @override
  String get roleplayTurnGradeC => '흠…';

  @override
  String get roleplayTurnGradeD => '오…';

  @override
  String get tutorialPage1Title => '**미션**을 확인하고\n대화를 시작하세요.';

  @override
  String get tutorialPage1Tip => '* Tip: 자연스럽게 말할수록\n보상이 더 커져요!';

  @override
  String get tutorialPage2Title => '문장을 모르겠으면\n**번역기**를 사용하세요.';

  @override
  String get tutorialPage3Title => '막힐 때는\n**힌트**를 보고 말해보세요.';

  @override
  String get tutorialPage3Subtitle => '힌트 자동 노출은\n언제든 켜고 끌 수 있어요.';

  @override
  String get tutorialPage4Title => '발음이 어렵다면\n듣고 따라 말해 보세요.';

  @override
  String get tutorialPage4Tip => '* Tip: 영어 답변을 보지 않고 말하면\n더 높은 점수를 받을 수 있어요!';

  @override
  String get tutorialPage5Title => '말하기 어려운 상황이면\n**텍스트 모드**로 전환하세요.';

  @override
  String get tutorialPage5Subtitle => '';

  @override
  String get tutorialPage6Title => '아무도 평가하지 않아요.\n자신 있게 말해봐요!';

  @override
  String rankCountdownDays(int count) {
    return '$count일 남음';
  }

  @override
  String rankCountdownHours(int count) {
    return '$count시간 남음';
  }

  @override
  String rankCountdownMinutes(int count) {
    return '$count분 남음';
  }

  @override
  String get rankWeeklyTitle => '주간 랭킹';

  @override
  String get rankAnnounceTitle => '주간 랭킹 결과';

  @override
  String get rankTop3RewardsTitle => 'TOP 3 보상';

  @override
  String get rankTop3RewardsDesc => '매주 Like를 획득하고 다른 학습자들과 상위 순위를 겨뤄보세요!';

  @override
  String get rankTop3Place1 => '1위';

  @override
  String get rankTop3Place2 => '2위';

  @override
  String get rankTop3Place3 => '3위';

  @override
  String get rankTop3Badge1 => '1위 배지';

  @override
  String get rankTop3Badge2 => '2위 배지';

  @override
  String get rankTop3Badge3 => '3위 배지';

  @override
  String get rankTop3Likes100 => '+100 Likes';

  @override
  String get rankTop3Likes60 => '+60 Likes';

  @override
  String get rankTop3Likes50 => '+50 Likes';

  @override
  String get rankTop3Box3 => '×3 보상 상자';

  @override
  String get rankTop3Box2 => '×2 보상 상자';

  @override
  String get rankTop3Box1 => '×1 보상 상자';

  @override
  String get rankTop3Okay => '확인';

  @override
  String get rankNotRankedYetTitle => '아직 랭킹에 참여하지 않았어요';

  @override
  String get rankNotRankedYetBody => 'Like를 획득하고 이번 주 랭킹에 참여해보세요.';

  @override
  String get rankAnnounceNextStartsIn => '다음 랭킹 시작까지:';

  @override
  String get rankAnnounceYou => '나:';

  @override
  String get rankAnnounceRank => '순위';

  @override
  String get rankAnnounceLike => 'Like';

  @override
  String get rankPlayNow => '지금 플레이';

  @override
  String get rankingRewardClaimCongratulations => '축하해요!';

  @override
  String rankingRewardClaimFinishedPlace(int place) {
    return '이번 주 랭킹에서 $place위를 차지했어요!';
  }

  @override
  String get rankingRewardClaimYourRewards => '나의 보상';

  @override
  String get rankingRewardClaim => '보상 받기';

  @override
  String get rankingRewardClaimError => '문제가 발생했어요. 다시 시도해주세요.';

  @override
  String get rewardUnboxingTapToOpen => '상자를 탭해서 열어보세요';

  @override
  String get rewardUnboxingNewCharacter => '새로운 캐릭터!';

  @override
  String rewardUnboxingYouGot(String characterName) {
    return '$characterName 를 획득했어요!';
  }

  @override
  String get rewardUnboxingSetAsProfile => '프로필로 설정';

  @override
  String get rewardUnboxingViewCharacter => '캐릭터 보기';
}
