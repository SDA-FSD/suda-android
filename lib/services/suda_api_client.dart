import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'token_storage.dart';

/// 401 Unauthorized 예외
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

/// SUDA 인증 토큰 응답 모델
class SudaAuthTokens {
  final String accessToken;
  final String? refreshToken;

  const SudaAuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  factory SudaAuthTokens.fromJson(Map<String, dynamic> json) {
    return SudaAuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}

/// SudaJson 모델 (key-value 구조)
class SudaJson {
  final String key;
  final String value;

  const SudaJson({
    required this.key,
    required this.value,
  });

  factory SudaJson.fromJson(Map<String, dynamic> json) {
    return SudaJson(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }
}

/// Roleplay Overview 응답 DTO
class RoleplayOverviewDto {
  final RoleplayDto? roleplay;
  final List<int>? availableRoleIds;
  final Map<int, int>? starResultMap;
  final List<RoleplayDto>? similarRoleplayList;

  const RoleplayOverviewDto({
    this.roleplay,
    this.availableRoleIds,
    this.starResultMap,
    this.similarRoleplayList,
  });

  factory RoleplayOverviewDto.fromJson(Map<String, dynamic> json) {
    return RoleplayOverviewDto(
      roleplay: json['roleplay'] == null
          ? null
          : RoleplayDto.fromJson(json['roleplay'] as Map<String, dynamic>),
      availableRoleIds: json['availableRoleIds'] == null
          ? null
          : (json['availableRoleIds'] as List<dynamic>)
              .map((item) => item as int)
              .toList(),
      starResultMap: _parseStarResultMap(json['starResultMap']),
      similarRoleplayList: json['similarRoleplayList'] == null
          ? null
          : (json['similarRoleplayList'] as List<dynamic>)
              .map((item) => RoleplayDto.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }

  static Map<int, int>? _parseStarResultMap(dynamic value) {
    if (value is! Map<String, dynamic> && value is! Map<dynamic, dynamic>) {
      return null;
    }
    final Map<int, int> result = {};
    final map = value as Map<dynamic, dynamic>;
    for (final entry in map.entries) {
      final keyValue = entry.key;
      final intKey = keyValue is int ? keyValue : int.tryParse(keyValue.toString());
      if (intKey == null) continue;
      final intValue = entry.value is int ? entry.value as int : int.tryParse(entry.value.toString());
      if (intValue == null) continue;
      result[intKey] = intValue;
    }
    return result;
  }
}

class RoleplayDto {
  final int id;
  final int? categoryId;
  final List<SudaJson>? title;
  final List<SudaJson>? synopsis;
  final String? duration;
  final String? thumbnailImgPath;
  final String? overviewImgPath;
  final SudaJson? starter;
  final List<RoleplayRoleDto>? roleList;

  const RoleplayDto({
    required this.id,
    this.categoryId,
    this.title,
    this.synopsis,
    this.duration,
    this.thumbnailImgPath,
    this.overviewImgPath,
    this.starter,
    this.roleList,
  });

  factory RoleplayDto.fromJson(Map<String, dynamic> json) {
    final durationValue = json['duration'];
    final duration = durationValue == null || (durationValue is String && durationValue.isEmpty)
        ? null
        : durationValue.toString();

    return RoleplayDto(
      id: json['id'] as int? ?? 0,
      categoryId: json['categoryId'] as int?,
      title: json['title'] == null
          ? null
          : (json['title'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      synopsis: json['synopsis'] == null
          ? null
          : (json['synopsis'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      duration: duration,
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
      overviewImgPath: json['overviewImgPath'] as String?,
      starter: json['starter'] == null
          ? null
          : SudaJson.fromJson(json['starter'] as Map<String, dynamic>),
      roleList: json['roleList'] == null
          ? null
          : (json['roleList'] as List<dynamic>)
              .map((item) => RoleplayRoleDto.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class RoleplayRoleDto {
  final int id;
  final int? roleplayId;
  final int? characterId;
  final List<SudaJson>? name;
  final List<SudaJson>? scenario;
  final String? availableToUsersYn;
  final String? avatarImgPath;
  final List<String>? scenarioFlow;
  final List<RoleplayEndingDto>? endingList;
  final List<RoleplayMissionDto>? missionList;

  const RoleplayRoleDto({
    required this.id,
    this.roleplayId,
    this.characterId,
    this.name,
    this.scenario,
    this.availableToUsersYn,
    this.avatarImgPath,
    this.scenarioFlow,
    this.endingList,
    this.missionList,
  });

  factory RoleplayRoleDto.fromJson(Map<String, dynamic> json) {
    return RoleplayRoleDto(
      id: json['id'] as int? ?? 0,
      roleplayId: json['roleplayId'] as int?,
      characterId: json['characterId'] as int?,
      name: json['name'] == null
          ? null
          : (json['name'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      scenario: json['scenario'] == null
          ? null
          : (json['scenario'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      availableToUsersYn: json['availableToUsersYn'] as String?,
      avatarImgPath: json['avatarImgPath'] as String?,
      scenarioFlow: json['scenarioFlow'] == null
          ? null
          : (json['scenarioFlow'] as List<dynamic>)
              .map((item) => item.toString())
              .toList(),
      endingList: json['endingList'] == null
          ? null
          : (json['endingList'] as List<dynamic>)
              .map((item) => RoleplayEndingDto.fromJson(item as Map<String, dynamic>))
              .toList(),
      missionList: json['missionList'] == null
          ? null
          : (json['missionList'] as List<dynamic>)
              .map((item) => RoleplayMissionDto.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class RoleplayEndingDto {
  final int id;
  final int? roleplayRoleId;
  final List<SudaJson>? buttonText;
  final List<SudaJson>? title;
  final List<SudaJson>? content;
  final String? imgPath;

  const RoleplayEndingDto({
    required this.id,
    this.roleplayRoleId,
    this.buttonText,
    this.title,
    this.content,
    this.imgPath,
  });

  factory RoleplayEndingDto.fromJson(Map<String, dynamic> json) {
    return RoleplayEndingDto(
      id: json['id'] as int? ?? 0,
      roleplayRoleId: json['roleplayRoleId'] as int?,
      buttonText: json['buttonText'] == null
          ? null
          : (json['buttonText'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      title: json['title'] == null
          ? null
          : (json['title'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      content: json['content'] == null
          ? null
          : (json['content'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      imgPath: json['imgPath'] as String?,
    );
  }
}

class RoleplayMissionDto {
  final int id;
  final int? roleplayRoleId;
  final int? scenarioFlowIndex;

  const RoleplayMissionDto({
    required this.id,
    this.roleplayRoleId,
    this.scenarioFlowIndex,
  });

  factory RoleplayMissionDto.fromJson(Map<String, dynamic> json) {
    return RoleplayMissionDto(
      id: json['id'] as int? ?? 0,
      roleplayRoleId: json['roleplayRoleId'] as int?,
      scenarioFlowIndex: json['scenarioFlowIndex'] as int?,
    );
  }
}

/// /v1/latest-version 응답 Version DTO
class VersionDto {
  final String latestVersion;
  final String forceUpdateYn;
  final String? androidMarketLink;
  final String? appleMarketLink;

  const VersionDto({
    required this.latestVersion,
    required this.forceUpdateYn,
    this.androidMarketLink,
    this.appleMarketLink,
  });

  factory VersionDto.fromJson(Map<String, dynamic> json) {
    // 서버 응답 필드명 매핑: version -> latestVersion, aosMarketLink -> androidMarketLink, iosMarketLink -> appleMarketLink
    // 하위 호환성을 위해 두 필드명 모두 확인
    final versionValue = json['version'] ?? json['latestVersion'];
    final androidLink = json['aosMarketLink'] ?? json['androidMarketLink'];
    final appleLink = json['iosMarketLink'] ?? json['appleMarketLink'];
    
    return VersionDto(
      latestVersion: versionValue as String,
      forceUpdateYn: json['forceUpdateYn'] as String,
      androidMarketLink: _parseNullableString(androidLink),
      appleMarketLink: _parseNullableString(appleLink),
    );
  }
  
  /// 빈 문자열이나 null을 null로 처리하는 헬퍼 함수
  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    return value as String?;
  }
}

/// GET /v1/users/profile 응답 Profile DTO
class ProfileDto {
  /// 서버 응답의 JSON key는 `userDto`이지만, 앱 내부에서는 `user`로 통일해서 사용
  final UserDto user;
  final int currentLevel;
  final int progressPercentage;

  const ProfileDto({
    required this.user,
    required this.currentLevel,
    required this.progressPercentage,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      user: UserDto.fromJson(json['userDto'] as Map<String, dynamic>),
      currentLevel: json['currentLevel'] as int,
      progressPercentage: json['progressPercentage'] as int,
    );
  }
}

/// User DTO
class UserDto {
  final int id;
  final String provider;
  final String sub;
  final String name;
  final String email;
  final String? profileImgUrl;
  final int roleplayCount;
  final int wordsSpokenCount;
  final int likePoint;
  final String firstLoginYn;
  final List<SudaJson>? metaInfo;

  const UserDto({
    required this.id,
    required this.provider,
    required this.sub,
    required this.name,
    required this.email,
    this.profileImgUrl,
    required this.roleplayCount,
    required this.wordsSpokenCount,
    required this.likePoint,
    required this.firstLoginYn,
    this.metaInfo,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      provider: json['provider'] as String,
      sub: json['sub'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImgUrl: json['profileImgUrl'] as String?,
      roleplayCount: json['roleplayCount'] as int,
      wordsSpokenCount: json['wordsSpokenCount'] as int,
      likePoint: json['likePoint'] as int,
      firstLoginYn: json['firstLoginYn'] as String,
      metaInfo: json['metaInfo'] == null
          ? null
          : (json['metaInfo'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }

  UserDto copyWith({
    List<SudaJson>? metaInfo,
    String? name,
    String? profileImgUrl,
  }) {
    return UserDto(
      id: id,
      provider: provider,
      sub: sub,
      name: name ?? this.name,
      email: email,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      roleplayCount: roleplayCount,
      wordsSpokenCount: wordsSpokenCount,
      likePoint: likePoint,
      firstLoginYn: firstLoginYn,
      metaInfo: metaInfo ?? this.metaInfo,
    );
  }
}

/// GET /v1/home/banners 응답 Banner DTO
class MainHomeBannerDto {
  final String imgPath;
  final List<SudaJson> overlayText;

  const MainHomeBannerDto({
    required this.imgPath,
    required this.overlayText,
  });

  factory MainHomeBannerDto.fromJson(Map<String, dynamic> json) {
    return MainHomeBannerDto(
      imgPath: json['imgPath'] as String,
      overlayText: json['overlayText'] == null
          ? []
          : (json['overlayText'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// 카테고리 정보 DTO
class RoleplayCategoryDto {
  final int id;
  final String name;

  const RoleplayCategoryDto({required this.id, required this.name});

  factory RoleplayCategoryDto.fromJson(Map<String, dynamic> json) {
    return RoleplayCategoryDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// 홈 화면 롤플레이 정보 DTO
class AppHomeRoleplayDto {
  final int id;
  final List<SudaJson> title;
  final String thumbnailImgPath;

  const AppHomeRoleplayDto({
    required this.id,
    required this.title,
    required this.thumbnailImgPath,
  });

  factory AppHomeRoleplayDto.fromJson(Map<String, dynamic> json) {
    return AppHomeRoleplayDto(
      id: json['id'] as int? ?? 0,
      title: json['title'] == null
          ? []
          : (json['title'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      thumbnailImgPath: json['thumbnailImgPath'] as String? ?? '',
    );
  }
}

/// 홈 화면 카테고리별 롤플레이 그룹 DTO
class AppHomeRoleplayGroupDto {
  final RoleplayCategoryDto roleplayCategoryDto;
  final List<AppHomeRoleplayDto> list;

  const AppHomeRoleplayGroupDto({
    required this.roleplayCategoryDto,
    required this.list,
  });

  factory AppHomeRoleplayGroupDto.fromJson(Map<String, dynamic> json) {
    return AppHomeRoleplayGroupDto(
      roleplayCategoryDto: RoleplayCategoryDto.fromJson(
          json['roleplayCategoryDto'] as Map<String, dynamic>),
      list: (json['list'] as List<dynamic>)
          .map((item) => AppHomeRoleplayDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 공통 페이징 응답 모델
class SudaAppPage<T> {
  final List<T> content;
  final int number;
  final int size;
  final bool last;
  final bool first;

  const SudaAppPage({
    required this.content,
    required this.number,
    required this.size,
    required this.last,
    required this.first,
  });

  factory SudaAppPage.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return SudaAppPage<T>(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      number: json['number'] as int,
      size: json['size'] as int,
      last: json['last'] as bool,
      first: json['first'] as bool,
    );
  }
}

/// SUDA API 클라이언트
class SudaApiClient {
  static final http.Client _client = http.Client();

  static Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    // base URL 파싱
    final baseUrl = Uri.parse(AppConfig.apiBaseUrl);
    return Uri(
      scheme: baseUrl.scheme,
      host: baseUrl.host,
      port: baseUrl.port,
      path: path,
      queryParameters: queryParameters,
    );
  }

  /// Token Refresh Manager (동시 요청 큐잉 처리)
  static final _refreshManager = _TokenRefreshManager();

  /// Refresh Token으로 Access Token 갱신 (내부용, 동시 요청 방지)
  static Future<String> _refreshAccessToken() async {
    return await _refreshManager.refresh();
  }
}

/// Token Refresh Manager
/// 
/// 동시에 여러 요청이 401을 받을 때 refresh 요청을 1회만 실행하고
/// 나머지 요청은 대기 후 새 토큰으로 재시도
class _TokenRefreshManager {
  Future<String>? _refreshFuture;
  final Completer<void>? _refreshCompleter = null;

  Future<String> refresh() async {
    // 이미 refresh가 진행 중이면 대기
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    // refresh 시작
    _refreshFuture = _doRefresh();
    try {
      final newAccessToken = await _refreshFuture!;
      return newAccessToken;
    } finally {
      // refresh 완료 후 초기화
      _refreshFuture = null;
    }
  }

  Future<String> _doRefresh() async {
    final refreshToken = await TokenStorage.loadRefreshToken();
    if (refreshToken == null) {
      throw UnauthorizedException('No refresh token available');
    }

    final deviceId = await TokenStorage.getDeviceId();
    final tokens = await SudaApiClient.refreshToken(
      refreshToken: refreshToken,
      deviceId: deviceId,
    );

    // 새 토큰 저장
    await TokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    return tokens.accessToken;
  }

  /// Refresh 실패 시 큐에 대기 중인 요청 모두 실패 처리
  void clear() {
    _refreshFuture = null;
  }
}

  /// 홈 화면 배너 목록 조회
  ///
  /// GET /v1/home/banners
  static Future<List<MainHomeBannerDto>> getHomeBanners({
    required String accessToken,
  }) async {
    return await _executeWithRefresh(
      () => _getHomeBannersInternal(accessToken),
      retryWithNewToken: (newToken) => _getHomeBannersInternal(newToken),
    );
  }

  static Future<List<MainHomeBannerDto>> _getHomeBannersInternal(String accessToken) async {
    final uri = _buildUri('/v1/home/banners');
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) => MainHomeBannerDto.fromJson(item as Map<String, dynamic>)).toList();
    }

    throw Exception(
      'GET /v1/home/banners failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 홈 화면 카테고리별 롤플레이 목록 전체 조회
  ///
  /// GET /v1/home/roleplays/all
  static Future<List<AppHomeRoleplayGroupDto>> getHomeRoleplayGroups({
    required String accessToken,
  }) async {
    return await _executeWithRefresh(
      () => _getHomeRoleplayGroupsInternal(accessToken),
      retryWithNewToken: (newToken) => _getHomeRoleplayGroupsInternal(newToken),
    );
  }

  static Future<List<AppHomeRoleplayGroupDto>> _getHomeRoleplayGroupsInternal(String accessToken) async {
    final uri = _buildUri('/v1/home/roleplays/all');
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) => AppHomeRoleplayGroupDto.fromJson(item as Map<String, dynamic>)).toList();
    }

    throw Exception(
      'GET /v1/home/roleplays/all failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 카테고리별 롤플레이 목록 페이징 조회
  ///
  /// GET /v1/home/roleplays/categories/{roleplayCategoryId}?pageNum={page}
  static Future<SudaAppPage<AppHomeRoleplayDto>> getRoleplaysByCategory({
    required String accessToken,
    required int categoryId,
    required int pageNum,
  }) async {
    return await _executeWithRefresh(
      () => _getRoleplaysByCategoryInternal(accessToken, categoryId, pageNum),
      retryWithNewToken: (newToken) => _getRoleplaysByCategoryInternal(newToken, categoryId, pageNum),
    );
  }

  static Future<SudaAppPage<AppHomeRoleplayDto>> _getRoleplaysByCategoryInternal(
    String accessToken,
    int categoryId,
    int pageNum,
  ) async {
    final uri = _buildUri('/v1/home/roleplays/categories/$categoryId', {
      'pageNum': pageNum.toString(),
    });
    
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return SudaAppPage<AppHomeRoleplayDto>.fromJson(
        data,
        (json) => AppHomeRoleplayDto.fromJson(json),
      );
    }

    throw Exception(
      'GET /v1/home/roleplays/categories failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 롤플레이 오버뷰 조회
  ///
  /// GET /v1/roleplays/{roleplayId}/overview
  static Future<RoleplayOverviewDto> getRoleplayOverview({
    required String accessToken,
    required int roleplayId,
  }) async {
    return await _executeWithRefresh(
      () => _getRoleplayOverviewInternal(accessToken, roleplayId),
      retryWithNewToken: (newToken) => _getRoleplayOverviewInternal(newToken, roleplayId),
    );
  }

  static Future<RoleplayOverviewDto> _getRoleplayOverviewInternal(
    String accessToken,
    int roleplayId,
  ) async {
    final uri = _buildUri('/v1/roleplays/$roleplayId/overview');
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Access token expired');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return RoleplayOverviewDto.fromJson(data);
    }

    throw Exception(
      'GET /v1/roleplays/$roleplayId/overview failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 최신 버전 정보 조회
  ///
  /// GET /v1/latest-version
  static Future<VersionDto> getLatestVersion() async {
    final uri = _buildUri('/v1/latest-version');
    late final http.Response response;
    try {
      response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
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

  /// Google ID Token으로 SUDA 서버에 로그인 요청
  ///
  /// POST /v1/auth/google
  static Future<SudaAuthTokens> loginWithGoogle({
    required String idToken,
    required String deviceId,
  }) async {
    final uri = _buildUri('/v1/auth/google');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'idToken': idToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SudaAuthTokens.fromJson(data);
    }

    throw Exception(
      'SUDA Google auth failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// Refresh Token으로 Access Token 갱신
  ///
  /// POST /v1/auth/refresh
  static Future<SudaAuthTokens> refreshToken({
    required String refreshToken,
    required String deviceId,
  }) async {
    final uri = _buildUri('/v1/auth/refresh');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SudaAuthTokens.fromJson(data);
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Refresh token expired or invalid');
    }

    throw Exception(
      'POST /v1/auth/refresh failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 로그아웃
  ///
  /// POST /v1/auth/logout
  static Future<void> logout({
    required String refreshToken,
    required String deviceId,
  }) async {
    final uri = _buildUri('/v1/auth/logout');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // 로그아웃은 실패해도 로컬 토큰은 삭제하므로 에러를 무시하지 않지만,
    // 401이어도 정상 처리로 간주 (이미 만료된 토큰일 수 있음)
    if (response.statusCode == 401) {
      return;
    }

    throw Exception(
      'POST /v1/auth/logout failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 현재 로그인된 사용자 정보 조회
  ///
  /// GET /v1/users
  static Future<UserDto> getCurrentUser({
    required String accessToken,
  }) async {
    return await _executeWithRefresh(
      () => _getCurrentUserInternal(accessToken),
      retryWithNewToken: (newToken) => _getCurrentUserInternal(newToken),
    );
  }

  static Future<UserDto> _getCurrentUserInternal(String accessToken) async {
    final uri = _buildUri('/v1/users');

    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
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

  /// 401 발생 시 자동 refresh 후 재시도하는 래퍼
  static Future<T> _executeWithRefresh<T>(
    Future<T> Function() apiCall, {
    Future<T> Function(String newAccessToken)? retryWithNewToken,
  }) async {
    try {
      return await apiCall();
    } on UnauthorizedException {
      // 401 발생 시 refresh 시도
      try {
        final newAccessToken = await _refreshAccessToken();
        // refresh 성공 시 새로운 토큰으로 재시도
        if (retryWithNewToken != null) {
          return await retryWithNewToken(newAccessToken);
        }
        // retryWithNewToken이 제공되지 않은 경우 원래 호출 재시도
        // (이 경우 클로저로 캡처된 토큰을 사용하므로 제대로 동작하지 않을 수 있음)
        return await apiCall();
      } catch (e) {
        // refresh 실패 시 큐에 대기 중인 요청 모두 실패 처리
        _refreshManager.clear();
        rethrow;
      }
    }
  }

  /// 사용자 프로필 정보 조회 (user + 부가 정보)
  ///
  /// GET /v1/users/profile
  static Future<ProfileDto> getUserProfile({
    required String accessToken,
  }) async {
    return await _executeWithRefresh(
      () => _getUserProfileInternal(accessToken),
      retryWithNewToken: (newToken) => _getUserProfileInternal(newToken),
    );
  }

  static Future<ProfileDto> _getUserProfileInternal(String accessToken) async {
    final uri = _buildUri('/v1/users/profile');

    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
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

  /// 사용자 이름 변경
  ///
  /// PUT /v1/users?name=...
  static Future<void> updateName({
    required String accessToken,
    required String name,
  }) async {
    final uri = _buildUri('/v1/users', {'name': name});

    late final http.Response response;
    try {
      response = await _client
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'PUT /v1/users failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 사용자 계정 삭제
  ///
  /// DELETE /v1/users
  static Future<void> deleteUser({
    required String accessToken,
  }) async {
    final uri = _buildUri('/v1/users');

    late final http.Response response;
    try {
      response = await _client
          .delete(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'DELETE /v1/users failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 푸시 토큰 등록
  ///
  /// POST /v1/users/push-token
  static Future<void> registerPushToken({
    required String accessToken,
    required String pushToken,
    required String languageCode,
  }) async {
    final uri = _buildUri('/v1/users/push-token');

    try {
      await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'deviceType': 'ANDROID',
              'pushToken': pushToken,
              'languageCode': languageCode,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // 무시
    }
  }

  /// 사용자 서비스 이용 동의 처리
  ///
  /// POST /v1/users/agreement
  static Future<void> updateAgreement({
    required String accessToken,
  }) async {
    final uri = _buildUri('/v1/users/agreement');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'POST /v1/users/agreement failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 사용자 영어 레벨 변경
  ///
  /// PUT /v1/users/language-level?languageLevel=...
  static Future<void> updateLanguageLevel({
    required String accessToken,
    required String languageLevel,
  }) async {
    final uri = _buildUri('/v1/users/language-level', {'languageLevel': languageLevel});

    late final http.Response response;
    try {
      response = await _client
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'PUT /v1/users/language-level failed: HTTP ${response.statusCode} ${response.body}',
    );
  }

  /// 사용자 피드백 전송
  ///
  /// POST /v1/users/feedback?content=...
  static Future<void> sendFeedback({
    required String accessToken,
    required String content,
  }) async {
    final uri = _buildUri('/v1/users/feedback', {'content': content});

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
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
