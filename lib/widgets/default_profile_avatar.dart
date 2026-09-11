import 'package:flutter/material.dart';

/// 단색 원형 배경 위에 smile 마스크를 중앙에 올리는 기본 프로필 아바타.
///
/// 마스크는 원 지름 대비 [maskScale] 배(기본 0.35)로, 가로·세로 중앙 정렬한다.
class DefaultProfileAvatar extends StatelessWidget {
  static const defaultMaskAsset = 'assets/images/smile_layer.png';
  static const defaultMaskScale = 0.35;

  /// 원 지름(가로·세로).
  final double size;
  final Color color;
  final String maskAsset;

  /// 원 지름 대비 마스크 한 변 비율 (0–1).
  final double maskScale;

  const DefaultProfileAvatar({
    super.key,
    required this.size,
    required this.color,
    this.maskAsset = defaultMaskAsset,
    this.maskScale = defaultMaskScale,
  });

  @override
  Widget build(BuildContext context) {
    final maskSize = size * maskScale;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.expand(),
          ),
          SizedBox(
            width: maskSize,
            height: maskSize,
            child: Image.asset(
              maskAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
  }
}
