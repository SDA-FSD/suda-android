import 'dart:async';

import '../../services/token_storage.dart';
import '../suda_api_client.dart';

/// 온보딩 튜토리얼 진행 단계. 화면 분기가 아니라 최초 1회 통계다.
class OnboardingTutorialProgressStep {
  const OnboardingTutorialProgressStep._();

  static const startTapped = 'START_TAPPED';
  static const micPermissionPassed = 'MIC_PERMISSION_PASSED';
  static const firstMicReady = 'FIRST_MIC_READY';
  static const firstMicPressed = 'FIRST_MIC_PRESSED';
  static const turn1Accepted = 'TURN_1_ACCEPTED';
  static const firstHintOpened = 'FIRST_HINT_OPENED';
  static const turn2Accepted = 'TURN_2_ACCEPTED';
  static const turn3Accepted = 'TURN_3_ACCEPTED';
  static const skipConfirmed = 'SKIP_CONFIRMED';
}

/// Lab preview는 보내지 않는다. 실패해도 튜토리얼은 그대로 진행한다.
void reportOnboardingTutorialProgress({
  required bool preview,
  required String step,
}) {
  if (preview) return;
  unawaited(() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) return;
      await SudaApiClient.postOnboardingTutorialProgress(
        accessToken: token,
        step: step,
      );
    } catch (_) {}
  }());
}
