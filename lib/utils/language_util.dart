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
