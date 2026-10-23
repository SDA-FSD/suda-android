import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../l10n/app_localizations.dart';

/// 튜토리얼 롤플레이 결과. 본편 Result 진입과 같은 배경·별 채움·햅틱. 성과 지표는 없다.
class TutorialResultScreen extends StatefulWidget {
  static const topBg = Color(0xFF054544);
  static const bottomBg = Color(0xFF0CABA8);
  static const mint = Color(0xFF80D7CF);
  static const main = Color(0xFF0CABA8);
  static const starGold = 'assets/images/star_gold.png';
  static const starSilver = 'assets/images/star_silver.png';

  /// 시안: X 0, Y 4, 흐림 4, 스프레드 0, `#000000` 25%.
  static const buttonShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
    spreadRadius: 0,
  );

  final VoidCallback onContinue;

  const TutorialResultScreen({super.key, required this.onContinue});

  @override
  State<TutorialResultScreen> createState() => _TutorialResultScreenState();
}

class _TutorialResultScreenState extends State<TutorialResultScreen> {
  int _revealedStars = 0;
  bool _buttonShown = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _playEntrance();
  }

  @override
  void dispose() {
    _seq++;
    super.dispose();
  }

  /// 본편 Result와 같이 300ms 간격으로 왼쪽·가운데·오른쪽 별을 채우고 80ms 햅틱.
  Future<void> _playEntrance() async {
    final seq = _seq;
    for (var i = 1; i <= 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted || seq != _seq) return;
      setState(() => _revealedStars = i);
      Vibration.vibrate(duration: 80);
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted || seq != _seq) return;
    setState(() => _buttonShown = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: TutorialResultScreen.bottomBg,
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TutorialResultScreen.topBg,
                  TutorialResultScreen.bottomBg,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonTop = constraints.maxHeight * 2 / 3;
                  final rise = constraints.maxHeight - buttonTop;
                  return Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ThreeStars(revealed: _revealedStars),
                            const SizedBox(height: 5),
                            Text(
                              'You did it!',
                              style: theme.headlineLarge?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              l10n.tutorialRoleplayResultSubtitle,
                              style: const TextStyle(
                                fontFamily: 'ChironGoRoundTC',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontVariations: [FontVariation('wght', 600)],
                                color: TutorialResultScreen.mint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: buttonTop,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: rise,
                            end: _buttonShown ? 0 : rise,
                          ),
                          duration: const Duration(milliseconds: 560),
                          curve: Curves.easeOutCubic,
                          builder: (context, dy, child) {
                            return Transform.translate(
                              offset: Offset(0, dy),
                              child: child,
                            );
                          },
                          child: _PulsingContinueButton(
                            label: l10n.tutorialRoleplayResultContinue,
                            pulse: _buttonShown,
                            onTap: widget.onContinue,
                          ),
                        ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeStars extends StatelessWidget {
  final int revealed;

  const _ThreeStars({required this.revealed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PopStar(size: 70, degrees: -10, dy: 10, gold: revealed >= 1),
        const SizedBox(width: 10),
        _PopStar(size: 80, degrees: 0, dy: 0, gold: revealed >= 2),
        const SizedBox(width: 10),
        _PopStar(size: 70, degrees: 10, dy: 10, gold: revealed >= 3),
      ],
    );
  }
}

class _PopStar extends StatefulWidget {
  final double size;
  final double degrees;
  final double dy;
  final bool gold;

  const _PopStar({
    required this.size,
    required this.degrees,
    required this.dy,
    required this.gold,
  });

  @override
  State<_PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<_PopStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didUpdateWidget(covariant _PopStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gold && !oldWidget.gold) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final bump = math.sin(_pop.value * math.pi);
        return Transform.translate(
          offset: Offset(0, widget.dy),
          child: Transform.rotate(
            angle: widget.degrees * math.pi / 180,
            child: Transform.scale(scale: 1 + 0.18 * bump, child: child),
          ),
        );
      },
      child: Image.asset(
        widget.gold
            ? TutorialResultScreen.starGold
            : TutorialResultScreen.starSilver,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PulsingContinueButton extends StatefulWidget {
  final String label;
  final bool pulse;
  final VoidCallback onTap;

  const _PulsingContinueButton({
    required this.label,
    required this.pulse,
    required this.onTap,
  });

  @override
  State<_PulsingContinueButton> createState() => _PulsingContinueButtonState();
}

class _PulsingContinueButtonState extends State<_PulsingContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _PulsingContinueButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.pulse && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// 힌트 전구와 같이 0에서 30%까지 밝아졌다가 다시 투명.
  double _glow(double t, double phase) {
    final wave = math.sin(((t + phase) % 1) * math.pi);
    return 0.30 * wave;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final button = DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        boxShadow: [TutorialResultScreen.buttonShadow],
      ),
      child: Material(
        color: TutorialResultScreen.main,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _halo(16, 12, _glow(t, 0)),
            _halo(8, 6, _glow(t, 0.28)),
            child!,
          ],
        );
      },
      child: button,
    );
  }

  /// 버튼보다 가로 [extraX], 세로 [extraY]만큼 더 큰 메인 색 겹.
  Widget _halo(double extraX, double extraY, double opacity) {
    final strength = (opacity / 0.30).clamp(0.0, 1.0);
    return Positioned(
      left: -extraX,
      right: -extraX,
      top: -extraY,
      bottom: -extraY,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TutorialResultScreen.main.withValues(alpha: opacity.clamp(0, 1)),
            borderRadius: BorderRadius.all(Radius.circular(28 + extraY)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.25 * strength),
                offset: const Offset(0, 4),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
