import 'dart:async';

import 'package:flutter/material.dart';

/// Overlay 기반 토스트 메시지.
///
/// 스펙:
/// - 배경: 기본 #353535 85% 투명도 / 경고 #E4382A 85% 투명도
/// - 텍스트: body-default, 흰색
/// - 크기: min height 48, max width 90% 디스플레이
/// - 위치: 하단에서 60px
/// - 모양: 좌우 반원(Stadium)
/// - duration: 기본 2초 (가시 시간)
/// - fade-in/out: 각 1초 (토스트 콘텐츠만 적용)
/// - 토스트 pill 영역 탭: 표시 타이머 취소 후 자동 종료와 동일한 fade-out(동일 1초)
class DefaultToast {
  static OverlayEntry? _currentEntry;

  static const Color _defaultBg = Color(0xD9353535); // #353535 @ 85%
  static const Color _errorBg = Color(0xD9E4382A); // #E4382A @ 85%
  static const double _bottomOffset = 60;
  static const double _maxWidthRatio = 0.9;
  static const double _minHeight = 48;
  static const double _maxRadius = 34; // 2줄 기준, 3줄 이상은 이 값 유지
  static const double _horizontalPadding = 16;
  static const double _verticalPadding = 12;
  static const Duration _fadeDuration = Duration(seconds: 1);

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final color = isError ? _errorBg : _defaultBg;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        right: 0,
        bottom: _bottomOffset,
        child: Center(
          child: _ToastFadeWidget(
            fadeDuration: _fadeDuration,
            displayDuration: duration,
            onComplete: () {
              entry.remove();
              if (_currentEntry == entry) {
                _currentEntry = null;
              }
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _minHeight,
                maxWidth: mediaQuery.size.width * _maxWidthRatio,
              ),
              child: Material(
                color: Colors.transparent,
                child: CustomPaint(
                painter: _ToastBackgroundPainter(color: color, maxRadius: _maxRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                    vertical: _verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _minHeight),
                    child: Center(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                        maxLines: null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastFadeWidget extends StatefulWidget {
  final Widget child;
  final Duration fadeDuration;
  final Duration displayDuration;
  final VoidCallback onComplete;

  const _ToastFadeWidget({
    required this.child,
    required this.fadeDuration,
    required this.displayDuration,
    required this.onComplete,
  });

  @override
  State<_ToastFadeWidget> createState() => _ToastFadeWidgetState();
}

class _ToastFadeWidgetState extends State<_ToastFadeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _displayTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward().then((_) {
      if (!mounted || _completed) {
        return;
      }
      _displayTimer = Timer(widget.displayDuration, _finishWithFadeOut);
    });
  }

  void _invokeComplete() {
    if (_completed || !mounted) {
      return;
    }
    _completed = true;
    widget.onComplete();
  }

  void _finishWithFadeOut() {
    if (_completed || !mounted) {
      return;
    }
    _displayTimer?.cancel();
    _displayTimer = null;
    if (_controller.status == AnimationStatus.reverse) {
      return;
    }
    if (_controller.status == AnimationStatus.dismissed) {
      _invokeComplete();
      return;
    }
    _controller.reverse().then((_) {
      _invokeComplete();
    });
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finishWithFadeOut,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child,
      ),
    );
  }
}

class _ToastBackgroundPainter extends CustomPainter {
  final Color color;
  final double maxRadius;

  _ToastBackgroundPainter({required this.color, required this.maxRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.height / 2).clamp(0.0, maxRadius);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ToastBackgroundPainter oldDelegate) =>
      color != oldDelegate.color || maxRadius != oldDelegate.maxRadius;
}
