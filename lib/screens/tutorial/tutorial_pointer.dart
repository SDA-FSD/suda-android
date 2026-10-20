import 'package:flutter/material.dart';

/// 탭 가이드: `tutorial_pointer.png` 스케일 펄스 + 손끝 원 리플.
///
/// 손가락·채움원·테두리원 모두 `#8C8C8C`, 살짝 투명(90%)은 위젯 [Opacity]로 일괄.
/// 원 중심 = 손가락 손끝 앵커.
class TutorialPointer extends StatefulWidget {
  static const assetPath = 'assets/images/tutorial/tutorial_pointer.png';
  static const color = Color(0xFF8C8C8C);

  /// 손가락·원 공통 살짝 투명.
  static const opacity = 0.9;

  /// 원 앵커 (위젯 size 대비). Center 기준 손끝 ≈ (0.28, 0.22).
  static const tipX = 0.36;
  static const tipY = 0.30;
  static const fingerNudgeUp = 0.05;
  static const fingerNudgeLeft = 0.02;
  static const _baseTipX = 0.28;
  static const _baseTipY = 0.22;

  /// PNG 알파를 눌러 불투명 `#8C8C8C` 실루엣으로 칠한 뒤, 부모 Opacity로 통일.
  static const _opaqueTint = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 0x8C,
    0, 0, 0, 0, 0x8C,
    0, 0, 0, 0, 0x8C,
    0, 0, 0, 4, 0,
  ]);

  final double size;
  final Duration startDelay;

  const TutorialPointer({
    super.key,
    this.size = 120,
    this.startDelay = Duration.zero,
  });

  @override
  State<TutorialPointer> createState() => _TutorialPointerState();
}

class _TutorialPointerState extends State<TutorialPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    Future<void>.delayed(widget.startDelay, () {
      if (!mounted) return;
      setState(() => _visible = true);
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return SizedBox(width: widget.size, height: widget.size);

    final scale = TweenSequence<double>([
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

    return Opacity(
      opacity: TutorialPointer.opacity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Transform.translate(
                    offset: tipShift,
                    child: Transform.scale(
                      scale: scale.value,
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
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TapRipplePainter(progress: t),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 안쪽 채움 원 1개 + 바깥 테두리 원 1개. 중심 = [TutorialPointer.tipX/Y].
/// 베이스 투명도는 부모 [Opacity], 테두리는 커지며 추가 fade.
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

    final fillT = progress < 0.75 ? 1.0 : (1.0 - (progress - 0.75) / 0.25);
    if (fillT > 0.01) {
      canvas.drawCircle(
        center,
        base * 0.65,
        Paint()..color = TutorialPointer.color.withValues(alpha: fillT),
      );
    }

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
