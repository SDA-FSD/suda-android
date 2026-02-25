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
    final uri = SudaHttpClient.buildUri('/v1/home/contents');
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
      'GET /v1/home/contents failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<SudaAppPage<AppHomeRoleplayDto>> getRoleplaysByCategory({
    required String accessToken,
    required int categoryId,
    required int pageNum,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getRoleplaysByCategoryInternal(accessToken, categoryId, pageNum),
      retryWithNewToken: (newToken) =>
          _getRoleplaysByCategoryInternal(newToken, categoryId, pageNum),
    );
  }

  static Future<SudaAppPage<AppHomeRoleplayDto>> _getRoleplaysByCategoryInternal(
    String accessToken,
    int categoryId,
    int pageNum,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/home/roleplays/categories/$categoryId', {
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
      return SudaAppPage<AppHomeRoleplayDto>.fromJson(
        data,
        (json) => AppHomeRoleplayDto.fromJson(json),
      );
    }

    throw Exception(
      'GET /v1/home/roleplays/categories failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
