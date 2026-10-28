import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../api/endpoints/onboarding_tutorial_api.dart';
import '../../../api/suda_api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/series_models.dart';
import '../../../screens/roleplay/playing_conversation_mixin.dart'
    show PlayingConversationLayout;
import '../../../screens/roleplay/suda_tts_audio_player.dart';
import '../../../services/token_storage.dart';
import '../../../effects/mission_complete_effect.dart';
import '../../../widgets/default_popup.dart';
import '../../../widgets/guide_bubble.dart';
import '../../../widgets/roleplay_mic_button_area.dart';
import '../../../widgets/roleplay_mission_panel.dart';
import '../../../widgets/roleplay_turn_bar_area.dart';
import 'pointer.dart';
import 'result.dart';
import 'backdrop.dart';

/// 마이크 가이드 문구. 기본은 AI 발화 후, 나머지는 홀드/짧은 탭/무인식.
enum _TutorialMicGuide { afterVoice, holding, tooShort, noSpeech }

/// 온보딩 Tutorial Roleplay.
///
/// 대화 화면. 턴바 3칸은 비어 있고, 사용자 대답 시마다 채워짐.
class TutorialRoleplayScreen extends StatefulWidget {
  static const bettyAvatarAsset = 'assets/images/onboarding/onboarding_tutorial_betty.png';

  final VoidCallback onSkip;
  final bool preview;

  const TutorialRoleplayScreen({
    super.key,
    required this.onSkip,
    this.preview = false,
  });

  @override
  State<TutorialRoleplayScreen> createState() => _TutorialRoleplayScreenState();
}

class _TutorialRoleplayScreenState extends State<TutorialRoleplayScreen>
    with TickerProviderStateMixin {
  static const _turnCount = 3;

  late final AnimationController _bgFade;
  late final AnimationController _blurUi;
  late final AnimationController _playingExit;
  late final AnimationController _micLoadingRotation;
  late final Animation<double> _chromeOpacity;

  /// 서버가 받은 사용자 발화 수. 턴바는 최대 3칸, 색은 `#0CABA8`.
  int _answeredTurnCount = 0;
  int _completedMissions = 0;
  final Set<int> _completedMissionIndexes = {};
  final GlobalKey _missionIconAnchorKey = GlobalKey();
  bool _showMissionCompletedFlash = false;
  int _flashMissionIndex = 0;
  bool _showGreetingSuccess = false;
  late final AnimationController _greetingSuccess;
  Timer? _missionCompleteTimer;
  Timer? _roleplayEndTimer;
  OverlayEntry? _endingEntry;
  Timer? _holdToSpeakTimer;
  String? _holdToSpeakText;
  bool _holdToSpeakVisible = false;
  String? _sessionId;
  int _lastAiMsgId = 1;
  bool _sending = false;
  bool _recording = false;
  bool _recordStarting = false;
  bool _showRecordingBubble = false;
  bool _micHeld = false;
  bool _stopRequested = false;
  bool _stopCancel = false;
  bool _showHelloGuide = true;
  String? _hintEnglish;
  String? _hintNative;
  bool _hintVisible = false;
  final GlobalKey _hintCardKey = GlobalKey();

  /// 두 번째 AI 음성이 끝난 뒤에만 힌트 안내를 띄운다.
  bool _hintCoachReady = false;
  bool _showFreeAnswerGuide = false;
  bool _freeAnswerGuideDismissed = false;
  bool _hintAnswerGuideDismissed = false;
  bool _hintEnglishRevealed = false;

  /// 이번 온보딩에서 힌트 박스를 한 번이라도 열었는지. 첫 박스만 영어 예시를 펼친다.
  bool _hintBoxOpened = false;

  /// 힌트를 한 번 열기 전에는 버튼 안내를 보여 준다.
  bool _hintCoachDismissed = false;

  /// -1이면 문장 전체, 0 이상이면 그 단어.
  int? _hintPlayingIndex;
  DateTime? _recordStartedAt;
  final List<double> _speechLevelsDb = [];
  StreamSubscription<Amplitude>? _speechLevelSub;
  final AudioRecorder _recorder = AudioRecorder();
  bool _micPermissionGranted = false;
  final ScrollController _talkScroll = ScrollController();
  final List<_TutorialLine> _lines = [];

  /// 화면 전환 직후 Betty 말풍선.
  bool _showBetty = false;
  bool _showMicGuide = false;
  bool _showMicPointer = false;
  bool _micEnabled = false;
  bool _micPulsing = false;
  // ignore: prefer_final_fields — 홀드/짧은 탭/무인식 시 setState로 바꿈
  _TutorialMicGuide _micGuide = _TutorialMicGuide.afterVoice;
  final SudaTtsAudioPlayer _aiVoice = SudaTtsAudioPlayer();
  int _playingIntroGen = 0;

  @override
  void initState() {
    super.initState();
    _bgFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    )..value = 1;
    _blurUi = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _playingExit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _micLoadingRotation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _greetingSuccess = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _greetingSuccess.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showGreetingSuccess = false);
      }
    });
    _chromeOpacity = CurvedAnimation(parent: _blurUi, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _blurUi.forward();
      _startPlayingIntro();
    });
  }

  @override
  void dispose() {
    _playingIntroGen++;
    _speechLevelSub?.cancel();
    _recorder.dispose();
    _talkScroll.dispose();
    _aiVoice.dispose();
    _bgFade.dispose();
    _blurUi.dispose();
    _playingExit.dispose();
    _micLoadingRotation.dispose();
    _greetingSuccess.dispose();
    _missionCompleteTimer?.cancel();
    _roleplayEndTimer?.cancel();
    _holdToSpeakTimer?.cancel();
    _endingEntry?.remove();
    _endingEntry = null;
    super.dispose();
  }

  Future<void> _showSkipPopup() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    await DefaultPopup.show(
      context,
      titleText: l10n.tutorialRoleplaySkipTitle,
      expandPrimaryButtons: true,
      bodyWidget: Text(
        l10n.tutorialRoleplaySkipBody,
        textAlign: TextAlign.center,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.tutorialRoleplaySkipConfirm,
          onPressed: widget.onSkip,
        ),
        DefaultPopupButton(
          type: DefaultPopupButtonType.text,
          label: l10n.tutorialRoleplaySkipKeepGoing,
          onPressed: () {},
        ),
      ],
    );
  }

  /// 접힌 미션+마이크만 → 화면 전환 직후 Betty 말풍선+음성 → 음성 종료 후 안내.
  Future<void> _startPlayingIntro() async {
    final gen = ++_playingIntroGen;
    final soundFuture = _loadOpeningVoice();
    if (!_playingIntroAlive(gen)) return;
    setState(() => _showBetty = true);
    final sound = await soundFuture;
    if (!_playingIntroAlive(gen)) return;
    await _playOpeningVoice(sound);
    if (!_playingIntroAlive(gen)) return;
    _revealMicGuide();
  }

  bool _playingIntroAlive(int gen) {
    return mounted && gen == _playingIntroGen;
  }

  Future<RpS2SoundResDto?> _loadOpeningVoice() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) return null;
      final session = await SudaApiClient.createTutorialSession(
        accessToken: token,
      );
      _sessionId = session.sessionId;
      _lastAiMsgId = session.startMsgId ?? 1;
      return session.aiSound;
    } catch (e) {
      debugPrint('[DEBUG] tutorial opening voice: $e');
      return null;
    }
  }

  Future<void> _playOpeningVoice(RpS2SoundResDto? sound) async {
    if (sound == null) return;
    try {
      final source = await _aiVoice.prepare(
        cdnYn: sound.cdnYn,
        cdnPath: sound.cdnPath,
        soundBytes: sound.file,
      );
      if (source == null || !mounted) return;
      final done = Completer<void>();
      var started = false;
      final sub = _aiVoice.playerStateStream.listen((state) {
        if (state.playing) started = true;
        if (started &&
            state.processingState == ProcessingState.completed &&
            !done.isCompleted) {
          done.complete();
        }
      });
      try {
        await _aiVoice.play();
        await done.future.timeout(const Duration(seconds: 20));
      } finally {
        await sub.cancel();
      }
    } catch (e) {
      debugPrint('[DEBUG] tutorial opening voice play: $e');
    }
    await _armMicSession();
  }

  void _revealMicGuide() {
    setState(() {
      _showMicGuide = true;
      _micEnabled = false;
      _micPulsing = true;
      _micGuide = _TutorialMicGuide.afterVoice;
    });
    unawaited(_prepareMicThenEnable());
  }

  /// 권한과 녹음 세션을 버튼을 열기 전에 맞춘다.
  /// iOS는 본편처럼 `playAndRecord`를 유지해야 첫 홀드 초반이 잘리지 않는다.
  Future<void> _prepareMicThenEnable() async {
    try {
      _micPermissionGranted = await _recorder.hasPermission();
      if (!mounted) return;
      if (_micPermissionGranted) await _armMicSession();
    } catch (e) {
      debugPrint('[DEBUG] tutorial mic prepare: $e');
    }
    if (!mounted) return;
    setState(() => _micEnabled = true);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !_micEnabled) {
        return;
      }
      setState(() => _showMicPointer = true);
    });
  }

  void _onMicHoldStart() {
    if (_sending || !_micEnabled) return;
    setState(() {
      _showRecordingBubble = true;
      _micHeld = true;
      _micPulsing = false;
      _showMicPointer = false;
      _hideFreeAnswerGuide();
      if (_hintEnglish != null) _hintAnswerGuideDismissed = true;
      if (_answeredTurnCount == 0) {
        _micGuide = _TutorialMicGuide.holding;
      } else {
        _showHelloGuide = false;
      }
    });
    _scrollTalkToEnd();
    unawaited(_startRecording());
  }

  void _onMicHoldEnd({required bool cancel}) {
    if (mounted && _micHeld) {
      setState(() => _micHeld = false);
    }
    unawaited(_finishRecording(cancel: cancel));
  }

  Future<void> _armMicSession() async {
    if (!Platform.isIOS) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration.speech().copyWith(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth,
        ),
      );
      await session.setActive(true).timeout(const Duration(seconds: 3));
      await _recorder.ios?.manageAudioSession(false);
    } catch (e) {
      debugPrint('[DEBUG] tutorial mic session: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _recordStarting || _sending) return;
    _recordStarting = true;
    _stopRequested = false;
    if (!_micPermissionGranted) {
      _micPermissionGranted = await _recorder.hasPermission();
    }
    if (!_micPermissionGranted || !mounted) {
      _recordStarting = false;
      _restoreMicGuide(_TutorialMicGuide.afterVoice);
      return;
    }
    final ext = Platform.isIOS ? 'wav' : 'm4a';
    final path =
        '${Directory.systemTemp.path}/tutorial_record_${DateTime.now().millisecondsSinceEpoch}.$ext';
    _recordStarting = true;
    final config = RecordConfig(
      encoder: Platform.isIOS ? AudioEncoder.wav : AudioEncoder.aacLc,
    );
    try {
      if (_aiVoice.isPlaying) {
        try {
          await _aiVoice.stop().timeout(const Duration(milliseconds: 150));
        } catch (_) {}
      }
      await _recorder.start(config, path: path);
      _recordStartedAt = DateTime.now();
      _listenSpeechLevel(_recordStartedAt!);
    } catch (e) {
      debugPrint('[DEBUG] tutorial record start: $e');
      _recordStarting = false;
      _restoreMicGuide(_TutorialMicGuide.afterVoice);
      return;
    }
    _recordStarting = false;
    if (!mounted) return;
    setState(() => _recording = true);
    if (_stopRequested) {
      await _finishRecording(cancel: _stopCancel);
    }
  }

  Future<void> _finishRecording({required bool cancel}) async {
    if (_recordStarting && !_recording) {
      _stopRequested = true;
      _stopCancel = cancel;
      return;
    }
    final started = _recordStartedAt;
    _recordStartedAt = null;
    if (!_recording) {
      if (!cancel) {
        _restoreMicGuide(_TutorialMicGuide.tooShort);
        _showHoldToSpeakOnLaterTurn();
      }
      return;
    }
    final heldMs = started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds;
    String? path;
    try {
      if (cancel || heldMs < 500) {
        await _speechLevelSub?.cancel();
        _speechLevelSub = null;
        _speechLevelsDb.clear();
        await _recorder.cancel();
      } else {
        path = await _recorder.stop();
      }
    } catch (e) {
      debugPrint('[DEBUG] tutorial record stop: $e');
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _showRecordingBubble = false;
    });
    if (cancel) {
      _restoreMicGuide(_TutorialMicGuide.afterVoice);
      return;
    }
    if (heldMs < 500 || path == null) {
      _restoreMicGuide(_TutorialMicGuide.tooShort);
      _showHoldToSpeakOnLaterTurn();
      _deleteFile(path);
      return;
    }
    if (!_speechDetected()) {
      _restoreMicGuide(_TutorialMicGuide.noSpeech);
      _deleteFile(path);
      return;
    }
    final bytes = await File(path).readAsBytes();
    _deleteFile(path);
    await _sendAudio(bytes);
  }

  void _listenSpeechLevel(DateTime startedAt) {
    _speechLevelSub?.cancel();
    _speechLevelsDb.clear();
    _speechLevelSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          if (DateTime.now().difference(startedAt).inMilliseconds < 150) return;
          if (!amp.current.isFinite || amp.current == 0) return;
          _speechLevelsDb.add(amp.current);
        });
  }

  bool _speechDetected() {
    final levels = List<double>.of(_speechLevelsDb);
    _speechLevelsDb.clear();
    if (levels.length < 3) return false;
    final sorted = List<double>.of(levels)..sort();
    final floor = sorted[((sorted.length - 1) * 0.2).floor()];
    final peak = sorted.last;
    return peak - floor >= 10 || peak >= -30;
  }

  void _deleteFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  /// 2·3번째 사용자 발화에서만, 본편과 같은 한 줄 안내.
  void _showHoldToSpeakOnLaterTurn() {
    if (!mounted || _answeredTurnCount < 1) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    _holdToSpeakTimer?.cancel();
    setState(() {
      _holdToSpeakText = l10n.holdMicrophoneToSpeak;
      _holdToSpeakVisible = true;
    });
    _holdToSpeakTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _holdToSpeakVisible = false);
      _holdToSpeakTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _holdToSpeakText = null);
      });
    });
  }

  void _restoreMicGuide(_TutorialMicGuide guide, {bool revealHint = false}) {
    if (!mounted || _answeredTurnCount >= _turnCount) return;
    final showFreeAnswer =
        _answeredTurnCount == 2 && !_freeAnswerGuideDismissed;
    setState(() {
      _micEnabled = true;
      _sending = false;
      _showRecordingBubble = false;
      _showFreeAnswerGuide = showFreeAnswer;
      _micPulsing = _helloGuideActive || _showFreeAnswerGuide;
      _showMicPointer = _helloGuideActive;
      _micGuide = guide;
      if (revealHint) _hintCoachReady = true;
    });
    if (showFreeAnswer) _scrollTalkToEnd();
  }

  Future<void> _sendAudio(List<int> bytes) async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _restoreMicGuide(_TutorialMicGuide.afterVoice);
      return;
    }
    setState(() {
      _sending = true;
      _showFreeAnswerGuide = false;
      _micEnabled = false;
      _micPulsing = false;
      _showMicPointer = false;
    });
    if (!_micLoadingRotation.isAnimating) _micLoadingRotation.repeat();
    var armHint = false;
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) {
        _restoreMicGuide(_TutorialMicGuide.afterVoice);
        return;
      }
      final response = await SudaApiClient.sendTutorialUserAudio(
        accessToken: token,
        sessionId: sessionId,
        audioData: Uint8List.fromList(bytes),
      );
      if (!mounted) return;
      final showTranslation =
          Localizations.localeOf(context).languageCode != 'en';
      final aiText = response.aiText ?? '';
      final aiMsgId = response.aiMsgId;
      final soundFuture = SudaApiClient.getTutorialAiAudio(
        accessToken: token,
        sessionId: sessionId,
      );
      var missionJustCompleted = false;
      var showGreetingSuccess = false;
      final done = response.missionCompletedIndex;
      final completesGreeting =
          done == 0 && !_completedMissionIndexes.contains(0);
      final aiLine = _TutorialLine.ai(aiText);
      setState(() {
        _sending = false;
        _lines.add(_TutorialLine.user(response.userText ?? ''));
        if (!completesGreeting) _lines.add(aiLine);
        _answeredTurnCount = (_answeredTurnCount + 1).clamp(0, _turnCount);
        if (done != null &&
            done >= 0 &&
            done < _turnCount &&
            !_completedMissionIndexes.contains(done)) {
          _completedMissionIndexes.add(done);
          _flashMissionIndex = done;
          _showMissionCompletedFlash = true;
          _completedMissions = _completedMissionIndexes.length;
          missionJustCompleted = true;
          if (done == 0) {
            _showGreetingSuccess = true;
            showGreetingSuccess = true;
          }
        }
        _showHelloGuide = false;
        _hintEnglish = null;
        _hintNative = null;
        _hintVisible = false;
        _hintPlayingIndex = null;
        if (aiMsgId != null) _lastAiMsgId = aiMsgId;
      });
      armHint = _answeredTurnCount == 1 && !_hintCoachDismissed;
      _scrollTalkToEnd();
      if (missionJustCompleted) _playMissionSuccess();
      if (showGreetingSuccess) {
        await _greetingSuccess.forward(from: 0);
        if (!mounted) return;
        setState(() => _lines.add(aiLine));
        _scrollTalkToEnd();
      }
      if (showTranslation && aiMsgId != null) {
        unawaited(() async {
          final translation = await _fetchTranslation(sessionId, aiMsgId);
          if (!mounted || translation == null) return;
          setState(() => aiLine.translation = translation);
          _scrollTalkToEnd();
        }());
      }
      try {
        final sound = await soundFuture;
        if (mounted) await _playOpeningVoice(sound);
      } catch (e) {
        debugPrint('[DEBUG] tutorial ai audio: $e');
      }
      if (!mounted) return;
      if (_answeredTurnCount >= _turnCount) {
        await _finishAfterLastVoice();
        return;
      }
      await _armMicSession();
      _restoreMicGuide(_TutorialMicGuide.afterVoice, revealHint: armHint);
    } on TutorialAudioTooShortException {
      _restoreMicGuide(_TutorialMicGuide.tooShort);
      _showHoldToSpeakOnLaterTurn();
    } on TutorialNoSpeechException {
      _restoreMicGuide(_TutorialMicGuide.noSpeech);
    } catch (e) {
      debugPrint('[DEBUG] tutorial user audio: $e');
      _restoreMicGuide(_TutorialMicGuide.afterVoice, revealHint: armHint);
    } finally {
      if (_micLoadingRotation.isAnimating) _micLoadingRotation.stop();
    }
  }

  /// 마지막 AI 음성 뒤 나레이션을 붙이고, 그 노출 2초 뒤 결과로 간다.
  Future<void> _finishAfterLastVoice() async {
    if (!mounted) return;
    final narration = AppLocalizations.of(
      context,
    )!.tutorialRoleplayArrivalNarration;
    setState(() {
      _sending = false;
      _micEnabled = false;
      _micPulsing = false;
      _showRecordingBubble = false;
      _lines.add(_TutorialLine.narration(narration));
    });
    _scrollTalkToEnd();
    if (!widget.preview) unawaited(_completeOnboarding());
    unawaited(
      precacheImage(
        const AssetImage(TutorialResultScreen.endingAsset),
        context,
      ),
    );
    _roleplayEndTimer?.cancel();
    _roleplayEndTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _playingExit.forward();
      if (!mounted) return;
      _openEnding();
    });
  }

  void _openEnding() {
    if (_endingEntry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _endingEntry = OverlayEntry(
      builder: (context) => SizedBox.expand(
        child: TutorialResultScreen(onContinue: widget.onSkip),
      ),
    );
    overlay.insert(_endingEntry!);
  }

  Future<void> _completeOnboarding() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) return;
      await SudaApiClient.postOnboardingTutorial(accessToken: token);
    } catch (_) {}
  }

  void _playMissionSuccess() {
    MissionCompleteEffect.play(context, anchorKey: _missionIconAnchorKey);
    _missionCompleteTimer?.cancel();
    _missionCompleteTimer = Timer(
      RoleplayMissionPanel.completedBackgroundDuration,
      () {
        if (!mounted) return;
        setState(() => _showMissionCompletedFlash = false);
      },
    );
  }

  Future<String?> _fetchTranslation(String sessionId, int rpMsgId) async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return null;
      final text = await SudaApiClient.getTutorialTranslation(
        accessToken: token,
        sessionId: sessionId,
        rpMsgId: rpMsgId,
      );
      if (text.isEmpty) return null;
      return text;
    } catch (e) {
      debugPrint('[DEBUG] tutorial translation: $e');
      return null;
    }
  }

  /// 힌트는 발화 차례로 고정한다. 두 번째는 목적지, 세 번째는 이유.
  (String, String?) _localHint(AppLocalizations l10n) {
    final reason = _answeredTurnCount >= 2;
    final english = reason ? "I'm moving there today." : 'SUDA City, please.';
    return (english, _nativeForHint(l10n, english));
  }

  /// 말해야 하는 영어는 그대로 두고, 모국어만 앱 언어로 보여 준다. 영어 사용자는 모국어가 없다.
  String? _nativeForHint(AppLocalizations l10n, String english) {
    final native = english == "I'm moving there today."
        ? l10n.tutorialRoleplayHintReasonNative
        : l10n.tutorialRoleplayHintDestinationNative;
    final shown = native.trim();
    return shown.isEmpty ? null : shown;
  }

  void _applyHint(String english, String? native) {
    final shownNative = (native ?? '').trim();
    final opening = _hintEnglish == null;
    setState(() {
      _hintEnglish = english.trim().isEmpty ? null : english.trim();
      _hintNative = shownNative.isEmpty ? null : shownNative;
      _hintVisible = _hintEnglish != null;
      _hintCoachDismissed = _hintEnglish != null;
      _hintPlayingIndex = null;
      if (opening && _hintEnglish != null) {
        _hintAnswerGuideDismissed = false;
        final firstBox = !_hintBoxOpened;
        _hintBoxOpened = true;
        _hintEnglishRevealed = shownNative.isEmpty || firstBox;
      }
      _hideFreeAnswerGuide();
    });
    _scrollHintIntoView();
  }

  void _closeHintBox() {
    unawaited(_aiVoice.stop());
    if (!_hintVisible && _hintPlayingIndex == null) return;
    setState(() {
      _hintVisible = false;
      _hintPlayingIndex = null;
    });
  }

  void _reopenHintBox() {
    if (_hintEnglish == null || _hintEnglish!.isEmpty || _hintVisible) return;
    setState(() => _hintVisible = true);
    _scrollHintIntoView();
  }

  Future<void> _onHintTap() async {
    if (_answeredTurnCount < 1 || _hintVisible) return;
    if (_hintEnglish != null && _hintEnglish!.isNotEmpty) {
      _reopenHintBox();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final local = _localHint(l10n);
    _applyHint(local.$1, local.$2);
    final sessionId = _sessionId;
    if (sessionId == null) return;
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || !mounted) return;
      final hint = await SudaApiClient.getTutorialHint(
        accessToken: token,
        sessionId: sessionId,
        rpMsgId: _lastAiMsgId,
      );
      if (!mounted) return;
      final english = (hint.hint ?? '').trim();
      if (english.isEmpty) return;
      if (english != local.$1) {
        debugPrint(
          '[DEBUG] tutorial hint ignored for current turn: $english',
        );
        return;
      }
      _applyHint(english, _nativeForHint(l10n, english));
    } catch (e) {
      debugPrint('[DEBUG] tutorial hint: $e');
    }
  }

  Future<void> _playHintSound({int? wordIndex}) async {
    final sessionId = _sessionId;
    final english = _hintEnglish;
    if (sessionId == null || english == null || english.isEmpty) return;
    setState(() => _hintPlayingIndex = wordIndex ?? -1);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;
      final sound = await SudaApiClient.getTutorialHintSound(
        accessToken: token,
        sessionId: sessionId,
        wordIndex: wordIndex,
      );
      if (!mounted) return;
      await _playOpeningVoice(
        RpS2SoundResDto(
          cdnYn: sound.cdnYn,
          cdnPath: sound.cdnPath,
          file: sound.sound,
        ),
      );
    } catch (e) {
      debugPrint('[DEBUG] tutorial hint sound: $e');
    } finally {
      if (mounted) setState(() => _hintPlayingIndex = null);
    }
  }

  void _scrollTalkToEnd() {
    void perform() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_talkScroll.hasClients) return;
        _talkScroll.animateTo(
          _talkScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }

    perform();
    WidgetsBinding.instance.addPostFrameCallback((_) => perform());
  }

  /// 힌트 상자는 대화 맨 아래에 붙는다. 높이가 잡힌 뒤에 다시 끝까지 내린다.
  void _scrollHintIntoView() {
    void perform() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final anchor = _hintCardKey.currentContext;
        if (anchor != null) {
          Scrollable.ensureVisible(
            anchor,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 1.0,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
        if (!_talkScroll.hasClients) return;
        final position = _talkScroll.position;
        position.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }

    perform();
    WidgetsBinding.instance.addPostFrameCallback((_) => perform());
    Future<void>.delayed(const Duration(milliseconds: 280), perform);
    Future<void>.delayed(const Duration(milliseconds: 480), perform);
  }

  /// 두 번째 AI 음성 후, 힌트를 열기 전에는 Skip과 힌트만 누를 수 있다.
  /// AI 발화 3 이후에는 힌트를 열지 않아도 말할 수 있다.
  bool get _mustTapHint =>
      _hintCoachReady && !_hintCoachDismissed && _answeredTurnCount < 2;

  /// AI 발화 3 음성이 끝난 뒤, 이유 발화를 기다리는 동안.
  bool get _freeAnswerGuideActive => _showFreeAnswerGuide;

  /// 힌트나 마이크를 누르면 이 안내는 다시 나오지 않는다.
  void _hideFreeAnswerGuide() {
    if (!_showFreeAnswerGuide) return;
    _freeAnswerGuideDismissed = true;
    _showFreeAnswerGuide = false;
  }

  /// Hello 안내는 첫 발화가 받아지기 전에만 보여 준다.
  bool get _helloGuideActive => _showHelloGuide && _answeredTurnCount == 0;

  /// 누르는 순간의 ‘Hello’도 첫 발화 전에만. 이후 홀드는 이 안내를 쓰지 않는다.
  bool get _showMicGuideBubble =>
      _helloGuideActive &&
      _showMicGuide &&
      (_micGuide == _TutorialMicGuide.afterVoice ||
          _micGuide == _TutorialMicGuide.tooShort ||
          _micGuide == _TutorialMicGuide.noSpeech ||
          (_micGuide == _TutorialMicGuide.holding && _micHeld));

  String? _footerMicGuide(AppLocalizations l10n) {
    if (_freeAnswerGuideActive) return l10n.tutorialRoleplayFreeAnswerGuide;
    if (!_showMicGuideBubble) return null;
    return _micGuideText(l10n);
  }

  String _micGuideText(AppLocalizations l10n) {
    return switch (_micGuide) {
      _TutorialMicGuide.afterVoice => l10n.tutorialRoleplayHoldHello,
      _TutorialMicGuide.holding => l10n.tutorialRoleplayMicHolding,
      _TutorialMicGuide.tooShort => l10n.tutorialRoleplayMicTooShort,
      _TutorialMicGuide.noSpeech => l10n.tutorialRoleplayMicNoSpeech,
    };
  }

  List<Color> _turnBarColors() {
    return List<Color>.generate(_turnCount, (i) {
      if (i < _answeredTurnCount) return const Color(0xFF0CABA8);
      return RoleplayTurnBarArea.defaultBarColor;
    });
  }

  List<RpS2CefrMissionDto> _missionDtos(AppLocalizations l10n) {
    final texts = [
      l10n.tutorialRoleplayMission1,
      l10n.tutorialRoleplayMission2,
      l10n.tutorialRoleplayMission3,
    ];
    final code = Localizations.localeOf(context).languageCode;
    return [
      for (final t in texts)
        RpS2CefrMissionDto(
          keyExpression: {code: t, 'en': t},
          instruction: {code: t, 'en': t},
          sampleAnswer: const {},
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return PopScope(
      canPop: widget.preview,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: AnimatedBuilder(
          animation: Listenable.merge([_bgFade, _blurUi]),
          builder: (context, _) {
            final bgOpacity = Curves.easeOut.transform(_bgFade.value);
            final blurAmount = _blurUi.value;

            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(
                    CurvedAnimation(
                      parent: _playingExit,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                Opacity(
                  opacity: bgOpacity,
                  child: TutorialRoleplayBackdrop(blurAmount: blurAmount),
                ),
                if (_blurUi.value > 0)
                  FadeTransition(
                    opacity: _chromeOpacity,
                    child: SafeArea(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  0,
                                ),
                                child: SizedBox(
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        l10n.tutorialRoleplayTitle,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _showSkipPopup,
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            l10n.tutorialRoleplaySkip,
                                            style: theme.bodyMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              RoleplayTurnBarArea(
                                turnCount: _turnCount,
                                barColors: _turnBarColors(),
                              ),
                              Expanded(child: _buildPlayingBody(l10n, theme)),
                                _PlayingLikeDisabledFooter(
                                  loadingRotationController:
                                      _micLoadingRotation,
                                  micGuide: _footerMicGuide(l10n),
                                  holdToSpeakText: _holdToSpeakText,
                                  holdToSpeakVisible: _holdToSpeakVisible,
                                  showHintCoach: _mustTapHint,
                                  hintGuide: l10n.tutorialRoleplayHintGuide,
                                  showMicPointer:
                                      _showMicPointer && _showHelloGuide,
                                  guideReserveText: _freeAnswerGuideActive
                                      ? l10n.tutorialRoleplayFreeAnswerGuide
                                      : l10n.tutorialRoleplayHoldHello,
                                  gapAboveMic: _freeAnswerGuideActive
                                      ? 40
                                      : 48,
                                  micEnabled: _micEnabled && !_mustTapHint,
                                  micLoading: _sending,
                                  hintEnabled: _hintCoachReady && !_hintVisible,
                                  hintSparkle: false,
                                  showMicPulse: _micPulsing,
                                  onMicHoldStart: _onMicHoldStart,
                                  onMicHoldEnd: _onMicHoldEnd,
                                  onHintTap: _onHintTap,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showGreetingSuccess)
                  IgnorePointer(child: _greetingSuccessOverlay(l10n, theme)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 첫 인사 미션 성공. 가운데에서 작게 시작해 커지고, 2초면 사라진다.
  Widget _greetingSuccessOverlay(AppLocalizations l10n, TextTheme theme) {
    return AnimatedBuilder(
      animation: _greetingSuccess,
      builder: (context, _) {
        final t = _greetingSuccess.value;
        final pop = Curves.easeOutBack.transform((t / 0.18).clamp(0.0, 1.0));
        final scale = 0.2 + 0.8 * pop;
        final opacity = t < 0.9 ? 1.0 : ((1 - t) / 0.1).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n.tutorialRoleplayGreetingSuccess,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: theme.headlineLarge?.copyWith(
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayingBody(AppLocalizations l10n, TextTheme theme) {
    final locale = Localizations.localeOf(context);
    final showTranslation = locale.languageCode != 'en';
    final missions = _missionDtos(l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PlayingConversationLayout.scaffoldBodyHorizontalInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: PlayingConversationLayout.bodyTopGap),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SingleChildScrollView(
                  controller: _talkScroll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: PlayingConversationLayout.firstBubbleTopOffset,
                      ),
                      _StaggerFade(
                        visible: _showBetty,
                        child: _TutorialAiBubble(
                          english: l10n.tutorialRoleplayBettyLine1,
                          translation: showTranslation
                              ? l10n.tutorialRoleplayBettyLine1Translation
                              : null,
                        ),
                      ),
                      for (final line in _lines) ...[
                        SizedBox(
                          height: line.kind == _TutorialLineKind.narration
                              ? 40
                              : 14,
                        ),
                        if (line.kind == _TutorialLineKind.user)
                          _TutorialUserBubble(text: line.text)
                        else if (line.kind == _TutorialLineKind.narration)
                          _TutorialNarration(text: line.text)
                        else
                          _TutorialAiBubble(
                            english: line.text,
                            translation: showTranslation
                                ? line.translation
                                : null,
                          ),
                      ],
                      if (_hintVisible && _hintEnglish != null) ...[
                        const SizedBox(height: 14),
                        KeyedSubtree(
                          key: _hintCardKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ClassicHintCard(
                                sceneryTick: _talkScroll,
                                label: l10n.roleplayHintLabel,
                                english: _hintEnglish!,
                                native: _hintNative,
                                englishVisible:
                                    _hintEnglishRevealed ||
                                    _hintNative == null,
                                revealLabel: l10n.roleplayHintShowAnswer,
                                englishLabel: l10n.roleplayHintEnglishLabel,
                                onReveal: () {
                                  setState(() => _hintEnglishRevealed = true);
                                  _scrollHintIntoView();
                                },
                                onClose: _closeHintBox,
                                playingIndex: _hintPlayingIndex,
                                onWord: (index) => unawaited(
                                  _playHintSound(wordIndex: index),
                                ),
                                onSentence: () => unawaited(_playHintSound()),
                              ),
                              if (_answeredTurnCount < 2 &&
                                  !_hintAnswerGuideDismissed &&
                                  (_hintEnglishRevealed ||
                                      _hintNative == null)) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: _tutorialGuide(
                                    l10n.tutorialRoleplayHintAnswerGuide,
                                    tail: GuideBubbleTail.top,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_showRecordingBubble) ...[
                        const SizedBox(height: 14),
                        const _TutorialRecordingBubble(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Positioned(
                  top: PlayingConversationLayout.missionPanelTop,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: _mustTapHint,
                    child: RoleplayMissionPanel(
                      missions: missions,
                      activeMissionIndex: _showMissionCompletedFlash
                          ? _flashMissionIndex
                          : _answeredTurnCount.clamp(0, _turnCount - 1),
                      completedCount: _completedMissions,
                      completedMissionIndexes: _completedMissionIndexes,
                      showCompletedBackgroundFlash: _showMissionCompletedFlash,
                      missionIconAnchorKey: _missionIconAnchorKey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TutorialLineKind { user, ai, narration }

class _TutorialLine {
  final _TutorialLineKind kind;
  final String text;
  String? translation;

  _TutorialLine.user(this.text) : kind = _TutorialLineKind.user;
  _TutorialLine.ai(this.text) : kind = _TutorialLineKind.ai;
  _TutorialLine.narration(this.text) : kind = _TutorialLineKind.narration;
}

/// 온보딩 힌트 상자. 모국어면 보기 버튼, 영어 사용자면 영어만.
class _ClassicHintCard extends StatelessWidget {
  static const _bg = Color(0xFF0CABA8);
  static const _accent = Color(0xFF80D7CF);
  static const _playback = Color(0xFF054544);
  static const _buttonFill = Color(0xFFEDEDED);
  static const _buttonText = Color(0xFF0CABA8);
  static const _blurSigma = 15.0;

  final Listenable sceneryTick;
  final String label;
  final String english;
  final String? native;
  final bool englishVisible;
  final String revealLabel;
  final String englishLabel;
  final VoidCallback onReveal;
  final VoidCallback onClose;
  final int? playingIndex;
  final void Function(int index)? onWord;
  final VoidCallback? onSentence;

  const _ClassicHintCard({
    required this.sceneryTick,
    required this.label,
    required this.english,
    required this.native,
    required this.englishVisible,
    required this.revealLabel,
    required this.englishLabel,
    required this.onReveal,
    required this.onClose,
    required this.playingIndex,
    this.onWord,
    this.onSentence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNative = native != null && native!.isNotEmpty;
    final labelStyle =
        theme.textTheme.bodyMedium?.copyWith(color: _accent);
    final nativeStyle =
        theme.textTheme.bodyLarge?.copyWith(color: Colors.white);
    final englishLabelStyle =
        theme.textTheme.bodySmall?.copyWith(color: _accent);
    final buttonStyle =
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{})
            ?.copyWith(color: _buttonText) ??
        theme.textTheme.bodyMedium?.copyWith(color: _buttonText);
    final words = english
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final headline =
        theme.textTheme.headlineSmall ?? theme.textTheme.bodyLarge;
    final playing = playingIndex != null;

    final tint = _bg.withValues(alpha: 0.7);
    final titleRow = Row(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
          child: Image.asset(
            'assets/images/icons/lightball.png',
            height: 14,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: labelStyle, textAlign: TextAlign.start),
        ),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.close, size: 20, color: Colors.white),
          ),
        ),
      ],
    );
    final top = <Widget>[
      titleRow,
      if (hasNative)
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Text(native!, textAlign: TextAlign.start, style: nativeStyle),
        ),
      if (hasNative && !englishVisible)
        Padding(
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: Material(
            color: _buttonFill,
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              onTap: onReveal,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _accent, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        revealLabel,
                        style: buttonStyle,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: _buttonText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
    final englishBody = <Widget>[
      Text(englishLabel, style: englishLabelStyle),
      Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onSentence,
              behavior: HitTestBehavior.opaque,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  playing ? _playback : Colors.white,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  playing
                      ? 'assets/images/icons/megaphone_fill.png'
                      : 'assets/images/icons/megaphone.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < words.length; i++) ...[
                    if (i > 0) Text(' ', style: headline),
                    _HintWord(
                      word: words[i],
                      headline: headline,
                      highlighted: playingIndex == -1 || playingIndex == i,
                      textColor: (playingIndex == -1 || playingIndex == i)
                          ? _playback
                          : Colors.white,
                      underlineColor:
                          (playingIndex == -1 || playingIndex == i)
                          ? _playback
                          : Colors.white,
                      onTap: onWord == null ? null : () => onWord!(i),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: _HintFrostedScene(tick: sceneryTick),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: tint,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      8,
                      englishVisible ? 12 : 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: top,
                    ),
                  ),
                ),
                if (englishVisible) ...[
                  ColoredBox(
                    color: tint,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 1,
                        child: ColoredBox(color: Color(0xFF0CABA8)),
                      ),
                    ),
                  ),
                  ColoredBox(
                    color: tint,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: englishBody,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 대화 배경을 박스 위치에 맞춰 깔고, 그 위에 blur 15를 준다.
/// FadeTransition/스크롤 안의 BackdropFilter는 배경 사진을 못 본다.
class _HintFrostedScene extends StatefulWidget {
  final Listenable tick;

  const _HintFrostedScene({required this.tick});

  @override
  State<_HintFrostedScene> createState() => _HintFrostedSceneState();
}

class _HintFrostedSceneState extends State<_HintFrostedScene> {
  @override
  void initState() {
    super.initState();
    widget.tick.addListener(_retick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _HintFrostedScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) {
      oldWidget.tick.removeListener(_retick);
      widget.tick.addListener(_retick);
    }
  }

  @override
  void dispose() {
    widget.tick.removeListener(_retick);
    super.dispose();
  }

  void _retick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero)
        : Offset.zero;
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -origin.dx,
              top: -origin.dy,
              width: screen.width,
              height: screen.height,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _ClassicHintCard._blurSigma,
                  sigmaY: _ClassicHintCard._blurSigma,
                ),
                child: const TutorialRoleplayBackdrop(blurAmount: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintWord extends StatelessWidget {
  final String word;
  final TextStyle? headline;
  final bool highlighted;
  final Color? textColor;
  final Color? underlineColor;
  final VoidCallback? onTap;

  const _HintWord({
    required this.word,
    required this.headline,
    required this.highlighted,
    this.textColor,
    this.underlineColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = headline?.copyWith(
      color: textColor ?? Colors.white,
      height: 1.35,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    );
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(word, style: style),
          const SizedBox(height: 2),
          SizedBox(
            width: width,
            height: 3,
            child: CustomPaint(
              painter: _HintDottedUnderlinePainter(
                color:
                    underlineColor ??
                    (highlighted ? Colors.white : Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintDottedUnderlinePainter extends CustomPainter {
  static const double _strokeWidth = 1.5;
  static const double _dashLength = 3;
  static const double _dashGap = 3;

  final Color color;

  _HintDottedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      final segmentEnd = math.min(x + _dashLength, size.width);
      if (segmentEnd > x) {
        canvas.drawLine(Offset(x, y), Offset(segmentEnd, y), paint);
      }
      x += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _HintDottedUnderlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 힌트 아이콘 둘레의 흰 테두리 원 두 개.
/// 영상: 작게 나타났다가 커지면서 옅어지고, 다시 안쪽에서 이어진다.
class _HintAimRings extends StatefulWidget {
  static const canvas = 96.0;

  const _HintAimRings();

  @override
  State<_HintAimRings> createState() => _HintAimRingsState();
}

class _HintAimRingsState extends State<_HintAimRings>
    with SingleTickerProviderStateMixin {
  static const _minInner = 16.0;
  static const _maxInner = 32.0;
  static const _gap = 8.0;
  static const _innerStroke = 2.5;
  static const _outerStroke = 2.0;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final travel = Curves.easeOut.transform(t);
        final fadeIn = (t / 0.18).clamp(0.0, 1.0);
        final opacity = fadeIn * (1 - travel);
        return CustomPaint(
          size: const Size(_HintAimRings.canvas, _HintAimRings.canvas),
          painter: _HintRingPainter(
            innerRadius: _minInner + (_maxInner - _minInner) * travel,
            opacity: opacity,
          ),
        );
      },
    );
  }
}

class _HintRingPainter extends CustomPainter {
  final double innerRadius;
  final double opacity;

  /// 안쪽(버튼에 가까운) 원 선 굵기. 기본은 힌트 버튼 값.
  final double innerStroke;

  /// 안쪽 원과 바깥 원 사이 간격. 기본은 힌트 버튼 값.
  final double gap;

  _HintRingPainter({
    required this.innerRadius,
    required this.opacity,
    this.innerStroke = _HintAimRingsState._innerStroke,
    this.gap = _HintAimRingsState._gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final center = Offset(size.width / 2, size.height / 2);
    final color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStroke;
    final outer = Paint()
      ..color = color.withValues(alpha: (opacity * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = _HintAimRingsState._outerStroke;
    canvas.drawCircle(center, innerRadius, inner);
    canvas.drawCircle(center, innerRadius + gap, outer);
  }

  @override
  bool shouldRepaint(covariant _HintRingPainter oldDelegate) =>
      oldDelegate.innerRadius != innerRadius ||
      oldDelegate.opacity != opacity ||
      oldDelegate.innerStroke != innerStroke ||
      oldDelegate.gap != gap;
}

/// 힌트 버튼 위에 강조 원과 안내를 화면 맨 위에 붙인다.
class _HintCoachLayer extends StatefulWidget {
  final bool show;
  final String guide;
  final Widget child;

  const _HintCoachLayer({
    required this.show,
    required this.guide,
    required this.child,
  });

  @override
  State<_HintCoachLayer> createState() => _HintCoachLayerState();
}

class _HintCoachLayerState extends State<_HintCoachLayer>
    with SingleTickerProviderStateMixin {
  static const _appearDuration = Duration(milliseconds: 560);

  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  late final AnimationController _appear;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(vsync: this, duration: _appearDuration)
      ..addListener(() => _entry?.markNeedsBuild());
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _HintCoachLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show != widget.show || oldWidget.guide != widget.guide) {
      _schedule();
    }
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sync();
    });
  }

  void _sync() {
    if (!mounted) return;
    if (!widget.show) {
      _appear.stop();
      _appear.value = 0;
      _remove();
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final fresh = _entry == null;
    _entry ??= OverlayEntry(builder: _build);
    if (_entry!.mounted) {
      _entry!.markNeedsBuild();
    } else {
      overlay.insert(_entry!);
    }
    if (fresh) _appear.forward(from: 0);
  }

  Widget _build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(_appear.value);
    return IgnorePointer(
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.center,
            followerAnchor: Alignment.center,
            child: Opacity(opacity: t, child: const _HintAimRings()),
          ),
          if (widget.guide.isNotEmpty)
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomRight,
              // 꼭지 끝은 버튼 가운데(오른쪽 끝에서 20)에 맞춘 뒤, 말풍선을 조금 위·오른쪽으로 두고 아주 조금 왼쪽으로 당긴다.
              offset: Offset(26, -16 + (1 - t) * 18),
              child: Opacity(
                opacity: t,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(decoration: TextDecoration.none),
                  child: _tutorialGuide(
                    widget.guide,
                    tailCentered: false,
                    tailOffsetFromEnd: 20,
                    maxWidth: MediaQuery.sizeOf(context).width * 2 / 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _remove() {
    if (_entry?.mounted ?? false) _entry!.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _remove();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _link, child: widget.child);
  }
}

/// 본편 녹음 말풍선과 같은 흰 점 3개 파도.
class _TutorialRecordingBubble extends StatelessWidget {
  const _TutorialRecordingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x4DFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _TutorialWaveDots(),
        ),
      ),
    );
  }
}

class _TutorialWaveDots extends StatefulWidget {
  const _TutorialWaveDots();

  @override
  State<_TutorialWaveDots> createState() => _TutorialWaveDotsState();
}

class _TutorialWaveDotsState extends State<_TutorialWaveDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityFor(int index, double t) {
    final phase = (t * 2 * math.pi) + (index * 0.8);
    return 0.3 + (0.7 * (1 + math.sin(phase)) / 2);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: Opacity(
                opacity: _opacityFor(index, _controller.value),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 6, height: 6),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TutorialUserBubble extends StatelessWidget {
  final String text;

  const _TutorialUserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// 본편 나레이션과 같은 가운데 이탤릭.
class _TutorialNarration extends StatelessWidget {
  final String text;

  const _TutorialNarration({required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontStyle: FontStyle.italic,
      height: 1.27,
    );
    return Center(
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}

/// Playing AI 말풍선과 동일 톤. 번역 버튼 없이 번역 문장 상시 노출(영어 로케일 제외).
class _TutorialAiBubble extends StatelessWidget {
  final String english;
  final String? translation;

  const _TutorialAiBubble({
    required this.english,
    this.translation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final textStyle = theme.bodyMedium?.copyWith(color: Colors.white);
    final translationStyle = theme.labelSmall?.copyWith(
      color: const Color(0xFF777373),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              TutorialRoleplayScreen.bettyAvatarAsset,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF353535),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(english, style: textStyle),
                  if (translation != null && translation!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      translation!,
                      style: translationStyle,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 처음 붙을 때 0→1 fade. 레이아웃에는 붙은 순간부터 자리 잡음.
class _EnterFade extends StatefulWidget {
  final Widget child;

  const _EnterFade({required this.child});

  @override
  State<_EnterFade> createState() => _EnterFadeState();
}

class _EnterFadeState extends State<_EnterFade> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _on ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}

class _StaggerFade extends StatelessWidget {
  final bool visible;
  final Widget child;

  const _StaggerFade({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}

/// 온보딩 롤플레이 안내. 공통 [GuideBubble]이고, 기본으로 위아래를 흔든다.
Widget _tutorialGuide(
  String text, {
  GuideBubbleTail tail = GuideBubbleTail.bottom,
  List<InlineSpan>? spans,
  double tailOffsetFromEnd = 20,
  bool tailCentered = true,
  bool wobble = true,
  double maxWidth = _TutorialGuide.defaultMaxWidth,
}) {
  return _TutorialGuide(
    text: text,
    tail: tail,
    spans: spans,
    tailOffsetFromEnd: tailOffsetFromEnd,
    tailCentered: tailCentered,
    wobble: wobble,
    maxWidth: maxWidth,
  );
}

/// 공통 [GuideBubble]은 그대로 두고, 온보딩에서만 글자 둘레 여백을 더한다.
/// 공통 여백 가로 14·세로 10에 가로 14·세로 12를 더해 가로 28·세로 22가 된다.
/// 글자는 말풍선 본문 한가운데에 둔다.
class _TutorialGuide extends StatelessWidget {
  static const _extraPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  /// 큰 글씨라 공통 기본(260)이면 문장이 어색하게 꺾여서 온보딩만 넓힌다.
  /// 실제 폭은 부모(화면 좌우 여백)가 다시 제한한다.
  static const defaultMaxWidth = 360.0;

  final String text;
  final GuideBubbleTail tail;
  final List<InlineSpan>? spans;
  final double tailOffsetFromEnd;
  final bool tailCentered;
  final bool wobble;
  final double maxWidth;

  const _TutorialGuide({
    required this.text,
    required this.tail,
    required this.spans,
    required this.tailOffsetFromEnd,
    required this.tailCentered,
    required this.wobble,
    this.maxWidth = defaultMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      decoration: TextDecoration.none,
    );
    return GuideBubble(
      text: text,
      tail: tail,
      wobble: wobble,
      dropShadow: true,
      textStyle: style,
      textAlign: TextAlign.center,
      cornerRadius: 20,
      maxWidth: maxWidth,
      tailCentered: tailCentered,
      tailOffsetFromEnd: tailOffsetFromEnd,
      contentPadding: _extraPadding,
      spans: spans,
    );
  }
}

/// 마이크 위 Hello 안내. 꼬리는 아래로(마이크 쪽).
/// 보이는 문구가 짧아져도 슬롯 높이는 [reserveText]만큼 유지한다.
class _PinnedGuideSlot extends StatelessWidget {
  final String? reserveText;
  final Widget child;

  const _PinnedGuideSlot({required this.reserveText, required this.child});

  @override
  Widget build(BuildContext context) {
    final reserve = reserveText;
    if (reserve == null || reserve.isEmpty) return child;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Opacity(
          opacity: 0,
          child: _tutorialGuide(
            reserve,
            wobble: false,
            spans: _helloSpans(reserve),
          ),
        ),
        child,
      ],
    );
  }
}

const _helloColor = Color(0xFF054544);
final _helloPattern = RegExp("'Hello'|‘Hello’");

List<InlineSpan> _helloSpans(String text) {
  final match = _helloPattern.firstMatch(text);
  if (match == null) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, match.start)),
    TextSpan(
      text: match.group(0),
      style: const TextStyle(color: _helloColor),
    ),
    TextSpan(text: text.substring(match.end)),
  ];
}

/// 마이크 둘레 파동. 힌트 버튼 강조 원(`_HintAimRings`)과 같은 동작:
/// 1.2초마다 안쪽 테두리 원이 마이크 바로 바깥에서 16px 퍼지며 나타났다 사라지고,
/// 8px 바깥의 흐린(40%) 테두리 원이 함께 따라간다. 흰 마이크 원은 고정.
class _TutorialMicRipple extends StatefulWidget {
  /// 흰 원 100 기준으로 바깥 링 끝까지의 칸.
  /// 가장 크게 퍼진 바깥 원(68+11+선 반 두께)이 잘리지 않는 크기.
  static const displaySize = 160.0;

  const _TutorialMicRipple();

  @override
  State<_TutorialMicRipple> createState() => _TutorialMicRippleState();
}

class _TutorialMicRippleState extends State<_TutorialMicRipple>
    with SingleTickerProviderStateMixin {
  /// 흰 원(지름 100) 바로 바깥에서 시작해 전구와 같은 16px을 퍼진다.
  static const _minInner = 52.0;
  static const _maxInner = 68.0;

  /// 마이크에 가까운 안쪽 원은 힌트 버튼(2.5)보다 두껍게.
  static const _innerStroke = 4.0;

  /// 안쪽 원과 바깥 원 사이 간격(힌트 버튼 8보다 살짝 넓게).
  static const _gap = 11.0;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final travel = Curves.easeOut.transform(t);
        final fadeIn = (t / 0.18).clamp(0.0, 1.0);
        return CustomPaint(
          size: const Size.square(_TutorialMicRipple.displaySize),
          painter: _HintRingPainter(
            innerRadius: _minInner + (_maxInner - _minInner) * travel,
            opacity: fadeIn * (1 - travel),
            innerStroke: _innerStroke,
            gap: _gap,
          ),
        );
      },
    );
  }
}

/// 힌트 전구. 앞장은 기존 24 논리 픽셀. AI 발화 3 이후에는 반짝이지 않는다.
class _HintBulb extends StatefulWidget {
  final bool sparkle;

  const _HintBulb({required this.sparkle});

  @override
  State<_HintBulb> createState() => _HintBulbState();
}

class _HintBulbState extends State<_HintBulb>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/images/icons/lightball.png';

  /// 기존 힌트 아이콘. 높이 24는 유지하고, 가로는 전구 비율 15.71.
  static const _iconW = 15.71;
  static const _iconH = 24.0;
  static const _midW = 22.26;
  static const _midH = 34.0;
  static const _outerW = 28.8;
  static const _outerH = 44.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.sparkle) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _HintBulb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sparkle && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.sparkle && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 뒤 아이콘은 최대 30%까지 밝아졌다가 다시 투명해진다.
  double _glow(double t, double phase) {
    final wave = math.sin(((t + phase) % 1) * math.pi);
    return 0.30 * wave;
  }

  Widget _glowLayer(double width, double height, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Image.asset(_asset, width: width, height: height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final front = Image.asset(_asset, width: _iconW, height: _iconH);
    return SizedBox(
      width: 40,
      height: 40,
      child: widget.sparkle
          ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _glowLayer(_outerW, _outerH, _glow(t, 0)),
                    _glowLayer(_midW, _midH, _glow(t, 0.28)),
                    child!,
                  ],
                );
              },
              child: front,
            )
          : Center(child: front),
    );
  }
}

/// Playing `buildPlayingFooter` 녹음 모드와 동일 크기·위치. 타이핑 토글만 비노출(빈 40슬롯).
class _PlayingLikeDisabledFooter extends StatelessWidget {
  final AnimationController loadingRotationController;
  final String? micGuide;
  final String? holdToSpeakText;
  final bool holdToSpeakVisible;
  final bool showHintCoach;
  final String hintGuide;
  final bool showMicPointer;

  /// 누르는 순간 문구가 줄어도 마이크가 움직이지 않게 잡아 두는 높이.
  final String? guideReserveText;
  final double gapAboveMic;
  final bool micEnabled;
  final bool micLoading;
  final bool hintEnabled;
  final bool hintSparkle;
  final bool showMicPulse;
  final VoidCallback onMicHoldStart;
  final VoidCallback onHintTap;
  final void Function({required bool cancel}) onMicHoldEnd;

  const _PlayingLikeDisabledFooter({
    required this.loadingRotationController,
    this.micGuide,
    this.holdToSpeakText,
    this.holdToSpeakVisible = false,
    this.showHintCoach = false,
    this.hintGuide = '',
    this.showMicPointer = false,
    this.guideReserveText,
    this.gapAboveMic = 48,
    this.micEnabled = false,
    this.micLoading = false,
    this.hintEnabled = false,
    this.hintSparkle = false,
    this.showMicPulse = false,
    required this.onMicHoldStart,
    required this.onMicHoldEnd,
    required this.onHintTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (micGuide != null) ...[
              _PinnedGuideSlot(
                reserveText: guideReserveText,
                child: _EnterFade(
                  child: _tutorialGuide(
                    micGuide!,
                    spans: _helloSpans(micGuide!),
                  ),
                ),
              ),
              SizedBox(height: gapAboveMic),
            ] else ...[
              SizedBox(
                height: 24,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: holdToSpeakVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      holdToSpeakText ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              height: roleplayMicFooterStackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (showMicPulse)
                    const Positioned(
                      key: ValueKey('tutorialMicRipple'),
                      left: 0,
                      right: 0,
                      bottom:
                          roleplayMicBottomInsetFromStackBottom +
                          roleplayMicDefaultSize / 2 -
                          _TutorialMicRipple.displaySize / 2,
                      child: IgnorePointer(
                        child: Center(child: _TutorialMicRipple()),
                      ),
                    ),
                  Positioned.fill(
                    key: const ValueKey('tutorialMicButton'),
                    child: RoleplayMicButtonArea(
                      isInteractive: micEnabled && !micLoading,
                      isLoading: micLoading,
                      isDisabled: !micEnabled || micLoading,
                      loadingRotationController: loadingRotationController,
                      onPressStart: onMicHoldStart,
                      onPressEnd: (cancel) => onMicHoldEnd(cancel: cancel),
                      onPressCancel: () => onMicHoldEnd(cancel: true),
                    ),
                  ),
                  Positioned(
                    key: const ValueKey('tutorialMicIcons'),
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: roleplayFooterIconRowHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 40, height: 40),
                          const Expanded(child: SizedBox.shrink()),
                          _HintCoachLayer(
                            show: showHintCoach,
                            guide: hintGuide,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 560),
                              curve: Curves.easeOutCubic,
                              opacity: hintEnabled ? 1 : 0.4,
                              child: GestureDetector(
                                onTap: hintEnabled ? onHintTap : null,
                                child: _HintBulb(sparkle: hintSparkle),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showMicPointer)
                    const Positioned(
                      key: ValueKey('tutorialMicPointer'),
                      right: 74,
                      bottom: -6,
                      child: IgnorePointer(
                        child: TutorialPointer(size: 120, holdGesture: true),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
