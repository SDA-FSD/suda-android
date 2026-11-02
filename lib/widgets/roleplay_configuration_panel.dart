import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// S2 Playing 설정패널 (configuration panel) — 케밥 버튼 아래 글래스 오버레이.
class RoleplayConfigurationPanel extends StatelessWidget {
  static const double panelBorderRadius = 16;
  static const double railWidth = 200;

  final bool autoHintEnabled;
  final ValueChanged<bool> onAutoHintChanged;

  const RoleplayConfigurationPanel({
    super.key,
    required this.autoHintEnabled,
    required this.onAutoHintChanged,
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

