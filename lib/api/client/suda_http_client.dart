import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/auth_models.dart';
import '../../services/token_storage.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class SudaHttpClient {
  static final http.Client _client = http.Client();
  static final _TokenRefreshManager _refreshManager = _TokenRefreshManager();

  static http.Client get client => _client;

  static Uri buildUri(String path, [Map<String, String>? queryParameters]) {
    final baseUrl = Uri.parse(AppConfig.apiBaseUrl);
    return Uri(
      scheme: baseUrl.scheme,
      host: baseUrl.host,
      port: baseUrl.port,
      path: path,
      queryParameters: queryParameters,
    );
  }

  static Future<T> executeWithRefresh<T>(
    Future<T> Function() apiCall, {
    Future<T> Function(String newAccessToken)? retryWithNewToken,
  }) async {
    try {
      return await apiCall();
    } on UnauthorizedException {
      try {
        final newAccessToken = await _refreshManager.refresh();
        if (retryWithNewToken != null) {
          return await retryWithNewToken(newAccessToken);
        }
        return await apiCall();
      } catch (_) {
        _refreshManager.clear();
        rethrow;
      }
    }
  }
}

class _TokenRefreshManager {
  Future<String>? _refreshFuture;

  Future<String> refresh() async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String> _doRefresh() async {
    final refreshToken = await TokenStorage.loadRefreshToken();
    if (refreshToken == null) {
      throw UnauthorizedException('No refresh token available');
    }

    final deviceId = await TokenStorage.getDeviceId();
    final tokens = await _requestRefreshTokens(
      refreshToken: refreshToken,
      deviceId: deviceId,
    );

    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    return tokens.accessToken;
  }

  Future<SudaAuthTokens> _requestRefreshTokens({
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

  void clear() {
    _refreshFuture = null;
  }
}
