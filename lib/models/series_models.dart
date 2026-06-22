import 'dart:convert';
import 'dart:typed_data';

import '../utils/suda_json_util.dart';

/// GET /rps2/series/{seriesId}/overview 응답 DTO
class RpS2SeriesOverviewDto {
  final int id;
  final Map<String, String> title;
  final String? category;
  final String? synopsisComplexityLevel;
  final Map<String, String> synopsis;
  final String? thumbnailImgPath;
  final RpS2CharacterDto? userCharacter;
  final Map<String, String> endingTitle;
  final Map<String, String> endingContent;
  final String? endingImgPath;
  final List<RpS2SeriesEpisodeDto> episodes;
  final Map<int, int> bestScoreMap;

  const RpS2SeriesOverviewDto({
    required this.id,
    required this.title,
    this.category,
    this.synopsisComplexityLevel,
    required this.synopsis,
    this.thumbnailImgPath,
    this.userCharacter,
    required this.endingTitle,
    required this.endingContent,
    this.endingImgPath,
    required this.episodes,
    required this.bestScoreMap,
  });

  factory RpS2SeriesOverviewDto.fromJson(Map<String, dynamic> json) {
    final episodesRaw = json['episodes'];
    final List<RpS2SeriesEpisodeDto> episodes = episodesRaw == null
        ? []
        : (episodesRaw as List<dynamic>)
              .map(
                (item) =>
                    RpS2SeriesEpisodeDto.fromJson(item as Map<String, dynamic>),
              )
              .toList();

    return RpS2SeriesOverviewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: SudaJsonUtil.localizedMapFromJson(json['title']),
      category: json['category'] as String?,
      synopsisComplexityLevel: json['synopsisComplexityLevel'] as String?,
      synopsis: SudaJsonUtil.localizedMapFromJson(json['synopsis']),
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
      userCharacter: json['userCharacter'] == null
          ? null
          : RpS2CharacterDto.fromJson(
              json['userCharacter'] as Map<String, dynamic>,
            ),
      endingTitle: SudaJsonUtil.localizedMapFromJson(json['endingTitle']),
      endingContent: SudaJsonUtil.localizedMapFromJson(json['endingContent']),
      endingImgPath: json['endingImgPath'] as String?,
      episodes: episodes,
      bestScoreMap: bestScoreMapFromJson(json['bestScoreMap']),
    );
  }

  RpS2SeriesOverviewDto copyWith({Map<int, int>? bestScoreMap}) {
    return RpS2SeriesOverviewDto(
      id: id,
      title: title,
      category: category,
      synopsisComplexityLevel: synopsisComplexityLevel,
      synopsis: synopsis,
      thumbnailImgPath: thumbnailImgPath,
      userCharacter: userCharacter,
      endingTitle: endingTitle,
      endingContent: endingContent,
      endingImgPath: endingImgPath,
      episodes: episodes,
      bestScoreMap: bestScoreMap ?? this.bestScoreMap,
    );
  }
}

class RpS2SeriesEpisodeDto {
  final int id;
  final Map<String, String> title;
  final Map<String, String> summary;
  final Map<String, String> briefing;
  final Map<String, String> learningFunction;
  final String? thumbnailImgPath;
  final RpS2CharacterDto? aiCharacter;
  final Map<String, RpS2CefrDto> cefrMap;

  const RpS2SeriesEpisodeDto({
    required this.id,
    required this.title,
    required this.summary,
    required this.briefing,
    required this.learningFunction,
    this.thumbnailImgPath,
    this.aiCharacter,
    this.cefrMap = const {},
  });

  factory RpS2SeriesEpisodeDto.fromJson(Map<String, dynamic> json) {
    return RpS2SeriesEpisodeDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: SudaJsonUtil.localizedMapFromJson(json['title']),
      summary: SudaJsonUtil.localizedMapFromJson(json['summary']),
      briefing: SudaJsonUtil.localizedMapFromJson(json['briefing']),
      learningFunction: SudaJsonUtil.localizedMapFromJson(
        json['learningFunction'],
      ),
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
      aiCharacter: json['aiCharacter'] == null
          ? null
          : RpS2CharacterDto.fromJson(
              json['aiCharacter'] as Map<String, dynamic>,
            ),
      cefrMap: _cefrMapFromJson(json['cefrMap']),
    );
  }
}

class RpS2CefrDto {
  final int? requiredSpeechCount;
  final String? startLine;
  final List<RpS2CefrMissionDto> missions;

  const RpS2CefrDto({
    this.requiredSpeechCount,
    this.startLine,
    this.missions = const [],
  });

  factory RpS2CefrDto.fromJson(Map<String, dynamic> json) {
    final missionsRaw = json['missions'];
    final List<RpS2CefrMissionDto> missions = missionsRaw == null
        ? []
        : (missionsRaw as List<dynamic>)
              .map(
                (item) =>
                    RpS2CefrMissionDto.fromJson(item as Map<String, dynamic>),
              )
              .toList();

    return RpS2CefrDto(
      requiredSpeechCount: (json['requiredSpeechCount'] as num?)?.toInt(),
      startLine: json['startLine'] as String?,
      missions: missions,
    );
  }
}

class RpS2CefrMissionDto {
  final Map<String, String> keyExpression;
  final Map<String, String> instruction;
  final Map<String, String> sampleAnswer;

  const RpS2CefrMissionDto({
    required this.keyExpression,
    required this.instruction,
    required this.sampleAnswer,
  });

  factory RpS2CefrMissionDto.fromJson(Map<String, dynamic> json) {
    return RpS2CefrMissionDto(
      keyExpression: SudaJsonUtil.localizedMapFromJson(json['keyExpression']),
      instruction: SudaJsonUtil.localizedMapFromJson(json['instruction']),
      sampleAnswer: SudaJsonUtil.localizedMapFromJson(json['sampleAnswer']),
    );
  }
}

class RpS2CharacterDto {
  final int? id;
  final String? name;
  final String? gender;
  final String? ageRange;
  final String? occupation;
  final String? personality;
  final String? speechStyle;
  final String? nationality;
  final String? rpImgPath;

  const RpS2CharacterDto({
    this.id,
    this.name,
    this.gender,
    this.ageRange,
    this.occupation,
    this.personality,
    this.speechStyle,
    this.nationality,
    this.rpImgPath,
  });

  factory RpS2CharacterDto.fromJson(Map<String, dynamic> json) {
    return RpS2CharacterDto(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      ageRange: json['ageRange'] as String?,
      occupation: json['occupation'] as String?,
      personality: json['personality'] as String?,
      speechStyle: json['speechStyle'] as String?,
      nationality: json['nationality'] as String?,
      rpImgPath: json['rpImgPath'] as String?,
    );
  }
}

Map<String, RpS2CefrDto> _cefrMapFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <String, RpS2CefrDto>{};
  raw.forEach((key, value) {
    if (value is! Map) return;
    result[key.toString()] = RpS2CefrDto.fromJson(
      Map<String, dynamic>.from(value),
    );
  });
  return result;
}

Map<int, int> bestScoreMapFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <int, int>{};
  raw.forEach((key, value) {
    final episodeId = int.tryParse(key.toString());
    if (episodeId == null) return;
    if (value is num) {
      result[episodeId] = value.toInt();
    }
  });
  return result;
}

/// `POST /rps2/sessions` 요청 DTO
class RpS2SessionRequestDto {
  final int seriesId;
  final int episodeId;

  const RpS2SessionRequestDto({
    required this.seriesId,
    required this.episodeId,
  });

  Map<String, dynamic> toJson() {
    return {'seriesId': seriesId, 'episodeId': episodeId};
  }
}

/// S2 세션 초기화 응답의 AI 사운드
class RpS2SoundResDto {
  final String? cdnYn;
  final String? cdnPath;
  final Uint8List? file;

  const RpS2SoundResDto({this.cdnYn, this.cdnPath, this.file});

  factory RpS2SoundResDto.fromJson(Map<String, dynamic> json) {
    return RpS2SoundResDto(
      cdnYn: json['cdnYn'] as String?,
      cdnPath: json['cdnPath'] as String?,
      file: _parseBytes(json['file']) ?? _parseBytes(json['sound']),
    );
  }
}

/// `GET /rps2/sessions/{rpSessionId}/hint/{rpMsgId}` 응답 DTO
class RpS2HintDto {
  final String? hint;
  final String? translatedHint;

  const RpS2HintDto({this.hint, this.translatedHint});

  factory RpS2HintDto.fromJson(Map<String, dynamic> json) {
    return RpS2HintDto(
      hint: json['hint'] as String?,
      translatedHint: json['translatedHint'] as String?,
    );
  }
}

/// `POST /rps2/sessions/{rpSessionId}/user-message/*` 응답 DTO.
class RpS2UserMessageResponseDto {
  final String? userText;
  final String? userGrade;
  final String? narration;
  final String? aiText;
  final int? missionCompletedIndex;
  final String? serviceMessage;

  const RpS2UserMessageResponseDto({
    this.userText,
    this.userGrade,
    this.narration,
    this.aiText,
    this.missionCompletedIndex,
    this.serviceMessage,
  });

  factory RpS2UserMessageResponseDto.fromJson(Map<String, dynamic> json) {
    return RpS2UserMessageResponseDto(
      userText: json['userText'] as String?,
      userGrade: json['userGrade'] as String?,
      narration: json['narration'] as String?,
      aiText: json['aiText'] as String?,
      missionCompletedIndex: _optionalInt(json['missionCompletedIndex']),
      serviceMessage: json['serviceMessage'] as String?,
    );
  }
}

/// `POST /rps2/sessions` 응답 DTO
class RpS2SessionDto {
  final String? sessionId;
  final RpS2SoundResDto? aiSound;

  const RpS2SessionDto({this.sessionId, this.aiSound});

  factory RpS2SessionDto.fromJson(Map<String, dynamic> json) {
    final raw = json['sessionId'];
    final sessionId = raw?.toString();
    return RpS2SessionDto(
      sessionId: sessionId,
      aiSound: _parseRpS2SoundRes(json['aiSound']),
    );
  }
}

RpS2SoundResDto? _parseRpS2SoundRes(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  return RpS2SoundResDto.fromJson(raw);
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

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// `GET /rps2/user-histories/{rpUserHistoryId}` 응답 DTO
class RpS2UserHistoryDto {
  final int? id;
  final int? userId;
  final int? seriesId;
  final int? episodeId;
  final int? episodeCefrId;
  final String? sessionId;
  final String? firstPlayYn;
  final String? status;
  final String? thumbnailImgPath;
  final List<RpS2UserHistoryMsgDto> messages;
  final Map<int, RpS2HintVo> hints;
  final Map<int, String> translations;
  final List<bool> missions;
  final int? starScore;
  final int? words;
  final int? likePoint;
  final List<RpS2KeyExpressionVo> keyExpressions;
  final Map<int, RpS2UserFeedbackVo> speechFeedback;
  final int? userStarRating;
  final String? createdAt;
  final String? updatedAt;
  final String? mainTitle;
  final String? subTitle;
  final String? avatarImgPath;
  final int? beforeLikePoint;
  final int? beforeLevel;
  final int? beforeProgressPercentage;
  final int? afterLikePoint;
  final int? afterLevel;
  final int? afterProgressPercentage;

  const RpS2UserHistoryDto({
    this.id,
    this.userId,
    this.seriesId,
    this.episodeId,
    this.episodeCefrId,
    this.sessionId,
    this.firstPlayYn,
    this.status,
    this.thumbnailImgPath,
    this.messages = const [],
    this.hints = const {},
    this.translations = const {},
    this.missions = const [],
    this.starScore,
    this.words,
    this.likePoint,
    this.keyExpressions = const [],
    this.speechFeedback = const {},
    this.userStarRating,
    this.createdAt,
    this.updatedAt,
    this.mainTitle,
    this.subTitle,
    this.avatarImgPath,
    this.beforeLikePoint,
    this.beforeLevel,
    this.beforeProgressPercentage,
    this.afterLikePoint,
    this.afterLevel,
    this.afterProgressPercentage,
  });

  factory RpS2UserHistoryDto.fromJson(Map<String, dynamic> json) {
    return RpS2UserHistoryDto(
      id: _optionalInt(json['id']),
      userId: _optionalInt(json['userId']),
      seriesId: _optionalInt(json['seriesId']),
      episodeId: _optionalInt(json['episodeId']),
      episodeCefrId: _optionalInt(json['episodeCefrId']),
      sessionId: json['sessionId']?.toString(),
      firstPlayYn: json['firstPlayYn'] as String?,
      status: json['status'] as String?,
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
      messages: _userHistoryMessagesFromJson(json['messages']),
      hints: _hintVoMapFromJson(json['hints']),
      translations: _intStringMapFromJson(json['translations']),
      missions: _boolListFromJson(json['missions']),
      starScore: _optionalInt(json['starScore']),
      words: _optionalInt(json['words']),
      likePoint: _optionalInt(json['likePoint']),
      keyExpressions: _keyExpressionsFromJson(json['keyExpressions']),
      speechFeedback: _speechFeedbackMapFromJson(json['speechFeedback']),
      userStarRating: _optionalInt(json['userStarRating']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      mainTitle: json['mainTitle'] as String?,
      subTitle: json['subTitle'] as String?,
      avatarImgPath: json['avatarImgPath'] as String?,
      beforeLikePoint: _optionalInt(json['beforeLikePoint']),
      beforeLevel: _optionalInt(json['beforeLevel']),
      beforeProgressPercentage: _optionalInt(json['beforeProgressPercentage']),
      afterLikePoint: _optionalInt(json['afterLikePoint']),
      afterLevel: _optionalInt(json['afterLevel']),
      afterProgressPercentage: _optionalInt(json['afterProgressPercentage']),
    );
  }
}

class RpS2UserHistoryMsgDto {
  final int? id;
  final String? role;
  final String? content;
  final int? prepareTextStartedAt;
  final int? prepareTextEndedAt;
  final int? prepareAudioStartedAt;
  final int? prepareAudioEndedAt;
  final int? deliveredAt;
  final String? audioInputYn;
  final String? audioPath;

  const RpS2UserHistoryMsgDto({
    this.id,
    this.role,
    this.content,
    this.prepareTextStartedAt,
    this.prepareTextEndedAt,
    this.prepareAudioStartedAt,
    this.prepareAudioEndedAt,
    this.deliveredAt,
    this.audioInputYn,
    this.audioPath,
  });

  factory RpS2UserHistoryMsgDto.fromJson(Map<String, dynamic> json) {
    return RpS2UserHistoryMsgDto(
      id: _optionalInt(json['id']),
      role: json['role']?.toString(),
      content: json['content'] as String?,
      prepareTextStartedAt: _optionalInt(json['prepareTextStartedAt']),
      prepareTextEndedAt: _optionalInt(json['prepareTextEndedAt']),
      prepareAudioStartedAt: _optionalInt(json['prepareAudioStartedAt']),
      prepareAudioEndedAt: _optionalInt(json['prepareAudioEndedAt']),
      deliveredAt: _optionalInt(json['deliveredAt']),
      audioInputYn: json['audioInputYn'] as String?,
      audioPath: json['audioPath'] as String?,
    );
  }
}

class RpS2HintVo {
  final String? hint;
  final String? translatedHint;
  final Set<int> soundHistorySet;
  final String? deliveredYn;

  const RpS2HintVo({
    this.hint,
    this.translatedHint,
    this.soundHistorySet = const {},
    this.deliveredYn,
  });

  factory RpS2HintVo.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['soundHistorySet'];
    final Set<int> soundHistorySet;
    if (rawHistory is List) {
      soundHistorySet = rawHistory
          .map((item) => _optionalInt(item))
          .whereType<int>()
          .toSet();
    } else {
      soundHistorySet = const {};
    }
    return RpS2HintVo(
      hint: json['hint'] as String?,
      translatedHint: json['translatedHint'] as String?,
      soundHistorySet: soundHistorySet,
      deliveredYn: json['deliveredYn'] as String?,
    );
  }
}

class RpS2KeyExpressionVo {
  final Map<String, String> keyExpression;
  final Map<String, String> sampleAnswer;

  const RpS2KeyExpressionVo({
    required this.keyExpression,
    required this.sampleAnswer,
  });

  factory RpS2KeyExpressionVo.fromJson(Map<String, dynamic> json) {
    return RpS2KeyExpressionVo(
      keyExpression: SudaJsonUtil.localizedMapFromJson(json['keyExpression']),
      sampleAnswer: SudaJsonUtil.localizedMapFromJson(json['sampleAnswer']),
    );
  }
}

class RpS2UserFeedbackVo {
  final String? grade;
  final RpS2ScoreVo? score;
  final String? feedback;

  const RpS2UserFeedbackVo({this.grade, this.score, this.feedback});

  factory RpS2UserFeedbackVo.fromJson(Map<String, dynamic> json) {
    return RpS2UserFeedbackVo(
      grade: json['grade'] as String?,
      score: json['score'] == null
          ? null
          : RpS2ScoreVo.fromJson(json['score'] as Map<String, dynamic>),
      feedback: json['feedback'] as String?,
    );
  }
}

class RpS2ScoreVo {
  final String? meaning;
  final String? relevance;
  final String? vocabulary;
  final String? grammar;

  const RpS2ScoreVo({
    this.meaning,
    this.relevance,
    this.vocabulary,
    this.grammar,
  });

  factory RpS2ScoreVo.fromJson(Map<String, dynamic> json) {
    return RpS2ScoreVo(
      meaning: json['meaning'] as String?,
      relevance: json['relevance'] as String?,
      vocabulary: json['vocabulary'] as String?,
      grammar: json['grammar'] as String?,
    );
  }
}

List<RpS2UserHistoryMsgDto> _userHistoryMessagesFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (item) => RpS2UserHistoryMsgDto.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

Map<int, RpS2HintVo> _hintVoMapFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <int, RpS2HintVo>{};
  raw.forEach((key, value) {
    final intKey = int.tryParse(key.toString());
    if (intKey == null || value is! Map) return;
    result[intKey] = RpS2HintVo.fromJson(Map<String, dynamic>.from(value));
  });
  return result;
}

Map<int, String> _intStringMapFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <int, String>{};
  raw.forEach((key, value) {
    final intKey = int.tryParse(key.toString());
    if (intKey == null || value == null) return;
    result[intKey] = value.toString();
  });
  return result;
}

List<bool> _boolListFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item == true).toList();
}

List<RpS2KeyExpressionVo> _keyExpressionsFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map(
        (item) => RpS2KeyExpressionVo.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}

Map<int, RpS2UserFeedbackVo> _speechFeedbackMapFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  final result = <int, RpS2UserFeedbackVo>{};
  raw.forEach((key, value) {
    final intKey = int.tryParse(key.toString());
    if (intKey == null || value is! Map) return;
    result[intKey] = RpS2UserFeedbackVo.fromJson(
      Map<String, dynamic>.from(value),
    );
  });
  return result;
}
