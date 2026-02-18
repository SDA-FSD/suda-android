import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/user_models.dart';
import '../client/suda_http_client.dart';

class UserApi {
  static Future<UserDto> getCurrentUser({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getCurrentUserInternal(accessToken),
      retryWithNewToken: (newToken) => _getCurrentUserInternal(newToken),
    );
  }

  static Future<UserDto> _getCurrentUserInternal(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v1/users');

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
      return UserDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/users failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<ProfileDto> getUserProfile({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserProfileInternal(accessToken),
      retryWithNewToken: (newToken) => _getUserProfileInternal(newToken),
    );
  }

  static Future<ProfileDto> _getUserProfileInternal(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v1/users/profile');

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
      return ProfileDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/users/profile failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> updateName({
    required String accessToken,
    required String name,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users', {'name': name});

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
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
      'PUT /v1/users failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> deleteUser({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .delete(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
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
      'DELETE /v1/users failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> updateAgreement({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/agreement');

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
      'POST /v1/users/agreement failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> updateLanguageLevel({
    required String accessToken,
    required String languageLevel,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/language-level', {
      'languageLevel': languageLevel,
    });

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .put(
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
      'PUT /v1/users/language-level failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<UserTicketDto> getUserTicket({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserTicketInternal(accessToken),
      retryWithNewToken: (newToken) => _getUserTicketInternal(newToken),
    );
  }

  static Future<UserTicketDto> _getUserTicketInternal(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v1/users/ticket');

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
      return UserTicketDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/users/ticket failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> updatePushAgreement({
    required String accessToken,
    required String agreementYn,
  }) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/push-agreement',
      {'agreementYn': agreementYn},
    );

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .put(
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
      return;
    }

    throw Exception(
      'PUT /v1/users/push-agreement failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<List<NotificationDto>> getNotifications({
    required String accessToken,
    required int page,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getNotificationsInternal(accessToken, page),
      retryWithNewToken: (newToken) => _getNotificationsInternal(newToken, page),
    );
  }

  static Future<List<NotificationDto>> _getNotificationsInternal(
    String accessToken,
    int page,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/notification',
      {'page': page.toString()},
    );

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
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => NotificationDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'GET /v1/users/notification failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
