import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../client/suda_http_client.dart';

class PushApi {
  static Future<void> registerPushToken({
    required String accessToken,
    required String pushToken,
    required String languageCode,
    required String languageTag,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/push-token');

    final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
    try {
      await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'deviceType': deviceType,
              'pushToken': pushToken,
              'languageCode': languageCode,
              'languageTag': languageTag,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // 무시
    }
  }
}
