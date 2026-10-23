import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 탭 가이드: `onboarding_tutorial_pointer.png` 스케일 펄스 + 손끝 테두리 원 리플(탭은 채움 원 없음).
/// 홀드(마이크)는 채움 원 + 테두리 원이 손가락 뒤에 깔리고, 손가락 둘레는 원이 지워져 공백이 생긴다.
/// 탭의 손가락·원은 `#8C8C8C` 불투명. 홀드는 같은 색을 80%로 그린다.
/// 원 중심 = 손가락 손끝 앵커.
class TutorialPointer extends StatefulWidget {
  static const assetPath = 'assets/images/onboarding/onboarding_tutorial_pointer.png';
  static const color = Color(0xFF8C8C8C);

  /// 원 앵커 (위젯 size 대비). Center 기준 손끝 ≈ (0.28, 0.22).
  static const tipX = 0.36;
  static const tipY = 0.30;
  static const fingerNudgeUp = 0.10;
  static const fingerNudgeLeft = 0.07;
  static const _baseTipX = 0.28;
  static const _baseTipY = 0.22;

  /// PNG 알파를 눌러 불투명 `#8C8C8C` 실루엣으로 칠함.
  static const _opaqueTint = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 0x8C,
    0, 0, 0, 0, 0x8C,
    0, 0, 0, 0, 0x8C,
    0, 0, 0, 4, 0,
  ]);

  /// 홀드(마이크) 손가락·원 전체 투명도 80%.
  static const holdOpacity = 0.8;
  static const _holdAlpha = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, holdOpacity, 0,
  ]);

  final double size;
  final Duration startDelay;

  /// 손끝 원. 탭은 테두리 원만 펄스. 홀드는 채움 원에서 테두리가 퍼져 사라진다.
  final bool showCircles;
  final bool holdGesture;

  const TutorialPointer({
    super.key,
    this.size = 120,
    this.startDelay = Duration.zero,
    this.showCircles = true,
    this.holdGesture = false,
  });

  @override
  State<TutorialPointer> createState() => _TutorialPointerState();
}

class _TutorialPointerState extends State<TutorialPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = false;

  /// 홀드에서 손가락을 직접 그려 둘레 공백을 만들기 위한 이미지.
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  ImageInfo? _imageInfo;

  bool get _paintsFingerItself => widget.holdGesture && widget.showCircles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paintsFingerItself) _resolveImage();
  }

  void _resolveImage() {
    final stream = const AssetImage(TutorialPointer.assetPath)
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _imageStream?.key) return;
    _detachImage();
    _imageStream = stream;
    _imageListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _imageInfo?.dispose();
        _imageInfo = info.clone();
      });
    });
    stream.addListener(_imageListener!);
  }

  void _detachImage() {
    final listener = _imageListener;
    if (listener != null) _imageStream?.removeListener(listener);
    _imageStream = null;
    _imageListener = null;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdGesture
          ? const Duration(milliseconds: 1600)
          : const Duration(milliseconds: 1100),
    );
    Future<void>.delayed(widget.startDelay, () {
      if (!mounted) return;
      setState(() => _visible = true);
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _detachImage();
    _imageInfo?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return SizedBox(width: widget.size, height: widget.size);

    final Animation<double> scale = widget.holdGesture
        ? const AlwaysStoppedAnimation(1)
        : TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(begin: 0.92, end: 1.08)
                  .chain(CurveTween(curve: Curves.easeOut)),
              weight: 35,
            ),
            TweenSequenceItem(
              tween: Tween(begin: 1.08, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut)),
              weight: 30,
            ),
            TweenSequenceItem(
              tween: Tween(begin: 1.0, end: 0.92)
                  .chain(CurveTween(curve: Curves.easeIn)),
              weight: 35,
            ),
          ]).animate(_controller);

    final tipShift = Offset(
      widget.size *
          (TutorialPointer.tipX -
              TutorialPointer._baseTipX -
              TutorialPointer.fingerNudgeLeft),
      widget.size *
          (TutorialPointer.tipY -
              TutorialPointer._baseTipY -
              TutorialPointer.fingerNudgeUp),
    );

    final holdImage = _paintsFingerItself ? _imageInfo?.image : null;
    if (holdImage != null) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _HoldPointerPainter(
              progress: _controller.value,
              image: holdImage,
              tipShift: tipShift,
            ),
          ),
        ),
      );
    }

    final fallback = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final press = widget.holdGesture ? _holdPress(t) : 0.0;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Transform.translate(
                    offset: tipShift +
                        Offset(0, widget.holdGesture ? widget.size * 0.06 * press : 0),
                    child: Transform.scale(
                      scale: widget.holdGesture
                          ? 1 - 0.12 * press
                          : scale.value,
                      alignment: const Alignment(-0.35, -0.55),
                      child: ColorFiltered(
                        colorFilter: TutorialPointer._opaqueTint,
                        child: Image.asset(
                          TutorialPointer.assetPath,
                          width: widget.size * 0.92,
                          height: widget.size * 0.92,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showCircles)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: widget.holdGesture
                          ? _HoldCirclePainter(progress: t)
                          : _TapRipplePainter(progress: t),
                    ),
                  ),
              ],
            ),
          );
        },
    );
    // Opacity는 손가락 알파 4배 필터와 합쳐져 100%가 되므로 알파 필터를 바깥에 건다.
    return widget.holdGesture
        ? ColorFiltered(colorFilter: TutorialPointer._holdAlpha, child: fallback)
        : fallback;
  }
}

/// 바깥 테두리 원 1개(채움 원 없음). 중심 = [TutorialPointer.tipX/Y].
/// 테두리는 커지며 사라질 때만 fade.
class _TapRipplePainter extends CustomPainter {
  final double progress;

  const _TapRipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * TutorialPointer.tipX,
      size.height * TutorialPointer.tipY,
    );
    final base = size.shortestSide * 0.09;

    const ringStart = 0.08;
    const ringEnd = 0.9;
    if (progress >= ringStart && progress <= ringEnd) {
      final local =
          ((progress - ringStart) / (ringEnd - ringStart)).clamp(0.0, 1.0);
      final radius = base * (1.0 + local * 1.8);
      final ringFade = (1.0 - local) * (1.0 - local * 0.35);
      if (ringFade > 0.02) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * (1.0 - local * 0.35)
            ..color = TutorialPointer.color.withValues(alpha: ringFade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TapRipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 0 뜸 → 1 꾹 누른 채 유지 → 0 뗌.
double _holdPress(double t) {
  if (t < 0.22) return Curves.easeIn.transform(t / 0.22);
  if (t < 0.78) return 1;
  return 1 - Curves.easeOut.transform((t - 0.78) / 0.22);
}

/// 홀드: 손가락이 누르는 만큼 채움 원이 작았다가 커지고, 테두리 원은 그 원에서 퍼져 사라진다.
class _HoldCirclePainter extends CustomPainter {
  final double progress;

  const _HoldCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final press = _holdPress(progress);
    if (press < 0.02) return;
    final center = Offset(
      size.width * TutorialPointer.tipX,
      size.height * (TutorialPointer.tipY + 0.06 * press),
    );
    final base = size.shortestSide * 0.09;
    final fillRadius = base * (0.40 + 0.72 * press);
    canvas.drawCircle(
      center,
      fillRadius,
      Paint()..color = TutorialPointer.color,
    );

    const ringStart = 0.24;
    const ringEnd = 0.68;
    if (progress < ringStart || progress > ringEnd) return;
    final local =
        ((progress - ringStart) / (ringEnd - ringStart)).clamp(0.0, 1.0);
    final grow = Curves.easeOut.transform(local);
    canvas.drawCircle(
      center,
      fillRadius + base * 2.6 * grow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = TutorialPointer.color,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 홀드 전용. 채움 원·테두리 원을 먼저 그리고, 손가락 실루엣보다 [_gapFraction]만큼 넓은
/// 부분을 지운 뒤(공백) 그 위에 손가락을 그린다. 위치·크기 변환은 위젯 방식 손가락과 같다.
class _HoldPointerPainter extends CustomPainter {
  /// 손가락 둘레 공백 폭(위젯 size 대비).
  static const _gapFraction = 0.022;

  final double progress;
  final ui.Image image;
  final Offset tipShift;

  const _HoldPointerPainter({
    required this.progress,
    required this.image,
    required this.tipShift,
  });

  void _drawFinger(
    Canvas canvas,
    Size size,
    double press,
    Paint paint, {
    Offset extra = Offset.zero,
  }) {
    final box = size.width * 0.92;
    final boxCenter =
        Offset(size.width / 2, size.height / 2) +
        tipShift +
        Offset(0, size.width * 0.06 * press);
    final boxRect = Rect.fromCenter(center: boxCenter, width: box, height: box);
    final pivot = boxRect.center + Offset(-0.35 * box / 2, -0.55 * box / 2);
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, imageSize, boxRect.size);
    final dst = Alignment.center.inscribe(fitted.destination, boxRect);
    canvas.save();
    canvas.translate(extra.dx, extra.dy);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(1 - 0.12 * press);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawImageRect(image, Offset.zero & imageSize, dst, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final press = _holdPress(progress);

    // 손가락·원 전체를 한 번에 80%로. (공백 덕에 둘이 겹치지 않아 따로 칠해도 같다.)
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: TutorialPointer.holdOpacity),
    );
    if (press >= 0.02) {
      canvas.saveLayer(null, Paint());
      _paintCircles(canvas, size, press);

      // 손가락 실루엣을 여러 방향으로 밀어 dstOut → 둘레가 gap만큼 지워진다.
      final gap = size.width * _gapFraction;
      final erase = Paint()
        ..blendMode = BlendMode.dstOut
        ..filterQuality = FilterQuality.medium;
      _drawFinger(canvas, size, press, erase);
      for (final r in [gap * 0.5, gap]) {
        for (var i = 0; i < 16; i++) {
          final a = i * math.pi * 2 / 16;
          _drawFinger(
            canvas,
            size,
            press,
            erase,
            extra: Offset(math.cos(a) * r, math.sin(a) * r),
          );
        }
      }
      canvas.restore();
    }

    _drawFinger(
      canvas,
      size,
      press,
      Paint()
        ..colorFilter = TutorialPointer._opaqueTint
        ..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _paintCircles(Canvas canvas, Size size, double press) {
    final center = Offset(
      size.width * TutorialPointer.tipX,
      size.height * (TutorialPointer.tipY + 0.06 * press),
    );
    final base = size.shortestSide * 0.09;
    final fillRadius = base * (0.40 + 0.72 * press);
    canvas.drawCircle(
      center,
      fillRadius,
      Paint()..color = TutorialPointer.color,
    );

    const ringStart = 0.24;
    const ringEnd = 0.68;
    if (progress < ringStart || progress > ringEnd) return;
    final local =
        ((progress - ringStart) / (ringEnd - ringStart)).clamp(0.0, 1.0);
    final grow = Curves.easeOut.transform(local);
    canvas.drawCircle(
      center,
      fillRadius + base * 2.6 * grow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = TutorialPointer.color,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldPointerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.image != image ||
      oldDelegate.tipShift != tipShift;
}
