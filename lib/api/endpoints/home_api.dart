import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/home_models.dart';
import '../../models/pagination.dart';
import '../client/suda_http_client.dart';

class HomeApi {
  static Future<List<MainHomeBannerDto>> getHomeBanners({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getHomeBannersInternal(accessToken),
      retryWithNewToken: (newToken) => _getHomeBannersInternal(newToken),
    );
  }

  static Future<List<MainHomeBannerDto>> _getHomeBannersInternal(
    String accessToken,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/home/banners');
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
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => MainHomeBannerDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'GET /v1/home/banners failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<List<AppHomeRoleplayGroupDto>> getHomeRoleplayGroups({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getHomeRoleplayGroupsInternal(accessToken),
      retryWithNewToken: (newToken) => _getHomeRoleplayGroupsInternal(newToken),
    );
  }

  static Future<List<AppHomeRoleplayGroupDto>> _getHomeRoleplayGroupsInternal(
    String accessToken,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/home/roleplays/all');
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
      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) {
        throw Exception('GET /v1/home/roleplays/all unexpected body');
      }
      final List<dynamic> data = decoded as List<dynamic>;
      return data
          .map((item) => AppHomeRoleplayGroupDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'GET /v1/home/roleplays/all failed: HTTP ${response.statusCode} ${response.body}',
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
