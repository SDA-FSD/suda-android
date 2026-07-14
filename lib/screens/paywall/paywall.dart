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
  static const _heroToPremiumGapRatio = 0.035;
  /// 캐릭터 너비(화면 대비). 0.56에서 소폭 축소.
  static const _heroCharacterWidthRatio = 0.50;
  /// 값이 커질수록 왼쪽으로 이동(음수면 화면 우측으로 더 삐져나감).
  static const _heroCharacterRightRatio = -0.05;
  static const _premiumCard = Color(0xFF48069D);
  static const _premiumCardTopInset = 10.0;
  static const _premiumBadgeDesignSize = 34.0;
  static const _premiumBadgeDesignCardWidth = 342.0;
  static const _premiumBadgeMinSize = 30.0;
  static const _premiumBadgeMaxSize = 40.0;
  static const _premiumBadgeOutline = Color(0xFF51218F);
  static const _premiumBadgeOutlineWidth = 1.5;
  static const _premiumBadgeShadow = BoxShadow(
    color: Color(0x40000000),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final characterWidth = size.width * _heroCharacterWidthRatio;
    // X 버튼과 동일 밴드(topPad+8)에서 캐릭터 모자 시작.
    const closeTop = 8.0;

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  bottomPad + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20 + (size.height * 0.01)),
                    _buildHeroPremiumSection(size, characterWidth),
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
            ),
            Positioned(
              top: topPad + closeTop,
              right: size.width * _heroCharacterRightRatio,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/icons/paywall_character.png',
                  width: characterWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: topPad + closeTop,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPremiumSection(Size size, double characterWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(characterWidth),
        SizedBox(height: size.height * _heroToPremiumGapRatio),
        _buildPremiumCard(),
      ],
    );
  }

  Widget _buildHero(double characterWidth) {
    return Padding(
      padding: EdgeInsets.only(right: characterWidth * 0.55, top: 12),
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
        final cardWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;
        final scaledBadgeSize =
            cardWidth * _premiumBadgeDesignSize / _premiumBadgeDesignCardWidth;
        final badgeSize =
            scaledBadgeSize.clamp(_premiumBadgeMinSize, _premiumBadgeMaxSize);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: _premiumCardTopInset),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                color: _premiumCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_cardShadow],
              ),
              child: Column(
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
            Positioned(
              left: -badgeSize * 0.5,
              top: _premiumCardTopInset - (badgeSize * 0.5),
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: const [_premiumBadgeShadow],
                  border: Border.all(
                    color: _premiumBadgeOutline,
                    width: _premiumBadgeOutlineWidth,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: ClipOval(
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/icons/paywall_star_badge.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _planCard(
          selected: selected,
          onTap: () => setState(() => _selected = _PaywallPlan.annual),
          title: 'Plano Anual',
          subtitle: 'Economize 33% em relação ao plano mensal.',
          priceMain: 'R\$16,66/mês',
          priceSub: 'R\$199,99/ano',
        ),
        Positioned(
          right: 12,
          top: -10,
          child: _melhorBadge(),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF5B1BC7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_cardShadow],
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
            style: _style(size: 14, weight: FontWeight.w700),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFD8A4)],
              stops: [0.0, 0.65],
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
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      Image.asset(
                        selected
                            ? 'assets/images/icons/paywall_radio_selected.png'
                            : 'assets/images/icons/paywall_radio_unselected.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
