import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/pagination.dart';
import '../../models/roleplay_models.dart';
import '../client/suda_http_client.dart';

class RoleplayApi {
  static Future<RoleplayOverviewDto> getRoleplayOverview({
    required String accessToken,
    required int roleplayId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getRoleplayOverviewInternal(accessToken, roleplayId),
      retryWithNewToken: (newToken) =>
          _getRoleplayOverviewInternal(newToken, roleplayId),
    );
  }

  static Future<RoleplaySessionDto> createRoleplaySession({
    required String accessToken,
    required int roleplayId,
    required int roleId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _createRoleplaySessionInternal(accessToken, roleplayId, roleId),
      retryWithNewToken: (newToken) =>
          _createRoleplaySessionInternal(newToken, roleplayId, roleId),
    );
  }

  static Future<RoleplayUserMessageResponseDto> sendUserMessageText({
    required String accessToken,
    required String rpSessionId,
    required String text,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _sendUserMessageTextInternal(accessToken, rpSessionId, text),
      retryWithNewToken: (newToken) =>
          _sendUserMessageTextInternal(newToken, rpSessionId, text),
    );
  }

  static Future<RoleplayUserMessageResponseDto> sendUserMessageAudio({
    required String accessToken,
    required String rpSessionId,
    required Uint8List audioData,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _sendUserMessageAudioInternal(accessToken, rpSessionId, audioData),
      retryWithNewToken: (newToken) =>
          _sendUserMessageAudioInternal(newToken, rpSessionId, audioData),
    );
  }

  static Future<RoleplayAiMessageDto> getAiMessage({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getAiMessageInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _getAiMessageInternal(newToken, rpSessionId),
    );
  }

  static Future<RoleplayNarrationDto> getNarration({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getNarrationInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _getNarrationInternal(newToken, rpSessionId),
    );
  }

  static Future<String> getHint({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getHintInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _getHintInternal(newToken, rpSessionId),
    );
  }

  /// `GET /v1/roleplay-sessions/{rpSessionId}/hint/sound` — 전체 문장 발음 JSON (`cdnYn`, `cdnPath`, `sound`).
  /// 텍스트는 [getHint] (`.../hint`)와 별도 경로.
  static Future<RoleplayAiMessageDto> getHintAudio({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getHintAudioInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _getHintAudioInternal(newToken, rpSessionId),
    );
  }

  /// `GET /v1/roleplay-sessions/{rpSessionId}/hint/sound/{wordIndex}` — 단어별 발음.
  static Future<RoleplayAiMessageDto> getHintWordAudio({
    required String accessToken,
    required String rpSessionId,
    required int wordIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getHintWordAudioInternal(accessToken, rpSessionId, wordIndex),
      retryWithNewToken: (newToken) =>
          _getHintWordAudioInternal(newToken, rpSessionId, wordIndex),
    );
  }

  static Future<String> getTranslation({
    required String accessToken,
    required String rpSessionId,
    required int index,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getTranslationInternal(accessToken, rpSessionId, index),
      retryWithNewToken: (newToken) =>
          _getTranslationInternal(newToken, rpSessionId, index),
    );
  }

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

  /// GET /v1/roleplays/results?pageNum=0 (0-based, 9 items per page)
  static Future<SudaAppPage<RpSimpleResultDto>> getResults({
    required String accessToken,
    required int pageNum,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getResultsInternal(accessToken, pageNum),
      retryWithNewToken: (newToken) =>
          _getResultsInternal(newToken, pageNum),
    );
  }

  static Future<RoleplayResultDto> getRoleplayResult({
    required String accessToken,
    required int resultId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getRoleplayResultInternal(accessToken, resultId),
      retryWithNewToken: (newToken) =>
          _getRoleplayResultInternal(newToken, resultId),
    );
  }

  /// GET /v1/roleplays/results-reload/{resultId}
  /// Returns RoleplayResultDto on 2xx, null otherwise (no throw). Operator refresh test.
  static Future<RoleplayResultDto?> getRoleplayResultReload({
    required String accessToken,
    required int resultId,
  }) async {
    return _getRoleplayResultReloadInternal(accessToken, resultId);
  }

  static Future<RoleplayResultDto?> _getRoleplayResultReloadInternal(
    String accessToken,
    int resultId,
  ) async {
    final uri =
        SudaHttpClient.buildUri('/v1/roleplays/results-reload/$resultId');
    try {
      final response = await SudaHttpClient.client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return RoleplayResultDto.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /v1/roleplays/{rpId}/roles/{rpRoleId}/endings/{endingId}
  static Future<RoleplayEndingDto> getRoleplayEnding({
    required String accessToken,
    required int rpId,
    required int rpRoleId,
    required int endingId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getRoleplayEndingInternal(accessToken, rpId, rpRoleId, endingId),
      retryWithNewToken: (newToken) =>
          _getRoleplayEndingInternal(newToken, rpId, rpRoleId, endingId),
    );
  }

  static Future<void> updateRoleplayResultStar({
    required String accessToken,
    required int resultId,
    required int star,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _updateRoleplayResultStarInternal(accessToken, resultId, star),
      retryWithNewToken: (newToken) =>
          _updateRoleplayResultStarInternal(newToken, resultId, star),
    );
  }

  /// POST /v1/roleplays/results/{roleplayResultId}/report
  /// Request body: JSON with string field `content`.
  static Future<void> sendResultReport({
    required String accessToken,
    required int roleplayResultId,
    required String content,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _sendResultReportInternal(accessToken, roleplayResultId, content),
      retryWithNewToken: (newToken) =>
          _sendResultReportInternal(newToken, roleplayResultId, content),
    );
  }

  static Future<RoleplayOverviewDto> _getRoleplayOverviewInternal(
    String accessToken,
    int roleplayId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/roleplays/$roleplayId/overview');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayOverviewDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplays/$roleplayId/overview failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplaySessionDto> _createRoleplaySessionInternal(
    String accessToken,
    int roleplayId,
    int roleId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/roleplay-sessions');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
              RoleplaySessionRequestDto(
                roleplayId: roleplayId,
                roleId: roleId,
              ).toJson(),
            ),
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
      return RoleplaySessionDto.fromJson(data);
    }

    throw Exception(
      'POST /v1/roleplay-sessions failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplayUserMessageResponseDto> _sendUserMessageTextInternal(
    String accessToken,
    String rpSessionId,
    String text,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplay-sessions/$rpSessionId/user-message/text',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
              RoleplayUserMessageRequestDto(text: text).toJson(),
            ),
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
      return RoleplayUserMessageResponseDto.fromJson(data);
    }

    throw Exception(
      'POST /v1/roleplay-sessions/$rpSessionId/user-message/text failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplayUserMessageResponseDto> _sendUserMessageAudioInternal(
    String accessToken,
    String rpSessionId,
    Uint8List audioData,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplay-sessions/$rpSessionId/user-message/audio',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/octet-stream',
            },
            body: audioData,
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
      return RoleplayUserMessageResponseDto.fromJson(data);
    }

    throw Exception(
      'POST /v1/roleplay-sessions/$rpSessionId/user-message/audio failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplayAiMessageDto> _getAiMessageInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri =
        SudaHttpClient.buildUri('/v1/roleplay-sessions/$rpSessionId/ai-message');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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

    final statusCode = response.statusCode;
    debugPrint('[DEBUG] AI response HTTP statusCode=$statusCode');

    if (statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (statusCode == 202) {
      throw Exception(
        'GET /v1/roleplay-sessions/$rpSessionId/ai-message not ready: HTTP 202',
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayAiMessageDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplay-sessions/$rpSessionId/ai-message failed: HTTP $statusCode ${response.body}',
    );
  }

  static Future<RoleplayNarrationDto> _getNarrationInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri =
        SudaHttpClient.buildUri('/v1/roleplay-sessions/$rpSessionId/narration');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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

    final statusCode = response.statusCode;

    if (statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (statusCode == 202) {
      throw Exception(
        'GET /v1/roleplay-sessions/$rpSessionId/narration not ready: HTTP 202',
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayNarrationDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplay-sessions/$rpSessionId/narration failed: HTTP $statusCode ${response.body}',
    );
  }

  static Future<String> _getHintInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri =
        SudaHttpClient.buildUri('/v1/roleplay-sessions/$rpSessionId/hint');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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
      return _parseStringResponse(response.body);
    }

    throw Exception(
      'GET /v1/roleplay-sessions/$rpSessionId/hint failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplayAiMessageDto> _getHintAudioInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplay-sessions/$rpSessionId/hint/sound',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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

    final statusCode = response.statusCode;
    if (statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (statusCode >= 200 && statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayAiMessageDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplay-sessions/$rpSessionId/hint/sound failed: HTTP $statusCode ${response.body}',
    );
  }

  static Future<RoleplayAiMessageDto> _getHintWordAudioInternal(
    String accessToken,
    String rpSessionId,
    int wordIndex,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplay-sessions/$rpSessionId/hint/sound/$wordIndex',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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

    final statusCode = response.statusCode;
    if (statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (statusCode >= 200 && statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayAiMessageDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplay-sessions/$rpSessionId/hint/sound/$wordIndex failed: HTTP $statusCode ${response.body}',
    );
  }

  static Future<String> _getTranslationInternal(
    String accessToken,
    String rpSessionId,
    int index,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplay-sessions/$rpSessionId/translation',
      {
        'index': index.toString(),
      },
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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
      return _parseStringResponse(response.body);
    }

    throw Exception(
      'GET /v1/roleplay-sessions/$rpSessionId/translation failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> _updateSpeedRateInternal(
    String accessToken,
    String speedRate,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/users/speed-rate',
      {'speedRate': speedRate},
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
      'PUT /v1/users/speed-rate failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<SudaAppPage<RpSimpleResultDto>> _getResultsInternal(
    String accessToken,
    int pageNum,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/roleplays/results', {
      'pageNum': pageNum.toString(),
    });
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SudaAppPage<RpSimpleResultDto>.fromJson(
        data,
        (json) => RpSimpleResultDto.fromJson(Map<String, dynamic>.from(json)),
      );
    }

    throw Exception(
      'GET /v1/roleplays/results failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplayResultDto> _getRoleplayResultInternal(
    String accessToken,
    int resultId,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/roleplays/results/$resultId');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayResultDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplays/results/$resultId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RoleplayEndingDto> _getRoleplayEndingInternal(
    String accessToken,
    int rpId,
    int rpRoleId,
    int endingId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplays/$rpId/roles/$rpRoleId/endings/$endingId',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
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
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayEndingDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplays/$rpId/roles/$rpRoleId/endings/$endingId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> _updateRoleplayResultStarInternal(
    String accessToken,
    int resultId,
    int star,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplays/results/$resultId',
      {'star': star.toString()},
    );
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
      'PUT /v1/roleplays/results/$resultId?star=$star failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> _sendResultReportInternal(
    String accessToken,
    int roleplayResultId,
    String content,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/v1/roleplays/results/$roleplayResultId/report',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'content': content}),
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
      'POST /v1/roleplays/results/$roleplayResultId/report failed: HTTP ${response.statusCode} ${response.body}',
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
