import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../client/suda_http_client.dart';

class PurchaseApi {
  /// `POST /v1/purchases/verify` — Play 구매 TEMP 검증(INAPP/SUBS 동일 body).
  /// 200이어도 지급 성공이 아님(서버 분기·로그/지급은 서버 책임).
  static Future<void> verifyPurchase({
    required String accessToken,
    required String purchaseToken,
    required String productId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _verifyPurchaseInternal(
        accessToken,
        purchaseToken,
        productId,
      ),
      retryWithNewToken: (newToken) => _verifyPurchaseInternal(
        newToken,
        purchaseToken,
        productId,
      ),
    );
  }

  static Future<void> _verifyPurchaseInternal(
    String accessToken,
    String purchaseToken,
    String productId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/purchases/verify');

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
              'purchaseToken': purchaseToken,
              'productId': productId,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'POST /v1/purchases/verify failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
