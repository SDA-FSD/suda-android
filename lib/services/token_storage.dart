import 'package:shared_preferences/shared_preferences.dart';

/// SUDA JWT 토큰 저장/로드 유틸
class TokenStorage {
  static const _keyAccessToken = 'suda_access_token';
  static const _keyRefreshToken = 'suda_refresh_token';

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

  /// 모든 토큰 삭제 (로그아웃 시 사용)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }
}


