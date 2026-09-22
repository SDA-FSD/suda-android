import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/user_img_path.dart';
import 'cdn_thumb_image.dart';
import 'character_rarity_frame.dart';
import 'default_profile_avatar.dart';

/// 유저 프로필 링. 구독·등급·무료 중 하나만 그린다.
abstract final class UserProfileRing {
  static const premium = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
  );

  static const free = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF80D7CF), Color(0xFF43716D)],
  );

  /// 프로필·Account 등 단일 링. 외경 100일 때 두께 4.
  static double borderWidthFor(double outer) => outer * 0.04;

  static LinearGradient standard({
    required bool isPremium,
    required UserImgPath parsed,
  }) {
    if (isPremium) return premium;
    if (parsed.isCharacter) {
      return CharacterRarityFrame.borderGradient(parsed.rarity!);
    }
    return free;
  }

  /// 포디움·Ranking Reward Claim 전용 링 안쪽. 없으면 링을 그리지 않는다.
  static LinearGradient? nested({
    required bool isPremium,
    required UserImgPath parsed,
  }) {
    if (isPremium) return premium;
    if (parsed.isCharacter) {
      return CharacterRarityFrame.borderGradient(parsed.rarity!);
    }
    return null;
  }

  static Widget box({
    required double size,
    required double borderWidth,
    required Gradient gradient,
    required Widget child,
  }) {
    final inner = (size - borderWidth * 2).clamp(1.0, size);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: Center(
          child: SizedBox(
            width: inner,
            height: inner,
            child: ClipOval(child: child),
          ),
        ),
      ),
    );
  }
}

/// 단일 링 + 프로필 얼굴. 구독이면 구독 링, 비구독 캐릭터면 등급 링, 그 외 무료 링.
class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    required this.imgPath,
    required this.isPremium,
    required this.size,
    this.borderWidth,
    this.isLoading = false,
    this.slot = CdnThumbSlot.profileAvatar,
    this.useOriginal = false,
  });

  final String? imgPath;
  final bool isPremium;
  final double size;
  final double? borderWidth;
  final bool isLoading;
  final CdnThumbSlot slot;

  /// 캐릭터 CDN을 `_150` 없이 원본으로 로드한다.
  final bool useOriginal;

  @override
  Widget build(BuildContext context) {
    final parsed = UserImgPath.parse(imgPath);
    final width = borderWidth ?? UserProfileRing.borderWidthFor(size);
    return UserProfileRing.box(
      size: size,
      borderWidth: width,
      gradient: UserProfileRing.standard(isPremium: isPremium, parsed: parsed),
      child: _face(parsed, (size - width * 2).clamp(1.0, size)),
    );
  }

  Widget _face(UserImgPath parsed, double inner) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF3F3F3F),
        child: const ColoredBox(color: Colors.white),
      );
    }
    if (parsed.isDefault) {
      return DefaultProfileAvatar(
        size: inner,
        color: parsed.defaultColor ?? UserImgPath.fallbackColor,
      );
    }
    final path = parsed.cdnPath;
    if (path == null || path.isEmpty) {
      return DefaultProfileAvatar(
        size: inner,
        color: UserImgPath.fallbackColor,
      );
    }
    if (useOriginal) {
      return CachedNetworkImage(
        imageUrl: CdnThumbUrl.original(path),
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => DefaultProfileAvatar(
          size: inner,
          color: UserImgPath.fallbackColor,
        ),
      );
    }
    return CdnThumbImage(
      path: path,
      slot: slot,
      width: inner,
      height: inner,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => DefaultProfileAvatar(
        size: inner,
        color: UserImgPath.fallbackColor,
      ),
    );
  }
}
