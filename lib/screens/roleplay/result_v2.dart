import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibration/vibration.dart';

import '../../effects/like_progress_effect.dart';
import '../../l10n/app_localizations.dart';
import '../../models/roleplay_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';

const Color _exprTextPrimary = Color(0xFF121212);
const Color _exprTextSecondary = Color(0xFF676767);
const Color _expressionUpgradeCardBg = Color(0xFF80D7CF);

/// Roleplay Result V2 Screen (Full Screen)
///
/// 화면 fully shown 이후 1초 뒤 상단 이동 + LikeProgressEffect(레벨·라이크 진행) 후
/// Feedback / Expression Upgrade 본문 레이어를 노출한다.
class RoleplayResultScreenV2 extends StatefulWidget {
  static const String routeName = '/roleplay/result_v2';

  final bool showCloseButton;

  const RoleplayResultScreenV2({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<RoleplayResultScreenV2> createState() => _RoleplayResultScreenV2State();
}

class _RoleplayResultScreenV2State extends State<RoleplayResultScreenV2>
    with TickerProviderStateMixin {
  static const Color _topBg = Color(0xFF054544);
  static const Color _bottomBg = Color(0xFF0CABA8);
  static const Color _teal = Color(0xFF0CABA8);
  static const Color _mint = Color(0xFF80D7CF);
  static const Color _cardBg = Color(0x8080D7CF);
  static const Color _feedbackBoxFill = Color(0xFF80D7CF);
  static const Color _reportText = Color(0xFF054544);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const String _missionSucceeded =
      'assets/images/icons/mission_succeeded.png';
  static const String _missionFailed =
      'assets/images/icons/mission_failed.png';

  late final AnimationController _panelMoveController;
  late final AnimationController _feedbackEntranceController;
  late final AnimationController _expressionEntranceController;
  late final AnimationController _footerFadeController;
  final GlobalKey _panelKey = GlobalKey();
  double? _panelMeasuredHeight;
  Animation<double>? _routeAnimation;
  bool _didAttachRouteAnimation = false;
  bool _hasScheduledPostEntrance = false;
  bool _hasStartedEffectSequence = false;
  bool _effectDone = false;
  bool _showFooterActions = false;
  int _revealedGoldStars = 0;
  bool _reportSubmitted = false;

  RoleplayResultDto? get _dto => RoleplayStateService.instance.cachedResult;

  @override
  void initState() {
    super.initState();
    _panelMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _feedbackEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _expressionEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _footerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scheduleStarSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didAttachRouteAnimation) {
      return;
    }
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation == null) {
      _schedulePostEntranceSequence();
      _didAttachRouteAnimation = true;
      return;
    }
    _routeAnimation = animation;
    animation.addStatusListener(_onRouteAnimationStatusChanged);
    if (animation.status == AnimationStatus.completed) {
      _schedulePostEntranceSequence();
    }
    _didAttachRouteAnimation = true;
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _schedulePostEntranceSequence();
    }
  }

  Future<void> _schedulePostEntranceSequence() async {
    if (_hasScheduledPostEntrance) {
      return;
    }
    _hasScheduledPostEntrance = true;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    _startPanelMoveAndEffect();
  }

  Future<void> _scheduleStarSequence() async {
    final rawStarResult = _dto?.starResult ?? 0;
    final targetGoldStars = (rawStarResult >= 1 && rawStarResult <= 3)
        ? rawStarResult
        : 0;

    for (var i = 1; i <= targetGoldStars; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) {
        return;
      }
      setState(() => _revealedGoldStars = i);
      Vibration.vibrate(duration: 80);
    }
  }

  void _startPanelMoveAndEffect() {
    if (_hasStartedEffectSequence) {
      return;
    }
    _hasStartedEffectSequence = true;
    _panelMoveController.forward();

    final dto = _dto;
    if (dto == null) {
      return;
    }

    LikeProgressEffect.play(
      context,
      params: LikeProgressEffectParams(
        asIsLikePoint: dto.beforeLikePoint ?? 0,
        toBeLikePoint: dto.afterLikePoint ?? 0,
        asIsLevel: dto.beforeLevel ?? 0,
        toBeLevel: dto.afterLevel ?? 0,
        asIsProgress: dto.beforeProgressPercentage ?? 0,
        toBeProgress: dto.afterProgressPercentage ?? 0,
      ),
      onCompleted: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _effectDone = true;
          _showFooterActions = false;
        });
        if (mounted) {
          _feedbackEntranceController.forward(from: 0);
        }
        final hasUpgrades = dto.expressionUpgrades?.isNotEmpty ?? false;
        if (hasUpgrades) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _expressionEntranceController.forward(from: 0);
            }
          });
        }
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) {
            return;
          }
          _footerFadeController.reset();
          setState(() => _showFooterActions = true);
          _footerFadeController.forward();
        });
      },
    );
  }

  void _scheduleMeasurePanel() {
    if (_panelMeasuredHeight != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _panelMeasuredHeight != null) {
        return;
      }
      final ctx = _panelKey.currentContext;
      if (ctx == null) {
        return;
      }
      final size = ctx.size;
      if (size == null || size.height <= 0) {
        return;
      }
      setState(() => _panelMeasuredHeight = size.height);
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _panelMoveController.dispose();
    _feedbackEntranceController.dispose();
    _expressionEntranceController.dispose();
    _footerFadeController.dispose();
    super.dispose();
  }

  void _navigateToOverview(BuildContext context) {
    RoleplayRouter.popToOverview(context);
  }

  Widget _buildStarsRow() {
    final leftGold = _revealedGoldStars >= 1;
    final centerGold = _revealedGoldStars >= 2;
    final rightGold = _revealedGoldStars >= 3;
    final leftStar = leftGold ? _starGold : _starSilver;
    final centerStar = centerGold ? _starGold : _starSilver;
    final rightStar = rightGold ? _starGold : _starSilver;

    const double star70Offset = 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: Image.asset(
              leftStar,
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Image.asset(centerStar, width: 80, height: 80, fit: BoxFit.contain),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: Image.asset(
              rightStar,
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionIcons() {
    final missionResultStr = _dto?.missionResult ?? '';
    final missionLen = missionResultStr.isEmpty
        ? (_dto?.completedMissionIds?.length ?? 0)
        : missionResultStr.length;
    final missionIcons = <Widget>[];

    if (missionResultStr.isEmpty) {
      for (var i = 0; i < missionLen; i++) {
        missionIcons.add(
          Image.asset(_missionFailed, height: 20, width: 15, fit: BoxFit.contain),
        );
      }
    } else {
      for (var i = 0; i < missionResultStr.length; i++) {
        final isSuccess = missionResultStr[i].toUpperCase() == 'Y';
        missionIcons.add(
          Image.asset(
            isSuccess ? _missionSucceeded : _missionFailed,
            height: 20,
            width: 15,
            fit: BoxFit.contain,
          ),
        );
      }
    }

    if (missionIcons.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: Colors.white),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 0,
      runSpacing: 2,
      children: missionIcons,
    );
  }

  Widget _buildLikeText(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final likeValue = '${_dto?.likePoint ?? 0}'.padLeft(2, '0');

    return Text(
      likeValue,
      style: theme.bodyLarge?.copyWith(color: Colors.white),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context).textTheme;
    final labelPrimary = theme.bodyLarge?.copyWith(
          fontFamily: 'ChironGoRoundTC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation('wght', 600)],
          letterSpacing: -0.4,
          height: 1.2,
          color: Colors.white,
        ) ??
        const TextStyle(
          fontFamily: 'ChironGoRoundTC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation('wght', 600)],
          letterSpacing: -0.4,
          height: 1.2,
          color: Colors.white,
        );

    return Expanded(
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: labelPrimary,
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(child: child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final wordsDisplay = '${_dto?.words ?? 0}'.padLeft(2, '0');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),
            _buildStarsRow(),
            const SizedBox(height: 5),
            Text(
              _dto?.mainTitle ?? '',
              style: theme.headlineLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              _dto?.subTitle ?? '',
              style: theme.headlineSmall?.copyWith(color: _mint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  context,
                  title: 'Mission',
                  child: _buildMissionIcons(),
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  context,
                  title: 'Words',
                  child: Text(
                    wordsDisplay,
                    style: theme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  context,
                  title: 'Like',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        _likeAtResult,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 2),
                      Flexible(child: _buildLikeText(context)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackLayer(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final feedback = _dto?.overallFeedback ?? '';

    final entrance = CurvedAnimation(
      parent: _feedbackEntranceController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(entrance),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.2),
          end: Offset.zero,
        ).animate(entrance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Feedback',
                style: theme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _feedbackBoxFill,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    feedback,
                    style: theme.bodyMedium?.copyWith(color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionCarousel(BuildContext context) {
    final items = _dto?.expressionUpgrades ?? const <ExpressionUpgradeDto>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final sw = MediaQuery.sizeOf(context).width;
    final itemW = sw * 0.7;
    const between = 16.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              SizedBox(
                width: itemW,
                child: _ExpressionUpgradeCard(item: items[i]),
              ),
              if (i < items.length - 1) const SizedBox(width: between),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionLayer(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    final entrance = CurvedAnimation(
      parent: _expressionEntranceController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(entrance),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.2),
          end: Offset.zero,
        ).animate(entrance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Expression Upgrade',
                style: theme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            _buildExpressionCarousel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPostEffectBody(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasUpgrades = _dto?.expressionUpgrades?.isNotEmpty ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, 32, 0, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFeedbackLayer(context),
          if (hasUpgrades) ...[
            const SizedBox(height: 28),
            _buildExpressionLayer(context),
          ],
          if (_showFooterActions)
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _footerFadeController,
                curve: Curves.easeOut,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 28),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _navigateToOverview(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _teal,
                        disabledForegroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Got it!'),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Center(
                    child: _reportSubmitted
                        ? IgnorePointer(
                            child: Opacity(
                              opacity: 0,
                              child: Text(
                                l10n.endingReport,
                                style: theme.bodySmall
                                    ?.copyWith(color: _reportText),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              final result = await RoleplayRouter
                                  .pushResultReport<bool>(context);
                              if (result == true && mounted) {
                                setState(() => _reportSubmitted = true);
                              }
                            },
                            child: Text(
                              l10n.endingReport,
                              style: theme.bodySmall
                                  ?.copyWith(color: _reportText),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurePanel();
    final moveProgress = Curves.easeOutCubic.transform(_panelMoveController.value);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final targetHeight = (_panelMeasuredHeight ?? screenHeight).clamp(0.0, screenHeight);
    final boxHeight = lerpDouble(screenHeight, targetHeight, moveProgress) ?? screenHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigateToOverview(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_topBg, _bottomBg],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: boxHeight,
                    width: double.infinity,
                    child: Container(
                      alignment: Alignment.center,
                      child: KeyedSubtree(
                        key: _panelKey,
                        child: _buildPanel(context),
                      ),
                    ),
                  ),
                  if (_effectDone)
                    Expanded(
                      child: _buildPostEffectBody(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpressionUpgradeCard extends StatelessWidget {
  const _ExpressionUpgradeCard({required this.item});

  final ExpressionUpgradeDto item;

  static const String _checkMintSvg = 'assets/images/icons/check_mint.svg';
  static const String _megaphonePng = 'assets/images/icons/megaphone.png';
  static const String _bookmarkOffPng = 'assets/images/icons/bookmark_off.png';
  /// check(22) + gap(8) — meaning·rephrased 좌측 정렬 공통
  static const double _bodyLeftIndent = 30;
  static const Color _megaphoneTint = Color(0xFF0CABA8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final expression = item.expression ?? '';
    final meaning = item.meaningUserLanguage ?? '';
    final rephrased = item.rephrasedSentence ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: _expressionUpgradeCardBg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      _checkMintSvg,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expression,
                        style: theme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _exprTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: _bodyLeftIndent),
                  child: Text(
                    meaning,
                    style: theme.bodySmall?.copyWith(
                      color: _exprTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(left: _bodyLeftIndent),
                  child: Text(
                    rephrased,
                    style: theme.bodyMedium?.copyWith(
                      color: _exprTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Image.asset(
                        _megaphonePng,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: _megaphoneTint,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Image.asset(
                        _bookmarkOffPng,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
