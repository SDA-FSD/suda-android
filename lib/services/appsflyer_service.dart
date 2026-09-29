import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suda/config/app_config.dart';

/// AppsFlyer SDK 초기화 서비스
///
/// 운영(prd) 환경에서만 SDK를 초기화한다.
class AppsflyerService {
  static const String _devKey = 'HB9bSEm3Gw6siaicgKTAyK';
  /// ASC Apple ID. iOS만 필수. 없으면 릴리스에서 이벤트가 iOS 앱에 안 붙는다.
  static const String _iosAppId = '6798914572';
  static const String _reportedOrdersKey = 'af_reported_order_ids';
  static const int _reportedOrdersCap = 200;
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
        appId: _iosAppId,
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

  static Future<bool> logEvent(
    String eventName, {
    Map<String, dynamic>? values,
  }) async {
    if (!_initialized || !AppConfig.isPrd || _sdk == null) {
      debugPrint(
        '[DEBUG] AF logEvent skip name=$eventName '
        'initialized=$_initialized ENV=${AppConfig.env}',
      );
      return false;
    }
    try {
      final result =
          await _sdk!.logEvent(eventName, values ?? <String, dynamic>{});
      debugPrint('[DEBUG] AF logEvent name=$eventName result=$result');
      return result != false;
    } catch (e, st) {
      debugPrint('[DEBUG] AF logEvent failed name=$eventName error=$e');
      debugPrint('[DEBUG] AF logEvent stack: $st');
      return false;
    }
  }

  /// 스토어 결제 1건. 단건 `af_purchase`, 구독 `af_subscribe`.
  ///
  /// `af_revenue`가 있어야 AppsFlyer Total Revenue에 잡힌다.
  /// [orderId]가 있으면 기기에 남겨 재전송하지 않는다.
  static Future<void> logPurchase({
    required bool subscription,
    required double revenue,
    required String currencyCode,
    required String contentId,
    String? orderId,
    String? basePlanId,
  }) async {
    final currency = currencyCode.trim().toUpperCase();
    if (revenue <= 0 || currency.length != 3 || contentId.isEmpty) {
      debugPrint(
        '[DEBUG] AF logPurchase skip invalid '
        'revenue=$revenue currency=$currency contentId=$contentId',
      );
      return;
    }
    final order = orderId?.trim() ?? '';
    if (order.isNotEmpty && await _alreadyReported(order)) {
      debugPrint('[DEBUG] AF logPurchase skip duplicate orderId=$order');
      return;
    }
    final values = <String, dynamic>{
      'af_revenue': revenue,
      'af_currency': currency,
      'af_quantity': 1,
      'af_content_id': contentId,
    };
    if (order.isNotEmpty) values['af_order_id'] = order;
    final plan = basePlanId?.trim() ?? '';
    if (subscription && plan.isNotEmpty) values['base_plan_id'] = plan;
    final sent = await logEvent(
      subscription ? 'af_subscribe' : 'af_purchase',
      values: values,
    );
    if (sent && order.isNotEmpty) {
      await _rememberReported(order);
    }
  }

  static Future<bool> _alreadyReported(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_reportedOrdersKey);
      return raw != null && raw.contains(orderId);
    } catch (e, st) {
      debugPrint('[DEBUG] AF reported-order read failed: $e\n$st');
      return false;
    }
  }

  static Future<void> _rememberReported(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = List<String>.of(
        prefs.getStringList(_reportedOrdersKey) ?? const <String>[],
      );
      raw.remove(orderId);
      raw.add(orderId);
      final capped = raw.length > _reportedOrdersCap
          ? raw.sublist(raw.length - _reportedOrdersCap)
          : raw;
      await prefs.setStringList(_reportedOrdersKey, capped);
    } catch (e, st) {
      debugPrint('[DEBUG] AF reported-order write failed: $e\n$st');
    }
  }
}
