import 'package:flutter/material.dart';

/// 메인 라우트(첫 번째 라우트)가 다시 포그라운드될 때 콜백을 호출하는 래퍼.
/// 서브 스크린에서 pop으로 복귀 시 [onReturnToRoute]가 호출된다.
class MainRouteAwareWrapper extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  final VoidCallback onReturnToRoute;
  final Widget child;

  const MainRouteAwareWrapper({
    super.key,
    required this.routeObserver,
    required this.onReturnToRoute,
    required this.child,
  });

  @override
  State<MainRouteAwareWrapper> createState() => _MainRouteAwareWrapperState();
}

class _MainRouteAwareWrapperState extends State<MainRouteAwareWrapper>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route is ModalRoute<void>) {
      widget.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    widget.onReturnToRoute();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
