import 'dart:async';
import 'package:flutter/foundation.dart';
import 'suda_api_client.dart';
import 'token_storage.dart';

/// Access Token 사전 갱신 서비스 (백그라운드 타이머 기반)
class TokenRefreshService {
  TokenRefreshService._();

  static final TokenRefreshService instance = TokenRefreshService._();

  Timer? _timer;
  Future<void>? _refreshFuture;

  /// 타이머 시작 (포그라운드 전제)
  void start() {
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      refreshIfNeeded();
    });
  }

  /// 타이머 중지
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 앱이 포그라운드로 돌아올 때 즉시 확인
  Future<void> onAppResumed() async {
    await refreshIfNeeded();
  }

  /// 만료 임박 시 refresh 수행 (중복 방지)
  Future<void> refreshIfNeeded() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _refreshIfNeededInternal();
    try {
      await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _refreshIfNeededInternal() async {
    final expiringSoon = await TokenStorage.isAccessTokenExpiringSoon();
    if (!expiringSoon) return;

    final refreshToken = await TokenStorage.loadRefreshToken();
    if (refreshToken == null) return;

    try {
      final deviceId = await TokenStorage.getDeviceId();
      final tokens = await SudaApiClient.refreshToken(
        refreshToken: refreshToken,
        deviceId: deviceId,
      );
      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (e) {
      debugPrint('[DEBUG] Token refresh failed: $e');
    }
  }
}
