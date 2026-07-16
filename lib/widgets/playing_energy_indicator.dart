import 'package:flutter/material.dart';

import '../models/user_models.dart';
import '../utils/energy_icon.dart';

const _energyZeroColor = Color(0xFFE60000);

/// Playing 푸터 중앙 에너지 표시. 무제한은 아이콘만, 일반은 아이콘+숫자.
class PlayingEnergyIndicator extends StatelessWidget {
  final UserEnergyDto? energy;

  const PlayingEnergyIndicator({super.key, required this.energy});

  @override
  Widget build(BuildContext context) {
    final dto = energy;
    if (dto == null) return const SizedBox.shrink();

    final nowUtc = DateTime.now().toUtc();
    if (dto.isUnlimitedActiveAt(nowUtc)) {
      return Image.asset(
        energyIconAssetPath(dto, nowUtc),
        width: 24,
        height: 24,
      );
    }

    final count = dto.energyCount;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          energyIconAssetPath(dto, nowUtc),
          width: 24,
          height: 24,
        ),
        Text(
          '$count',
          style: count == 0
              ? textStyle?.copyWith(color: _energyZeroColor) ??
                  const TextStyle(
                    color: _energyZeroColor,
                    fontWeight: FontWeight.w700,
                  )
              : textStyle,
        ),
      ],
    );
  }
}
