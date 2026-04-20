import 'dart:convert';
import 'dart:typed_data';

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

class RoleplaySessionRequestDto {
  final int roleplayId;
  final int roleId;

  const RoleplaySessionRequestDto({
    required this.roleplayId,
    required this.roleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'roleplayId': roleplayId,
      'roleId': roleId,
    };
  }
}

class RoleplaySessionDto {
  final String? sessionId;
  final String? aiSoundCdnYn;
  final String? aiSoundCdnPath;
  final Uint8List? aiSoundFile;

  const RoleplaySessionDto({
    this.sessionId,
    this.aiSoundCdnYn,
    this.aiSoundCdnPath,
    this.aiSoundFile,
  });

  factory RoleplaySessionDto.fromJson(Map<String, dynamic> json) {
    final raw = json['sessionId'];
    final sessionId = raw == null ? null : raw.toString();
    return RoleplaySessionDto(
      sessionId: sessionId,
      aiSoundCdnYn: json['aiSoundCdnYn'] as String?,
      aiSoundCdnPath: json['aiSoundCdnPath'] as String?,
      aiSoundFile: _parseBytes(json['aiSoundFile']),
    );
  }
}

class RoleplayUserMessageRequestDto {
  final String text;

  const RoleplayUserMessageRequestDto({
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}

class RoleplayUserMessageResponseDto {
  final String? text;
  final String? missionCompleteYn;

  const RoleplayUserMessageResponseDto({
    this.text,
    this.missionCompleteYn,
  });

  factory RoleplayUserMessageResponseDto.fromJson(Map<String, dynamic> json) {
    return RoleplayUserMessageResponseDto(
      text: json['text'] as String?,
      missionCompleteYn: json['missionCompleteYn'] as String?,
    );
  }
}

class TtsResultDto {
  final String? text;
  final String? cdnYn;
  final String? cdnPath;
  /// Byte[] 음원. CDN 미사용(cdnYn == 'N')이거나 미제공 시 null.
  final Uint8List? sound;

  const TtsResultDto({
    this.text,
    this.cdnYn,
    this.cdnPath,
    this.sound,
  });

  factory TtsResultDto.fromJson(Map<String, dynamic> json) {
    return TtsResultDto(
      text: json['text'] as String?,
      cdnYn: json['cdnYn'] as String?,
      cdnPath: json['cdnPath'] as String?,
      sound: _parseBytes(json['sound']),
    );
  }
}

class RoleplaySessionStatusDto {
  final String? completedYn;
  final int? resultId;

  const RoleplaySessionStatusDto({this.completedYn, this.resultId});

  factory RoleplaySessionStatusDto.fromJson(Map<String, dynamic> json) {
    return RoleplaySessionStatusDto(
      completedYn: json['completedYn'] as String?,
      resultId: _optionalInt(json['resultId']),
    );
  }
}

class RoleplayNarrationDto {
  final String? text;
  final String? missionActiveYn;
  final int? currentStep;
  final int? resultId;

  const RoleplayNarrationDto({
    this.text,
    this.missionActiveYn,
    this.currentStep,
    this.resultId,
  });

  factory RoleplayNarrationDto.fromJson(Map<String, dynamic> json) {
    return RoleplayNarrationDto(
      text: json['text'] as String?,
      missionActiveYn: json['missionActiveYn'] as String?,
      currentStep: _optionalInt(json['currentStep']),
      resultId: _optionalInt(json['resultId']),
    );
  }
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

Uint8List? _parseBytes(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is List<dynamic>) {
    return Uint8List.fromList(value.map((item) => item as int).toList());
  }
  if (value is String && value.isNotEmpty) {
    return Uint8List.fromList(base64Decode(value));
  }
  return null;
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
  final int roleplayRoleId;
  final List<SudaJson>? buttonText;
  final List<SudaJson> title;
  final List<SudaJson> content;
  final String? imgPath;

  const RoleplayEndingDto({
    required this.id,
    required this.roleplayRoleId,
    this.buttonText,
    required this.title,
    required this.content,
    this.imgPath,
  });

  factory RoleplayEndingDto.fromJson(Map<String, dynamic> json) {
    return RoleplayEndingDto(
      id: _optionalInt(json['id']) ?? 0,
      roleplayRoleId: _optionalInt(json['roleplayRoleId']) ?? 0,
      buttonText: json['buttonText'] == null
          ? null
          : (json['buttonText'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      title: json['title'] == null
          ? <SudaJson>[]
          : (json['title'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      content: json['content'] == null
          ? <SudaJson>[]
          : (json['content'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      imgPath: json['imgPath'] as String?,
    );
  }
}

class RoleplayMissionDto {
  final int id;
  final int? roleId;
  final int? scenarioFlowIndex;
  final List<SudaJson>? mission;

  const RoleplayMissionDto({
    required this.id,
    this.roleId,
    this.scenarioFlowIndex,
    this.mission,
  });

  factory RoleplayMissionDto.fromJson(Map<String, dynamic> json) {
    return RoleplayMissionDto(
      id: _optionalInt(json['id']) ?? 0,
      roleId: _optionalInt(json['roleId']),
      scenarioFlowIndex: _optionalInt(json['scenarioFlowIndex']),
      mission: json['mission'] == null
          ? null
          : (json['mission'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ExpressionUpgradeDto {
  final String? expression;
  final String? meaningUserLanguage;
  final String? rephrasedSentence;

  const ExpressionUpgradeDto({
    this.expression,
    this.meaningUserLanguage,
    this.rephrasedSentence,
  });

  factory ExpressionUpgradeDto.fromJson(Map<String, dynamic> json) {
    return ExpressionUpgradeDto(
      expression: json['expression'] as String?,
      meaningUserLanguage: json['meaningUserLanguage'] as String?,
      rephrasedSentence: json['rephrasedSentence'] as String?,
    );
  }
}

/// `GET /v1/users/expressions?pageNum=...` 응답 원소
class UserExpressionDto {
  final int? id;
  final int? userId;
  final int? roleplayResultId;
  final int? expressionIndex;
  final String? expression;
  final String? meaningUserLanguage;
  final String? rephrasedSentence;
  final String? createdAt;

  const UserExpressionDto({
    this.id,
    this.userId,
    this.roleplayResultId,
    this.expressionIndex,
    this.expression,
    this.meaningUserLanguage,
    this.rephrasedSentence,
    this.createdAt,
  });

  factory UserExpressionDto.fromJson(Map<String, dynamic> json) {
    return UserExpressionDto(
      id: _optionalInt(json['id']),
      userId: _optionalInt(json['userId']),
      roleplayResultId: _optionalInt(json['roleplayResultId']),
      expressionIndex: _optionalInt(json['expressionIndex']),
      expression: json['expression'] as String?,
      meaningUserLanguage: json['meaningUserLanguage'] as String?,
      rephrasedSentence: json['rephrasedSentence'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class RoleplayResultDto {
  final int? id;
  final int? version;
  final int? userId;
  final int? roleplayId;
  final int? roleplayRoleId;
  final int? endingId;
  final List<SudaJson>? chatHistory;
  final String? completeYn;
  final List<int>? completedMissionIds;
  final String? missionResult;
  final int? starResult;
  final int? words;
  final String? goodFeedback;
  final String? improvementFeedback;
  final String? overallFeedback;
  final List<ExpressionUpgradeDto>? expressionUpgrades;
  final List<int>? savedExpressionIndexes;
  final int? beforeLikePoint;
  final int? afterLikePoint;
  final int? likePoint;
  final String? likePointReceivedYn;
  final int? star;
  final String? createdAt;
  final String? mainTitle; // non-null on server
  final String? subTitle; // non-null on server
  final String? avatarImgPath;
  final int? beforeLevel;
  final int? beforeProgressPercentage;
  final int? afterLevel;
  final int? afterProgressPercentage;

  const RoleplayResultDto({
    this.id,
    this.version,
    this.userId,
    this.roleplayId,
    this.roleplayRoleId,
    this.endingId,
    this.chatHistory,
    this.completeYn,
    this.completedMissionIds,
    this.missionResult,
    this.starResult,
    this.words,
    this.goodFeedback,
    this.improvementFeedback,
    this.overallFeedback,
    this.expressionUpgrades,
    this.savedExpressionIndexes,
    this.beforeLikePoint,
    this.afterLikePoint,
    this.likePoint,
    this.likePointReceivedYn,
    this.star,
    this.createdAt,
    this.mainTitle,
    this.subTitle,
    this.avatarImgPath,
    this.beforeLevel,
    this.beforeProgressPercentage,
    this.afterLevel,
    this.afterProgressPercentage,
  });

  factory RoleplayResultDto.fromJson(Map<String, dynamic> json) {
    return RoleplayResultDto(
      id: _optionalInt(json['id']),
      version: _optionalInt(json['version']),
      userId: _optionalInt(json['userId']),
      roleplayId: _optionalInt(json['roleplayId']),
      roleplayRoleId: _optionalInt(json['roleplayRoleId']),
      endingId: _optionalInt(json['endingId']),
      chatHistory: json['chatHistory'] == null
          ? null
          : (json['chatHistory'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      completeYn: json['completeYn'] as String?,
      completedMissionIds: json['completedMissionIds'] == null
          ? null
          : (json['completedMissionIds'] as List<dynamic>)
              .map((e) => _optionalInt(e) ?? 0)
              .toList(),
      missionResult: json['missionResult'] as String?,
      starResult: _optionalInt(json['starResult']),
      words: _optionalInt(json['words']),
      goodFeedback: json['goodFeedback'] as String?,
      improvementFeedback: json['improvementFeedback'] as String?,
      overallFeedback: json['overallFeedback'] as String?,
      expressionUpgrades: json['expressionUpgrades'] == null
          ? null
          : (json['expressionUpgrades'] as List<dynamic>)
              .map(
                (item) => ExpressionUpgradeDto.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      savedExpressionIndexes: json['savedExpressionIndexes'] == null
          ? null
          : (json['savedExpressionIndexes'] as List<dynamic>)
              .map((e) => _optionalInt(e))
              .whereType<int>()
              .toList(),
      beforeLikePoint: _optionalInt(json['beforeLikePoint']),
      afterLikePoint: _optionalInt(json['afterLikePoint']),
      likePoint: _optionalInt(json['likePoint']),
      likePointReceivedYn: json['likePointReceivedYn'] as String?,
      star: _optionalInt(json['star']),
      createdAt: json['createdAt'] as String?,
      mainTitle: json['mainTitle'] as String?,
      subTitle: json['subTitle'] as String?,
      avatarImgPath: json['avatarImgPath'] as String?,
      beforeLevel: _optionalInt(json['beforeLevel']),
      beforeProgressPercentage: _optionalInt(json['beforeProgressPercentage']),
      afterLevel: _optionalInt(json['afterLevel']),
      afterProgressPercentage: _optionalInt(json['afterProgressPercentage']),
    );
  }
}

/// GET /v1/roleplays/results 페이징 응답의 content 항목
class RpSimpleResultDto {
  final int? resultId;
  final int? version;
  final String? imgPath;
  final int? starResult;
  final String? createdAt;

  const RpSimpleResultDto({
    this.resultId,
    this.version,
    this.imgPath,
    this.starResult,
    this.createdAt,
  });

  factory RpSimpleResultDto.fromJson(Map<String, dynamic> json) {
    return RpSimpleResultDto(
      resultId: _optionalInt(json['resultId']),
      version: _optionalInt(json['version']),
      imgPath: json['imgPath'] as String?,
      starResult: _optionalInt(json['starResult']),
      createdAt: json['createdAt'] as String?,
    );
  }
}
