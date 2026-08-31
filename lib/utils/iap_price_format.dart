import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:intl/intl.dart';

/// IAP 스토어 가격과 동일한 국가·통화 포맷으로 금액 문자열 생성.
class IapPriceFormat {
  IapPriceFormat._();

  static const _alpha3ToAlpha2 = {
    'USA': 'US',
    'KOR': 'KR',
    'BRA': 'BR',
    'GBR': 'GB',
    'JPN': 'JP',
    'DEU': 'DE',
    'FRA': 'FR',
    'ITA': 'IT',
    'ESP': 'ES',
    'MEX': 'MX',
    'CAN': 'CA',
    'AUS': 'AU',
    'IND': 'IN',
    'IDN': 'ID',
    'THA': 'TH',
    'VNM': 'VN',
    'PHL': 'PH',
    'MYS': 'MY',
    'TWN': 'TW',
    'HKG': 'HK',
    'CHN': 'CN',
    'RUS': 'RU',
    'POL': 'PL',
    'NLD': 'NL',
    'TUR': 'TR',
    'SAU': 'SA',
    'ARE': 'AE',
    'PRT': 'PT',
  };

  static const _countryLocales = {
    'US': 'en_US',
    'BR': 'pt_BR',
    'KR': 'ko_KR',
    'JP': 'ja_JP',
    'GB': 'en_GB',
    'DE': 'de_DE',
    'FR': 'fr_FR',
    'IT': 'it_IT',
    'ES': 'es_ES',
    'MX': 'es_MX',
    'CA': 'en_CA',
    'AU': 'en_AU',
    'IN': 'en_IN',
    'ID': 'id_ID',
    'TH': 'th_TH',
    'VN': 'vi_VN',
    'PH': 'en_PH',
    'MY': 'ms_MY',
    'TW': 'zh_TW',
    'HK': 'zh_HK',
    'CN': 'zh_CN',
    'RU': 'ru_RU',
    'PL': 'pl_PL',
    'NL': 'nl_NL',
    'TR': 'tr_TR',
    'SA': 'ar_SA',
    'AE': 'ar_AE',
    'PT': 'pt_PT',
  };

  static const _currencyLocales = {
    'USD': 'en_US',
    'BRL': 'pt_BR',
    'KRW': 'ko_KR',
    'JPY': 'ja_JP',
    'EUR': 'de_DE',
    'GBP': 'en_GB',
    'CNY': 'zh_CN',
    'TWD': 'zh_TW',
    'HKD': 'zh_HK',
    'INR': 'en_IN',
    'RUB': 'ru_RU',
    'PLN': 'pl_PL',
    'TRY': 'tr_TR',
    'MXN': 'es_MX',
    'CAD': 'en_CA',
    'AUD': 'en_AU',
    'IDR': 'id_ID',
    'THB': 'th_TH',
    'VND': 'vi_VN',
    'PHP': 'en_PH',
    'MYR': 'ms_MY',
    'SAR': 'ar_SA',
    'AED': 'ar_AE',
  };

  /// [ProductDetails]에서 스토어 국가·통화 기준 locale (예: `pt_BR`).
  static String resolveLocale(ProductDetails product) {
    if (product is AppStoreProductDetails) {
      final country = product.skProduct.priceLocale.countryCode;
      if (country.isNotEmpty) {
        return localeFromCountryCode(country, currencyCode: product.currencyCode);
      }
    }
    return localeFromCurrencyCode(product.currencyCode);
  }

  /// iOS StoreKit country / Android currency → `language_COUNTRY`.
  static String localeFromCountryCode(
    String countryCode, {
    String? currencyCode,
  }) {
    final upper = countryCode.toUpperCase();
    final alpha2 = _alpha3ToAlpha2[upper] ??
        (upper.length == 2 ? upper : '');
    final fromCountry = alpha2.isEmpty ? null : _countryLocales[alpha2];
    if (fromCountry != null) return fromCountry;
    if (currencyCode != null && currencyCode.isNotEmpty) {
      return localeFromCurrencyCode(currencyCode);
    }
    return platformLocale();
  }

  static String localeFromCurrencyCode(String currencyCode) {
    final code = currencyCode.toUpperCase();
    return _currencyLocales[code] ?? platformLocale();
  }

  /// 디바이스 locale (`ko_KR` 형식).
  static String platformLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  /// 스토어 [product]와 동일 locale·통화로 [amount] 포맷.
  static String formatAmount(ProductDetails product, double amount) {
    return formatWithLocale(
      amount: amount,
      currencyCode: product.currencyCode,
      currencySymbol: product.currencySymbol,
      locale: resolveLocale(product),
    );
  }

  static String formatWithLocale({
    required double amount,
    required String currencyCode,
    required String currencySymbol,
    required String locale,
  }) {
    if (currencyCode.isEmpty) {
      return NumberFormat.decimalPattern(locale).format(amount);
    }
    return NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: currencySymbol.isNotEmpty ? currencySymbol : currencyCode,
    ).format(amount);
  }
}
