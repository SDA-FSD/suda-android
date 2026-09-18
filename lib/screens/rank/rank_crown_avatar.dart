import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 랭킹 프로필 프레임 스타일 (포디움·리스트·Claim 공용).
enum RankProfileFrameStyle { winner, premium, free, podiumFree, claimRunnerUp }

/// 왕관+원형 아바타 그룹. 좌표·비율은 동결 — [scale]만 곱한다.
///
/// 기준값 (포디움 `_PodiumSlot`과 동일):
/// - avatarOuter 114, borderW 3.8
/// - crownW 154.77, crownH 118.33
/// - crownLeftOnAvatar -0.31, crownTopOnAvatar -59
class RankCrownAvatar extends StatelessWidget {
  const RankCrownAvatar({
    super.key,
    required this.scale,
    required this.imgPath,
    required this.frameStyle,
    required this.defaultAsset,
    required this.crownAsset,
    this.showCrown = true,
    this.level,
    this.showLevelBadge = false,
    this.outerShadowScale,
  });

  final double scale;
  final String? imgPath;
  final RankProfileFrameStyle frameStyle;
  final String defaultAsset;
  final String crownAsset;
  final bool showCrown;
  final int? level;
  final bool showLevelBadge;

  /// non-null이면 Paywall 카드와 동일 outer shadow 적용.
  final double? outerShadowScale;

  static const avatarOuter = 114.0;
  static const borderW = 3.8;
  static const crownW = 154.77;
  static const crownH = 118.33;
  static const crownLeftOnAvatar = -7.31 - 5.0 + 12.0; // -0.31
  static const crownTopOnAvatar = -57.0 - 5.0 + 3.0; // -59

  /// 포디움 슬롯 스택 높이 (아바타+왕관 overflow 영역).
  static const boxH = 126.0;
  static const badge = 34.0;
  static const badgeFont = 22.0;
  static const badgeLeft = 84.0;
  static const badgeTop = 83.0;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final outer = avatarOuter * s;

    return SizedBox(
      width: outer,
      height: boxH * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: RankProfileFrame(
              imgPath: imgPath,
              outer: outer,
              borderWidth: borderW * s,
              style: frameStyle,
              defaultAsset: defaultAsset,
              outerShadowScale: outerShadowScale,
            ),
          ),
          if (showLevelBadge && level != null)
            Positioned(
              left: badgeLeft * s,
              top: badgeTop * s,
              child: RankPodiumLevelBadge(
                level: level!,
                size: badge * s,
                fontSize: badgeFont * s,
              ),
            ),
          if (showCrown)
            Positioned(
              left: crownLeftOnAvatar * s,
              top: crownTopOnAvatar * s,
              child: IgnorePointer(
                child: Image.asset(
                  crownAsset,
                  width: crownW * s,
                  height: crownH * s,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 1위: 흰→금. 2·3위 일반: 흰→#0CABA8. 그 외: Profile과 동일.
class RankProfileFrame extends StatelessWidget {
  const RankProfileFrame({
    super.key,
    required this.imgPath,
    required this.outer,
    required this.borderWidth,
    required this.style,
    required this.defaultAsset,
    this.outerShadowScale,
  });

  final String? imgPath;
  final double outer;
  final double borderWidth;
  final RankProfileFrameStyle style;
  final String defaultAsset;

  /// non-null이면 Paywall `_cardShadow`(Offset/Blur 20, #000000 30%) 적용·스케일.
  final double? outerShadowScale;

  static const _winnerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFB700)],
  );

  static const _premiumGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
  );

  static const _freeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF80D7CF), Color(0xFF43716D)],
  );

  /// 2·3위 일반 유저 (SVG: 위 #FFFFFF → 아래 #0CABA8).
  static const _podiumFreeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFF0CABA8)],
  );

  /// Claim 2·3등 보더 (위 #FFFFFF → 아래 #0D7F7D).
  static const _claimRunnerUpGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFF0D7F7D)],
  );

  static const _innerFill = Colors.white;
  static const _podiumFreeInnerFill = Color(0xFFD9D9D9);

  /// `paywall.dart` `_cardShadow`와 동일 스펙.
  static const _figmaOuterShadowColor = Color(0x4D000000);
  static const _figmaOuterShadow = 20.0;

  @override
  Widget build(BuildContext context) {
    final inner = (outer - borderWidth * 2).clamp(1.0, outer);
    final Gradient gradient = switch (style) {
      RankProfileFrameStyle.winner => _winnerGradient,
      RankProfileFrameStyle.premium => _premiumGradient,
      RankProfileFrameStyle.free => _freeGradient,
      RankProfileFrameStyle.podiumFree => _podiumFreeGradient,
      RankProfileFrameStyle.claimRunnerUp => _claimRunnerUpGradient,
    };
    final innerFill = style == RankProfileFrameStyle.podiumFree
        ? _podiumFreeInnerFill
        : _innerFill;
    final shadowScale = outerShadowScale;
    final shadows = shadowScale == null
        ? null
        : <BoxShadow>[
            BoxShadow(
              color: _figmaOuterShadowColor,
              offset: Offset(
                _figmaOuterShadow * shadowScale,
                _figmaOuterShadow * shadowScale,
              ),
              blurRadius: _figmaOuterShadow * shadowScale,
              spreadRadius: 0,
            ),
          ];

    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(shape: BoxShape.circle, color: innerFill),
        clipBehavior: Clip.antiAlias,
        child: RankAvatar(
          imgPath: imgPath,
          size: inner,
          defaultAsset: defaultAsset,
          placeholderColor: style == RankProfileFrameStyle.podiumFree
              ? const Color(0xFF938F99)
              : null,
        ),
      ),
    );
  }
}

class RankAvatar extends StatelessWidget {
  const RankAvatar({
    super.key,
    required this.imgPath,
    required this.size,
    required this.defaultAsset,
    this.placeholderColor,
  });

  final String? imgPath;
  final double size;
  final String defaultAsset;
  final Color? placeholderColor;

  Widget _placeholder() {
    final img = Image.asset(
      defaultAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    if (placeholderColor == null) return img;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(placeholderColor!, BlendMode.srcIn),
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imgPath?.trim();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                // 랭킹 imgPath는 풀 URL. CDN prefix 붙이지 않음.
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }
}

class RankPodiumLevelBadge extends StatelessWidget {
  const RankPodiumLevelBadge({
    super.key,
    required this.level,
    required this.size,
    required this.fontSize,
  });

  final int level;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF0CABA8),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$level',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
