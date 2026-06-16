import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const double roleplayMicDefaultSize = 100;
const double roleplayMicPressedSize = 115;

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// S1 `playing_backup._MicButtonArea` 이식. 녹음 버튼·Cancel·드래그 화살표 UX.
class RoleplayMicButtonArea extends StatefulWidget {
  final bool isInteractive;
  final bool isLoading;
  final bool isDisabled;
  final AnimationController loadingRotationController;
  final VoidCallback onPressStart;
  final void Function(bool cancel) onPressEnd;
  final VoidCallback onPressCancel;

  const RoleplayMicButtonArea({
    super.key,
    required this.isInteractive,
    required this.isLoading,
    required this.isDisabled,
    required this.loadingRotationController,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onPressCancel,
  });

  @override
  State<RoleplayMicButtonArea> createState() => _RoleplayMicButtonAreaState();
}

class _RoleplayMicButtonAreaState extends State<RoleplayMicButtonArea>
    with TickerProviderStateMixin {
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0);
  final ValueNotifier<bool> _isCancelHovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isPressed = ValueNotifier<bool>(false);

  late final AnimationController _arrowPulseController;

  double? _lastCenterX;
  double? _lastCancelCenter;
  double? _lastMaxLeftOffset;

  @override
  void initState() {
    super.initState();
    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _isPressed.addListener(_syncArrowPulse);
  }

  void _syncArrowPulse() {
    if (_isPressed.value) {
      if (!_arrowPulseController.isAnimating) {
        _arrowPulseController.repeat();
      }
    } else {
      if (_arrowPulseController.isAnimating) {
        _arrowPulseController.stop();
      }
      _arrowPulseController.reset();
    }
  }

  @override
  void dispose() {
    _isPressed.removeListener(_syncArrowPulse);
    _dragOffset.dispose();
    _isCancelHovered.dispose();
    _isPressed.dispose();
    _arrowPulseController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isInteractive || widget.isLoading || widget.isDisabled) return;
    _isPressed.value = true;
    _dragOffset.value = 0;
    _isCancelHovered.value = false;
    widget.onPressStart();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPressed.value) return;
    final centerX = _lastCenterX;
    final cancelCenter = _lastCancelCenter;
    final maxLeftOffset = _lastMaxLeftOffset;
    if (centerX == null || cancelCenter == null || maxLeftOffset == null) {
      return;
    }
    final nextOffset = (_dragOffset.value + event.delta.dx).clamp(
      maxLeftOffset,
      0.0,
    );
    final buttonLeft = centerX + nextOffset - (roleplayMicPressedSize / 2);
    final cancelHovered = buttonLeft <= cancelCenter;
    if (nextOffset != _dragOffset.value ||
        cancelHovered != _isCancelHovered.value) {
      _dragOffset.value = nextOffset;
      _isCancelHovered.value = cancelHovered;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isPressed.value) return;
    final cancel = _isCancelHovered.value;
    _isPressed.value = false;
    _dragOffset.value = 0;
    _isCancelHovered.value = false;
    widget.onPressEnd(cancel);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!_isPressed.value) return;
    _isPressed.value = false;
    _dragOffset.value = 0;
    _isCancelHovered.value = false;
    widget.onPressCancel();
  }

  static String _assetFor(
    bool isPressed,
    bool cancelHover,
    bool isLoading,
    bool isDisabled,
  ) {
    if (isLoading) return 'assets/images/buttons/mic_btn_loading.png';
    if (isDisabled) return 'assets/images/buttons/mic_btn_disabled.png';
    if (isPressed && cancelHover) {
      return 'assets/images/buttons/mic_btn_default.png';
    }
    if (isPressed) return 'assets/images/buttons/mic_btn_pressed.png';
    return 'assets/images/buttons/mic_btn_default.png';
  }

  static double _sizeFor(
    bool isPressed,
    bool cancelHover,
    bool isLoading,
    bool isDisabled,
  ) {
    if (isLoading || isDisabled) return roleplayMicDefaultSize;
    if (isPressed && cancelHover) return roleplayMicDefaultSize;
    if (isPressed) return roleplayMicPressedSize;
    return roleplayMicDefaultSize;
  }

  Widget _buildButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPressed,
      builder: (context, isPressed, _) {
        return ValueListenableBuilder<double>(
          valueListenable: _dragOffset,
          builder: (context, dragOffset, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isCancelHovered,
              builder: (context, cancelHovered, ___) {
                final size = _sizeFor(
                  isPressed,
                  cancelHovered,
                  widget.isLoading,
                  widget.isDisabled,
                );
                final asset = _assetFor(
                  isPressed,
                  cancelHovered,
                  widget.isLoading,
                  widget.isDisabled,
                );
                final image = Image.asset(asset, width: size, height: size);
                final content = widget.isLoading
                    ? RotationTransition(
                        turns: widget.loadingRotationController,
                        child: image,
                      )
                    : image;
                return SizedBox(
                  width: size,
                  height: size,
                  child: Center(child: content),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDragArrows(
    double cancelRightX,
    double areaHeight,
    double anchorLeftX,
  ) {
    const iconSize = 16.0;
    const gap = 5.0;
    const count = 3;
    final groupWidth = (iconSize * count) + (gap * (count - 1));
    final availableWidth = anchorLeftX - cancelRightX;
    if (availableWidth <= groupWidth) return const SizedBox.shrink();
    final groupLeft = cancelRightX + ((availableWidth - groupWidth) / 2);
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _arrowPulseController,
        builder: (context, child) {
          final shift = _arrowPulseController.value;
          return Stack(
            children: [
              Positioned(
                left: groupLeft,
                top: (areaHeight - iconSize) / 2,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlidingGradientTransform(-shift),
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.modulate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (index) {
                      if (index > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(left: gap),
                          child: SvgPicture.asset(
                            'assets/images/icons/header_arrow_back.svg',
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      }
                      return SvgPicture.asset(
                        'assets/images/icons/header_arrow_back.svg',
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth;
        final centerX = areaWidth / 2;
        final cancelStyle =
            Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0CABA8)) ??
            const TextStyle();
        final cancelWidth = _measureTextWidth('Cancel', cancelStyle);
        final cancelCenter = cancelWidth / 2;
        final maxLeftOffset = (roleplayMicPressedSize / 2) - centerX;

        _lastCenterX = centerX;
        _lastCancelCenter = cancelCenter;
        _lastMaxLeftOffset = maxLeftOffset;

        return ValueListenableBuilder<bool>(
          valueListenable: _isPressed,
          builder: (context, isPressed, _) {
            final showArrows = isPressed;
            final shouldShowCancel = isPressed;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: shouldShowCancel ? 1 : 0,
                    child: Text('Cancel', style: cancelStyle),
                  ),
                ),
                if (showArrows)
                  _buildDragArrows(
                    cancelWidth,
                    120,
                    centerX - (roleplayMicPressedSize / 2),
                  ),
                Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _dragOffset,
                    builder: (context, dragOffset, __) {
                      final effectiveOffset = isPressed ? dragOffset : 0.0;
                      return Transform.translate(
                        offset: Offset(effectiveOffset, 0),
                        child: IgnorePointer(
                          ignoring: !widget.isInteractive,
                          child: Listener(
                            onPointerDown: _onPointerDown,
                            onPointerMove: _onPointerMove,
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: _buildButton(context),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
