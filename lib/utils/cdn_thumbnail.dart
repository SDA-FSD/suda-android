import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

import '../config/app_config.dart';

/// CDN 파생 썸네일 크기. 파일명 `{stem}_{size}.{ext}` (`_150` / `_500` 예정).
enum CdnThumbSize {
  original,
  w150,
  w300,
  w500;

  String? get suffix {
    switch (this) {
      case CdnThumbSize.original:
        return null;
      case CdnThumbSize.w150:
        return '_150';
      case CdnThumbSize.w300:
        return '_300';
      case CdnThumbSize.w500:
        return '_500';
    }
  }
}

/// 작은 썸네일 노출 슬롯. 크기 매핑만 바꾸고 호출부는 슬롯을 유지한다.
enum CdnThumbSlot {
  /// Home 카테고리 가로 행 (`HomeSeriesDto.thumbnailImgPath`).
  seriesRow(CdnThumbSize.w300),

  /// Series Overview Similar Topic 3열 (`HomeSeriesDto.thumbnailImgPath`).
  similarGrid(CdnThumbSize.w300),

  /// Series Overview Episode 탭 좌측 카드 (`RpS2SeriesEpisodeDto.thumbnailImgPath`).
  episodeCard(CdnThumbSize.w300),

  /// Profile 히스토리 그리드 (`RpS2SimpleHistoryDto.imgPath`). 프로필 아바타 아님.
  profileHistory(CdnThumbSize.w300),

  /// 배경 LQIP. 메모리 히트일 때만 사용하고 추가 GET 하지 않음.
  backdropPreview(CdnThumbSize.w300);

  const CdnThumbSlot(this.size);
  final CdnThumbSize size;
}

abstract final class CdnThumbUrl {
  static String original(String path) => '${AppConfig.cdnBaseUrl}$path';

  static String forSlot(String path, CdnThumbSlot slot) {
    return '${AppConfig.cdnBaseUrl}${sizedPath(path, slot.size)}';
  }

  /// `…/zj66s0.png` + [CdnThumbSize.w300] → `…/zj66s0_300.png`.
  /// 확장자 없거나 이미 같은 suffix면 [path] 그대로.
  static String sizedPath(String path, CdnThumbSize size) {
    final suffix = size.suffix;
    if (suffix == null) return path;
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return path;
    final slash = path.lastIndexOf('/');
    if (slash >= dot) return path;
    final stem = path.substring(0, dot);
    if (stem.endsWith(suffix)) return path;
    return '$stem$suffix${path.substring(dot)}';
  }

  /// [ImageCache]에 해당 URL이 있으면 true. 디스크 조회·네트워크 없음.
  static bool isInMemory(String url) {
    return PaintingBinding.instance.imageCache.containsKey(
      CachedNetworkImageProvider(url),
    );
  }
}
