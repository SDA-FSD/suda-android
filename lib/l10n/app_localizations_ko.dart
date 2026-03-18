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
  String get settingsLanguageLevel => '언어 레벨';

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
  String get languageLevelTitle => '영어 레벨을 선택하세요';

  @override
  String get languageLevelDescription => 'SUDA의 주민들은 당신의 레벨에 맞추어 대화합니다.';

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
  String get roleplayEndedFailed => '미션을 실패했습니다...';

  @override
  String get roleplayEndedTimesup => '시간이 소진되었습니다...';

  @override
  String get roleplayEndedComplete => '롤플레이를 완료했습니다';

  @override
  String get roleplayEndedEnding => '엔딩으로 이동합니다...';

  @override
  String get endingFailTitle => '모든 미션을 완수하지 못했습니다!';

  @override
  String get endingFailSubtitle => '다시 시도하여 전체 스토리를 발견하세요.';

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
  String get profileHistoryEmpty => '아직 롤플레이 결과가 없습니다';

  @override
  String get noTicketsTitle => '티켓이 없습니다...';

  @override
  String get noTicketsBody => '오늘의 티켓을 모두 소진했습니다.\n내일 다시 만나요!';

  @override
  String get surveyPromptLine1 => '티켓을 모두 소진했습니다.';

  @override
  String get surveyPromptLine2 => '짧은 설문을 마치고 티켓을 받으세요!';

  @override
  String get pushTicketPromptLine2 => '푸시 알림을 켜고, 티켓을 받으세요!';

  @override
  String get surveyAnswerNowButton => '설문 시작하기 ✅';

  @override
  String get pushTicketTurnOnButton => '알림 켜기 🔔';

  @override
  String get shareTicketPromptLine2 => '앱 링크를 공유하고 티켓을 받으세요!';

  @override
  String get shareTicketButton => '공유하기💬';

  @override
  String get reviewTicketPromptLine2 => '리뷰를 남기고 티켓을 받으세요!';

  @override
  String get reviewTicketButton => '리뷰하기 ⭐';

  @override
  String get surveyMaybeLater => '다음에 하기';

  @override
  String get surveyStep1Title => '연령대를 선택해주세요';

  @override
  String get surveyStep2Title => '성별을 알려주세요';

  @override
  String get surveyStep3Title => 'SUDA를 어디에서 보셨나요?';

  @override
  String get surveyGenderFemale => '여성';

  @override
  String get surveyGenderMale => '남성';

  @override
  String get surveyGenderPreferNotToSay => '응답 거부';

  @override
  String get surveySuccessToast => '티켓 1장이 추가되었습니다! 🎉';

  @override
  String get dailyTicketTitle => '출석 보상 도착!';

  @override
  String get dailyTicketContent => '데일리 무료 티켓을 받으세요!\n오늘 사용하지 않으면 사라집니다.';

  @override
  String get dailyTicketButton => '티켓 받기 🎟️';

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
  String get reregistrationRestrictedMessage =>
      '회원 탈퇴 후 2일 동안 재가입이 제한됩니다. 잠시 후 다시 시도해주세요.';
}
