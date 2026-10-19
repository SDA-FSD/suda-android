import 'package:flutter/material.dart';

import 'tutorial_roleplay_backdrop.dart';

/// Tutorial Roleplay 본편 전까지의 자리 표시. Intro Start(마이크 허용) 후 진입.
class TutorialRoleplayStubScreen extends StatelessWidget {
  final VoidCallback onClose;
  final bool preview;

  const TutorialRoleplayStubScreen({
    super.key,
    required this.onClose,
    this.preview = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return PopScope(
      canPop: preview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onClose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const TutorialRoleplayBackdrop(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tutorial Roleplay',
                        textAlign: TextAlign.center,
                        style: theme.headlineLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Coming soon',
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CABA8),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
