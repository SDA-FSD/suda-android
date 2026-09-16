import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// SVG 포디움 wireframe 9선.
/// 로컬 원점 (0,0) = 화면 (34, 290). 좌표에 [scale] (= contentWidth/440) 곱함.
class RankPodiumBasePainter extends CustomPainter {
  const RankPodiumBasePainter({required this.scale});

  final double scale;

  /// #FFFFFF @ 20%
  static const _strokeStart = Color(0x33FFFFFF);

  static const _end5626A1 = Color(0xFF5626A1);
  static const _end4E2292 = Color(0xFF4E2292);
  static const _end8A38F5 = Color(0xFF8A38F5);
  static const _end5928A6 = Color(0xFF5928A6);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 2등 왼쪽 바깥 세로선
    _vertical(canvas, 0.5, 65, 133, _end5626A1);
    // 2. 2등 오른쪽(1등과 경계) 세로선
    _vertical(canvas, 132.5, 65, 133, _end4E2292);
    // 3. 2등 윗변 가로선 (그라디언트 벡터는 수직)
    _horizontal(canvas, 64.5, 0, 133, 65, 133, _end8A38F5);
    // 4. 1등 왼쪽(2등과 경계) 세로선
    _vertical(canvas, 132.5, 2, 148, _end5626A1);
    // 5. 1등 오른쪽(3등과 경계) 세로선
    _vertical(canvas, 258.5, 2, 148, _end5928A6);
    // 6. 1등 윗변 가로선
    _horizontal(canvas, 0.5, 132, 259, 2, 148, _end8A38F5);
    // 7. 3등 왼쪽(1등과 경계) 세로선 — 5번과 x 동일, 합치지 않음
    _vertical(canvas, 258.5, 82, 150, _end5626A1);
    // 8. 3등 오른쪽 바깥 세로선
    _vertical(canvas, 384.5, 82, 150, _end4E2292);
    // 9. 3등 윗변 가로선
    _horizontal(canvas, 81.5, 259, 385, 82, 150, _end8A38F5);
  }

  void _vertical(
    Canvas canvas,
    double x,
    double y1,
    double y2,
    Color endColor,
  ) {
    final sx = x * scale;
    final sy1 = y1 * scale;
    final sy2 = y2 * scale;
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(sx, sy1),
        Offset(sx, sy2),
        [_strokeStart, endColor],
      );
    canvas.drawLine(Offset(sx, sy1), Offset(sx, sy2), paint);
  }

  void _horizontal(
    Canvas canvas,
    double y,
    double x1,
    double x2,
    double gradY1,
    double gradY2,
    Color endColor,
  ) {
    final sy = y * scale;
    final sx1 = x1 * scale;
    final sx2 = x2 * scale;
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(sx1, gradY1 * scale),
        Offset(sx1, gradY2 * scale),
        [_strokeStart, endColor],
      );
    canvas.drawLine(Offset(sx1, sy), Offset(sx2, sy), paint);
  }

  @override
  bool shouldRepaint(covariant RankPodiumBasePainter oldDelegate) =>
      scale != oldDelegate.scale;
}

/// 포디움 배경 큰 순위 숫자. Opacity 0.2 + BlendMode.
class PodiumRankNumber extends StatelessWidget {
  const PodiumRankNumber({
    super.key,
    required this.digit,
    required this.style,
    required this.blendMode,
  });

  final String digit;
  final TextStyle style;
  final BlendMode blendMode;

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: digit, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return SizedBox(
      width: textPainter.width,
      height: textPainter.height,
      child: CustomPaint(
        painter: _PodiumRankNumberPainter(
          digit: digit,
          style: style,
          blendMode: blendMode,
        ),
      ),
    );
  }
}

class _PodiumRankNumberPainter extends CustomPainter {
  const _PodiumRankNumberPainter({
    required this.digit,
    required this.style,
    required this.blendMode,
  });

  final String digit;
  final TextStyle style;
  final BlendMode blendMode;

  static const _opacity = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: digit,
        style: style.copyWith(
          color: Colors.white.withValues(alpha: _opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    canvas.saveLayer(
      Offset.zero & size,
      Paint()..blendMode = blendMode,
    );
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PodiumRankNumberPainter oldDelegate) =>
      digit != oldDelegate.digit ||
      style != oldDelegate.style ||
      blendMode != oldDelegate.blendMode;
}
