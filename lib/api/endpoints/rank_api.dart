import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/character_reward_models.dart';
import '../../models/rank_models.dart';
import '../client/suda_http_client.dart';

class RankApi {
  static const _headers = {'Accept': 'application/json'};

  static Future<RankScreenDto> getRankScreen({
    required String accessToken,
  }) async {
    return await SudaHttpClient.executeWithRefresh(
      () => _getRankScreenInternal(accessToken),
      retryWithNewToken: (newToken) => _getRankScreenInternal(newToken),
    );
  }

  static Future<RankScreenDto> _getRankScreenInternal(String accessToken) async {
    // period·entries 병렬 → snapshotMinute로 /entries/me (sticky 전용)
    final results = await Future.wait<Object?>([
      _getCurrentPeriod(accessToken),
      _getEntries(accessToken, pageNum: 0),
    ]);
    final period = results[0] as RankPeriodDto?;
    if (period == null) {
      return const RankScreenDto();
    }
    final page = results[1] as RankEntryPageDto;
    final snap = page.snapshotMinute;
    RankEntryDto? myEntry;
    if (snap != null && snap.isNotEmpty) {
      try {
        myEntry = await _getMyEntryInternal(accessToken, snap);
      } catch (err) {
        // /me 실패 시 page0 isMe 폴백
        debugPrint('rank getMyEntry failed, fallback to page isMe: $err');
        for (final entry in page.entries) {
          if (entry.isMe) {
            myEntry = entry.copyWith(isMe: true);
            break;
          }
        }
      }
    }
    return RankScreenDto.fromPeriodAndPage(
      period: period,
      page: page,
      myEntry: myEntry,
      myEntryFromMeApi: true,
    );
  }

  /// GET /v1/rank/entries/me?snapshotMinute= — 200 + body / JSON null.
  static Future<RankEntryDto?> getMyEntry({
    required String accessToken,
    required String snapshotMinute,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _getMyEntryInternal(accessToken, snapshotMinute),
      retryWithNewToken: (newToken) =>
          _getMyEntryInternal(newToken, snapshotMinute),
    );
  }

  static Future<RankEntryDto?> _getMyEntryInternal(
    String accessToken,
    String snapshotMinute,
  ) async {
    final response = await _get(
      '/v1/rank/entries/me',
      accessToken,
      {'snapshotMinute': snapshotMinute},
    );
    final raw = response.body.trim();
    if (raw.isEmpty || raw == 'null') {
      return null;
    }
    final data = jsonDecode(raw);
    if (data == null) {
      return null;
    }
    if (data is! Map<String, dynamic>) {
      throw Exception(
        'GET /v1/rank/entries/me unexpected body: ${response.body}',
      );
    }
    return RankEntryDto.fromJson(data).copyWith(isMe: true);
  }

  static Future<RankPeriodDto?> _getCurrentPeriod(String accessToken) async {
    final response = await _get('/v1/rank/period/current', accessToken);
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      return null;
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception(
        'GET /v1/rank/period/current unexpected body: ${response.body}',
      );
    }
    return RankPeriodDto.fromJson(data);
  }

  /// GET /v1/rank/character-rewards/claimable?periodId= — `List<Long>` 미수령 RANKED reward id.
  static Future<List<int>> getRankingRewardClaimableIds({
    required String accessToken,
    required int periodId,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _getRankingRewardClaimableIdsInternal(accessToken, periodId),
      retryWithNewToken: (newToken) =>
          _getRankingRewardClaimableIdsInternal(newToken, periodId),
    );
  }

  static Future<List<int>> _getRankingRewardClaimableIdsInternal(
    String accessToken,
    int periodId,
  ) async {
    final response = await _get(
      '/v1/rank/character-rewards/claimable',
      accessToken,
      {'periodId': '$periodId'},
    );
    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception(
        'GET /v1/rank/character-rewards/claimable unexpected body: ${response.body}',
      );
    }
    return data.map((e) => (e as num).toInt()).toList();
  }

  /// POST /v1/rank/character-rewards/claim — body `List<Long>`, 200 수령분.
  static Future<List<CharacterRewardClaimDto>> claimRankingCharacterRewards({
    required String accessToken,
    required List<int> userCharacterRewardIds,
  }) {
    return SudaHttpClient.executeWithRefresh(
      () => _claimRankingCharacterRewardsInternal(
        accessToken,
        userCharacterRewardIds,
      ),
      retryWithNewToken: (newToken) => _claimRankingCharacterRewardsInternal(
        newToken,
        userCharacterRewardIds,
      ),
    );
  }

  static Future<List<CharacterRewardClaimDto>>
      _claimRankingCharacterRewardsInternal(
    String accessToken,
    List<int> userCharacterRewardIds,
  ) async {
    final uri = SudaHttpClient.buildUri('/v1/rank/character-rewards/claim');
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .post(
            uri,
            headers: {
              ..._headers,
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
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
        'POST /v1/rank/character-rewards/claim failed: HTTP ${response.statusCode} ${response.body}',
      );
    }

    final raw = response.body.trim();
    if (raw.isEmpty || raw == 'null') {
      return const [];
    }
    final data = jsonDecode(raw);
    if (data is! List) {
      throw Exception(
        'POST /v1/rank/character-rewards/claim unexpected body: ${response.body}',
      );
    }
    return [
      for (final e in data)
        if (e is Map)
          CharacterRewardClaimDto.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  static Future<RankEntryPageDto> getRankEntries({
    required String accessToken,
    required int pageNum,
    String? snapshotMinute,
  }) async {
    return SudaHttpClient.executeWithRefresh(
      () => _getEntries(accessToken, pageNum: pageNum, snapshotMinute: snapshotMinute),
      retryWithNewToken: (newToken) =>
          _getEntries(newToken, pageNum: pageNum, snapshotMinute: snapshotMinute),
    );
  }

  static Future<RankEntryPageDto> _getEntries(
    String accessToken, {
    required int pageNum,
    String? snapshotMinute,
  }) async {
    final query = <String, String>{'pageNum': '$pageNum'};
    if (snapshotMinute != null && snapshotMinute.isNotEmpty) {
      query['snapshotMinute'] = snapshotMinute;
    }
    final response = await _get('/v1/rank/entries', accessToken, query);
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception(
        'GET /v1/rank/entries unexpected body: ${response.body}',
      );
    }
    return RankEntryPageDto.fromJson(data);
  }

  static Future<http.Response> _get(
    String path,
    String accessToken, [
    Map<String, String>? query,
  ]) async {
    final uri = SudaHttpClient.buildUri(path, query);
    late final http.Response response;
    try {
      response = await SudaHttpClient.client
          .get(
            uri,
            headers: {
              ..._headers,
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
      return response;
    }

    throw Exception(
      'GET $path failed: HTTP ${response.statusCode} ${response.body}',
    );
  }
}
