import 'common_models.dart';

/// GET /v1/users/ticket 응답
class UserTicketDto {
  final int beforeTicketCount;
  final int finalTicketCount;
  final String? dailyTicketGrantYn;

  const UserTicketDto({
    required this.beforeTicketCount,
    required this.finalTicketCount,
    this.dailyTicketGrantYn,
  });

  factory UserTicketDto.fromJson(Map<String, dynamic> json) {
    return UserTicketDto(
      beforeTicketCount: json['beforeTicketCount'] as int? ?? 0,
      finalTicketCount: json['finalTicketCount'] as int? ?? 0,
      dailyTicketGrantYn: json['dailyTicketGrantYn'] as String?,
    );
  }
}

/// PUT /v1/users/push-agreement 응답
class QuestResultDto {
  final String completeYn;

  const QuestResultDto({
    required this.completeYn,
  });

  factory QuestResultDto.fromJson(Map<String, dynamic> json) {
    return QuestResultDto(
      completeYn: json['completeYn'] as String? ?? 'N',
    );
  }
}

class ProfileDto {
  final UserDto userDto;
  final int currentLevel;
  final double progressPercentage;

  const ProfileDto({
    required this.userDto,
    required this.currentLevel,
    required this.progressPercentage,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    return ProfileDto(
      userDto: UserDto.fromJson(json['userDto'] as Map<String, dynamic>),
      currentLevel: json['currentLevel'] as int? ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class UserDto {
  final int id;
  final String? provider;
  final String? sub;
  final String? name;
  final String? email;
  final String? profileImgUrl;
  final int? roleplayCount;
  final int? wordsSpokenCount;
  final int? likePoint;
  final String? firstLoginYn;
  final String? createdAt;
  final String? updatedAt;
  final List<SudaJson>? metaInfo;

  const UserDto({
    required this.id,
    this.provider,
    this.sub,
    this.name,
    this.email,
    this.profileImgUrl,
    this.roleplayCount,
    this.wordsSpokenCount,
    this.likePoint,
    this.firstLoginYn,
    this.createdAt,
    this.updatedAt,
    this.metaInfo,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int? ?? 0,
      provider: json['provider'] as String?,
      sub: json['sub'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImgUrl: json['profileImgUrl'] as String?,
      roleplayCount: json['roleplayCount'] as int?,
      wordsSpokenCount: json['wordsSpokenCount'] as int?,
      likePoint: json['likePoint'] as int?,
      firstLoginYn: json['firstLoginYn'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      metaInfo: json['metaInfo'] == null
          ? null
          : (json['metaInfo'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }

  UserDto copyWith({
    int? id,
    String? provider,
    String? sub,
    String? name,
    String? email,
    String? profileImgUrl,
    int? roleplayCount,
    int? wordsSpokenCount,
    int? likePoint,
    String? firstLoginYn,
    String? createdAt,
    String? updatedAt,
    List<SudaJson>? metaInfo,
  }) {
    return UserDto(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      sub: sub ?? this.sub,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      roleplayCount: roleplayCount ?? this.roleplayCount,
      wordsSpokenCount: wordsSpokenCount ?? this.wordsSpokenCount,
      likePoint: likePoint ?? this.likePoint,
      firstLoginYn: firstLoginYn ?? this.firstLoginYn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metaInfo: metaInfo ?? this.metaInfo,
    );
  }
}

class NotificationDto {
  final int id;
  final List<SudaJson>? title;
  final List<SudaJson>? content;
  final String? imgPath;
  final String? appPath;
  final String? sendFinishedAt;

  const NotificationDto({
    required this.id,
    this.title,
    this.content,
    this.imgPath,
    this.appPath,
    this.sendFinishedAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as int? ?? 0,
      title: (json['title'] as List<dynamic>?)
          ?.map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList(),
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList(),
      imgPath: json['imgPath'] as String?,
      appPath: json['appPath'] as String?,
      sendFinishedAt: json['sendFinishedAt'] as String?,
    );
  }
}
