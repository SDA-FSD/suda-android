import 'common_models.dart';

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
      final intValue =
          entry.value is int ? entry.value as int : int.tryParse(entry.value.toString());
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
  final int? roleId;
  final List<SudaJson>? name;
  final List<SudaJson>? description;
  final String? endingType;

  const RoleplayEndingDto({
    required this.id,
    this.roleId,
    this.name,
    this.description,
    this.endingType,
  });

  factory RoleplayEndingDto.fromJson(Map<String, dynamic> json) {
    return RoleplayEndingDto(
      id: json['id'] as int? ?? 0,
      roleId: json['roleId'] as int?,
      name: json['name'] == null
          ? null
          : (json['name'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      description: json['description'] == null
          ? null
          : (json['description'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      endingType: json['endingType'] as String?,
    );
  }
}

class RoleplayMissionDto {
  final int id;
  final int? roleId;
  final List<SudaJson>? mission;
  final int? score;

  const RoleplayMissionDto({
    required this.id,
    this.roleId,
    this.mission,
    this.score,
  });

  factory RoleplayMissionDto.fromJson(Map<String, dynamic> json) {
    return RoleplayMissionDto(
      id: json['id'] as int? ?? 0,
      roleId: json['roleId'] as int?,
      mission: json['mission'] == null
          ? null
          : (json['mission'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      score: json['score'] as int?,
    );
  }
}
