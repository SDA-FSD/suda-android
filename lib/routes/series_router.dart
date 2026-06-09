import 'package:flutter/material.dart';

import '../models/user_models.dart';
import '../screens/series/overview.dart';
import '../services/rest_status_service.dart';
import '../utils/sub_screen_route.dart';
import '../widgets/rest_overlay.dart';

class SeriesRouter {
  static void pushOverview(BuildContext context, int seriesId, {UserDto? user}) {
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
        page: SeriesOverviewScreen(seriesId: seriesId, user: user),
        settings: RouteSettings(
          name: SeriesOverviewScreen.routeName,
          arguments: seriesId,
        ),
      ),
    );
  }
}
