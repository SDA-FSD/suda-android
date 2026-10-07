import 'package:flutter/widgets.dart';

import '../services/suda_api_client.dart';
import '../services/token_storage.dart';

class AppLanguageOption {
  final String id;
  final String label;
  /// 지역·스크립트가 고정이면 기기 태그를 붙이지 않는다.
  final bool fixed;
  final String code;

  const AppLanguageOption(this.id, this.label, this.code, this.fixed);
}

class AppLanguageOptions {
  static const catalog = <AppLanguageOption>[
    AppLanguageOption('en', 'English', 'en', false),
    AppLanguageOption('ko', '한국어', 'ko', false),
    AppLanguageOption('pt-BR', 'Português (Brasil)', 'pt-BR', true),
    AppLanguageOption('es-419', 'Español (Latinoamérica)', 'es-419', true),
    AppLanguageOption('ja', '日本語', 'ja', false),
    AppLanguageOption('zh-Hans', '简体中文', 'zh-Hans', true),
    AppLanguageOption('zh-Hant', '繁體中文', 'zh-Hant', true),
    AppLanguageOption('fr', 'Français', 'fr', false),
    AppLanguageOption('de', 'Deutsch', 'de', false),
    AppLanguageOption('it', 'Italiano', 'it', false),
    AppLanguageOption('vi', 'Tiếng Việt', 'vi', false),
    AppLanguageOption('th', 'ไทย', 'th', false),
    AppLanguageOption('id', 'Bahasa Indonesia', 'id', false),
    AppLanguageOption('ms', 'Bahasa Melayu', 'ms', false),
    AppLanguageOption('fil', 'Filipino', 'fil', false),
    AppLanguageOption('hi', 'हिन्दी', 'hi', false),
    AppLanguageOption('ar', 'العربية', 'ar', false),
    AppLanguageOption('tr', 'Türkçe', 'tr', false),
    AppLanguageOption('ru', 'Русский', 'ru', false),
    AppLanguageOption('pl', 'Polski', 'pl', false),
    AppLanguageOption('nl', 'Nederlands', 'nl', false),
  ];

  static final _tagPattern = RegExp(r'^[A-Za-z0-9-]{1,12}$');

  static String? optionIdForTag(String? tag) {
    if (tag == null || tag.trim().isEmpty) return null;
    final lower = tag.trim().toLowerCase();
    for (final option in catalog) {
      if (option.code.toLowerCase() == lower) return option.id;
    }
    if (lower.startsWith('zh')) {
      final region = lower.split('-').last;
      if (lower.contains('hant') ||
          region == 'tw' ||
          region == 'hk' ||
          region == 'mo') {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }
    if (lower.startsWith('pt')) return 'pt-BR';
    if (lower.startsWith('es')) return 'es-419';
    if (lower.startsWith('fil') || lower.startsWith('tl')) return 'fil';
    final primary = lower.split('-').first;
    for (final option in catalog) {
      if (!option.fixed && option.code == primary) return option.id;
    }
    return null;
  }

  static String? similarId(Locale device) {
    final lang = device.languageCode.toLowerCase();
    final script = device.scriptCode?.toLowerCase();
    final country = device.countryCode?.toUpperCase();
    if (lang == 'zh') {
      if (script == 'hant' ||
          country == 'TW' ||
          country == 'HK' ||
          country == 'MO') {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }
    if (lang == 'pt') return 'pt-BR';
    if (lang == 'es') return 'es-419';
    if (lang == 'fil' || lang == 'tl') return 'fil';
    for (final option in catalog) {
      if (!option.fixed && option.code == lang) return option.id;
    }
    return null;
  }

  static List<AppLanguageOption> pinnedForDevice(Locale device) {
    final similar = similarId(device);
    if (similar == null) return List.of(catalog);
    final picked = catalog.where((option) => option.id == similar);
    final rest = catalog.where((option) => option.id != similar);
    return [...picked, ...rest];
  }

  static String valueToSave(AppLanguageOption option, Locale device) {
    if (option.fixed) return option.code;
    if (device.languageCode.toLowerCase() != option.code) return option.code;
    final tag = device.toLanguageTag();
    if (_tagPattern.hasMatch(tag)) return tag;
    return option.code;
  }

  static Future<UserDto> persist(String tag) async {
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      throw Exception('missing token');
    }
    await SudaApiClient.updateLanguageTag(
      accessToken: token,
      languageTag: tag,
    );
    final fresh = await SudaApiClient.getCurrentUser(accessToken: token);
    return fresh.upsertMetaInfo(key: 'LANGUAGE_TAG', value: tag);
  }
}
