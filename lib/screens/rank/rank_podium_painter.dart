import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 포디움 wireframe 로컬 기하 (원점 = 베이스 왼쪽 상단).
/// 원본 384폭 · 경계 0.5/132.5/258.5/384.5 에서
/// 폭 408(+24)로 균등 +8씩 확장. y·색·그라디언트 방향은 원본 유지.
class RankPodiumGeometry {
  RankPodiumGeometry._();

  static const width = 408.0;
  /// 440 프레임 안 좌우 여백 균등: (440-408)/2 = 16.
  static const baseXInFrame = 16.0;

  // 세로 경계 (공유 무결성: x1=2·4번, x2=5·7번)
  static const x0 = 0.5; // 2등 왼쪽 바깥
  static const w2 = 140.0; // 132+8
  static const w1 = 134.0; // 126+8
  static const w3 = 134.0; // 126+8
  static const x1 = x0 + w2; // 140.5 — 2등|1등
  static const x2 = x1 + w1; // 274.5 — 1등|3등
  static const x3 = x2 + w3; // 408.5 — 3등 오른쪽 바깥

  // 가로선 x (세로선 ±0.5 — 원본 SVG와 동일 규칙)
  static const h2x1 = x0 - 0.5; // 0
  static const h2x2 = x1 + 0.5; // 141
  static const h1x1 = x1 - 0.5; // 140
  static const h1x2 = x2 + 0.5; // 275
  static const h3x1 = x2 - 0.5; // 274
  static const h3x2 = x3 + 0.5; // 409

  // 슬롯/숫자 셀: 세로 경계 사이 폭
  static const step2W = w2;
  static const step1W = w1;
  static const step3W = w3;
  static const step1LocalX = x1 - 0.5; // 140
  static const step3LocalX = x2 - 0.5; // 274
}

/// SVG 포디움 wireframe 9선 — 직선 stroke가 아니라
/// 끝은 뾰족·중앙은 볼록한 방추형(filled cubic path).
/// 각 도형: #FFFFFF@20% → 끝색@100% 선형 그라디언트 (세로 벡터 y1→y2).
/// 가로 도형도 그라디언트는 수직 벡터 유지 (원본 SVG linearGradient와 동일).
class RankPodiumBasePainter extends CustomPainter {
  const RankPodiumBasePainter({required this.scale});

  final double scale;

  /// #FFFFFF @ 20%
  static const _strokeStart = Color(0x33FFFFFF);
  static const _end5626A1 = Color(0xFF5626A1);
  static const _end4E2292 = Color(0xFF4E2292);
  static const _end8A38F5 = Color(0xFF8A38F5);
  static const _end5928A6 = Color(0xFF5928A6);

  /// Podium.png(1155×450 = 3×385×150) 실측: tip hw≈0.17, mid hw≈0.50
  static const _maxHalf = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    // 1) 2등 왼쪽 바깥 세로
    _fillVerticalSpindle(canvas, RankPodiumGeometry.x0, 65, 133, _end5626A1);
    // 2) 2등|1등 경계 세로 (2등 쪽)
    _fillVerticalSpindle(canvas, RankPodiumGeometry.x1, 65, 133, _end4E2292);
    // 3) 2등 윗변 가로 — 그라디언트 y 65→133
    _fillHorizontalSpindle(
      canvas,
      64.5,
      RankPodiumGeometry.h2x1,
      RankPodiumGeometry.h2x2,
      65,
      133,
      _end8A38F5,
    );
    // 4) 2등|1등 경계 세로 (1등 쪽) — x == 2번
    _fillVerticalSpindle(canvas, RankPodiumGeometry.x1, 2, 148, _end5626A1);
    // 5) 1등|3등 경계 세로 (1등 쪽)
    _fillVerticalSpindle(canvas, RankPodiumGeometry.x2, 2, 148, _end5928A6);
    // 6) 1등 윗변 가로 — 그라디언트 y 2→148
    _fillHorizontalSpindle(
      canvas,
      0.5,
      RankPodiumGeometry.h1x1,
      RankPodiumGeometry.h1x2,
      2,
      148,
      _end8A38F5,
    );
    // 7) 1등|3등 경계 세로 (3등 쪽) — x == 5번
    _fillVerticalSpindle(canvas, RankPodiumGeometry.x2, 82, 150, _end5626A1);
    // 8) 3등 오른쪽 바깥 세로
    _fillVerticalSpindle(canvas, RankPodiumGeometry.x3, 82, 150, _end4E2292);
    // 9) 3등 윗변 가로 — 그라디언트 y 82→150
    _fillHorizontalSpindle(
      canvas,
      81.5,
      RankPodiumGeometry.h3x1,
      RankPodiumGeometry.h3x2,
      82,
      150,
      _end8A38F5,
    );
  }

  /// 세로 방추: tip(x,y1) → 중앙 볼록 → tip(x,y2). cubicTo만 사용.
  Path _verticalSpindlePath(double x, double y1, double y2) {
    final s = scale;
    final sx = x * s;
    final sy1 = y1 * s;
    final sy2 = y2 * s;
    final mid = (sy1 + sy2) / 2;
    final hw = _maxHalf * s;
    final len = (sy2 - sy1).abs();
    // 끝 구간·볼록 제어 (원본 PNG 프로파일에 맞춤)
    final tip = len * 0.18;
    final k = hw * 0.25;

    final path = Path()..moveTo(sx, sy1);
    // 우측 상단 → 중앙
    path.cubicTo(sx + k, sy1 + tip * 0.35, sx + hw, mid - tip * 0.4, sx + hw, mid);
    // 우측 중앙 → 하단 tip
    path.cubicTo(sx + hw, mid + tip * 0.4, sx + k, sy2 - tip * 0.35, sx, sy2);
    // 좌측 하단 → 중앙
    path.cubicTo(sx - k, sy2 - tip * 0.35, sx - hw, mid + tip * 0.4, sx - hw, mid);
    // 좌측 중앙 → 상단 tip
    path.cubicTo(sx - hw, mid - tip * 0.4, sx - k, sy1 + tip * 0.35, sx, sy1);
    path.close();
    return path;
  }

  /// 가로 방추: tip(x1,y) → 중앙 볼록 → tip(x2,y). cubicTo만 사용.
  Path _horizontalSpindlePath(double y, double x1, double x2) {
    final s = scale;
    final sy = y * s;
    final sx1 = x1 * s;
    final sx2 = x2 * s;
    final mid = (sx1 + sx2) / 2;
    final hw = _maxHalf * s;
    final len = (sx2 - sx1).abs();
    final tip = len * 0.18;
    final k = hw * 0.25;

    final path = Path()..moveTo(sx1, sy);
    // 상단 좌→중앙
    path.cubicTo(sx1 + tip * 0.35, sy - k, mid - tip * 0.4, sy - hw, mid, sy - hw);
    // 상단 중앙→우 tip
    path.cubicTo(mid + tip * 0.4, sy - hw, sx2 - tip * 0.35, sy - k, sx2, sy);
    // 하단 우→중앙
    path.cubicTo(sx2 - tip * 0.35, sy + k, mid + tip * 0.4, sy + hw, mid, sy + hw);
    // 하단 중앙→좌 tip
    path.cubicTo(mid - tip * 0.4, sy + hw, sx1 + tip * 0.35, sy + k, sx1, sy);
    path.close();
    return path;
  }

  void _fillVerticalSpindle(
    Canvas canvas,
    double x,
    double y1,
    double y2,
    Color endColor,
  ) {
    final s = scale;
    final path = _verticalSpindlePath(x, y1, y2);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(x * s, y1 * s),
        Offset(x * s, y2 * s),
        [_strokeStart, endColor],
      );
    canvas.drawPath(path, paint);
  }

  void _fillHorizontalSpindle(
    Canvas canvas,
    double y,
    double x1,
    double x2,
    double gradY1,
    double gradY2,
    Color endColor,
  ) {
    final s = scale;
    final path = _horizontalSpindlePath(y, x1, x2);
    // 가로 도형이어도 그라디언트 벡터는 수직 (원본 SVG)
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        Offset(x1 * s, gradY1 * s),
        Offset(x1 * s, gradY2 * s),
        [_strokeStart, endColor],
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RankPodiumBasePainter oldDelegate) =>
      scale != oldDelegate.scale;
}

/// Figma 포디움 큰 숫자.
/// white · fill-opacity 0.19 · group opacity 0.2 · mix-blend-mode: plus-lighter
/// 바깥쪽 그림자: offset(20,20) blur 20 · #000 @ 30% (아바타 BoxShadow와 동일 톤).
class PodiumRankNumber extends StatelessWidget {
  const PodiumRankNumber({
    super.key,
    required this.digit,
    required this.style,
    required this.scale,
  });

  final String digit;
  final TextStyle style;
  final double scale;

  static const _groupOpacity = 0.2;
  static const _fillOpacity = 0.19;
  static const _shadowOffset = 20.0;
  /// Figma blur 20 → ImageFilter sigma ≈ 10 (Skia).
  static const _shadowSigma = 10.0;
  static const _shadowOpacity = 0.30;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final digitStyle = style.copyWith(height: 1, letterSpacing: 0);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(_shadowOffset * s, _shadowOffset * s),
          child: Opacity(
            opacity: _shadowOpacity,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: _shadowSigma * s,
                sigmaY: _shadowSigma * s,
                tileMode: ui.TileMode.decal,
              ),
              child: Text(
                digit,
                textAlign: TextAlign.center,
                style: digitStyle.copyWith(color: Colors.black),
              ),
            ),
          ),
        ),
        _PlusLighterBlend(
          opacity: _groupOpacity,
          child: Text(
            digit,
            textAlign: TextAlign.center,
            style: digitStyle.copyWith(
              color: Colors.white.withValues(alpha: _fillOpacity),
            ),
          ),
        ),
      ],
    );
  }
}

/// CSS `mix-blend-mode: plus-lighter` + group opacity.
class _PlusLighterBlend extends SingleChildRenderObjectWidget {
  const _PlusLighterBlend({
    required this.opacity,
    required Widget child,
  }) : super(child: child);

  final double opacity;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPlusLighterBlend(opacity);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPlusLighterBlend renderObject,
  ) {
    renderObject.opacity = opacity;
  }
}

class _RenderPlusLighterBlend extends RenderProxyBox {
  _RenderPlusLighterBlend(this._opacity);

  double _opacity;
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = offset & size;
    context.canvas.saveLayer(rect, Paint()..blendMode = BlendMode.plus);
    context.canvas.saveLayer(
      rect,
      Paint()..color = Color.fromRGBO(255, 255, 255, _opacity),
    );
    super.paint(context, offset);
    context.canvas.restore();
    context.canvas.restore();
  }
}
