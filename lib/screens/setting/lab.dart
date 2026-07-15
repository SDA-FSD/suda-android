import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../api/suda_api_client.dart';
import '../../config/app_config.dart';
import '../../effects/like_progress_effect.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/series_state_service.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/iap_obfuscated_account_id.dart';
import '../../widgets/main_reregistration_restricted_popup.dart'
    show
        showMainReregistrationRestrictedAuthCheckDefaultPopupForLab,
        showMainReregistrationRestrictedSignInDefaultPopupForLab;
import '../../widgets/energy_info_popup.dart' show showEnergyPopupForLab;
import '../../widgets/app_scaffold.dart';
import '../profile.dart'
    show showProfileDeleteSavedExpressionDefaultPopupForLab;
import 'announcements.dart'
    show showAnnouncementsPostNoLongerAvailableDefaultPopupForLab;
import '../roleplay/try_again.dart';
import '../first_cefr_level.dart';
import '../paywall/paywall.dart';
import '../paywall/paywall_completed.dart';

enum _LabIapKind { inapp, subs }

class _LabIapSku {
  const _LabIapSku({
    required this.key,
    required this.productId,
    required this.label,
    required this.kind,
    this.basePlanId,
    this.consumable = false,
  });

  final String key;
  final String productId;
  final String label;
  final _LabIapKind kind;
  final String? basePlanId;
  final bool consumable;
}

const List<_LabIapSku> _kLabIapSkus = [
  _LabIapSku(
    key: 'unlimited_energy_10_minute',
    productId: 'unlimited_energy_10_minute',
    label: 'Unlimited Energy 10m',
    kind: _LabIapKind.inapp,
    consumable: true,
  ),
  _LabIapSku(
    key: 'energy_capacity_6',
    productId: 'energy_capacity_6',
    label: 'Energy Capacity 6',
    kind: _LabIapKind.inapp,
  ),
  _LabIapSku(
    key: 'energy_capacity_7',
    productId: 'energy_capacity_7',
    label: 'Energy Capacity 7',
    kind: _LabIapKind.inapp,
  ),
  _LabIapSku(
    key: 'subscription_premium_monthly',
    productId: 'subscription_premium',
    label: 'Premium Monthly',
    kind: _LabIapKind.subs,
    basePlanId: 'bp-premium-monthly',
  ),
  _LabIapSku(
    key: 'subscription_premium_yearly',
    productId: 'subscription_premium',
    label: 'Premium Yearly',
    kind: _LabIapKind.subs,
    basePlanId: 'bp-premium-yearly',
  ),
];

Set<String> get _kLabIapProductIds =>
    {for (final sku in _kLabIapSkus) sku.productId};

/// Lab에서 재현 가능한 `DefaultPopup` 목록.
/// `DefaultPopup` 전환이 완료될 때마다 여기에 **한 항목씩** 추가한다.
///
/// 라벨 규칙: 괄호로 분기/sessionId를 붙이지 않는다.
final List<LabDefaultPopupOption> kLabDefaultPopupOptions = [
  LabDefaultPopupOption(
    id: 'profile_delete_saved_expression',
    label: 'Profile: Delete saved expression',
    show: showProfileDeleteSavedExpressionDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'announcements_post_no_longer_available',
    label: 'Announcements: Post no longer available',
    show: showAnnouncementsPostNoLongerAvailableDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'main_reregistration_restricted_auth_check',
    label: 'Main: Re-registration restricted — auth check',
    show: showMainReregistrationRestrictedAuthCheckDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'main_reregistration_restricted_sign_in',
    label: 'Main: Re-registration restricted — sign-in',
    show: showMainReregistrationRestrictedSignInDefaultPopupForLab,
  ),
];

class LabDefaultPopupOption {
  LabDefaultPopupOption({
    required this.id,
    required this.label,
    required this.show,
  });

  final String id;
  final String label;
  final Future<void> Function(BuildContext context) show;
}

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  bool _guarded = false;
  bool _toastIsWarning = false;
  String? _selectedLabDefaultPopupId;
  bool _energyPopupPlaying = false;
  bool _energyPopupUnlimited = false;
  final TextEditingController _energyPopupCountController =
      TextEditingController(text: '3');
  final TextEditingController _iapProductIdsController =
      TextEditingController(text: _kLabIapProductIds.join(', '));
  bool _iapBusy = false;
  String _iapLog = '';
  StreamSubscription<List<PurchaseDetails>>? _iapPurchaseSub;
  static const _longToastTestMessage = 'Test Popup, Test Toast, 가나다라마바사아자차카타파하';
  static const _stylePreviewLines = ['말해요!?', 'Talk', 'E sua vez primeiro!'];

  @override
  void dispose() {
    unawaited(_iapPurchaseSub?.cancel());
    _energyPopupCountController.dispose();
    _iapProductIdsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (kLabDefaultPopupOptions.isNotEmpty) {
      _selectedLabDefaultPopupId = kLabDefaultPopupOptions.first.id;
    }
    _iapPurchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onIapPurchaseUpdates,
      onError: (Object e, StackTrace st) {
        debugPrint('[DEBUG] Lab IAP purchaseStream error: $e\n$st');
        _appendIapLog('purchaseStream error: $e');
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guarded) return;
    _guarded = true;

    // TEMP: prd에서도 Lab 허용 (IAP Internal 테스트용). 끝나면 isPrd 제거.
    if (!AppConfig.isDev && !AppConfig.isPrd && !kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _showSelectedLabDefaultPopup() async {
    final id = _selectedLabDefaultPopupId;
    if (id == null) return;
    LabDefaultPopupOption? found;
    for (final o in kLabDefaultPopupOptions) {
      if (o.id == id) {
        found = o;
        break;
      }
    }
    if (found == null) return;
    await found.show(context);
  }

  void _showTestToast() {
    final message = 'Test Popup, Test Toast';
    DefaultToast.show(context, message, isError: _toastIsWarning);
  }

  void _showTestToastLong() {
    DefaultToast.show(context, _longToastTestMessage, isError: _toastIsWarning);
  }

  Future<void> _openFirstCefrLevelScreen() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => FirstCefrLevelScreen(
          onComplete: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  Future<void> _openPaywallScreen() async {
    if (!mounted) return;
    await PaywallScreen.push(context);
  }

  Future<void> _openPaywallCompletedScreen() async {
    if (!mounted) return;
    await PaywallCompletedScreen.push(context);
  }

  void _appendIapLog(String message) {
    final stamped = '[${DateTime.now().toIso8601String()}] $message';
    debugPrint('[DEBUG] Lab IAP: $stamped');
    if (!mounted) return;
    setState(() {
      _iapLog = _iapLog.isEmpty ? stamped : '$_iapLog\n$stamped';
    });
  }

  Set<String> _parseIapProductIds() {
    return _iapProductIdsController.text
        .split(RegExp(r'[\s,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  String _formatIapProductDetails(ProductDetails product) {
    final buf = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${product.id}')
      ..writeln('title: ${product.title}')
      ..writeln('description: ${product.description}')
      ..writeln('price: ${product.price}')
      ..writeln('rawPrice: ${product.rawPrice}')
      ..writeln('currencyCode: ${product.currencyCode}')
      ..writeln('currencySymbol: ${product.currencySymbol}');

    if (product is GooglePlayProductDetails) {
      final wrapper = product.productDetails;
      buf
        ..writeln('android.productType: ${wrapper.productType}')
        ..writeln('android.name: ${wrapper.name}')
        ..writeln('android.subscriptionIndex: ${product.subscriptionIndex}')
        ..writeln('android.offerToken: ${product.offerToken}');

      final offers = wrapper.subscriptionOfferDetails;
      if (offers != null) {
        for (var i = 0; i < offers.length; i++) {
          final offer = offers[i];
          buf
            ..writeln('android.offer[$i].basePlanId: ${offer.basePlanId}')
            ..writeln('android.offer[$i].offerId: ${offer.offerId}')
            ..writeln('android.offer[$i].offerTags: ${offer.offerTags}')
            ..writeln(
              'android.offer[$i].offerIdToken: ${offer.offerIdToken}',
            );
          for (var p = 0; p < offer.pricingPhases.length; p++) {
            final phase = offer.pricingPhases[p];
            buf
              ..writeln(
                'android.offer[$i].phase[$p].formattedPrice: '
                '${phase.formattedPrice}',
              )
              ..writeln(
                'android.offer[$i].phase[$p].billingPeriod: '
                '${phase.billingPeriod}',
              )
              ..writeln(
                'android.offer[$i].phase[$p].billingCycleCount: '
                '${phase.billingCycleCount}',
              )
              ..writeln(
                'android.offer[$i].phase[$p].priceAmountMicros: '
                '${phase.priceAmountMicros}',
              )
              ..writeln(
                'android.offer[$i].phase[$p].priceCurrencyCode: '
                '${phase.priceCurrencyCode}',
              )
              ..writeln(
                'android.offer[$i].phase[$p].recurrenceMode: '
                '${phase.recurrenceMode}',
              );
          }
        }
      }

      final oneTime = wrapper.oneTimePurchaseOfferDetails;
      if (oneTime != null) {
        buf
          ..writeln(
            'android.oneTime.formattedPrice: ${oneTime.formattedPrice}',
          )
          ..writeln(
            'android.oneTime.priceAmountMicros: ${oneTime.priceAmountMicros}',
          )
          ..writeln(
            'android.oneTime.priceCurrencyCode: ${oneTime.priceCurrencyCode}',
          );
      }
    }

    return buf.toString();
  }

  Future<void> _queryIapProductIds(Set<String> ids, {String? title}) async {
    if (ids.isEmpty) {
      _appendIapLog('No productIds to query.');
      return;
    }
    if (_iapBusy) return;

    setState(() => _iapBusy = true);
    _appendIapLog(
      '${title ?? 'Query'} start — ENV=${AppConfig.env} ids=${ids.join(',')}',
    );

    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) {
        _appendIapLog('Store not available (isAvailable=false).');
        return;
      }

      final response = await iap.queryProductDetails(ids);
      final buf = StringBuffer()
        ..writeln('requestedIds: ${ids.join(', ')}')
        ..writeln('found: ${response.productDetails.length}')
        ..writeln(
          'notFoundIDs: ${response.notFoundIDs.isEmpty ? '(none)' : response.notFoundIDs.join(', ')}',
        );
      if (response.error != null) {
        buf
          ..writeln('error.code: ${response.error!.code}')
          ..writeln('error.message: ${response.error!.message}')
          ..writeln('error.details: ${response.error!.details}');
      }
      for (final product in response.productDetails) {
        buf.write(_formatIapProductDetails(product));
      }
      _appendIapLog(buf.toString().trimRight());
    } catch (e, st) {
      debugPrint('[DEBUG] Lab IAP query failed: $e\n$st');
      _appendIapLog('Query exception: $e');
    } finally {
      if (mounted) setState(() => _iapBusy = false);
    }
  }

  Future<void> _queryIapProducts() =>
      _queryIapProductIds(_parseIapProductIds(), title: 'Query freeform');

  Future<void> _queryLabSku(_LabIapSku sku) =>
      _queryIapProductIds({sku.productId}, title: 'Query ${sku.label}');

  Future<void> _queryAllLabSkus() =>
      _queryIapProductIds(_kLabIapProductIds, title: 'Query all catalog');

  ProductDetails? _pickProductForSku(
    _LabIapSku sku,
    List<ProductDetails> products,
  ) {
    final matches = products.where((p) => p.id == sku.productId).toList();
    if (matches.isEmpty) return null;
    if (sku.kind != _LabIapKind.subs || sku.basePlanId == null) {
      return matches.first;
    }
    for (final product in matches) {
      if (product is! GooglePlayProductDetails) continue;
      final index = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) continue;
      if (offers[index].basePlanId == sku.basePlanId) {
        return product;
      }
    }
    return matches.first;
  }

  Future<void> _buyLabSku(_LabIapSku sku) async {
    if (_iapBusy) return;
    setState(() => _iapBusy = true);
    _appendIapLog(
      'Buy ${sku.label} start — productId=${sku.productId}'
      '${sku.basePlanId == null ? '' : ' basePlanId=${sku.basePlanId}'}'
      ' ENV=${AppConfig.env}',
    );

    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _appendIapLog('Buy aborted — no JWT (login required)');
        if (mounted) {
          DefaultToast.show(context, 'Login required for buy', isError: true);
        }
        return;
      }

      final user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
      if (user.id <= 0) {
        _appendIapLog('Buy aborted — invalid user.id=${user.id}');
        if (mounted) {
          DefaultToast.show(context, 'Invalid user id', isError: true);
        }
        return;
      }
      final obfuscatedAccountId = iapObfuscatedAccountIdFromUserId(user.id);
      _appendIapLog(
        'obfuscatedAccountId set — userId=${user.id} '
        'sha256_hex=${obfuscatedAccountId.substring(0, 8)}…',
      );

      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        _appendIapLog('Store not available.');
        return;
      }

      final response = await iap.queryProductDetails({sku.productId});
      if (response.notFoundIDs.contains(sku.productId) ||
          response.productDetails.isEmpty) {
        _appendIapLog(
          'Buy failed: product not found (${response.notFoundIDs.join(', ')})',
        );
        if (mounted) {
          DefaultToast.show(
            context,
            'Product not found: ${sku.productId}',
            isError: true,
          );
        }
        return;
      }

      final product = _pickProductForSku(sku, response.productDetails);
      if (product == null) {
        _appendIapLog('Buy failed: no matching offer for ${sku.key}');
        return;
      }

      _appendIapLog(
        'Launching purchase UI — price=${product.price}'
        '${product is GooglePlayProductDetails ? ' offerToken=${product.offerToken}' : ''}',
      );

      // applicationUserName → Play BillingFlowParams.setObfuscatedAccountId
      final purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: obfuscatedAccountId,
        offerToken: product is GooglePlayProductDetails
            ? product.offerToken
            : null,
      );

      final bool launched;
      if (sku.consumable) {
        launched = await iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        launched = await iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      _appendIapLog('buy* launched=$launched (await purchaseStream)');
    } catch (e, st) {
      debugPrint('[DEBUG] Lab IAP buy failed: $e\n$st');
      _appendIapLog('Buy exception: $e');
      if (mounted) {
        DefaultToast.show(context, 'Buy failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _iapBusy = false);
    }
  }

  String _purchaseTokenOf(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseToken;
    }
    return purchase.verificationData.serverVerificationData;
  }

  Future<void> _onIapPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      _appendIapLog(
        'purchaseStream status=${purchase.status} '
        'productID=${purchase.productID} '
        'purchaseID=${purchase.purchaseID} '
        'pendingComplete=${purchase.pendingCompletePurchase}',
      );

      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _appendIapLog(
          'purchase error: ${purchase.error?.code} ${purchase.error?.message}',
        );
        if (mounted) {
          DefaultToast.show(
            context,
            'Purchase error: ${purchase.error?.message ?? purchase.error?.code}',
            isError: true,
          );
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        _appendIapLog('purchase canceled');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final token = _purchaseTokenOf(purchase);
        _appendIapLog(
          'purchase ok — productId=${purchase.productID} '
          'purchaseToken=$token',
        );
        // INAPP/SUBS 동일 전송. 서버가 productId로 분기.
        await _verifyPurchaseWithServer(
          productId: purchase.productID,
          purchaseToken: token,
        );
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(purchase);
          _appendIapLog('completePurchase done for ${purchase.productID}');
        } catch (e) {
          _appendIapLog('completePurchase failed: $e');
        }
      }
    }
  }

  Future<void> _verifyPurchaseWithServer({
    required String productId,
    required String purchaseToken,
  }) async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _appendIapLog('verify skipped — no JWT (login required)');
      if (mounted) {
        DefaultToast.show(context, 'Login required for verify', isError: true);
      }
      return;
    }

    _appendIapLog(
      'POST /v1/purchases/verify — ENV=${AppConfig.env} '
      'productId=$productId (server packageName follows ENV)',
    );
    try {
      await SudaApiClient.verifyPurchase(
        accessToken: accessToken,
        purchaseToken: purchaseToken,
        productId: productId,
      );
      _appendIapLog(
        'verify HTTP OK (TEMP: log-only on server, not entitlement grant)',
      );
      if (mounted) {
        DefaultToast.show(context, 'Verify called (TEMP OK)');
      }
    } catch (e, st) {
      debugPrint('[DEBUG] Lab IAP verify failed: $e\n$st');
      _appendIapLog('verify failed: $e');
      if (mounted) {
        DefaultToast.show(context, 'Verify failed: $e', isError: true);
      }
    }
  }

  void _seedLabS2TryAgainState() {
    SeriesStateService.instance.setSeriesOverview(
      seriesId: 1,
      overview: const RpS2SeriesOverviewDto(
        title: {'en': 'Lab Series'},
        synopsis: {'en': ''},
        endingTitle: {'en': 'Lab Ending'},
        endingContent: {'en': ''},
        episodes: [
          RpS2SeriesEpisodeDto(
            id: 1,
            title: {'en': 'Lab Episode'},
            summary: {'en': ''},
            briefing: {'en': ''},
            learningFunction: {'en': ''},
          ),
        ],
        bestScoreMap: {},
      ),
    );
    SeriesStateService.instance.setSelectedEpisodeId(1);
  }

  Future<void> _openTryAgainScreen() async {
    _seedLabS2TryAgainState();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleplayTryAgainScreen()),
    );
  }

  Future<void> _openTryAgainReportScreen() async {
    if (!mounted) return;
    await RoleplayRouter.pushTryAgainReport(context);
  }

  int _parseEnergyPopupCount() {
    final parsed = int.tryParse(_energyPopupCountController.text.trim());
    if (parsed == null) return 0;
    return parsed.clamp(0, 5);
  }

  Future<void> _showEnergyPopupTest() async {
    final count = _parseEnergyPopupCount();
    if (_energyPopupCountController.text.trim() != '$count') {
      _energyPopupCountController.text = '$count';
    }
    await showEnergyPopupForLab(
      context,
      playing: _energyPopupPlaying,
      unlimited: _energyPopupUnlimited,
      energyCount: count,
    );
  }

  Widget _buildLabCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context).textTheme;
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFF0CABA8),
      checkColor: Colors.white,
      title: Text(
        label,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildLabScreenButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0CABA8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(height: 1, thickness: 1, color: Color(0xFF353535)),
    );
  }

  Widget _buildStylePreview(
    BuildContext context, {
    required String label,
    required TextStyle? style,
  }) {
    final theme = Theme.of(context).textTheme;
    final previewStyle = style?.copyWith(color: Colors.white);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.labelSmall?.copyWith(color: const Color(0xFF80D7CF)),
          ),
          const SizedBox(height: 8),
          for (final line in _stylePreviewLines) ...[
            Text(line, style: previewStyle),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return AppScaffold(
      centerTitle: l10n.settingsFsdLaboratory,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'First CEFR Level',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _openFirstCefrLevelScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Open First CEFR Level'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Paywall',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: 'Open Paywall',
              onPressed: () => unawaited(_openPaywallScreen()),
            ),
            const SizedBox(height: 8),
            _buildLabScreenButton(
              label: 'Open Paywall Completed',
              onPressed: () => unawaited(_openPaywallCompletedScreen()),
            ),
            _buildSectionDivider(),
            Text(
              'IAP Products',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'INAPP/SUBS buy → POST /v1/purchases/verify (서버가 productId 분기).\n'
              'ENV=${AppConfig.env} (server packageName follows ENV).',
              style: theme.bodySmall?.copyWith(color: const Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: _iapBusy ? 'IAP busy…' : 'Query All Catalog',
              onPressed: _iapBusy
                  ? () {}
                  : () => unawaited(_queryAllLabSkus()),
            ),
            const SizedBox(height: 12),
            for (final sku in _kLabIapSkus) ...[
              Text(
                '${sku.label}  (${sku.productId}'
                '${sku.basePlanId == null ? '' : ' / ${sku.basePlanId}'}'
                '${sku.kind == _LabIapKind.inapp ? ', INAPP' : ', SUBS'})',
                style: theme.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLabScreenButton(
                      label: 'Query',
                      onPressed: _iapBusy
                          ? () {}
                          : () => unawaited(_queryLabSku(sku)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLabScreenButton(
                      label: 'Buy',
                      onPressed: _iapBusy
                          ? () {}
                          : () => unawaited(_buyLabSku(sku)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _iapProductIdsController,
              style: theme.bodyLarge?.copyWith(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'productIds (comma / space separated)',
                labelStyle: theme.bodyMedium?.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
                hintText: 'manual override',
                hintStyle: theme.bodyMedium?.copyWith(
                  color: const Color(0xFF635F5F),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF353535)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF353535)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF80D7CF)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: 'Query Freeform IDs',
              onPressed: _iapBusy
                  ? () {}
                  : () => unawaited(_queryIapProducts()),
            ),
            if (_iapLog.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _iapLog = ''),
                  child: const Text('Clear log'),
                ),
              ),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 360),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF353535)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _iapLog,
                    style: theme.bodySmall?.copyWith(
                      color: const Color(0xFF80D7CF),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
            _buildSectionDivider(),
            Text(
              'Roleplay Try Again',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: 'Open Try Again Screen',
              onPressed: () => unawaited(_openTryAgainScreen()),
            ),
            const SizedBox(height: 8),
            _buildLabScreenButton(
              label: 'Open Try Again Report Screen',
              onPressed: () => unawaited(_openTryAgainReportScreen()),
            ),
            _buildSectionDivider(),
            Text(
              'Default Popup Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (kLabDefaultPopupOptions.isEmpty) ...[
              Text(
                'No migrated DefaultPopup yet. Entries are added in '
                '`kLabDefaultPopupOptions` after each migration.',
                style: theme.bodyMedium?.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ] else ...[
              InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF353535)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF353535)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF80D7CF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedLabDefaultPopupId,
                    dropdownColor: const Color(0xFF1E1E1E),
                    hint: Text(
                      'Select popup',
                      style: theme.bodyLarge?.copyWith(
                        color: const Color(0xFF635F5F),
                      ),
                    ),
                    style: theme.bodyLarge?.copyWith(color: Colors.white),
                    items: [
                      for (final o in kLabDefaultPopupOptions)
                        DropdownMenuItem<String>(
                          value: o.id,
                          child: Text(o.label),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedLabDefaultPopupId = v),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: kLabDefaultPopupOptions.isEmpty
                    ? null
                    : () => unawaited(_showSelectedLabDefaultPopup()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Show Popup'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Energy Popup Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildLabCheckbox(
              label: 'playing',
              value: _energyPopupPlaying,
              onChanged: (v) => setState(() => _energyPopupPlaying = v),
            ),
            _buildLabCheckbox(
              label: '무제한 모드',
              value: _energyPopupUnlimited,
              onChanged: (v) => setState(() => _energyPopupUnlimited = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _energyPopupCountController,
              keyboardType: TextInputType.number,
              style: theme.bodyLarge?.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Energy count (0~5)',
                labelStyle: theme.bodyMedium?.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF353535)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF353535)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF80D7CF)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: 'Show Energy Popup',
              onPressed: () => unawaited(_showEnergyPopupTest()),
            ),
            _buildSectionDivider(),
            Text(
              'Default Toast Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _toastIsWarning,
              onChanged: (v) => setState(() => _toastIsWarning = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF0CABA8),
              checkColor: Colors.white,
              title: Text(
                'Warning (red)',
                style: theme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showTestToast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Show Toast'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showTestToastLong,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Show Toast(Long Text)'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Like Effect Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _playLikeEffect(
                  const LikeProgressEffectParams(
                    asIsLikePoint: 36,
                    toBeLikePoint: 72,
                    asIsLevel: 36,
                    toBeLevel: 36,
                    asIsProgress: 25,
                    toBeProgress: 75,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Simple Like Effect'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _playLikeEffect(
                  const LikeProgressEffectParams(
                    asIsLikePoint: 36,
                    toBeLikePoint: 172,
                    asIsLevel: 36,
                    toBeLevel: 38,
                    asIsProgress: 25,
                    toBeProgress: 75,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Levelup Like Effect'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Style',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildStylePreview(
              context,
              label: 'heading1 (headlineLarge)',
              style: theme.headlineLarge,
            ),
            _buildStylePreview(
              context,
              label: 'heading2 (headlineMedium)',
              style: theme.headlineMedium,
            ),
            _buildStylePreview(
              context,
              label: 'heading3 (headlineSmall)',
              style: theme.headlineSmall,
            ),
            _buildStylePreview(
              context,
              label: 'body-default (bodyLarge)',
              style: theme.bodyLarge,
            ),
            _buildStylePreview(
              context,
              label: 'body-secondary (bodyMedium)',
              style: theme.bodyMedium,
            ),
            _buildStylePreview(
              context,
              label: 'body-caption (bodySmall)',
              style: theme.bodySmall,
            ),
            _buildStylePreview(
              context,
              label: 'body-tiny (labelSmall)',
              style: theme.labelSmall,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _playLikeEffect(LikeProgressEffectParams params) async {
    await LikeProgressEffect.play(context, params: params);
  }
}
