import 'package:flutter/material.dart';

/// S2 Playing **턴바영역**(turn bar area).
///
/// 헤더 타이틀 영역 바로 아래, 디스플레이 전폭·높이 24.
/// [turnCount]개의 턴박스가 gap [turnBoxGap]만 두고 가로로 균등 분할된다.
class RoleplayTurnBarArea extends StatelessWidget {
  static const double areaHeight = 24;
  static const double turnBarHeight = 4;

  /// 좌우 둥근 캡슐 형태 (Stadium). radius = height / 2.
  static const double turnBarBorderRadius = turnBarHeight / 2;
  static const double horizontalMargin = 24;
  static const double turnBoxGap = 6;
  static const Color defaultBarColor = Color(0x66635F5F); // #635F5F 40%

  final int turnCount;
  final List<Color> barColors;
  final List<String?> labelTexts;
  final List<Color?> labelColors;

  const RoleplayTurnBarArea({
    super.key,
    required this.turnCount,
    required this.barColors,
    this.labelTexts = const [],
    this.labelColors = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (turnCount <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: SizedBox(
        height: areaHeight,
        width: double.infinity,
        child: Row(
          children: [
            for (var i = 0; i < turnCount; i++) ...[
              Expanded(
                child: _TurnBox(
                  barColor: i < barColors.length
                      ? barColors[i]
                      : defaultBarColor,
                  labelText: i < labelTexts.length ? labelTexts[i] : null,
                  labelColor: i < labelColors.length ? labelColors[i] : null,
                  labelStyle: theme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ),
              if (i < turnCount - 1) const SizedBox(width: turnBoxGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _TurnBox extends StatelessWidget {
  final Color barColor;
  final String? labelText;
  final Color? labelColor;
  final TextStyle? labelStyle;

  const _TurnBox({
    required this.barColor,
    this.labelText,
    this.labelColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: labelText == null || labelText!.isEmpty
                ? const SizedBox.shrink()
                : Center(
                    key: ValueKey<String>(labelText!),
                    child: Text(
                      labelText!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle?.copyWith(color: labelColor),
                    ),
                  ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          height: RoleplayTurnBarArea.turnBarHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(
              RoleplayTurnBarArea.turnBarBorderRadius,
            ),
          ),
        ),
      ],
    );
  }
}
