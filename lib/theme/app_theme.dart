import 'package:flutter/material.dart';

/// 앱 전역 테마 설정
/// 
/// MaterialApp에서 사용할 ThemeData를 정의
class AppTheme {
  /// 기본 테마 데이터
  static ThemeData get themeData {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212), // 기본 배경색 설정

      // 기본 폰트 패밀리 (텍스트 전반에 사용)
      fontFamily: 'ChironHeiHK',

      // 전역 텍스트 스타일 정의 (CSS의 h1, body 등과 유사하게 사용)
      //
      // 매핑:
      // - heading1      -> headlineLarge
      // - heading2      -> headlineMedium
      // - heading3      -> headlineSmall
      // - body-default  -> bodyLarge
      // - body-secondary-> bodyMedium
      // - body-caption  -> bodySmall
      // - body-tiny     -> labelSmall
      textTheme: const TextTheme(
        // heading1: default font, fontsize 32, w700
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        // heading2: default font, fontsize 24, w600
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        // heading3: default font, fontsize 20, w700
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        // body-default: default font, fontsize 18, w400
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
        // body-secondary: default font, fontsize 16, w400
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
        // body-caption: default font, fontsize 14, w400
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
        // body-tiny: default font, fontsize 12, w600
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),

      // 1. ElevatedButton (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'ChironGoRoundTC',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 2. OutlinedButton (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'ChironGoRoundTC',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // 3. TextButton (Tertiary)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'ChironGoRoundTC',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

