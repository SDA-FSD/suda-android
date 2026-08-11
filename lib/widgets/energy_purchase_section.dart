import 'dart:async';

import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../l10n/app_localizations.dart';
import '../api/suda_api_client.dart';
import '../models/user_models.dart';
import '../screens/paywall/paywall.dart';
import '../screens/setting/push_agreement.dart';
import '../services/energy_refresh_bus.dart';
import '../services/iap_purchase_service.dart';
import '../theme/app_theme.dart';
import '../utils/default_toast.dart';
import '../utils/iap_busy_overlay.dart';
import '../utils/sub_screen_route.dart';

enum _EnergyPurchaseKind { enablePush, unlimited, capacity6, capacity7 }

/// Impression `productId`. IAP 상품이 아님.
const _enablePushFreeChargeProductId = 'enable_push_free_charge';

/// 에너지 팝업: 안내문구와 닫기 버튼 사이에 노출되는 구매·Go Premium 영역.
class EnergyPurchaseSection extends StatefulWidget {
  final String paywallScreen;
  final UserEnergyDto energy;
  final String accessToken;
  final bool labMode;
  final bool forceShowGoPremium;
  /// Lab 전용. `screen=lab`이라 실서비스 조건에 안 걸려도 슬롯을 그림.
  final bool forceShowEnablePush;
  /// `home` / `opening` / `opening_insufficient` 일 때만 Enable Notifications 슬롯 허용.
  final bool allowEnablePushOffer;
  /// 결제 성공 후 에너지 detail 재조회. 반환 DTO로 섹션·부모 상태를 맞춘다.
  final Future<UserEnergyDto?> Function()? onRefetchEnergy;

  const EnergyPurchaseSection({
    super.key,
    required this.energy,
    required this.accessToken,
    required this.paywallScreen,
    this.labMode = false,
    this.forceShowGoPremium = false,
    this.forceShowEnablePush = false,
    this.allowEnablePushOffer = false,
    this.onRefetchEnergy,
  });

  @override
  State<EnergyPurchaseSection> createState() => _EnergyPurchaseSectionState();
}

class _EnergyPurchaseSectionState extends State<EnergyPurchaseSection> {
  static const _buttonGap = 10.0;
  static const _themeTintIdle = 0.05;
  static const _themeTintBusy = 0.30;
  static const _removeDuration = Duration(milliseconds: 1000);

  late UserEnergyDto _energy;
  final Map<String, String> _prices = {};
  final Set<_EnergyPurchaseKind> _hiddenKinds = {};
  final Set<_EnergyPurchaseKind> _removingKinds = {};
  _EnergyPurchaseKind? _busyKind;
  double _themeTintOpacity = _themeTintIdle;
  bool _goPremiumDismissed = false;
  bool _goPremiumRemoving = false;
  /// offerSessionId+productId 단위 impression 중복 전송 방지(팝업 생명주기).
  final Set<String> _impressedTapKeys = {};

  @override
  void initState() {
    super.initState();
    _energy = widget.energy;
    unawaited(_loadPrices());
  }

  @override
  void didUpdateWidget(EnergyPurchaseSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.energy != widget.energy) {
      _energy = widget.energy;
      unawaited(_loadPrices());
    }
  }

  Future<void> _loadPrices() async {
    final ids = <String>{};
    if (_energy.showUnlimitedPurchase) {
      ids.add(IapPurchaseService.productUnlimited10Min);
    }
    if (_energy.showCapacity6Purchase) {
      ids.add(IapPurchaseService.productCapacity6);
    }
    if (_energy.showCapacity7Purchase) {
      ids.add(IapPurchaseService.productCapacity7);
    }
    if (ids.isEmpty) return;

    if (!widget.labMode) {
      await IapPurchaseService.instance.prefetchAndCachePrices(ids);
    }
    if (!mounted) return;

    final next = <String, String>{};
    for (final id in ids) {
      final cached =
          await IapPurchaseService.instance.cachedFormattedPrice(id);
      if (cached != null && cached.isNotEmpty) {
        next[id] = cached;
      }
    }
    if (!mounted) return;
    setState(() => _prices.addAll(next));
  }

  bool get _shouldShowGoPremiumSlot {
    if (_goPremiumDismissed && !_goPremiumRemoving) return false;
    if (_goPremiumRemoving) return true;
    if (widget.forceShowGoPremium) return true;
    return _energy.subscribedYn != 'Y';
  }

  bool get _shouldShowEnablePushSlot {
    if (_hiddenKinds.contains(_EnergyPurchaseKind.enablePush)) return false;
    if (widget.forceShowEnablePush) return true;
    return widget.allowEnablePushOffer && _energy.showEnablePushFreeCharge;
  }

  List<_EnergyPurchaseKind> get _visibleKinds {
    final list = <_EnergyPurchaseKind>[];
    if (_shouldShowEnablePushSlot) {
      list.add(_EnergyPurchaseKind.enablePush);
    }
    if (_energy.showUnlimitedPurchase &&
        !_hiddenKinds.contains(_EnergyPurchaseKind.unlimited)) {
      list.add(_EnergyPurchaseKind.unlimited);
    }
    if (_energy.showCapacity6Purchase &&
        !_hiddenKinds.contains(_EnergyPurchaseKind.capacity6)) {
      list.add(_EnergyPurchaseKind.capacity6);
    }
    if (_energy.showCapacity7Purchase &&
        !_hiddenKinds.contains(_EnergyPurchaseKind.capacity7)) {
      list.add(_EnergyPurchaseKind.capacity7);
    }
    return list;
  }

  String _productId(_EnergyPurchaseKind kind) {
    switch (kind) {
      case _EnergyPurchaseKind.enablePush:
        return _enablePushFreeChargeProductId;
      case _EnergyPurchaseKind.unlimited:
        return IapPurchaseService.productUnlimited10Min;
      case _EnergyPurchaseKind.capacity6:
        return IapPurchaseService.productCapacity6;
      case _EnergyPurchaseKind.capacity7:
        return IapPurchaseService.productCapacity7;
    }
  }

  bool _isConsumable(_EnergyPurchaseKind kind) =>
      kind == _EnergyPurchaseKind.unlimited;

  Future<void> _impressIfNeeded(String productId) async {
    final offerSessionId = _energy.offerSessionId;
    if (offerSessionId.isEmpty) return;
    final tapKey = '$offerSessionId::$productId';
    if (_impressedTapKeys.contains(tapKey)) return;
    _impressedTapKeys.add(tapKey);
    unawaited(() async {
      try {
        await SudaApiClient.impressProduct(
          accessToken: widget.accessToken,
          offerSessionId: offerSessionId,
          productId: productId,
        );
      } catch (_) {
        // impression 실패는 UX에 영향 없음(미수집 방지).
      }
    }());
  }

  Future<void> _onEnablePushTap() async {
    if (widget.labMode) return;
    if (_busyKind != null || IapPurchaseService.instance.isBusy) return;
    if (widget.accessToken.isEmpty) return;

    unawaited(_impressIfNeeded(_enablePushFreeChargeProductId));

    setState(() {
      _busyKind = _EnergyPurchaseKind.enablePush;
      _themeTintOpacity = _themeTintBusy;
    });

    UserDto? user;
    try {
      user = await SudaApiClient.getCurrentUser(
        accessToken: widget.accessToken,
      );
    } catch (e, st) {
      debugPrint('[DEBUG] enable push GET /v1/users failed: $e\n$st');
    }
    if (!mounted) return;

    final completed = await Navigator.of(context).push<bool>(
      SubScreenRoute<bool>(
        page: PushAgreementScreen(user: user),
      ),
    );
    if (!mounted) return;

    if (completed != true) {
      setState(() {
        _themeTintOpacity = _themeTintIdle;
        _busyKind = null;
      });
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    DefaultToast.show(context, l10n.energyEnablePushCompleted);

    setState(() => _removingKinds.add(_EnergyPurchaseKind.enablePush));
    await Future<void>.delayed(_removeDuration);
    if (!mounted) return;

    setState(() {
      _removingKinds.remove(_EnergyPurchaseKind.enablePush);
      _hiddenKinds.add(_EnergyPurchaseKind.enablePush);
      _busyKind = null;
      _themeTintOpacity = _themeTintIdle;
    });

    final refreshed = await widget.onRefetchEnergy?.call();
    if (!mounted) return;
    if (refreshed != null) {
      setState(() => _energy = refreshed);
    }
    EnergyRefreshBus.instance.notify(refreshed);
  }

  Future<void> _onPurchaseTap(_EnergyPurchaseKind kind) async {
    if (widget.labMode) return;
    if (_busyKind != null || IapPurchaseService.instance.isBusy) return;
    if (widget.accessToken.isEmpty) return;

    final offerSessionId = _energy.offerSessionId;
    final productId = _productId(kind);
    unawaited(_impressIfNeeded(productId));

    setState(() {
      _busyKind = kind;
      _themeTintOpacity = _themeTintBusy;
    });

    final result = await IapBusyOverlay.run(
      context,
      () => IapPurchaseService.instance.purchaseInApp(
        productId: productId,
        consumable: _isConsumable(kind),
        accessToken: widget.accessToken,
        // 탭 시점 세션 고정(스토어 체류 중 detail refetch로 id가 바뀌어도 유지).
        offerSessionId:
            offerSessionId.isNotEmpty ? offerSessionId : null,
      ),
    );
    if (!mounted) return;

    if (!result.isSuccess) {
      if (result.outcome == IapPurchaseOutcome.verifyFailed) {
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(
          context,
          l10n.energyPurchaseNotCompleted,
          isError: true,
        );
      }
      setState(() {
        _themeTintOpacity = _themeTintIdle;
        _busyKind = null;
      });
      return;
    }

    if (result.pendingApproval) {
      final l10n = AppLocalizations.of(context)!;
      DefaultToast.show(context, l10n.energyPurchasePendingApproval);
    }

    setState(() => _removingKinds.add(kind));
    await Future<void>.delayed(_removeDuration);
    if (!mounted) return;

    setState(() {
      _removingKinds.remove(kind);
      _hiddenKinds.add(kind);
      _busyKind = null;
      _themeTintOpacity = _themeTintIdle;
    });

    final refreshed = await widget.onRefetchEnergy?.call();
    if (!mounted) return;
    if (refreshed != null) {
      setState(() => _energy = refreshed);
    }
    EnergyRefreshBus.instance.notify(refreshed);
  }

  Future<void> _onGoPremiumTap() async {
    if (_busyKind != null || _goPremiumRemoving || _goPremiumDismissed) return;
    final subscribed = await PaywallScreen.push<bool>(
      context,
      screen: widget.paywallScreen,
    );
    if (!mounted || subscribed != true) return;

    setState(() => _goPremiumRemoving = true);
    await Future<void>.delayed(_removeDuration);
    if (!mounted) return;

    setState(() {
      _goPremiumRemoving = false;
      _goPremiumDismissed = true;
    });

    final refreshed = await widget.onRefetchEnergy?.call();
    if (!mounted) return;
    if (refreshed != null) {
      setState(() => _energy = refreshed);
    }
    EnergyRefreshBus.instance.notify(refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final kinds = _visibleKinds;
    final showPremium = _shouldShowGoPremiumSlot;
    if (kinds.isEmpty && !showPremium) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final isPt = Localizations.localeOf(context).languageCode == 'pt';
    final children = <Widget>[];

    for (var i = 0; i < kinds.length; i++) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: _buttonGap));
      }
      final kind = kinds[i];
      final productId = _productId(kind);
      final isEnablePush = kind == _EnergyPurchaseKind.enablePush;
      var price = isEnablePush ? l10n.energyEnablePushPrice : _prices[productId];
      if (!isEnablePush &&
          widget.labMode &&
          (price == null || price.isEmpty)) {
        price = 'R\$2,99';
      }
      children.add(
        _AnimatedPurchaseSlot(
          removing: _removingKinds.contains(kind),
          child: _PurchaseProductButton(
            kind: kind,
            price: price,
            showPtStrike: isPt && kind == _EnergyPurchaseKind.unlimited,
            title: isEnablePush
                ? l10n.energyEnablePushTitle
                : kind == _EnergyPurchaseKind.unlimited
                    ? l10n.energyPurchaseUnlimitedTitle
                    : l10n.energyPurchaseCapacityTitle,
            subtitle: isEnablePush
                ? l10n.energyEnablePushSubtitle
                : kind == _EnergyPurchaseKind.unlimited
                    ? l10n.energyPurchaseUnlimitedSubtitle
                    : l10n.energyPurchaseCapacitySubtitle,
            offerBadge:
                isEnablePush ? l10n.energyEnablePushOfferBadge : null,
            themeTintOpacity:
                _busyKind == kind ? _themeTintOpacity : _themeTintIdle,
            enabled: _busyKind == null,
            onTap: () => unawaited(
              isEnablePush ? _onEnablePushTap() : _onPurchaseTap(kind),
            ),
          ),
        ),
      );
    }

    if (showPremium) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: _buttonGap));
      }
      children.add(
        _AnimatedPurchaseSlot(
          removing: _goPremiumRemoving,
          child: _GoPremiumButton(
            title: l10n.energyGoPremiumTitle,
            exploreLabel: l10n.energyGoPremiumExplore,
            enabled: _busyKind == null && !_goPremiumRemoving,
            onTap: () => unawaited(_onGoPremiumTap()),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class _AnimatedPurchaseSlot extends StatelessWidget {
  final bool removing;
  final Widget child;

  const _AnimatedPurchaseSlot({
    required this.removing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1000),
        opacity: removing ? 0 : 1,
        child: removing
            ? const SizedBox(width: double.infinity, height: 0)
            : child,
      ),
    );
  }
}

class _PurchaseProductButton extends StatelessWidget {
  static const _radius = 20.0;
  static const _innerRadius = 19.0;
  static const _canvasBase = Color(0xFF121212);

  final _EnergyPurchaseKind kind;
  final String? price;
  final bool showPtStrike;
  final String title;
  final String subtitle;
  final String? offerBadge;
  /// 테마색 오버레이 알파. 평소 0.05, 결제 진행 중 0.30.
  final double themeTintOpacity;
  final bool enabled;
  final VoidCallback onTap;

  const _PurchaseProductButton({
    required this.kind,
    required this.price,
    required this.showPtStrike,
    required this.title,
    required this.subtitle,
    this.offerBadge,
    required this.themeTintOpacity,
    required this.enabled,
    required this.onTap,
  });

  bool get _isUnlimited => kind == _EnergyPurchaseKind.unlimited;
  bool get _isEnablePush => kind == _EnergyPurchaseKind.enablePush;

  String get _iconAsset {
    switch (kind) {
      case _EnergyPurchaseKind.enablePush:
        return 'assets/images/icons/gnb_alarm.png';
      case _EnergyPurchaseKind.unlimited:
        return 'assets/images/icons/product_unlimited_10min.png';
      case _EnergyPurchaseKind.capacity6:
        return 'assets/images/icons/product_max_energy_6.png';
      case _EnergyPurchaseKind.capacity7:
        return 'assets/images/icons/product_max_energy_7.png';
    }
  }

  Color get _themeTint {
    if (_isEnablePush) return const Color(0xFFFF0044);
    if (_isUnlimited) return const Color(0xFF009628);
    return const Color(0xFFFFB700);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final List<Color> borderColors;
    final List<Color> priceBg;
    final Color priceColor;
    if (_isEnablePush) {
      borderColors = const [Color(0xFFFF0044), Color(0xFFFF00A6)];
      priceBg = const [Color(0xFFFF0044), Color(0xFFFF00A6)];
      priceColor = Colors.white;
    } else if (_isUnlimited) {
      borderColors = const [Color(0xFF009628), Color(0xFF37D27A)];
      priceBg = const [Color(0xFF3DAC47), Color(0xFF79CD83)];
      priceColor = Colors.white;
    } else {
      borderColors = const [Color(0xFFF9DF85), Color(0xFFEE9B00)];
      priceBg = const [Color(0xFFF9B93F), Color(0xFFFBDB81)];
      priceColor = const Color(0xFF613D0D);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: _isEnablePush ? 96 : 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_radius),
                    gradient: LinearGradient(colors: borderColors),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_innerRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: _canvasBase),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            color: _themeTint.withValues(
                              alpha: themeTintOpacity,
                            ),
                          ),
                          Padding(
                            padding: _isEnablePush
                                ? const EdgeInsets.fromLTRB(10, 34, 10, 10)
                                : const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Image.asset(_iconAsset, width: 30, height: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PurchaseTitleLine(
                                        text: title,
                                        style: theme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontVariations: const [
                                            FontVariation('wght', 600),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: theme.labelSmall?.copyWith(
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (offerBadge != null && offerBadge!.isNotEmpty)
                Positioned(
                  top: 6,
                  left: 8,
                  child: Container(
                    height: 25,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                    child: Text(
                      offerBadge!,
                      style: theme.labelMini.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [
                          FontVariation('wght', 700),
                        ],
                      ),
                    ),
                  ),
                ),
              if (price != null && price!.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showPtStrike)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            'R\$5,99',
                            style: theme.labelSmall?.copyWith(
                              color: const Color(0xFF8C8C8C),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFF8C8C8C),
                            ),
                          ),
                        ),
                      Container(
                        height: 25,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: priceBg),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(_radius),
                            bottomLeft: Radius.circular(_radius),
                          ),
                        ),
                        child: Text(
                          price!,
                          style: theme.bodySmall?.copyWith(
                            color: priceColor,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [
                              FontVariation('wght', 600),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseTitleLine extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _PurchaseTitleLine({
    required this.text,
    required this.style,
  });

  bool _shouldMarquee({
    required String text,
    required TextStyle? style,
    required double maxWidth,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldMarquee = _shouldMarquee(
          text: text,
          style: style,
          maxWidth: constraints.maxWidth,
          textDirection: Directionality.of(context),
        );
        return SizedBox(
          height: 20,
          width: constraints.maxWidth,
          child: shouldMarquee
              ? Marquee(
                  text: text,
                  style: style,
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  blankSpace: 20.0,
                  velocity: 30.0,
                  pauseAfterRound: const Duration(seconds: 2),
                  startPadding: 0,
                  accelerationDuration: const Duration(seconds: 1),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: const Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: style,
                  ),
                ),
        );
      },
    );
  }
}

class _GoPremiumButton extends StatelessWidget {
  static const _radius = 20.0;
  static const _innerRadius = 19.0;

  final String title;
  final String exploreLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _GoPremiumButton({
    required this.title,
    required this.exploreLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              gradient: const LinearGradient(
                colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_innerRadius),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A38F5), Color(0xFF280752)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/icons/product_premium.png',
                          width: 30,
                          height: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [
                              FontVariation('wght', 600),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.36),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0.10),
                            ],
                          ),
                        ),
                        child: Text(
                          exploreLabel,
                          style: theme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
