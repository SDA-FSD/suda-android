import 'package:flutter/material.dart';

/// 캐릭터 등급 원형 테두리. 상단→하단 그라데이션, 기본 두께 10.
/// Reward Unboxing 외 다른 스크린에서도 동일 규칙으로 재사용.
class CharacterRarityFrame extends StatelessWidget {
  const CharacterRarityFrame({
    super.key,
    required this.rarity,
    required this.size,
    required this.child,
    this.borderWidth = 10,
  });

  /// `NORMAL` | `RARE` | `EPIC` (대소문자 무시).
  final String rarity;
  final double size;
  final double borderWidth;
  final Widget child;

  static const _normal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF71A431), Color(0xFF2B3E13)],
  );
  static const _rare = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF009DFF), Color(0xFF0CABA8)],
  );
  static const _epic = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDF3FF8), Color(0xFF51218F)],
  );

  static String normalize(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'RARE':
        return 'RARE';
      case 'EPIC':
        return 'EPIC';
      default:
        return 'NORMAL';
    }
  }

  static LinearGradient borderGradient(String rarity) {
    switch (normalize(rarity)) {
      case 'RARE':
        return _rare;
      case 'EPIC':
        return _epic;
      default:
        return _normal;
    }
  }

  static String englishLabel(String rarity) {
    switch (normalize(rarity)) {
      case 'RARE':
        return '[Rare]';
      case 'EPIC':
        return '[Epic]';
      default:
        return '[Normal]';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inner = (size - borderWidth * 2).clamp(1.0, size);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: borderGradient(rarity),
        ),
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
