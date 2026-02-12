import 'package:flutter/material.dart';

import '../models/user_models.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/gnb_bar.dart';

/// Notification Box Screen (기존 AlarmMessageScreen)
class NotificationBoxScreen extends StatelessWidget {
  const NotificationBoxScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToProfile,
    this.onNavigateToAlarm,
    this.isActive = false,
    this.user,
  });

  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToAlarm;
  final bool isActive;
  final UserDto? user;

  static const String routeName = '/notification_box';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: false,
      centerTitle: 'Notification Box',
      bottomNavigationBar: GnbBar(
        isAlarmActive: true,
        isHomeActive: false,
        isProfileActive: false,
        onAlarmTap: () {},
        onHomeTap: onNavigateToHome,
        onProfileTap: onNavigateToProfile,
        user: user,
      ),
      body: const Center(
        child: Text(
          'No messages yet.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

