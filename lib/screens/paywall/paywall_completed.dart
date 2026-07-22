import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/full_screen_route.dart';

class PaywallCompletedScreen extends StatelessWidget {
  const PaywallCompletedScreen({super.key});

  static const String routeName = '/paywall/completed';

  /// 배경 glow (부모 size 대비 반응형 + blur 고정).
  static const _glowWidthRatio = 1.086;
  static const _glowHeightRatio = 0.707;
  static const _glowLeftRatio = -0.355;
  static const _glowTopRatio = -0.004;
  static const _glowColor = Color(0xFFAB6AFF);
  static const _glowOpacity = 0.57;
  static const _glowBlurSigma = 88.7;

  static Future<T?> push<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      FullScreenRoute<T>(
        page: const PaywallCompletedScreen(),
        transition: FullScreenTransition.bottomUp,
        settings: const RouteSettings(name: routeName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF8A38F5),
      body: ClipRect(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8A38F5), Color(0xFF80D7CF)],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 그라디언트 위 · 콘텐츠 아래 glow 레이어
              Positioned(
                left: size.width * _glowLeftRatio - _glowBlurSigma * 2,
                top: size.height * _glowTopRatio - _glowBlurSigma * 2,
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _glowBlurSigma,
                      sigmaY: _glowBlurSigma,
                      tileMode: TileMode.decal,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(_glowBlurSigma * 2),
                      child: Opacity(
                        opacity: _glowOpacity,
                        child: Container(
                          width: size.width * _glowWidthRatio,
                          height: size.height * _glowHeightRatio,
                          decoration: const BoxDecoration(
                            color: _glowColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: topPad + 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ),
              Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/icons/premium_verified_badge.png',
                      width: 130,
                      height: 130,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Parabéns!',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Seus benefícios Premium já estão ativos.',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // 블록 자체는 가운데, 내부 체크 아이콘은 동일 세로선 정렬
                    const Center(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BenefitLine('Mais prática todos os dias'),
                            SizedBox(height: 14),
                            _BenefitLine('Energia máxima de 30'),
                            SizedBox(height: 14),
                            _BenefitLine('Feedback da IA sobre frases'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000), // #000000 25%
                              offset: Offset(0, 4),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0CABA8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'Continuar',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/icons/white_check_icon.png',
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
