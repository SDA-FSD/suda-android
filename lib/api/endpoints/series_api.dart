import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/pagination.dart';
import '../../models/roleplay_models.dart';
import '../../models/series_models.dart';
import '../client/suda_http_client.dart';

class RpS2SessionNotFoundException implements Exception {
  final String message;
  RpS2SessionNotFoundException(this.message);
  @override
  String toString() => message;
}

class SeriesApi {
  static void _throwIfRpS2SessionNotFound(
    http.Response response,
    String operation,
  ) {
    if (response.statusCode == 404) {
      throw RpS2SessionNotFoundException('$operation: HTTP 404');
    }
  }
  static Future<RpS2SeriesOverviewDto> getSeriesOverview({
    required String accessToken,
    required int seriesId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSeriesOverviewInternal(accessToken, seriesId),
      retryWithNewToken: (newToken) =>
          _getSeriesOverviewInternal(newToken, seriesId),
    );
  }

  static Future<RpS2SeriesOverviewDto> _getSeriesOverviewInternal(
    String accessToken,
    int seriesId,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/series/$seriesId/overview');

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
      return RpS2SeriesOverviewDto.fromJson(data);
    }

    throw Exception(
      'GET /rps2/series/$seriesId/overview failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<Map<int, int>> getSeriesBestScore({
    required String accessToken,
    required int seriesId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSeriesBestScoreInternal(accessToken, seriesId),
      retryWithNewToken: (newToken) =>
          _getSeriesBestScoreInternal(newToken, seriesId),
    );
  }

  static Future<Map<int, int>> _getSeriesBestScoreInternal(
    String accessToken,
    int seriesId,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/series/$seriesId/best-score');

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
      final dynamic data = jsonDecode(response.body);
      return bestScoreMapFromJson(data);
    }

    throw Exception(
      'GET /rps2/series/$seriesId/best-score failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2SessionDto> createSession({
    required String accessToken,
    required int seriesId,
    required int episodeId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _createSessionInternal(accessToken, seriesId, episodeId),
      retryWithNewToken: (newToken) =>
          _createSessionInternal(newToken, seriesId, episodeId),
    );
  }

  static Future<RpS2SessionDto> _createSessionInternal(
    String accessToken,
    int seriesId,
    int episodeId,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/sessions');
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
              RpS2SessionRequestDto(
                seriesId: seriesId,
                episodeId: episodeId,
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
      return RpS2SessionDto.fromJson(data);
    }

    throw Exception(
      'POST /rps2/sessions failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<String> getSessionTranslation({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSessionTranslationInternal(accessToken, rpSessionId, rpMsgId),
      retryWithNewToken: (newToken) =>
          _getSessionTranslationInternal(newToken, rpSessionId, rpMsgId),
    );
  }

  static Future<String> _getSessionTranslationInternal(
    String accessToken,
    String rpSessionId,
    int rpMsgId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/translation',
      {'rpMsgId': rpMsgId.toString()},
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
    _throwIfRpS2SessionNotFound(
      response,
      'GET /rps2/sessions/$rpSessionId/translation',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseStringResponse(response.body);
    }
    throw Exception(
      'GET /rps2/sessions/$rpSessionId/translation failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2HintDto> getSessionHint({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) async {
    return await _getSessionHintWithReadyRetry(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      rpMsgId: rpMsgId,
    );
  }

  static Future<RpS2HintDto> _getSessionHintWithReadyRetry({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) async {
    // S1 narration/AI polling과 동일한 not-ready 대기 패턴.
    const delays = [
      Duration(milliseconds: 150),
      Duration(milliseconds: 150),
      Duration(milliseconds: 150),
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
      Duration(milliseconds: 400),
      Duration(milliseconds: 400),
      Duration(milliseconds: 400),
      Duration(milliseconds: 700),
      Duration(milliseconds: 700),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1500),
      Duration(milliseconds: 1500),
      Duration(milliseconds: 1500),
    ];
    var attempt = 0;
    while (true) {
      try {
        final result = await SudaHttpClient.executeWithRefresh(
          () => _getSessionHintInternal(accessToken, rpSessionId, rpMsgId),
          retryWithNewToken: (newToken) =>
              _getSessionHintInternal(newToken, rpSessionId, rpMsgId),
        );
        if (attempt > 0) {
          debugPrint('[DEBUG] RpS2 hint received after $attempt retries');
        }
        return result;
      } catch (e) {
        if (e is RpS2SessionNotFoundException) {
          rethrow;
        }
        final message = e.toString();
        final shouldRetry = message.contains('HTTP 202');
        if (!shouldRetry || attempt >= delays.length) {
          if (attempt >= delays.length) {
            debugPrint('[DEBUG] RpS2 hint retry exhausted: $e');
          }
          rethrow;
        }
        await Future.delayed(delays[attempt]);
        attempt += 1;
      }
    }
  }

  static Future<RpS2HintDto> _getSessionHintInternal(
    String accessToken,
    String rpSessionId,
    int rpMsgId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/hint/$rpMsgId',
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
    if (response.statusCode == 202) {
      throw Exception(
        'GET /rps2/sessions/$rpSessionId/hint/$rpMsgId not ready: HTTP 202',
      );
    }
    _throwIfRpS2SessionNotFound(
      response,
      'GET /rps2/sessions/$rpSessionId/hint/$rpMsgId',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2HintDto.fromJson(data);
    }
    throw Exception(
      'GET /rps2/sessions/$rpSessionId/hint/$rpMsgId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 영문 힌트 노출(또는 답변보기 탭) 시 서버에 전달 완료를 기록한다.
  static Future<void> markSessionHintDelivered({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) async {
    await SudaHttpClient.executeWithRefresh(
      () => _markSessionHintDeliveredInternal(
        accessToken,
        rpSessionId,
        rpMsgId,
      ),
      retryWithNewToken: (newToken) => _markSessionHintDeliveredInternal(
        newToken,
        rpSessionId,
        rpMsgId,
      ),
    );
  }

  static Future<void> _markSessionHintDeliveredInternal(
    String accessToken,
    String rpSessionId,
    int rpMsgId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/hint/$rpMsgId',
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
      'PUT /rps2/sessions/$rpSessionId/hint/$rpMsgId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<TtsResultDto> getSessionHintSound({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSessionHintSoundInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _getSessionHintSoundInternal(newToken, rpSessionId),
    );
  }

  static Future<TtsResultDto> _getSessionHintSoundInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/hint/sound',
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
    _throwIfRpS2SessionNotFound(
      response,
      'GET /rps2/sessions/$rpSessionId/hint/sound',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return TtsResultDto.fromJson(data);
    }
    throw Exception(
      'GET /rps2/sessions/$rpSessionId/hint/sound failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<TtsResultDto> getSessionHintWordSound({
    required String accessToken,
    required String rpSessionId,
    required int wordIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () =>
          _getSessionHintWordSoundInternal(accessToken, rpSessionId, wordIndex),
      retryWithNewToken: (newToken) =>
          _getSessionHintWordSoundInternal(newToken, rpSessionId, wordIndex),
    );
  }

  static Future<TtsResultDto> _getSessionHintWordSoundInternal(
    String accessToken,
    String rpSessionId,
    int wordIndex,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/hint/sound/$wordIndex',
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
    _throwIfRpS2SessionNotFound(
      response,
      'GET /rps2/sessions/$rpSessionId/hint/sound/$wordIndex',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return TtsResultDto.fromJson(data);
    }
    throw Exception(
      'GET /rps2/sessions/$rpSessionId/hint/sound/$wordIndex failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2UserMessageResponseDto> sendSessionUserMessageAudio({
    required String accessToken,
    required String rpSessionId,
    required Uint8List audioData,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _sendSessionUserMessageAudioInternal(
        accessToken,
        rpSessionId,
        audioData,
      ),
      retryWithNewToken: (newToken) => _sendSessionUserMessageAudioInternal(
        newToken,
        rpSessionId,
        audioData,
      ),
    );
  }

  static Future<RpS2UserMessageResponseDto>
  _sendSessionUserMessageAudioInternal(
    String accessToken,
    String rpSessionId,
    Uint8List audioData,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/user-message/audio',
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
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    _throwIfRpS2SessionNotFound(
      response,
      'POST /rps2/sessions/$rpSessionId/user-message/audio',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2UserMessageResponseDto.fromJson(data);
    }
    throw Exception(
      'POST /rps2/sessions/$rpSessionId/user-message/audio failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2UserMessageResponseDto> sendSessionUserMessageText({
    required String accessToken,
    required String rpSessionId,
    required String text,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _sendSessionUserMessageTextInternal(accessToken, rpSessionId, text),
      retryWithNewToken: (newToken) =>
          _sendSessionUserMessageTextInternal(newToken, rpSessionId, text),
    );
  }

  static Future<RpS2UserMessageResponseDto> _sendSessionUserMessageTextInternal(
    String accessToken,
    String rpSessionId,
    String text,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/user-message/text',
    );
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'text/plain; charset=utf-8',
            },
            body: text,
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    _throwIfRpS2SessionNotFound(
      response,
      'POST /rps2/sessions/$rpSessionId/user-message/text',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2UserMessageResponseDto.fromJson(data);
    }
    throw Exception(
      'POST /rps2/sessions/$rpSessionId/user-message/text failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2SoundResDto> getSessionAiMessageAudio({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getSessionAiMessageAudioInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _getSessionAiMessageAudioInternal(newToken, rpSessionId),
    );
  }

  static Future<RpS2SoundResDto> _getSessionAiMessageAudioInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/sessions/$rpSessionId/ai-message/audio',
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
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2SoundResDto.fromJson(data);
    }
    throw Exception(
      'GET /rps2/sessions/$rpSessionId/ai-message/audio failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<int> finishSession({
    required String accessToken,
    required String rpSessionId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _finishSessionInternal(accessToken, rpSessionId),
      retryWithNewToken: (newToken) =>
          _finishSessionInternal(newToken, rpSessionId),
    );
  }

  static Future<int> _finishSessionInternal(
    String accessToken,
    String rpSessionId,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/sessions/$rpSessionId/finish');
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
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    _throwIfRpS2SessionNotFound(
      response,
      'PUT /rps2/sessions/$rpSessionId/finish',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is num) {
        return decoded.toInt();
      }
      throw Exception(
        'PUT /rps2/sessions/$rpSessionId/finish invalid body: ${response.body}',
      );
    }
    throw Exception(
      'PUT /rps2/sessions/$rpSessionId/finish failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// GET /rps2/user-histories?pageNum=0 (0-based)
  static Future<SudaAppPage<RpS2SimpleHistoryDto>> getUserHistories({
    required String accessToken,
    required int pageNum,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserHistoriesInternal(accessToken, pageNum),
      retryWithNewToken: (newToken) =>
          _getUserHistoriesInternal(newToken, pageNum),
    );
  }

  static Future<SudaAppPage<RpS2SimpleHistoryDto>> _getUserHistoriesInternal(
    String accessToken,
    int pageNum,
  ) async {
    final uri = SudaHttpClient.buildUri('/rps2/user-histories', {
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
      return SudaAppPage<RpS2SimpleHistoryDto>.fromJson(
        data,
        (json) => RpS2SimpleHistoryDto.fromJson(
          Map<String, dynamic>.from(json),
        ),
      );
    }

    throw Exception(
      'GET /rps2/user-histories failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2UserHistoryDto> getUserHistory({
    required String accessToken,
    required int rpUserHistoryId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserHistoryInternal(accessToken, rpUserHistoryId),
      retryWithNewToken: (newToken) =>
          _getUserHistoryInternal(newToken, rpUserHistoryId),
    );
  }

  static Future<RpS2UserHistoryDto> _getUserHistoryInternal(
    String accessToken,
    int rpUserHistoryId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId',
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
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    _throwIfRpS2SessionNotFound(
      response,
      'GET /rps2/user-histories/$rpUserHistoryId',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2UserHistoryDto.fromJson(data);
    }
    throw Exception(
      'GET /rps2/user-histories/$rpUserHistoryId failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<TtsResultDto> getUserHistoryExpressionSound({
    required String accessToken,
    required int rpUserHistoryId,
    required int expressionIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserHistoryExpressionSoundInternal(
        accessToken,
        rpUserHistoryId,
        expressionIndex,
      ),
      retryWithNewToken: (newToken) => _getUserHistoryExpressionSoundInternal(
        newToken,
        rpUserHistoryId,
        expressionIndex,
      ),
    );
  }

  static Future<TtsResultDto> _getUserHistoryExpressionSoundInternal(
    String accessToken,
    int rpUserHistoryId,
    int expressionIndex,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId/expressions/$expressionIndex/sound',
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
      return TtsResultDto.fromJson(data);
    }

    throw Exception(
      'GET /rps2/user-histories/$rpUserHistoryId/expressions/$expressionIndex/sound failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> saveUserHistoryExpression({
    required String accessToken,
    required int rpUserHistoryId,
    required int expressionIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _saveUserHistoryExpressionInternal(
        accessToken,
        rpUserHistoryId,
        expressionIndex,
      ),
      retryWithNewToken: (newToken) => _saveUserHistoryExpressionInternal(
        newToken,
        rpUserHistoryId,
        expressionIndex,
      ),
    );
  }

  static Future<void> _saveUserHistoryExpressionInternal(
    String accessToken,
    int rpUserHistoryId,
    int expressionIndex,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId/expressions/$expressionIndex',
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
      'POST /rps2/user-histories/$rpUserHistoryId/expressions/$expressionIndex failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> deleteUserHistoryExpression({
    required String accessToken,
    required int rpUserHistoryId,
    required int expressionIndex,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _deleteUserHistoryExpressionInternal(
        accessToken,
        rpUserHistoryId,
        expressionIndex,
      ),
      retryWithNewToken: (newToken) => _deleteUserHistoryExpressionInternal(
        newToken,
        rpUserHistoryId,
        expressionIndex,
      ),
    );
  }

  static Future<void> _deleteUserHistoryExpressionInternal(
    String accessToken,
    int rpUserHistoryId,
    int expressionIndex,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId/expressions/$expressionIndex',
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
      'DELETE /rps2/user-histories/$rpUserHistoryId/expressions/$expressionIndex failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<TtsResultDto> getUserHistoryMessageAudio({
    required String accessToken,
    required int rpUserHistoryId,
    required int rpMsgId,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getUserHistoryMessageAudioInternal(
        accessToken,
        rpUserHistoryId,
        rpMsgId,
      ),
      retryWithNewToken: (newToken) => _getUserHistoryMessageAudioInternal(
        newToken,
        rpUserHistoryId,
        rpMsgId,
      ),
    );
  }

  static Future<TtsResultDto> _getUserHistoryMessageAudioInternal(
    String accessToken,
    int rpUserHistoryId,
    int rpMsgId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId/messages/$rpMsgId/audio',
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
      return TtsResultDto.fromJson(data);
    }

    throw Exception(
      'GET /rps2/user-histories/$rpUserHistoryId/messages/$rpMsgId/audio failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<void> updateUserStarRating({
    required String accessToken,
    required int rpUserHistoryId,
    required int userStarRating,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _updateUserStarRatingInternal(
        accessToken,
        rpUserHistoryId,
        userStarRating,
      ),
      retryWithNewToken: (newToken) => _updateUserStarRatingInternal(
        newToken,
        rpUserHistoryId,
        userStarRating,
      ),
    );
  }

  static Future<void> _updateUserStarRatingInternal(
    String accessToken,
    int rpUserHistoryId,
    int userStarRating,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId/user-star-rating',
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
            body: jsonEncode({'userStarRating': userStarRating}),
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
      'PUT /rps2/user-histories/$rpUserHistoryId/user-star-rating failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// POST /rps2/user-histories/{rpUserHistoryId}/report
  /// Request body: JSON with string field `content`.
  static Future<void> sendUserHistoryReport({
    required String accessToken,
    required int rpUserHistoryId,
    required String content,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _sendUserHistoryReportInternal(
        accessToken,
        rpUserHistoryId,
        content,
      ),
      retryWithNewToken: (newToken) => _sendUserHistoryReportInternal(
        newToken,
        rpUserHistoryId,
        content,
      ),
    );
  }

  static Future<void> _sendUserHistoryReportInternal(
    String accessToken,
    int rpUserHistoryId,
    String content,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/rps2/user-histories/$rpUserHistoryId/report',
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
      'POST /rps2/user-histories/$rpUserHistoryId/report failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// S1 `RoleplayApi._parseStringResponse`와 동일 — 응답이 plain text 또는 JSON String.
  static String _parseStringResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // plain text 응답
    }
    return body;
  }
}
