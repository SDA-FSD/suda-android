import 'package:flutter/material.dart';

/// Sub Screen용 iOS 스타일 슬라이드 애니메이션 Route
/// 
/// 우측에서 좌측으로 슬라이드되어 표시되며, 배경 반짝임을 방지합니다.
class SubScreenRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SubScreenRoute({required this.page, RouteSettings? settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          settings: settings ?? const RouteSettings(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 우측에서 좌측으로 슬라이드
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          opaque: true, // 배경 반짝임 방지
          barrierColor: Colors.transparent, // 배경 반짝임 방지
        );
}
