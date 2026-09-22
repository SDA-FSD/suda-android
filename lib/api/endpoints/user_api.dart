import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/character_reward_models.dart';
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

  static Future<MyProfileDto> getMyProfile({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getMyProfileInternal(accessToken),
      retryWithNewToken: (newToken) => _getMyProfileInternal(newToken),
    );
  }

  static Future<MyProfileDto> _getMyProfileInternal(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v1/users/my-profile');

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
      return MyProfileDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/users/my-profile failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<UserProgressDto> getProgress({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getProgressInternal(accessToken),
      retryWithNewToken: (newToken) => _getProgressInternal(newToken),
    );
  }

  static Future<UserProgressDto> _getProgressInternal(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/v1/users/progress');

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
      return UserProgressDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/users/progress failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<List<CharacterRewardClaimDto>> claimCharacterRewards({
    required String accessToken,
    required List<int> userCharacterRewardIds,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _claimCharacterRewardsInternal(accessToken, userCharacterRewardIds),
      retryWithNewToken: (newToken) =>
          _claimCharacterRewardsInternal(newToken, userCharacterRewardIds),
    );
  }

  static Future<List<CharacterRewardClaimDto>> _claimCharacterRewardsInternal(
    String accessToken,
    List<int> userCharacterRewardIds,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/users/character-rewards/claim');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(userCharacterRewardIds),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'POST /v1/users/character-rewards/claim failed: HTTP ${response.statusCode} ${response.body}',
      );
    }

    final raw = response.body.trim();
    if (raw.isEmpty || raw == 'null') {
      return const [];
    }
    final data = jsonDecode(raw);
    if (data is! List) {
      throw Exception(
        'POST /v1/users/character-rewards/claim unexpected body: ${response.body}',
      );
    }
    return [
      for (final e in data)
        if (e is Map)
          CharacterRewardClaimDto.fromJson(Map<String, dynamic>.from(e)),
    ];
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

  static Future<void> updateProfileImage({
    required String accessToken,
    required String type,
    required String value,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/profile-img');

    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'type': type,
              'value': value,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'PUT /v1/users/profile-img failed: HTTP ${response.statusCode} ${response.body}',
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

  /// POST /v1/users/tutorial-shown (best-effort; 200 only)
  static Future<void> tutorialShown({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/tutorial-shown');

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
      return;
    }

    throw Exception(
      'POST /v1/users/tutorial-shown failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// POST /v1/users/first-overview (best-effort; 200 only)
  static Future<void> postFirstOverview({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/first-overview');

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
      return;
    }

    throw Exception(
      'POST /v1/users/first-overview failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// PUT /v1/users/grant-welcome-gift
  static Future<void> grantWelcomeGift({
    required String accessToken,
  }) async {
    final uri = SudaHttpClient.buildUri('/v1/users/grant-welcome-gift');

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

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'PUT /v1/users/grant-welcome-gift failed: HTTP ${response.statusCode} ${response.body}',
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

  static final Map<String, Future<UserEnergyDto>> _inflightEnergyDetail = {};
  static Future<UserEnergyDto>? _inflightEnergySimple;

  /// `GET /v1/users/energy/detail` — 상품 노출 플래그 포함. 에너지 팝업 전용.
  ///
  /// - `screen` 쿼리 파라미터는 통계 수집 contract 용도입니다. 클라이언트에서 임의 수정/확장 금지.
  static Future<UserEnergyDto> getUserEnergy({
    required String accessToken,
    String? screen,
  }) async {
    final key = screen ?? '';
    final existing = _inflightEnergyDetail[key];
    if (existing != null) return existing;

    final queryParameters =
        screen == null ? null : <String, String>{'screen': screen};

    final future = SudaHttpClient.executeWithRefresh(
      () => _getUserEnergyAt(
        '/v1/users/energy/detail',
        accessToken,
        queryParameters: queryParameters,
      ),
      retryWithNewToken: (newToken) => _getUserEnergyAt(
        '/v1/users/energy/detail',
        newToken,
        queryParameters: queryParameters,
      ),
    );
    _inflightEnergyDetail[key] = future;
    try {
      return await future;
    } finally {
      if (_inflightEnergyDetail[key] == future) {
        _inflightEnergyDetail.remove(key);
      }
    }
  }

  /// `GET /v1/users/energy/simple` — 잔량·구독 등 레이블/상태용(상품 플래그 없음).
  static Future<UserEnergyDto> getUserEnergySimple({
    required String accessToken,
  }) async {
    final existing = _inflightEnergySimple;
    if (existing != null) return existing;

    final future = SudaHttpClient.executeWithRefresh(
      () => _getUserEnergyAt('/v1/users/energy/simple', accessToken),
      retryWithNewToken: (newToken) =>
          _getUserEnergyAt('/v1/users/energy/simple', newToken),
    );
    _inflightEnergySimple = future;
    try {
      return await future;
    } finally {
      if (identical(_inflightEnergySimple, future)) {
        _inflightEnergySimple = null;
      }
    }
  }

  static Future<UserEnergyDto> _getUserEnergyAt(
    String path,
    String accessToken, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = SudaHttpClient.buildUri(path, queryParameters);

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
      return UserEnergyDto.fromJson(data);
    }

    throw Exception(
      'GET $path failed: HTTP ${response.statusCode} ${response.body}',
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

  static Future<OtherUserProfileDto> getOtherUserProfile({
    required String accessToken,
    required int userId,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _getOtherUserProfileInternal(accessToken, userId),
      retryWithNewToken: (newToken) =>
          _getOtherUserProfileInternal(newToken, userId),
    );
  }

  static Future<OtherUserProfileDto> _getOtherUserProfileInternal(
    String accessToken,
    int userId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/users/$userId/profile');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
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
      return OtherUserProfileDto.fromJson(data);
    }
    throw Exception(
      'GET /v1/users/$userId/profile failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<FriendRelationDto> requestFriend({
    required String accessToken,
    required int targetUserId,
  }) {
    return _friendWrite(
      accessToken: accessToken,
      method: 'POST',
      path: '/v1/users/friends/$targetUserId',
    );
  }

  static Future<FriendRelationDto> cancelFriendRequest({
    required String accessToken,
    required int targetUserId,
  }) {
    return _friendWrite(
      accessToken: accessToken,
      method: 'DELETE',
      path: '/v1/users/friends/$targetUserId/request',
    );
  }

  static Future<FriendRelationDto> unfriend({
    required String accessToken,
    required int targetUserId,
  }) {
    return _friendWrite(
      accessToken: accessToken,
      method: 'DELETE',
      path: '/v1/users/friends/$targetUserId',
    );
  }

  static Future<FriendRelationDto> _friendWrite({
    required String accessToken,
    required String method,
    required String path,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _friendWriteInternal(accessToken, method, path),
      retryWithNewToken: (newToken) =>
          _friendWriteInternal(newToken, method, path),
    );
  }

  static Future<FriendRelationDto> _friendWriteInternal(
    String accessToken,
    String method,
    String path,
  ) async {
    final uri = SudaHttpClient.buildUri(path);
    late final http.Response response;
    try {
      final headers = {'Authorization': 'Bearer $accessToken'};
      if (method == 'POST') {
        response = await SudaHttpClient.client
            .post(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      } else {
        response = await SudaHttpClient.client
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
      }
    } on TimeoutException {
      rethrow;
    }
    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode == 409) {
      throw _parseFriendError(response);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return FriendRelationDto.fromJson(data);
    }
    throw FriendApiException(statusCode: response.statusCode);
  }

  static FriendApiException _parseFriendError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return FriendApiException(
          statusCode: response.statusCode,
          code: decoded['code'] as String?,
          limit: (decoded['limit'] as num?)?.toInt(),
          limitUserId: (decoded['limitUserId'] as num?)?.toInt(),
        );
      }
    } catch (_) {}
    return FriendApiException(statusCode: response.statusCode);
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
