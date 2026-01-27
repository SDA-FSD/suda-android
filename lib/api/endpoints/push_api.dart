import 'dart:async';
import 'dart:convert';

import '../client/suda_http_client.dart';

class PushApi {
  static Future<void> registerPushToken({
    required String accessToken,
    required String pushToken,
    required String languageCode,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/push-token');

    try {
      await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'deviceType': 'ANDROID',
              'pushToken': pushToken,
              'languageCode': languageCode,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // 무시
    }
  }
}
