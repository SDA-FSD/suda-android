import 'dart:ui';

import 'package:flutter/material.dart';

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
  // 4s 대기 → 0.3s 이동 → 1s 대기 → 1s 복귀 = 6.3s
  static const _glowCycleDuration = Duration(milliseconds: 6300);
  static const _glowOpacity = 0.62;

  final GlobalKey _contentStackKey = GlobalKey();
  final GlobalKey _starKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _exploreKey = GlobalKey();

  late final AnimationController _glowController;
  late final Animation<double> _glowProgress;

  Offset _glow1Start = const Offset(14, 25);
  Offset _glow1End = const Offset(180, 25);
  Offset _glow2Start = const Offset(80, 30);
  Offset _glow2End = const Offset(40, 25);
  bool _anchorsMeasured = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: _glowCycleDuration,
    )..repeat();

    _glowProgress = TweenSequence<double>([
      // 0~4000ms: 시작 위치 대기
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 4000),
      // 4000~4300ms: 목적지로 빠른 이동
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
      // 4300~5300ms: 목적지 대기
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1000),
      // 5300~6300ms: 원위치 복귀
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1000,
      ),
    ]).animate(_glowController);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureGlowAnchors());
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileGoPremiumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exploreLabel != widget.exploreLabel ||
        oldWidget.title != widget.title) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureGlowAnchors());
    }
  }

  TextStyle _titleMeasureStyle(double fontSize) {
    final base = Theme.of(context).textTheme.headlineSmall!.copyWith(
          height: 1.0,
          color: Colors.white,
        );
    return base.copyWith(fontSize: fontSize);
  }

  double _resolveTitleFontSize(String title, double maxWidth) {
    var fontSize = Theme.of(context).textTheme.headlineSmall!.fontSize ?? 20;
    while (fontSize > _titleMinFontSize) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: _titleMeasureStyle(fontSize)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width <= maxWidth) break;
      fontSize -= 0.5;
    }
    return fontSize;
  }

  void _measureGlowAnchors() {
    if (!mounted) return;

    final stackContext = _contentStackKey.currentContext;
    final starContext = _starKey.currentContext;
    final titleContext = _titleKey.currentContext;
    final exploreContext = _exploreKey.currentContext;
    if (stackContext == null ||
        starContext == null ||
        titleContext == null ||
        exploreContext == null) {
      return;
    }

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final starBox = starContext.findRenderObject() as RenderBox?;
    final titleBox = titleContext.findRenderObject() as RenderBox?;
    final exploreBox = exploreContext.findRenderObject() as RenderBox?;
    if (stackBox == null ||
        starBox == null ||
        titleBox == null ||
        exploreBox == null) {
      return;
    }

    final starCenter = starBox.localToGlobal(
      starBox.size.center(Offset.zero),
      ancestor: stackBox,
    );

    final title = widget.title;
    final titleFontSize = _resolveTitleFontSize(title, titleBox.size.width);
    final titleStyle = _titleMeasureStyle(titleFontSize);

    // Glow 2 시작: 알약 버튼 전체 가로 중앙에서 살짝 왼쪽 + 하단.
    // Stack은 content padding(좌 20·우 28) 안이라, 알약 전체 중심을 stack 좌표로 보정.
    final stackSize = stackBox.size;
    final pillCenterXInStack =
        (stackSize.width + _contentPadding.left + _contentPadding.right) / 2 -
            _contentPadding.left;
    final glow2Start = Offset(
      pillCenterXInStack - (stackSize.width * 0.08),
      stackSize.height * 0.82,
    );

    // Glow 2 끝: 제목 텍스트 시작 X + 세로 중간보다 살짝 위.
    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final titleTextWidth = titlePainter.width;
    final titleInsetX = (titleBox.size.width - titleTextWidth) / 2;
    final titleOrigin = titleBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final glow2End = titleOrigin + Offset(
      titleInsetX,
      titleBox.size.height * 0.38,
    );

    final exploreStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontVariations: const [FontVariation('wght', 400)],
          height: 1.0,
        );
    final label = widget.exploreLabel;
    final rIndex = label.toLowerCase().indexOf('r');
    final anchorIndex = rIndex >= 0 ? rIndex : label.length - 1;
    final prefix = label.substring(0, anchorIndex + 1);

    final prefixPainter = TextPainter(
      text: TextSpan(text: prefix, style: exploreStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final fullPainter = TextPainter(
      text: TextSpan(text: label, style: exploreStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final pillSize = exploreBox.size;
    final textStartX = (pillSize.width - fullPainter.width) / 2;
    final textCenterY = pillSize.height / 2;

    final exploreAnchorLocal = Offset(
      textStartX + prefixPainter.width,
      textCenterY,
    );
    final exploreAnchor = exploreBox.localToGlobal(
      exploreAnchorLocal,
      ancestor: stackBox,
    );

    setState(() {
      _glow1Start = starCenter;
      _glow1End = exploreAnchor;
      _glow2Start = glow2Start;
      _glow2End = glow2End;
      _anchorsMeasured = true;
    });
  }

  Widget _buildGlowLayer(Offset center) {
    return Transform.translate(
      offset: Offset(
        center.dx - _GlowOrb.size / 2,
        center.dy - _GlowOrb.size / 2,
      ),
      child: Opacity(
        opacity: _anchorsMeasured ? _glowOpacity : 0.0,
        child: const _GlowOrb(),
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
                      AnimatedBuilder(
                        animation: _glowProgress,
                        builder: (context, child) {
                          final t = _glowProgress.value;
                          final glow1Center =
                              Offset.lerp(_glow1Start, _glow1End, t)!;
                          final glow2Center =
                              Offset.lerp(_glow2Start, _glow2End, t)!;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildGlowLayer(glow1Center),
                              _buildGlowLayer(glow2Center),
                            ],
                          );
                        },
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
                              child: KeyedSubtree(
                                key: _titleKey,
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

///글로우
class _GlowOrb extends StatelessWidget {
  const _GlowOrb();

  static const size = 56.0;
  static const _blurSigma = 18.0;
  static const _asset = 'assets/images/icons/paywall_star_badge.png';

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: _blurSigma,
        sigmaY: _blurSigma,
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
