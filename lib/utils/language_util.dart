import 'package:flutter/material.dart';

/// 언어 코드 관련 유틸리티.
///
/// [bind]에 사용자 `LANGUAGE_TAG`가 있으면 그 값을 쓴다. 없으면 기기 로케일.
class LanguageUtil {
  static String? _boundTag;

  /// 저장된 앱 언어. null이면 이후 조회는 기기 로케일.
  static void bind(String? languageTag) {
    final tag = languageTag?.trim();
    _boundTag = (tag == null || tag.isEmpty) ? null : tag;
  }

  static String? get boundTag => _boundTag;

  /// ISO 639-1 언어 코드. 저장 태그가 있으면 그 primary (`ko-KR` → `ko`).
  static String getCurrentLanguageCode() {
    final bound = _boundTag;
    if (bound != null) {
      final dash = bound.indexOf('-');
      return dash <= 0 ? bound : bound.substring(0, dash);
    }
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }

  /// BCP 47 language tag. 저장 태그가 있으면 그 원문.
  static String getCurrentLanguageTag() {
    final bound = _boundTag;
    if (bound != null) return bound;
    return WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
  }

  /// 서버 다국어 키 조회 순서. 대소문자 구분 (`ko-KR`).
  ///
  /// 기본: language tag → languageCode → `en`.
  /// [languageCode]를 넘기면 그 값(태그일 수 있음) → primary subtag → `en`.
  static List<String> localizationLookupKeys({String? languageCode}) {
    final keys = <String>[];
    void add(String? key) {
      if (key == null || key.isEmpty) return;
      if (!keys.contains(key)) keys.add(key);
    }

    if (languageCode != null && languageCode.isNotEmpty) {
      add(languageCode);
      add(_primaryLanguageSubtag(languageCode));
    } else {
      add(getCurrentLanguageTag());
      add(getCurrentLanguageCode());
    }
    add('en');
    return keys;
  }

  /// `ko-KR` → `ko`. 하이픈 없으면 null.
  static String? _primaryLanguageSubtag(String tagOrCode) {
    final hyphen = tagOrCode.indexOf('-');
    if (hyphen <= 0) return null;
    return tagOrCode.substring(0, hyphen);
  }

  /// 언어 코드가 유효한지 확인
  /// 
  /// ISO 639-1 표준에 맞는 두 글자 언어 코드인지 확인합니다.
  static bool isValidLanguageCode(String? code) {
    if (code == null || code.isEmpty) return false;
    // ISO 639-1은 두 글자 언어 코드
    return code.length == 2 && code.codeUnits.every((c) => 
      (c >= 97 && c <= 122) // a-z
    );
  }
}
