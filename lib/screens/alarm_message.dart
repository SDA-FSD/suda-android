import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';

class AlarmMessageScreen extends StatelessWidget {
  const AlarmMessageScreen({super.key});

  static const String routeName = '/alarm_message';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      centerTitle: 'Alarm Message',
      body: Center(
        child: Text(
          'No messages yet.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
