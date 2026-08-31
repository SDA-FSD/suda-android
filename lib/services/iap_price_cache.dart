import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Play/App Store 가격·메타 영속 캐시.
///
/// - INAPP: key = productId
/// - SUBS: key = productId::basePlanId
class IapPriceCache {
  IapPriceCache._();

  static const _keyPrefix = 'iap_formatted_price_';
  static const _metaKeyPrefix = 'iap_price_meta_';

  static String _key(String productId, {String? basePlanId}) {
    if (basePlanId == null || basePlanId.isEmpty) return '$_keyPrefix$productId';
    return '$_keyPrefix$productId::$basePlanId';
  }

  static String _metaKey(String productId, {String? basePlanId}) {
    if (basePlanId == null || basePlanId.isEmpty) {
      return '$_metaKeyPrefix$productId';
    }
    return '$_metaKeyPrefix$productId::$basePlanId';
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

  static Future<void> saveMeta(
    IapPriceMeta meta, {
    required String productId,
    String? basePlanId,
  }) async {
    if (productId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _metaKey(productId, basePlanId: basePlanId),
      jsonEncode(meta.toJson()),
    );
  }

  static Future<IapPriceMeta?> loadMeta({
    required String productId,
    String? basePlanId,
  }) async {
    if (productId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey(productId, basePlanId: basePlanId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return IapPriceMeta.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

/// 스토어 조회 시 저장하는 가격 메타 (폴백·계산가 포맷용).
class IapPriceMeta {
  final String formattedPrice;
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;
  final String locale;

  const IapPriceMeta({
    required this.formattedPrice,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
    required this.locale,
  });

  Map<String, dynamic> toJson() => {
        'formattedPrice': formattedPrice,
        'rawPrice': rawPrice,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'locale': locale,
      };

  factory IapPriceMeta.fromJson(Map<String, dynamic> json) {
    return IapPriceMeta(
      formattedPrice: json['formattedPrice'] as String? ?? '',
      rawPrice: (json['rawPrice'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currencyCode'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
    );
  }
}
