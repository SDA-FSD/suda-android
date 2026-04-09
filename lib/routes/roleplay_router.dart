import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../services/rest_status_service.dart';
import '../utils/full_screen_route.dart';
import '../utils/sub_screen_route.dart';
import '../widgets/rest_overlay.dart';
import '../screens/roleplay/overview.dart';
import '../screens/roleplay/opening.dart';
import '../screens/roleplay/playing.dart';
import '../screens/roleplay/ending.dart';
import '../screens/roleplay/failed.dart';
import '../screens/roleplay/result.dart';
import '../screens/roleplay/result_v2.dart';
import '../screens/roleplay/failed_report.dart';
import '../screens/roleplay/result_report.dart';
import '../screens/roleplay/survey.dart';
import '../screens/roleplay/tutorial.dart';

class RoleplayRouter {
  static const String openingRouteName = '/roleplay/opening';

  /// Failed Report 스크린을 push (Failed 화면에서만 진입). pop 시 결과값(전송 성공 시 true)을 반환.
  static Future<T?> pushFailedReport<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      SubScreenRoute(
        page: const RoleplayFailedReportScreen(),
        settings: const RouteSettings(
          name: RoleplayFailedReportScreen.routeName,
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

  static void replaceWithFailed(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayFailedScreen(),
      ),
    );
  }

  /// Ending → Result 전환 시 흰 화면 방지: Material 대신 라우트 최상위를 #0CABA8로 그림.
  static void replaceWithResult(BuildContext context) {
    const teal = Color(0xFF0CABA8);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, __) => Container(
          color: teal,
          child: const RoleplayResultScreen(),
        ),
        settings: const RouteSettings(name: '/roleplay/result'),
      ),
    );
  }

  /// Result V2 전용 helper. 현재 기본 Result 종료 플로우에서 사용한다.
  static void replaceWithResultV2(BuildContext context) {
    const teal = Color(0xFF0CABA8);
    Navigator.pushReplacement(
      context,
      FullScreenRoute(
        transition: FullScreenTransition.bottomUp,
        settings: const RouteSettings(name: RoleplayResultScreenV2.routeName),
        page: Container(
          color: teal,
          child: const RoleplayResultScreenV2(),
        ),
      ),
    );
  }

  static void popToOverview(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      return route.isFirst || route.settings.name == RoleplayOverviewScreen.routeName;
    });
  }
}
