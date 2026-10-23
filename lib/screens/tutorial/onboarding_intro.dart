import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../utils/default_toast.dart';
import 'onboarding_intro_stage.dart';
import 'onboarding_backdrop.dart';

/// 온보딩 Username 다음. 프로필·문구·Start → 마이크 권한 → 장면 문구 → 롤플레이.
class TutorialIntroScreen extends StatefulWidget {
  /// 이번 배포는 false라 Username 다음이 홈이다. 다음 배포에서 true.
  static const onboardingEnabled = false;
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
  bool _requestingMic = false;
  bool _sceneRunning = false;
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
    super.dispose();
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

  /// 인트로가 걷히면 선명한 배경. 1.5초 뒤 그라데이션, 이어서 문구.
  /// 글자가 보이기 시작한 시점부터 5초면 대화. 400ms 페이드는 그 5초에 포함된다.
  Future<void> _playSceneThenStart() async {
    final gen = ++_sceneGen;
    setState(() => _sceneRunning = true);
    await _introFade.forward();
    if (!_sceneAlive(gen)) return;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!_sceneAlive(gen)) return;
    await _gradient.forward();
    if (!_sceneAlive(gen)) return;
    unawaited(_caption.forward());
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!_sceneAlive(gen)) return;
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
        body: Stack(
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
              FadeTransition(
                opacity: _caption,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    size.width * 0.08,
                    size.height * 0.77,
                    size.width * 0.08,
                    0,
                  ),
                  child: Text(
                    l10n.tutorialRoleplaySceneCaption,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: captionStyle,
                  ),
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
    );
  }
}
