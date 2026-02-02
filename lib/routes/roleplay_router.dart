import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../utils/sub_screen_route.dart';
import '../screens/roleplay/overview.dart';
import '../screens/roleplay/opening.dart';
import '../screens/roleplay/playing.dart';
import '../screens/roleplay/ending.dart';
import '../screens/roleplay/failed.dart';
import '../screens/roleplay/result.dart';
import '../screens/roleplay/report.dart';

class RoleplayRouter {
  static const String openingRouteName = '/roleplay/opening';

  /// Report 스크린을 push. pop 시 결과값(전송 성공 시 true)을 반환.
  static Future<T?> pushReport<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      SubScreenRoute(
        page: const RoleplayReportScreen(),
        settings: const RouteSettings(
          name: RoleplayReportScreen.routeName,
        ),
      ),
    );
  }

  static void pushOverview(BuildContext context, int roleplayId, {UserDto? user}) {
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

  static void replaceWithResult(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayResultScreen(),
      ),
    );
  }

  static void popToOverview(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      return route.isFirst || route.settings.name == RoleplayOverviewScreen.routeName;
    });
  }
}
