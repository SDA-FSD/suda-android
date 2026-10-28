import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/suda_api_client.dart';
import '../../../services/token_storage.dart';
import '../../../utils/default_toast.dart';
import 'intro_stage.dart';
import 'backdrop.dart';

/// 온보딩 Username 다음. 프로필·문구·Start → 마이크 권한 → 장면 문구 → 롤플레이.
class TutorialIntroScreen extends StatefulWidget {
  /// false면 Username 다음이 홈이다. true면 `ONBOARDING_TUTORIAL != Y`일 때 Intro.
  static const onboardingEnabled = true;
  final UserDto? user;
  final VoidCallback onStartTutorial;
  final bool preview;

  /// Username Confirm 전환을 이미 재생했으면 false(최종 프레임부터).
  final bool playEntrance;

  const TutorialIntroScreen({
    super.key,
    this.user,
    required this.onStartTutorial,
    this.preview = false,
    this.playEntrance = true,
  });

  @override
  State<TutorialIntroScreen> createState() => _TutorialIntroScreenState();
}

class _TutorialIntroScreenState extends State<TutorialIntroScreen>
    with TickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 400);

  late final AnimationController _entrance;
  late final AnimationController _introFade;
  late final AnimationController _gradient;
  late final AnimationController _caption;
  late final AnimationController _continueFade;
  late final AnimationController _continueBlink;
  bool _requestingMic = false;
  bool _sceneRunning = false;
  bool _continueReady = false;
  bool _continued = false;
  int _sceneGen = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: TutorialIntroStage.duration,
    );
    _introFade = AnimationController(vsync: this, duration: _fade);
    _gradient = AnimationController(vsync: this, duration: _fade);
    _caption = AnimationController(vsync: this, duration: _fade);
    _continueFade = AnimationController(vsync: this, duration: _fade);
    _continueBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..value = 1;
    if (!widget.preview) {
      unawaited(_postOnboardingTutorialShownBestEffort());
    }
    if (widget.playEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entrance.forward();
      });
    } else {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _sceneGen++;
    _entrance.dispose();
    _introFade.dispose();
    _gradient.dispose();
    _caption.dispose();
    _continueFade.dispose();
    _continueBlink.dispose();
    super.dispose();
  }

  Future<void> _postOnboardingTutorialShownBestEffort() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) return;
      await SudaApiClient.postOnboardingTutorialShown(accessToken: token);
    } catch (_) {}
  }

  String get _displayName {
    final raw = widget.user?.name?.trim() ?? '';
    if (raw.isEmpty) return 'Friend';
    return raw;
  }

  Future<bool> _ensureMicrophonePermission(BuildContext context) async {
    var status = await Permission.microphone.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.microphonePermissionDenied),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.accountGoBack),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    DefaultToast.show(context, l10n.microphonePermissionDenied);
    return false;
  }

  Future<void> _onStartTutorial() async {
    if (_requestingMic || _sceneRunning) return;
    _requestingMic = true;
    final ok = await _ensureMicrophonePermission(context);
    if (!mounted) return;
    _requestingMic = false;
    if (!ok) return;
    await _playSceneThenStart();
  }

  /// 인트로가 걷히면 선명한 배경. 0.6초 뒤 그라데이션, 이어서 문구.
  /// 문구 페이드가 끝난 뒤 0.5초 지나 «탭해서 계속하기»가 뜨고, 그 탭으로만 대화로 간다.
  Future<void> _playSceneThenStart() async {
    final gen = ++_sceneGen;
    setState(() => _sceneRunning = true);
    await _introFade.forward();
    if (!_sceneAlive(gen)) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!_sceneAlive(gen)) return;
    await _gradient.forward();
    if (!_sceneAlive(gen)) return;
    await _caption.forward();
    if (!_sceneAlive(gen)) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!_sceneAlive(gen)) return;
    await _continueFade.forward();
    if (!_sceneAlive(gen)) return;
    setState(() => _continueReady = true);
    _continueBlink.repeat(reverse: true);
  }

  void _onTapContinue() {
    if (!_continueReady || _continued) return;
    _continued = true;
    _sceneGen++;
    _continueBlink.stop();
    unawaited(_fadeOutThenContinue());
  }

  /// 문구·안내를 걷어 선명한 배경만 남긴 뒤 대화 화면으로 넘긴다.
  Future<void> _fadeOutThenContinue() async {
    await Future.wait([
      _caption.reverse(),
      _continueFade.reverse(),
      _gradient.reverse(),
    ]);
    if (!mounted) return;
    widget.onStartTutorial();
  }

  bool _sceneAlive(int gen) => mounted && gen == _sceneGen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final captionStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      height: 1.45,
    );
    return PopScope(
      canPop: widget.preview && !_sceneRunning,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _continueReady && !_continued ? _onTapContinue : null,
          child: Stack(
          fit: StackFit.expand,
          children: [
            if (_sceneRunning) const TutorialRoleplayBackdrop(blurAmount: 0),
            if (_sceneRunning)
              FadeTransition(
                opacity: _gradient,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00121212), Color(0xFF121212)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            if (_sceneRunning)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  size.width * 0.08,
                  size.height * 0.77,
                  size.width * 0.08,
                  0,
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _caption,
                      child: Text(
                        l10n.tutorialRoleplaySceneCaption,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: captionStyle,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _continueFade,
                      child: IgnorePointer(
                        ignoring: !_continueReady,
                        child: GestureDetector(
                          onTap: _onTapContinue,
                          behavior: HitTestBehavior.opaque,
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.35, end: 1).animate(
                              _continueBlink,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.tutorialRoleplayGuideMissionTapContinue,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: const Color(0xCCFFFFFF),
                                        ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xCCFFFFFF),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            FadeTransition(
              opacity: ReverseAnimation(_introFade),
              child: IgnorePointer(
                ignoring: _sceneRunning,
                child: AnimatedBuilder(
                  animation: _entrance,
                  builder: (context, _) {
                    return TutorialIntroStage(
                      progress: _entrance.value,
                      displayName: _displayName,
                      imgPath: widget.user?.imgPath,
                      onStartTutorial: _onStartTutorial,
                    );
                  },
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
