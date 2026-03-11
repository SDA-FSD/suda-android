import 'package:flutter/material.dart';

/// 앱 실행 시 네이티브 스플래시 제거 후, LoginScreen 전에만 노출되는 커스텀 스플래시.
/// 로그아웃 시에는 표시하지 않고 곧바로 LoginScreen으로 이동한다.
/// logo_splash.png가 좌측 상단에서 큰 포물선을 그리며 정중앙으로 한 번에 이동하는 애니메이션 후 Login으로 전환.
class CustomSplashScreen extends StatefulWidget {
  /// 스플래시 종료 시 호출. main.dart에서 LoginScreen으로 전환하기 위해 사용.
  final VoidCallback onComplete;

  const CustomSplashScreen({super.key, required this.onComplete});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF121212);
  static const _animationDuration = Duration(milliseconds: 1000);
  /// 좌측 화면 밖 시작 위치 (정중앙 0에 도달)
  static const _initialOffsetX = -420.0;
  /// 좌측 상단 시작 Y (포물선 궤적으로 정중앙 0에 도달)
  static const _initialOffsetY = -220.0;
  /// 포물선 궤적 크기 (중간에 위로 휘는 정도, 음수일수록 높이 올라감)
  static const _arcPeak = -350.0;

  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _progress.value;
            final offsetX = _initialOffsetX * (1.0 - t);
            final offsetY = _initialOffsetY * (1.0 - t) + _arcPeak * t * (1.0 - t);
            return Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Transform.scale(
                scale: 0.8,
                child: Image.asset(
                  'assets/images/logo_splash.png',
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
