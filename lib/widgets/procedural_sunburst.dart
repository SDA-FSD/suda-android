import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 절차적 sunburst(흰 10%/20% 교차 wedge). Reward Unboxing·Ranking Reward Claim.
enum SunburstFocal {
  /// 화면 가로·세로 중앙.
  center,

  /// 화면 하단 중앙(일장기형).
  bottomCenter,
}

/// 48s CW / 64s CCW 이중 회전 sunburst. [IgnorePointer], 레이어 opacity 기본 0.55.
class ProceduralSunburstOverlay extends StatefulWidget {
  const ProceduralSunburstOverlay({
    super.key,
    this.focal = SunburstFocal.center,
    this.layerOpacity = 0.55,
  });

  final SunburstFocal focal;
  final double layerOpacity;

  @override
  State<ProceduralSunburstOverlay> createState() =>
      _ProceduralSunburstOverlayState();
}

class _ProceduralSunburstOverlayState extends State<ProceduralSunburstOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _cwController;
  late final AnimationController _ccwController;

  @override
  void initState() {
    super.initState();
    _cwController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    )..repeat();
    _ccwController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 64),
    )..repeat();
  }

  @override
  void dispose() {
    _cwController.dispose();
    _ccwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: Listenable.merge([_cwController, _ccwController]),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _SunburstLayer(
                  size: size,
                  turns: _cwController.value,
                  scale: 1.05,
                  wedgeCount: 24,
                  focal: widget.focal,
                  layerOpacity: widget.layerOpacity,
                ),
                _SunburstLayer(
                  size: size,
                  turns: -_ccwController.value,
                  scale: 1.22,
                  wedgeCount: 30,
                  focal: widget.focal,
                  layerOpacity: widget.layerOpacity,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SunburstLayer extends StatelessWidget {
  const _SunburstLayer({
    required this.size,
    required this.turns,
    required this.scale,
    required this.wedgeCount,
    required this.focal,
    required this.layerOpacity,
  });

  final Size size;
  final double turns;
  final double scale;
  final int wedgeCount;
  final SunburstFocal focal;
  final double layerOpacity;

  Alignment get _rotateAlignment => switch (focal) {
        SunburstFocal.center => Alignment.center,
        SunburstFocal.bottomCenter => Alignment.bottomCenter,
      };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        alignment: _rotateAlignment,
        angle: turns * math.pi * 2,
        child: Opacity(
          opacity: layerOpacity,
          child: CustomPaint(
            size: size,
            painter: _ProceduralSunburstPainter(
              scale: scale,
              wedgeCount: wedgeCount,
              focal: focal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProceduralSunburstPainter extends CustomPainter {
  const _ProceduralSunburstPainter({
    required this.scale,
    required this.wedgeCount,
    required this.focal,
  });

  static const _white10 = Color(0x1AFFFFFF);
  static const _white20 = Color(0x33FFFFFF);

  final double scale;
  final int wedgeCount;
  final SunburstFocal focal;

  Offset _focalPoint(Size size) {
    return switch (focal) {
      SunburstFocal.center => size.center(Offset.zero),
      SunburstFocal.bottomCenter => Offset(size.width / 2, size.height),
    };
  }

  double _coverRadius(Offset center, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    var maxDist = 0.0;
    for (final corner in corners) {
      maxDist = math.max(maxDist, (corner - center).distance);
    }
    return maxDist * scale;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = _focalPoint(size);
    final radius = _coverRadius(center, size);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / wedgeCount;

    for (var i = 0; i < wedgeCount; i++) {
      if (i.isOdd) continue;
      final color = (i ~/ 2).isEven ? _white10 : _white20;
      final paint = Paint()..color = color;
      canvas.drawArc(rect, i * sweep, sweep, true, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProceduralSunburstPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.wedgeCount != wedgeCount ||
      oldDelegate.focal != focal;
}
