import 'package:shared_preferences/shared_preferences.dart';

/// SUDA JWT 토큰 저장/로드 유틸
class TokenStorage {
  static const _keyAccessToken = 'suda_access_token';
  static const _keyRefreshToken = 'suda_refresh_token';
  static const _keyLanguageCode = 'suda_language_code';
  static const _keyLatestVersion = 'suda_latest_version';

  /// Access / Refresh 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    } else {
      await prefs.remove(_keyRefreshToken);
    }
  }

  /// 저장된 Access Token 가져오기
  static Future<String?> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// 저장된 Refresh Token 가져오기
  static Future<String?> loadRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// 언어 코드 저장
  /// 
  /// 앱 실행 시 또는 언어 변경 시 호출하여 사용자 언어 코드를 보존 데이터 영역에 저장
  static Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguageCode, languageCode);
  }

  /// 저장된 언어 코드 가져오기
  /// 
  /// 서버 API 호출 시 필요한 경우 사용
  /// 반환값: ISO 639-1 두 글자 언어 코드 (예: 'ko', 'en', 'pt')
  /// 저장된 값이 없으면 null 반환
  static Future<String?> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguageCode);
  }

  /// 최신 버전 정보 저장
  /// 
  /// 버전 체크 API 호출 시 최신 버전 정보를 영구 저장 영역에 저장
  static Future<void> saveLatestVersion(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLatestVersion, latestVersion);
  }

  /// 저장된 최신 버전 정보 가져오기
  /// 
  /// 앱 버전 노출 페이지 등에서 사용
  /// 저장된 값이 없으면 null 반환
  static Future<String?> loadLatestVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLatestVersion);
  }

  /// 모든 토큰 및 언어 코드 삭제 (로그아웃 시 사용)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyLanguageCode);
  }
}


