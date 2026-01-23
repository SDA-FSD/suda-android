import 'package:flutter/material.dart';
import 'ending.dart';
import 'failed.dart';
import 'overview.dart';
import '../../widgets/roleplay_scaffold.dart';

/// Roleplay Playing Screen (Full Screen)
/// 
/// Roleplay 진행 중 화면
class RoleplayPlayingScreen extends StatelessWidget {
  final bool showCloseButton;

  const RoleplayPlayingScreen({
    super.key,
    this.showCloseButton = true,
  });

  void _navigateToEnding(BuildContext context) {
    // playing screen 삭제하고 ending으로 전환
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayEndingScreen(),
      ),
    );
  }

  void _navigateToFailed(BuildContext context) {
    // playing screen 삭제하고 failed로 전환
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayFailedScreen(),
      ),
    );
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    // 뒤로가기 시 얼럿 표시
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification'),
        content: const Text('Exit from page'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (shouldPop == true && context.mounted) {
      // playing screen 삭제하고 overview로 돌아감
      // overview는 Sub Screen이므로 Navigator.popUntil으로 overview까지 pop
      Navigator.of(context).popUntil((route) {
        return route.isFirst || route.settings.name == RoleplayOverviewScreen.routeName;
      });
    }

    return false; // PopScope가 자동으로 pop하지 않도록
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBackButton(context);
        }
      },
      child: RoleplayScaffold(
        showCloseButton: showCloseButton,
        onClose: () => _handleBackButton(context),
        body: const SizedBox.shrink(),
        footer: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _navigateToEnding(context),
                child: Text(
                  'Ending',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _navigateToFailed(context),
                child: Text(
                  'Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
