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
  /// null이면 `headlineSmall` + 흰색
  final TextStyle? titleStyle;
  /// null이면 2줄. 1이면 말줄임 한 줄.
  final int? titleMaxLines;
  final String? duration; // 헤더 중앙 듀레이션 (MM:ss)
  final Color? durationColor;
  final Widget? headerExtra;
  /// 헤더 타이틀 영역 바로 아래 전폭 슬롯 (예: S2 Playing 턴바영역). [belowHeaderHeight]와 쌍으로 사용.
  final Widget? belowHeader;
  final double belowHeaderHeight;
  /// 본문 시작 간격 델타 (정책 baseSpacing 70/90에 더해짐)
  final double headerTopSpacingDelta;

  /// true면 X·우측 액션 버튼 밴드(top 16, height 40) 안에서 타이틀 세로 중앙 정렬.
  final bool centerTitleInHeaderActionRow;

  /// null이면 기본 롤플레이 배경 `#121212` (전면 이미지 등 뒤에 깔 레이어가 있을 때는 `Colors.transparent` 등으로 지정)
  final Color? backgroundColor;

  const RoleplayScaffold({
    super.key,
    required this.body,
    required this.footer,
    this.showCloseButton = true,
    this.onClose,
    this.title,
    this.titleStyle,
    this.titleMaxLines,
    this.duration,
    this.durationColor,
    this.headerExtra,
    this.belowHeader,
    this.belowHeaderHeight = 0,
    this.headerTopSpacingDelta = 0,
    this.centerTitleInHeaderActionRow = false,
    this.backgroundColor,
  });

  int _computeTitleLineCount({
    required BuildContext context,
    required String title,
    required TextStyle? style,
    required double maxWidth,
    required int maxLines,
  }) {
    final safeWidth = maxWidth.isFinite && maxWidth > 0 ? maxWidth : 0.0;
    final painter = TextPainter(
      text: TextSpan(text: title, style: style),
      textDirection: Directionality.of(context),
      textAlign: TextAlign.center,
      maxLines: maxLines,
      ellipsis: '…',
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: safeWidth);

    final lines = painter.computeLineMetrics().length;
    return lines.clamp(1, maxLines);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    // Header layout rules:
    // - title: [titleMaxLines] lines with ellipsis (default 2)
    // - center header side margin: 30 (was 24)
    // - body top spacing: base 70, but 90 only when maxLines>=2 and title wraps to 2 lines
    // - final body top spacing: base + headerTopSpacingDelta
    const headerSideMargin = 30.0;
    const titleHorizontalPadding = 20.0;
    const headerActionTop = 16.0;
    const headerActionHeight = 40.0;

    final titleText = title;
    final effectiveTitleMaxLines = titleMaxLines ?? 2;
    final effectiveTitleStyle =
        titleStyle ?? theme.headlineSmall?.copyWith(color: Colors.white);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxTitleWidth = (screenWidth -
            (headerSideMargin * 2) -
            (titleHorizontalPadding * 2))
        .clamp(0.0, double.infinity);

    final baseHeaderTopSpacing = (titleText != null &&
            effectiveTitleMaxLines >= 2 &&
            _computeTitleLineCount(
                  context: context,
                  title: titleText,
                  style: effectiveTitleStyle,
                  maxWidth: maxTitleWidth,
                  maxLines: effectiveTitleMaxLines,
                ) ==
                2)
        ? 90.0
        : 70.0;

    final effectiveHeaderTopSpacing =
        baseHeaderTopSpacing + headerTopSpacingDelta;
    final effectiveBelowHeaderHeight =
        belowHeader != null ? belowHeaderHeight : 0.0;
    final bodyTopOffset =
        effectiveHeaderTopSpacing + effectiveBelowHeaderHeight;

    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 본문 영역 (헤더 공간 확보, 좌우 24 마진)
            Column(
              children: [
                SizedBox(height: bodyTopOffset),
                Expanded(
                  child: ClipRect(
                    clipBehavior: Clip.none,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: body,
                    ),
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
            if (centerTitleInHeaderActionRow &&
                title != null &&
                duration == null &&
                headerExtra == null)
              Positioned(
                top: headerActionTop,
                left: headerSideMargin,
                right: headerSideMargin,
                height: headerActionHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: titleHorizontalPadding,
                  ),
                  child: Center(
                    child: Text(
                      title!,
                      style: effectiveTitleStyle,
                      textAlign: TextAlign.center,
                      maxLines: effectiveTitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: 0,
                left: headerSideMargin,
                right: headerSideMargin,
                height: effectiveHeaderTopSpacing,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: titleHorizontalPadding,
                        ),
                        child: Text(
                          title!,
                          style: effectiveTitleStyle,
                          textAlign: TextAlign.center,
                          maxLines: effectiveTitleMaxLines,
                          overflow: TextOverflow.ellipsis,
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

            // 5. 헤더 직하 전폭 영역 (좌우 마진 없음)
            if (belowHeader != null)
              Positioned(
                top: effectiveHeaderTopSpacing,
                left: 0,
                right: 0,
                height: effectiveBelowHeaderHeight,
                child: belowHeader!,
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
