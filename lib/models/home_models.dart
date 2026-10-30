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

/// GET /v3/home/contents 응답 DTO
class HomeDto {
  final String restYn;
  final DateTime? restStartsAt;
  final DateTime? restEndsAt;
  final String notiboxUnreadYn;
  final String rankBadgeYn;
  final String profileBadgeYn;
  final List<MainHomeBannerDto> banners;
  final List<HomeSeriesGroupDto> seriesList;
  final HomeFirstRpRecommendDto? firstRpRecommend;

  const HomeDto({
    required this.restYn,
    this.restStartsAt,
    this.restEndsAt,
    this.notiboxUnreadYn = 'N',
    this.rankBadgeYn = 'N',
    this.profileBadgeYn = 'N',
    required this.banners,
    required this.seriesList,
    this.firstRpRecommend,
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
      rankBadgeYn: sudaYnFromJson(json['rankBadgeYn']),
      profileBadgeYn: sudaYnFromJson(json['profileBadgeYn']),
      banners: banners,
      seriesList: seriesList,
      firstRpRecommend: HomeFirstRpRecommendDto.fromJson(
        json['firstRpRecommend'],
      ),
    );
  }
}

/// 첫 롤플레이 추천 팝업. 이력 없거나 노출 시리즈가 아니면 서버가 필드를 비운다.
class HomeFirstRpRecommendDto {
  final int seriesId;
  final String? thumbnailImgPath;
  final Map<String, String> title;
  final HomeCategoryDto? category;
  final String? synopsisComplexityLevel;
  final String localizedTitleShowYn;
  final double titleBoxLeft;
  final double titleBoxTop;
  final double titleBoxWidth;

  const HomeFirstRpRecommendDto({
    required this.seriesId,
    this.thumbnailImgPath,
    required this.title,
    this.category,
    this.synopsisComplexityLevel,
    this.localizedTitleShowYn = 'N',
    this.titleBoxLeft = 0,
    this.titleBoxTop = 0,
    this.titleBoxWidth = 0,
  });

  static HomeFirstRpRecommendDto? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final seriesId = (json['seriesId'] as num?)?.toInt();
    if (seriesId == null) return null;
    final categoryRaw = json['category'];
    return HomeFirstRpRecommendDto(
      seriesId: seriesId,
      thumbnailImgPath: json['thumbnailImgPath'] as String?,
      title: _localizedMapFromJson(json['title']),
      category: categoryRaw is Map
          ? HomeCategoryDto.fromJson(Map<String, dynamic>.from(categoryRaw))
          : null,
      synopsisComplexityLevel: json['synopsisComplexityLevel'] as String?,
      localizedTitleShowYn: json['localizedTitleShowYn'] == 'Y' ? 'Y' : 'N',
      titleBoxLeft: (json['titleBoxLeft'] as num?)?.toDouble() ?? 0,
      titleBoxTop: (json['titleBoxTop'] as num?)?.toDouble() ?? 0,
      titleBoxWidth: (json['titleBoxWidth'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// GET /v3/home/badges 응답. 랭킹·프로필 GNB 점만.
class GnbBadgeDto {
  final String rankBadgeYn;
  final String profileBadgeYn;

  const GnbBadgeDto({
    this.rankBadgeYn = 'N',
    this.profileBadgeYn = 'N',
  });

  factory GnbBadgeDto.fromJson(Map<String, dynamic> json) {
    return GnbBadgeDto(
      rankBadgeYn: sudaYnFromJson(json['rankBadgeYn']),
      profileBadgeYn: sudaYnFromJson(json['profileBadgeYn']),
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
