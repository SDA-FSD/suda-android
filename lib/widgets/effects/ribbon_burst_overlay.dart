import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 직사각형 리본 폭죽. 터치 통과, 배경 딤 없음.
class RibbonBurstOverlay extends StatefulWidget {
  final VoidCallback onCompleted;

  const RibbonBurstOverlay({
    super.key,
    required this.onCompleted,
  });

  @override
  State<RibbonBurstOverlay> createState() => _RibbonBurstOverlayState();
}

class _RibbonBurstOverlayState extends State<RibbonBurstOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 2800);
  static const int _ribbonCount = 72;

  late final AnimationController _controller;
  late final List<_Ribbon> _ribbons;
  final math.Random _random = math.Random();
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ribbons = List<_Ribbon>.generate(
      _ribbonCount,
      (_) => _Ribbon.burst(_random),
    );
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addListener(_step)
      ..forward().then((_) {
        if (mounted) widget.onCompleted();
      });
  }

  void _step() {
    final elapsed = _controller.lastElapsedDuration ?? Duration.zero;
    var dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (dt > 0.05) dt = 1 / 60;
    for (final ribbon in _ribbons) {
      ribbon.step(dt);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RibbonBurstPainter(
          ribbons: _ribbons,
          progress: _controller,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Ribbon {
  static const List<Color> _palette = [
    Color(0xFFFF5A5A),
    Color(0xFFFFB800),
    Color(0xFF62FF00),
    Color(0xFF0CABA8),
    Color(0xFF80D7CF),
    Color(0xFF5B8CFF),
    Color(0xFFE85DFF),
    Color(0xFFFF7A1A),
    Color(0xFFFFE566),
    Color(0xFFFF6B9D),
  ];

  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  double rx;
  double ry;
  double rz;
  double vrx;
  double vry;
  double vrz;
  double width;
  double height;
  Color color;

  _Ribbon({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.rx,
    required this.ry,
    required this.rz,
    required this.vrx,
    required this.vry,
    required this.vrz,
    required this.width,
    required this.height,
    required this.color,
  });

  factory _Ribbon.burst(math.Random random) {
    final theta = random.nextDouble() * math.pi * 2;
    final phi = random.nextDouble() * math.pi * 0.75 + 0.12;
    final speed = 420 + random.nextDouble() * 580;
    return _Ribbon(
      x: 0,
      y: 0,
      z: 0,
      vx: math.sin(phi) * math.cos(theta) * speed,
      vy: -math.cos(phi) * speed - 180,
      vz: math.sin(phi) * math.sin(theta) * speed,
      rx: random.nextDouble() * math.pi * 2,
      ry: random.nextDouble() * math.pi * 2,
      rz: random.nextDouble() * math.pi * 2,
      vrx: (random.nextDouble() - 0.5) * 14,
      vry: (random.nextDouble() - 0.5) * 18,
      vrz: (random.nextDouble() - 0.5) * 10,
      width: 7 + random.nextDouble() * 8,
      height: 22 + random.nextDouble() * 28,
      color: _palette[random.nextInt(_palette.length)],
    );
  }

  void step(double dt) {
    vy += 920 * dt;
    vx *= math.pow(0.985, dt * 60).toDouble();
    vy *= math.pow(0.992, dt * 60).toDouble();
    vz *= math.pow(0.985, dt * 60).toDouble();
    x += vx * dt;
    y += vy * dt;
    z += vz * dt;
    rx += vrx * dt;
    ry += vry * dt;
    rz += vrz * dt;
  }
}

class _RibbonBurstPainter extends CustomPainter {
  static const double _focal = 900;
  static const double _fadeStart = 0.82;

  final List<_Ribbon> ribbons;
  final Animation<double> progress;

  _RibbonBurstPainter({
    required this.ribbons,
    required this.progress,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final fade = t < _fadeStart
        ? 1.0
        : (1.0 - (t - _fadeStart) / (1.0 - _fadeStart)).clamp(0.0, 1.0);
    if (fade <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final ordered = List<_Ribbon>.from(ribbons)
      ..sort((a, b) => b.z.compareTo(a.z));

    for (final ribbon in ordered) {
      final denom = _focal + ribbon.z;
      if (denom <= 40) continue;
      final scale = _focal / denom;
      final px = cx + ribbon.x * scale;
      final py = cy + ribbon.y * scale;
      if (px < -80 || px > size.width + 80) continue;
      if (py < -80 || py > size.height + 80) continue;

      final facing = math.cos(ribbon.ry) * math.cos(ribbon.rx);
      final shade = facing < 0 ? 0.52 : (0.72 + 0.28 * facing.abs());
      paint.color = Color.lerp(Colors.black, ribbon.color, shade)!
          .withValues(alpha: fade);

      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..translateByDouble(px, py, 0, 1)
        ..rotateX(ribbon.rx)
        ..rotateY(ribbon.ry)
        ..rotateZ(ribbon.rz)
        ..scaleByDouble(scale, scale, 1, 1);

      canvas.save();
      canvas.transform(matrix.storage);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: ribbon.width,
          height: ribbon.height,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RibbonBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ribbons != ribbons;
  }
}
