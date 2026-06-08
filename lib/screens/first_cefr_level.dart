import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../utils/english_level_util.dart';

/// 최초 서비스 이용 동의 직후 1회 노출되는 CEFR 레벨 선택 Full Screen.
class FirstCefrLevelScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FirstCefrLevelScreen({super.key, required this.onComplete});

  @override
  State<FirstCefrLevelScreen> createState() => _FirstCefrLevelScreenState();
}

class _FirstCefrLevelScreenState extends State<FirstCefrLevelScreen> {
  static const _backgroundColor = Color(0xFF121212);
  static const _accentColor = Color(0xFF0CABA8);
  static const _levelCodeColor = Color(0xFF07504E);
  static const _hintColor = Color(0xFF8C8C8C);
  static const _sideGradientStart = Color(0x99121212);
  static const _focusCircleWidthFraction = 0.8;
  /// 포커스 원 대비 좌·우 대기 원 지름 비율 (반원 peek와 무관)
  static const _sideCircleScale = 0.4;
  late final PageController _pageController;
  int _currentIndex = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 반원 peek 배치: 인접 페이지 중심을 화면 좌·우 끝에 맞춤 (원 크기와 무관)
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.5,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    Vibration.vibrate(duration: 80);
  }

  double _itemScale(int index) {
    if (!_pageController.hasClients || !_pageController.position.haveDimensions) {
      return index == _currentIndex ? 1.0 : _sideCircleScale;
    }
    final page = _pageController.page ?? _currentIndex.toDouble();
    final diff = (page - index).abs();
    return (1.0 - diff.clamp(0.0, 1.0) * (1.0 - _sideCircleScale))
        .clamp(_sideCircleScale, 1.0);
  }

  Future<void> _onConfirm() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateLanguageLevel(
          accessToken: token,
          languageLevel: _selectedLevel,
        );
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(
          context,
          'Failed to update language level: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onComplete();
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
            // 라벨 한 줄일 때 하단 descent 여백 보정
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

  Widget _buildCarousel(TextTheme theme, AppLocalizations l10n, double screenWidth) {
    final baseDiameter = screenWidth * _focusCircleWidthFraction;
    // 대기 원 반원이 노출되는 가로 폭 (= 대기 원 반지름)
    final sidePeekWidth = baseDiameter * _sideCircleScale * 0.5;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PageView.builder(
          controller: _pageController,
          clipBehavior: Clip.none,
          itemCount: EnglishLevelUtil.visibleLevels.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final cefrLevel = EnglishLevelUtil.visibleLevels[index];
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                final scale = _itemScale(index);
                final diameter = baseDiameter * scale;
                return Center(
                  child: _buildLevelCircle(
                    cefrLevel: cefrLevel,
                    levelLabel: _levelLabel(l10n, cefrLevel),
                    theme: theme,
                    diameter: diameter,
                  ),
                );
              },
            );
          },
        ),
        // 좌·우 끝 그라데이션: 대기 원 위를 덮어 반원 peek 연출
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Column(
          children: [
            Expanded(child: _buildTopSection(l10n, theme)),
            Expanded(
              child: Column(
                children: [
                  _buildDescriptionText(l10n, theme),
                  Expanded(
                    child: _buildCarousel(theme, l10n, screenWidth),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBottomSection(l10n, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(AppLocalizations l10n, TextTheme theme) {
    return Column(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Text(
                l10n.firstCefrLevelTitle,
                style: theme.headlineLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Widget _buildBottomSection(AppLocalizations l10n, TextTheme theme) {
    return Column(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.firstCefrLevelSettingsHint,
                    style: theme.labelSmall?.copyWith(
                      color: _hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onConfirm,
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
              ],
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
