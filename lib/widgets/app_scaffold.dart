import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 앱 전체의 공통 레이아웃 표준을 정의하는 베이스 스캐폴드
/// 
/// STYLE 가이드에 따라 다음 규칙을 적용합니다:
/// - 좌우 콘텐츠 여백: 24
/// - 본문 시작 상단 여백: 80
/// - 헤더 구성 규칙:
///   - 좌측 상단 아이콘: 뒤로가기(`assets/images/icons/header_arrow_back.svg`) 등. Positioned(top: 16, left: 16)
///   - 중앙 제목: 페이지 제목 표시 시 h2 스타일 사용 및 중앙 정렬
///   - 아이콘 표준 크기: 24x24
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title; // 헤더 좌측 상단에 표시될 보조 타이틀 (caption 스타일)
  final TextStyle? titleStyle; // 헤더 타이틀의 커스텀 스타일
  final String? centerTitle; // 헤더 중앙에 표시될 메인 타이틀 (h2 스타일)
  final Widget? leading; // 좌측 상단 버튼 (커스텀이 필요할 경우)
  final List<Widget>? actions; // 우측 상단에 표시될 버튼들
  final Color backgroundColor;
  final bool usePadding; // 본문 영역에 기본 24 패딩을 적용할지 여부
  final bool showBackButton; // 좌측 상단 뒤로가기 버튼 표시 여부 (기본 true)
  final Widget? bottomNavigationBar; // 하단 네비게이션 바 (메인 스크린용)
  final bool resizeToAvoidBottomInset; // 키보드에 따른 레이아웃 리사이즈 여부

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleStyle,
    this.centerTitle,
    this.leading,
    this.actions,
    this.backgroundColor = const Color(0xFF121212),
    this.usePadding = true,
    this.showBackButton = true,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      // GNB는 body 위에 오버레이로 배치하므로 Scaffold의 bottomNavigationBar는 사용하지 않음
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 본문 영역 (상단 70, 좌우 24 마진 적용) — GNB 아래까지 확장(본문이 GNB 위를 덮는 구조)
            Padding(
              padding: EdgeInsets.only(
                top: 70,
                left: usePadding ? 24 : 0,
                right: usePadding ? 24 : 0,
              ),
              child: body,
            ),

            // 2. 헤더 중앙 제목 (h2 스타일)
            if (centerTitle != null)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    centerTitle!,
                    style: theme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),

            // 3. 헤더 타이틀 (좌측 상단 16, 16 - 뒤로가기 버튼이 없을 때나 보조로 사용)
            if (title != null)
              Positioned(
                top: 16,
                left: showBackButton || leading != null ? 56 : 16, // 뒤로가기 버튼 공간 고려
                child: Text(
                  title!,
                  style: titleStyle ?? theme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),

            // 4. 좌측 상단 버튼 (뒤로가기 화살표 등)
            if (showBackButton || leading != null)
              Positioned(
                top: 16,
                left: 16,
                child: leading ?? backButton(context),
              ),

            // 5. 헤더 액션 버튼들 (우측 상단 16, 16)
            if (actions != null)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),

            // 6. GNB — 본문 위에 덮는 형태 (playing 슬라이더와 동일한 투명+블러는 각 화면 _buildGNB에서 적용)
            if (bottomNavigationBar != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: bottomNavigationBar!,
              ),
          ],
        ),
      ),
    );
  }

  /// 공통적으로 사용되는 뒤로가기 버튼 생성 헬퍼
  static Widget backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/icons/header_arrow_back.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  /// (구) X 버튼 - 하위 호환성 유지용 (점진적 제거 대상)
  static Widget closeButton(BuildContext context) {
    return backButton(context); // 이제 X 대신 화살표를 쓰므로 backButton으로 리다이렉트
  }
}
