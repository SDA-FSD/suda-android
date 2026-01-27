import 'common_models.dart';

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
}
