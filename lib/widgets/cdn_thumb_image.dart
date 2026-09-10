import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/cdn_thumbnail.dart';

export '../utils/cdn_thumbnail.dart';

/// 작은 노출용. 슬롯 사이즈 URL을 먼저 로드하고 실패 시 원본.
class CdnThumbImage extends StatelessWidget {
  final String path;
  final CdnThumbSlot slot;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ImageWidgetBuilder? imageBuilder;

  const CdnThumbImage({
    super.key,
    required this.path,
    required this.slot,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final originalUrl = CdnThumbUrl.original(path);
    final sizedUrl = CdnThumbUrl.forSlot(path, slot);
    return _CdnNetworkImage(
      url: sizedUrl,
      fallbackUrl: sizedUrl == originalUrl ? null : originalUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      placeholder: placeholder,
      errorWidget: errorWidget,
      imageBuilder: imageBuilder,
    );
  }
}

/// 배경용. 최종은 원본. 메모리에 원본이 있으면 즉시 원본,
/// 없으면 `_300`이 메모리에 있을 때만 placeholder로 쓰고 원본 도착 즉시 교체.
/// `_300` 추가 GET 없음.
class CdnProgressiveNetworkImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  const CdnProgressiveNetworkImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final originalUrl = CdnThumbUrl.original(path);
    if (CdnThumbUrl.isInMemory(originalUrl)) {
      return Image(
        image: CachedNetworkImageProvider(originalUrl),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
      );
    }

    final thumbUrl = CdnThumbUrl.forSlot(path, CdnThumbSlot.backdropPreview);
    final thumbInMemory =
        thumbUrl != originalUrl && CdnThumbUrl.isInMemory(thumbUrl);

    return CachedNetworkImage(
      imageUrl: originalUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) {
        if (thumbInMemory) {
          return Image(
            image: CachedNetworkImageProvider(thumbUrl),
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            gaplessPlayback: true,
          );
        }
        return placeholder?.call(context, url) ?? const SizedBox.shrink();
      },
      errorWidget: errorWidget,
    );
  }
}

class _CdnNetworkImage extends StatelessWidget {
  final String url;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ImageWidgetBuilder? imageBuilder;

  const _CdnNetworkImage({
    required this.url,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit,
    required this.alignment,
    required this.fadeInDuration,
    required this.fadeOutDuration,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      imageBuilder: imageBuilder,
      placeholder: placeholder,
      errorWidget: fallbackUrl == null
          ? errorWidget
          : (context, url, error) => _CdnNetworkImage(
                url: fallbackUrl!,
                width: width,
                height: height,
                fit: fit,
                alignment: alignment,
                fadeInDuration: fadeInDuration,
                fadeOutDuration: fadeOutDuration,
                placeholder: placeholder,
                errorWidget: errorWidget,
                imageBuilder: imageBuilder,
              ),
    );
  }
}
