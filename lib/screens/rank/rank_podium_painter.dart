import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// SVG 포디움 wireframe 9선만. 숫자 1/2/3은 Stack Text로 그림(페인터 Paragraph가 기기에서 안 보임).
class RankPodiumBasePainter extends CustomPainter {
  const RankPodiumBasePainter({required this.scale});

  final double scale;

  static const _strokeStart = Color(0x2BFFFFFF);
  static const _end5626A1 = Color(0xD95626A1);
  static const _end4E2292 = Color(0xD94E2292);
  static const _end8A38F5 = Color(0xD98A38F5);
  static const _end5928A6 = Color(0xD95928A6);

  @override
  void paint(Canvas canvas, Size size) {
    _vertical(canvas, 0.5, 65, 133, _end5626A1);
    _vertical(canvas, 132.5, 65, 133, _end4E2292);
    _horizontal(canvas, 64.5, 0, 133, 65, 133, _end8A38F5);
    _vertical(canvas, 132.5, 2, 148, _end5626A1);
    _vertical(canvas, 258.5, 2, 148, _end5928A6);
    _horizontal(canvas, 0.5, 132, 259, 2, 148, _end8A38F5);
    _vertical(canvas, 258.5, 82, 150, _end5626A1);
    _vertical(canvas, 384.5, 82, 150, _end4E2292);
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
