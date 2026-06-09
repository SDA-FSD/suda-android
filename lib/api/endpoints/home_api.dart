import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/home_models.dart';
import '../../models/pagination.dart';
import '../client/suda_http_client.dart';

class HomeApi {
  static Future<HomeDto> getHomeContents({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getHomeContentsInternal(accessToken),
      retryWithNewToken: (newToken) => _getHomeContentsInternal(newToken),
    );
  }

  static Future<HomeDto> _getHomeContentsInternal(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v2/home/contents');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
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
      return HomeDto.fromJson(data);
    }

    throw Exception(
      'GET /v2/home/contents failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<SudaAppPage<HomeSeriesDto>> getSeriesByCategory({
    required String accessToken,
    required String categoryEnumValue,
    required int pageNum,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSeriesByCategoryInternal(
        accessToken,
        categoryEnumValue,
        pageNum,
      ),
      retryWithNewToken: (newToken) => _getSeriesByCategoryInternal(
        newToken,
        categoryEnumValue,
        pageNum,
      ),
    );
  }

  static Future<SudaAppPage<HomeSeriesDto>> _getSeriesByCategoryInternal(
    String accessToken,
    String categoryEnumValue,
    int pageNum,
  ) async {
    final uri = SudaHttpClient.buildUri('/v2/home/series', {
      'category': categoryEnumValue,
      'pageNum': pageNum.toString(),
    });

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
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
      return SudaAppPage<HomeSeriesDto>.fromJson(
        data,
        (json) => HomeSeriesDto.fromJson(json),
      );
    }

    throw Exception(
      'GET /v2/home/series failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
