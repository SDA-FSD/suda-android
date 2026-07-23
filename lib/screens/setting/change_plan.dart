import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/iap_purchase_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/default_popup.dart';

enum _PlanKind { monthly, yearly }

/// Change Plan Sub Screen (결제/플랜 변경은 Phase 5; CTA는 확인 팝업까지).
class ChangePlanScreen extends StatefulWidget {
  const ChangePlanScreen({super.key});

  @override
  State<ChangePlanScreen> createState() => _ChangePlanScreenState();
}

class _ChangePlanScreenState extends State<ChangePlanScreen> {
  static const _accent = Color(0xFF0CABA8);
  static const _priceMint = Color(0xFF80D7CF);
  static const _cardBg = Color(0xFF353535);
  static const _cardHeight = 103.0;
  static const _cardHPad = 16.0;
  static const _radioSize = 24.0;

  /// 플랜명: ChironHeiHK 20
  static const _planNameStyle = TextStyle(
    fontFamily: 'ChironHeiHK',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.4,
    height: 1.2,
    color: Colors.white,
  );

  /// 부제·갱신일: ChironHeiHK 14
  static const _planCaptionStyle = TextStyle(
    fontFamily: 'ChironHeiHK',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: -0.4,
    height: 1.2,
    color: Colors.white70,
  );

  /// 우측 주 가격: H3 (`headlineSmall`)
  TextStyle get _priceH3Style =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white);

  /// 연간 부 가격: ChironHeiHK 14 · `#80D7CF`
  static const _priceMintStyle = TextStyle(
    fontFamily: 'ChironHeiHK',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: -0.4,
    height: 1.2,
    color: _priceMint,
  );

  bool _loading = true;
  bool _loadFailed = false;
  UserEnergyDto? _energy;
  PremiumSubscriptionPrices? _prices;
  bool _availableSelected = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _availableSelected = false;
    });
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadFailed = true;
          _energy = null;
        });
        return;
      }
      final energy = await SudaApiClient.getUserEnergy(accessToken: token);
      final prices =
          await IapPurchaseService.instance.loadPremiumSubscriptionPrices();
      if (!mounted) return;
      final basePlanId = energy.subscriptionBasePlanId;
      final known = basePlanId == IapPurchaseService.basePlanMonthly ||
          basePlanId == IapPurchaseService.basePlanYearly;
      setState(() {
        _energy = energy;
        _prices = prices;
        _loading = false;
        _loadFailed = !known;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _energy = null;
      });
    }
  }

  _PlanKind? get _currentPlan {
    final id = _energy?.subscriptionBasePlanId;
    if (id == IapPurchaseService.basePlanMonthly) return _PlanKind.monthly;
    if (id == IapPurchaseService.basePlanYearly) return _PlanKind.yearly;
    return null;
  }

  _PlanKind? get _availablePlan {
    final current = _currentPlan;
    if (current == null) return null;
    return current == _PlanKind.monthly ? _PlanKind.yearly : _PlanKind.monthly;
  }

  String _formatRenewDate(DateTime utc, String languageCode) {
    final local = utc.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    if (languageCode == 'pt') return '$d/$m/$y';
    return '$y/$m/$d';
  }

  String _planTitle(AppLocalizations l10n, _PlanKind plan) {
    return plan == _PlanKind.yearly
        ? l10n.paywallAnnualPlanTitle
        : l10n.paywallMonthlyPlanTitle;
  }

  String _planSubtitle(AppLocalizations l10n, _PlanKind plan) {
    return plan == _PlanKind.yearly
        ? l10n.paywallAnnualPlanSubtitle
        : l10n.paywallMonthlyPlanSubtitle;
  }

  String _monthlyPrice(AppLocalizations l10n) {
    final v = _prices?.monthlyFormatted;
    final amount =
        (v != null && v.isNotEmpty) ? v : l10n.paywallFallbackMonthly;
    return l10n.paywallPricePerMonth(amount);
  }

  String _yearlyPriceMain(AppLocalizations l10n) {
    final v = _prices?.yearlyPerMonthFormatted;
    final amount =
        (v != null && v.isNotEmpty) ? v : l10n.paywallFallbackAnnualPerMonth;
    return l10n.paywallPricePerMonth(amount);
  }

  String _yearlyPriceSub(AppLocalizations l10n) {
    final v = _prices?.yearlyFormatted;
    final amount = (v != null && v.isNotEmpty) ? v : l10n.paywallFallbackAnnual;
    return l10n.paywallPricePerYear(amount);
  }

  String _currentPriceLabel(AppLocalizations l10n, _PlanKind plan) {
    return plan == _PlanKind.yearly
        ? _yearlyPriceMain(l10n)
        : _monthlyPrice(l10n);
  }

  void _onChangePlanTap() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    unawaited(
      DefaultPopup.show(
        context,
        titleText: l10n.changePlanConfirmTitle,
        bodyWidget: Text(
          l10n.changePlanConfirmBody,
          style: theme.bodyLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        buttons: [
          DefaultPopupButton(
            type: DefaultPopupButtonType.primary,
            label: l10n.changePlanConfirmOk,
            onPressed: () {
              // Phase 5: changeSubscription / purchase.
            },
          ),
          DefaultPopupButton(
            type: DefaultPopupButtonType.text,
            label: l10n.changePlanConfirmCancel,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return AppScaffold(
      centerTitle: l10n.changePlanTitle,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _loadFailed
              ? _buildError(l10n, theme)
              : _buildContent(l10n, theme),
    );
  }

  Widget _buildError(AppLocalizations l10n, TextTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.changePlanLoadFailed,
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => unawaited(_load()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(l10n.changePlanRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, TextTheme theme) {
    final current = _currentPlan!;
    final available = _availablePlan!;
    final expiredAt = _energy?.subscriptionExpiredAt;
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.changePlanCurrentPlan,
                  style: theme.headlineMedium?.copyWith(color: _accent),
                ),
                const SizedBox(height: 24),
                _currentPlanCard(
                  l10n: l10n,
                  plan: current,
                  renewsLabel: expiredAt == null
                      ? null
                      : l10n.changePlanRenewsOn(
                          _formatRenewDate(expiredAt, lang),
                        ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.changePlanAvailablePlans,
                  style: theme.headlineMedium?.copyWith(color: _accent),
                ),
                const SizedBox(height: 24),
                _availablePlanCard(
                  l10n: l10n,
                  plan: available,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _availableSelected ? _onChangePlanTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: const Color(0xFF4A4A4A),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white54,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(l10n.accountChangePlan),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _currentPlanCard({
    required AppLocalizations l10n,
    required _PlanKind plan,
    required String? renewsLabel,
  }) {
    return Container(
      width: double.infinity,
      height: _cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: _cardHPad),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _planTitle(l10n, plan),
                    maxLines: 1,
                    softWrap: false,
                    style: _planNameStyle,
                  ),
                ),
                if (renewsLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    renewsLabel,
                    style: _planCaptionStyle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _currentPriceLabel(l10n, plan),
            style: _priceH3Style,
          ),
        ],
      ),
    );
  }

  Widget _availablePlanCard({
    required AppLocalizations l10n,
    required _PlanKind plan,
  }) {
    final selected = _availableSelected;
    final isYearly = plan == _PlanKind.yearly;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _availableSelected = !_availableSelected),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: _cardHeight),
          padding: const EdgeInsets.symmetric(horizontal: _cardHPad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  selected
                      ? 'assets/images/icons/paywall_radio_selected.png'
                      : 'assets/images/icons/paywall_radio_unselected.png',
                  width: _radioSize,
                  height: _radioSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _planTitle(l10n, plan),
                          maxLines: 1,
                          softWrap: false,
                          style: _planNameStyle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _planSubtitle(l10n, plan),
                        style: _planCaptionStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isYearly ? _yearlyPriceMain(l10n) : _monthlyPrice(l10n),
                      style: _priceH3Style,
                    ),
                    if (isYearly) ...[
                      const SizedBox(height: 2),
                      Text(
                        _yearlyPriceSub(l10n),
                        style: _priceMintStyle,
                      ),
                    ],
                  ],
                ),
              ],
            ),
        ),
      ),
    );
  }
}
