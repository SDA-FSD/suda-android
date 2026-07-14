import 'package:flutter/material.dart';

import '../../utils/full_screen_route.dart';

/// Premium 구독 Paywall (Full Screen, UI only).
///
/// 진입: Lab 등에서 [PaywallScreen.push] 사용 (bottom-up 450ms).
/// X = pop / Assinar agora·약관 = no-op. 플랜 선택은 로컬 UI 상태만.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static const String routeName = '/paywall';

  static Future<T?> push<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      FullScreenRoute<T>(
        page: const PaywallScreen(),
        transition: FullScreenTransition.bottomUp,
        settings: const RouteSettings(name: routeName),
      ),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum _PaywallPlan { annual, monthly }

class _PaywallScreenState extends State<PaywallScreen> {
  static const _font = 'ChironHeiHK';
  static const _bgTop = Color(0xFF8A38F5);
  static const _bgBottom = Color(0xFF80D7CF);
  static const _heroToPremiumGapWidthRatio = 0.08;
  /// 캐릭터 너비(화면 대비). 0.56에서 소폭 축소.
  static const _heroCharacterWidthRatio = 0.50;
  /// 값이 커질수록 왼쪽으로 이동(음수면 화면 우측으로 더 삐져나감).
  static const _heroCharacterRightRatio = -0.03;
  /// 에셋 804×1096.
  static const _heroCharacterAspect = 1096 / 804;
  /// top↑ = 캐릭터↓. 신발 끝이 PREMIUM 카드 안쪽까지 겹치도록 내림.
  static const _heroCharacterTopDropRatio = 0.21;
  /// 캐릭터 높이 중 카드 위로 남길(겹칠) 발 영역 비율.
  static const _heroCharacterFootOverlapRatio = 0.08;
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
  static const _accentPurple = Color(0xFF8A38F5);

  static const _cardShadow = BoxShadow(
    color: Color(0x4D000000),
    offset: Offset(20, 20),
    blurRadius: 20,
    spreadRadius: 0,
  );
  static const _selectedPlanShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
    spreadRadius: 0,
  );

  _PaywallPlan _selected = _PaywallPlan.annual;
  final GlobalKey _heroStackKey = GlobalKey();
  final GlobalKey _premiumCardKey = GlobalKey();
  double? _premiumCardTopInStack;

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

  Widget _gradientText({
    required String text,
    required TextStyle style,
    required Gradient gradient,
    TextAlign align = TextAlign.start,
    List<Shadow>? shadows,
  }) {
    // ShaderMask는 레이어 클립으로 글리프 하단이 잘리므로,
    // TextStyle.foreground 셰이더로 그린다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = style.copyWith(
          height: 1.35,
          leadingDistribution: TextLeadingDistribution.even,
        );
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final painter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textAlign: align,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxWidth);
        final shader = gradient.createShader(
          Rect.fromLTWH(0, 0, painter.width, painter.height),
        );
        return Text(
          text,
          textAlign: align,
          overflow: TextOverflow.visible,
          style: textStyle.copyWith(
            foreground: Paint()..shader = shader,
            shadows: shadows,
          ),
        );
      },
    );
  }

  void _measurePremiumCardTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stackContext = _heroStackKey.currentContext;
      final cardContext = _premiumCardKey.currentContext;
      if (stackContext == null || cardContext == null) return;

      final stackBox = stackContext.findRenderObject() as RenderBox?;
      final cardBox = cardContext.findRenderObject() as RenderBox?;
      if (stackBox == null || cardBox == null) return;

      final cardTop = cardBox.localToGlobal(
        Offset.zero,
        ancestor: stackBox,
      ).dy;
      final current = _premiumCardTopInStack;
      if (current == null || (current - cardTop).abs() > 0.5) {
        setState(() => _premiumCardTopInStack = cardTop);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final characterWidth = size.width * _heroCharacterWidthRatio;
    final characterHeight = characterWidth * _heroCharacterAspect;
    // X는 상태바 아래 안전영역에 고정한다.
    const closeTop = 8.0;
    const closeButtonSize = 44.0;
    const contentPaddingTop = 8.0;
    const heroInnerTop = 12.0;
    const closeToTextMinGap = 8.0;
    const headerBandTop = 0.0;
    final baseHeroTopGap = (12 + (size.height * 0.01)) * 0.8;
    final minHeroTopGap = (topPad + closeTop + closeButtonSize + closeToTextMinGap) -
        (headerBandTop + closeButtonSize + contentPaddingTop + heroInnerTop);
    final heroTopGap = baseHeroTopGap < minHeroTopGap
        ? minHeroTopGap
        : baseHeroTopGap;
    final overlapHeight = characterHeight * _heroCharacterFootOverlapRatio;
    // 카드 실측 top에 종속: 캐릭터 발이 카드 상단에 살짝 겹치도록.
    final characterTop = _premiumCardTopInStack != null
        ? _premiumCardTopInStack! - (characterHeight - overlapHeight)
        // 초기 1프레임 fallback (측정 전): 기존 대비 과도한 점프 방지용.
        : (closeButtonSize + contentPaddingTop + heroTopGap) +
            (characterHeight * _heroCharacterTopDropRatio);

    _measurePremiumCardTop();

    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          padding: EdgeInsets.only(bottom: bottomPad + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: headerBandTop),
              // X·히어로·PREMIUM·캐릭터를 한 Stack에 두고, 캐릭터를 마지막에
              // 그려 발이 카드 위에 보이도록 함 (이전엔 Column 순서로 카드가 덮음).
              Stack(
                key: _heroStackKey,
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 44),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: heroTopGap),
                            _buildHeroPremiumSection(size, characterWidth),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 8,
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
                  Positioned(
                    right: size.width * _heroCharacterRightRatio,
                    top: characterTop,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/icons/paywall_character.png',
                        width: characterWidth,
                        height: characterHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.028),
                    _buildPlanDivider(),
                    const SizedBox(height: 14),
                    _buildAnnualPlan(),
                    const SizedBox(height: 12),
                    _buildMonthlyPlan(),
                    SizedBox(height: size.height * 0.028),
                    _buildCta(),
                    const SizedBox(height: 12),
                    Text(
                      'A assinatura é renovada automaticamente, a menos que '
                      'seja cancelada com pelo menos 24 horas de antecedência '
                      'do fim do período de cobrança atual.',
                      textAlign: TextAlign.center,
                      style: _style(size: 12, color: _legal, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Termos de Serviço  •  Política de Privacidade',
                        textAlign: TextAlign.center,
                        style: _style(size: 10, color: _legal),
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

  Widget _buildHeroPremiumSection(Size size, double characterWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(characterWidth),
        SizedBox(height: size.width * _heroToPremiumGapWidthRatio),
        _buildPremiumCard(),
      ],
    );
  }

  Widget _buildHero(double characterWidth) {
    return Padding(
      padding: EdgeInsets.only(right: characterWidth * 0.62, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pratique Mais',
            style: _style(
              size: 20,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          _gradientText(
            text: 'Aprenda Conversando',
            style: _style(size: 32, weight: FontWeight.w700),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A003D), Color(0xFF742AD5)],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pratique por mais tempo com o Premium e receba feedback '
            'da IA para evoluir no inglês.',
            style: _style(size: 14, color: Colors.white, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
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
            _premiumCardTopInset - (cardWidth * _premiumBadgeTopOverhangWidthRatio);

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cardWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: _premiumCardKey,
                  width: cardWidth,
                  margin: const EdgeInsets.only(top: _premiumCardTopInset),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                  decoration: BoxDecoration(
                    color: _premiumCard,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [_cardShadow],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PREMIUM',
                        style: _style(
                          size: 20,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _premiumRow('Mais prática todos os dias'),
                      const SizedBox(height: 10),
                      _premiumRow('Energia máxima de 30'),
                      const SizedBox(height: 10),
                      _premiumRow('Feedback da IA sobre frases'),
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
      children: [
        Image.asset(
          'assets/images/icons/paywall_check_Icon.png',
          width: 18,
          height: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: _style(size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Escolha seu plano',
            style: _style(size: 16, color: Colors.white),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
      ],
    );
  }

  Widget _buildAnnualPlan() {
    final selected = _selected == _PaywallPlan.annual;
    return _planCard(
      selected: selected,
      onTap: () => setState(() => _selected = _PaywallPlan.annual),
      title: 'Plano Anual',
      subtitle: 'Economize 33% em relação ao plano mensal.',
      priceMain: 'R\$16,66/mês',
      priceSub: 'R\$199,99/ano',
      showMelhorBadge: true,
    );
  }

  Widget _buildMonthlyPlan() {
    final selected = _selected == _PaywallPlan.monthly;
    return _planCard(
      selected: selected,
      onTap: () => setState(() => _selected = _PaywallPlan.monthly),
      title: 'Plano Mensal',
      subtitle: 'Acesso mensal com flexibilidade.',
      priceMain: 'R\$24,99/mês',
    );
  }

  Widget _melhorBadge() {
    const strokeWidth = 1.2;
    const radius = 24.0;
    // Outside stroke가 CustomPaint bounds 밖으로 그려지므로 padding으로 확보.
    return Padding(
      padding: const EdgeInsets.all(strokeWidth),
      child: CustomPaint(
        foregroundPainter: const _MelhorBadgeStrokePainter(
          strokeWidth: strokeWidth,
          radius: radius,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.038),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/icons/paywall_small_star.png',
                width: 12,
                height: 12,
              ),
              const SizedBox(width: 4),
              _gradientText(
                text: 'MELHOR',
                style: _style(size: 14, weight: FontWeight.w700)
                    .copyWith(letterSpacing: 14 * -0.01),
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
    );
  }

  Widget _planCard({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String priceMain,
    String? priceSub,
    bool showMelhorBadge = false,
  }) {
    final radius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF0CABA8), Color(0xFF8A38F5)],
                  )
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
                  ),
            border: Border.all(
              color: selected
                  ? const Color(0xCCFFFFFF)
                  : _accentPurple,
              width: selected ? 3 : 1,
            ),
            boxShadow: selected
                ? const [_selectedPlanShadow]
                : const [_cardShadow],
          ),
          child: ClipRRect(
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (!selected)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x4D8A38F5)),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    14,
                    14,
                    showMelhorBadge ? 25 : 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showMelhorBadge) const SizedBox(height: 16),
                            Row(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          color: _planTitle.withValues(
                                            alpha: 0.85,
                                          ),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showMelhorBadge) ...[
                            _melhorBadge(),
                            const SizedBox(height: 6),
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
                              style: _style(size: 15, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCta() {
    return GestureDetector(
      onTap: () {},
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xC98A38F5), Color(0xC9280752)],
            ),
          ),
          child: Text(
            'Assinar agora',
            style: _style(
              size: 18,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// MELHOR 뱃지 outside stroke 근사: path를 strokeWidth/2만큼 확장 후
/// [PaintingStyle.stroke] + [SweepGradient] shader만 적용(배경 fill 금지).
class _MelhorBadgeStrokePainter extends CustomPainter {
  const _MelhorBadgeStrokePainter({
    required this.strokeWidth,
    required this.radius,
  });

  final double strokeWidth;
  final double radius;

  static const _sweep = SweepGradient(
    colors: [
      Color(0x4FFFFFFF), // #FFFFFF 31%
      Color(0x00FFFFFF), // #FFFFFF 0%
      Color(0x4FFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.12, 0.37, 0.62, 0.87],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    // Centered stroke를 Outside에 가깝게: Rect를 half만큼 확장.
    final rect = Rect.fromLTWH(
      -half,
      -half,
      size.width + strokeWidth,
      size.height + strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius + half),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..shader = _sweep.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _MelhorBadgeStrokePainter oldDelegate) =>
      strokeWidth != oldDelegate.strokeWidth || radius != oldDelegate.radius;
}
