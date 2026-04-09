import 'package:flutter/material.dart';

enum FullScreenTransition {
  defaultTransition,
  bottomUp,
}

/// Full Screen용 공통 Route.
///
/// 기본값은 기존 Full Screen처럼 별도 전환 효과 없이 즉시 노출되고,
/// 필요 시에만 bottom-up 슬라이드 인을 선택적으로 적용한다.
class FullScreenRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FullScreenRoute({
    required this.page,
    this.transition = FullScreenTransition.defaultTransition,
    RouteSettings? settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         settings: settings ?? const RouteSettings(),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           switch (transition) {
             case FullScreenTransition.bottomUp:
               final tween = Tween(
                 begin: const Offset(0, 1),
                 end: Offset.zero,
               ).chain(CurveTween(curve: Curves.easeOutCubic));
               return SlideTransition(
                 position: animation.drive(tween),
                 child: child,
               );
             case FullScreenTransition.defaultTransition:
               return child;
           }
         },
         transitionDuration: transition == FullScreenTransition.bottomUp
             ? const Duration(milliseconds: 320)
             : Duration.zero,
         reverseTransitionDuration: transition == FullScreenTransition.bottomUp
             ? const Duration(milliseconds: 280)
             : Duration.zero,
         opaque: true,
         barrierColor: Colors.transparent,
       );

  final FullScreenTransition transition;
}
