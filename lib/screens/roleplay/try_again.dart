import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../widgets/roleplay_scaffold.dart';

/// Roleplay Try Again Screen (Full Screen)
///
/// Roleplay 실패 종료 화면.
/// 닫기(X)/시스템 뒤로가기 시 Overview로 복귀. Retry는 동일 에피소드 Opening으로 재시작(S2).
/// 푸터 없음, 본문 영역만 노출.
class RoleplayTryAgainScreen extends StatefulWidget {
  static const String routeName = '/roleplay/try_again';

  final bool showCloseButton;

  const RoleplayTryAgainScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<RoleplayTryAgainScreen> createState() => _RoleplayTryAgainScreenState();
}

class _RoleplayTryAgainScreenState extends State<RoleplayTryAgainScreen>
    with TickerProviderStateMixin {
  static const Color _tryAgainGradientColor = Color(0xFF5F0C0C);

  late final AnimationController _fadeInController;
  late final AnimationController _heartWipeController;
  late final Animation<double> _fadeIn;
  /// Try Again Report 스크린에서 정상 전송 완료 후 돌아온 경우에만 true. 이때만 Report 텍스트 숨김.
  bool _reportSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heartWipeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeInController.forward().then((_) {
        if (mounted) _heartWipeController.forward();
      });
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _heartWipeController.dispose();
    super.dispose();
  }

  void _goToOverview(BuildContext context) {
    RoleplayRouter.popToOverview(context);
  }

  void _retry(BuildContext context) {
    RoleplayRouter.replaceWithOpeningForRetry(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToOverview(context);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF121212)),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      _tryAgainGradientColor,
                      _tryAgainGradientColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          RoleplayScaffold(
            backgroundColor: Colors.transparent,
            showCloseButton: widget.showCloseButton,
            onClose: () => _goToOverview(context),
            body: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Try Again',
                    style: theme.headlineMedium?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    width: screenWidth * 0.3,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        alignment: Alignment.center,
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/heart_broken.png',
                            fit: BoxFit.contain,
                          ),
                          AnimatedBuilder(
                            animation: _heartWipeController,
                            builder: (context, child) {
                              return ClipRect(
                                clipper: _TopToBottomWipeClipper(
                                  progress: _heartWipeController.value,
                                ),
                                child: Image.asset(
                                  'assets/images/heart_default.png',
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.roleplayTryAgainMessage,
                      style: theme.bodyLarge?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _retry(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                        elevation: 0,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                  _reportSubmitted
                      ? IgnorePointer(
                          child: Opacity(
                            opacity: 0,
                            child: Text(
                              l10n.endingReport,
                              style: theme.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () async {
                            final result =
                                await RoleplayRouter.pushTryAgainReport<bool>(
                                  context,
                                );
                            if (result == true && mounted) {
                              setState(() => _reportSubmitted = true);
                            }
                          },
                          child: Text(
                            l10n.endingReport,
                            style: theme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            footer: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Clips so top disappears first: visible rect is the bottom part (y = progress * height, height = (1-progress) * height).
class _TopToBottomWipeClipper extends CustomClipper<Rect> {
  final double progress;

  _TopToBottomWipeClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    final visibleHeight = size.height * (1 - progress);
    final top = size.height * progress;
    return Rect.fromLTWH(0, top, size.width, visibleHeight);
  }

  @override
  bool shouldReclip(_TopToBottomWipeClipper old) => old.progress != progress;
}
