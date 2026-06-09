import 'common_models.dart';

Map<String, String> _localizedMapFromJson(dynamic value) {
  if (value == null) return const {};
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
    );
  }
  return const {};
}

/// GET /v2/home/contents 응답 DTO
class HomeDto {
  final String restYn;
  final DateTime? restStartsAt;
  final DateTime? restEndsAt;
  final String notiboxUnreadYn;
  final List<MainHomeBannerDto> banners;
  final List<HomeSeriesGroupDto> seriesList;

  const HomeDto({
    required this.restYn,
    this.restStartsAt,
    this.restEndsAt,
    this.notiboxUnreadYn = 'N',
    required this.banners,
    required this.seriesList,
  });

  factory HomeDto.fromJson(Map<String, dynamic> json) {
    final restYn = sudaYnFromJson(json['restYn']);
    final notiboxUnreadYn = sudaYnFromJson(
      json['notiboxUnreadYn'] ?? json['notibox_unread_yn'],
    );

    DateTime? parseInstant(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final bannersRaw = json['banners'];
    final List<MainHomeBannerDto> banners = bannersRaw == null
        ? []
        : (bannersRaw as List<dynamic>)
              .map(
                (item) =>
                    MainHomeBannerDto.fromJson(item as Map<String, dynamic>),
              )
              .toList();

    final seriesListRaw = json['seriesList'];
    final List<HomeSeriesGroupDto> seriesList = seriesListRaw == null
        ? []
        : (seriesListRaw as List<dynamic>)
              .map(
                (item) => HomeSeriesGroupDto.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

    return HomeDto(
      restYn: restYn,
      restStartsAt: parseInstant(json['restStartsAt']),
      restEndsAt: parseInstant(json['restEndsAt']),
      notiboxUnreadYn: notiboxUnreadYn,
      banners: banners,
      seriesList: seriesList,
    );
  }
}

class MainHomeBannerDto {
  final String imgPath;
  final List<SudaJson> overlayText;
  final String? appPath;

  const MainHomeBannerDto({
    required this.imgPath,
    required this.overlayText,
    this.appPath,
  });

  factory MainHomeBannerDto.fromJson(Map<String, dynamic> json) {
    return MainHomeBannerDto(
      imgPath: json['imgPath'] as String? ?? '',
      overlayText: json['overlayText'] == null
          ? []
          : (json['overlayText'] as List<dynamic>)
                .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
                .toList(),
      appPath: json['appPath'] as String?,
    );
  }
}

class HomeCategoryDto {
  final String enumValue;
  final Map<String, String> name;

  const HomeCategoryDto({
    required this.enumValue,
    required this.name,
  });

  factory HomeCategoryDto.fromJson(Map<String, dynamic> json) {
    return HomeCategoryDto(
      enumValue: json['enumValue'] as String? ?? '',
      name: _localizedMapFromJson(json['name']),
    );
  }
}

class HomeSeriesDto {
  final int id;
  final Map<String, String> title;
  final String? thumbnailImgPath;

  const HomeSeriesDto({
    required this.id,
    required this.title,
    this.thumbnailImgPath,
  });

  factory HomeSeriesDto.fromJson(Map<String, dynamic> json) {
    return HomeSeriesDto(
      id: json['id'] as int? ?? 0,
      title: _localizedMapFromJson(json['title']),
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
    );
  }
}

class HomeSeriesGroupDto {
  final HomeCategoryDto category;
  final List<HomeSeriesDto> seriesList;

  const HomeSeriesGroupDto({
    required this.category,
    required this.seriesList,
  });

  factory HomeSeriesGroupDto.fromJson(Map<String, dynamic> json) {
    return HomeSeriesGroupDto(
      category: HomeCategoryDto.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      seriesList: json['seriesList'] == null
          ? []
          : (json['seriesList'] as List<dynamic>)
                .map(
                  (item) =>
                      HomeSeriesDto.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
    );
  }
}
