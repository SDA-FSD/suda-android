import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// SUDA JWT 토큰 저장/로드 유틸
class TokenStorage {
  static const _keyAccessToken = 'suda_access_token';
  static const _keyRefreshToken = 'suda_refresh_token';
  static const _keyAccessTokenSavedAt = 'suda_access_token_saved_at';
  static const _keyDeviceId = 'suda_device_id';
  static const _keyLanguageCode = 'suda_language_code';
  static const _keyLatestVersion = 'suda_latest_version';
  static const _secureStorage = FlutterSecureStorage();
  static const _uuid = Uuid();

  /// Device ID 가져오기 (없으면 생성)
  static Future<String> getDeviceId() async {
    final existing = await _secureStorage.read(key: _keyDeviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newDeviceId = _uuid.v4();
    await _secureStorage.write(key: _keyDeviceId, value: newDeviceId);
    return newDeviceId;
  }

  /// Access / Refresh 토큰 저장
  /// 
  /// 저장 시점을 기록하여 만료 시간 계산에 사용
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    // 저장 시점 기록 (밀리초 단위 타임스탬프)
    final savedAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: _keyAccessTokenSavedAt, value: savedAt);
    if (refreshToken != null) {
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    } else {
      await _secureStorage.delete(key: _keyRefreshToken);
    }
  }

  /// Access Token 만료 임박 여부 확인
  /// 
  /// 만료 5분 전인지 확인 (30분 만료 기준)
  /// 반환값: true면 만료 임박 (1-3분 전), false면 아직 여유 있음
  static Future<bool> isAccessTokenExpiringSoon() async {
    final savedAtStr = await _secureStorage.read(key: _keyAccessTokenSavedAt);
    if (savedAtStr == null) return true; // 저장 시점이 없으면 만료로 간주
    
    final savedAt = DateTime.fromMillisecondsSinceEpoch(int.parse(savedAtStr));
    final now = DateTime.now();
    final elapsed = now.difference(savedAt);
    
    // 30분 만료 기준: 25분 이상 경과 시 만료 임박
    const expiryDuration = Duration(minutes: 30);
    const warningThreshold = Duration(minutes: 25);
    
    return elapsed >= warningThreshold && elapsed < expiryDuration;
  }

  /// Access Token 만료 여부 확인
  /// 
  /// 30분 경과 여부 확인
  static Future<bool> isAccessTokenExpired() async {
    final savedAtStr = await _secureStorage.read(key: _keyAccessTokenSavedAt);
    if (savedAtStr == null) return true;
    
    final savedAt = DateTime.fromMillisecondsSinceEpoch(int.parse(savedAtStr));
    final now = DateTime.now();
    final elapsed = now.difference(savedAt);
    
    const expiryDuration = Duration(minutes: 30);
    return elapsed >= expiryDuration;
  }

  /// 저장된 Access Token 가져오기
  static Future<String?> loadAccessToken() async {
    return _secureStorage.read(key: _keyAccessToken);
  }

  /// 저장된 Refresh Token 가져오기
  static Future<String?> loadRefreshToken() async {
    return _secureStorage.read(key: _keyRefreshToken);
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
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyAccessTokenSavedAt);
    await prefs.remove(_keyLanguageCode);
  }
}


