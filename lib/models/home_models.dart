import 'common_models.dart';

class MainHomeBannerDto {
  final String imgPath;
  final List<SudaJson> overlayText;

  const MainHomeBannerDto({
    required this.imgPath,
    required this.overlayText,
  });

  factory MainHomeBannerDto.fromJson(Map<String, dynamic> json) {
    return MainHomeBannerDto(
      imgPath: json['imgPath'] as String? ?? '',
      overlayText: json['overlayText'] == null
          ? []
          : (json['overlayText'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class RoleplayCategoryDto {
  final int id;
  final List<SudaJson> name;

  const RoleplayCategoryDto({
    required this.id,
    required this.name,
  });

  factory RoleplayCategoryDto.fromJson(Map<String, dynamic> json) {
    final nameValue = json['name'];
    final List<SudaJson> names;
    if (nameValue is String) {
      names = [SudaJson(key: 'en', value: nameValue)];
    } else if (nameValue is List<dynamic>) {
      names = nameValue
          .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      names = [];
    }
    return RoleplayCategoryDto(
      id: json['id'] as int? ?? 0,
      name: names,
    );
  }
}

class AppHomeRoleplayDto {
  final int id;
  final int? categoryId;
  final List<SudaJson> title;
  final String? thumbnailImgPath;
  final String? bannerImgPath;
  final String? bannerColor;
  final int? roleplayCategoryId;
  final int? order;

  const AppHomeRoleplayDto({
    required this.id,
    this.categoryId,
    required this.title,
    this.thumbnailImgPath,
    this.bannerImgPath,
    this.bannerColor,
    this.roleplayCategoryId,
    this.order,
  });

  factory AppHomeRoleplayDto.fromJson(Map<String, dynamic> json) {
    return AppHomeRoleplayDto(
      id: json['id'] as int? ?? 0,
      categoryId: json['categoryId'] as int?,
      title: json['title'] == null
          ? []
          : (json['title'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
      bannerImgPath: json['bannerImgPath'] as String?,
      bannerColor: json['bannerColor'] as String?,
      roleplayCategoryId: json['roleplayCategoryId'] as int?,
      order: json['order'] as int?,
    );
  }
}

class AppHomeRoleplayGroupDto {
  final RoleplayCategoryDto roleplayCategoryDto;
  final List<AppHomeRoleplayDto> list;

  const AppHomeRoleplayGroupDto({
    required this.roleplayCategoryDto,
    required this.list,
  });

  factory AppHomeRoleplayGroupDto.fromJson(Map<String, dynamic> json) {
    return AppHomeRoleplayGroupDto(
      roleplayCategoryDto:
          RoleplayCategoryDto.fromJson(json['roleplayCategoryDto'] as Map<String, dynamic>),
      list: json['list'] == null
          ? []
          : (json['list'] as List<dynamic>)
              .map((item) => AppHomeRoleplayDto.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}
