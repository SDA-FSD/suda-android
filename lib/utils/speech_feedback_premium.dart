import 'package:flutter/material.dart';

import '../screens/paywall/paywall.dart';

/// Speech Feedback 펼침: 서버 `feedbackLockedYn` 기준.
///
/// - `'N'`(또는 그 외 비-Y): 즉시 허용
/// - `'Y'`: Paywall. 구독 성공 시 [onUnlockedAfterPaywall]로 history 재조회만 하고
///   **자동 펼침 없음**(재탭 시 펼침).
Future<bool> ensureSpeechFeedbackUnlocked(
  BuildContext context, {
  required String feedbackLockedYn,
  Future<void> Function()? onUnlockedAfterPaywall,
}) async {
  if (feedbackLockedYn != 'Y') return true;

  final subscribed = await PaywallScreen.push<bool>(context);
  if (!context.mounted) return false;
  if (subscribed == true) {
    try {
      await onUnlockedAfterPaywall?.call();
    } catch (_) {}
    return false;
  }
  return false;
}
