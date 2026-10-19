import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/iap_purchase_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/full_screen_route.dart';
import '../../utils/paywall_impression_screen.dart';
import '../../utils/sub_screen_route.dart';
import '../webview_screen.dart';
import 'paywall_completed.dart';

/// Premium 구독 Paywall (Full Screen).
///
/// 진입: 에너지 팝업 Go Premium / Lab 등에서 [PaywallScreen.push].
/// 결제 성공 → [PaywallCompletedScreen] → pop(true).
/// Play/`pendingYn` 승인대기 → 토스트 후 화면 유지. `successYn=N` → 실패 토스트·유지.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.screen, this.visualType = 1});

  /// Paywall mount 통계용 screen (`PaywallImpressionScreen`).
  final String screen;

  /// 1·2·3. [push]가 로컬에서 1→2→3→1로 넘긴 값.
  final int visualType;

  static const String routeName = '/paywall';
  static const _visualTypeKey = 'paywall_visual_type';

  /// 다음에 보여줄 type. 없으면 1. 읽고 나서 1→2→3→1.
  static Future<int> _takeVisualType() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_visualTypeKey) ?? 1;
    final type = stored >= 1 && stored <= 3 ? stored : 1;
    await prefs.setInt(_visualTypeKey, type == 3 ? 1 : type + 1);
    return type;
  }

  /// `true` = 구독 성공(에너지 팝업에서 Go Premium 숨김·detail 재조회).
  static Future<T?> push<T>(
    BuildContext context, {
    required String screen,
  }) async {
    final visualType = await _takeVisualType();
    if (!context.mounted) return null;
    return Navigator.of(context).push<T>(
      FullScreenRoute<T>(
        page: PaywallScreen(screen: screen, visualType: visualType),
        transition: FullScreenTransition.bottomUp,
        settings: const RouteSettings(name: routeName),
      ),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum _PaywallPlan { annual, monthly }

/// type 2·3 glow. 원 크기는 type 1 청록 glow와 같음.
class _PaywallGlow {
  const _PaywallGlow({
    required this.leftRatio,
    required this.topRatio,
    required this.color,
  });

  final double leftRatio;
  final double topRatio;
  final Color color;

  static const widthRatio = 478 / 440;
  static const heightWidthRatio = 521 / 440;
  static const blurSigma = 50.0;
  static const opacity = 0.39;
}

class _PaywallVisual {
  const _PaywallVisual({
    required this.bgTop,
    required this.bgBottom,
    required this.characterAsset,
    required this.characterAspect,
    this.characterRightOverflow = 0.05,
    this.glows = const [],
  });

  final Color bgTop;
  final Color bgBottom;
  final String characterAsset;
  final double characterAspect;

  /// 화면 너비 대비 오른쪽 삐져나감. type3은 0.
  final double characterRightOverflow;
  final List<_PaywallGlow> glows;

  static const type1 = _PaywallVisual(
    bgTop: Color(0xFF8A38F5),
    bgBottom: Color(0xFF80D7CF),
    characterAsset: 'assets/images/icons/paywall_character.png',
    characterAspect: 1096 / 804,
  );

  static const type2 = _PaywallVisual(
    bgTop: Color(0xFF80D7CF),
    bgBottom: Color(0xFF8A38F5),
    characterAsset: 'assets/images/icons/paywall_character2.png',
    characterAspect: 1181 / 756,
    glows: [
      _PaywallGlow(
        leftRatio: -239 / 440,
        topRatio: 620 / 956,
        color: Color(0xFF04E7E2),
      ),
      _PaywallGlow(
        leftRatio: 180 / 440,
        topRatio: 280 / 956,
        color: Color(0xFFF8F2FF),
      ),
    ],
  );

  static const type3 = _PaywallVisual(
    bgTop: Color(0xFFAD38F5),
    bgBottom: Color(0xFFFFD6F1),
    characterAsset: 'assets/images/icons/paywall_character3.png',
    characterAspect: 1194 / 840,
    characterRightOverflow: 0,
    glows: [
      _PaywallGlow(
        leftRatio: -40 / 440,
        topRatio: 280 / 956,
        color: Color(0xFF04E7E2),
      ),
      _PaywallGlow(
        leftRatio: -239 / 440,
        topRatio: 250 / 956,
        color: Color(0xFFF8F2FF),
      ),
    ],
  );

  static _PaywallVisual of(int type) {
    switch (type) {
      case 2:
        return type2;
      case 3:
        return type3;
      default:
        return type1;
    }
  }
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const _font = 'ChironHeiHK';
  static const _heroToPremiumGapWidthRatio = 0.08;
  static const _heroWidthRatio = 0.70;
  static const _characterWidthRatio = 0.45;

  /// 배경 보라 glow (PaywallCompleted와 동일: 부모 size 대비 반응형 + blur 고정).
  static const _purpleGlowWidthRatio = 1.086;
  static const _purpleGlowHeightRatio = 0.707;
  static const _purpleGlowLeftRatio = -0.355;
  static const _purpleGlowTopRatio = -0.004;
  static const _purpleGlowColor = Color(0xFFAB6AFF);
  static const _purpleGlowOpacity = 0.57;
  static const _purpleGlowBlurSigma = 88.7;

  /// 배경 청록 glow (Figma 440×956 기준).
  static const _glowLeftRatio = 100 / 440;
  static const _glowTopRatio = 600 / 956;
  static const _glowWidthRatio = 478 / 440;
  static const _glowHeightWidthRatio = 521 / 440;
  static const _glowColor = Color(0xFF04E7E2);
  static const _glowBlurSigma = 50.0;

  static const _premiumCard = Color(0xFF48069D);
  static const _premiumCardTopInset = 10.0;

  /// Figma 콘텐츠 392 대비 카드 299.
  static const _premiumCardWidthRatio = 0.763;

  /// 뱃지 크기 = 카드 폭 * 0.11.
  static const _premiumBadgeSizeRatio = 0.11;

  /// 뱃지 왼쪽 오버행(카드 폭 기준): 2.3%
  static const _premiumBadgeLeftOverhangRatio = 0.023;

  /// 뱃지 위쪽 오버행(카드 폭 기준): 1.34%
  static const _premiumBadgeTopOverhangWidthRatio = 0.0134;
  static const _premiumBadgeOutlineWidth = 1.5;
  static const _premiumBadgeOutlineGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF51218F), Color(0xFF8A38F5)],
  );
  static const _premiumBadgeShadow = BoxShadow(
    // Figma는 25%(0x40). 어두운 PREMIUM 카드 위에서 거의 안 보여 33%로 가시성만 보정.
    color: Color(0x54000000),
    offset: Offset(0, 4),
    blurRadius: 4,
    spreadRadius: 0,
  );
  static const _planTitle = Color(0xFF2A0060);
  static const _yearPrice = Color(0xFF80D7CF);
  static const _legal = Color(0xFF054544);

  static const _cardShadow = BoxShadow(
    color: Color(0x4D000000),
    offset: Offset(20, 20),
    blurRadius: 20,
    spreadRadius: 0,
  );

  /// 플랜 카드 전용 soft drop (glow 위에서도 또렷하게).
  static const _planCardShadow = BoxShadow(
    color: Color(0x66000000), // #000000 40%
    offset: Offset(0, 8),
    blurRadius: 12,
    spreadRadius: 0,
  );

  _PaywallVisual get _visual => _PaywallVisual.of(widget.visualType);

  _PaywallPlan _selected = _PaywallPlan.annual;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _restoreRecognizer;
  PremiumSubscriptionPrices? _prices;
  bool _purchasing = false;
  bool _presentingCompleted = false;
  String? _paywallSessionId;

  bool get _subscribeLocked {
    if (_purchasing) return true;
    final basePlanId = _selected == _PaywallPlan.annual
        ? IapPurchaseService.basePlanYearly
        : IapPurchaseService.basePlanMonthly;
    return IapPurchaseService.instance.isSubscriptionPurchaseBlocked(
      basePlanId: basePlanId,
    );
  }

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
    _restoreRecognizer = TapGestureRecognizer()
      ..onTap = () {
        unawaited(_onRestoreTap());
      };
    IapPurchaseService.instance.uiListenable.addListener(_onIapUi);
    IapPurchaseService.instance.userNotice.addListener(_onIapNotice);
    unawaited(_loadPrices());
    unawaited(_initPaywallSession());
  }

  @override
  void dispose() {
    IapPurchaseService.instance.uiListenable.removeListener(_onIapUi);
    IapPurchaseService.instance.userNotice.removeListener(_onIapNotice);
    if (_purchasing) {
      IapPurchaseService.instance.abandonPendingPurchase();
    }
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _restoreRecognizer.dispose();
    super.dispose();
  }

  void _onIapUi() {
    if (mounted) setState(() {});
  }

  void _onIapNotice() {
    final notice = IapPurchaseService.instance.userNotice.value;
    if (notice == null) return;
    if (notice.kind != IapPurchaseUserNoticeKind.completed) return;
    if (!IapPurchaseService.isSubscriptionProductId(notice.productId)) return;
    if (!mounted || _presentingCompleted) return;
    unawaited(_presentCompletedFlow());
  }

  Future<void> _presentCompletedFlow() async {
    if (_presentingCompleted) return;
    _presentingCompleted = true;
    IapPurchaseService.instance.markSuccessUiPresented();
    if (!mounted) return;
    await PaywallCompletedScreen.push(context);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _loadPrices() async {
    final prices = await IapPurchaseService.instance
        .loadPremiumSubscriptionPrices();
    if (!mounted) return;
    setState(() => _prices = prices);
  }

  Future<void> _initPaywallSession() async {
    if (!PaywallImpressionScreen.shouldCollect(widget.screen)) return;
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted || accessToken == null || accessToken.isEmpty) return;
      final sessionId = await SudaApiClient.openSubscriptionPaywallImpression(
        accessToken: accessToken,
        screen: widget.screen,
      );
      if (!mounted) return;
      _paywallSessionId = sessionId;
    } catch (e, st) {
      debugPrint('[DEBUG] Paywall open impression failed: $e\n$st');
    }
  }

  Future<void> _recordSubscriptionTap(String basePlanId) async {
    final sessionId = _paywallSessionId?.trim();
    if (sessionId == null || sessionId.isEmpty) return;
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      await SudaApiClient.recordSubscriptionPaywallTap(
        accessToken: accessToken,
        paywallSessionId: sessionId,
        basePlanId: basePlanId,
      );
    } catch (e, st) {
      debugPrint('[DEBUG] Paywall subscription tap impression failed: $e\n$st');
    }
  }

  String _annualPriceMain(AppLocalizations l10n) {
    final v = _prices?.yearlyFormatted;
    final amount = (v != null && v.isNotEmpty) ? v : l10n.paywallFallbackAnnual;
    return l10n.paywallPricePerYear(amount);
  }

  String _annualPriceSub(AppLocalizations l10n) {
    final v = _prices?.yearlyPerMonthFormatted;
    final amount = (v != null && v.isNotEmpty)
        ? v
        : l10n.paywallFallbackAnnualPerMonth;
    return l10n.paywallPricePerMonth(amount);
  }

  /// 월간 구독료×12 비교가 (취소선). 접미사 없음.
  String _annualPriceStrike(AppLocalizations l10n) {
    final v = _prices?.monthlyTimes12Formatted;
    if (v != null && v.isNotEmpty) return v;
    return l10n.paywallFallbackMonthlyTimes12;
  }

  String _monthlyPriceMain(AppLocalizations l10n) {
    final v = _prices?.monthlyFormatted;
    final amount = (v != null && v.isNotEmpty)
        ? v
        : l10n.paywallFallbackMonthly;
    return l10n.paywallPricePerMonth(amount);
  }

  Future<void> _onSubscribeTap() async {
    if (_subscribeLocked || IapPurchaseService.instance.isBusy) return;
    setState(() => _purchasing = true);

    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted) return;
      if (accessToken == null || accessToken.isEmpty) {
        setState(() => _purchasing = false);
        return;
      }

      final basePlanId = _selected == _PaywallPlan.annual
          ? IapPurchaseService.basePlanYearly
          : IapPurchaseService.basePlanMonthly;

      await _recordSubscriptionTap(basePlanId);

      final result = await IapPurchaseService.instance.purchaseSubscription(
        basePlanId: basePlanId,
        accessToken: accessToken,
        paywallSessionId: _paywallSessionId,
      );
      if (!mounted) return;

      if (result.isProcessing) {
        setState(() => _purchasing = false);
        return;
      }

      if (result.pendingApproval) {
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.energyPurchasePendingApproval);
        setState(() => _purchasing = false);
        return;
      }

      if (!result.isSuccess) {
        if (result.outcome == IapPurchaseOutcome.verifyFailed) {
          final l10n = AppLocalizations.of(context)!;
          DefaultToast.show(
            context,
            l10n.energyPurchaseNotCompleted,
            isError: true,
          );
        }
        setState(() => _purchasing = false);
        return;
      }

      setState(() => _purchasing = false);
      await _presentCompletedFlow();
    } catch (e, st) {
      debugPrint('[DEBUG] Paywall subscribe failed: $e\n$st');
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _onRestoreTap() async {
    if (_subscribeLocked || IapPurchaseService.instance.isBusy) return;
    setState(() => _purchasing = true);

    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted) return;
      if (accessToken == null || accessToken.isEmpty) {
        setState(() => _purchasing = false);
        return;
      }

      final result = await IapPurchaseService.instance.restorePurchases(
        accessToken: accessToken,
      );
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      if (result.outcome == IapPurchaseOutcome.nothingToRestore) {
        DefaultToast.show(context, l10n.restorePurchasesNothing);
        setState(() => _purchasing = false);
        return;
      }
      if (result.pendingApproval) {
        DefaultToast.show(context, l10n.energyPurchasePendingApproval);
        setState(() => _purchasing = false);
        return;
      }
      if (!result.isSuccess) {
        if (result.outcome == IapPurchaseOutcome.verifyFailed ||
            result.outcome == IapPurchaseOutcome.unavailable) {
          DefaultToast.show(
            context,
            l10n.energyPurchaseNotCompleted,
            isError: true,
          );
        }
        setState(() => _purchasing = false);
        return;
      }

      DefaultToast.show(context, l10n.restorePurchasesCompleted);
      try {
        await SudaApiClient.getUserEnergySimple(accessToken: accessToken);
      } catch (e, st) {
        debugPrint('[DEBUG] Paywall restore energy refresh failed: $e\n$st');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('[DEBUG] Paywall restore failed: $e\n$st');
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _openTerms() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      SubScreenRoute(
        page: WebViewScreen(
          url: 'https://sudatalk.kr/public/app/terms',
          title: l10n.settingsTerms,
        ),
      ),
    );
  }

  void _openPrivacy() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      SubScreenRoute(
        page: WebViewScreen(
          url: 'https://sudatalk.kr/public/app/privacy',
          title: l10n.settingsPrivacy,
        ),
      ),
    );
  }

  TextStyle _style({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.25,
  }) {
    final wght = weight == FontWeight.w700
        ? 700.0
        : weight == FontWeight.w600
        ? 600.0
        : 400.0;
    return TextStyle(
      fontFamily: _font,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', wght)],
      color: color,
      height: height,
      letterSpacing: -0.4,
    );
  }

  /// 가용 폭·줄 수에 맞게 base→min까지 축소. 로케일 분기 없음(좁은 기기·긴 문장 공통).
  /// [forceTokenFitBelowMin]: min에 도달해도 긴 토큰이 폭을 넘으면 [absoluteMinSize]까지 더 줄임
  /// (단어 중간 줄바꿈 방지). Paywall은 말줄임 없이 전부 보여야 함.
  double _autoFitFontSize({
    required String text,
    required TextStyle baseStyle,
    required double maxWidth,
    required TextDirection textDirection,
    required double baseSize,
    required double minSize,
    required int maxLines,
    bool requireTokensFit = true,
    bool forceTokenFitBelowMin = false,
    double? absoluteMinSize,
  }) {
    final floor = absoluteMinSize ?? minSize;
    var fontSize = baseSize;
    while (true) {
      final style = baseStyle.copyWith(fontSize: fontSize);
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        maxLines: maxLines,
      )..layout(maxWidth: maxWidth);
      final linesOk = !painter.didExceedMaxLines;
      final tokensOk =
          !requireTokensFit ||
          !_anyTokenExceedsWidth(text, style, maxWidth, textDirection);
      if (linesOk && tokensOk) return fontSize;

      final next = fontSize - 0.5;
      if (next < minSize) {
        if (forceTokenFitBelowMin &&
            requireTokensFit &&
            !tokensOk &&
            next >= floor) {
          fontSize = next;
          continue;
        }
        // min(또는 absolute floor)에서도 한 번 더 검사한 뒤 반환.
        if (fontSize > minSize) {
          fontSize = minSize;
          continue;
        }
        if (forceTokenFitBelowMin && fontSize > floor) {
          fontSize = floor;
          continue;
        }
        return fontSize;
      }
      fontSize = next;
    }
  }

  bool _anyTokenExceedsWidth(
    String text,
    TextStyle style,
    double maxWidth,
    TextDirection textDirection,
  ) {
    for (final line in text.split('\n')) {
      for (final token in line.split(RegExp(r'\s+'))) {
        if (token.isEmpty) continue;
        final painter = TextPainter(
          text: TextSpan(text: token, style: style),
          textDirection: textDirection,
          maxLines: 1,
        )..layout();
        if (painter.width > maxWidth) return true;
      }
    }
    return false;
  }

  /// 폭 제한 없이 한 줄 실측. 줄바꿈으로 끝 음절이 사라지는 판정을 피한다.
  double _singleLineWidth({
    required String text,
    required TextStyle style,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    return painter.width;
  }

  /// arb `\n`은 2줄 필요할 때만 적용. 1줄에 들어가면 공백으로 이어 붙여 표시.
  ({String displayText, double fontSize}) _resolveSoftBreakHeroTitle({
    required String textWithBreaks,
    required TextStyle baseStyle,
    required double maxWidth,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required double baseSize,
    required double minSize,
    required int maxLinesWhenBroken,
    double? absoluteMinSize,
  }) {
    final singleLine = textWithBreaks.replaceAll('\n', ' ');
    final styleBase = baseStyle.copyWith(
      height: 1.35,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final floor = absoluteMinSize ?? minSize;

    var fontSize = baseSize;
    while (fontSize >= minSize) {
      final style = styleBase.copyWith(fontSize: fontSize);
      final fits =
          _singleLineWidth(
            text: singleLine,
            style: style,
            textDirection: textDirection,
            textScaler: textScaler,
          ) <=
          maxWidth;
      if (fits &&
          !_anyTokenExceedsWidth(singleLine, style, maxWidth, textDirection)) {
        return (displayText: singleLine, fontSize: fontSize);
      }
      fontSize -= 0.5;
    }

    final fittedSize = _autoFitFontSize(
      text: textWithBreaks,
      baseStyle: styleBase,
      maxWidth: maxWidth,
      textDirection: textDirection,
      baseSize: baseSize,
      minSize: minSize,
      maxLines: maxLinesWhenBroken,
      forceTokenFitBelowMin: true,
      absoluteMinSize: floor,
    );
    return (displayText: textWithBreaks, fontSize: fittedSize);
  }

  Widget _gradientText({
    required String text,
    required TextStyle style,
    required Gradient gradient,
    TextAlign align = TextAlign.start,
    List<Shadow>? shadows,
    double? minFontSize,
    int maxLines = 2,
    bool softLineBreak = false,
  }) {
    // ShaderMask는 레이어 클립으로 글리프 하단이 잘리므로,
    // TextStyle.foreground 셰이더로 그린다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final baseSize = style.fontSize ?? 32;
        final minSize = minFontSize ?? baseSize;
        final absoluteFloor = minFontSize != null
            ? (minFontSize - 4).clamp(20.0, minFontSize)
            : baseSize;
        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);
        final styleBase = style.copyWith(
          height: 1.35,
          leadingDistribution: TextLeadingDistribution.even,
        );

        late final String displayText;
        late final double fittedSize;
        if (softLineBreak && text.contains('\n')) {
          final resolved = _resolveSoftBreakHeroTitle(
            textWithBreaks: text,
            baseStyle: style,
            maxWidth: maxWidth,
            textDirection: textDirection,
            textScaler: textScaler,
            baseSize: baseSize,
            minSize: minSize,
            maxLinesWhenBroken: maxLines,
            absoluteMinSize: absoluteFloor,
          );
          displayText = resolved.displayText;
          fittedSize = resolved.fontSize;
        } else {
          displayText = text;
          fittedSize = minSize < baseSize
              ? _autoFitFontSize(
                  text: text,
                  baseStyle: styleBase,
                  maxWidth: maxWidth,
                  textDirection: textDirection,
                  baseSize: baseSize,
                  minSize: minSize,
                  maxLines: maxLines,
                  forceTokenFitBelowMin: true,
                  absoluteMinSize: absoluteFloor,
                )
              : baseSize;
        }

        final textStyle = styleBase.copyWith(fontSize: fittedSize);
        final oneLine = !displayText.contains('\n');
        final displayMaxLines = oneLine ? 1 : maxLines;
        final painter = TextPainter(
          text: TextSpan(text: displayText, style: textStyle),
          textAlign: align,
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: displayMaxLines,
        );
        if (oneLine) {
          painter.layout();
        } else {
          painter.layout(maxWidth: maxWidth);
        }
        final shaderWidth = align == TextAlign.center ? maxWidth : painter.width;
        final shader = gradient.createShader(
          Rect.fromLTWH(0, 0, shaderWidth, painter.height),
        );
        return Text(
          displayText,
          textAlign: align,
          maxLines: displayMaxLines,
          softWrap: !oneLine,
          overflow: TextOverflow.visible,
          style: textStyle.copyWith(
            foreground: Paint()..shader = shader,
            shadows: shadows,
          ),
        );
      },
    );
  }

  Widget _variantGlow(Size size, _PaywallGlow glow) {
    const blur = _PaywallGlow.blurSigma;
    return Positioned(
      left: size.width * glow.leftRatio - blur * 2,
      top: size.height * glow.topRatio - blur * 2,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.decal,
            ),
            child: Padding(
              padding: const EdgeInsets.all(blur * 2),
              child: Opacity(
                opacity: _PaywallGlow.opacity,
                child: Container(
                  width: size.width * _PaywallGlow.widthRatio,
                  height: size.width * _PaywallGlow.heightWidthRatio,
                  decoration: BoxDecoration(
                    color: glow.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final characterWidth = size.width * _characterWidthRatio;
    final characterHeight = characterWidth * _visual.characterAspect;
    // X는 상태바 아래 안전영역에 고정한다.
    const closeTop = 8.0;
    const closeButtonSize = 44.0;
    const contentPaddingTop = 8.0;
    const heroInnerTop = 12.0;
    const closeToTextMinGap = 8.0;
    const headerBandTop = 0.0;
    final baseHeroTopGap = (12 + (size.height * 0.01)) * 0.8;
    final minHeroTopGap =
        (topPad + closeTop + closeButtonSize + closeToTextMinGap) -
        (headerBandTop + closeButtonSize + contentPaddingTop + heroInnerTop);
    final heroTopGap = baseHeroTopGap < minHeroTopGap
        ? minHeroTopGap
        : baseHeroTopGap;

    return Scaffold(
      backgroundColor: _visual.bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_visual.bgTop, _visual.bgBottom],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_visual.glows.isEmpty) ...[
              // 그라디언트 위 · 콘텐츠 아래 보라 glow (캐릭터/그림자 clip 방지를 위해 이 레이어만 ClipRect)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left:
                              size.width * _purpleGlowLeftRatio -
                              _purpleGlowBlurSigma * 2,
                          top:
                              size.height * _purpleGlowTopRatio -
                              _purpleGlowBlurSigma * 2,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _purpleGlowBlurSigma,
                              sigmaY: _purpleGlowBlurSigma,
                              tileMode: TileMode.decal,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                _purpleGlowBlurSigma * 2,
                              ),
                              child: Opacity(
                                opacity: _purpleGlowOpacity,
                                child: Container(
                                  width: size.width * _purpleGlowWidthRatio,
                                  height: size.height * _purpleGlowHeightRatio,
                                  decoration: const BoxDecoration(
                                    color: _purpleGlowColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // "Escolha seu plano" 근처 좌측 청록 glow
              Positioned(
                left: size.width * _glowLeftRatio - _glowBlurSigma * 2,
                top: size.height * _glowTopRatio - _glowBlurSigma * 2,
                child: IgnorePointer(
                  // ImageFiltered를 별 레이어로 분리해야 형제 위젯 boxShadow가 합성에서 살아남음.
                  child: RepaintBoundary(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _glowBlurSigma,
                        sigmaY: _glowBlurSigma,
                        tileMode: TileMode.decal,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(_glowBlurSigma * 2),
                        child: Container(
                          width: size.width * _glowWidthRatio,
                          height: size.width * _glowHeightWidthRatio,
                          decoration: const BoxDecoration(
                            color: _glowColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              for (final glow in _visual.glows) _variantGlow(size, glow),
            SingleChildScrollView(
              clipBehavior: Clip.none,
              padding: EdgeInsets.only(bottom: bottomPad + 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: headerBandTop),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 44),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: heroTopGap),
                                    _buildHeroPremiumSection(size),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          PositionedDirectional(
                            start: 8,
                            top: topPad + closeTop,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.028),
                      _buildPlanDivider(),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAnnualPlan(),
                            const SizedBox(height: 12),
                            _buildMonthlyPlan(),
                            SizedBox(height: size.height * 0.028),
                            _buildCta(),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.paywallAutoRenewNotice,
                              textAlign: TextAlign.center,
                              style: _style(
                                size: 12,
                                color: _legal,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                style: _style(size: 10, color: _legal),
                                children: [
                                  TextSpan(
                                    text: AppLocalizations.of(
                                      context,
                                    )!.settingsTerms,
                                    style: _style(size: 10, color: _legal)
                                        .copyWith(
                                          decoration: TextDecoration.underline,
                                          decorationColor: _legal,
                                        ),
                                    recognizer: _termsRecognizer,
                                  ),
                                  const TextSpan(text: '  •  '),
                                  TextSpan(
                                    text: AppLocalizations.of(
                                      context,
                                    )!.settingsPrivacy,
                                    style: _style(size: 10, color: _legal)
                                        .copyWith(
                                          decoration: TextDecoration.underline,
                                          decorationColor: _legal,
                                        ),
                                    recognizer: _privacyRecognizer,
                                  ),
                                  if (!kIsWeb && Platform.isIOS) ...[
                                    const TextSpan(text: '  •  '),
                                    TextSpan(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.settingsRestorePurchases,
                                      style: _style(size: 10, color: _legal)
                                          .copyWith(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: _legal,
                                          ),
                                      recognizer: _restoreRecognizer,
                                    ),
                                  ],
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _characterLayer(
                    size,
                    characterWidth,
                    characterHeight,
                    topPad,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _characterLayer(
    Size size,
    double characterWidth,
    double characterHeight,
    double top,
  ) {
    return Positioned(
      right: -size.width * _visual.characterRightOverflow,
      top: top,
      child: IgnorePointer(
        child: Image.asset(
          _visual.characterAsset,
          width: characterWidth,
          height: characterHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHeroPremiumSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: size.width * _heroWidthRatio,
            child: _buildHero(),
          ),
        ),
        SizedBox(height: size.width * _heroToPremiumGapWidthRatio),
        _buildPremiumCard(),
      ],
    );
  }

  Widget _buildHero() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.paywallHeroTitle1,
            textAlign: TextAlign.center,
            style: _style(
              size: 20,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          _gradientText(
            text: l10n.paywallHeroTitle2,
            align: TextAlign.center,
            style: _style(size: 32, weight: FontWeight.w700),
            // `\n`은 2줄 필요할 때만 적용. 1줄에 들어가면 줄바꿈 없음.
            softLineBreak: true,
            minFontSize: 26,
            maxLines: 2,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A003D), Color(0xFF742AD5)],
            ),
          ),
          const SizedBox(height: 10),
          _buildHeroBody(l10n.paywallHeroBody),
        ],
      ),
    );
  }

  /// 히어로 본문: 기본 14px, 가능하면 3줄 안에 맞춤. 말줄임 없음(세로로 늘어나도 전부 표시).
  Widget _buildHeroBody(String text) {
    const preferredMaxLines = 3;
    const baseSize = 14.0;
    const minSize = 12.5;
    const lineHeight = 1.35;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final textDirection = Directionality.of(context);
        final baseStyle = _style(
          size: baseSize,
          color: Colors.white,
          height: lineHeight,
        );
        final fontSize = _autoFitFontSize(
          text: text,
          baseStyle: baseStyle,
          maxWidth: maxWidth,
          textDirection: textDirection,
          baseSize: baseSize,
          minSize: minSize,
          maxLines: preferredMaxLines,
          requireTokensFit: false,
        );
        final fittedStyle = baseStyle.copyWith(fontSize: fontSize);

        return Text(
          text,
          textAlign: TextAlign.center,
          // 줄 수 제한 없음 → 공간 부족 시 아래로 늘어나며 전부 표시.
          overflow: TextOverflow.visible,
          style: fittedStyle,
        );
      },
    );
  }

  Widget _buildPremiumCard() {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Figma: 콘텐츠 폭 392 대비 카드 폭 299 → 0.763, 가운데 정렬.
        final contentWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;
        final cardWidth = contentWidth * _premiumCardWidthRatio;
        final badgeSize = cardWidth * _premiumBadgeSizeRatio;
        // Figma 실측 오버행 기준: 좌 2.3%, 상 1.34%(둘 다 카드폭 기준).
        final badgeLeft = -(cardWidth * _premiumBadgeLeftOverhangRatio);
        final badgeTop =
            _premiumCardTopInset -
            (cardWidth * _premiumBadgeTopOverhangWidthRatio);

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cardWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(top: _premiumCardTopInset),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                  decoration: BoxDecoration(
                    color: _premiumCard,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [_cardShadow],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.paywallPremiumLabel,
                        style: _style(
                          size: 20,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _premiumRow(l10n.paywallBenefitMaxEnergy),
                      const SizedBox(height: 10),
                      _premiumRow(l10n.paywallBenefitAiFeedback),
                      const SizedBox(height: 10),
                      _premiumRow(l10n.paywallBenefitProfileBadge),
                    ],
                  ),
                ),
                // 뱃지를 카드 위에 그려 그림자가 카드/배경에 보이도록 함.
                // Stack clipBehavior: Clip.none (잘림 없음).
                Positioned(
                  left: badgeLeft,
                  top: badgeTop,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _premiumBadgeOutlineGradient,
                      boxShadow: [_premiumBadgeShadow],
                    ),
                    // inside stroke: 그라데이션 원 위에 안쪽 inset으로 이미지.
                    child: Padding(
                      padding: const EdgeInsets.all(_premiumBadgeOutlineWidth),
                      child: ClipOval(
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/icons/paywall_star_badge.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _premiumRow(String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Image.asset(
            'assets/images/icons/paywall_check_Icon.png',
            width: 18,
            height: 18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const preferredMaxLines = 1;
              const baseSize = 16.0;
              const minSize = 14.0;
              final maxWidth = constraints.maxWidth;
              final textDirection = Directionality.of(context);
              final baseStyle = _style(size: baseSize, color: Colors.white);
              final fontSize = _autoFitFontSize(
                text: label,
                baseStyle: baseStyle,
                maxWidth: maxWidth,
                textDirection: textDirection,
                baseSize: baseSize,
                minSize: minSize,
                maxLines: preferredMaxLines,
              );
              final style = baseStyle.copyWith(fontSize: fontSize);
              final oneLinePainter = TextPainter(
                text: TextSpan(text: label, style: style),
                textDirection: textDirection,
                maxLines: 1,
              )..layout(maxWidth: maxWidth);
              // 1줄 불가해도 말줄임/fade 없이 줄바꿈해 전부 표시.
              final fitsOneLine =
                  !oneLinePainter.didExceedMaxLines &&
                  !_anyTokenExceedsWidth(label, style, maxWidth, textDirection);

              return Text(
                label,
                maxLines: fitsOneLine ? 1 : null,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: style,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDivider() {
    const lineColor = Color(0x80816CE8);
    const lineThickness = 1.0;
    const lineGap = 3.0;
    const lineRadius = 20.0;

    Widget roundedLine() {
      return Container(
        height: lineThickness,
        width: double.infinity,
        decoration: BoxDecoration(
          color: lineColor,
          borderRadius: BorderRadius.circular(lineRadius),
        ),
      );
    }

    Widget doubleLine() {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            roundedLine(),
            const SizedBox(height: lineGap),
            roundedLine(),
          ],
        ),
      );
    }

    // 좌우 Expanded 동일 → 텍스트 화면 중앙, 선은 화면 가장자리까지.
    return Row(
      children: [
        doubleLine(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppLocalizations.of(context)!.paywallChoosePlan,
            style: _style(size: 16, color: Colors.white),
          ),
        ),
        doubleLine(),
      ],
    );
  }

  Widget _buildAnnualPlan() {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected == _PaywallPlan.annual;
    return _planCard(
      selected: selected,
      onTap: _subscribeLocked
          ? () {}
          : () => setState(() => _selected = _PaywallPlan.annual),
      title: l10n.paywallAnnualPlanTitle,
      subtitle: l10n.paywallAnnualPlanSubtitle,
      priceMain: _annualPriceMain(l10n),
      priceSub: _annualPriceSub(l10n),
      priceStrike: _annualPriceStrike(l10n),
      showMelhorBadge: true,
    );
  }

  Widget _buildMonthlyPlan() {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected == _PaywallPlan.monthly;
    return _planCard(
      selected: selected,
      onTap: _subscribeLocked
          ? () {}
          : () => setState(() => _selected = _PaywallPlan.monthly),
      title: l10n.paywallMonthlyPlanTitle,
      subtitle: l10n.paywallMonthlyPlanSubtitle,
      priceMain: _monthlyPriceMain(l10n),
    );
  }

  static const _melhorGlyphShadow = Shadow(
    color: Color(0x45000000), // #000000 27%
    offset: Offset(0, 4),
    blurRadius: 4,
  );

  Widget _melhorBadge() {
    const strokeWidth = 2.0;
    const radius = 24.0;
    // Outside stroke가 bounds 밖으로 그려지므로 padding으로 확보.
    return Padding(
      padding: const EdgeInsets.all(strokeWidth),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.038),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x78000000),
                              offset: Offset(0, 4),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/icons/paywall_small_star.png',
                          width: 12,
                          height: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _gradientText(
                        text: AppLocalizations.of(context)!.paywallBestBadge,
                        style: _style(
                          size: 14,
                          weight: FontWeight.w700,
                        ).copyWith(letterSpacing: 14 * -0.01),
                        shadows: const [_melhorGlyphShadow],
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFFFD8A4)],
                          stops: [0.0, 0.65],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _MelhorBadgeStrokePainter(
                  strokeWidth: strokeWidth,
                  radius: radius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String priceMain,
    String? priceSub,
    String? priceStrike,
    bool showMelhorBadge = false,
  }) {
    final radius = BorderRadius.circular(16);
    // 선택/미선택 모두 outside stroke → 안쪽 콘텐츠 크기 고정(탭 시 밀림 방지).
    const selectedBorderWidth = 3.0;
    const unselectedBorderWidth = 1.0;
    final strokeWidth = selected ? selectedBorderWidth : unselectedBorderWidth;
    // 그림자는 Material/Ink 바깥에 둬 clip에 잘리지 않게 함.
    final cardBody = Ink(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF0CABA8), Color(0xFF8A38F5)],
              )
            : const LinearGradient(
                colors: [Color(0x4D8A38F5), Color(0x4D8A38F5)],
              ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, showMelhorBadge ? 26 : 14, 14, 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: showMelhorBadge
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        selected
                            ? 'assets/images/icons/paywall_radio_selected.png'
                            : 'assets/images/icons/paywall_radio_unselected.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: _style(
                                size: 20,
                                weight: FontWeight.w700,
                                color: _planTitle,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: _style(
                                size: 14,
                                color: _planTitle.withValues(alpha: 0.85),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: showMelhorBadge
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (priceStrike != null) ...[
                      Text(
                        priceStrike,
                        style: _style(size: 15, color: _yearPrice).copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: _yearPrice,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      priceMain,
                      style: _style(
                        size: 20,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (priceSub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        priceSub,
                        style: _style(size: 15, color: _yearPrice),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final painted = CustomPaint(
      foregroundPainter: _PlanCardOutsideStrokePainter(
        strokeWidth: strokeWidth,
        radius: 16,
        // 선택: 흰 80% solid / 미선택: 기존 gradient
        color: selected ? const Color(0xCCFFFFFF) : null,
        gradient: selected
            ? null
            : _PlanCardOutsideStrokePainter.unselectedStrokeGradient,
      ),
      child: cardBody,
    );

    // BEST 뱃지는 ClipRRect 밖 Stack에 두고 top border와 겹치게 함.
    final cardWithBadge = showMelhorBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              painted,
              Positioned(left: 10, top: -16, child: _melhorBadge()),
            ],
          )
        : painted;

    // 그림자는 Material/Ink 바깥. (카드에 RepaintBoundary 금지 — soft shadow overflow가 잘림)
    // 연간 뱃지 overhang을 위해 상단 여백.
    return Padding(
      padding: EdgeInsets.only(top: showMelhorBadge ? 16 : 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [_planCardShadow],
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.none,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: cardWithBadge,
          ),
        ),
      ),
    );
  }

  Widget _buildCta() {
    return Center(
      child: IntrinsicWidth(
        child: Opacity(
          opacity: _subscribeLocked ? 0.7 : 1,
          child: GestureDetector(
            onTap: _subscribeLocked ? null : () => unawaited(_onSubscribeTap()),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xC98A38F5), Color(0xC9280752)],
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.paywallCta,
                  style: _style(
                    size: 18,
                    weight: FontWeight.w700,
                    color: Colors.white,
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

/// MELHOR 뱃지 outside stroke: Figma 각도형 #FFFFFF 하이라이트 유지 + 전 둘레 연속.
/// (0% 투명 구간을 두면 오른쪽 끝이 잘린 것처럼 보이므로 최소 투명도 floor 적용)
class _MelhorBadgeStrokePainter extends CustomPainter {
  const _MelhorBadgeStrokePainter({
    required this.strokeWidth,
    required this.radius,
  });

  final double strokeWidth;
  final double radius;

  static const _white31 = Color(0x4FFFFFFF); // #FFFFFF 31%
  static const _whiteSoft = Color(0x28FFFFFF); // #FFFFFF 약 16% — 끊김 방지 floor

  /// Figma 중지점 13·37·62·87% (+ 루프 seam). 어두운 구간도 soft로 유지해 둘레가 이어짐.
  static const _sweep = SweepGradient(
    startAngle: -1.5707963267948966, // -90° (Figma 각도형 0° ≈ 상단)
    colors: [
      _whiteSoft,
      _white31,
      _whiteSoft,
      _white31,
      _whiteSoft,
      _whiteSoft,
    ],
    stops: [0.0, 0.13, 0.37, 0.62, 0.87, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      half,
      half,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round
      ..shader = _sweep.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _MelhorBadgeStrokePainter oldDelegate) =>
      strokeWidth != oldDelegate.strokeWidth || radius != oldDelegate.radius;
}

/// 플랜 카드 outside stroke (선택/미선택 공통).
/// 내부 fill에 경계색이 번지지 않도록 테두리를 바깥쪽으로만 그린다.
class _PlanCardOutsideStrokePainter extends CustomPainter {
  const _PlanCardOutsideStrokePainter({
    required this.strokeWidth,
    required this.radius,
    this.color,
    this.gradient,
  });

  final double strokeWidth;
  final double radius;
  final Color? color;
  final Gradient? gradient;

  static const unselectedStrokeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      -half,
      -half,
      size.width + strokeWidth,
      size.height + strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius + half));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else if (color != null) {
      paint.color = color!;
    }
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PlanCardOutsideStrokePainter oldDelegate) =>
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius ||
      color != oldDelegate.color ||
      gradient != oldDelegate.gradient;
}
