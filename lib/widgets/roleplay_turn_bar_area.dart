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

  static const Duration labelFadeOutDuration = Duration(milliseconds: 150);

  final int turnCount;
  final List<Color> barColors;
  final List<String?> labelTexts;
  final List<Color?> labelColors;
  final bool labelFadeOut;

  const RoleplayTurnBarArea({
    super.key,
    required this.turnCount,
    required this.barColors,
    this.labelTexts = const [],
    this.labelColors = const [],
    this.labelFadeOut = false,
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
                  labelFadeOut: labelFadeOut,
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
  final bool labelFadeOut;
  final TextStyle? labelStyle;

  const _TurnBox({
    required this.barColor,
    this.labelText,
    this.labelColor,
    this.labelFadeOut = false,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _TurnGradeLabel(
            text: labelText,
            color: labelColor,
            style: labelStyle,
            fadeOut: labelFadeOut,
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

class _TurnGradeLabel extends StatefulWidget {
  final String? text;
  final Color? color;
  final TextStyle? style;
  final bool fadeOut;

  const _TurnGradeLabel({
    this.text,
    this.color,
    this.style,
    this.fadeOut = false,
  });

  @override
  State<_TurnGradeLabel> createState() => _TurnGradeLabelState();
}

class _TurnGradeLabelState extends State<_TurnGradeLabel>
    with SingleTickerProviderStateMixin {
  static const Duration _popDuration = Duration(milliseconds: 320);

  late final AnimationController _popController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(vsync: this, duration: _popDuration);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.42,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.42,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_popController);
    _triggerPopIfNeeded(null, widget.text);
  }

  @override
  void didUpdateWidget(covariant _TurnGradeLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _triggerPopIfNeeded(oldWidget.text, widget.text);
  }

  void _triggerPopIfNeeded(String? oldText, String? newText) {
    if (newText == null || newText.isEmpty) return;
    if (oldText != newText) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedOpacity(
        opacity: widget.fadeOut ? 0 : 1,
        duration: RoleplayTurnBarArea.labelFadeOutDuration,
        curve: Curves.easeOut,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomCenter,
          child: Text(
            text,
            key: ValueKey<String>(text),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: widget.style?.copyWith(color: widget.color),
          ),
        ),
      ),
    );
  }
}
