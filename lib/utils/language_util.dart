import 'package:flutter/material.dart';

/// 언어 코드 관련 유틸리티
class LanguageUtil {
  /// 현재 디바이스의 언어 코드 가져오기
  /// 
  /// ISO 639-1 두 글자 언어 코드를 반환합니다 (예: 'ko', 'en', 'pt')
  /// Flutter의 platformDispatcher.locale을 사용하여 디바이스 언어 설정을 가져옵니다.
  /// 
  /// 반환값: 언어 코드 (예: 'ko', 'en', 'pt')
  static String getCurrentLanguageCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.languageCode;
  }

  /// 현재 디바이스의 BCP 47 language tag 가져오기
  ///
  /// 예: 'ko-KR', 'zh-Hans-CN'. region/script가 없으면 languageCode만 (예: 'ko').
  static String getCurrentLanguageTag() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.toLanguageTag();
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
