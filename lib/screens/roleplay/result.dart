import 'package:flutter/material.dart';
import 'overview.dart';
import '../../widgets/roleplay_scaffold.dart';

/// Roleplay Result Screen (Full Screen)
/// 
/// Roleplay 결과 화면
class RoleplayResultScreen extends StatelessWidget {
  final bool showCloseButton;

  const RoleplayResultScreen({
    super.key,
    this.showCloseButton = true,
  });

  void _navigateToOverview(BuildContext context) {
    // result screen 삭제하고 overview로 돌아감
    Navigator.of(context).popUntil((route) {
      return route.isFirst || route.settings.name == RoleplayOverviewScreen.routeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _navigateToOverview(context);
        }
      },
      child: RoleplayScaffold(
        showCloseButton: showCloseButton,
        onClose: () => _navigateToOverview(context),
        body: const SizedBox.shrink(),
        footer: Center(
          child: GestureDetector(
            onTap: () => _navigateToOverview(context),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
