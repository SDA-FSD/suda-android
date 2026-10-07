import 'package:flutter/material.dart';

import '../models/user_models.dart';
import 'language_util.dart';

/// 사용자 `LANGUAGE_TAG`와 Flutter locale 매핑.
class AppLanguage {
  static String? tagOf(UserDto? user) {
    final meta = user?.metaInfo;
    if (meta == null) return null;
    for (final item in meta) {
      if (item.key == 'LANGUAGE_TAG') {
        final value = item.value.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static bool hasEnglishLevel(UserDto? user) {
    final meta = user?.metaInfo;
    if (meta == null) return false;
    for (final item in meta) {
      if (item.key == 'ENGLISH_LEVEL' && item.value.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// 태그 없으면 null. MaterialApp은 그때 기기 로케일을 쓴다.
  static Locale? materialLocale(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final lower = tag.toLowerCase();
    if (lower == 'zh-hant' || lower.startsWith('zh-hant-')) {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    }
    if (lower.startsWith('zh-hant') ||
        _region(lower) == 'tw' ||
        _region(lower) == 'hk' ||
        _region(lower) == 'mo') {
      if (lower.startsWith('zh')) {
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      }
    }
    if (lower.startsWith('zh')) {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
    if (lower == 'es-419' || lower.startsWith('es-419-')) {
      return const Locale('es', '419');
    }
    final primary = lower.split('-').first;
    const supported = {
      'en', 'ko', 'pt', 'es', 'ja', 'fr', 'de', 'it', 'vi', 'th', 'id', 'ms',
      'fil', 'hi', 'ar', 'tr', 'ru', 'pl', 'nl',
    };
    if (supported.contains(primary)) return Locale(primary);
    return const Locale('en');
  }

  /// 화면 문구용 locale. 저장된 태그가 있으면 그 값, 없을 때만 지금 위젯 locale.
  static Locale displayLocale(BuildContext context) {
    return materialLocale(LanguageUtil.boundTag) ??
        Localizations.localeOf(context);
  }

  static void apply(UserDto? user) {
    LanguageUtil.bind(tagOf(user));
  }

  static String? _region(String lowerTag) {
    final parts = lowerTag.split('-');
    if (parts.length < 2) return null;
    return parts.last;
  }
}
