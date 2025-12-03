import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final logoSize = math.min(screenSize.width, screenSize.height) * 0.65;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 로고 이미지 (정중앙)
            Center(
              child: SizedBox(
                width: logoSize,
                height: logoSize,
                child: Image.asset(
                  'assets/images/logo_3d.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // "Loading" 텍스트 (이미지 하단과 디바이스 하단 사이 중간 영역)
            Positioned(
              bottom: screenSize.height * 0.15, // 하단에서 15% 위치 (중간 영역)
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Loading',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
