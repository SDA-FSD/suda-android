import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/auth_models.dart';
import '../client/suda_http_client.dart';

class AuthApi {
  static Future<SudaAuthTokens> loginWithGoogle({
    required String idToken,
    required String deviceId,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/auth/google');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'idToken': idToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
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

  static Future<SudaAuthTokens> refreshToken({
    required String refreshToken,
    required String deviceId,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/auth/refresh');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SudaAuthTokens.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Refresh token expired or invalid');
    }

    throw Exception(
      'POST /v1/auth/refresh failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> logout({
    required String refreshToken,
    required String deviceId,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/auth/logout');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'POST /v1/auth/logout failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
