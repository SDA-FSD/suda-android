import 'dart:async';

import 'package:http/http.dart' as http;

import '../client/suda_http_client.dart';

class RoleplayApi {
  static Future<void> updateSpeedRate({
    required String accessToken,
    required String speedRate,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _updateSpeedRateInternal(accessToken, speedRate),
      retryWithNewToken: (newToken) =>
          _updateSpeedRateInternal(newToken, speedRate),
    );
  }

  static Future<void> _updateSpeedRateInternal(
    String accessToken,
    String speedRate,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/users/speed-rate', {
      'speedRate': speedRate,
    });
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .put(uri, headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 10));
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
      'PUT /v1/users/speed-rate failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
