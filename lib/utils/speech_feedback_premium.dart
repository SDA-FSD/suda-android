import 'package:flutter/material.dart';

import '../api/suda_api_client.dart';
import '../screens/paywall/paywall.dart';
import '../services/energy_refresh_bus.dart';
import '../services/subscription_status_cache.dart';
import '../services/token_storage.dart';

/// Speech Feedback 펼침: 구독자만 허용. 비구독이면 Paywall.
///
/// Paywall에서 구독 완료 후 복귀 시에는 펼치지 않고, 캐시만 갱신한다.
/// 사용자가 Feedback을 다시 탭하면 그때 펼친다.
Future<bool> ensureSubscribedForSpeechFeedback(BuildContext context) async {
  if (SubscriptionStatusCache.isSubscribedActive) return true;

  final token = await TokenStorage.loadAccessToken();
  if (!context.mounted) return false;
  if (token != null && token.isNotEmpty) {
    try {
      await SudaApiClient.getUserEnergy(accessToken: token);
    } catch (_) {
      // 캐시/실패 시 아래 분기로
    }
  }
  if (!context.mounted) return false;
  if (SubscriptionStatusCache.isSubscribedActive) return true;

  final subscribed = await PaywallScreen.push<bool>(context);
  if (!context.mounted) return false;
  if (subscribed == true) {
    final accessToken = await TokenStorage.loadAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final dto =
            await SudaApiClient.getUserEnergy(accessToken: accessToken);
        EnergyRefreshBus.instance.notify(dto);
      } catch (_) {}
    }
    // 결제 직후 자동 펼침 없음 — 다음 Feedback 탭에서 연다.
    return false;
  }
  return false;
}
