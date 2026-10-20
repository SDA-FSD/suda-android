import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/default_popup.dart';
import '../../widgets/roleplay_mic_button_area.dart';
import '../../widgets/roleplay_turn_bar_area.dart';
import 'tutorial_pointer.dart';
import 'tutorial_roleplay_backdrop.dart';

/// 온보딩 Tutorial Roleplay. 현재 1단계: 미션 확인 + Skip.
///
/// 흐름: `tutorial_rp_bg` 선명 페이드인 → Playing처럼 blur·딤 → 미션/말풍선 → 탭 포인터.
class TutorialRoleplayScreen extends StatefulWidget {
  final VoidCallback onSkip;
  final bool preview;
  final VoidCallback? onMissionGuideContinue;

  const TutorialRoleplayScreen({
    super.key,
    required this.onSkip,
    this.preview = false,
    this.onMissionGuideContinue,
  });

  @override
  State<TutorialRoleplayScreen> createState() => _TutorialRoleplayScreenState();
}

class _TutorialRoleplayScreenState extends State<TutorialRoleplayScreen>
    with TickerProviderStateMixin {
  static const _bgFadeIn = Duration(seconds: 3);
  /// 영상(2026-10-19 4.01.05): 선명 hold → blur ~0.5s → UI ~0.45s 간격.
  static const _sharpHold = Duration(milliseconds: 600);
  static const _blurReveal = Duration(milliseconds: 550);

  late final AnimationController _bgFade;
  late final AnimationController _blurUi;
  late final AnimationController _micLoadingRotation;
  late final Animation<double> _chromeOpacity;

  /// 영상 참고: Missions 타이틀 → 미션 박스 → 말풍선 → 포인터 순.
  bool _showMissionsTitle = false;
  bool _showMissionBox = false;
  bool _showBubble = false;
  bool _showPointer = false;

  @override
  void initState() {
    super.initState();
    _bgFade = AnimationController(vsync: this, duration: _bgFadeIn);
    _blurUi = AnimationController(vsync: this, duration: _blurReveal);
    _micLoadingRotation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chromeOpacity = CurvedAnimation(parent: _blurUi, curve: Curves.easeOut);

    _bgFade.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startBlurUiPhase();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bgFade.forward();
    });
  }

  Future<void> _startBlurUiPhase() async {
    await Future<void>.delayed(_sharpHold);
    if (!mounted) return;
    // 블러·크롬 먼저 → 잠깐 블러만 → Missions → 박스 → 말풍선 → 포인터
    await _blurUi.forward();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showMissionsTitle = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _showMissionBox = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _showBubble = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showPointer = true);
  }

  @override
  void dispose() {
    _bgFade.dispose();
    _blurUi.dispose();
    _micLoadingRotation.dispose();
    super.dispose();
  }

  Future<void> _showSkipPopup() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    await DefaultPopup.show(
      context,
      titleText: l10n.tutorialRoleplaySkipTitle,
      expandPrimaryButtons: true,
      bodyWidget: Text(
        l10n.tutorialRoleplaySkipBody,
        textAlign: TextAlign.center,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.tutorialRoleplaySkipConfirm,
          onPressed: widget.onSkip,
        ),
        DefaultPopupButton(
          type: DefaultPopupButtonType.text,
          label: l10n.tutorialRoleplaySkipKeepGoing,
          onPressed: () {},
        ),
      ],
    );
  }

  void _onContinue() {
    widget.onMissionGuideContinue?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    final missions = [
      l10n.tutorialRoleplayMission1,
      l10n.tutorialRoleplayMission2,
      l10n.tutorialRoleplayMission3,
    ];

    return PopScope(
      canPop: widget.preview,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: AnimatedBuilder(
          animation: Listenable.merge([_bgFade, _blurUi]),
          builder: (context, _) {
            final bgOpacity = Curves.easeOut.transform(_bgFade.value);
            final blurAmount = _blurUi.value;

            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: bgOpacity,
                  child: TutorialRoleplayBackdrop(blurAmount: blurAmount),
                ),
                if (_blurUi.value > 0)
                  FadeTransition(
                    opacity: _chromeOpacity,
                    child: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: SizedBox(
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    l10n.tutorialRoleplayTitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showSkipPopup,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.tutorialRoleplaySkip,
                                        style: theme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          RoleplayTurnBarArea(
                            turnCount: 3,
                            barColors: List<Color>.filled(
                              3,
                              RoleplayTurnBarArea.defaultBarColor,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onContinue,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                ),
                                child: Column(
                                  children: [
                                    const Spacer(flex: 2),
                                    _StaggerFade(
                                      visible: _showMissionsTitle,
                                      child: Text(
                                        l10n.tutorialRoleplayMissions,
                                        textAlign: TextAlign.center,
                                        style: theme.headlineLarge?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _StaggerFade(
                                      visible: _showMissionBox,
                                      child: _MissionListBox(
                                        missions: missions,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    _StaggerFade(
                                      visible: _showBubble,
                                      child: _GuideBubble(
                                        mainText: l10n
                                            .tutorialRoleplayGuideMissionMain,
                                        subText: l10n
                                            .tutorialRoleplayGuideMissionTapContinue,
                                        showPointer: _showPointer,
                                      ),
                                    ),
                                    const Spacer(flex: 3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _PlayingLikeDisabledFooter(
                            loadingRotationController: _micLoadingRotation,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StaggerFade extends StatelessWidget {
  final bool visible;
  final Widget child;

  const _StaggerFade({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}

/// 시안: radius 26 · 흰 6.8% 채우기 + Playing 미션 패널과 동일 BackdropFilter blur 12.
class _MissionListBox extends StatelessWidget {
  static const _radius = 26.0;
  /// 시안 채우기 `#FFFFFF` 6.8%.
  static final _fill = Colors.white.withValues(alpha: 0.068);

  final List<String> missions;

  const _MissionListBox({required this.missions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.36),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              children: [
                for (var i = 0; i < missions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/icons/rps2_mission_off.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          missions[i],
                          style: theme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideBubble extends StatelessWidget {
  static const _fill = Color(0xFF0CABA8);
  static const _sub = Color(0xFF054544);

  final String mainText;
  final String subText;
  final bool showPointer;

  const _GuideBubble({
    required this.mainText,
    required this.subText,
    required this.showPointer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 10),
          painter: const _BubbleTailPainter(color: _fill),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 문구만 가운데 정렬. 손가락은 오버레이(레이아웃에 영향 없음).
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    mainText,
                    textAlign: TextAlign.center,
                    style: theme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  // "탭해서 계속하기 >" 옆에 손끝·원
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subText,
                              style: theme.bodyMedium?.copyWith(color: _sub),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: _sub,
                              size: 20,
                            ),
                          ],
                        ),
                        if (showPointer)
                          const Positioned(
                            // 손끝·원이 ">" 오른쪽·같은 높이에 오도록
                            right: -80,
                            top: -22,
                            child: IgnorePointer(
                              child: TutorialPointer(size: 120),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;

  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Playing `buildPlayingFooter` 녹음 모드와 동일 크기·위치. 타이핑 토글만 비노출(빈 40슬롯).
class _PlayingLikeDisabledFooter extends StatelessWidget {
  final AnimationController loadingRotationController;

  const _PlayingLikeDisabledFooter({
    required this.loadingRotationController,
  });

  @override
  Widget build(BuildContext context) {
    // RoleplayScaffold 푸터와 동일: SafeArea + 좌우 24 + 하단 24.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            const SizedBox(height: 10),
            SizedBox(
              height: roleplayMicFooterStackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: roleplayFooterIconRowHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 타이핑 버튼 자리만 유지 (미노출)
                          const SizedBox(width: 40, height: 40),
                          const Expanded(child: SizedBox.shrink()),
                          Opacity(
                            opacity: 0.4,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/icons/lightball.png',
                                  height: 24,
                                  width: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: RoleplayMicButtonArea(
                      isInteractive: false,
                      isLoading: false,
                      isDisabled: true,
                      loadingRotationController: loadingRotationController,
                      onPressStart: () {},
                      onPressEnd: (_) {},
                      onPressCancel: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
