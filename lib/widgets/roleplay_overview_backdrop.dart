import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'cdn_thumb_image.dart';

/// Overview 상단과 동일한 CDN URL로 `CachedNetworkImage` 디스크 캐시를 재사용하는 롤플레이 전면 배경.
///
/// 논리 높이 100% · [BoxFit.fitHeight] · 가로 중앙(좌우 크롭). 블러·딤은 Opening/Playing 공통.
/// 최종은 원본. 메모리의 `_300`이 있으면 먼저 노출하고 원본 도착 즉시 교체.
const double kRoleplayOverviewBackdropBlurSigma = 10;
const Color kRoleplayOverviewBackdropDim = Color(0x99000000);
const double kRoleplayOverviewBackdropImageScale = 1.06;

class RoleplayOverviewBackdrop extends StatelessWidget {
  final String imagePath;

  const RoleplayOverviewBackdrop({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final memH = (h * MediaQuery.of(context).devicePixelRatio).round();

    return ColoredBox(
      color: const Color(0xFF121212),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: kRoleplayOverviewBackdropImageScale,
              alignment: Alignment.center,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: kRoleplayOverviewBackdropBlurSigma,
                  sigmaY: kRoleplayOverviewBackdropBlurSigma,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: h,
                    child: CdnProgressiveNetworkImage(
                      path: imagePath,
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.center,
                      memCacheHeight: memH,
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) =>
                          const ColoredBox(color: Color(0xFF121212)),
                    ),
                  ),
                ),
              ),
            ),
            const ColoredBox(color: kRoleplayOverviewBackdropDim),
          ],
        ),
      ),
    );
  }
}
