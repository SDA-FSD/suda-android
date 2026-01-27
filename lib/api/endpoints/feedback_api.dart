import 'dart:async';

import 'package:http/http.dart' as http;

import '../client/suda_http_client.dart';

class FeedbackApi {
  static Future<void> sendFeedback({
    required String accessToken,
    required String content,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/feedback', {'content': content});

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'POST /v1/users/feedback failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
