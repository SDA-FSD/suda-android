import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../effects/like_progress_effect.dart';
import '../../models/roleplay_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';

/// Roleplay Result V2 Screen (Full Screen)
///
/// 현재 단계에서는 중앙 박스레이어만 먼저 정의하고,
/// 화면 fully shown 이후 1초 뒤 상단 이동 + like progress effect를 수행한다.
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
  static const Color _mint = Color(0xFF80D7CF);
  static const Color _mintLight = Color(0xFFCFFFFB);
  static const Color _cardBg = Color(0x8080D7CF);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const String _missionSucceeded =
      'assets/images/icons/mission_succeeded.png';
  static const String _missionFailed =
      'assets/images/icons/mission_failed.png';

  late final AnimationController _panelMoveController;
  final GlobalKey _panelKey = GlobalKey();
  double? _panelMeasuredHeight;
  Animation<double>? _routeAnimation;
  bool _didAttachRouteAnimation = false;
  bool _hasScheduledPostEntrance = false;
  bool _hasStartedEffectSequence = false;
  bool _effectDone = false;
  int _revealedGoldStars = 0;

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
        if (mounted) {
          setState(() => _effectDone = true);
        }
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
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
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
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

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurePanel();
    final moveProgress = Curves.easeOutCubic.transform(_panelMoveController.value);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final targetHeight = (_panelMeasuredHeight ?? screenHeight).clamp(0.0, screenHeight);
    final boxHeight = lerpDouble(screenHeight, targetHeight, moveProgress) ?? screenHeight;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
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
                ],
              ),
              if (_effectDone)
                const Center(
                  child: Text(
                    'done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
