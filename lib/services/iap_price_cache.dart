import 'package:shared_preferences/shared_preferences.dart';

/// Play Billing `formattedPrice` 영속 캐시.
///
/// - INAPP: key = productId
/// - SUBS: key = productId::basePlanId
class IapPriceCache {
  IapPriceCache._();

  static const _keyPrefix = 'iap_formatted_price_';

  static String _key(String productId, {String? basePlanId}) {
    if (basePlanId == null || basePlanId.isEmpty) return '$_keyPrefix$productId';
    return '$_keyPrefix$productId::$basePlanId';
  }

  static Future<void> save(
    String productId,
    String formattedPrice, {
    String? basePlanId,
  }) async {
    if (productId.isEmpty || formattedPrice.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(productId, basePlanId: basePlanId), formattedPrice);
  }

  static Future<String?> load(String productId, {String? basePlanId}) async {
    if (productId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(productId, basePlanId: basePlanId));
  }
}
