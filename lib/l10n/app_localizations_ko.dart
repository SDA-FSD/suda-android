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
  String get firstCefrLevelConfirm => '확인';

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
}
