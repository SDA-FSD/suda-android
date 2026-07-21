import 'dart:async';
import 'dart:convert';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/auth_models.dart';
import '../../services/perf_monitoring_service.dart';
import '../../services/token_storage.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class SudaHttpClient {
  /// `package:http`는 네이티브 FPM 자동수집 대상이 아니므로 [HttpMetric] 래퍼 사용.
  /// 수집 OFF(local/stg)일 때는 래퍼가 바로 통과한다.
  static final http.Client _client = _PerfMetricHttpClient(http.Client());
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

/// Firebase Performance Network 탭용. [PerfMonitoringService.isCollectionEnabled]일 때만 계측.
class _PerfMetricHttpClient extends http.BaseClient {
  _PerfMetricHttpClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!PerfMonitoringService.isCollectionEnabled) {
      return _inner.send(request);
    }

    final metricUrl = request.url.replace(query: '', fragment: '').toString();
    final metric = FirebasePerformance.instance.newHttpMetric(
      metricUrl,
      _httpMethodOf(request.method),
    );
    metric.putAttribute('env', AppConfig.env);
    final contentLength = request.contentLength;
    if (contentLength != null && contentLength >= 0) {
      metric.requestPayloadSize = contentLength;
    }

    try {
      await metric.start();
    } catch (e, st) {
      debugPrint('[DEBUG] HttpMetric start failed: $e\n$st');
      return _inner.send(request);
    }

    try {
      final response = await _inner.send(request);
      metric.httpResponseCode = response.statusCode;
      final responseLength = response.contentLength;
      if (responseLength != null && responseLength >= 0) {
        metric.responsePayloadSize = responseLength;
      }
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.isNotEmpty) {
        metric.responseContentType = contentType;
      }
      return response;
    } finally {
      try {
        await metric.stop();
      } catch (e, st) {
        debugPrint('[DEBUG] HttpMetric stop failed: $e\n$st');
      }
    }
  }

  static HttpMethod _httpMethodOf(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      case 'TRACE':
        return HttpMethod.Trace;
      case 'CONNECT':
        return HttpMethod.Connect;
      default:
        return HttpMethod.Get;
    }
  }

  @override
  void close() => _inner.close();
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
