import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Profile 무료 사용자용 Premium CTA (레벨바 아래).
class ProfileGoPremiumButton extends StatefulWidget {
  final String title;
  final String exploreLabel;
  final VoidCallback onTap;

  const ProfileGoPremiumButton({
    super.key,
    required this.title,
    required this.exploreLabel,
    required this.onTap,
  });

  @override
  State<ProfileGoPremiumButton> createState() => _ProfileGoPremiumButtonState();
}

class _ProfileGoPremiumButtonState extends State<ProfileGoPremiumButton>
    with SingleTickerProviderStateMixin {
  static const _buttonHeight = 52.0;
  static const _iconToTitleGap = 12.0;
  static const _titleToExploreGap = 20.0;
  static const _contentPadding = EdgeInsets.only(left: 20, right: 28);
  static const _titleMinFontSize = 10.0;
  static const _buttonFillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8A38F5), Color(0xFF280752)],
  );
  static const _titleBlendMode = BlendMode.softLight;
  static const _glowOpacity = 0.55;
  static const _glowBlur = 10.0;
  /// 한 방향 횡단(홈→끝 또는 끝→홈)에 걸리는 시간 범위.
  static const _legDurationMin = 2.4;
  static const _legDurationMax = 3.8;
  static const _bobAmplitude = 3.5;
  static const _bobHz = 0.7;

  final GlobalKey _contentStackKey = GlobalKey();
  final GlobalKey _starKey = GlobalKey();
  final GlobalKey _exploreKey = GlobalKey();
  final math.Random _rng = math.Random();

  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _elapsedSec = 0;

  /// 글로우 중심이 움직일 수 있는 영역 (stack 로컬 좌표).
  Rect _floatBounds = Rect.zero;
  bool _boundsMeasured = false;
  bool _spawned = false;

  late _GlowMote _glow1;
  late _GlowMote _glow2;

  @override
  void initState() {
    super.initState();
    _glow1 = _GlowMote.idle();
    _glow2 = _GlowMote.idle();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureFloatBounds());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileGoPremiumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureFloatBounds());
  }

  void _measureFloatBounds() {
    if (!mounted) return;

    final stackContext = _contentStackKey.currentContext;
    final starContext = _starKey.currentContext;
    final exploreContext = _exploreKey.currentContext;
    if (stackContext == null ||
        starContext == null ||
        exploreContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureFloatBounds());
      return;
    }

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final starBox = starContext.findRenderObject() as RenderBox?;
    final exploreBox = exploreContext.findRenderObject() as RenderBox?;
    if (stackBox == null ||
        starBox == null ||
        exploreBox == null ||
        !stackBox.hasSize ||
        starBox.size.isEmpty ||
        exploreBox.size.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureFloatBounds());
      return;
    }

    final size = stackBox.size;
    final inset = _GlowOrb.size * 0.35;
    final bounds = Rect.fromLTRB(
      inset,
      inset * 0.55,
      math.max(inset + 1, size.width - inset),
      math.max(inset * 0.55 + 1, size.height - inset * 0.55),
    );

    final starCenter = _clampPoint(
      starBox.localToGlobal(
        starBox.size.center(Offset.zero),
        ancestor: stackBox,
      ),
      bounds,
    );
    final exploreCenter = _clampPoint(
      exploreBox.localToGlobal(
        exploreBox.size.center(Offset.zero),
        ancestor: stackBox,
      ),
      bounds,
    );

    // 아직 좌/우로 벌어지지 않았으면(레이아웃 미완료) 다음 프레임에 재시도.
    if (exploreCenter.dx - starCenter.dx < 48) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureFloatBounds());
      return;
    }

    setState(() {
      _floatBounds = bounds;
      _boundsMeasured = true;
      if (!_spawned) {
        // Glow1: 별(왼쪽) → 오른쪽 끝 → 복귀
        // Glow2: 혜택보기(오른쪽) → 왼쪽 끝 → 복귀
        _glow1 = _GlowMote.shuttle(
          home: starCenter,
          startsOnLeft: true,
          bobPhase: 0,
        );
        _glow2 = _GlowMote.shuttle(
          home: exploreCenter,
          startsOnLeft: false,
          bobPhase: math.pi * 0.9,
        );
        _startLeg(_glow1, outbound: true);
        _startLeg(_glow2, outbound: true);
        _spawned = true;
      } else {
        _glow1.home = _clampPoint(_glow1.home, bounds);
        _glow2.home = _clampPoint(_glow2.home, bounds);
        _glow1.clampTo(bounds);
        _glow2.clampTo(bounds);
      }
    });
  }

  Offset _clampPoint(Offset point, Rect bounds) {
    return Offset(
      point.dx.clamp(bounds.left, bounds.right),
      point.dy.clamp(bounds.top, bounds.bottom),
    );
  }

  double _farXFor(_GlowMote mote) =>
      mote.startsOnLeft ? _floatBounds.right : _floatBounds.left;

  void _startLeg(_GlowMote mote, {required bool outbound}) {
    mote.goingOutbound = outbound;
    mote.legElapsed = 0;
    mote.legDuration =
        _legDurationMin + _rng.nextDouble() * (_legDurationMax - _legDurationMin);
    mote.from = mote.position;
    if (outbound) {
      mote.midBouncesLeft = _rng.nextInt(4); // 0~3
      mote.to = Offset(
        _farXFor(mote),
        _floatBounds.top + _rng.nextDouble() * _floatBounds.height,
      );
    } else {
      mote.midBouncesLeft = 0;
      mote.to = Offset(
        mote.home.dx,
        mote.home.dy + (_rng.nextDouble() - 0.5) * 6,
      );
      mote.to = _clampPoint(mote.to, _floatBounds);
    }
    mote._rebuildBouncePoints(_rng, _floatBounds);
  }

  void _onTick(Duration elapsed) {
    if (!_boundsMeasured || !_spawned || !mounted) {
      _lastElapsed = elapsed;
      return;
    }

    final rawDt = _lastElapsed == null
        ? 1 / 60
        : (elapsed - _lastElapsed!).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final dt = rawDt.clamp(0.0, 1 / 30);
    _elapsedSec += dt;

    _stepMote(_glow1, dt);
    _stepMote(_glow2, dt);

    setState(() {});
  }

  void _stepMote(_GlowMote mote, double dt) {
    mote.legElapsed += dt;
    var t = (mote.legElapsed / mote.legDuration).clamp(0.0, 1.0);
    // 두둥실 ease
    final eased = Curves.easeInOut.transform(t);

    var x = mote.from.dx + (mote.to.dx - mote.from.dx) * eased;
    var y = mote.from.dy + (mote.to.dy - mote.from.dy) * eased;

    // 중간 튕김: 진행 중 랜덤 지점에서 Y를 짧게 튀김
    for (final bounce in mote.bouncePoints) {
      final influence = math.exp(-math.pow((eased - bounce.at) * 14, 2).toDouble());
      y += bounce.dy * influence;
    }

    mote.position = Offset(
      x.clamp(_floatBounds.left, _floatBounds.right),
      y.clamp(_floatBounds.top, _floatBounds.bottom),
    );

    if (t >= 1.0) {
      // 끝 도착 → 방향 반전
      _startLeg(mote, outbound: !mote.goingOutbound);
    }
  }

  Offset _displayCenter(_GlowMote mote) {
    final bob = math.sin(
          (_elapsedSec * _bobHz * 2 * math.pi) + mote.bobPhase,
        ) *
        _bobAmplitude;
    return Offset(mote.position.dx, mote.position.dy + bob);
  }

  Widget _buildGlowLayer(Offset center, double blurSigma) {
    return Transform.translate(
      offset: Offset(
        center.dx - _GlowOrb.size / 2,
        center.dy - _GlowOrb.size / 2,
      ),
      child: Opacity(
        opacity: _spawned ? _glowOpacity : 0.0,
        child: RepaintBoundary(
          child: _GlowOrb(blurSigma: blurSigma),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final radius = _buttonHeight / 2;
    final innerRadius = radius - 1;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: _buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(innerRadius),
                gradient: _buttonFillGradient,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Padding(
                  padding: _contentPadding,
                  child: Stack(
                    key: _contentStackKey,
                    clipBehavior: Clip.none,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildGlowLayer(_displayCenter(_glow1), _glowBlur),
                          _buildGlowLayer(_displayCenter(_glow2), _glowBlur),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          KeyedSubtree(
                            key: _starKey,
                            child: const _PremiumStarIcon(),
                          ),
                          const SizedBox(width: _iconToTitleGap),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _ScaledSingleLineText(
                                text: widget.title,
                                baseStyle: theme.headlineSmall!.copyWith(
                                  height: 1.0,
                                ),
                                minFontSize: _titleMinFontSize,
                                blendMode: _titleBlendMode,
                              ),
                            ),
                          ),
                          const SizedBox(width: _titleToExploreGap),
                          KeyedSubtree(
                            key: _exploreKey,
                            child: _ExplorePill(label: widget.exploreLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBounce {
  const _GlowBounce({required this.at, required this.dy});
  final double at; // 0~1 progress
  final double dy;
}

class _GlowMote {
  Offset position;
  Offset home;
  Offset from;
  Offset to;
  bool startsOnLeft;
  bool goingOutbound;
  double legElapsed;
  double legDuration;
  int midBouncesLeft;
  double bobPhase;
  List<_GlowBounce> bouncePoints;

  _GlowMote({
    required this.position,
    required this.home,
    required this.from,
    required this.to,
    required this.startsOnLeft,
    required this.goingOutbound,
    required this.legElapsed,
    required this.legDuration,
    required this.midBouncesLeft,
    required this.bobPhase,
    required this.bouncePoints,
  });

  factory _GlowMote.idle() => _GlowMote(
        position: Offset.zero,
        home: Offset.zero,
        from: Offset.zero,
        to: Offset.zero,
        startsOnLeft: true,
        goingOutbound: true,
        legElapsed: 0,
        legDuration: 1,
        midBouncesLeft: 0,
        bobPhase: 0,
        bouncePoints: const [],
      );

  factory _GlowMote.shuttle({
    required Offset home,
    required bool startsOnLeft,
    required double bobPhase,
  }) {
    return _GlowMote(
      position: home,
      home: home,
      from: home,
      to: home,
      startsOnLeft: startsOnLeft,
      goingOutbound: true,
      legElapsed: 0,
      legDuration: 1,
      midBouncesLeft: 0,
      bobPhase: bobPhase,
      bouncePoints: const [],
    );
  }

  void _rebuildBouncePoints(math.Random rng, Rect bounds) {
    if (!goingOutbound || midBouncesLeft <= 0) {
      bouncePoints = const [];
      return;
    }
    final count = midBouncesLeft;
    final points = <_GlowBounce>[];
    for (var i = 0; i < count; i++) {
      points.add(
        _GlowBounce(
          at: 0.2 + rng.nextDouble() * 0.6,
          dy: (rng.nextDouble() - 0.5) * bounds.height * 0.7,
        ),
      );
    }
    points.sort((a, b) => a.at.compareTo(b.at));
    bouncePoints = points;
  }

  void clampTo(Rect bounds) {
    position = Offset(
      position.dx.clamp(bounds.left, bounds.right),
      position.dy.clamp(bounds.top, bounds.bottom),
    );
    home = Offset(
      home.dx.clamp(bounds.left, bounds.right),
      home.dy.clamp(bounds.top, bounds.bottom),
    );
    from = Offset(
      from.dx.clamp(bounds.left, bounds.right),
      from.dy.clamp(bounds.top, bounds.bottom),
    );
    to = Offset(
      to.dx.clamp(bounds.left, bounds.right),
      to.dy.clamp(bounds.top, bounds.bottom),
    );
  }
}

/// 별 뱃지 에셋을 블러해 빛처럼 보이게 한 글로우.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.blurSigma});

  final double blurSigma;

  static const size = 56.0;
  static const _asset = 'assets/images/icons/paywall_star_badge.png';

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
        tileMode: TileMode.decal,
      ),
      child: Image.asset(
        _asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// 단일 행 텍스트. 말줄임·클립 없이 [minFontSize]까지 축소.
class _ScaledSingleLineText extends StatelessWidget {
  const _ScaledSingleLineText({
    required this.text,
    required this.baseStyle,
    required this.minFontSize,
    this.alignment = Alignment.center,
    this.blendMode,
  });

  final String text;
  final TextStyle baseStyle;
  final double minFontSize;
  final Alignment alignment;
  final BlendMode? blendMode;

  /// 측정용 — color만 사용(foreground와 분리).
  TextStyle _measureStyle(double fontSize) {
    return baseStyle.copyWith(
      fontSize: fontSize,
      color: Colors.white,
    );
  }

  /// 렌더용 — [blendMode]가 있으면 color 없이 foreground만 설정.
  TextStyle _displayStyle(double fontSize) {
    final scaled = baseStyle.copyWith(fontSize: fontSize);
    final mode = blendMode;
    if (mode == null) {
      return scaled.copyWith(color: Colors.white);
    }
    return TextStyle(
      fontSize: fontSize,
      fontWeight: scaled.fontWeight,
      fontStyle: scaled.fontStyle,
      fontFamily: scaled.fontFamily,
      fontFamilyFallback: scaled.fontFamilyFallback,
      fontVariations: scaled.fontVariations,
      letterSpacing: scaled.letterSpacing,
      wordSpacing: scaled.wordSpacing,
      textBaseline: scaled.textBaseline,
      height: scaled.height,
      leadingDistribution: scaled.leadingDistribution,
      locale: scaled.locale,
      foreground: Paint()
        ..color = Colors.white
        ..blendMode = mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return const SizedBox.shrink();
        }

        double measureWidth(double size) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: _measureStyle(size),
            ),
            maxLines: 1,
            textDirection: Directionality.of(context),
          )..layout();
          return painter.width;
        }

        var fontSize = baseStyle.fontSize ?? 20;
        var chosen = minFontSize;
        for (var size = fontSize; size >= minFontSize; size -= 0.25) {
          if (measureWidth(size) <= maxWidth) {
            chosen = size;
            break;
          }
        }
        fontSize = chosen;

        final displayStyle = _displayStyle(fontSize);
        final textWidget = Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: displayStyle,
        );

        if (measureWidth(fontSize) > maxWidth) {
          return Align(
            alignment: alignment,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignment,
              child: textWidget,
            ),
          );
        }

        return Align(
          alignment: alignment,
          child: textWidget,
        );
      },
    );
  }
}

/// 별 아이콘 — `paywall_star_badge.png`, inside stroke 1.2px, 하향 drop shadow.
class _PremiumStarIcon extends StatelessWidget {
  const _PremiumStarIcon();

  static const _size = 28.0;
  static const _insideStroke = 1.2;
  static const _asset = 'assets/images/icons/paywall_star_badge.png';
  static const _outlineGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF51218F), Color(0xFF8A38F5)],
  );
  // Paywall PREMIUM 뱃지와 동일 하향 그림자 (`paywall.dart` `_premiumBadgeShadow`).
  static const _badgeShadow = BoxShadow(
    color: Color(0x54000000),
    offset: Offset(0, 4),
    blurRadius: 4,
    spreadRadius: 0,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: OverflowBox(
        maxHeight: _size + 4,
        alignment: Alignment.center,
        child: SizedBox(
          width: _size,
          height: _size,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _outlineGradient,
              boxShadow: [_badgeShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(_insideStroke),
              child: ClipOval(
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  _asset,
                  width: _size - _insideStroke * 2,
                  height: _size - _insideStroke * 2,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplorePill extends StatelessWidget {
  const _ExplorePill({required this.label});

  final String label;

  static const _width = 66.0;
  static const _height = 24.0;
  static const _radius = _height / 2;
  static const _fillOpacity = 0.038;
  static const _exploreMinFontSize = 9.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              color: Colors.white.withValues(alpha: _fillOpacity),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Center(
                child: _ScaledSingleLineText(
                  text: label,
                  baseStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontVariations: const [FontVariation('wght', 400)],
                        height: 1.0,
                      ),
                  minFontSize: _exploreMinFontSize,
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: const _ExplorePillStrokePainter(
              strokeWidth: 1,
              radius: _radius,
            ),
          ),
        ],
      ),
    );
  }
}

/// Explorar pill outside stroke — Paywall `_MelhorBadgeStrokePainter`와 동일 seam 처리.
class _ExplorePillStrokePainter extends CustomPainter {
  const _ExplorePillStrokePainter({
    required this.strokeWidth,
    required this.radius,
  });

  final double strokeWidth;
  final double radius;

  static const _sweep = SweepGradient(
    colors: [
      Color(0x29FFFFFF), // 0.0 == 1.0 seam
      Color(0x4FFFFFFF), // 31% @ 0.12
      Color(0x00FFFFFF), // 0%   @ 0.37
      Color(0x4FFFFFFF), // 31% @ 0.62
      Color(0x00FFFFFF), // 0%   @ 0.87
      Color(0x29FFFFFF), // ~16% @ 1.0
    ],
    stops: [0.0, 0.12, 0.37, 0.62, 0.87, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      -half,
      -half,
      size.width + strokeWidth,
      size.height + strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius + half),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..shader = _sweep.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ExplorePillStrokePainter oldDelegate) =>
      strokeWidth != oldDelegate.strokeWidth || radius != oldDelegate.radius;
}
