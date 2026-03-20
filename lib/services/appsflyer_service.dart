import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:suda/config/app_config.dart';

/// AppsFlyer SDK 초기화 서비스
///
/// 운영(prd) 환경에서만 SDK를 초기화한다.
class AppsflyerService {
  static const String _devKey = 'HB9bSEm3Gw6siaicgKTAyK';
  static bool _initialized = false;
  static AppsflyerSdk? _sdk;

  static Future<void> initialize() async {
    if (_initialized || !AppConfig.isPrd) {
      return;
    }

    try {
      final options = AppsFlyerOptions(
        afDevKey: _devKey,
        showDebug: kDebugMode,
      );

      final sdk = AppsflyerSdk(options);
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnDeepLinkingCallback: true,
        registerOnAppOpenAttributionCallback: true,
      );
      sdk.startSDK();
      _sdk = sdk;
      _initialized = true;
    } catch (_) {
      // AppsFlyer 초기화 실패는 앱 실행을 막지 않는다.
    }
  }

  static Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? values,
  }) async {
    if (!_initialized || !AppConfig.isPrd || _sdk == null) {
      return;
    }
    try {
      await _sdk!.logEvent(eventName, values ?? <String, dynamic>{});
    } catch (_) {
      // 이벤트 전송 실패는 앱 실행 흐름을 막지 않는다.
    }
  }
}
