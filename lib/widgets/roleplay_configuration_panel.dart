import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// S2 Playing 설정패널 (configuration panel) — 케밥 버튼 아래 글래스 오버레이.
class RoleplayConfigurationPanel extends StatelessWidget {
  static const double panelBorderRadius = 16;
  static const double railWidth = 200;
  static const double railHeight = 4;
  static const double thumbSize = 9;
  static const Color fillColor = Color(0xFF80D7CF);
  /// 구분선·슬라이더 레일 기본색 (#FFFFFF 40%)
  static const Color panelLineColor = Color(0x66FFFFFF);

  static const List<double> speedLabels = [0.7, 1.0, 1.2, 1.5];
  static const int speedStepCount = 4;

  final bool autoHintEnabled;
  final ValueChanged<bool> onAutoHintChanged;
  final int speedIndex;
  final ValueChanged<int> onSpeedIndexChanged;

  const RoleplayConfigurationPanel({
    super.key,
    required this.autoHintEnabled,
    required this.onAutoHintChanged,
    required this.speedIndex,
    required this.onSpeedIndexChanged,
  });

  TextStyle _labelStyle(TextTheme theme) {
    return (theme.bodySmall ?? const TextStyle()).copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final labelStyle = _labelStyle(theme);
    final clampedIndex = speedIndex.clamp(0, speedLabels.length - 1);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(panelBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(panelBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(panelBorderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.36),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AutoHintRow(
                    label: l10n.roleplayAutoHint,
                    labelStyle: labelStyle,
                    isOn: autoHintEnabled,
                    onChanged: onAutoHintChanged,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: railWidth,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: panelLineColor),
                      ),
                    ),
                  ),
                  Text(l10n.roleplayVoiceSpeed, style: labelStyle),
                  const SizedBox(height: 10),
                  _SpeedSlider(
                    speedIndex: clampedIndex,
                    labelStyle: theme.bodySmall?.copyWith(color: Colors.white),
                    onStepChanged: onSpeedIndexChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoHintRow extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const _AutoHintRow({
    required this.label,
    required this.labelStyle,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: RoleplayConfigurationPanel.railWidth,
      child: Row(
        children: [
          Text(label, style: labelStyle),
          const Spacer(),
          GestureDetector(
            onTap: () => onChanged(!isOn),
            child: _SudaToggleSwitch(isOn: isOn),
          ),
        ],
      ),
    );
  }
}

/// Push agreement 스크린과 동일 스타일 토글.
class _SudaToggleSwitch extends StatelessWidget {
  static const Color _trackOff = Color(0xFF8C8C8C);
  static const Color _trackOn = Color(0xFF80D7CF);
  static const double _trackWidth = 56;
  static const double _trackHeight = 24;
  static const double _thumbSize = 20;

  final bool isOn;

  const _SudaToggleSwitch({required this.isOn});

  @override
  Widget build(BuildContext context) {
    const thumbMargin = 2.0;
    final thumbLeft =
        isOn ? _trackWidth - thumbMargin - _thumbSize : thumbMargin;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: isOn ? _trackOn : _trackOff,
        borderRadius: BorderRadius.circular(_trackHeight / 2),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            left: thumbLeft,
            top: (_trackHeight - _thumbSize) / 2,
            child: Container(
              width: _thumbSize,
              height: _thumbSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedSlider extends StatefulWidget {
  final int speedIndex;
  final TextStyle? labelStyle;
  final ValueChanged<int> onStepChanged;

  const _SpeedSlider({
    required this.speedIndex,
    required this.labelStyle,
    required this.onStepChanged,
  });

  @override
  State<_SpeedSlider> createState() => _SpeedSliderState();
}

class _SpeedSliderState extends State<_SpeedSlider> {
  double? _dragThumbCenterX;

  static double get _stepGap =>
      RoleplayConfigurationPanel.railWidth /
      (RoleplayConfigurationPanel.speedStepCount - 1);

  double _thumbCenterForIndex(int index) => index * _stepGap;

  int _indexFromX(double x) {
    return (x / _stepGap)
        .round()
        .clamp(0, RoleplayConfigurationPanel.speedStepCount - 1);
  }

  void _handleTap(double localX) {
    final thumbCenterX =
        _dragThumbCenterX ?? _thumbCenterForIndex(widget.speedIndex);

    if (localX > thumbCenterX &&
        widget.speedIndex < RoleplayConfigurationPanel.speedStepCount - 1) {
      widget.onStepChanged(widget.speedIndex + 1);
    } else if (localX < thumbCenterX && widget.speedIndex > 0) {
      widget.onStepChanged(widget.speedIndex - 1);
    }
  }

  void _handleDragX(double localX) {
    setState(() {
      _dragThumbCenterX = localX.clamp(
        0.0,
        RoleplayConfigurationPanel.railWidth,
      );
    });
  }

  void _commitDrag() {
    final dragX = _dragThumbCenterX;
    if (dragX == null) return;
    final nextIndex = _indexFromX(dragX);
    setState(() => _dragThumbCenterX = null);
    if (nextIndex != widget.speedIndex) {
      widget.onStepChanged(nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    const railWidth = RoleplayConfigurationPanel.railWidth;
    const railHeight = RoleplayConfigurationPanel.railHeight;
    const thumbSize = RoleplayConfigurationPanel.thumbSize;
    final thumbCenterX =
        _dragThumbCenterX ?? _thumbCenterForIndex(widget.speedIndex);
    final fillWidth = thumbCenterX.clamp(0.0, railWidth);

    return SizedBox(
      width: railWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _handleTap(details.localPosition.dx),
        onHorizontalDragStart: (details) =>
            _handleDragX(details.localPosition.dx),
        onHorizontalDragUpdate: (details) =>
            _handleDragX(details.localPosition.dx),
        onHorizontalDragEnd: (_) => _commitDrag(),
        onHorizontalDragCancel: () => setState(() => _dragThumbCenterX = null),
        onVerticalDragStart: (details) =>
            _handleDragX(details.localPosition.dx),
        onVerticalDragUpdate: (details) =>
            _handleDragX(details.localPosition.dx),
        onVerticalDragEnd: (_) => _commitDrag(),
        onVerticalDragCancel: () => setState(() => _dragThumbCenterX = null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: railWidth,
              height: thumbSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    top: (thumbSize - railHeight) / 2,
                    child: Container(
                      width: railWidth,
                      height: railHeight,
                      decoration: BoxDecoration(
                        color: RoleplayConfigurationPanel.panelLineColor,
                        borderRadius: BorderRadius.circular(railHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: (thumbSize - railHeight) / 2,
                    child: Container(
                      width: fillWidth,
                      height: railHeight,
                      decoration: BoxDecoration(
                        color: RoleplayConfigurationPanel.fillColor,
                        borderRadius: BorderRadius.circular(railHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbCenterX - thumbSize / 2,
                    top: 0,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final value in RoleplayConfigurationPanel.speedLabels)
                  Text(
                    value == value.roundToDouble()
                        ? '${value.toInt()}.0'
                        : value.toString(),
                    style: widget.labelStyle,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
