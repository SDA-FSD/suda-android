import 'package:flutter/material.dart';

/// 프로필·티켓 안내 등 공통 Lv 진행 바 (height 4, base #635F5F, progress #80D7CF).
class LevelProgressBar extends StatelessWidget {
  final double progressPercentage;

  const LevelProgressBar({super.key, required this.progressPercentage});

  @override
  Widget build(BuildContext context) {
    final p = (progressPercentage.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFF635F5F)),
            ),
            FractionallySizedBox(
              widthFactor: p,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const ColoredBox(color: Color(0xFF80D7CF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
