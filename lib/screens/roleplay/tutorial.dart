import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibration/vibration.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/main_user_sync.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';

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

class _RoleplayTutorialScreenState extends State<RoleplayTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  bool _slide2HintVisible = false;
  final List<bool> _play = [false, false, false];
  final List<Timer?> _playDelay = [null, null, null];
  final GlobalKey _feedbackButtonKey = GlobalKey();
  OverlayEntry? _resultEntry;
  late final AnimationController _resultReveal;
  late final AnimationController _resultDim;
  late final AnimationController _resultRing;
  int _resultGen = 0;
  bool _playbackSyncQueued = false;
  late final AnimationController _readyBlink;
  int _currentPage = 0;
  int _tutorialStepHigh = 0;
  bool _isCheckingUser = true;
  bool _isSubmitting = false;

  static const int _totalPages = 3;
  static const double _readySlotHeight = 72;
  static const Color _ghost = Color(0x99FFFFFF);
  static const List<FontVariation> _wght700 = [FontVariation('wght', 700)];
  static const List<FontVariation> _wght800 = [FontVariation('wght', 800)];

  static const List<Color> _pageColors = [
    Color(0xFF0CABA8),
    Color(0xFFFFB700),
    Color(0xFFFF00A6),
  ];

  static const List<Color> _keywordColors = [
    Color(0xFF054544),
    Color(0xFF633721),
    Color(0xFF61003F),
  ];

  static const List<BoxShadow> _stageShadow = [
    BoxShadow(
      color: Color(0xA6000000),
      blurRadius: 28,
      offset: Offset(16, 22),
    ),
  ];

  /// 세부 묘사 바탕. 상단 `#121212` 100%, 높이 1/4에서 60%, 그 아래 60%.
  static const LinearGradient _stageBase = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121212),
      Color(0x99121212),
      Color(0x99121212),
    ],
    stops: [0, 0.25, 1],
  );

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_syncSlide2HintVisibility);
    _pageController.addListener(_syncPlayback);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback());
    _resultReveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() => _resultEntry?.markNeedsBuild());
    _resultDim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _resultRing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() => _resultEntry?.markNeedsBuild());
    _readyBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    if (widget.preview) {
      _isCheckingUser = false;
    } else {
      _checkTutorialStatus();
    }
  }

  void _syncPlayback() {
    if (_playbackSyncQueued) return;
    _playbackSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playbackSyncQueued = false;
      if (!mounted) return;
      _applyPlayback();
      _applySlide2HintVisibility();
    });
  }

  void _applyPlayback() {
    final page = _pageController.page ?? 0;
    if (!mounted) return;
    var changed = false;
    for (var i = 0; i < 3; i++) {
      final onPage = (page - i).abs() < 0.02;
      if (!onPage) {
        _playDelay[i]?.cancel();
        _playDelay[i] = null;
        if (_play[i]) {
          _play[i] = false;
          changed = true;
          if (i == 2) _stopResultLoop();
        }
      } else if (!_play[i] && _playDelay[i] == null) {
        _playDelay[i] = Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _playDelay[i] = null;
          setState(() => _play[i] = true);
          if (i == 2) _startResultLoop();
        });
      }
    }
    if (changed) setState(() {});
  }

  void _applySlide2HintVisibility() {
    final page = _pageController.page;
    if (page == null || !mounted) return;
    final visible = (page - 1).abs() < 0.02;
    if (visible == _slide2HintVisible) return;
    setState(() => _slide2HintVisible = visible);
  }

  void _syncSlide2HintVisibility() => _syncPlayback();

  RenderBox? _activeBox(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx is! Element || !ctx.mounted) return null;
    try {
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return null;
      return box;
    } on FlutterError {
      return null;
    }
  }

  void _stopResultLoop() {
    _resultGen++;
    final entry = _resultEntry;
    _resultEntry = null;
    entry?.remove();
    if (_resultReveal.isAnimating || _resultReveal.value != 0) {
      _resultReveal.stop();
      _resultReveal.value = 0;
    }
    _resultDim.stop();
    _resultDim.value = 0;
    _resultRing.stop();
    _resultRing.value = 0;
  }

  void _ensureResultEntry() {
    if (_resultEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final locale = Localizations.localeOf(context);
    _resultEntry = OverlayEntry(
      builder: (overlayContext) {
        return Localizations.override(
          context: context,
          locale: locale,
          child: _buildResultLessonOverlay(overlayContext),
        );
      },
    );
    overlay.insert(_resultEntry!);
  }

  Future<void> _startResultLoop() async {
    _resultGen++;
    final gen = _resultGen;
    _ensureResultEntry();
    while (mounted && _play[2] && gen == _resultGen) {
      await _resultRing.forward(from: 0);
      if (!mounted || !_play[2] || gen != _resultGen) return;
      _resultRing.value = 0;
      final open = _resultReveal.forward(from: 0);
      final dimIn = _resultDim.forward(from: 0);
      await Future.wait<void>([open, dimIn]);
      if (!mounted || !_play[2] || gen != _resultGen) return;
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted || !_play[2] || gen != _resultGen) return;
      }
      await Future.wait<void>([
        _resultReveal.reverse(),
        _resultDim.reverse(),
      ]);
      if (!mounted || !_play[2] || gen != _resultGen) return;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Widget _buildResultLessonOverlay(BuildContext overlayContext) {
    final screen = MediaQuery.sizeOf(overlayContext);
    final button = _activeBox(_feedbackButtonKey);
    final t = Curves.easeInOutCubic.transform(_resultReveal.value);
    final l10n = AppLocalizations.of(context)!;
    Offset? buttonCenter;
    if (button != null && button.attached && button.hasSize) {
      buttonCenter = button.localToGlobal(button.size.center(Offset.zero));
    }
    final cardWidth = screen.width - 48;
    return IgnorePointer(
      child: Stack(
        children: [
          if (t == 0 && buttonCenter != null)
            _resultRings(buttonCenter, _resultRingAmount),
          if (t > 0)
            Center(
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.08 + 0.92 * t,
                  alignment: _lessonOrigin(
                    screen,
                    buttonCenter,
                    Size(cardWidth, _lessonHeight(cardWidth, l10n)),
                  ),
                  child: SizedBox(
                    width: cardWidth,
                    child: _resultLessonCard(l10n),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Alignment _lessonOrigin(Size screen, Offset? button, Size card) {
    if (button == null || card.height <= 0) return Alignment.center;
    final cx = screen.width / 2;
    final cy = screen.height / 2;
    return Alignment(
      ((button.dx - cx) / (card.width / 2)).clamp(-6.0, 6.0),
      ((button.dy - cy) / (card.height / 2)).clamp(-8.0, 8.0),
    );
  }

  double _lessonHeight(double width, AppLocalizations l10n) {
    final painter = TextPainter(
      text: TextSpan(
        text: l10n.tutorialSlide3Feedback,
        style: const TextStyle(fontSize: 16, height: 1.2),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width - 32);
    final height = 16 + 18 + 8 + 40 + 8 + 18 + 8 + 40 + 16 + 12 + painter.height + 16;
    painter.dispose();
    return height;
  }

  double get _resultRingAmount {
    final t = _resultRing.value;
    final ping = t <= 0.5 ? t * 2 : (1 - t) * 2;
    return Curves.easeInOut.transform(ping);
  }

  Widget _resultRings(Offset center, double amount) {
    if (amount <= 0.01) return const SizedBox.shrink();
    final scale = 0.82 + 0.18 * amount;
    const canvas = _TutorialTranslateAim.canvas;
    return Positioned(
      left: center.dx - canvas / 2,
      top: center.dy - canvas / 2,
      width: canvas,
      height: canvas,
      child: Opacity(
        opacity: amount,
        child: CustomPaint(
          painter: _AimRingsPainter(
            color: const Color(0xFFFF00A6),
            innerRadius: _TutorialTranslateAim.innerRadius * scale,
            outerRadius: _TutorialTranslateAim.outerRadius * scale,
            innerStroke: _TutorialTranslateAim.innerStroke,
            outerStroke: _TutorialTranslateAim.outerStroke,
          ),
        ),
      ),
    );
  }

  Widget _resultLessonCard(AppLocalizations l10n) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tutorialSlide3SaidLabel,
              style: theme.bodySmall?.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Image(
                        image: AssetImage('assets/images/icons/megaphone.png'),
                        width: 24,
                        height: 24,
                        color: Colors.black,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'I want coffee.',
                        style: TextStyle(
                          fontFamily: 'ChironHeiHK',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontVariations: [FontVariation('wght', 700)],
                          color: Color(0xFF121212),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tutorialSlide3BetterLabel,
              style: theme.bodySmall?.copyWith(color: const Color(0xFF0CABA8)),
            ),
            const SizedBox(height: 8),
            const Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Image(
                        image: AssetImage('assets/images/icons/megaphone.png'),
                        width: 24,
                        height: 24,
                        color: Color(0xFF0CABA8),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "I'd like a coffee, please.",
                        style: TextStyle(
                          fontFamily: 'ChironHeiHK',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0CABA8),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: ColoredBox(
                color: Color(0xFFD9D9D9),
                child: SizedBox(width: double.infinity, height: 1),
              ),
            ),
            Text(
              l10n.tutorialSlide3Feedback,
              style: theme.bodyMedium?.copyWith(color: const Color(0xFF635F5F)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_syncSlide2HintVisibility);
    _pageController.removeListener(_syncPlayback);
    for (final timer in _playDelay) {
      timer?.cancel();
    }
    _stopResultLoop();
    _resultReveal.dispose();
    _resultDim.dispose();
    _resultRing.dispose();
    _readyBlink.dispose();
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

  void _updateLocalUserTutorialDone() {
    final currentUser = SeriesStateService.instance.user;
    if (currentUser == null) return;
    final updated = currentUser.upsertMetaInfo(key: 'TUTORIAL', value: 'Y');
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

  void _reportTutorialStep(int index) {
    if (widget.preview || index <= _tutorialStepHigh) return;
    final previous = _tutorialStepHigh;
    _tutorialStepHigh = index;
    if (previous < 1 && index >= 1) {
      unawaited(_postTutorialStepBestEffort(SudaApiClient.tutorial1To2));
    }
    if (previous < 2 && index >= 2) {
      unawaited(_postTutorialStepBestEffort(SudaApiClient.tutorial2To3));
    }
  }

  Future<void> _postTutorialStepBestEffort(
    Future<void> Function({required String accessToken}) post,
  ) async {
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted) return;
      if (accessToken == null) return;
      await post(accessToken: accessToken);
    } catch (_) {
      // best-effort: ignore
    }
  }

  void _vibrate() {
    Vibration.vibrate(duration: 80, amplitude: 200);
  }

  void _handleBottomTap(int index) {
    if (_isSubmitting) return;
    if (index >= _totalPages - 1) {
      if (widget.preview) {
        Navigator.of(context).pop();
      } else {
        _handleComplete();
      }
      return;
    }
    _pageController.animateToPage(
      index + 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        final fresh =
            await SudaApiClient.getCurrentUser(accessToken: accessToken);
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
      DefaultToast.show(
        context,
        'Failed to save tutorial. Please try again.',
        isError: true,
      );
    }
  }

  String _titleForPage(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.tutorialSlide1Title;
      case 1:
        return l10n.tutorialSlide2Title;
      case 2:
        return l10n.tutorialSlide3Title;
      default:
        return '';
    }
  }

  /// `**keyword**`만 강조.
  List<InlineSpan> _spansFor(String text, TextStyle base, Color keywordColor) {
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
            color: keywordColor,
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

  Widget _ghostAsset(String asset, double size, {bool svg = false}) {
    final child = svg
        ? SvgPicture.asset(asset, width: size, height: size)
        : Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(_ghost, BlendMode.srcIn),
      child: child,
    );
  }

  Widget _buildTitle(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = const TextStyle(
      fontFamily: 'ChironHeiHK',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontVariations: _wght700,
      letterSpacing: -0.4,
      height: 1.25,
      color: Colors.white,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Text.rich(
              TextSpan(
                children: _spansFor(
                  _titleForPage(l10n, index),
                  titleStyle,
                  _keywordColors[index],
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInactiveTurns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _ghost,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 4) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayingStage({
    required bool showTranslatorSample,
    bool translatorFrozen = false,
    bool hintVisible = false,
    bool animate = false,
  }) {
    const titleStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontVariations: _wght700,
      letterSpacing: -0.4,
      height: 1.2,
      color: _ghost,
    );
    return _TutorialStageFrame(
      child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const SizedBox(height: 8),
                  _buildInactiveTurns(),
                  const Spacer(),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 28),
                      child: Opacity(
                        opacity: 0.6,
                        child: Image(
                          image: AssetImage(
                            'assets/images/buttons/mic_btn_default.png',
                          ),
                          width: 88,
                          height: 88,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 20,
              left: 48,
              right: 48,
              height: 20,
              child: Text(
                'SUDA Talk',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            Positioned(
              left: 20,
              top: 20,
              child: _ghostAsset('assets/images/icons/close.svg', 20, svg: true),
            ),
            Positioned(
              right: 20,
              top: 20,
              child: _ghostAsset('assets/images/icons/kebab.png', 20),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: _ghostAsset('assets/images/icons/keyboard.png', 20),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: _ghostAsset('assets/images/icons/lightball.png', 20),
            ),
            if (showTranslatorSample)
              Positioned(
                left: 12,
                right: 8,
                top: 92,
                child: _TutorialTranslatorSample(
                  translation:
                      AppLocalizations.of(context)!.tutorialSlide1Translation,
                  frozen: translatorFrozen,
                  hintVisible: hintVisible,
                  animate: animate,
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildStars() {
    Widget star(double size, double degrees, double dy) {
      return Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(
          angle: degrees * math.pi / 180,
          child: Image.asset(
            'assets/images/star_gold.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        star(56, -10, 8),
        const SizedBox(width: 8),
        star(68, 0, 0),
        const SizedBox(width: 8),
        star(56, 10, 8),
      ],
    );
  }

  Widget _buildResultStage() {
    final theme = Theme.of(context).textTheme;
    return _TutorialStageFrame(
      fill: const Color(0xFF0CABA8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStars(),
                const SizedBox(height: 5),
                Text(
                  'Well Played!',
                  style: theme.headlineLarge?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                const Text(
                  'you are crushing it!',
                  style: TextStyle(
                    fontFamily: 'ChironGoRoundTC',
                    fontFamilyFallback: ['ChironHeiHK'],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontVariations: [FontVariation('wght', 600)],
                    color: Color(0xFF80D7CF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const _TutorialResultStatRow(),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Speech Feedback',
                    style: theme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                _TutorialSpeechFeedbackCard(
                  buttonKey: _feedbackButtonKey,
                  gradeLabel: 'NEEDS IMPROVEMENT',
                  gradeColor: const Color(0xFFFFB700),
                  speech: 'I want coffee.',
                ),
                const SizedBox(height: 16),
                const _TutorialSpeechFeedbackCard(
                  gradeLabel: 'GOOD',
                  gradeColor: Color(0xFF009628),
                  speech: 'Thank you',
                ),
              ],
            ),
          ),
        ),
          ),
          AnimatedBuilder(
            animation: _resultDim,
            builder: (context, _) {
              final t = _resultDim.value;
              if (t == 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10 * t,
                      sigmaY: 10 * t,
                    ),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.4 * t),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReady(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: _keywordColors[index],
          decoration: TextDecoration.none,
        );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _readyBlink, curve: Curves.easeInOut),
      ),
      child: Text(
        index == 2 ? l10n.tutorialSlideReady : l10n.tutorialSlideContinue,
        textAlign: TextAlign.center,
        style: style,
      ),
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
          width: isActive ? 10 : 5,
          height: isActive ? 10 : 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleBottomTap(index),
      child: ColoredBox(
        color: _pageColors[index],
        child: Column(
          children: [
            SizedBox(
              height: screenHeight / 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, top + 12, 24, 8),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(child: Center(child: _buildTitle(context, index))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 4, 44, 8),
                child: index == 2
                    ? _buildResultStage()
                    : _buildPlayingStage(
                        showTranslatorSample: index < 2,
                        translatorFrozen: index == 1,
                        hintVisible: index == 1 && _slide2HintVisible,
                        animate: index == 0 && _play[0],
                      ),
              ),
            ),
            SizedBox(
              height: _readySlotHeight + bottom,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: Center(child: _buildReady(context, index)),
              ),
            ),
          ],
        ),
      ),
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

    final top = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _pageColors[_currentPage],
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _vibrate();
                _reportTutorialStep(index);
              },
              itemBuilder: (context, index) => _buildPage(context, index),
            ),
            Positioned(
              top: top + 16,
              left: 0,
              right: 0,
              child: IgnorePointer(child: _buildDotIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

/// 그림자는 둥근 사각형 밖에만 그리고, 안쪽은 반투명 그라데이션만 깐다.
class _TutorialResultStatRow extends StatelessWidget {
  const _TutorialResultStatRow();

  static const _label = TextStyle(
    fontFamily: 'ChironGoRoundTC',
    fontFamilyFallback: ['ChironHeiHK'],
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: -0.4,
    height: 1.2,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          'Mission',
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              for (var i = 0; i < 3; i++)
                Image.asset(
                  'assets/images/icons/rps2_mission_on.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _card('Words', Text('08', style: valueStyle)),
        const SizedBox(width: 8),
        _card(
          'Like',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/like_at_result.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 2),
              Text('12', style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(String title, Widget child) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0x8080D7CF),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            Text(title, style: _label.copyWith(fontSize: 14), textAlign: TextAlign.center),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );
  }
}

class _TutorialSpeechFeedbackCard extends StatelessWidget {
  const _TutorialSpeechFeedbackCard({
    required this.gradeLabel,
    required this.gradeColor,
    required this.speech,
    this.buttonKey,
  });

  final String gradeLabel;
  final Color gradeColor;
  final String speech;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              gradeLabel,
              textAlign: TextAlign.start,
              style: theme.bodySmall?.copyWith(
                color: gradeColor,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Image(
                        image: AssetImage('assets/images/icons/megaphone.png'),
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: Colors.black,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        speech,
                        style: theme.bodyLarge?.copyWith(
                          color: const Color(0xFF121212),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                key: buttonKey,
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0CABA8)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Feedback',
                      style: theme.labelSmall?.copyWith(
                        color: const Color(0xFF0CABA8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.flip(
                      flipY: true,
                      child: Image.asset(
                        'assets/images/icons/click_to_fold.png',
                        width: 12,
                        height: 12,
                        fit: BoxFit.contain,
                        color: const Color(0xFF0CABA8),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStageFrame extends StatelessWidget {
  const _TutorialStageFrame({required this.child, this.fill});

  final Widget child;
  final Color? fill;

  static const double _radius = 28;
  static const double _shadowPad = 64;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -_shadowPad,
          top: -_shadowPad,
          right: -_shadowPad,
          bottom: -_shadowPad,
          child: ClipPath(
            clipper: const _ExteriorOnlyClipper(
              radius: _radius,
              inset: _shadowPad,
            ),
            child: const Padding(
              padding: EdgeInsets.all(_shadowPad),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF000000),
                  borderRadius: BorderRadius.all(Radius.circular(_radius)),
                  boxShadow: _RoleplayTutorialScreenState._stageShadow,
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(_radius)),
            color: fill,
            gradient: fill == null
                ? _RoleplayTutorialScreenState._stageBase
                : null,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(_radius)),
            child: fill == null
                ? child
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _RoleplayTutorialScreenState._stageBase,
                          ),
                        ),
                      ),
                      child,
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExteriorOnlyClipper extends CustomClipper<Path> {
  const _ExteriorOnlyClipper({required this.radius, required this.inset});

  final double radius;
  final double inset;

  @override
  Path getClip(Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          Radius.circular(radius),
        ),
      );
    return Path.combine(PathOperation.difference, outer, hole);
  }

  @override
  bool shouldReclip(covariant _ExteriorOnlyClipper oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.inset != inset;
  }
}

/// 1번 슬라이드. 영어 발화는 고정이고, 번역 줄만 사용자 언어.
/// 조준 원은 말풍선 너비에 넣지 않고 Overlay에 그린다.
class _TutorialTranslatorSample extends StatefulWidget {
  const _TutorialTranslatorSample({
    required this.translation,
    this.frozen = false,
    this.hintVisible = false,
    this.animate = false,
  });

  final String translation;

  /// 2번 슬라이드. 번역은 활성으로 고정하고 조준 원은 그리지 않는다.
  final bool frozen;

  /// 2번 슬라이드가 화면에 있을 때만 힌트 오버레이를 둔다.
  final bool hintVisible;

  /// 1번 슬라이드가 1초 머문 뒤에만 번역 루프를 돌린다.
  final bool animate;

  @override
  State<_TutorialTranslatorSample> createState() =>
      _TutorialTranslatorSampleState();
}

class _TutorialTranslatorSampleState extends State<_TutorialTranslatorSample>
    with SingleTickerProviderStateMixin {
  static const _english = 'Would you like to order?';
  static const _avatarSize = 32.0;
  static const _iconGap = 5.0;

  final LayerLink _iconLink = LayerLink();
  bool _expanded = false;
  OverlayEntry? _hintEntry;
  final LayerLink _hintLink = LayerLink();
  late final AnimationController _rings;
  late final Animation<double> _ringScale;
  OverlayEntry? _ringsEntry;
  Timer? _activeHold;

  @override
  void initState() {
    super.initState();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addStatusListener(_onRingStatus);
    _ringScale = CurvedAnimation(parent: _rings, curve: Curves.easeInOut);
    if (widget.frozen) {
      _expanded = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.frozen) {
        if (widget.hintVisible) _insertHint();
        return;
      }
      if (widget.animate) _beginTranslationLoop();
    });
  }

  void _beginTranslationLoop() {
    _insertRings();
    if (_rings.isAnimating || _activeHold != null) return;
    _rings.forward(from: 0);
  }

  void _resetTranslationLoop() {
    _activeHold?.cancel();
    _activeHold = null;
    _rings.stop();
    _rings.value = 0;
    _ringsEntry?.remove();
    _ringsEntry = null;
    if (_expanded) setState(() => _expanded = false);
  }

  void _onRingStatus(AnimationStatus status) {
    if (!mounted) return;
    switch (status) {
      case AnimationStatus.forward:
        _activeHold?.cancel();
        if (!_expanded) setState(() => _expanded = true);
      case AnimationStatus.completed:
        _activeHold?.cancel();
        _activeHold = Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          _rings.reverse();
        });
      case AnimationStatus.reverse:
        if (_expanded) setState(() => _expanded = false);
      case AnimationStatus.dismissed:
        _rings.forward();
    }
  }

  void _removeHint() {
    _hintEntry?.remove();
    _hintEntry = null;
  }

  @override
  void didUpdateWidget(covariant _TutorialTranslatorSample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.frozen && widget.animate != oldWidget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.animate) {
          _beginTranslationLoop();
        } else if (!widget.frozen) {
          _resetTranslationLoop();
        }
      });
    }
    if (!widget.frozen) return;
    if (widget.hintVisible) {
      if (_hintEntry == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.hintVisible) _insertHint();
        });
      }
    } else {
      _removeHint();
    }
  }

  void _insertHint() {
    if (_hintEntry != null || !widget.hintVisible) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final locale = Localizations.localeOf(context);
    _hintEntry = OverlayEntry(
      builder: (overlayContext) {
        final screenW = MediaQuery.sizeOf(overlayContext).width;
        return Localizations.override(
          context: context,
          locale: locale,
            child: CompositedTransformFollower(
            link: _hintLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(-32, 14),
            child: Align(
              alignment: Alignment.topLeft,
              child: IgnorePointer(
                child: SizedBox(
                  width: screenW - 48,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(decoration: TextDecoration.none),
                    child: const _TutorialHintCoach(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_hintEntry!);
  }

  void _insertRings() {
    if (_ringsEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _ringsEntry = OverlayEntry(builder: _buildRings);
    overlay.insert(_ringsEntry!);
  }

  Widget _buildRings(BuildContext context) {
    return IgnorePointer(
      child: CompositedTransformFollower(
        link: _iconLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.center,
        followerAnchor: Alignment.center,
        child: AnimatedBuilder(
          animation: _ringScale,
          builder: (context, _) {
            final scale = 0.82 + (1 - 0.82) * _ringScale.value;
            return SizedBox(
              width: _TutorialTranslateAim.canvas,
              height: _TutorialTranslateAim.canvas,
              child: CustomPaint(
                painter: _AimRingsPainter(
                  innerRadius: _TutorialTranslateAim.innerRadius * scale,
                  outerRadius: _TutorialTranslateAim.outerRadius * scale,
                  innerStroke: _TutorialTranslateAim.innerStroke,
                  outerStroke: _TutorialTranslateAim.outerStroke,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activeHold?.cancel();
    _hintEntry?.remove();
    _hintEntry = null;
    _ringsEntry?.remove();
    _ringsEntry = null;
    _rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        );
    final translationStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF777373),
        );
    return CompositedTransformTarget(
      link: _hintLink,
      child: LayoutBuilder(
      builder: (context, constraints) {
        final maxBubble = (constraints.maxWidth -
                _avatarSize -
                _iconGap -
                _iconGap -
                _TutorialTranslateAim.iconSize)
            .clamp(0.0, double.infinity);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/tutorial/turorial_character.png',
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: _iconGap),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubble),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _expanded ? 1 : 0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                builder: (context, t, translationChild) {
                  final scaler = MediaQuery.textScalerOf(context);
                  final englishPainter = TextPainter(
                    text: TextSpan(text: _english, style: textStyle),
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                  )..layout(maxWidth: maxBubble);
                  final translationPainter = TextPainter(
                    text: TextSpan(
                      text: widget.translation,
                      style: translationStyle,
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: Directionality.of(context),
                    textScaler: scaler,
                  )..layout(maxWidth: maxBubble);
                  final extraWidth =
                      (translationPainter.width - englishPainter.width)
                          .clamp(0.0, double.infinity);
                  final bubbleWidth = englishPainter.width + extraWidth * t;
                  englishPainter.dispose();
                  translationPainter.dispose();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF353535),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: bubbleWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _english,
                            style: textStyle,
                            textAlign: TextAlign.start,
                            textDirection: TextDirection.ltr,
                          ),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.topLeft,
                              heightFactor: t,
                              child: translationChild,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.translation,
                    style: translationStyle,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _iconGap),
            CompositedTransformTarget(
              link: _iconLink,
              child: SizedBox(
                width: _TutorialTranslateAim.iconSize,
                height: _TutorialTranslateAim.iconSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: _expanded ? 1 : 0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  builder: (context, t, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/icons/translation_grey.png',
                          width: _TutorialTranslateAim.iconSize,
                          height: _TutorialTranslateAim.iconSize,
                        ),
                        Opacity(
                          opacity: t,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/icons/translation_grey.png',
                              width: _TutorialTranslateAim.iconSize,
                              height: _TutorialTranslateAim.iconSize,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }
}

class _TutorialTranslateAim {
  static const iconSize = 36.0;
  static const innerStroke = 5.0;
  static const outerStroke = 3.0;
  static const gap = 10.0;
  static const pad = 4.0;

  /// 아이콘+여백 기준 안쪽 원 중심 반지름의 1.5배.
  static const innerRadius =
      (iconSize / 2 + pad + innerStroke / 2) * 1.5;
  static const outerRadius =
      innerRadius + innerStroke / 2 + gap + outerStroke / 2;
  static const canvas = (outerRadius + outerStroke / 2) * 2 + 2;
}

class _AimRingsPainter extends CustomPainter {
  const _AimRingsPainter({
    this.color = Colors.white,
    required this.innerRadius,
    required this.outerRadius,
    required this.innerStroke,
    required this.outerStroke,
  });

  final Color color;
  final double innerRadius;
  final double outerRadius;
  final double innerStroke;
  final double outerStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    paint.strokeWidth = innerStroke;
    canvas.drawCircle(center, innerRadius, paint);
    paint.strokeWidth = outerStroke;
    canvas.drawCircle(center, outerRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _AimRingsPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius;
  }
}

/// 2번 슬라이드 힌트. 메가폰 강조선 뒤 문장 물들임, 이어서 please만 반복.
class _TutorialHintCoach extends StatefulWidget {
  const _TutorialHintCoach();

  @override
  State<_TutorialHintCoach> createState() => _TutorialHintCoachState();
}

class _TutorialHintCoachState extends State<_TutorialHintCoach>
    with SingleTickerProviderStateMixin {
  static const _words = ['Just', 'a', 'latte,', 'please.'];
  static const _header = Color(0xFF054544);
  static const _accent = Color(0xFF80D7CF);
  static const _teal = Color(0xFF0CABA8);
  static const _bubble = Color(0xFF194847);

  final GlobalKey _megaphoneKey = GlobalKey();
  final GlobalKey _pleaseKey = GlobalKey();
  late final AnimationController _cycle;
  OverlayEntry? _ringsEntry;
  Timer? _startDelay;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6400),
    )..addListener(() => _ringsEntry?.markNeedsBuild());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _insertRings();
      _startDelay = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _cycle.repeat();
      });
    });
  }

  void _insertRings() {
    if (_ringsEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _ringsEntry = OverlayEntry(builder: _buildRings);
    overlay.insert(_ringsEntry!);
  }

  @override
  void dispose() {
    _startDelay?.cancel();
    _ringsEntry?.remove();
    _ringsEntry = null;
    _cycle.dispose();
    super.dispose();
  }

  double _window(double t, double start, double end) {
    if (t <= start || t >= end) return t >= end ? 1 : 0;
    return Curves.easeInOut.transform((t - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle =
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{})
            ?.copyWith(color: _accent, decoration: TextDecoration.none) ??
        theme.textTheme.bodyMedium?.copyWith(
          color: _accent,
          decoration: TextDecoration.none,
        );
    final lineStyle = theme.textTheme.bodyMedium?.copyWith(
      color: _accent,
      decoration: TextDecoration.none,
    );
    final wordStyle = (theme.textTheme.headlineSmall ?? theme.textTheme.bodyLarge)
        ?.copyWith(
          height: 1.35,
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.none,
        );

    return AnimatedBuilder(
      animation: _cycle,
      builder: (context, _) {
        final t = _cycle.value;
        final mega = _ping(t, 0.02, 0.30);
        final sentenceFlow = t < 0.08 || t >= 0.48
            ? 0.0
            : _window(t, 0.08, 0.36);
        final sentenceFade = t >= 0.36 && t < 0.48
            ? _window(t, 0.36, 0.48)
            : 0.0;
        final pleaseRing = _ping(t, 0.54, 0.86);
        final pleaseFlow = t < 0.60 || t >= 0.90
            ? 0.0
            : _window(t, 0.60, 0.78);
        final pleaseFade = t >= 0.78 && t < 0.90
            ? _window(t, 0.78, 0.90)
            : 0.0;
        return Container(
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: _bubble.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 27,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _header,
                  borderRadius: BorderRadius.circular(13.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        _accent,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/icons/lightball.png',
                        height: 14,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(l10n.roleplayHintLabel, style: labelStyle),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Text(
                  l10n.tutorialSlide2HintLine,
                  style: lineStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1 + 0.28 * mega,
                        alignment: Alignment.center,
                        child: SizedBox(
                          key: _megaphoneKey,
                          width: 40,
                          height: 40,
                          child: Center(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Color.lerp(Colors.white, _teal, mega)!,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/icons/megaphone.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < _words.length; i++) ...[
                            if (i > 0)
                              Text(
                                ' ',
                                style: wordStyle?.copyWith(color: Colors.white),
                              ),
                            _word(
                              i,
                              wordStyle,
                              sentenceFlow,
                              sentenceFade,
                              pleaseRing,
                              pleaseFlow,
                              pleaseFade,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 구간 안에서 0→1→0.
  double _ping(double t, double start, double end) {
    if (t <= start || t >= end) return 0;
    final u = (t - start) / (end - start);
    final up = u < 0.5 ? u * 2 : (1 - u) * 2;
    return Curves.easeInOut.transform(up);
  }

  Widget _word(
    int index,
    TextStyle? base,
    double sentenceFlow,
    double sentenceFade,
    double pleaseRing,
    double pleaseFlow,
    double pleaseFade,
  ) {
    final word = _words[index];
    final isPlease = index == _words.length - 1;
    final pleaseOn = isPlease && (pleaseFlow > 0 || pleaseFade > 0);
    final flow = pleaseOn ? pleaseFlow : sentenceFlow;
    final fade = pleaseOn ? pleaseFade : sentenceFade;
    final count = pleaseOn ? word.length : _sentenceChars();
    final localIndex = pleaseOn ? 0 : _charStart(index);
    final scale = pleaseOn
        ? 1 + 0.2 * pleaseRing
        : sentenceFlow > 0
            ? 1 + 0.45 * _bell(index, sentenceFlow)
            : 1.0;
    final spans = <InlineSpan>[
      for (var i = 0; i < word.length; i++)
        TextSpan(
          text: word[i],
          style: base?.copyWith(
            color: _flowColor(
              pleaseOn ? i : localIndex + i,
              count,
              flow,
              fade,
            ),
          ),
        ),
    ];
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            key: isPlease ? _pleaseKey : null,
            TextSpan(children: spans),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: _hintWordUnderlineGap),
          SizedBox(
            width: _measureWordWidth(word, base),
            height: 3,
            child: const CustomPaint(
              painter: _TutorialHintDottedUnderlinePainter(color: _teal),
            ),
          ),
        ],
      ),
    );
  }

  static const double _hintWordUnderlineGap = 2;

  double _measureWordWidth(String word, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(
        children: [
          for (var i = 0; i < word.length; i++)
            TextSpan(text: word[i], style: style),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  int _sentenceChars() => _words.fold(0, (n, w) => n + w.length);

  int _charStart(int wordIndex) {
    var n = 0;
    for (var i = 0; i < wordIndex; i++) {
      n += _words[i].length;
    }
    return n;
  }

  double _bell(int wordIndex, double wash) {
    final n = _words.length;
    final center = (wordIndex + 0.5) / n;
    final dist = (wash - center).abs();
    final half = 0.5 / n;
    return (1 - dist / half).clamp(0.0, 1.0);
  }

  Color _flowColor(int index, int count, double progress, double fade) {
    if (count <= 0 || (progress <= 0 && fade <= 0)) return Colors.white;
    final local = (progress * (count + 1) - index).clamp(0.0, 1.0);
    final flowed = Color.lerp(Colors.white, _teal, local)!;
    return Color.lerp(flowed, Colors.white, fade)!;
  }

  Widget _buildRings(BuildContext context) {
    final t = _cycle.value;
    final mega = _ping(t, 0.02, 0.30);
    final please = _ping(t, 0.54, 0.86);
    final showPlease = please > mega;
    final amount = showPlease ? please : mega;
    final key = showPlease ? _pleaseKey : _megaphoneKey;
    if (amount <= 0.01) return const SizedBox.shrink();
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) {
      return const SizedBox.shrink();
    }
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final canvas = _TutorialTranslateAim.canvas;
    final scale = (0.78 + 0.22 * amount) * (showPlease ? 1.3 : 1);
    final draw = canvas * scale;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: center.dx - draw / 2,
            top: center.dy - draw / 2,
            width: draw,
            height: draw,
            child: CustomPaint(
              painter: _AimRingsPainter(
                innerRadius: _TutorialTranslateAim.innerRadius * scale,
                outerRadius: _TutorialTranslateAim.outerRadius * scale,
                innerStroke: _TutorialTranslateAim.innerStroke,
                outerStroke: _TutorialTranslateAim.outerStroke,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Playing 힌트 원문과 같은 점선 밑줄. 대시 3, 간격 3, 두께 1.5.
class _TutorialHintDottedUnderlinePainter extends CustomPainter {
  static const double _strokeWidth = 1.5;
  static const double _dashLength = 3;
  static const double _dashGap = 3;

  final Color color;

  const _TutorialHintDottedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final segmentEnd = math.min(x + _dashLength, size.width);
      if (segmentEnd > x) {
        canvas.drawLine(Offset(x, y), Offset(segmentEnd, y), paint);
      }
      x += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(
    covariant _TutorialHintDottedUnderlinePainter oldDelegate,
  ) => color != oldDelegate.color;
}
