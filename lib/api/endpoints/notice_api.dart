import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/pagination.dart';
import '../../models/user_models.dart';
import '../client/suda_http_client.dart';

class NoticeApi {
  /// GET /v1/notice?page=0&size=10 (0-based)
  static Future<SudaAppPage<AppNoticeDto>> getNotices({
    required String accessToken,
    required int page,
    int size = 10,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getNoticesInternal(accessToken, page, size),
      retryWithNewToken: (newToken) =>
          _getNoticesInternal(newToken, page, size),
    );
  }

  static Future<SudaAppPage<AppNoticeDto>> _getNoticesInternal(
    String accessToken,
    int page,
    int size,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/notice', {
      'page': page.toString(),
      'size': size.toString(),
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
      return SudaAppPage<AppNoticeDto>.fromJson(
        data,
        (item) => AppNoticeDto.fromJson(item as Map<String, dynamic>),
      );
    }

    throw Exception(
      'GET /v1/notice failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// GET /v1/notice/{noticeId}. Returns null on 404.
  static Future<AppNoticeDto?> getNotice({
    required String accessToken,
    required int noticeId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getNoticeInternal(accessToken, noticeId),
      retryWithNewToken: (newToken) =>
          _getNoticeInternal(newToken, noticeId),
    );
  }

  static Future<AppNoticeDto?> _getNoticeInternal(
    String accessToken,
    int noticeId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/notice/$noticeId');

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

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return AppNoticeDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/notice/$noticeId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
