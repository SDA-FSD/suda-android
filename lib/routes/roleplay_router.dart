import 'package:flutter/material.dart';
import '../utils/full_screen_route.dart';
import '../utils/sub_screen_route.dart';
import '../screens/series/overview.dart';
import '../screens/roleplay/opening.dart';
import '../screens/roleplay/playing.dart';
import '../screens/roleplay/ending.dart';
import '../screens/roleplay/try_again.dart';
import '../screens/roleplay/result.dart';
import '../screens/roleplay/try_again_report.dart';
import '../screens/roleplay/result_report.dart';
import '../screens/roleplay/tutorial.dart';
import '../services/roleplay_state_service.dart';
import '../services/series_state_service.dart';
import '../services/version_check_service.dart';

class RoleplayRouter {
  static const String openingRouteName = '/roleplay/opening';

  /// Try Again Report 스크린을 push (Try Again 화면에서만 진입). pop 시 결과값(전송 성공 시 true)을 반환.
  static Future<T?> pushTryAgainReport<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      SubScreenRoute(
        page: const RoleplayTryAgainReportScreen(),
        settings: const RouteSettings(
          name: RoleplayTryAgainReportScreen.routeName,
        ),
      ),
    );
  }

  /// Result Report 스크린을 push (Result 화면에서만 진입). pop 시 결과값(전송 성공 시 true)을 반환.
  static Future<T?> pushResultReport<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      SubScreenRoute(
        page: const RoleplayResultReportScreen(),
        settings: const RouteSettings(
          name: RoleplayResultReportScreen.routeName,
        ),
      ),
    );
  }

  /// Tutorial 스크린을 push (Overview에서 Opening 전환 전 조건 분기용).
  static void pushTutorial(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayTutorialScreen(),
        settings: const RouteSettings(name: RoleplayTutorialScreen.routeName),
      ),
    );
  }

  /// Lab 미리보기. [locale] 오버레이로 열고, 완료 API는 호출하지 않는다.
  static Future<void> pushTutorialPreview(
    BuildContext context, {
    required Locale locale,
  }) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => Localizations.override(
          context: context,
          locale: locale,
          child: const RoleplayTutorialScreen(preview: true),
        ),
        settings: const RouteSettings(name: RoleplayTutorialScreen.routeName),
      ),
    );
  }

  /// Tutorial 완료 후 Opening으로 교체 (Tutorial 스크린을 스택에서 제거).
  static void replaceWithOpeningFromTutorial(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayOpeningScreen(),
        settings: const RouteSettings(name: openingRouteName),
      ),
    );
  }

  static void pushOpening(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayOpeningScreen(),
        settings: const RouteSettings(name: openingRouteName),
      ),
    );
  }

  static void replaceWithPlaying(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleplayPlayingScreen()),
    );
  }

  static void replaceWithEnding(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleplayEndingScreen()),
    );
  }

  static void replaceWithTryAgain(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: RoleplayTryAgainScreen.routeName),
        builder: (context) => const RoleplayTryAgainScreen(),
      ),
    );
  }

  /// 다음 에피소드. 결과 캐시를 버리고 Overview Play와 같은 진입(튜토리얼 또는 Opening).
  /// [resultRoute]가 현재 라우트면 교체하고, 페이월 아래면 그 자리에서 바꾼다.
  static void replaceResultWithNextEpisode(
    NavigatorState nav, {
    required Route<dynamic> resultRoute,
    required int episodeId,
  }) {
    if (!resultRoute.isActive) return;
    final series = SeriesStateService.instance;
    series
      ..markProfileHistoryRefreshPending()
      ..markBestScoreRefreshPending();
    series.setSelectedEpisodeId(episodeId);
    final user = series.user;
    if (user != null) {
      RoleplayStateService.instance.setUser(user);
    }
    final route = _nextEpisodeEntryRoute();
    if (resultRoute.isCurrent) {
      nav.pushReplacement(route);
      return;
    }
    nav.replace<void>(oldRoute: resultRoute, newRoute: route);
  }

  static Route<void> _nextEpisodeEntryRoute() {
    if (VersionCheckService.skipRoleplayTutorial) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: openingRouteName),
        builder: (_) => const RoleplayOpeningScreen(),
      );
    }
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: RoleplayTutorialScreen.routeName),
      builder: (_) => const RoleplayTutorialScreen(),
    );
  }

  /// Tutorial이 맨 위가 아닐 때(페이월 아래) 자기 라우트만 Opening으로 바꾼다.
  static void replaceRouteWithOpening(
    NavigatorState nav,
    Route<dynamic> oldRoute,
  ) {
    if (!oldRoute.isActive || oldRoute.isCurrent) return;
    nav.replace<void>(
      oldRoute: oldRoute,
      newRoute: MaterialPageRoute<void>(
        settings: const RouteSettings(name: openingRouteName),
        builder: (_) => const RoleplayOpeningScreen(),
      ),
    );
  }

  /// Try Again Retry — 동일 에피소드 Opening으로 재시작 (Overview 복귀 아님).
  static void replaceWithOpeningForRetry(BuildContext context) {
    SeriesStateService.instance.clearPlaySession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayOpeningScreen(),
        settings: const RouteSettings(name: openingRouteName),
      ),
    );
  }

  /// Ending/Playing → Result 전환. FullScreenRoute + bottom-up.
  static void replaceWithResult(BuildContext context) {
    const teal = Color(0xFF0CABA8);
    Navigator.pushReplacement(
      context,
      FullScreenRoute(
        transition: FullScreenTransition.bottomUp,
        settings: const RouteSettings(name: RoleplayResultScreen.routeName),
        page: Container(color: teal, child: const RoleplayResultScreen()),
      ),
    );
  }

  static void popToOverview(
    BuildContext context, {
    bool refreshBestScore = true,
  }) {
    final series = SeriesStateService.instance;
    series.markProfileHistoryRefreshPending();
    if (refreshBestScore) {
      series.markBestScoreRefreshPending();
    }
    Navigator.of(context).popUntil((route) {
      return route.isFirst ||
          route.settings.name == SeriesOverviewScreen.routeName;
    });
  }
}
