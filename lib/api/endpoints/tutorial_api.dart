import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../models/roleplay_models.dart';
import '../../models/series_models.dart';
import '../client/suda_http_client.dart';

class TutorialNoSpeechException implements Exception {
  const TutorialNoSpeechException();
}

class TutorialAudioTooShortException implements Exception {
  const TutorialAudioTooShortException();
}

class TutorialApi {
  static Future<RpS2SessionDto> createSession({
    required String accessToken,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _createSession(accessToken),
      retryWithNewToken: _createSession,
    );
  }

  static Future<RpS2SessionDto> _createSession(String accessToken) async {
    final uri = SudaHttpClient.buildUri('/tutorial/sessions');
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
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RpS2SessionDto.fromJson(data);
    }

    throw Exception(
      'POST /tutorial/sessions failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2UserMessageResponseDto> sendUserAudio({
    required String accessToken,
    required String sessionId,
    required Uint8List audioData,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _sendUserAudio(accessToken, sessionId, audioData),
      retryWithNewToken: (token) => _sendUserAudio(token, sessionId, audioData),
    );
  }

  static Future<RpS2UserMessageResponseDto> _sendUserAudio(
    String accessToken,
    String sessionId,
    Uint8List audioData,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/tutorial/sessions/$sessionId/user-message/audio',
    );
    final response = await SudaHttpClient.client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/octet-stream',
          },
          body: audioData,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode == 400 && _code(response.body) == 'AUDIO_TOO_SHORT') {
      throw const TutorialAudioTooShortException();
    }
    if (response.statusCode == 400 && _code(response.body) == 'NO_SPEECH') {
      throw const TutorialNoSpeechException();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RpS2UserMessageResponseDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'POST /tutorial/sessions/$sessionId/user-message/audio failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  static Future<RpS2SoundResDto> aiAudio({
    required String accessToken,
    required String sessionId,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _aiAudio(accessToken, sessionId),
      retryWithNewToken: (token) => _aiAudio(token, sessionId),
    );
  }

  static Future<RpS2SoundResDto> _aiAudio(
    String accessToken,
    String sessionId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/tutorial/sessions/$sessionId/ai-message/audio',
    );
    final response = await SudaHttpClient.client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RpS2SoundResDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'GET /tutorial/sessions/$sessionId/ai-message/audio failed: HTTP ${response.statusCode}',
    );
  }

  static Future<String> translation({
    required String accessToken,
    required String sessionId,
    required int rpMsgId,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _translation(accessToken, sessionId, rpMsgId),
      retryWithNewToken: (token) => _translation(token, sessionId, rpMsgId),
    );
  }

  static Future<String> _translation(
    String accessToken,
    String sessionId,
    int rpMsgId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/tutorial/sessions/$sessionId/translation',
      {'rpMsgId': '$rpMsgId'},
    );
    final response = await SudaHttpClient.client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      return decoded is String ? decoded : '';
    }
    throw Exception(
      'GET /tutorial/sessions/$sessionId/translation failed: HTTP ${response.statusCode}',
    );
  }

  static Future<RpS2HintDto> hint({
    required String accessToken,
    required String sessionId,
    required int rpMsgId,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _hint(accessToken, sessionId, rpMsgId),
      retryWithNewToken: (token) => _hint(token, sessionId, rpMsgId),
    );
  }

  static Future<RpS2HintDto> _hint(
    String accessToken,
    String sessionId,
    int rpMsgId,
  ) async {
    final uri = SudaHttpClient.buildUri(
      '/tutorial/sessions/$sessionId/hint/$rpMsgId',
    );
    final response = await SudaHttpClient.client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RpS2HintDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'GET /tutorial/sessions/$sessionId/hint/$rpMsgId failed: HTTP ${response.statusCode}',
    );
  }

  static Future<TtsResultDto> hintSound({
    required String accessToken,
    required String sessionId,
    int? wordIndex,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _hintSound(accessToken, sessionId, wordIndex),
      retryWithNewToken: (token) => _hintSound(token, sessionId, wordIndex),
    );
  }

  static Future<TtsResultDto> _hintSound(
    String accessToken,
    String sessionId,
    int? wordIndex,
  ) async {
    final path = wordIndex == null
        ? '/tutorial/sessions/$sessionId/hint/sound'
        : '/tutorial/sessions/$sessionId/hint/sound/$wordIndex';
    final response = await SudaHttpClient.client
        .get(
          SudaHttpClient.buildUri(path),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return TtsResultDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'GET $path failed: HTTP ${response.statusCode}',
    );
  }

  static String? _code(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } catch (_) {}
    return null;
  }
}
