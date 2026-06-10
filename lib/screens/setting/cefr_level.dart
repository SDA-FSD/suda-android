import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibration/vibration.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/english_level_util.dart';
import '../../widgets/app_scaffold.dart';

class CefrLevelScreen extends StatefulWidget {
  final UserDto? user;

  const CefrLevelScreen({super.key, this.user});

  @override
  State<CefrLevelScreen> createState() => _CefrLevelScreenState();
}

class _CefrLevelScreenState extends State<CefrLevelScreen>
    with SingleTickerProviderStateMixin {
  static const _accentColor = Color(0xFF0CABA8);
  static const _levelCodeColor = Color(0xFF07504E);
  static const _sideGradientStart = Color(0x99121212);
  static const _focusCircleWidthFraction = 0.8;
  static const _sideCircleScale = 0.4;
  static const _sidePeekFadeDuration = Duration(milliseconds: 280);
  static const _sidePeekFadeOutDuration = Duration(milliseconds: 160);

  PageController? _pageController;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isClosing = false;
  bool _routeListenerAttached = false;
  bool _sidePeekFadeScheduled = false;
  bool _sidePeekFadeCompleted = false;

  late final AnimationController _sidePeekFadeController;
  late final Animation<double> _sidePeekFadeAnimation;

  @override
  void initState() {
    super.initState();
    _sidePeekFadeController = AnimationController(
      vsync: this,
      duration: _sidePeekFadeDuration,
    );
    _sidePeekFadeAnimation = CurvedAnimation(
      parent: _sidePeekFadeController,
      curve: Curves.easeOut,
    );
    _sidePeekFadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _sidePeekFadeCompleted = true);
      }
    });
    _initializeLevel();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _sidePeekFadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeListenerAttached) return;
    _routeListenerAttached = true;

    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation == null) {
      _scheduleSidePeekFadeIn();
      return;
    }
    if (routeAnimation.status == AnimationStatus.completed) {
      _scheduleSidePeekFadeIn();
      return;
    }
    routeAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scheduleSidePeekFadeIn();
      }
    });
  }

  void _scheduleSidePeekFadeIn() {
    if (_sidePeekFadeScheduled || _sidePeekFadeCompleted) return;
    _sidePeekFadeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageController == null) return;
      _sidePeekFadeController.forward();
    });
  }

  bool _isCenterCarouselIndex(int index) {
    final controller = _pageController;
    if (controller == null) return index == _currentIndex;
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return index == _currentIndex;
    }
    final page = controller.page ?? _currentIndex.toDouble();
    return (page - index).abs() < 0.05;
  }

  double _opacityForCarouselItem(int index) {
    if (_isCenterCarouselIndex(index)) return 1.0;
    if (_isClosing) return _sidePeekFadeAnimation.value;
    if (_sidePeekFadeCompleted) return 1.0;
    return _sidePeekFadeAnimation.value;
  }

  bool get _hasSideCarouselItems {
    return _currentIndex > 0 ||
        _currentIndex < EnglishLevelUtil.visibleLevels.length - 1;
  }

  Future<void> _closeWithSideFadeOut() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    setState(() {});

    final shouldFadeOut = !_isLoading &&
        _pageController != null &&
        _hasSideCarouselItems &&
        _sidePeekFadeAnimation.value > 0;

    if (shouldFadeOut) {
      await _sidePeekFadeController.animateTo(
        0,
        duration: _sidePeekFadeOutDuration,
        curve: Curves.easeIn,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _isClosing ? null : _closeWithSideFadeOut,
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

  String _levelLabel(AppLocalizations l10n, String cefrLevel) {
    switch (cefrLevel) {
      case 'Pre-A1':
        return l10n.cefrLevelAbsoluteBeginner;
      case 'A1':
        return l10n.cefrLevelBeginner;
      case 'A2':
        return l10n.cefrLevelBasic;
      case 'B1':
        return l10n.cefrLevelIntermediate;
      default:
        return cefrLevel;
    }
  }

  String _levelDescription(AppLocalizations l10n, String cefrLevel) {
    switch (cefrLevel) {
      case 'Pre-A1':
        return l10n.firstCefrLevelDescriptionPreA1;
      case 'A1':
        return l10n.firstCefrLevelDescriptionA1;
      case 'A2':
        return l10n.firstCefrLevelDescriptionA2;
      case 'B1':
        return l10n.firstCefrLevelDescriptionB1;
      default:
        return '';
    }
  }

  String get _selectedLevel => EnglishLevelUtil.visibleLevels[_currentIndex];

  int _indexForLevel(String level) {
    final idx = EnglishLevelUtil.visibleLevels.indexOf(level);
    return idx >= 0 ? idx : 0;
  }

  void _initializeLevel() {
    if (widget.user != null) {
      _applyLoadedLevel(_readLevelFromUser(widget.user!));
      return;
    }
    _fetchUserInfo();
  }

  String _readLevelFromUser(UserDto user) {
    final levelMeta = user.metaInfo?.firstWhere(
      (meta) => meta.key == 'ENGLISH_LEVEL',
      orElse: () => const SudaJson(
        key: 'ENGLISH_LEVEL',
        value: EnglishLevelUtil.defaultLevel,
      ),
    );
    return EnglishLevelUtil.normalizeToCefr(levelMeta?.value);
  }

  void _applyLoadedLevel(String level) {
    _currentIndex = _indexForLevel(level);
    _pageController?.dispose();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.5,
    );
    setState(() => _isLoading = false);
    _maybeStartSidePeekFadeAfterLoad();
  }

  void _maybeStartSidePeekFadeAfterLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageController == null) return;
      final anim = ModalRoute.of(context)?.animation;
      if (anim == null || anim.status == AnimationStatus.completed) {
        _scheduleSidePeekFadeIn();
      }
    });
  }

  Future<void> _fetchUserInfo() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        final user = await SudaApiClient.getCurrentUser(accessToken: token);
        if (!mounted) return;
        _applyLoadedLevel(_readLevelFromUser(user));
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    _applyLoadedLevel(EnglishLevelUtil.defaultLevel);
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    Vibration.vibrate(duration: 80);
  }

  double _itemScale(int index) {
    final controller = _pageController;
    if (controller == null ||
        !controller.hasClients ||
        !controller.position.haveDimensions) {
      return index == _currentIndex ? 1.0 : _sideCircleScale;
    }
    final page = controller.page ?? _currentIndex.toDouble();
    final diff = (page - index).abs();
    return (1.0 - diff.clamp(0.0, 1.0) * (1.0 - _sideCircleScale))
        .clamp(_sideCircleScale, 1.0);
  }

  void _updateLocalUserMeta(String cefrLevel) {
    if (widget.user?.metaInfo == null) return;
    final meta = widget.user!.metaInfo!;
    final index = meta.indexWhere((m) => m.key == 'ENGLISH_LEVEL');
    if (index != -1) {
      meta[index] = SudaJson(key: 'ENGLISH_LEVEL', value: cefrLevel);
    } else {
      meta.add(SudaJson(key: 'ENGLISH_LEVEL', value: cefrLevel));
    }
  }

  Future<void> _onConfirm() async {
    if (_isSubmitting || _isClosing) return;

    setState(() => _isSubmitting = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateLanguageLevel(
          accessToken: token,
          languageLevel: _selectedLevel,
        );
        _updateLocalUserMeta(_selectedLevel);
      }
      if (!mounted) return;
      await _closeWithSideFadeOut();
    } catch (e) {
      if (mounted) {
        DefaultToast.show(
          context,
          'Failed to update language level: $e',
          isError: true,
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildLevelCircle({
    required String cefrLevel,
    required String levelLabel,
    required TextTheme theme,
    required double diameter,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: _accentColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: diameter * 0.08),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -diameter * 0.025),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cefrLevel,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: theme.bodyMedium?.copyWith(
                    color: _levelCodeColor,
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation('wght', 700)],
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: diameter * 0.03),
                Text(
                  levelLabel,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: theme.headlineSmall?.copyWith(
                    color: Colors.white,
                    height: 1.1,
                    fontSize: (theme.headlineSmall?.fontSize ?? 20) *
                        (diameter /
                            (MediaQuery.sizeOf(context).width *
                                _focusCircleWidthFraction)),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionText(AppLocalizations l10n, TextTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _levelDescription(l10n, _selectedLevel),
        style: theme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCarousel(
    TextTheme theme,
    AppLocalizations l10n,
    double screenWidth,
  ) {
    final controller = _pageController!;
    final baseDiameter = screenWidth * _focusCircleWidthFraction;
    final sidePeekWidth = baseDiameter * _sideCircleScale * 0.5;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PageView.builder(
          controller: controller,
          clipBehavior: Clip.none,
          itemCount: EnglishLevelUtil.visibleLevels.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final cefrLevel = EnglishLevelUtil.visibleLevels[index];
            return AnimatedBuilder(
              animation: Listenable.merge([
                controller,
                _sidePeekFadeController,
              ]),
              builder: (context, child) {
                final scale = _itemScale(index);
                final diameter = baseDiameter * scale;
                final isCenter = _isCenterCarouselIndex(index);
                Widget circle = _buildLevelCircle(
                  cefrLevel: cefrLevel,
                  levelLabel: _levelLabel(l10n, cefrLevel),
                  theme: theme,
                  diameter: diameter,
                );
                if (isCenter) {
                  circle = GestureDetector(
                    onTap: (_isSubmitting || _isClosing) ? null : _onConfirm,
                    behavior: HitTestBehavior.opaque,
                    child: circle,
                  );
                }
                return Opacity(
                  opacity: _opacityForCarouselItem(index),
                  child: Center(child: circle),
                );
              },
            );
          },
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: sidePeekWidth,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_sideGradientStart, Color(0x00121212)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: sidePeekWidth,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [_sideGradientStart, Color(0x00121212)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection(AppLocalizations l10n, TextTheme theme) {
    return Column(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Expanded(
          child: Center(
            child: _buildDescriptionText(l10n, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isClosing) ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white.withOpacity(0.6),
                  disabledForegroundColor: Colors.black.withOpacity(0.6),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(l10n.firstCefrLevelConfirm),
              ),
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isClosing) return;
        _closeWithSideFadeOut();
      },
      child: AppScaffold(
        centerTitle: l10n.settingsCefrLevel,
        usePadding: false,
        leading: _buildBackButton(),
        body: _isLoading || _pageController == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(child: _buildTopSection(l10n, theme)),
                Expanded(
                  child: _buildCarousel(theme, l10n, screenWidth),
                ),
                Expanded(child: _buildBottomSection(l10n)),
              ],
            ),
      ),
    );
  }
}
