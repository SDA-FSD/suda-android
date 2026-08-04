import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/user_models.dart';
import '../client/suda_http_client.dart';

class PurchaseApi {
  /// `POST /v1/purchases/verify` — Play 구매 검증.
  /// 응답의 `successYn`/`pendingYn`으로 지급·승인대기 여부를 판단한다.
  static Future<PurchaseVerifyResultDto> verifyPurchase({
    required String accessToken,
    required String purchaseToken,
    required String productId,
    String? offerSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _verifyPurchaseInternal(
        accessToken,
        purchaseToken,
        productId,
        offerSessionId,
      ),
      retryWithNewToken: (newToken) => _verifyPurchaseInternal(
        newToken,
        purchaseToken,
        productId,
        offerSessionId,
      ),
    );
  }

  static Future<PurchaseVerifyResultDto> _verifyPurchaseInternal(
    String accessToken,
    String purchaseToken,
    String productId,
    String? offerSessionId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/purchases/verify');

    final body = <String, dynamic>{
      'purchaseToken': purchaseToken,
      'productId': productId,
    };
    final sessionId = offerSessionId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      body['offerSessionId'] = sessionId;
    }

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return const PurchaseVerifyResultDto(successYn: 'N', pendingYn: 'N');
      }
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return PurchaseVerifyResultDto.fromJson(data);
    }

    throw Exception(
      'POST /v1/purchases/verify failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
