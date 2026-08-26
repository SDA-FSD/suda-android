import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/main_user_sync.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../models/user_models.dart';

class RoleplayTutorialScreen extends StatefulWidget {
  const RoleplayTutorialScreen({
    super.key,
    this.preview = false,
  });

  static const String routeName = '/roleplay/tutorial';

  /// Lab 미리보기. 완료 API·Opening 전환 없이 닫기만 한다.
  final bool preview;

  @override
  State<RoleplayTutorialScreen> createState() => _RoleplayTutorialScreenState();
}

class _RoleplayTutorialScreenState extends State<RoleplayTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingUser = true;
  bool _isSubmitting = false;

  static const int _totalPages = 6;
  static const double _imageAspect = 880 / 1912;
  static const Color _hintKeywordColor = Color(0xFF704028);
  static const List<FontVariation> _wght700 = [FontVariation('wght', 700)];
  static const List<FontVariation> _wght800 = [FontVariation('wght', 800)];
  static const List<FontVariation> _wght400 = [FontVariation('wght', 400)];

  static const List<Color> _pageColors = [
    Color(0xFF0CABA8),
    Color(0xFFFF00A6),
    Color(0xFFFFB700),
    Color(0xFF0CABA8),
    Color(0xFFFF00A6),
    Color(0xFF8A38F5),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preview) {
      _isCheckingUser = false;
    } else {
      _checkTutorialStatus();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Opening 전환은 첫 프레임 이후에만 수행(build 중 pushReplacement 방지).
  void _scheduleReplaceWithOpening() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RoleplayRouter.replaceWithOpeningFromTutorial(context);
    });
  }

  Future<void> _checkTutorialStatus() async {
    UserDto? user = SeriesStateService.instance.user;

    if (user == null) {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted) return;
      if (accessToken != null) {
        try {
          user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
          SeriesStateService.instance.setUser(user);
          RoleplayStateService.instance.setUser(user);
        } catch (_) {
          // 조회 실패 시 튜토리얼 노출
        }
      }
    }

    if (!mounted) return;

    final tutorialDone = user?.metaInfo?.any(
          (m) => m.key == 'TUTORIAL' && m.value == 'Y',
        ) ??
        false;

    if (tutorialDone) {
      _scheduleReplaceWithOpening();
      return;
    }

    // 튜토리얼을 실제로 노출하기로 확정된 경우에만 best-effort로 통계 호출
    unawaited(_postTutorialShownBestEffort());
    setState(() => _isCheckingUser = false);
  }

  String _imagePath(int pageIndex) {
    return 'assets/images/tutorial/tutorial${pageIndex + 1}.png';
  }

  void _updateLocalUserTutorialDone() {
    final currentUser = SeriesStateService.instance.user;
    if (currentUser == null) return;
    final updated =
        currentUser.upsertMetaInfo(key: 'TUTORIAL', value: 'Y');
    SeriesStateService.instance.setUser(updated);
    RoleplayStateService.instance.setUser(updated);
  }

  Future<void> _postTutorialShownBestEffort() async {
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted) return;
      if (accessToken == null) return;
      await SudaApiClient.tutorialShown(accessToken: accessToken);
    } catch (_) {
      // best-effort: ignore
    }
  }

  void _vibrate() {
    Vibration.vibrate(duration: 80, amplitude: 200);
  }

  void _handleTap() {
    if (_isSubmitting) return;
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (widget.preview) {
      Navigator.of(context).pop();
    } else {
      _handleComplete();
    }
  }

  Future<void> _handleComplete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (accessToken == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await SudaApiClient.completeTutorial(accessToken: accessToken);
      if (!mounted) return;
      try {
        final fresh = await SudaApiClient.getCurrentUser(accessToken: accessToken);
        if (!mounted) return;
        SeriesStateService.instance.setUser(fresh);
        RoleplayStateService.instance.setUser(fresh);
        MainUserSync.instance.notifyUserUpdated(fresh);
      } catch (_) {
        _updateLocalUserTutorialDone();
        final u = SeriesStateService.instance.user;
        if (u != null) MainUserSync.instance.notifyUserUpdated(u);
      }
      if (!mounted) return;
      _scheduleReplaceWithOpening();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      DefaultToast.show(context, 'Failed to save tutorial. Please try again.', isError: true);
    }
  }

  ({String title, String subtitle, Color? keywordColor}) _copyForPage(
    AppLocalizations l10n,
    int index,
  ) {
    switch (index) {
      case 0:
        return (
          title: l10n.tutorialPage1Title,
          subtitle: l10n.tutorialPage1Tip,
          keywordColor: null,
        );
      case 1:
        return (
          title: l10n.tutorialPage2Title,
          subtitle: '',
          keywordColor: null,
        );
      case 2:
        return (
          title: l10n.tutorialPage3Title,
          subtitle: l10n.tutorialPage3Subtitle,
          keywordColor: _hintKeywordColor,
        );
      case 3:
        return (
          title: l10n.tutorialPage4Title,
          subtitle: l10n.tutorialPage4Tip,
          keywordColor: null,
        );
      case 4:
        return (
          title: l10n.tutorialPage5Title,
          subtitle: l10n.tutorialPage5Subtitle,
          keywordColor: null,
        );
      case 5:
        return (
          title: l10n.tutorialPage6Title,
          subtitle: '',
          keywordColor: null,
        );
      default:
        return (title: '', subtitle: '', keywordColor: null);
    }
  }

  /// `**keyword**`만 강조. 팁의 선행 `*`는 그대로 둔다.
  List<InlineSpan> _spansFor(
    String text,
    TextStyle base, {
    Color? keywordColor,
  }) {
    final parts = text.split('**');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      if (i % 2 == 1) {
        spans.add(TextSpan(
          text: parts[i],
          style: base.copyWith(
            fontWeight: FontWeight.w800,
            fontVariations: _wght800,
            color: keywordColor ?? base.color,
          ),
        ));
      } else {
        spans.add(TextSpan(text: parts[i], style: base));
      }
    }
    if (spans.isEmpty) {
      return [TextSpan(text: '', style: base)];
    }
    return spans;
  }

  Widget _buildRich(
    String text,
    TextStyle style, {
    Color? keywordColor,
  }) {
    return Text.rich(
      TextSpan(children: _spansFor(text, style, keywordColor: keywordColor)),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOverlay(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final copy = _copyForPage(l10n, index);
    final titleStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      fontSize: index == 5 ? 28 : 24,
      fontWeight: FontWeight.w700,
      fontVariations: _wght700,
      letterSpacing: -0.4,
      height: 1.2,
      color: Colors.white,
    );
    final subtitleStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontVariations: _wght400,
      letterSpacing: -0.4,
      height: 1.3,
      color: Colors.white,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final isLast = index == 5;
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _imagePath(index),
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              top: isLast ? h * 0.28 : h * 0.775,
              bottom: isLast ? h * 0.38 : h * 0.03,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth - 56,
                  child: isLast
                      ? _buildRich(copy.title, titleStyle)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRich(
                              copy.title,
                              titleStyle,
                              keywordColor: copy.keywordColor,
                            ),
                            if (copy.subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildRich(
                                copy.subtitle,
                                subtitleStyle,
                                keywordColor: copy.keywordColor,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.4),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0CABA8)),
        ),
      );
    }

    return PopScope(
      canPop: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _pageColors[_currentPage],
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildDotIndicator(),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _totalPages,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _vibrate();
                      },
                      itemBuilder: (context, index) {
                        return ColoredBox(
                          color: _pageColors[index],
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: _imageAspect,
                              child: _buildOverlay(context, index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
