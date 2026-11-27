import 'dart:io' show Platform;

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suda/config/app_config.dart';

/// Meta 광고로 넘길 앱 이벤트. 운영(prd)에서만 SDK를 켠다.
///
/// 설치는 첫 실행의 활성화 이벤트. 가입은 Completed Registration.
/// 단건은 Purchase, 구독은 Subscribe. 자동 결제 수집은 쓰지 않는다.
class MetaAppEventsService {
  static final FacebookAppEvents _events = FacebookAppEvents();
  static const String _reportedOrdersKey = 'meta_reported_order_ids';
  static const int _reportedOrdersCap = 200;
  static Future<void>? _ready;

  static Future<void> initialize() {
    if (!AppConfig.isPrd) {
      debugPrint('[DEBUG] Meta init skip ENV=${AppConfig.env}');
      return Future<void>.value();
    }
    final existing = _ready;
    if (existing != null) return existing;
    final run = _start();
    _ready = run;
    return run;
  }

  static Future<void> _start() async {
    try {
      await _events.initializeSdk();
      await _events.setAutoLogAppEventsEnabled(false);
      await _events.setAutoLogMetaDataEnabled(false);
      await _events.setAdvertiserIdCollectionEnabled(Platform.isAndroid);
      await _events.activateApp();
      debugPrint('[DEBUG] Meta activateApp sent');
    } catch (e, st) {
      _ready = null;
      debugPrint('[DEBUG] Meta init failed: $e\n$st');
    }
  }

  static Future<void> logSignUp() async {
    if (!AppConfig.isPrd) {
      debugPrint('[DEBUG] Meta sign_up skip ENV=${AppConfig.env}');
      return;
    }
    try {
      await initialize();
      await _events.logCompletedRegistration(registrationMethod: 'agreement');
      debugPrint('[DEBUG] Meta CompletedRegistration sent');
    } catch (e, st) {
      debugPrint('[DEBUG] Meta CompletedRegistration failed: $e\n$st');
    }
  }

  /// 스토어 결제 1건. 단건 Purchase, 구독 Subscribe.
  ///
  /// 구독은 [orderId]가 있어야 보낸다. 있으면 기기에 남겨 재전송하지 않는다.
  static Future<void> logStorePurchase({
    required bool subscription,
    required double revenue,
    required String currencyCode,
    required String contentId,
    String? orderId,
    String? basePlanId,
  }) async {
    if (!AppConfig.isPrd) {
      debugPrint('[DEBUG] Meta logStorePurchase skip ENV=${AppConfig.env}');
      return;
    }
    final currency = currencyCode.trim().toUpperCase();
    if (revenue <= 0 || currency.length != 3 || contentId.isEmpty) {
      debugPrint(
        '[DEBUG] Meta logStorePurchase skip invalid '
        'revenue=$revenue currency=$currency contentId=$contentId',
      );
      return;
    }
    final order = orderId?.trim() ?? '';
    if (subscription && order.isEmpty) {
      debugPrint('[DEBUG] Meta Subscribe skip empty orderId');
      return;
    }
    if (order.isNotEmpty && await _alreadyReported(order)) {
      debugPrint('[DEBUG] Meta logStorePurchase skip duplicate orderId=$order');
      return;
    }
    final name = subscription ? 'Subscribe' : 'Purchase';
    try {
      await initialize();
      final plan = basePlanId?.trim() ?? '';
      final parameters = <String, dynamic>{
        FacebookAppEvents.paramNameContentId: contentId,
      };
      if (plan.isNotEmpty) parameters['base_plan_id'] = plan;
      if (subscription) {
        await _events.logSubscribe(
          orderId: order,
          price: revenue,
          currency: currency,
          parameters: parameters,
        );
      } else {
        if (order.isNotEmpty) {
          parameters[FacebookAppEvents.paramNameOrderId] = order;
        }
        await _events.logPurchase(
          amount: revenue,
          currency: currency,
          parameters: parameters,
        );
      }
      debugPrint('[DEBUG] Meta $name sent orderId=$order');
      if (order.isNotEmpty) await _rememberReported(order);
    } catch (e, st) {
      debugPrint('[DEBUG] Meta $name failed orderId=$order error=$e\n$st');
    }
  }

  static Future<bool> _alreadyReported(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_reportedOrdersKey);
      return raw != null && raw.contains(orderId);
    } catch (e, st) {
      debugPrint('[DEBUG] Meta reported-order read failed: $e\n$st');
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
      debugPrint('[DEBUG] Meta reported-order write failed: $e\n$st');
    }
  }
}
