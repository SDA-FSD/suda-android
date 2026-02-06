import 'package:flutter/material.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';

/// Roleplay Failed Screen (Full Screen)
///
/// Roleplay 실패 종료 화면.
/// 닫기(X)/시스템 뒤로가기 시 확인 다이얼로그 없이 Overview로 복귀 (Opening과 동일).
/// 푸터 없음, 본문 영역만 노출.
class RoleplayFailedScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayFailedScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<RoleplayFailedScreen> createState() => _RoleplayFailedScreenState();
}

class _RoleplayFailedScreenState extends State<RoleplayFailedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInController;
  late final AnimationController _heartWipeController;
  late final Animation<double> _fadeIn;
  /// Failed Report 스크린에서 정상 전송 완료 후 돌아온 경우에만 true. 이때만 Report 텍스트 숨김.
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {},
      child: RoleplayScaffold(
        showCloseButton: widget.showCloseButton,
        onClose: () => _goToOverview(context),
        body: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // 1st: "Failed" (h2, white, center)
              Text(
                'Failed',
                style: theme.headlineMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),

              // 2nd: heart_broken + heart_default (30% width, default wipes to reveal broken)
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

              // 3rd: ending.fail.title + subtitle (body-default, white)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.endingFailTitle,
                    style: theme.bodyLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.endingFailSubtitle,
                    style: theme.bodyLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // 4th: Retry button (Opening style, bg white, text black)
              SizedBox(
                width: screenWidth * 0.4,
                child: ElevatedButton(
                  onPressed: () => _goToOverview(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Retry'),
                ),
              ),

              // 5th: Report 텍스트. 처음엔 보이고 탭 시 Failed Report 스크린 진입. Failed Report에서 정상 전송 완료 후 돌아오면 숨김(레이아웃 유지용 플레이스홀더만)
              _reportSubmitted
                  ? IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: Text(
                          l10n.endingReport,
                          style: theme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () async {
                        final result = await RoleplayRouter.pushFailedReport<bool>(context);
                        if (result == true && mounted) {
                          setState(() => _reportSubmitted = true);
                        }
                      },
                      child: Text(
                        l10n.endingReport,
                        style: theme.bodySmall?.copyWith(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
        footer: const SizedBox.shrink(),
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
