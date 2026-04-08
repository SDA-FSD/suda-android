import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

import '../../services/effect_anchor_registry.dart';
import '../../effects/like_progress_effect.dart';

class LikeProgressOverlay extends StatefulWidget {
  final LikeProgressEffectParams params;
  final VoidCallback onCompleted;

  const LikeProgressOverlay({
    super.key,
    required this.params,
    required this.onCompleted,
  });

  @override
  State<LikeProgressOverlay> createState() => _LikeProgressOverlayState();
}

class _LikeProgressOverlayState extends State<LikeProgressOverlay>
    with TickerProviderStateMixin {
  static const _dimColor = Color(0x99000000);
  static const _mint = Color(0xFF80D7CF);
  static const _mintLight = Color(0xFFCFFFFB);

  static const _bgAsset = 'assets/images/like_progress_bg.png';
  static const _thumbAsset = 'assets/images/like_at_result.png';
  static const _ticketAsset = 'assets/images/icons/ticket.png';
  static const _sparkleAsset = 'assets/images/like_progress_star.png';

  final GlobalKey _lvLabelKey = GlobalKey();

  late final AnimationController _phase1Ctrl;
  late final AnimationController _phase5Ctrl;
  late final AnimationController _phase6Ctrl;
  late final AnimationController _phase6WobbleCtrl;
  late final AnimationController _phase7Ctrl;
  late final AnimationController _phase8Ctrl;

  bool _phase5Visible = false;
  bool _phase8FadingOut = false;
  bool _wobbling = false;
  bool _bgVisible = true;

  int _displayLikePoint = 0;
  int _displayLevel = 0;
  double _displayProgress = 0;

  final List<_FlyingTicket> _tickets = [];
  final List<_Sparkle> _sparkles = [];
  final List<Timer> _sparkleTimers = [];
  final math.Random _random = math.Random();

  bool _sparklesActive = false;
  Timer? _phase6HapticTimer;
  int _phase6HapticGeneration = 0;

  @override
  void initState() {
    super.initState();

    _displayLikePoint = widget.params.asIsLikePoint;
    _displayLevel = widget.params.asIsLevel;
    _displayProgress = widget.params.asIsProgress.toDouble();

    _phase1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _phase5Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _phase6Ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.params.asIsLevel == widget.params.toBeLevel
            ? 1000
            : 2000,
      ),
    );
    _phase6WobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _phase7Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _phase8Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runSequence());
    });
  }

  @override
  void dispose() {
    _stopPhase6Haptics();
    for (final t in _tickets) {
      t.controller.dispose();
    }
    _disposeSparkles();
    _phase1Ctrl.dispose();
    _phase5Ctrl.dispose();
    _phase6Ctrl.dispose();
    _phase6WobbleCtrl.dispose();
    _phase7Ctrl.dispose();
    _phase8Ctrl.dispose();
    super.dispose();
  }

  Future<void> _runSequence() async {
    // 1: scale 2→0.7 + Y 0→-50 + fade-in (500ms)
    setState(() => _phase5Visible = true);
    await Future.wait([_phase1Ctrl.forward(), _phase5Ctrl.forward()]);
    if (!mounted) return;

    // 6
    await _runPhase6();
    if (!mounted) return;

    // 7
    await _phase7Ctrl.forward();
    if (!mounted) return;

    // 8
    _stopSparkles();
    setState(() {
      _bgVisible = false;
      _phase8FadingOut = true;
    });
    await _phase8Ctrl.forward();
    if (!mounted) return;

    widget.onCompleted();
  }

  Future<void> _runPhase6() async {
    final p = widget.params;
    final likeFrom = p.asIsLikePoint;
    final likeTo = p.toBeLikePoint;

    final beforeLevel = p.asIsLevel;
    final afterLevel = p.toBeLevel;
    final beforeProgress = p.asIsProgress.toDouble();
    final afterProgress = p.toBeProgress.toDouble();

    final levelUps = math.max(0, afterLevel - beforeLevel);

    int lastTicketLevel = beforeLevel;

    _phase6Ctrl.addListener(() {
      final t = _phase6Ctrl.value;

      final like = (likeFrom + (likeTo - likeFrom) * t).round();
      final lp = _computeLevelProgress(
        t: t,
        beforeLevel: beforeLevel,
        afterLevel: afterLevel,
        beforeProgress: beforeProgress,
        afterProgress: afterProgress,
      );

      if (mounted) {
        setState(() {
          _displayLikePoint = like;
          _displayLevel = lp.$1;
          _displayProgress = lp.$2;
        });
      }

      if (levelUps <= 0) return;

      final currentLevel = lp.$1;
      if (currentLevel > lastTicketLevel) {
        for (var lv = lastTicketLevel + 1; lv <= currentLevel; lv++) {
          _spawnTicket();
        }
        lastTicketLevel = currentLevel;
      }
    });

    setState(() {
      _wobbling = true;
    });
    _startSparkles();
    _startPhase6Haptics();
    unawaited(
      _phase6WobbleCtrl.forward().then((_) {
        if (mounted) setState(() => _wobbling = false);
      }),
    );

    await _phase6Ctrl.forward();
    _stopPhase6Haptics();
  }

  (int, double) _computeLevelProgress({
    required double t,
    required int beforeLevel,
    required int afterLevel,
    required double beforeProgress,
    required double afterProgress,
  }) {
    if (beforeLevel == afterLevel) {
      final p = beforeProgress + t * (afterProgress - beforeProgress);
      return (beforeLevel, p.clamp(0, 100));
    }
    final levelDiff = afterLevel - beforeLevel;
    final segment1 = 100 - beforeProgress;
    final segmentLast = afterProgress;
    final total = segment1 + 100.0 * (levelDiff - 1) + segmentLast;
    final amount = (t * total).clamp(0.0, total);

    if (amount <= segment1) {
      final p = beforeProgress + (amount / segment1) * (100 - beforeProgress);
      return (beforeLevel, p);
    }
    final remaining = amount - segment1;
    final fullBars = (remaining / 100).floor().clamp(0, levelDiff - 1);
    if (fullBars < levelDiff - 1) {
      final progress = remaining - 100 * fullBars;
      return (beforeLevel + 1 + fullBars, progress.clamp(0, 100));
    }
    final p = (remaining - 100 * (levelDiff - 1)) / segmentLast * afterProgress;
    return (afterLevel, p.clamp(0, 100));
  }

  void _spawnTicket() {
    _pausePhase6HapticsForTicket();
    unawaited(_playLevelUpTicketHaptic(_phase6HapticGeneration));

    final startRect = _rectOf(_lvLabelKey) ?? _fallbackTicketStartRect();
    final targetRect = EffectAnchorRegistry.instance.getRect(
      EffectAnchorId.ticketBadge,
    );

    final start = startRect.center;
    final end = (targetRect?.center) ?? _fallbackTicketTargetOffset();

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    final curve = CurvedAnimation(parent: ctrl, curve: Curves.easeInOutCubic);
    final offsetTween = Tween<Offset>(begin: start, end: end).animate(curve);
    final scaleTween = Tween<double>(begin: 1.0, end: 0.2).animate(curve);
    final opacityTween = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: ctrl, curve: const Interval(0.7, 1.0)));

    final ticket = _FlyingTicket(
      controller: ctrl,
      offset: offsetTween,
      scale: scaleTween,
      opacity: opacityTween,
    );

    setState(() => _tickets.add(ticket));

    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() {
          _tickets.remove(ticket);
        });
        ctrl.dispose();
      }
    });
    ctrl.forward();
  }

  void _startPhase6Haptics() {
    _stopPhase6Haptics();
    _phase6HapticGeneration++;
    _schedulePhase6HapticTick(
      generation: _phase6HapticGeneration,
      delay: Duration.zero,
    );
  }

  void _stopPhase6Haptics() {
    _phase6HapticGeneration++;
    _phase6HapticTimer?.cancel();
    _phase6HapticTimer = null;
    unawaited(Vibration.cancel());
  }

  void _pausePhase6HapticsForTicket() {
    final generation = _phase6HapticGeneration;
    _phase6HapticTimer?.cancel();
    _phase6HapticTimer = null;
    unawaited(Vibration.cancel());
    _scheduleTicketHaptic(generation: generation);
  }

  void _scheduleTicketHaptic({required int generation}) {
    _phase6HapticTimer?.cancel();
    _phase6HapticTimer = Timer(const Duration(milliseconds: 90), () {
      if (!mounted || generation != _phase6HapticGeneration) return;
      unawaited(_playLevelUpTicketHaptic(generation));
    });
  }

  void _schedulePhase6Resume({
    required int generation,
    required Duration delay,
  }) {
    _phase6HapticTimer?.cancel();
    _phase6HapticTimer = Timer(delay, () {
      if (!mounted || generation != _phase6HapticGeneration) return;
      unawaited(_playPhase6ProgressHaptic(generation));
    });
  }

  void _schedulePhase6HapticTick({
    required int generation,
    required Duration delay,
  }) {
    _phase6HapticTimer?.cancel();
    _phase6HapticTimer = Timer(delay, () {
      if (!mounted || generation != _phase6HapticGeneration) return;
      unawaited(_playPhase6ProgressHaptic(generation));
    });
  }

  Future<void> _playPhase6ProgressHaptic(int generation) async {
    if (!mounted || generation != _phase6HapticGeneration) return;
    try {
      await Vibration.vibrate(preset: VibrationPreset.rapidTapFeedback);
    } catch (_) {}
    if (!mounted || generation != _phase6HapticGeneration) return;
    _schedulePhase6HapticTick(
      generation: generation,
      delay: const Duration(milliseconds: 420),
    );
  }

  Future<void> _playLevelUpTicketHaptic(int generation) async {
    if (!mounted || generation != _phase6HapticGeneration) return;
    try {
      await Vibration.vibrate(preset: VibrationPreset.doubleBuzz);
    } catch (_) {}
    if (!mounted || generation != _phase6HapticGeneration) return;
    _schedulePhase6Resume(
      generation: generation,
      delay: const Duration(milliseconds: 140),
    );
  }

  void _startSparkles() {
    _disposeSparkles();
    _sparklesActive = true;
    final sparkleTargetCount = 3 + _random.nextInt(3);
    for (var i = 0; i < sparkleTargetCount; i++) {
      _scheduleSparkleSpawn(Duration(milliseconds: _random.nextInt(180)));
    }
  }

  void _stopSparkles() {
    _sparklesActive = false;
    for (final timer in _sparkleTimers) {
      timer.cancel();
    }
    _sparkleTimers.clear();
  }

  void _disposeSparkles() {
    _stopSparkles();
    for (final sparkle in _sparkles) {
      sparkle.controller.dispose();
    }
    _sparkles.clear();
  }

  void _scheduleSparkleSpawn(Duration delay) {
    if (!_sparklesActive) return;
    late final Timer timer;
    timer = Timer(delay, () {
      _sparkleTimers.remove(timer);
      if (!mounted || !_sparklesActive) return;
      _spawnSparkle();
    });
    _sparkleTimers.add(timer);
  }

  void _spawnSparkle() {
    if (!_sparklesActive) return;

    const anchors = <Offset>[
      Offset(-0.58, -0.52),
      Offset(0.00, -0.72),
      Offset(0.56, -0.44),
      Offset(0.50, 0.26),
    ];
    final width = 20.0 + _random.nextDouble() * 10.0;
    final rotation = (_random.nextDouble() - 0.5) * (math.pi / 5);
    final alignment = _pickSparkleAlignment(anchors: anchors, width: width);
    if (alignment == null) {
      if (_sparklesActive) {
        _scheduleSparkleSpawn(
          Duration(milliseconds: 80 + _random.nextInt(160)),
        );
      }
      return;
    }

    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 420 + _random.nextInt(260)),
    );
    final opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
    ]).animate(ctrl);
    final scale = Tween<double>(
      begin: 0.7,
      end: 1.35,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

    final sparkle = _Sparkle(
      controller: ctrl,
      opacity: opacity,
      scale: scale,
      alignment: alignment,
      width: width,
      rotation: rotation,
    );

    setState(() => _sparkles.add(sparkle));

    ctrl.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (mounted) {
        setState(() {
          _sparkles.remove(sparkle);
        });
      } else {
        _sparkles.remove(sparkle);
      }
      ctrl.dispose();
      if (_sparklesActive) {
        _scheduleSparkleSpawn(
          Duration(milliseconds: 40 + _random.nextInt(220)),
        );
      }
    });
    ctrl.forward();
  }

  Offset? _pickSparkleAlignment({
    required List<Offset> anchors,
    required double width,
  }) {
    final layerSize = MediaQuery.sizeOf(context).width * 0.62;
    final halfLayer = layerSize / 2;

    for (var i = 0; i < 12; i++) {
      final anchor = anchors[_random.nextInt(anchors.length)];
      final jitterX = (_random.nextDouble() - 0.5) * 0.14;
      final jitterY = (_random.nextDouble() - 0.5) * 0.14;
      final alignment = Offset(anchor.dx + jitterX, anchor.dy + jitterY);
      final candidateCenter = Offset(
        alignment.dx * halfLayer,
        alignment.dy * halfLayer,
      );

      final overlapsExisting = _sparkles.any((sparkle) {
        final existingCenter = Offset(
          sparkle.alignment.dx * halfLayer,
          sparkle.alignment.dy * halfLayer,
        );
        final minDistance = ((width + sparkle.width) / 2) + 10;
        return (candidateCenter - existingCenter).distance < minDistance;
      });

      if (!overlapsExisting) {
        return alignment;
      }
    }

    return null;
  }

  Rect? _rectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Rect _fallbackTicketStartRect() {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.6),
      width: 38,
      height: 20,
    );
  }

  Offset _fallbackTicketTargetOffset() {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final pad = mq.padding;
    return Offset(size.width - 24, pad.top + 24);
  }

  /// [ShaderMask]는 [maskRect] 밖을 그리지 않아 글리프 상단이 잘릴 수 있음.
  /// [TextStyle.foreground]로 세로 그라데이션을 적용하면 동일 레이어 클리핑을 피함.
  Widget _buildLikePointGradientText(
    BuildContext context,
    TextTheme theme,
    String likeDisplay,
  ) {
    final baseStyle = theme.headlineLarge;
    if (baseStyle == null) {
      return Text(likeDisplay);
    }
    final fontSize = baseStyle.fontSize ?? 32;
    final heightFactor = baseStyle.height ?? 1.2;
    final scaler = MediaQuery.textScalerOf(context);
    final linePx = fontSize * heightFactor * scaler.scale(1);
    final shaderRect = Rect.fromLTWH(0, 0, 1, linePx + 4);
    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_mint, _mintLight],
    ).createShader(shaderRect);

    return Text(
      likeDisplay,
      style: baseStyle.copyWith(foreground: Paint()..shader = shader),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _phase1Ctrl,
        _phase5Ctrl,
        _phase6Ctrl,
        _phase6WobbleCtrl,
        _phase7Ctrl,
        _phase8Ctrl,
      ]),
      builder: (context, _) {
        final dimOpacity = _phase8FadingOut
            ? (1.0 - _phase8Ctrl.value)
            : _phase1Ctrl.value;
        final visualLayerOpacity = _phase8FadingOut
            ? (1.0 - _phase8Ctrl.value)
            : 1.0;

        // phase1: scale 2→0.7 + Y 0→-50 + fade-in (500ms)
        final t = _phase1Ctrl.value;
        final centerScale = 2.0 - 1.3 * t;
        final centerTranslateY = -50.0 * t;
        // phase6 wobble: 독자적인 500ms 컨트롤러 기준 sin 4사이클
        final wobbleT = _wobbling ? _phase6WobbleCtrl.value : 0.0;
        final thumbWobbleAngle =
            math.sin(wobbleT * math.pi * 4) * (10 * math.pi / 180);
        final sparkleLayerOpacity = _phase8FadingOut
            ? (1.0 - _phase8Ctrl.value)
            : 1.0;

        final contentOpacity = _phase8FadingOut
            ? (1.0 - _phase8Ctrl.value)
            : (_phase5Visible ? _phase5Ctrl.value : 0.0);

        final likeDisplay = '$_displayLikePoint'.padLeft(2, '0');
        final likePointText = _buildLikePointGradientText(
          context,
          theme,
          likeDisplay,
        );
        final thumbLayerSize = screenWidth * 0.62;
        final thumbWidth = screenWidth * 0.5;

        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: dimOpacity,
                  child: const ColoredBox(color: _dimColor),
                ),
              ),

              // 2) background image (fit to width, keep aspect)
              if (_bgVisible)
                Center(
                  child: Transform.translate(
                    offset: Offset(0, centerTranslateY),
                    child: Transform.scale(
                      scale: centerScale,
                      child: Image.asset(
                        _bgAsset,
                        width: screenWidth * 1.5,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),

              // 3) thumb image
              Center(
                child: Opacity(
                  opacity: visualLayerOpacity,
                  child: Transform.translate(
                    offset: Offset(0, centerTranslateY),
                    child: Transform.scale(
                      scale: centerScale,
                      child: SizedBox(
                        width: thumbLayerSize,
                        height: thumbLayerSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final sparkle in _sparkles)
                              AnimatedBuilder(
                                animation: sparkle.controller,
                                builder: (context, child) {
                                  final halfLayer = thumbLayerSize / 2;
                                  final x =
                                      halfLayer +
                                      sparkle.alignment.dx * halfLayer;
                                  final y =
                                      halfLayer +
                                      sparkle.alignment.dy * halfLayer;
                                  return Positioned(
                                    left: x - sparkle.width / 2,
                                    top: y - sparkle.width / 2,
                                    child: Opacity(
                                      opacity:
                                          sparkle.opacity.value *
                                          sparkleLayerOpacity,
                                      child: Transform.rotate(
                                        angle: sparkle.rotation,
                                        child: Transform.scale(
                                          scale: sparkle.scale.value,
                                          child: child,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Image.asset(
                                  _sparkleAsset,
                                  width: sparkle.width,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            Center(
                              child: Transform.rotate(
                                angle: thumbWobbleAngle,
                                child: Image.asset(
                                  _thumbAsset,
                                  width: thumbWidth,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 5) LikePoint, Lv, progress
              IgnorePointer(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          likePointText,
                          const SizedBox(height: 8),
                          SizedBox(
                            width: screenWidth * 0.7,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Lv. $_displayLevel',
                                  key: _lvLabelKey,
                                  style: theme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _LikeProgressBar(
                                    progressPercentage: _displayProgress,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // tickets
              for (final t in _tickets)
                AnimatedBuilder(
                  animation: t.controller,
                  builder: (context, child) {
                    final pos = t.offset.value;
                    return Positioned(
                      left: pos.dx - 19,
                      top: pos.dy - 10,
                      child: Opacity(
                        opacity: t.opacity.value,
                        child: Transform.scale(
                          scale: t.scale.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Image.asset(
                    _ticketAsset,
                    width: 38,
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LikeProgressBar extends StatelessWidget {
  final double progressPercentage;

  const _LikeProgressBar({required this.progressPercentage});

  @override
  Widget build(BuildContext context) {
    final p = (progressPercentage.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF635F5F)),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * p,
                  child: const ColoredBox(color: Color(0xFF80D7CF)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FlyingTicket {
  final AnimationController controller;
  final Animation<Offset> offset;
  final Animation<double> scale;
  final Animation<double> opacity;

  _FlyingTicket({
    required this.controller,
    required this.offset,
    required this.scale,
    required this.opacity,
  });
}

class _Sparkle {
  final AnimationController controller;
  final Animation<double> opacity;
  final Animation<double> scale;
  final Offset alignment;
  final double width;
  final double rotation;

  _Sparkle({
    required this.controller,
    required this.opacity,
    required this.scale,
    required this.alignment,
    required this.width,
    required this.rotation,
  });
}
