import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../screens/paywall/paywall.dart';
import '../screens/setting/push_agreement.dart';
import '../services/energy_refresh_bus.dart';
import '../services/iap_purchase_service.dart';
import '../services/pending_out_of_energy_push_reminder.dart';
import '../services/suda_api_client.dart';
import '../services/token_refresh_service.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../utils/paywall_impression_screen.dart';
import '../utils/sub_screen_route.dart';

enum _OutOfEnergyCard { premium, chatPass, wait }

const _pink = Color(0xFFFF00A6);
const _ctaPurple = Color(0xFF8A38F5);

enum _OutOfEnergySheetResult { goHome, askPush }

/// 충전/유도 시트와 동일 chrome
const _energySheetRadius = BorderRadius.vertical(top: Radius.circular(24));
/// 시트 외곽: Explorar 계열 — 0% 투명 없음·0==1 seam·이음은 하단(덜 보임).
const _energySheetBorderGradient = SweepGradient(
  startAngle: 1.5707963267948966, // 90° bottom seam
  colors: [
    Color(0x29FFFFFF), // 0.0 == 1.0
    Color(0x4FFFFFFF), // ~31%
    Color(0x1AFFFFFF), // ~10% floor (끊김 방지)
    Color(0x4FFFFFFF),
    Color(0x1AFFFFFF),
    Color(0x29FFFFFF),
  ],
  stops: [0.0, 0.12, 0.37, 0.62, 0.87, 1.0],
);

/// Wait: 50%/70% 피크, 골은 ~12% (0% 금지).
const _waitBorderGradient = SweepGradient(
  startAngle: 1.5707963267948966,
  colors: [
    Color(0x80FFFFFF), // seam / 50%
    Color(0x80FFFFFF), // 12% 50%
    Color(0x1FFFFFFF), // 37% ~12%
    Color(0xB3FFFFFF), // 62% 70%
    Color(0x1FFFFFFF), // 87% ~12%
    Color(0x80FFFFFF),
  ],
  stops: [0.0, 0.12, 0.37, 0.62, 0.87, 1.0],
);

/// Opening/Playing 에너지 부족 충전 바텀시트.
/// [playingHeader]면 타이틀·안내만 Playing 문구 + Betty 웃는 이미지.
Future<void> showOpeningOutOfEnergyBottomSheet(
  BuildContext context, {
  required String screen,
  bool playingHeader = false,
}) async {
  await TokenRefreshService.instance.refreshIfNeeded();
  if (!context.mounted) return;
  final accessToken = await TokenStorage.loadAccessToken();
  if (!context.mounted || accessToken == null) return;

  UserEnergyDto energy;
  try {
    energy = await SudaApiClient.getUserEnergy(
      accessToken: accessToken,
      screen: screen,
    );
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  final result = await showModalBottomSheet<_OutOfEnergySheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    builder: (ctx) => OutOfEnergyBottomSheet(
      initialEnergy: energy,
      accessToken: accessToken,
      screen: screen,
      playingHeader: playingHeader,
    ),
  );
  if (result != _OutOfEnergySheetResult.goHome &&
      result != _OutOfEnergySheetResult.askPush) {
    return;
  }

  // Wait CTA: 먼저 Main(root)까지. 푸시 유도는 Home 도착 후에만.
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }
  if (result == _OutOfEnergySheetResult.askPush) {
    // Opening pop 애니메이션이 시작되도록 한 프레임 뒤에 pending.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PendingOutOfEnergyPushReminder.instance.request(accessToken);
    });
  }
}

/// Home(스택에 Opening 없음)에서만 pending 푸시 유도 시트를 소비·노출.
Future<void> presentOutOfEnergyPushReminderIfPending(
  BuildContext context,
) async {
  if (!PendingOutOfEnergyPushReminder.instance.hasPending) return;
  if (!context.mounted) return;

  final accessToken = PendingOutOfEnergyPushReminder.instance.take();
  if (accessToken == null) return;
  if (!context.mounted) {
    // 컨텍스트가 죽었으면 pending 복구해 다음 기회에 띄운다.
    PendingOutOfEnergyPushReminder.instance.request(accessToken);
    return;
  }

  final notify = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    useRootNavigator: true,
    builder: (ctx) => const OutOfEnergyPushReminderSheet(),
  );
  if (!context.mounted) return;
  if (notify == true) {
    await openPushAgreementThenHome(context, accessToken);
  }
}

/// Wait 후 푸시 미허용 시 — 홈 위 하단 시트.
class OutOfEnergyPushReminderSheet extends StatelessWidget {
  const OutOfEnergyPushReminderSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(top: media.size.height * 0.36),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: _energySheetRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.30),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16 + bottom),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/icons/energy_notification_bell.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.outOfEnergyPushReminderTitle,
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ctaPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.outOfEnergyNotifyMe,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.outOfEnergyMaybeLater,
                          style: theme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SweepBorderPainter(
                      gradient: _energySheetBorderGradient,
                      borderRadius: _energySheetRadius,
                      strokeWidth: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openPushAgreementThenHome(
  BuildContext context,
  String accessToken,
) async {
  UserDto? user;
  try {
    user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
  } catch (_) {}
  if (!context.mounted) return;
  await Navigator.of(context).push<bool>(
    SubScreenRoute<bool>(
      page: PushAgreementScreen(
        user: user,
        autoEnableOnOpen: true,
      ),
    ),
  );
  if (!context.mounted) return;
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class OutOfEnergyBottomSheet extends StatefulWidget {
  final UserEnergyDto initialEnergy;
  final String accessToken;
  final String screen;
  final bool playingHeader;

  const OutOfEnergyBottomSheet({
    super.key,
    required this.initialEnergy,
    required this.accessToken,
    required this.screen,
    this.playingHeader = false,
  });

  @override
  State<OutOfEnergyBottomSheet> createState() => _OutOfEnergyBottomSheetState();
}

class _OutOfEnergyBottomSheetState extends State<OutOfEnergyBottomSheet> {
  late UserEnergyDto _energy;
  _OutOfEnergyCard _expanded = _OutOfEnergyCard.premium;
  String? _chatPassPrice;
  bool _buying = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _energy = widget.initialEnergy;
    if (_energy.isSubscribedActiveAt(DateTime.now().toUtc())) {
      _expanded = _OutOfEnergyCard.chatPass;
    }
    unawaited(_loadPrice());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _loadPrice() async {
    if (!_energy.showUnlimitedPurchase) return;
    const id = IapPurchaseService.productUnlimited10Min;
    Future<String?> read() async {
      await IapPurchaseService.instance.prefetchAndCachePrices({id});
      return IapPurchaseService.instance.cachedFormattedPrice(id);
    }

    var price = await read();
    // 스토어 초기화 직후 빈 응답이 올 수 있어 한 번 더 조회.
    if ((price == null || price.isEmpty) && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      price = await read();
    }
    if (!mounted) return;
    if (price != null && price.isNotEmpty) {
      setState(() => _chatPassPrice = price);
    }
  }

  String _chatPassCtaLabel(AppLocalizations l10n) {
    final price = _chatPassPrice;
    if (price != null && price.isNotEmpty) {
      return l10n.outOfEnergyBuyAndStart(price);
    }
    // 가격 미수신 시 "· —" 대신 문구만.
    return l10n.outOfEnergyBuyAndStart('').replaceFirst(RegExp(r'\s*·\s*$'), '');
  }

  String _mmss() {
    final last = _energy.lastAutoChargedAt;
    if (last == null) return '00:00';
    final next = last.toUtc().add(const Duration(minutes: 30));
    final remain = next.difference(DateTime.now().toUtc());
    if (remain.inSeconds <= 0) return '00:00';
    final m = remain.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remain.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _showPremium =>
      !_energy.isSubscribedActiveAt(DateTime.now().toUtc());

  bool get _showChatPass => _energy.showUnlimitedPurchase;

  Future<void> _onPremium() async {
    final subscribed = await PaywallScreen.push<bool>(
      context,
      screen: PaywallImpressionScreen.energyPopup(widget.screen),
    );
    if (!mounted) return;
    if (subscribed == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onBuyChatPass() async {
    if (_buying || IapPurchaseService.instance.isBusy) return;
    if (IapPurchaseService.instance.isProductPurchaseBlocked(
      IapPurchaseService.productUnlimited10Min,
    )) {
      return;
    }
    setState(() => _buying = true);
    final offerSessionId = _energy.offerSessionId;
    if (offerSessionId.isNotEmpty) {
      unawaited(
        SudaApiClient.impressProduct(
          accessToken: widget.accessToken,
          offerSessionId: offerSessionId,
          productId: IapPurchaseService.productUnlimited10Min,
        ),
      );
    }
    final result = await IapPurchaseService.instance.purchaseInApp(
      productId: IapPurchaseService.productUnlimited10Min,
      consumable: true,
      accessToken: widget.accessToken,
      offerSessionId: offerSessionId.isNotEmpty ? offerSessionId : null,
    );
    if (!mounted) return;
    setState(() => _buying = false);

    if (result.isProcessing) return;
    if (result.pendingApproval) {
      DefaultToast.show(
        context,
        AppLocalizations.of(context)!.energyPurchasePendingApproval,
      );
      return;
    }
    if (!result.isSuccess) {
      if (result.outcome == IapPurchaseOutcome.verifyFailed) {
        DefaultToast.show(
          context,
          AppLocalizations.of(context)!.energyPurchaseNotCompleted,
          isError: true,
        );
      }
      return;
    }
    IapPurchaseService.instance.markSuccessUiPresented();
    UserEnergyDto? refreshed;
    try {
      refreshed = await SudaApiClient.getUserEnergy(
        accessToken: widget.accessToken,
        screen: widget.screen,
      );
    } catch (_) {}
    EnergyRefreshBus.instance.notify(refreshed);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _isPushAgreed() async {
    try {
      final user = await SudaApiClient.getCurrentUser(
        accessToken: widget.accessToken,
      );
      final metas = user.metaInfo;
      if (metas == null) return false;
      for (final m in metas) {
        if (m.key == 'PUSH_AGREEMENT' && m.value == 'Y') return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _onWait() async {
    final agreed = await _isPushAgreed();
    if (!mounted) return;
    Navigator.of(context).pop(
      agreed
          ? _OutOfEnergySheetResult.goHome
          : _OutOfEnergySheetResult.askPush,
    );
  }

  void _toggle(_OutOfEnergyCard card) {
    if (_expanded == card) return;
    setState(() => _expanded = card);
    if (card == _OutOfEnergyCard.chatPass &&
        (_chatPassPrice == null || _chatPassPrice!.isEmpty)) {
      unawaited(_loadPrice());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;
    // 피그마: 시트 top이 더 아래(중하단).
    final topInset =
        media.size.height * (widget.playingHeader ? 0.30 : 0.36);

    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: _energySheetRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.30),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottom),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.playingHeader) ...[
                        // Betty + H2 타이틀 · 안내 18 — 모두 가운데
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/icons/roleplay_energy_happy.png',
                                    width: 56,
                                    height: 56,
                                  ),
                                  const SizedBox(width: 12),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          (constraints.maxWidth - 68).clamp(
                                        0,
                                        constraints.maxWidth,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.outOfEnergyPlayingTitle,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(color: Colors.white) ??
                                          const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.outOfEnergyPlayingSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.35,
                                  ) ??
                              TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 18,
                                height: 1.35,
                              ),
                        ),
                      ] else ...[
                        Text(
                          l10n.outOfEnergyTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.outOfEnergySubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_showPremium) ...[
                        _AccordionCard(
                          expanded: _expanded == _OutOfEnergyCard.premium,
                          onHeaderTap: () =>
                              _toggle(_OutOfEnergyCard.premium),
                          variant: _CardVariant.premium,
                          title: l10n.energyGoPremiumTitle,
                          badge: l10n.outOfEnergyRecommended,
                          badgeColor: const Color(0xFF9A6BFF),
                          expandedChild: _PremiumExpanded(
                            l10n: l10n,
                            trialEligible: !_energy.hasSubscriptionEver,
                            onCta: () => unawaited(_onPremium()),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_showChatPass) ...[
                        _AccordionCard(
                          expanded: _expanded == _OutOfEnergyCard.chatPass,
                          onHeaderTap: () =>
                              _toggle(_OutOfEnergyCard.chatPass),
                          variant: _CardVariant.chatPass,
                          title: l10n.outOfEnergyChatPassTitle,
                          badge: l10n.outOfEnergyPayOnce,
                          badgeColor: const Color(0xFF0CABA8),
                          expandedChild: _ChatPassExpanded(
                            l10n: l10n,
                            ctaLabel: _chatPassCtaLabel(l10n),
                            busy: _buying,
                            onCta: () => unawaited(_onBuyChatPass()),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _AccordionCard(
                        expanded: _expanded == _OutOfEnergyCard.wait,
                        onHeaderTap: () => _toggle(_OutOfEnergyCard.wait),
                        variant: _CardVariant.wait,
                        title: l10n.outOfEnergyWaitTitle,
                        badge: l10n.outOfEnergyFree,
                        badgeColor: const Color(0xFF6B6B6B),
                        expandedChild: _WaitExpanded(
                          l10n: l10n,
                          mmss: _mmss(),
                          onCta: () => unawaited(_onWait()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.outOfEnergyClose,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SweepBorderPainter(
                      gradient: _energySheetBorderGradient,
                      borderRadius: _energySheetRadius,
                      strokeWidth: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CardVariant { premium, chatPass, wait }

class _AccordionCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onHeaderTap;
  final _CardVariant variant;
  final String title;
  final String badge;
  final Color badgeColor;
  final Widget expandedChild;

  const _AccordionCard({
    required this.expanded,
    required this.onHeaderTap,
    required this.variant,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.expandedChild,
  });

  @override
  Widget build(BuildContext context) {
    const cardRadius = 24.0;
    final radius = BorderRadius.circular(cardRadius);
    final theme = Theme.of(context).textTheme;
    // 세 카드 공통: H3 타이틀 + 여백 (Premium과 동일).
    final titleStyle = theme.headlineSmall?.copyWith(color: Colors.white) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        );
    // 펼침 때만 타이틀 위 여백. 접힘에선 상하 동일해 세로 중앙.
    final topPad = expanded ? 22.0 : 16.0;
    final bottomPad = expanded ? 14.0 : 16.0;
    const leftPad = 22.0;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onHeaderTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(leftPad, topPad, 16, bottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: titleStyle),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: expandedChild,
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );

    return switch (variant) {
      _CardVariant.premium => _PremiumGlassCard(radius: radius, child: content),
      _CardVariant.chatPass => _TintedGlassCard(
          radius: radius,
          fill: const Color(0xFF0CABA8),
          fillOpacity: 0.28,
          borderGradient: _chatPassBorderGradient,
          child: content,
        ),
      _CardVariant.wait => _TintedGlassCard(
          radius: radius,
          fill: const Color(0xFF2A2A2A),
          fillOpacity: 0.55,
          borderGradient: _waitBorderGradient,
          child: content,
        ),
    };
  }
}

/// 피그마 구독/패스 카드 drop shadow 2종.
const _cardDropShadows = <BoxShadow>[
  BoxShadow(
    color: Color(0x26000000), // #000 15%
    offset: Offset(-11.15, -10.39),
    blurRadius: 48,
    spreadRadius: -12,
  ),
  BoxShadow(
    color: Color(0x26000000),
    offset: Offset(-1.86, -1.73),
    blurRadius: 12,
    spreadRadius: -8,
  ),
];

/// ChatPass: 골을 완전 투명이 아닌 soft floor로.
const _chatPassBorderGradient = SweepGradient(
  startAngle: 1.5707963267948966,
  colors: [
    Color(0xB300FFFA),
    Color(0xB300FFFA),
    Color(0x1A80D7CF), // ~10% floor
    Color(0xFF80D7CF),
    Color(0x1A80D7CF),
    Color(0xB300FFFA),
  ],
  stops: [0.0, 0.12, 0.37, 0.62, 0.87, 1.0],
);

/// 피그마 Premium: fill `#8A38F5` 40% 단색 + 각도형(Sweep) 1px stroke 보더.
/// (예전 inset+전체 gradient 트릭은 반투명 fill에 각도형이 면 전체로 비침)
class _PremiumGlassCard extends StatelessWidget {
  final BorderRadius radius;
  final Widget child;

  const _PremiumGlassCard({required this.radius, required this.child});

  static const _borderGradient = SweepGradient(
    startAngle: 1.5707963267948966,
    colors: [
      Color(0xCCD538F5),
      Color(0xCCD538F5),
      Color(0x1A8A38F5), // ~10% floor
      Color(0xFF8A38F5),
      Color(0x1A8A38F5),
      Color(0xCCD538F5),
    ],
    stops: [0.0, 0.12, 0.37, 0.62, 0.87, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _cardDropShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: const Color(0xFF8A38F5).withValues(alpha: 0.40),
                ),
              ),
            ),
            _InnerGlow(radius: radius, child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SweepBorderPainter(
                    gradient: _borderGradient,
                    borderRadius: radius,
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SweepBorderPainter extends CustomPainter {
  final Gradient gradient;
  final BorderRadius borderRadius;
  final double strokeWidth;

  const _SweepBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rrect = borderRadius.toRRect(Offset.zero & size).deflate(half);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(rrect.outerRect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _TintedGlassCard extends StatelessWidget {
  final BorderRadius radius;
  final Color fill;
  final double fillOpacity;
  final SweepGradient borderGradient;
  final Widget child;

  const _TintedGlassCard({
    required this.radius,
    required this.fill,
    required this.fillOpacity,
    required this.borderGradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Premium과 동일: drop shadow + fill blur + Sweep 1px stroke.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _cardDropShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: fill.withValues(alpha: fillOpacity),
                ),
              ),
            ),
            _InnerGlow(radius: radius, child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SweepBorderPainter(
                    gradient: borderGradient,
                    borderRadius: radius,
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 피그마 inner shadow(#FFF 9%) 근사 — 좌상단 하이라이트.
class _InnerGlow extends StatelessWidget {
  final BorderRadius radius;
  final Widget child;

  const _InnerGlow({required this.radius, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: const Alignment(-0.95, -0.95),
                  end: const Alignment(0.35, 0.35),
                  colors: [
                    Colors.white.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumExpanded extends StatelessWidget {
  final AppLocalizations l10n;
  final bool trialEligible;
  final VoidCallback onCta;

  const _PremiumExpanded({
    required this.l10n,
    required this.trialEligible,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    // 왕관은 Stack 오버레이 — Row 높이에 묶이지 않아 혜택↔CTA 여백이 왕관 크기에 안 끌려감.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BenefitLine(text: l10n.outOfEnergyPremiumBenefitEnergy),
                  const SizedBox(height: 8),
                  _BenefitLine(text: l10n.outOfEnergyPremiumBenefitFeedback),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SheetCtaButton(
              label: trialEligible
                  ? l10n.outOfEnergyTry7DaysFree
                  : l10n.outOfEnergyExplorePremium,
              color: const Color(0xFF8A38F5),
              onPressed: onCta,
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: -24,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/icons/energy_premium_crown.png',
              width: 92,
              height: 92,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatPassExpanded extends StatelessWidget {
  final AppLocalizations l10n;
  final String ctaLabel;
  final bool busy;
  final VoidCallback onCta;

  const _ChatPassExpanded({
    required this.l10n,
    required this.ctaLabel,
    required this.busy,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    // 피그마(이미지2): 뱃지는 헤더, 번개는 Premium 왕관처럼 본문 우측 오버레이.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 72),
              child: _BenefitLine(text: l10n.outOfEnergyChatPassDesc),
            ),
            const SizedBox(height: 36),
            _SheetCtaButton(
              label: ctaLabel,
              color: const Color(0xFF0CABA8),
              onPressed: busy ? null : onCta,
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: -4,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/icons/energy_unlimited_timer.png',
              width: 64,
              height: 64,
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitExpanded extends StatelessWidget {
  final AppLocalizations l10n;
  final String mmss;
  final VoidCallback onCta;

  const _WaitExpanded({
    required this.l10n,
    required this.mmss,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final template = l10n.outOfEnergyNextRecharge;
    final parts = template.split('@@TIME@@');
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          height: 1.35,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.35,
        );
    // Premium과 동일: 본문 우측 아이콘 오버레이 + bodySmall 14.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 72),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: _MintCheckIcon(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(text: parts.first),
                          TextSpan(
                            text: mmss,
                            style: const TextStyle(
                              color: _pink,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (parts.length > 1) TextSpan(text: parts[1]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            _SheetCtaButton(
              label: l10n.outOfEnergyComeBackLater,
              color: const Color(0xFF3A3A3A),
              onPressed: onCta,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.outOfEnergyReturnHomeHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                  ) ??
                  TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: -4,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/icons/energy_recharge_hourglass.png',
              width: 64,
              height: 64,
            ),
          ),
        ),
      ],
    );
  }
}

/// 공용 `check_mint.svg` — 원 `#0CABA8`, 체크 흰색.
class _MintCheckIcon extends StatelessWidget {
  const _MintCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/icons/check_mint.svg',
      width: 18,
      height: 18,
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final String text;

  const _BenefitLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          height: 1.35,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.35,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: _MintCheckIcon(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: style),
        ),
      ],
    );
  }
}

class _SheetCtaButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _SheetCtaButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
