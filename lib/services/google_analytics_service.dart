import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suda/config/app_config.dart';

/// Google Ads로 넘길 GA4 이벤트. 운영(prd)에서만 전송한다.
///
/// 가입 `sign_up`. 단건 `purchase`, 구독 `subscribe`.
/// 구독·단건은 [orderId]를 기기에 남겨 재전송하지 않는다.
class GoogleAnalyticsService {
  static const String _reportedOrdersKey = 'ga_reported_order_ids';
  static const int _reportedOrdersCap = 200;

  static Future<void> logSignUp() async {
    if (!AppConfig.isPrd) {
      debugPrint('[DEBUG] GA sign_up skip ENV=${AppConfig.env}');
      return;
    }
    try {
      await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'agreement');
      debugPrint('[DEBUG] GA sign_up sent');
    } catch (e, st) {
      debugPrint('[DEBUG] GA sign_up failed: $e\n$st');
    }
  }

  /// 스토어 결제 1건. 단건 `purchase`, 구독 `subscribe`.
  ///
  /// `value`와 `currency`가 있어야 Google Ads 가치로 잡힌다.
  static Future<void> logStorePurchase({
    required bool subscription,
    required double revenue,
    required String currencyCode,
    required String contentId,
    String? orderId,
    String? basePlanId,
  }) async {
    if (!AppConfig.isPrd) {
      debugPrint('[DEBUG] GA logStorePurchase skip ENV=${AppConfig.env}');
      return;
    }
    final currency = currencyCode.trim().toUpperCase();
    if (revenue <= 0 || currency.length != 3 || contentId.isEmpty) {
      debugPrint(
        '[DEBUG] GA logStorePurchase skip invalid '
        'revenue=$revenue currency=$currency contentId=$contentId',
      );
      return;
    }
    final order = orderId?.trim() ?? '';
    if (order.isNotEmpty && await _alreadyReported(order)) {
      debugPrint('[DEBUG] GA logStorePurchase skip duplicate orderId=$order');
      return;
    }
    final name = subscription ? 'subscribe' : 'purchase';
    try {
      if (subscription) {
        final params = <String, Object>{
          'value': revenue,
          'currency': currency,
          'item_id': contentId,
        };
        if (order.isNotEmpty) params['transaction_id'] = order;
        final plan = basePlanId?.trim() ?? '';
        if (plan.isNotEmpty) params['base_plan_id'] = plan;
        await FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: params,
        );
      } else {
        await FirebaseAnalytics.instance.logPurchase(
          currency: currency,
          value: revenue,
          transactionId: order.isEmpty ? null : order,
          items: [
            AnalyticsEventItem(itemId: contentId, quantity: 1),
          ],
        );
      }
      debugPrint('[DEBUG] GA $name sent orderId=$order');
      if (order.isNotEmpty) await _rememberReported(order);
    } catch (e, st) {
      debugPrint('[DEBUG] GA $name failed orderId=$order error=$e\n$st');
    }
  }

  static Future<bool> _alreadyReported(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_reportedOrdersKey);
      return raw != null && raw.contains(orderId);
    } catch (e, st) {
      debugPrint('[DEBUG] GA reported-order read failed: $e\n$st');
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
      debugPrint('[DEBUG] GA reported-order write failed: $e\n$st');
    }
  }
}
