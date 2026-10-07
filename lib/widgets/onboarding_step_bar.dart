import 'package:flutter/material.dart';

/// 온보딩 3단계 진행 막대. 이전 칸은 채워진 채, 이번 칸만 왼쪽부터 한 번 칠한다.
class OnboardingStepBar extends StatefulWidget {
  /// 1=언어, 2=CEFR, 3=프로필 이미지.
  final int step;

  const OnboardingStepBar({super.key, required this.step});

  @override
  State<OnboardingStepBar> createState() => _OnboardingStepBarState();
}

class _OnboardingStepBarState extends State<OnboardingStepBar>
    with SingleTickerProviderStateMixin {
  static const _inactive = Color(0xFF353535);
  static const _gradientStart = Color(0xFF076766);
  static const _gradientEnd = Color(0xFF0CABA8);
  static const _barHeight = 8.0;
  static const _gap = 5.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final barWidth = (width - _gap * 2) / 3;
            final doneEnd = (widget.step - 1) * (barWidth + _gap);
            final activeEnd = doneEnd + barWidth;
            final reveal = (doneEnd + (activeEnd - doneEnd) * _controller.value)
                .clamp(0.0, width);
            return SizedBox(
              height: _barHeight,
              child: Stack(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        Expanded(child: _capsule(_inactive)),
                      ],
                    ],
                  ),
                  ClipRect(
                    clipper: _LeftRevealClipper(reveal),
                    child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [_gradientStart, _gradientEnd],
                        ).createShader(rect),
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0) const SizedBox(width: _gap),
                              Expanded(
                                child: _capsule(
                                  i < widget.step
                                      ? Colors.white
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _capsule(Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_barHeight / 2),
      ),
      child: const SizedBox(height: _barHeight),
    );
  }
}

class _LeftRevealClipper extends CustomClipper<Rect> {
  final double reveal;

  _LeftRevealClipper(this.reveal);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, reveal, size.height);

  @override
  bool shouldReclip(_LeftRevealClipper oldClipper) =>
      oldClipper.reveal != reveal;
}

/// 온보딩 흰 타이틀. 상단 밴드 안에서 글 하단이 밴드 높이의 72%.
Widget onboardingTitle(String text, TextTheme theme) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: constraints.maxHeight * 0.28,
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Text(
                text,
                style: theme.headlineLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 헤더 자리(SafeArea 안, 상단 16·좌우 24)에 진행 막대를 올린다.
Widget withOnboardingStepBar({required int step, required Widget body}) {
  return Stack(
    children: [
      body,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: OnboardingStepBar(step: step),
          ),
        ),
      ),
    ],
  );
}
