import 'package:flutter/material.dart';
import '../utils/sub_screen_route.dart';
import '../screens/roleplay/overview.dart';
import '../screens/roleplay/opening.dart';
import '../screens/roleplay/playing.dart';
import '../screens/roleplay/ending.dart';
import '../screens/roleplay/failed.dart';
import '../screens/roleplay/result.dart';

class RoleplayRouter {
  static const String openingRouteName = '/roleplay/opening';

  static void pushOverview(BuildContext context, int roleplayId) {
    Navigator.push(
      context,
      SubScreenRoute(
        page: RoleplayOverviewScreen(roleplayId: roleplayId),
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
