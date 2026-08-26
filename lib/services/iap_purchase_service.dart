import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';

import '../api/suda_api_client.dart';
import '../models/user_models.dart';
import '../utils/iap_obfuscated_account_id.dart';
import 'iap_price_cache.dart';
import 'perf_monitoring_service.dart';
import 'token_storage.dart';

/// INAPP/SUBS 단건 구매 + 서버 verify.
///
/// - 동시에 하나의 구매/restore만 처리 (`isBusy`).
/// - 가격은 [IapPriceCache]에 영속 저장.
/// - AOS: 스토어 복귀 후 [_resumeGrace] 동안 매칭 스트림을 기다린다. 오면 즉시
///   verify하고 스피너를 닫는다. 만료 시에만 `queryPastPurchases`로 회수하고,
///   그래도 없으면 `storeDismissed`. 미ack/미consume은 orphan으로 verify.
/// - iOS: StoreKit 스트림의 purchased/canceled 대기. resume grace 없음.
/// - AOS: Play consume/ack는 서버. 클라 `completePurchase` 없음.
/// - iOS: verify `finishYn=Y`일 때만 `completePurchase`.
class IapPurchaseService with WidgetsBindingObserver {
  IapPurchaseService._();

  static final IapPurchaseService instance = IapPurchaseService._();

  static const productUnlimited10Min = 'unlimited_energy_10_minute';
  static const productCapacity6 = 'energy_capacity_6';
  static const productCapacity7 = 'energy_capacity_7';
  static const productPremium = 'subscription_premium';
  static const productPremiumMonthly = 'premium_monthly';
  static const productPremiumYearly = 'premium_yearly';
  static const basePlanMonthly = 'bp-premium-monthly';
  static const basePlanYearly = 'bp-premium-yearly';
  static const verifyPlatformIos = 'IOS';

  static const Set<String> inAppProductIds = {
    productUnlimited10Min,
    productCapacity6,
    productCapacity7,
  };

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// iOS 구독 ASC productId. AOS는 [productPremium] + basePlan.
  static String iosSubscriptionProductId(String basePlanId) {
    return basePlanId == basePlanYearly
        ? productPremiumYearly
        : productPremiumMonthly;
  }

  static String? basePlanIdForProductId(String productId) {
    if (productId == productPremiumMonthly) return basePlanMonthly;
    if (productId == productPremiumYearly) return basePlanYearly;
    return null;
  }

  /// AOS: 스토어 복귀 후 매칭 스트림 대기 상한. 조기 수신 시 즉시 종료.
  static const _resumeGrace = Duration(seconds: 10);
  static const _restoreInitialGrace = Duration(seconds: 8);
  static const _restoreIdleGrace = Duration(seconds: 2);

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<IapPurchaseResult>? _pending;
  String? _pendingProductId;
  String? _pendingAccessToken;
  /// 에너지 팝업 INAPP: 탭 시점 offerSessionId(verify 어트리뷰션). refetch로 바뀌어도 유지.
  String? _pendingOfferSessionId;
  /// Paywall SUBS: mount `paywallSessionId` + 선택 basePlanId(verify·탭 impression).
  String? _pendingPaywallSessionId;
  String? _pendingBasePlanId;
  Timer? _resumeGraceTimer;
  bool _lifecycleObserving = false;
  /// 매칭 purchaseStream 수신 후 true. resume grace가 verify 중 storeDismissed로
  /// 성공 결과를 덮어쓰지 않도록 한다.
  bool _purchaseUpdateReceived = false;

  /// 화면 이탈(abandon) 후에도 orphan verify에 쓸 세션.
  String? _detachedProductId;
  String? _detachedAccessToken;
  String? _detachedOfferSessionId;
  String? _detachedPaywallSessionId;
  String? _detachedBasePlanId;

  final Set<String> _verifiedPurchaseTokens = {};
  final Set<String> _verifyingPurchaseTokens = {};
  bool _recoveringUnfinished = false;
  Future<void> _purchaseUpdateChain = Future<void>.value();

  Completer<IapPurchaseResult>? _restorePending;
  String? _restoreAccessToken;
  Timer? _restoreGraceTimer;
  bool _restoreSawRestorable = false;
  bool _restoreHadSuccess = false;
  bool _restoreHadPending = false;
  bool _restoreHadVerifyFail = false;

  bool get isBusy => _pending != null || _restorePending != null;

  void ensureListening() {
    if (_purchaseSub != null) return;
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e, StackTrace st) {
        debugPrint('[DEBUG] IapPurchaseService stream error: $e\n$st');
        _failPending(IapPurchaseResult.storeDismissed);
        _failRestore(IapPurchaseResult.storeDismissed);
      },
    );
    _ensureLifecycleObserver();
    if (!_isIos) {
      unawaited(_recoverUnfinishedAndroidPurchases());
    }
  }

  void _ensureLifecycleObserver() {
    if (_lifecycleObserving) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleObserving = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // iOS는 StoreKit이 purchased/canceled를 스트림으로 줌. Play 시트 dismiss용
    // resume grace를 쓰면 복귀 후 스트림이 늦을 때 성공 구매가 storeDismissed로
    // 떨어질 수 있어 AOS만 상한 대기한다. 만료 전에는 조기 종료.
    if (_isIos) return;
    if (_pending == null || _purchaseUpdateReceived) return;

    _resumeGraceTimer?.cancel();
    _resumeGraceTimer = Timer(_resumeGrace, () {
      unawaited(_onResumeGraceTimeout());
    });
  }

  void _cancelResumeGrace() {
    _resumeGraceTimer?.cancel();
    _resumeGraceTimer = null;
  }

  Future<void> _onResumeGraceTimeout() async {
    if (_pending == null || _purchaseUpdateReceived) return;
    debugPrint(
      '[DEBUG] IapPurchaseService resume grace timeout → query '
      '(productId=$_pendingProductId)',
    );
    final recovered = await _recoverPendingFromPlayQuery();
    if (_pending == null || _purchaseUpdateReceived) return;
    if (recovered) return;
    debugPrint(
      '[DEBUG] IapPurchaseService resume grace timeout → storeDismissed '
      '(productId=$_pendingProductId)',
    );
    _failPending(IapPurchaseResult.storeDismissed);
  }

  /// 화면 이탈 등으로 대기 중 구매/restore를 포기할 때.
  /// 이후 도착하는 Play 콜백은 orphan이 세션을 이어받아 verify한다.
  void abandonPendingPurchase() {
    if (_pending != null) {
      _stashDetachedPending();
      _failPending(IapPurchaseResult.storeDismissed);
    }
    if (_restorePending != null) {
      _failRestore(IapPurchaseResult.storeDismissed);
    }
  }

  /// 스토어에서 가격을 조회해 캐시. 실패해도 기존 캐시 유지.
  Future<void> prefetchAndCachePrices(Set<String> productIds) async {
    if (productIds.isEmpty) return;
    ensureListening();
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return;
      final response =
          await InAppPurchase.instance.queryProductDetails(productIds);
      for (final product in response.productDetails) {
        final price = product.price;
        if (price.isNotEmpty) {
          await IapPriceCache.save(product.id, price);
        }
      }
    } catch (e, st) {
      debugPrint('[DEBUG] IapPurchaseService prefetch prices failed: $e\n$st');
    }
  }

  Future<String?> cachedFormattedPrice(String productId, {String? basePlanId}) {
    return IapPriceCache.load(productId, basePlanId: basePlanId);
  }

  /// Premium 월/연 플랜 가격 조회·캐시.
  Future<PremiumSubscriptionPrices> loadPremiumSubscriptionPrices() async {
    ensureListening();

    final cachedMonthly = await IapPriceCache.load(
      productPremium,
      basePlanId: basePlanMonthly,
    );
    final cachedYearly = await IapPriceCache.load(
      productPremium,
      basePlanId: basePlanYearly,
    );

    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        return PremiumSubscriptionPrices(
          monthlyFormatted: cachedMonthly,
          yearlyFormatted: cachedYearly,
          yearlyPerMonthFormatted: null,
        );
      }

      final queryIds = _isIos
          ? {productPremiumMonthly, productPremiumYearly}
          : {productPremium};
      final response =
          await InAppPurchase.instance.queryProductDetails(queryIds);
      final monthly = _isIos
          ? _productById(productPremiumMonthly, response.productDetails)
          : _pickSubscriptionProduct(
              productPremium,
              basePlanMonthly,
              response.productDetails,
            );
      final yearly = _isIos
          ? _productById(productPremiumYearly, response.productDetails)
          : _pickSubscriptionProduct(
              productPremium,
              basePlanYearly,
              response.productDetails,
            );

      if (monthly != null && monthly.price.isNotEmpty) {
        await IapPriceCache.save(
          productPremium,
          monthly.price,
          basePlanId: basePlanMonthly,
        );
      }
      if (yearly != null && yearly.price.isNotEmpty) {
        await IapPriceCache.save(
          productPremium,
          yearly.price,
          basePlanId: basePlanYearly,
        );
      }

      return PremiumSubscriptionPrices(
        monthlyFormatted: monthly?.price ?? cachedMonthly,
        yearlyFormatted: yearly?.price ?? cachedYearly,
        yearlyPerMonthFormatted:
            yearly == null ? null : _formatYearlyPerMonth(yearly),
      );
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService load premium prices failed: $e\n$st',
      );
      return PremiumSubscriptionPrices(
        monthlyFormatted: cachedMonthly,
        yearlyFormatted: cachedYearly,
        yearlyPerMonthFormatted: null,
      );
    }
  }

  String _formatYearlyPerMonth(ProductDetails yearly) {
    final perMonth = yearly.rawPrice / 12.0;
    final symbol = yearly.currencySymbol;
    final formatted = NumberFormat.currency(
      name: yearly.currencyCode,
      symbol: symbol,
      decimalDigits: 2,
    ).format(perMonth);
    return formatted;
  }

  ProductDetails? _productById(String productId, List<ProductDetails> products) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  ProductDetails? _pickSubscriptionProduct(
    String productId,
    String basePlanId,
    List<ProductDetails> products,
  ) {
    final matches = products.where((p) => p.id == productId).toList();
    if (matches.isEmpty) return null;

    for (final product in matches) {
      if (product is! GooglePlayProductDetails) continue;
      final index = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) continue;
      if (offers[index].basePlanId == basePlanId) {
        return product;
      }
    }
    return matches.first;
  }

  /// INAPP 구매 → verify.
  /// [offerSessionId]: 에너지 팝업 탭 시점 세션(verify body). 비어 있으면 미포함.
  Future<IapPurchaseResult> purchaseInApp({
    required String productId,
    required bool consumable,
    required String accessToken,
    String? offerSessionId,
  }) {
    return _purchase(
      productId: productId,
      accessToken: accessToken,
      resolveProduct: (products) => products.isEmpty ? null : products.first,
      consumable: consumable,
      offerSessionId: offerSessionId,
    );
  }

  /// SUBS Premium 구매 → verify. Paywall 경로는 [paywallSessionId] 포함.
  Future<IapPurchaseResult> purchaseSubscription({
    required String basePlanId,
    required String accessToken,
    String? paywallSessionId,
  }) {
    final productId =
        _isIos ? iosSubscriptionProductId(basePlanId) : productPremium;
    return _purchase(
      productId: productId,
      accessToken: accessToken,
      resolveProduct: (products) => _isIos
          ? _productById(productId, products)
          : _pickSubscriptionProduct(
              productPremium,
              basePlanId,
              products,
            ),
      consumable: false,
      cacheBasePlanId: basePlanId,
      paywallSessionId: paywallSessionId,
      verifyBasePlanId: basePlanId,
    );
  }

  /// Premium base plan 변경.
  ///
  /// AOS: [ReplacementMode.withoutProration]. 기존 활성 구매가 없으면
  /// [IapPurchaseOutcome.oldPurchaseNotFound].
  /// iOS: 같은 그룹 `premium_yearly` 구매(다음 renewal crossgrade).
  Future<IapPurchaseResult> changeSubscription({
    required String newBasePlanId,
    required String accessToken,
  }) async {
    if (isBusy) {
      return IapPurchaseResult.storeDismissed;
    }

    if (_isIos) {
      return _purchase(
        productId: iosSubscriptionProductId(newBasePlanId),
        accessToken: accessToken,
        resolveProduct: (products) => _productById(
          iosSubscriptionProductId(newBasePlanId),
          products,
        ),
        consumable: false,
        cacheBasePlanId: newBasePlanId,
        verifyBasePlanId: newBasePlanId,
      );
    }

    ensureListening();
    try {
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final past = await addition.queryPastPurchases();
      GooglePlayPurchaseDetails? oldPurchase;
      for (final p in past.pastPurchases) {
        if (p.productID == productPremium) {
          oldPurchase = p;
          break;
        }
      }
      if (oldPurchase == null) {
        debugPrint(
          '[DEBUG] IapPurchaseService changeSubscription: '
          'old purchase not found (productId=$productPremium, '
          'newBasePlanId=$newBasePlanId, '
          'pastCount=${past.pastPurchases.length}, '
          'error=${past.error})',
        );
        return IapPurchaseResult.oldPurchaseNotFound;
      }

      debugPrint(
        '[DEBUG] IapPurchaseService changeSubscription: '
        'oldTokenLen=${oldPurchase.billingClientPurchase.purchaseToken.length}, '
        'newBasePlanId=$newBasePlanId, replacementMode=withoutProration',
      );

      return _purchase(
        productId: productPremium,
        accessToken: accessToken,
        resolveProduct: (products) => _pickSubscriptionProduct(
          productPremium,
          newBasePlanId,
          products,
        ),
        consumable: false,
        cacheBasePlanId: newBasePlanId,
        changeSubscriptionParam: ChangeSubscriptionParam(
          oldPurchaseDetails: oldPurchase,
          replacementMode: ReplacementMode.withoutProration,
        ),
      );
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService changeSubscription failed: $e\n$st',
      );
      return IapPurchaseResult.storeDismissed;
    }
  }

  /// iOS Restore. 소모품은 verify하지 않음. 세션 ID 없음.
  Future<IapPurchaseResult> restorePurchases({
    required String accessToken,
  }) async {
    if (!_isIos) {
      return IapPurchaseResult.unavailable;
    }
    if (isBusy) {
      return IapPurchaseResult.storeDismissed;
    }

    ensureListening();
    try {
      if (!await InAppPurchase.instance.isAvailable()) {
        return IapPurchaseResult.unavailable;
      }
    } catch (e, st) {
      debugPrint('[DEBUG] IapPurchaseService restore available failed: $e\n$st');
      return IapPurchaseResult.storeDismissed;
    }

    final completer = Completer<IapPurchaseResult>();
    _restorePending = completer;
    _restoreAccessToken = accessToken;
    _restoreSawRestorable = false;
    _restoreHadSuccess = false;
    _restoreHadPending = false;
    _restoreHadVerifyFail = false;
    _armRestoreGrace(_restoreInitialGrace);

    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e, st) {
      debugPrint('[DEBUG] IapPurchaseService restorePurchases failed: $e\n$st');
      _failRestore(IapPurchaseResult.storeDismissed);
    }

    return completer.future;
  }

  Future<IapPurchaseResult> _purchase({
    required String productId,
    required String accessToken,
    required ProductDetails? Function(List<ProductDetails> products)
        resolveProduct,
    required bool consumable,
    String? cacheBasePlanId,
    ChangeSubscriptionParam? changeSubscriptionParam,
    String? offerSessionId,
    String? paywallSessionId,
    String? verifyBasePlanId,
  }) async {
    if (isBusy) {
      return IapPurchaseResult.storeDismissed;
    }

    // token 확보 전 구간 (스토어 UI·구매 응답까지)
    await PerfMonitoringService.instance.start('purchase_before_token');

    ensureListening();
    final completer = Completer<IapPurchaseResult>();
    _pending = completer;
    _pendingProductId = productId;
    _pendingAccessToken = accessToken;
    final trimmedOffer = offerSessionId?.trim();
    _pendingOfferSessionId =
        (trimmedOffer != null && trimmedOffer.isNotEmpty) ? trimmedOffer : null;
    final trimmedPaywall = paywallSessionId?.trim();
    _pendingPaywallSessionId =
        (trimmedPaywall != null && trimmedPaywall.isNotEmpty)
            ? trimmedPaywall
            : null;
    final trimmedPlan = verifyBasePlanId?.trim();
    _pendingBasePlanId =
        (trimmedPlan != null && trimmedPlan.isNotEmpty) ? trimmedPlan : null;
    _purchaseUpdateReceived = false;
    _cancelResumeGrace();
    _clearDetachedPending();

    try {
      final user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
      if (user.id <= 0) {
        _clearPending();
        await PerfMonitoringService.instance.stop('purchase_before_token');
        return IapPurchaseResult.storeDismissed;
      }
      final obfuscatedAccountId = iapObfuscatedAccountIdFromUserId(user.id);

      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        _clearPending();
        await PerfMonitoringService.instance.stop('purchase_before_token');
        return IapPurchaseResult.unavailable;
      }

      final response = await iap.queryProductDetails({productId});
      if (response.notFoundIDs.contains(productId) ||
          response.productDetails.isEmpty) {
        _clearPending();
        await PerfMonitoringService.instance.stop('purchase_before_token');
        return IapPurchaseResult.unavailable;
      }

      final product = resolveProduct(response.productDetails);
      if (product == null) {
        _clearPending();
        await PerfMonitoringService.instance.stop('purchase_before_token');
        return IapPurchaseResult.unavailable;
      }

      if (product.price.isNotEmpty) {
        await IapPriceCache.save(
          product.id,
          product.price,
          basePlanId: cacheBasePlanId,
        );
      }

      final PurchaseParam purchaseParam;
      if (_isIos) {
        purchaseParam = PurchaseParam(productDetails: product);
      } else {
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: obfuscatedAccountId,
          offerToken: product is GooglePlayProductDetails
              ? product.offerToken
              : null,
          changeSubscriptionParam: changeSubscriptionParam,
        );
      }

      // consume/ack는 서버 verify에서 처리(Play). iOS finish는 verify finishYn.
      final bool launched;
      if (consumable) {
        launched = await iap.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: false,
        );
      } else {
        launched = await iap.buyNonConsumable(purchaseParam: purchaseParam);
      }

      if (!launched) {
        debugPrint(
          '[DEBUG] IapPurchaseService buy not launched '
          '(productId=$productId, basePlanId=$cacheBasePlanId, '
          'change=${changeSubscriptionParam != null})',
        );
        if (!_isIos && await _recoverPendingFromPlayQuery()) {
          return completer.future;
        }
        _clearPending();
        await PerfMonitoringService.instance.stop('purchase_before_token');
        return IapPurchaseResult.storeDismissed;
      }
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService buy failed '
        '(productId=$productId, basePlanId=$cacheBasePlanId, '
        'change=${changeSubscriptionParam != null}): $e\n$st',
      );
      if (!_isIos && _pending != null && await _recoverPendingFromPlayQuery()) {
        return completer.future;
      }
      _clearPending();
      await PerfMonitoringService.instance.stop('purchase_before_token');
      return IapPurchaseResult.storeDismissed;
    }

    return completer.future;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    final run = _purchaseUpdateChain.then((_) => _dispatchPurchaseUpdates(purchases));
    _purchaseUpdateChain = run.catchError((Object e, StackTrace st) {
      debugPrint('[DEBUG] IapPurchaseService dispatch failed: $e\n$st');
    });
    return run;
  }

  Future<void> _dispatchPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint(
        '[DEBUG] IapPurchaseService stream: productId=${purchase.productID}, '
        'status=${purchase.status}, pendingProductId=$_pendingProductId',
      );
    }
    for (final purchase in purchases) {
      if (_isMatchingPendingUpdate(purchase)) {
        await _handlePendingPurchaseUpdate(purchase);
      }
    }
    for (final purchase in purchases) {
      if (_isMatchingPendingUpdate(purchase)) continue;
      if (_restorePending != null) {
        await _handleRestorePurchaseUpdate(purchase);
        continue;
      }
      await _handleOrphanPurchase(purchase);
    }
  }

  bool _isMatchingPendingUpdate(PurchaseDetails purchase) {
    if (_pending == null) return false;
    if (purchase.productID == _pendingProductId) return true;
    return purchase.productID.isEmpty &&
        (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled);
  }

  Future<void> _handlePendingPurchaseUpdate(PurchaseDetails purchase) async {
    _purchaseUpdateReceived = true;
    _cancelResumeGrace();

    if (purchase.status == PurchaseStatus.pending) {
      return;
    }

    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      final err = purchase.error;
      debugPrint(
        '[DEBUG] IapPurchaseService purchase ${purchase.status}: '
        'productId=${purchase.productID}, '
        'errorCode=${err?.code}, errorMessage=${err?.message}, '
        'errorDetails=${err?.details}',
      );
      _failPending(IapPurchaseResult.storeDismissed);
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      final accessToken = _pendingAccessToken;
      final purchaseToken = _purchaseTokenOf(purchase);
      await PerfMonitoringService.instance.stop('purchase_before_token');
      await PerfMonitoringService.instance.start('purchase_after_token');
      if (accessToken == null || accessToken.isEmpty) {
        _failPending(IapPurchaseResult.storeDismissed);
        return;
      }

      try {
        final verify = await _verifyPurchase(
          accessToken: accessToken,
          purchase: purchase,
          purchaseToken: purchaseToken,
          offerSessionId: _pendingOfferSessionId,
          paywallSessionId: _pendingPaywallSessionId,
          basePlanId: _basePlanIdForVerify(
            purchase.productID,
            pending: _pendingBasePlanId,
          ),
        );
        await _maybeFinish(purchase, verify);
        if (!verify.isSuccess) {
          _failPending(IapPurchaseResult.verifyFailed);
        } else {
          _completePending(
            IapPurchaseResult.success(pendingApproval: verify.isPending),
          );
        }
      } catch (e, st) {
        debugPrint(
          '[DEBUG] IapPurchaseService verify failed: '
          'productId=${purchase.productID}, error=$e\n$st',
        );
        _failPending(IapPurchaseResult.verifyFailed);
      }
    }
  }

  Future<void> _handleRestorePurchaseUpdate(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      _armRestoreGrace(_restoreIdleGrace);
      return;
    }
    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      debugPrint(
        '[DEBUG] IapPurchaseService restore ${purchase.status}: '
        'productId=${purchase.productID}, '
        'errorCode=${purchase.error?.code}, '
        'errorMessage=${purchase.error?.message}',
      );
      _armRestoreGrace(_restoreIdleGrace);
      return;
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }

    _armRestoreGrace(_restoreIdleGrace);

    if (purchase.productID == productUnlimited10Min) {
      await _finishWithoutVerify(purchase);
      return;
    }

    final accessToken = _restoreAccessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    _restoreSawRestorable = true;
    try {
      final verify = await _verifyPurchase(
        accessToken: accessToken,
        purchase: purchase,
        purchaseToken: _purchaseTokenOf(purchase),
        basePlanId: _basePlanIdForVerify(purchase.productID),
      );
      await _maybeFinish(purchase, verify);
      if (verify.isSuccess) {
        _restoreHadSuccess = true;
        if (verify.isPending) _restoreHadPending = true;
      } else {
        _restoreHadVerifyFail = true;
      }
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService restore verify failed: '
        'productId=${purchase.productID}, error=$e\n$st',
      );
      _restoreHadVerifyFail = true;
    }
  }

  /// 미ack(iOS finish / AOS ack) 또는 AOS 미consume 소모품.
  Future<void> _handleOrphanPurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) return;
    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      return;
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }
    if (purchase.productID.isEmpty) return;
    if (!_shouldVerifyOrphan(purchase)) return;
    final existingToken = _purchaseTokenOf(purchase);
    if (existingToken.isNotEmpty &&
        _verifiedPurchaseTokens.contains(existingToken)) {
      return;
    }

    final useDetached = purchase.productID == _detachedProductId;
    final accessToken = (useDetached ? _detachedAccessToken : null) ??
        await TokenStorage.loadAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      final verify = await _verifyPurchase(
        accessToken: accessToken,
        purchase: purchase,
        purchaseToken: _purchaseTokenOf(purchase),
        offerSessionId: useDetached ? _detachedOfferSessionId : null,
        paywallSessionId: useDetached ? _detachedPaywallSessionId : null,
        basePlanId: _basePlanIdForVerify(
          purchase.productID,
          pending: useDetached ? _detachedBasePlanId : null,
        ),
      );
      await _maybeFinish(purchase, verify);
      if (useDetached) _clearDetachedPending();
      if (verify.isSuccess) {
        try {
          await SudaApiClient.getUserEnergySimple(accessToken: accessToken);
        } catch (e, st) {
          debugPrint(
            '[DEBUG] IapPurchaseService orphan energy refresh failed: $e\n$st',
          );
        }
      }
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService orphan verify failed: '
        'productId=${purchase.productID}, error=$e\n$st',
      );
    }
  }

  Future<PurchaseVerifyResultDto> _verifyPurchase({
    required String accessToken,
    required PurchaseDetails purchase,
    required String purchaseToken,
    String? offerSessionId,
    String? paywallSessionId,
    String? basePlanId,
  }) async {
    debugPrint(
      '[DEBUG] IapPurchaseService verify start: productId=${purchase.productID}, '
      'tokenLen=${purchaseToken.length}',
    );
    if (purchaseToken.isNotEmpty) {
      if (_verifiedPurchaseTokens.contains(purchaseToken)) {
        debugPrint(
          '[DEBUG] IapPurchaseService verify skip (already verified) '
          'productId=${purchase.productID}',
        );
        return const PurchaseVerifyResultDto(
          successYn: 'Y',
          pendingYn: 'N',
          finishYn: 'N',
        );
      }
      while (_verifyingPurchaseTokens.contains(purchaseToken)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (_verifiedPurchaseTokens.contains(purchaseToken)) {
        debugPrint(
          '[DEBUG] IapPurchaseService verify skip (already verified) '
          'productId=${purchase.productID}',
        );
        return const PurchaseVerifyResultDto(
          successYn: 'Y',
          pendingYn: 'N',
          finishYn: 'N',
        );
      }
      _verifyingPurchaseTokens.add(purchaseToken);
    }
    try {
      final result = await SudaApiClient.verifyPurchase(
        accessToken: accessToken,
        purchaseToken: purchaseToken,
        productId: purchase.productID,
        offerSessionId: offerSessionId,
        paywallSessionId: paywallSessionId,
        basePlanId: basePlanId,
        platform: _isIos ? verifyPlatformIos : null,
      );
      if (result.isSuccess && purchaseToken.isNotEmpty) {
        _verifiedPurchaseTokens.add(purchaseToken);
      }
      return result;
    } finally {
      _verifyingPurchaseTokens.remove(purchaseToken);
    }
  }

  String? _basePlanIdForVerify(String productId, {String? pending}) {
    final trimmed = pending?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return basePlanIdForProductId(productId);
  }

  Future<void> _maybeFinish(
    PurchaseDetails purchase,
    PurchaseVerifyResultDto verify,
  ) async {
    if (!_isIos || !verify.shouldFinish) return;
    await _completeStorePurchase(purchase);
  }

  Future<void> _finishWithoutVerify(PurchaseDetails purchase) async {
    if (!_isIos) return;
    await _completeStorePurchase(purchase);
  }

  Future<void> _completeStorePurchase(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await InAppPurchase.instance.completePurchase(purchase);
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService completePurchase failed: '
        'productId=${purchase.productID}, error=$e\n$st',
      );
    }
  }

  String _purchaseTokenOf(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseToken;
    }
    return purchase.verificationData.serverVerificationData;
  }

  bool _shouldVerifyOrphan(PurchaseDetails purchase) {
    if (_isIos) return purchase.pendingCompletePurchase;
    return _shouldVerifyAndroidPurchase(purchase);
  }

  /// AOS query/stream 회수 대상. ack된 비소모/구독은 매 런치 verify하지 않음.
  /// 소모품은 query에 남아 있으면 미consume.
  bool _shouldVerifyAndroidPurchase(PurchaseDetails purchase) {
    if (purchase.productID.isEmpty) return false;
    if (_purchaseTokenOf(purchase).isEmpty) return false;
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return false;
    }
    if (purchase.productID == productUnlimited10Min) return true;
    return purchase.pendingCompletePurchase;
  }

  Future<List<PurchaseDetails>> _queryAndroidPastPurchases() async {
    final addition = InAppPurchase.instance
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final past = await addition.queryPastPurchases();
    if (past.error != null) {
      debugPrint(
        '[DEBUG] IapPurchaseService queryPastPurchases error: ${past.error}',
      );
    }
    return past.pastPurchases;
  }

  /// pending 중인 상품을 Play query로 찾아 기존 verify 경로로 넘긴다.
  /// 매칭 구매를 핸들러에 넘겼으면 true.
  Future<bool> _recoverPendingFromPlayQuery() async {
    if (_isIos || _pending == null || _purchaseUpdateReceived) return false;
    final productId = _pendingProductId;
    if (productId == null || productId.isEmpty) return false;

    debugPrint(
      '[DEBUG] IapPurchaseService query recover start (productId=$productId)',
    );
    try {
      final past = await _queryAndroidPastPurchases();
      if (_pending == null || _purchaseUpdateReceived) return false;
      for (final p in past) {
        if (p.productID != productId) continue;
        if (_purchaseTokenOf(p).isEmpty) continue;
        if (p.status != PurchaseStatus.purchased &&
            p.status != PurchaseStatus.restored) {
          continue;
        }
        debugPrint(
          '[DEBUG] IapPurchaseService query recover hit '
          '(productId=${p.productID}, pendingComplete=${p.pendingCompletePurchase})',
        );
        await _handlePendingPurchaseUpdate(p);
        return true;
      }
      debugPrint(
        '[DEBUG] IapPurchaseService query recover miss (productId=$productId, '
        'count=${past.length})',
      );
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService query recover failed: $e\n$st',
      );
    }
    return false;
  }

  Future<void> _recoverUnfinishedAndroidPurchases() async {
    if (_isIos || _recoveringUnfinished) return;
    _recoveringUnfinished = true;
    try {
      if (isBusy) return;
      final past = await _queryAndroidPastPurchases();
      for (final p in past) {
        if (isBusy) return;
        if (!_shouldVerifyAndroidPurchase(p)) continue;
        debugPrint(
          '[DEBUG] IapPurchaseService unfinished recover '
          '(productId=${p.productID})',
        );
        await _handleOrphanPurchase(p);
      }
    } catch (e, st) {
      debugPrint(
        '[DEBUG] IapPurchaseService unfinished recover failed: $e\n$st',
      );
    } finally {
      _recoveringUnfinished = false;
    }
  }

  void _stashDetachedPending() {
    _detachedProductId = _pendingProductId;
    _detachedAccessToken = _pendingAccessToken;
    _detachedOfferSessionId = _pendingOfferSessionId;
    _detachedPaywallSessionId = _pendingPaywallSessionId;
    _detachedBasePlanId = _pendingBasePlanId;
  }

  void _clearDetachedPending() {
    _detachedProductId = null;
    _detachedAccessToken = null;
    _detachedOfferSessionId = null;
    _detachedPaywallSessionId = null;
    _detachedBasePlanId = null;
  }

  void _armRestoreGrace(Duration duration) {
    _restoreGraceTimer?.cancel();
    _restoreGraceTimer = Timer(duration, _completeRestore);
  }

  void _completeRestore() {
    final completer = _restorePending;
    if (completer == null) return;
    final IapPurchaseResult result;
    if (_restoreHadSuccess) {
      result = IapPurchaseResult.success(pendingApproval: _restoreHadPending);
    } else if (_restoreHadPending) {
      result = IapPurchaseResult.success(pendingApproval: true);
    } else if (_restoreHadVerifyFail) {
      result = IapPurchaseResult.verifyFailed;
    } else if (!_restoreSawRestorable) {
      result = IapPurchaseResult.nothingToRestore;
    } else {
      result = IapPurchaseResult.verifyFailed;
    }
    _clearRestore();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _failRestore(IapPurchaseResult result) {
    final completer = _restorePending;
    _clearRestore();
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _clearRestore() {
    _restoreGraceTimer?.cancel();
    _restoreGraceTimer = null;
    _restorePending = null;
    _restoreAccessToken = null;
    _restoreSawRestorable = false;
    _restoreHadSuccess = false;
    _restoreHadPending = false;
    _restoreHadVerifyFail = false;
  }

  void _completePending(IapPurchaseResult result) {
    final completer = _pending;
    _clearPending();
    unawaited(PerfMonitoringService.instance.stop('purchase_before_token'));
    unawaited(PerfMonitoringService.instance.stop('purchase_after_token'));
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _failPending(IapPurchaseResult result) {
    _completePending(result);
  }

  void _clearPending() {
    _cancelResumeGrace();
    _pending = null;
    _pendingProductId = null;
    _pendingAccessToken = null;
    _pendingOfferSessionId = null;
    _pendingPaywallSessionId = null;
    _pendingBasePlanId = null;
    _purchaseUpdateReceived = false;
  }
}

class PremiumSubscriptionPrices {
  final String? monthlyFormatted;
  final String? yearlyFormatted;
  /// 연간 rawPrice/12 포맷 (연간 카드 메인 `…/mês`용).
  final String? yearlyPerMonthFormatted;

  const PremiumSubscriptionPrices({
    required this.monthlyFormatted,
    required this.yearlyFormatted,
    required this.yearlyPerMonthFormatted,
  });
}

enum IapPurchaseOutcome {
  success,
  verifyFailed,
  storeDismissed,
  unavailable,
  /// changeSubscription: queryPastPurchases에 활성 Premium 구매 없음.
  oldPurchaseNotFound,
  /// iOS restore: restorable 트랜잭션 없음.
  nothingToRestore,
}

class IapPurchaseResult {
  final IapPurchaseOutcome outcome;
  final bool pendingApproval;

  const IapPurchaseResult._(this.outcome, {this.pendingApproval = false});

  factory IapPurchaseResult.success({required bool pendingApproval}) =>
      IapPurchaseResult._(
        IapPurchaseOutcome.success,
        pendingApproval: pendingApproval,
      );

  static const verifyFailed =
      IapPurchaseResult._(IapPurchaseOutcome.verifyFailed);
  static const storeDismissed =
      IapPurchaseResult._(IapPurchaseOutcome.storeDismissed);
  static const unavailable =
      IapPurchaseResult._(IapPurchaseOutcome.unavailable);
  static const oldPurchaseNotFound =
      IapPurchaseResult._(IapPurchaseOutcome.oldPurchaseNotFound);
  static const nothingToRestore =
      IapPurchaseResult._(IapPurchaseOutcome.nothingToRestore);

  bool get isSuccess => outcome == IapPurchaseOutcome.success;
}
