import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/series_models.dart';
import '../client/suda_http_client.dart';

class SeriesApi {
  static Future<RpS2SeriesOverviewDto> getSeriesOverview({
    required String accessToken,
    required int seriesId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSeriesOverviewInternal(accessToken, seriesId),
      retryWithNewToken: (newToken) =>
          _getSeriesOverviewInternal(newToken, seriesId),
    );
  }

  static Future<RpS2SeriesOverviewDto> _getSeriesOverviewInternal(
    String accessToken,
    int seriesId,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/series/$seriesId/overview');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2SeriesOverviewDto.fromJson(data);
    }

    throw Exception(
      'GET /rps2/series/$seriesId/overview failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<Map<int, int>> getSeriesBestScore({
    required String accessToken,
    required int seriesId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSeriesBestScoreInternal(accessToken, seriesId),
      retryWithNewToken: (newToken) =>
          _getSeriesBestScoreInternal(newToken, seriesId),
    );
  }

  static Future<Map<int, int>> _getSeriesBestScoreInternal(
    String accessToken,
    int seriesId,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/series/$seriesId/best-score');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic data = jsonDecode(response.body);
      return bestScoreMapFromJson(data);
    }

    throw Exception(
      'GET /rps2/series/$seriesId/best-score failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
