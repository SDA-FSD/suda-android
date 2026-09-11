import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../widgets/default_profile_avatar.dart';

/// 최초 CEFR 선택 직후 1회 노출되는 기본 프로필 이미지 선택 Full Screen.
class FirstProfileImageScreen extends StatefulWidget {
  final void Function(UserDto? updatedUser) onComplete;

  const FirstProfileImageScreen({super.key, required this.onComplete});

  @override
  State<FirstProfileImageScreen> createState() =>
      _FirstProfileImageScreenState();
}

class _FirstProfileImageScreenState extends State<FirstProfileImageScreen> {
  static const _backgroundColor = Color(0xFF121212);
  static const _hintColor = Color(0xFF8C8C8C);
  static const _sideGradientStart = Color(0x99121212);
  /// 포커스 원 = 캐러셀 영역 안에 맞는 최대 정사각. 측면은 이 배율.
  static const _sideCircleScale = 0.4;

  /// value `1`…`5`와 동일 순서.
  static const _optionColors = <Color>[
    Color(0xFF03ABA8),
    Color(0xFFFFB700),
    Color(0xFFFFAAE1),
    Color(0xFFB286EB),
    Color(0xFF054544),
  ];

  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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

  String get _selectedValue => '${_currentIndex + 1}';

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    Vibration.vibrate(duration: 80);
  }

  double _itemScale(int index) {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
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
    UserDto? updated;
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateProfileImage(
          accessToken: token,
          type: 'DEFAULT',
          value: _selectedValue,
        );
        updated = await SudaApiClient.getCurrentUser(accessToken: token);
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(
          context,
          'Failed to update profile image: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onComplete(updated);
      }
    }
  }

  /// 포커스 크기로 아바타를 한 번만 만들고 [Transform.scale]로 측면 축소 → 마스크 비율 고정.
  Widget _buildCarousel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final focusSize = constraints.maxHeight < constraints.maxWidth
            ? constraints.maxHeight
            : constraints.maxWidth;
        final sidePeekWidth = focusSize * _sideCircleScale * 0.5;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              itemCount: _optionColors.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final avatar = DefaultProfileAvatar(
                  size: focusSize,
                  color: _optionColors[index],
                );
                return AnimatedBuilder(
                  animation: _pageController,
                  child: avatar,
                  builder: (context, child) {
                    return Center(
                      child: Transform.scale(
                        scale: _itemScale(index),
                        child: child,
                      ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Column(
          children: [
            Expanded(child: _buildTopSection(l10n, theme)),
            Expanded(child: _buildCarousel()),
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
                l10n.firstProfileImageTitle,
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
                        : Text(l10n.actionConfirm),
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
