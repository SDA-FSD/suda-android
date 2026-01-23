import 'package:flutter/material.dart';
import 'result.dart';
import 'overview.dart';
import '../../widgets/roleplay_scaffold.dart';

/// Roleplay Failed Screen (Full Screen)
/// 
/// Roleplay 실패 종료 화면
class RoleplayFailedScreen extends StatelessWidget {
  final bool showCloseButton;

  const RoleplayFailedScreen({
    super.key,
    this.showCloseButton = true,
  });

  void _navigateToResult(BuildContext context) {
    // failed screen 삭제하고 result로 전환
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleplayResultScreen(),
      ),
    );
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    // 뒤로가기 시 얼럿 표시
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification'),
        content: const Text('Exit from failed screen'),
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
      // failed screen 삭제하고 overview로 돌아감
      Navigator.of(context).popUntil((route) {
        return route.isFirst || route.settings.name == RoleplayOverviewScreen.routeName;
      });
    }

    return false;
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
          child: GestureDetector(
            onTap: () => _navigateToResult(context),
            child: Text(
              'Result',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
