import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/version_models.dart';
import '../client/suda_http_client.dart';

class VersionApi {
  static Future<VersionDto> getLatestVersion() async {
    final uri = SudaHttpClient.buildUri('/v1/latest-version');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return VersionDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/latest-version failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
