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
    if (_initialized) {
      debugPrint('[DEBUG] AF skip: already initialized');
      return;
    }
    if (!AppConfig.isPrd) {
      debugPrint('[DEBUG] AF skip: ENV=${AppConfig.env} (prd only)');
      return;
    }

    try {
      final options = AppsFlyerOptions(
        afDevKey: _devKey,
        showDebug: true,
        manualStart: true,
      );

      final sdk = AppsflyerSdk(options);
      sdk.onInstallConversionData((data) {
        debugPrint('[DEBUG] AF conversion data: $data');
      });
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnDeepLinkingCallback: true,
        registerOnAppOpenAttributionCallback: true,
      );
      final version = await sdk.getSDKVersion();
      debugPrint('[DEBUG] AF native SDK version=$version ENV=${AppConfig.env}');
      sdk.startSDK(
        onSuccess: () {
          debugPrint('[DEBUG] AF startSDK onSuccess');
        },
        onError: (int errorCode, String errorMessage) {
          debugPrint(
            '[DEBUG] AF startSDK onError code=$errorCode message=$errorMessage',
          );
        },
      );
      _sdk = sdk;
      _initialized = true;
      debugPrint('[DEBUG] AF startSDK invoked');
      Future<void>.delayed(const Duration(seconds: 3), () {
        logEvent(
          'debug_sdk_probe',
          values: {'ts': DateTime.now().toIso8601String()},
        );
      });
    } catch (e, st) {
      debugPrint('[DEBUG] AF initialize failed: $e');
      debugPrint('[DEBUG] AF initialize stack: $st');
    }
  }

  static Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? values,
  }) async {
    if (!_initialized || !AppConfig.isPrd || _sdk == null) {
      debugPrint(
        '[DEBUG] AF logEvent skip name=$eventName '
        'initialized=$_initialized ENV=${AppConfig.env}',
      );
      return;
    }
    try {
      final result =
          await _sdk!.logEvent(eventName, values ?? <String, dynamic>{});
      debugPrint('[DEBUG] AF logEvent name=$eventName result=$result');
    } catch (e, st) {
      debugPrint('[DEBUG] AF logEvent failed name=$eventName error=$e');
      debugPrint('[DEBUG] AF logEvent stack: $st');
    }
  }
}
