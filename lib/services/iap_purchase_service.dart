import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';

import '../api/suda_api_client.dart';
import '../utils/iap_obfuscated_account_id.dart';
import 'iap_price_cache.dart';

/// INAPP/SUBS 단건 구매 + 서버 verify.
///
/// - 동시에 하나의 구매만 처리 (`isBusy`).
/// - 가격은 [IapPriceCache]에 영속 저장.
/// - 스토어 UI에서 복귀(resume) 후 [_resumeGrace] 동안 **매칭 스트림이 없으면**
///   `storeDismissed`로 UI lock 해제. 스트림 수신 후에는 grace를 다시 걸지 않음.
class IapPurchaseService with WidgetsBindingObserver {
  IapPurchaseService._();

  static final IapPurchaseService instance = IapPurchaseService._();

  static const productUnlimited10Min = 'unlimited_energy_10_minute';
  static const productCapacity6 = 'energy_capacity_6';
  static const productCapacity7 = 'energy_capacity_7';
  static const productPremium = 'subscription_premium';
  static const basePlanMonthly = 'bp-premium-monthly';
  static const basePlanYearly = 'bp-premium-yearly';

  static const Set<String> inAppProductIds = {
    productUnlimited10Min,
    productCapacity6,
    productCapacity7,
  };

  /// 스토어 복귀 후 스트림 대기 grace.
  static const _resumeGrace = Duration(seconds: 2);

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<IapPurchaseResult>? _pending;
  String? _pendingProductId;
  String? _pendingAccessToken;
  Timer? _resumeGraceTimer;
  bool _lifecycleObserving = false;
  /// 매칭 purchaseStream 수신 후 true. resume grace가 verify 중 storeDismissed로
  /// 성공 결과를 덮어쓰지 않도록 한다.
  bool _purchaseUpdateReceived = false;

  bool get isBusy => _pending != null;

  void ensureListening() {
    if (_purchaseSub != null) return;
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e, StackTrace st) {
        debugPrint('[DEBUG] IapPurchaseService stream error: $e\n$st');
        _failPending(IapPurchaseResult.storeDismissed);
      },
    );
    _ensureLifecycleObserver();
  }

  void _ensureLifecycleObserver() {
    if (_lifecycleObserving) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleObserving = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_pending == null || _purchaseUpdateReceived) return;

    _resumeGraceTimer?.cancel();
    _resumeGraceTimer = Timer(_resumeGrace, () {
      if (_pending == null || _purchaseUpdateReceived) return;
      debugPrint(
        '[DEBUG] IapPurchaseService resume grace timeout → storeDismissed '
        '(productId=$_pendingProductId)',
      );
      _failPending(IapPurchaseResult.storeDismissed);
    });
  }

  void _cancelResumeGrace() {
    _resumeGraceTimer?.cancel();
    _resumeGraceTimer = null;
  }

  /// 화면 이탈 등으로 대기 중 구매를 포기할 때.
  void abandonPendingPurchase() {
    if (_pending == null) return;
    _failPending(IapPurchaseResult.storeDismissed);
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

      final response =
          await InAppPurchase.instance.queryProductDetails({productPremium});
      final monthly = _pickSubscriptionProduct(
        productPremium,
        basePlanMonthly,
        response.productDetails,
      );
      final yearly = _pickSubscriptionProduct(
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
  Future<IapPurchaseResult> purchaseInApp({
    required String productId,
    required bool consumable,
    required String accessToken,
  }) {
    return _purchase(
      productId: productId,
      accessToken: accessToken,
      resolveProduct: (products) => products.isEmpty ? null : products.first,
      consumable: consumable,
    );
  }

  /// SUBS Premium 구매 → verify. body는 INAPP과 동일 (`purchaseToken`, `productId`).
  Future<IapPurchaseResult> purchaseSubscription({
    required String basePlanId,
    required String accessToken,
  }) {
    return _purchase(
      productId: productPremium,
      accessToken: accessToken,
      resolveProduct: (products) => _pickSubscriptionProduct(
        productPremium,
        basePlanId,
        products,
      ),
      consumable: false,
      cacheBasePlanId: basePlanId,
    );
  }

  Future<IapPurchaseResult> _purchase({
    required String productId,
    required String accessToken,
    required ProductDetails? Function(List<ProductDetails> products)
        resolveProduct,
    required bool consumable,
    String? cacheBasePlanId,
  }) async {
    if (_pending != null) {
      return IapPurchaseResult.storeDismissed;
    }

    ensureListening();
    final completer = Completer<IapPurchaseResult>();
    _pending = completer;
    _pendingProductId = productId;
    _pendingAccessToken = accessToken;
    _purchaseUpdateReceived = false;
    _cancelResumeGrace();

    try {
      final user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
      if (user.id <= 0) {
        _clearPending();
        return IapPurchaseResult.storeDismissed;
      }
      final obfuscatedAccountId = iapObfuscatedAccountIdFromUserId(user.id);

      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        _clearPending();
        return IapPurchaseResult.unavailable;
      }

      final response = await iap.queryProductDetails({productId});
      if (response.notFoundIDs.contains(productId) ||
          response.productDetails.isEmpty) {
        _clearPending();
        return IapPurchaseResult.unavailable;
      }

      final product = resolveProduct(response.productDetails);
      if (product == null) {
        _clearPending();
        return IapPurchaseResult.unavailable;
      }

      if (product.price.isNotEmpty) {
        await IapPriceCache.save(
          product.id,
          product.price,
          basePlanId: cacheBasePlanId,
        );
      }

      final purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: obfuscatedAccountId,
        offerToken: product is GooglePlayProductDetails
            ? product.offerToken
            : null,
      );

      // consume/ack는 서버 verify에서 처리. 클라이언트는 호출하지 않음.
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
        _clearPending();
        return IapPurchaseResult.storeDismissed;
      }
    } catch (e, st) {
      debugPrint('[DEBUG] IapPurchaseService buy failed: $e\n$st');
      _clearPending();
      return IapPurchaseResult.storeDismissed;
    }

    return completer.future;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final pendingProductId = _pendingProductId;
      // consume/ack는 서버 전담. 클라이언트는 completePurchase 호출하지 않음.
      if (pendingProductId == null || purchase.productID != pendingProductId) {
        continue;
      }

      // 스토어가 응답했으면 resume grace 영구 차단(verify 중 dismiss 방지).
      _purchaseUpdateReceived = true;
      _cancelResumeGrace();

      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _failPending(IapPurchaseResult.storeDismissed);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final accessToken = _pendingAccessToken;
        final purchaseToken = _purchaseTokenOf(purchase);
        if (accessToken == null || accessToken.isEmpty) {
          _failPending(IapPurchaseResult.storeDismissed);
          continue;
        }

        try {
          final verify = await SudaApiClient.verifyPurchase(
            accessToken: accessToken,
            purchaseToken: purchaseToken,
            productId: purchase.productID,
          );
          if (!verify.isSuccess) {
            _failPending(IapPurchaseResult.verifyFailed);
          } else {
            _completePending(
              IapPurchaseResult.success(pendingApproval: verify.isPending),
            );
          }
        } catch (e, st) {
          debugPrint('[DEBUG] IapPurchaseService verify failed: $e\n$st');
          _failPending(IapPurchaseResult.verifyFailed);
        }
      }
    }
  }

  String _purchaseTokenOf(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseToken;
    }
    return purchase.verificationData.serverVerificationData;
  }

  void _completePending(IapPurchaseResult result) {
    final completer = _pending;
    _clearPending();
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

  bool get isSuccess => outcome == IapPurchaseOutcome.success;
}
