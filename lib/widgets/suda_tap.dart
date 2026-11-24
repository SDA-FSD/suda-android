import 'package:flutter/material.dart';

import '../utils/suda_haptics.dart';

export '../utils/suda_haptics.dart';

/// 조작 탭. `haptic: false`면 키보드를 닫거나 빈 탭처럼 진동을 내지 않는다.
class SudaTap extends StatelessWidget {
  final VoidCallback? onTap;
  final bool haptic;
  final HitTestBehavior? behavior;
  final Widget? child;

  const SudaTap({
    super.key,
    this.onTap,
    this.haptic = true,
    this.behavior,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: SudaHaptics.bind(onTap, haptic: haptic),
      behavior: behavior,
      child: child,
    );
  }
}

class SudaInkWell extends StatelessWidget {
  final VoidCallback? onTap;
  final bool haptic;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Color? splashColor;
  final Color? highlightColor;
  final Widget? child;

  const SudaInkWell({
    super.key,
    this.onTap,
    this.haptic = true,
    this.borderRadius,
    this.customBorder,
    this.splashColor,
    this.highlightColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: SudaHaptics.bind(onTap, haptic: haptic),
      borderRadius: borderRadius,
      customBorder: customBorder,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class SudaElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool haptic;
  final ButtonStyle? style;
  final Widget child;

  const SudaElevatedButton({
    super.key,
    required this.onPressed,
    this.haptic = true,
    this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: SudaHaptics.bind(onPressed, haptic: haptic),
      style: style,
      child: child,
    );
  }
}

class SudaTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool haptic;
  final ButtonStyle? style;
  final Widget child;

  const SudaTextButton({
    super.key,
    required this.onPressed,
    this.haptic = true,
    this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: SudaHaptics.bind(onPressed, haptic: haptic),
      style: style,
      child: child,
    );
  }
}

class SudaIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool haptic;
  final Widget icon;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Color? color;
  final Color? highlightColor;
  final Color? splashColor;
  final String? tooltip;
  final BoxConstraints? constraints;
  final ButtonStyle? style;

  const SudaIconButton({
    super.key,
    required this.onPressed,
    this.haptic = true,
    required this.icon,
    this.iconSize,
    this.padding,
    this.alignment,
    this.color,
    this.highlightColor,
    this.splashColor,
    this.tooltip,
    this.constraints,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: SudaHaptics.bind(onPressed, haptic: haptic),
      icon: icon,
      iconSize: iconSize,
      padding: padding,
      alignment: alignment,
      color: color,
      highlightColor: highlightColor,
      splashColor: splashColor,
      tooltip: tooltip,
      constraints: constraints,
      style: style,
      enableFeedback: false,
    );
  }
}
