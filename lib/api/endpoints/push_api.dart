import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../client/suda_http_client.dart';

class PushApi {
  static Future<void> registerPushToken({
    required String accessToken,
    required String pushToken,
    required String languageCode,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/push-token');

    final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
    // TODO(temp-log): 푸시 등록 진단용 — 확인 후 제거
    print('[PUSH] POST /v1/users/push-token deviceType=$deviceType tokenLen=${pushToken.length}');
    try {
      final response = await SudaHttpClient.client
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
            }),
          )
          .timeout(const Duration(seconds: 10));
      print('[PUSH] POST response status=${response.statusCode}');
    } catch (e) {
      print('[PUSH] POST error: $e');
      // 무시
    }
  }
}
