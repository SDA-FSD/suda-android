import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../services/rest_status_service.dart';
import '../utils/full_screen_route.dart';
import '../utils/sub_screen_route.dart';
import '../widgets/rest_overlay.dart';
import '../screens/roleplay/overview.dart';
import '../screens/series/overview.dart';
import '../screens/roleplay/opening.dart';
import '../screens/roleplay/playing.dart';
import '../screens/roleplay/ending.dart';
import '../screens/roleplay/try_again.dart';
import '../screens/roleplay/result.dart';
import '../screens/roleplay/try_again_report.dart';
import '../screens/roleplay/result_report.dart';
import '../screens/roleplay/survey.dart';
import '../screens/roleplay/tutorial.dart';
import '../services/series_state_service.dart';

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

  /// Survey 스크린을 push (Opening -10 분기에서 진입).
  static Future<T?> pushSurvey<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      SubScreenRoute(
        page: const RoleplaySurveyScreen(),
        settings: const RouteSettings(name: RoleplaySurveyScreen.routeName),
      ),
    );
  }

  static void pushOverview(BuildContext context, int roleplayId, {UserDto? user}) {
    if (RestStatusService.instance.shouldShowRestOverlay()) {
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (_, __, ___) => const RestOverlay(),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      SubScreenRoute(
        page: RoleplayOverviewScreen(roleplayId: roleplayId, user: user),
        settings: RouteSettings(
          name: RoleplayOverviewScreen.routeName,
          arguments: roleplayId,
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
      MaterialPageRoute(
        builder: (context) => const RoleplayPlayingScreen(),
      ),
    );
  }

  static void replaceWithEnding(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayEndingScreen(),
      ),
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
        page: Container(
          color: teal,
          child: const RoleplayResultScreen(),
        ),
      ),
    );
  }

  static void popToOverview(BuildContext context) {
    SeriesStateService.instance
      ..markBestScoreRefreshPending()
      ..markProfileHistoryRefreshPending();
    Navigator.of(context).popUntil((route) {
      return route.isFirst ||
          route.settings.name == SeriesOverviewScreen.routeName;
    });
  }
}
