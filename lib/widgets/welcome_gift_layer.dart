import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/energy_refresh_bus.dart';
import '../services/main_user_sync.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';

/// 앱 기동당 WelcomeGift 레이어 노출 시도 1회 가드.
class WelcomeGiftLayerGate {
  static bool shownThisLaunch = false;
}

/// Home 위 풀스크린 Welcome Gift 레이어.
///
/// 닫기 불가. Start Now 탭 시 `PUT /v1/users/grant-welcome-gift` 후 닫힘.
/// [previewOnly]면 API 없이 닫기만 한다(Lab).
class WelcomeGiftLayer extends StatefulWidget {
  const WelcomeGiftLayer({
    super.key,
    required this.onClosed,
    this.previewOnly = false,
  });

  final VoidCallback onClosed;
  final bool previewOnly;

  @override
  State<WelcomeGiftLayer> createState() => _WelcomeGiftLayerState();
}

class _WelcomeGiftLayerState extends State<WelcomeGiftLayer>
    with TickerProviderStateMixin {
  static const _blurPrepDuration = Duration(milliseconds: 500);
  static const _contentDuration = Duration(milliseconds: 1000);
  static const _mint = Color(0xFF0CABA8);

  late final AnimationController _blurController;
  late final AnimationController _contentController;
  late final AnimationController _twinkleController;

  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _blurController = AnimationController(
      vsync: this,
      duration: _blurPrepDuration,
    );
    _contentController = AnimationController(
      vsync: this,
      duration: _contentDuration,
    );
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _blurController.forward().then((_) {
      if (!mounted) return;
      _contentController.forward();
      _twinkleController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _blurController.dispose();
    _contentController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  Future<void> _onStartNow() async {
    if (_claiming) return;
    if (widget.previewOnly) {
      widget.onClosed();
      return;
    }

    setState(() => _claiming = true);
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null) return;

      await SudaApiClient.grantWelcomeGift(accessToken: accessToken);

      final user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
      MainUserSync.instance.notifyUserUpdated(user);

      final energy = await SudaApiClient.getUserEnergy(accessToken: accessToken);
      EnergyRefreshBus.instance.notify(energy);
    } catch (_) {
      // 비-200 / 네트워크 오류: meta 유지, 레이어만 숨김
    } finally {
      if (mounted) widget.onClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _blurController,
              builder: (context, _) {
                // 0 → 1 over 500ms; 뒤 홈이 더 잘 비치도록 완화
                return Opacity(
                  opacity: _blurController.value,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(color: const Color(0x4D000000)),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: Listenable.merge([
                _contentController,
                _twinkleController,
              ]),
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_contentController.value);
                return Opacity(
                  opacity: _contentController.value <= 0 ? 0 : 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildTopHalf(context, theme, l10n, t),
                      ),
                      Expanded(
                        child: _buildBottomHalf(context, theme, l10n, t),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHalf(
    BuildContext context,
    TextTheme theme,
    AppLocalizations l10n,
    double t,
  ) {
    // 상단 반을 4등분: [빈 영역][타이틀][이미지×2]
    return Column(
      children: [
        const Expanded(flex: 1, child: SizedBox.shrink()),
        Expanded(
          flex: 1,
          child: Center(
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, -24 * (1 - t)),
                child: Transform.scale(
                  scale: 0.85 + 0.15 * t,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.welcomeGiftTitle,
                      textAlign: TextAlign.center,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final areaW = constraints.maxWidth;
              final areaH = constraints.maxHeight;
              final base = math.min(areaW, areaH);
              final twinkle = _twinkleController.value;

              return Stack(
                alignment: Alignment.center,
                children: [
                  _rotatingGiftBg(
                    angleDeg: 30 + (-10 - 30) * t,
                    size: base * (0.5 + 0.5 * t),
                  ),
                  _rotatingGiftBg(
                    angleDeg: -20 + (40 - (-20)) * t,
                    size: base * (0.5 + 0.5 * t),
                  ),
                  Transform.rotate(
                    angle: (45 * (1 - t)) * math.pi / 180,
                    child: Image.asset(
                      'assets/images/icons/product_unlimited_10min.png',
                      width: 20 + 80 * t,
                      height: 20 + 80 * t,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: areaW / 2 - 60 - 25,
                    top: areaH / 2 - 60 - 25,
                    child: Opacity(
                      opacity: twinkle,
                      child: Image.asset(
                        'assets/images/like_progress_star.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                  Positioned(
                    left: areaW / 2 + 30 - 10,
                    top: areaH / 2 + 30 - 10,
                    child: Opacity(
                      opacity: twinkle,
                      child: Image.asset(
                        'assets/images/like_progress_star.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rotatingGiftBg({required double angleDeg, required double size}) {
    return Transform.rotate(
      angle: angleDeg * math.pi / 180,
      child: Image.asset(
        'assets/images/welcome_gift_bg.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBottomHalf(
    BuildContext context,
    TextTheme theme,
    AppLocalizations l10n,
    double t,
  ) {
    final bodyStyle = theme.bodySmall?.copyWith(color: Colors.white);
    const lineGap = 8.0;

    // 하단 반을 3등분: [혜택 텍스트][버튼][빈 영역]
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - t)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.welcomeGiftBenefitLead,
                        textAlign: TextAlign.center,
                        style: bodyStyle,
                      ),
                      const SizedBox(height: lineGap * 2),
                      IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _benefitRow(l10n.welcomeGiftLine2, bodyStyle),
                            const SizedBox(height: lineGap),
                            _benefitRow(l10n.welcomeGiftLine3, bodyStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.9 + 0.1 * t,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _claiming ? null : () => unawaited(_onStartNow()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mint,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _mint.withValues(alpha: 0.7),
                      disabledForegroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                    ),
                    child: _claiming
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.welcomeGiftStartNow),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Widget _benefitRow(String text, TextStyle? style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Image.asset(
            'assets/images/icons/paywall_check_Icon.png',
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: style),
        ),
      ],
    );
  }
}
