import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/token_storage.dart';
import '../../services/suda_api_client.dart';

/// Roleplay Result Screen (Full Screen)
///
/// 박스레이어: 줄어드는 영역. 본문레이어: 박스 뒤쪽 영역.
/// 진입 시: 전체 #0CABA8 박스레이어 → 별점·mainTitle·subTitle 순차 노출(각 300ms 후) → subTitle 노출 300ms 후 박스 축소.
class RoleplayResultScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayResultScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<RoleplayResultScreen> createState() => _RoleplayResultScreenState();
}

class _RoleplayResultScreenState extends State<RoleplayResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _boxShrinkController;
  bool _showStars = false;
  bool _showMainTitle = false;
  bool _showSubTitle = false;
  bool _shrinkScheduled = false;
  bool _shrinkStarted = false;
  double _shrinkFromHeight = 0;
  int? _currentLevel;
  double? _progressPercentage;
  bool _reportSubmitted = false;

  @override
  void initState() {
    super.initState();
    _boxShrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _boxShrinkController.addListener(() {
      if (mounted) setState(() {});
    });
    _scheduleBoxLayerSequence();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final token = await TokenStorage.loadAccessToken();
    if (token == null || !mounted) return;
    try {
      final profile = await SudaApiClient.getUserProfile(accessToken: token);
      if (mounted) {
        setState(() {
          _currentLevel = profile.currentLevel;
          _progressPercentage = profile.progressPercentage;
        });
      }
    } catch (_) {
      // ignore; progress bar will show 0
    }
  }

  void _scheduleBoxLayerSequence() {
    // 300ms: 별점 노출 + 진동
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _showStars = true);
      Vibration.vibrate(duration: 80);
      // 600ms: mainTitle 노출 + 진동
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _showMainTitle = true);
        Vibration.vibrate(duration: 80);
        // 900ms: subTitle 노출 + 진동
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => _showSubTitle = true);
          Vibration.vibrate(duration: 80);
          // 1200ms: 박스 축소 트리거
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            final h = MediaQuery.sizeOf(context).height;
            setState(() {
              _shrinkScheduled = true;
              _shrinkFromHeight = h;
              _shrinkStarted = true;
            });
            _boxShrinkController.forward();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _boxShrinkController.dispose();
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
  static const Color _progressBase = Color(0xFF635F5F);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const String _missionSucceeded = 'assets/images/icons/mission_succeeded.png';
  static const String _missionFailed = 'assets/images/icons/mission_failed.png';

  Widget _buildBoxLayerContent(BuildContext context) {
    final dto = RoleplayStateService.instance.cachedResult;
    final starResult = dto?.starResult ?? 0;
    final useGold = starResult >= 1 && starResult <= 3;
    final starAsset = useGold ? _starGold : _starSilver;
    final theme = Theme.of(context).textTheme;

    // 70x70을 80x80과 같은 기준선에 맞추기 위해 10 하향
    const double star70Offset = 10.0;
    final starsRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: Image.asset(starAsset, width: 70, height: 70, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 10),
        Image.asset(starAsset, width: 80, height: 80, fit: BoxFit.contain),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: Image.asset(starAsset, width: 70, height: 70, fit: BoxFit.contain),
          ),
        ),
      ],
    );

    // 전체 노출 시 레이아웃 기준으로 고정, Opacity로 순차 노출해 위치 변경 없음
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

    // likePoint 그라데이션 텍스트 (h1, #80D7CF -> #CFFFFB)
    final likePointValue = dto?.likePoint != null ? '${dto!.likePoint}' : '00';
    final likePointText = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_mint, _mintLight],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        likePointValue,
        style: theme.headlineLarge?.copyWith(color: Colors.white),
      ),
    );

    // missionResult: "YYNN" -> Y=succeeded, N=failed, 아이콘 높이 20, gap 없음
    final missionResultStr = dto?.missionResult ?? '';
    final missionIcons = <Widget>[];
    if (missionResultStr.isEmpty) {
      final missionCount = dto?.completedMissionIds?.length ?? 0;
      for (var i = 0; i < missionCount; i++) {
        missionIcons.add(Image.asset(_missionFailed, height: 20, width: 20, fit: BoxFit.contain));
      }
    } else {
      for (var i = 0; i < missionResultStr.length; i++) {
        final isSuccess = missionResultStr[i].toUpperCase() == 'Y';
        missionIcons.add(Image.asset(
          isSuccess ? _missionSucceeded : _missionFailed,
          height: 20,
          width: 20,
          fit: BoxFit.contain,
        ));
      }
    }

    final wordsValue = dto?.words != null ? '${dto!.words}' : '00';

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
        // 2) like_at_result 75x75 + likePoint (한 줄)
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(_likeAtResult, width: 75, height: 75, fit: BoxFit.contain),
              const SizedBox(width: 5),
              Transform.translate(
                offset: const Offset(0, 10),
                child: likePointText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),
        // 4) 좌 50% / 우 50%
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
                    Text(wordsValue, style: theme.bodyLarge?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        // 6) 프로그레스바 (Profile과 동일)
        Center(
          child: SizedBox(
            width: screenWidth * 0.7,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Lv. ${_currentLevel ?? 0}',
                style: theme.labelSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultProgressBar(progressPercentage: _progressPercentage ?? 0.0),
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 25),
        // 8) Good Points
        Text('Good Points', style: h3Mint, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          dto?.goodFeedback ?? '',
          style: theme.bodySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 25),
        // 12) To Improve
        Text('To Improve', style: h3Mint, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          dto?.improvementFeedback ?? '',
          style: theme.bodySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 25),
        // 16) Got it! 버튼 (Opening Let's Start 스타일, 내부 텍스트 기준 최소 width)
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
            child: const Text("Got it!"),
          ),
        ),
        const SizedBox(height: 35),
        // Report 문구 (다국어). 탭 시 Result Report 스크린 진입. 전송 성공 후 돌아오면 숨김.
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
            if (!didPop) _navigateToOverview(context);
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

/// Profile 스크린과 동일한 Lv.x 프로그레스바 형태 (height 4, base #635F5F, progress #80D7CF)
class _ResultProgressBar extends StatelessWidget {
  final double progressPercentage;

  const _ResultProgressBar({required this.progressPercentage});

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
