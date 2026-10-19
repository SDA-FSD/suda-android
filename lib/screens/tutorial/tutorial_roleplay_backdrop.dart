import 'package:flutter/material.dart';

/// Tutorial Intro / Roleplay 공용 배경.
///
/// 프로토타입 `#bg` = `tutorial_roleplay_bg.jpg`(이미 블러된 롤플레이 장면).
/// HTML은 추가 blur·딤 없이 이미지만 opacity로 올린다.
class TutorialRoleplayBackdrop extends StatelessWidget {
  const TutorialRoleplayBackdrop({super.key});

  static const assetPath = 'assets/images/tutorial/tutorial_roleplay_bg.jpg';

  /// 원본 mean≈47로 디바이스에서 거의 검게 보이므로 살짝 밝혀 시안처럼 비치게 한다.
  static const _lift = ColorFilter.matrix(<double>[
    1.35, 0, 0, 0, 18,
    0, 1.35, 0, 0, 18,
    0, 0, 1.35, 0, 18,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121212),
      child: ColorFiltered(
        colorFilter: _lift,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(assetPath),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
