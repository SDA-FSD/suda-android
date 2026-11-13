import 'package:flutter/foundation.dart';

/// Wait「충전되면 다시 올게요」후 홈에서 푸시 유도 시트를 띄우기 위한 pending.
/// [request] 후 Home이 [take]로 소비한다.
class PendingOutOfEnergyPushReminder {
  PendingOutOfEnergyPushReminder._();

  static final PendingOutOfEnergyPushReminder instance =
      PendingOutOfEnergyPushReminder._();

  String? _accessToken;

  /// null이 아니면 노출 대기 중. Home 리스너가 rebuild/소비 트리거.
  final ValueNotifier<String?> pendingNotifier = ValueNotifier<String?>(null);

  bool get hasPending =>
      _accessToken != null && _accessToken!.isNotEmpty;

  void request(String accessToken) {
    if (accessToken.isEmpty) return;
    _accessToken = accessToken;
    pendingNotifier.value = accessToken;
  }

  /// 소비. 없으면 null.
  String? take() {
    final token = _accessToken;
    _accessToken = null;
    pendingNotifier.value = null;
    if (token == null || token.isEmpty) return null;
    return token;
  }
}
