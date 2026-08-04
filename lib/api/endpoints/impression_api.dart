import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../client/suda_http_client.dart';

class ImpressionApi {
  /// `POST /v1/impressions/products` — offerSessionId + productId product 탭 impression 수집.
  static Future<void> impressProduct({
    required String accessToken,
    required String offerSessionId,
    required String productId,
  }) async {
    await SudaHttpClient.executeWithRefresh(
      () => _impressProductInternal(
        accessToken: accessToken,
        offerSessionId: offerSessionId,
        productId: productId,
      ),
      retryWithNewToken: (newToken) => _impressProductInternal(
        accessToken: newToken,
        offerSessionId: offerSessionId,
        productId: productId,
      ),
    );
  }

  static Future<void> _impressProductInternal({
    required String accessToken,
    required String offerSessionId,
    required String productId,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/impressions/products');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'offerSessionId': offerSessionId,
              'productId': productId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    // 응답 바디는 필요 없으므로 2xx만 OK로 처리.
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'POST /v1/impressions/products failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}

