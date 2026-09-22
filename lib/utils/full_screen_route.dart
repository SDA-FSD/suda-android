import 'package:flutter/material.dart';

enum FullScreenTransition {
  defaultTransition,
  bottomUp,
  fade,
}

/// Full Screen용 공통 Route.
///
/// 기본값은 기존 Full Screen처럼 별도 전환 효과 없이 즉시 노출되고,
/// 필요 시에만 bottom-up / fade를 선택적으로 적용한다. 새 스크린 타입 아님.
class FullScreenRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  static Duration _forwardDuration(FullScreenTransition transition) {
    switch (transition) {
      case FullScreenTransition.bottomUp:
        return const Duration(milliseconds: 450);
      case FullScreenTransition.fade:
        return const Duration(milliseconds: 200);
      case FullScreenTransition.defaultTransition:
        return Duration.zero;
    }
  }

  static Duration _reverseDuration(FullScreenTransition transition) {
    switch (transition) {
      case FullScreenTransition.bottomUp:
        return const Duration(milliseconds: 280);
      case FullScreenTransition.fade:
        return const Duration(milliseconds: 150);
      case FullScreenTransition.defaultTransition:
        return Duration.zero;
    }
  }

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
             case FullScreenTransition.fade:
               return FadeTransition(
                 opacity: CurvedAnimation(
                   parent: animation,
                   curve: Curves.easeOut,
                   reverseCurve: Curves.easeIn,
                 ),
                 child: child,
               );
             case FullScreenTransition.defaultTransition:
               return child;
           }
         },
         transitionDuration: _forwardDuration(transition),
         reverseTransitionDuration: _reverseDuration(transition),
         opaque: true,
         barrierColor: Colors.transparent,
       );

  final FullScreenTransition transition;
}
