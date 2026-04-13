import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/roleplay_models.dart';
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

  static Future<void> deleteProfileImage({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/profile-img');

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
      'DELETE /v1/users/profile-img failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> completeTutorial({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/tutorial');

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
      'POST /v1/users/tutorial failed: HTTP ${response.statusCode} ${response.body}',
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

  static Future<QuestResultDto> claimDailyTicket({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _claimDailyTicketInternal(accessToken),
      retryWithNewToken: (newToken) => _claimDailyTicketInternal(newToken),
    );
  }

  static Future<QuestResultDto> _claimDailyTicketInternal(
      String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v1/users/tickets/daily');

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
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return QuestResultDto.fromJson(data);
    }

    throw Exception(
      'PUT /v1/users/tickets/daily failed: HTTP ${response.statusCode} ${response.body}',
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

  static Future<QuestResultDto> updatePushAgreement({
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
      return _parseQuestResultResponse(response.body);
    }

    throw Exception(
      'PUT /v1/users/push-agreement failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<QuestResultDto> postUserQuest({
    required String accessToken,
    required String questId,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/quests/$questId');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
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
      return _parseQuestResultResponse(response.body);
    }

    throw Exception(
      'POST /v1/users/quests/$questId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static QuestResultDto _parseQuestResultResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return QuestResultDto.fromJson(decoded);
      }
      if (decoded is String) {
        return QuestResultDto(completeYn: decoded);
      }
    } catch (_) {
      // Fall back to plain text response.
    }
    return QuestResultDto(completeYn: body);
  }

  static Future<String> submitSurvey({
    required String accessToken,
    required int age,
    required int gender,
    required int source,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _submitSurveyInternal(
        accessToken: accessToken,
        age: age,
        gender: gender,
        source: source,
      ),
      retryWithNewToken: (newToken) => _submitSurveyInternal(
        accessToken: newToken,
        age: age,
        gender: gender,
        source: source,
      ),
    );
  }

  static Future<String> _submitSurveyInternal({
    required String accessToken,
    required int age,
    required int gender,
    required int source,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/survey');

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
              'age': age.toString(),
              'gender': gender.toString(),
              'source': source.toString(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseStringResponse(response.body);
    }

    throw Exception(
      'POST /v1/users/survey failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<QuestResultDto> markNotificationRead({
    required String accessToken,
    required int notificationId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _markNotificationReadInternal(accessToken, notificationId),
      retryWithNewToken: (newToken) =>
          _markNotificationReadInternal(newToken, notificationId),
    );
  }

  static Future<QuestResultDto> _markNotificationReadInternal(
    String accessToken,
    int notificationId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/notification/$notificationId/read',
    );

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
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
      return QuestResultDto.fromJson(data);
    }

    throw Exception(
      'POST /v1/users/notification/$notificationId/read failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// [pageNum]은 0부터 시작(첫 페이지 = 0).
  static Future<List<NotificationDto>> getNotifications({
    required String accessToken,
    required int pageNum,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getNotificationsInternal(accessToken, pageNum),
      retryWithNewToken: (newToken) =>
          _getNotificationsInternal(newToken, pageNum),
    );
  }

  static Future<List<NotificationDto>> _getNotificationsInternal(
    String accessToken,
    int pageNum,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/notification',
      {'pageNum': pageNum.toString()},
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

  /// `POST /v1/users/expressions` — body: `{ roleplayResultId, expressionIndex }`.
  static Future<void> saveUserExpression({
    required String accessToken,
    required int roleplayResultId,
    required int expressionIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _saveUserExpressionInternal(
        accessToken,
        roleplayResultId,
        expressionIndex,
      ),
      retryWithNewToken: (newToken) => _saveUserExpressionInternal(
        newToken,
        roleplayResultId,
        expressionIndex,
      ),
    );
  }

  static Future<void> _saveUserExpressionInternal(
    String accessToken,
    int roleplayResultId,
    int expressionIndex,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/users/expressions');

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
              'roleplayResultId': roleplayResultId,
              'expressionIndex': expressionIndex,
            }),
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
      'POST /v1/users/expressions failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// `DELETE /v1/users/expressions?rpResultId=...&expressionIndex=...`
  static Future<void> deleteUserExpression({
    required String accessToken,
    required int rpResultId,
    required int expressionIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _deleteUserExpressionInternal(accessToken, rpResultId, expressionIndex),
      retryWithNewToken: (newToken) =>
          _deleteUserExpressionInternal(newToken, rpResultId, expressionIndex),
    );
  }

  static Future<void> _deleteUserExpressionInternal(
    String accessToken,
    int rpResultId,
    int expressionIndex,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/expressions',
      {
        'rpResultId': rpResultId.toString(),
        'expressionIndex': expressionIndex.toString(),
      },
    );

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

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'DELETE /v1/users/expressions failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// `GET /v1/users/expressions?pageNum=...` — 응답: `List<UserExpressionDto>`
  static Future<List<UserExpressionDto>> getUserExpressions({
    required String accessToken,
    int pageNum = 0,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserExpressionsInternal(accessToken, pageNum),
      retryWithNewToken: (newToken) => _getUserExpressionsInternal(newToken, pageNum),
    );
  }

  static Future<List<UserExpressionDto>> _getUserExpressionsInternal(
    String accessToken,
    int pageNum,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/expressions',
      {'pageNum': pageNum.toString()},
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
          .map((item) => UserExpressionDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'GET /v1/users/expressions failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static String _parseStringResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // Fall back to plain text
    }
    return body;
  }
}
