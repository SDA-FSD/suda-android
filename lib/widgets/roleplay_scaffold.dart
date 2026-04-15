import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 롤플레이 단계별 스크린(Opening, Playing, Ending, Failed, Result) 전용 스캐폴드
/// 롤플레이 도메인 특화 레이아웃 [전용 X 헤더 - 스크롤 본문 - 고정 푸터]를 제공합니다.
class RoleplayScaffold extends StatelessWidget {
  final Widget body;
  final Widget footer;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final String? title; // 헤더 중앙 타이틀 (English)
  final String? duration; // 헤더 중앙 듀레이션 (MM:ss)
  final Color? durationColor;
  final Widget? headerExtra;
  final double headerTopSpacing;

  /// null이면 기본 롤플레이 배경 `#121212` (전면 이미지 등 뒤에 깔 레이어가 있을 때는 `Colors.transparent` 등으로 지정)
  final Color? backgroundColor;

  const RoleplayScaffold({
    super.key,
    required this.body,
    required this.footer,
    this.showCloseButton = true,
    this.onClose,
    this.title,
    this.duration,
    this.durationColor,
    this.headerExtra,
    this.headerTopSpacing = 70,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 본문 영역 (헤더 공간 확보, 좌우 24 마진)
            Column(
              children: [
                SizedBox(height: headerTopSpacing),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: body,
                  ),
                ),
                // 2. 하단 가변 푸터 영역 (좌우 24 마진)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: footer,
                ),
                const SizedBox(height: 24),
              ],
            ),

            // 3. 헤더 좌측 상단 X 버튼
            if (showCloseButton)
              Positioned(
                top: 16,
                left: 16,
                child: _RoleplayCloseButton(onPressed: onClose),
              ),

            // 4. 헤더 중앙 타이틀 및 듀레이션
            Positioned(
              top: 16,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        title!,
                        style: theme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (duration != null)
                    Text(
                      duration!,
                      style: theme.bodySmall?.copyWith(
                        color: durationColor ?? Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (headerExtra != null) headerExtra!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 롤플레이 전용 닫기 버튼 (close.svg, 24x24)
class _RoleplayCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _RoleplayCloseButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        color: Colors.transparent,
        child: Center(
          child: SvgPicture.asset(
            'assets/images/icons/close.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
