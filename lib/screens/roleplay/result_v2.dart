import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../utils/default_toast.dart';

/// Roleplay Result V2 Screen (Full Screen)
///
/// 기존 Result 화면을 유지한 채, 신규 Full Screen + bottom-up 전환 실험용으로
/// 별도 파일에 분리한 V2 스크린이다.
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
  late final AnimationController _boxShrinkController;
  bool _showStars = true;
  bool _showMainTitle = true;
  bool _showSubTitle = true;
  int _revealedGoldStars = 0;
  bool _shrinkScheduled = false;
  bool _shrinkStarted = false;
  double _shrinkFromHeight = 0;
  int? _currentLevel;
  double? _progressPercentage;
  bool _reportSubmitted = false;

  bool _missionRevealed = false;
  int _displayWords = 0;
  double _displayLikePoint = 0;
  int? _displayLevel;
  double _displayProgress = 0;
  AnimationController? _likePointController;
  AnimationController? _wordsController;
  AnimationController? _levelProgressController;
  bool _levelUpToastShown = false;

  @override
  void initState() {
    super.initState();
    _boxShrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _boxShrinkController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _boxShrinkController.addStatusListener(_onBoxShrinkStatusChanged);
    final dto = RoleplayStateService.instance.cachedResult;
    _currentLevel = dto?.afterLevel;
    _progressPercentage = dto?.afterProgressPercentage?.toDouble();
    _displayLevel = dto?.beforeLevel;
    _displayProgress = (dto?.beforeProgressPercentage ?? 0).toDouble();
    _scheduleBoxLayerSequence();
  }

  void _onBoxShrinkStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _boxShrinkController.removeStatusListener(_onBoxShrinkStatusChanged);
      _scheduleContentAnimations();
    }
  }

  Future<void> _scheduleContentAnimations() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _startPhase5_7_8();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _startPhase6();
  }

  void _startPhase5_7_8() {
    final dto = RoleplayStateService.instance.cachedResult;
    if (dto == null || !mounted) return;

    final missionResultStr = dto.missionResult ?? '';
    final hasAnyY = missionResultStr.toUpperCase().contains('Y');
    if (hasAnyY) {
      Vibration.vibrate(duration: 80);
    }
    setState(() => _missionRevealed = true);

    final likePointTarget = (dto.likePoint ?? 0).toDouble();
    _likePointController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _likePointController!.addListener(() {
      if (mounted && _likePointController != null) {
        setState(() {
          _displayLikePoint = likePointTarget * _likePointController!.value;
        });
      }
    });
    final lpCtrl = _likePointController!;
    lpCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        lpCtrl.dispose();
        _likePointController = null;
      }
    });
    lpCtrl.forward();

    final beforeLevel = dto.beforeLevel ?? 0;
    final afterLevel = dto.afterLevel ?? 0;
    final beforeProgress = (dto.beforeProgressPercentage ?? 0).toDouble();
    final afterProgress = (dto.afterProgressPercentage ?? 0).toDouble();

    _levelProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _levelProgressController!.addListener(() {
      if (!mounted || _levelProgressController == null) return;
      final t = _levelProgressController!.value;
      final levelProgress = _computeLevelProgress(
        t: t,
        beforeLevel: beforeLevel,
        afterLevel: afterLevel,
        beforeProgress: beforeProgress,
        afterProgress: afterProgress,
      );
      setState(() {
        _displayLevel = levelProgress.$1;
        _displayProgress = levelProgress.$2;
      });
    });
    final lvCtrl = _levelProgressController!;
    lvCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (afterLevel > beforeLevel && mounted && !_levelUpToastShown) {
          _levelUpToastShown = true;
          final ctx = context;
          final l10n = AppLocalizations.of(ctx);
          if (l10n != null) {
            DefaultToast.show(ctx, l10n.surveySuccessToast);
          }
        }
        lvCtrl.dispose();
        _levelProgressController = null;
      }
    });
    lvCtrl.forward();
  }

  (int, double) _computeLevelProgress({
    required double t,
    required int beforeLevel,
    required int afterLevel,
    required double beforeProgress,
    required double afterProgress,
  }) {
    if (beforeLevel == afterLevel) {
      final p = beforeProgress + t * (afterProgress - beforeProgress);
      return (beforeLevel, p.clamp(0, 100));
    }
    final levelDiff = afterLevel - beforeLevel;
    final segment1 = 100 - beforeProgress;
    final segmentLast = afterProgress;
    final total = segment1 + 100.0 * (levelDiff - 1) + segmentLast;
    final amount = (t * total).clamp(0.0, total);

    if (amount <= segment1) {
      final p = beforeProgress + (amount / segment1) * (100 - beforeProgress);
      return (beforeLevel, p);
    }
    final remaining = amount - segment1;
    final fullBars = (remaining / 100).floor().clamp(0, levelDiff - 1);
    if (fullBars < levelDiff - 1) {
      final progress = remaining - 100 * fullBars;
      return (beforeLevel + 1 + fullBars, progress.clamp(0, 100));
    }
    final p = (remaining - 100 * (levelDiff - 1)) / segmentLast * afterProgress;
    return (afterLevel, p.clamp(0, 100));
  }

  void _startPhase6() {
    final dto = RoleplayStateService.instance.cachedResult;
    if (dto == null || !mounted) return;
    final wordsTarget = dto.words ?? 0;
    if (wordsTarget > 0) {
      Vibration.vibrate(duration: 80);
    }
    _wordsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final wCtrl = _wordsController!;
    wCtrl.addListener(() {
      if (mounted) {
        setState(() {
          _displayWords = (wordsTarget * wCtrl.value).round();
        });
      }
    });
    wCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        wCtrl.dispose();
        _wordsController = null;
      }
    });
    wCtrl.forward();
  }

  void _startBoxShrink() {
    if (!mounted || _shrinkStarted) return;
    final h = MediaQuery.sizeOf(context).height;
    setState(() {
      _shrinkScheduled = true;
      _shrinkFromHeight = h;
      _shrinkStarted = true;
    });
    _boxShrinkController.forward();
  }

  Future<void> _scheduleBoxLayerSequence() async {
    final dto = RoleplayStateService.instance.cachedResult;
    final rawStarResult = dto?.starResult ?? 0;
    final targetGoldStars = (rawStarResult >= 1 && rawStarResult <= 3)
        ? rawStarResult
        : 0;

    for (var i = 1; i <= targetGoldStars; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _revealedGoldStars = i);
      Vibration.vibrate(duration: 80);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _startBoxShrink();
  }

  @override
  void dispose() {
    _boxShrinkController.removeStatusListener(_onBoxShrinkStatusChanged);
    _boxShrinkController.dispose();
    _likePointController?.dispose();
    _wordsController?.dispose();
    _levelProgressController?.dispose();
    super.dispose();
  }

  void _navigateToOverview(BuildContext context) {
    RoleplayRouter.popToOverview(context);
  }

  static const double _finalBoxHeight = 210;
  static const Color _teal = Color(0xFF0CABA8);
  static const Color _defaultBg = Color(0xFF121212);
  static const Color _mint = Color(0xFF80D7CF);
  static const Color _mintLight = Color(0xFFCFFFFB);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const String _missionSucceeded =
      'assets/images/icons/mission_succeeded.png';
  static const String _missionFailed =
      'assets/images/icons/mission_failed.png';

  Widget _buildBoxLayerContent(BuildContext context) {
    final dto = RoleplayStateService.instance.cachedResult;
    final leftGold = _revealedGoldStars >= 1;
    final centerGold = _revealedGoldStars >= 2;
    final rightGold = _revealedGoldStars >= 3;
    final leftStar = leftGold ? _starGold : _starSilver;
    final centerStar = centerGold ? _starGold : _starSilver;
    final rightStar = rightGold ? _starGold : _starSilver;
    final theme = Theme.of(context).textTheme;

    const double star70Offset = 10.0;
    final starsRow = Row(
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Opacity(opacity: _showStars ? 1 : 0, child: starsRow),
        const SizedBox(height: 5),
        Opacity(
          opacity: _showMainTitle ? 1 : 0,
          child: Text(
            dto?.mainTitle ?? '',
            style: theme.headlineLarge?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 5),
        Opacity(
          opacity: _showSubTitle ? 1 : 0,
          child: Text(
            dto?.subTitle ?? '',
            style: theme.headlineSmall?.copyWith(color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildContentLayer(BuildContext context) {
    final dto = RoleplayStateService.instance.cachedResult;
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final likePointDisplay = '${_displayLikePoint.round()}'.padLeft(2, '0');
    final likePointText = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_mint, _mintLight],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          likePointDisplay,
          style: theme.headlineLarge?.copyWith(color: Colors.white),
        ),
      ),
    );

    final missionResultStr = dto?.missionResult ?? '';
    final missionLen = missionResultStr.isEmpty
        ? (dto?.completedMissionIds?.length ?? 0)
        : missionResultStr.length;
    final missionIcons = <Widget>[];
    if (_missionRevealed) {
      if (missionResultStr.isEmpty) {
        for (var i = 0; i < missionLen; i++) {
          missionIcons.add(
            Image.asset(_missionFailed, height: 20, width: 20, fit: BoxFit.contain),
          );
        }
      } else {
        for (var i = 0; i < missionResultStr.length; i++) {
          final isSuccess = missionResultStr[i].toUpperCase() == 'Y';
          missionIcons.add(
            Image.asset(
              isSuccess ? _missionSucceeded : _missionFailed,
              height: 20,
              width: 20,
              fit: BoxFit.contain,
            ),
          );
        }
      }
    } else {
      for (var i = 0; i < missionLen; i++) {
        missionIcons.add(
          Image.asset(_missionFailed, height: 20, width: 20, fit: BoxFit.contain),
        );
      }
    }

    final wordsDisplay = '$_displayWords'.padLeft(2, '0');

    final bodyDefaultMint = theme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontFamily: 'ChironGoRoundTC',
      color: _mint,
    );
    final h3Mint = theme.headlineSmall?.copyWith(
      fontFamily: 'ChironGoRoundTC',
      color: _mint,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 35),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                _likeAtResult,
                width: 75,
                height: 75,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 5),
              Transform.translate(
                offset: const Offset(0, 10),
                child: likePointText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mission', style: bodyDefaultMint),
                    const SizedBox(height: 4),
                    if (missionIcons.isEmpty)
                      Text('—', style: theme.bodyMedium?.copyWith(color: Colors.white))
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: missionIcons,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Words', style: bodyDefaultMint),
                    const SizedBox(height: 4),
                    Text(
                      wordsDisplay,
                      style: theme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Center(
          child: SizedBox(
            width: screenWidth * 0.7,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Lv. ${_displayLevel ?? 0}',
                  style: theme.labelSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ResultV2ProgressBar(progressPercentage: _displayProgress),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        Text('Good Points', style: h3Mint, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          dto?.goodFeedback ?? '',
          style: theme.bodySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 25),
        Text('To Improve', style: h3Mint, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          dto?.improvementFeedback ?? '',
          style: theme.bodySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 25),
        Center(
          child: ElevatedButton(
            onPressed: () => _navigateToOverview(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _teal,
              disabledForegroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
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
                      style: theme.bodySmall?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () async {
                    final result =
                        await RoleplayRouter.pushResultReport<bool>(context);
                    if (result == true && mounted) {
                      setState(() => _reportSubmitted = true);
                    }
                  },
                  child: Text(
                    l10n.endingReport,
                    style: theme.bodySmall?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final shrinkT = _boxShrinkController.value;
    final boxHeight = _shrinkStarted
        ? _finalBoxHeight +
            (_shrinkFromHeight - _finalBoxHeight) *
                (1 - Curves.easeOutQuint.transform(shrinkT))
        : screenHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: Container(color: _teal)),
        PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              _navigateToOverview(context);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                AnimatedBuilder(
                  animation: _boxShrinkController,
                  builder: (context, child) {
                    return SizedBox(
                      height: boxHeight,
                      width: double.infinity,
                      child: Container(
                        color: _teal,
                        alignment: Alignment.center,
                        child: _buildBoxLayerContent(context),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    color: _defaultBg,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildContentLayer(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultV2ProgressBar extends StatelessWidget {
  final double progressPercentage;

  const _ResultV2ProgressBar({required this.progressPercentage});

  @override
  Widget build(BuildContext context) {
    final p = (progressPercentage.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF635F5F)),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * p,
                  child: const ColoredBox(color: Color(0xFF80D7CF)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
