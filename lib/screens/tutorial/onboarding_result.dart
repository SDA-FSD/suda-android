import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 온보딩 롤플레이 엔딩. 이미지 페이드 후 그라데이션, 문구, 버튼이 차례로 나온다.
class TutorialResultScreen extends StatefulWidget {
  static const endingAsset =
      'assets/images/onboarding/onboarding_tutorial_ending.png';
  static const main = Color(0xFF0CABA8);

  final VoidCallback onContinue;

  const TutorialResultScreen({super.key, required this.onContinue});

  @override
  State<TutorialResultScreen> createState() => _TutorialResultScreenState();
}

class _TutorialResultScreenState extends State<TutorialResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _imageFade;
  late final AnimationController _gradient;
  late final AnimationController _title;
  late final AnimationController _subtitle;
  late final AnimationController _button;

  @override
  void initState() {
    super.initState();
    _imageFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _gradient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _title = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _subtitle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _button = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  Future<void> _play() async {
    await precacheImage(
      const AssetImage(TutorialResultScreen.endingAsset),
      context,
    );
    if (!mounted) return;
    await _imageFade.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await _gradient.forward();
    if (!mounted) return;
    await _title.forward();
    if (!mounted) return;
    await _subtitle.forward();
    if (!mounted) return;
    await _button.forward();
  }

  @override
  void dispose() {
    _imageFade.dispose();
    _gradient.dispose();
    _title.dispose();
    _subtitle.dispose();
    _button.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final side = width * 0.08;
            return Stack(
              fit: StackFit.expand,
              children: [
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _imageFade,
                    curve: Curves.easeInOut,
                  ),
                  child: Image.asset(
                    TutorialResultScreen.endingAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _gradient,
                    curve: Curves.easeOut,
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFF121212),
                          Color(0x00121212),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScaleIn(
                          animation: _title,
                          child: Text(
                            l10n.tutorialRoleplayResultTitle,
                            textAlign: TextAlign.center,
                            style: theme.headlineLarge?.copyWith(
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.018),
                        _ScaleIn(
                          animation: _subtitle,
                          child: Text(
                            l10n.tutorialRoleplayResultSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.headlineMedium?.copyWith(
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: side,
                  right: side,
                  bottom: height * 0.14,
                  child: _RiseIn(
                    animation: _button,
                    child: Center(
                      child: Material(
                        color: TutorialResultScreen.main,
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: widget.onContinue,
                          borderRadius: BorderRadius.circular(28),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            child: Text(
                              l10n.tutorialRoleplayResultContinue,
                              textAlign: TextAlign.center,
                              style: theme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScaleIn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ScaleIn({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(animation.value);
        return Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform.scale(scale: 0.72 + 0.28 * t, child: child),
        );
      },
      child: child,
    );
  }
}

class _RiseIn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _RiseIn({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
