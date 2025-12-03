import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// SUDA 인증 토큰 응답 모델
class SudaAuthTokens {
  final String accessToken;
  final String? refreshToken;

  const SudaAuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  factory SudaAuthTokens.fromJson(Map<String, dynamic> json) {
    return SudaAuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}

/// SudaJson 모델 (key-value 구조)
class SudaJson {
  final String key;
  final String value;

  const SudaJson({
    required this.key,
    required this.value,
  });

  factory SudaJson.fromJson(Map<String, dynamic> json) {
    return SudaJson(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }
}

/// /users/me 응답 User DTO
class SudaUser {
  final int id;
  final String provider;
  final String sub;
  final String name;
  final String email;
  final String? profileImgUrl;
  final int roleplayCount;
  final int wordsSpokenCount;
  final int likePoint;
  final String firstLoginYn;
  final List<SudaJson>? metaInfo;

  const SudaUser({
    required this.id,
    required this.provider,
    required this.sub,
    required this.name,
    required this.email,
    this.profileImgUrl,
    required this.roleplayCount,
    required this.wordsSpokenCount,
    required this.likePoint,
    required this.firstLoginYn,
    this.metaInfo,
  });

  factory SudaUser.fromJson(Map<String, dynamic> json) {
    return SudaUser(
      id: json['id'] as int,
      provider: json['provider'] as String,
      sub: json['sub'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImgUrl: json['profileImgUrl'] as String?,
      roleplayCount: json['roleplayCount'] as int,
      wordsSpokenCount: json['wordsSpokenCount'] as int,
      likePoint: json['likePoint'] as int,
      firstLoginYn: json['firstLoginYn'] as String,
      metaInfo: json['metaInfo'] == null
          ? null
          : (json['metaInfo'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// SUDA API 클라이언트
class SudaApiClient {
  static final http.Client _client = http.Client();

  static Uri _buildUri(String path) {
    // base URL은 AppConfig.apiBaseUrl에서 관리
    return Uri.parse('${AppConfig.apiBaseUrl}$path');
  }

  /// Google ID Token으로 SUDA 서버에 로그인 요청
  ///
  /// POST /api/app/v1/auth/google
  /// Body: { "idToken": "<google_id_token>" }
  static Future<SudaAuthTokens> loginWithGoogle({
    required String idToken,
  }) async {
    final uri = _buildUri('/api/app/v1/auth/google');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print('Timeout calling /api/app/v1/auth/google: $e');
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SudaAuthTokens.fromJson(data);
    }

    throw Exception(
      'SUDA Google auth failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 현재 로그인된 사용자 정보 조회
  ///
  /// GET /users/me
  /// Header: Authorization: Bearer <accessToken>
  static Future<SudaUser> getCurrentUser({
    required String accessToken,
  }) async {
    final uri = _buildUri('/users/me');

    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print('Timeout calling /users/me: $e');
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SudaUser.fromJson(data);
    }

    // 디버깅을 위해 실패 응답을 터미널에 출력
    // ignore: avoid_print
    print(
      'GET /users/me failed '
      '(status: ${response.statusCode}, body: ${response.body})',
    );

    throw Exception(
      'GET /users/me failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}

