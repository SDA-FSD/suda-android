import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../api/endpoints/tutorial_api.dart';
import '../../api/suda_api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../screens/roleplay/playing_conversation_mixin.dart'
    show PlayingConversationLayout;
import '../../screens/roleplay/suda_tts_audio_player.dart';
import '../../services/token_storage.dart';
import '../../effects/mission_complete_effect.dart';
import '../../widgets/default_popup.dart';
import '../../widgets/roleplay_mic_button_area.dart';
import '../../widgets/roleplay_mission_panel.dart';
import '../../widgets/roleplay_turn_bar_area.dart';
import 'tutorial_pointer.dart';
import 'tutorial_roleplay_backdrop.dart';

enum _TutorialRpStage { missionGuide, playing }

/// 마이크 가이드 문구. 기본은 AI 발화 후, 나머지는 홀드/짧은 탭/무인식.
enum _TutorialMicGuide { afterVoice, holding, tooShort, noSpeech }

/// 온보딩 Tutorial Roleplay.
///
/// 1단계: 미션 확인 + Skip → 탭 시 2단계 Playing형 UI(목).
/// 턴바 3칸은 비어 있고, 사용자 대답 시마다 채워짐(이후 연동).
class TutorialRoleplayScreen extends StatefulWidget {
  static const bettyAvatarAsset = 'assets/images/tutorial/tutorial_betty.png';

  final VoidCallback onSkip;
  final bool preview;
  final VoidCallback? onMissionGuideContinue;

  const TutorialRoleplayScreen({
    super.key,
    required this.onSkip,
    this.preview = false,
    this.onMissionGuideContinue,
  });

  @override
  State<TutorialRoleplayScreen> createState() => _TutorialRoleplayScreenState();
}

class _TutorialRoleplayScreenState extends State<TutorialRoleplayScreen>
    with TickerProviderStateMixin {
  static const _bgFadeIn = Duration(seconds: 3);
  /// 영상(2026-10-19 4.01.05): 선명 hold → blur ~0.5s → UI ~0.45s 간격.
  static const _sharpHold = Duration(milliseconds: 600);
  static const _blurReveal = Duration(milliseconds: 550);
  static const _turnCount = 3;

  late final AnimationController _bgFade;
  late final AnimationController _blurUi;
  late final AnimationController _micLoadingRotation;
  late final Animation<double> _chromeOpacity;

  _TutorialRpStage _stage = _TutorialRpStage.missionGuide;

  /// 서버가 받은 사용자 발화 수. 턴바는 최대 3칸, 색은 `#0CABA8`.
  int _answeredTurnCount = 0;
  int _completedMissions = 0;
  final Set<int> _completedMissionIndexes = {};
  final GlobalKey _missionIconAnchorKey = GlobalKey();
  bool _showMissionCompletedFlash = false;
  int _flashMissionIndex = 0;
  Timer? _missionCompleteTimer;
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
  final GlobalKey _hintCardKey = GlobalKey();
  /// 영어 답변을 펼쳤는지. 영어 사용자는 처음부터 펼친다.
  bool _hintAnswerOpen = false;
  /// 두 번째 AI 음성이 끝난 뒤에만 힌트 안내를 띄운다.
  bool _hintCoachReady = false;
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

  /// 영상 참고: Missions 타이틀 → 미션 박스 → 말풍선 → 포인터 순.
  bool _showMissionsTitle = false;
  bool _showMissionBox = false;
  bool _showBubble = false;
  bool _showPointer = false;

  /// 2단계(2026-10-20 1.36.14): 패널만 → 나레이션 → Betty → Hello 말풍선 → 손가락.
  bool _showNarration = false;
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
    _bgFade = AnimationController(vsync: this, duration: _bgFadeIn);
    _blurUi = AnimationController(vsync: this, duration: _blurReveal);
    _micLoadingRotation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chromeOpacity = CurvedAnimation(parent: _blurUi, curve: Curves.easeOut);

    _bgFade.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startBlurUiPhase();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bgFade.forward();
    });
  }

  Future<void> _startBlurUiPhase() async {
    await Future<void>.delayed(_sharpHold);
    if (!mounted) return;
    await _blurUi.forward();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showMissionsTitle = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _showMissionBox = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _showBubble = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showPointer = true);
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
    _micLoadingRotation.dispose();
    _missionCompleteTimer?.cancel();
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

  void _onMissionGuideContinue() {
    if (_stage != _TutorialRpStage.missionGuide) return;
    setState(() => _stage = _TutorialRpStage.playing);
    widget.onMissionGuideContinue?.call();
    _startPlayingIntro();
  }

  /// 탭 후: 접힌 미션+마이크만 → 나레이션 → Betty 말풍선+음성 → 음성 종료 후 안내.
  Future<void> _startPlayingIntro() async {
    final gen = ++_playingIntroGen;
    final soundFuture = _loadOpeningVoice();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!_playingIntroAlive(gen)) return;
    setState(() => _showNarration = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!_playingIntroAlive(gen)) return;
    setState(() => _showBetty = true);
    final sound = await soundFuture;
    if (!_playingIntroAlive(gen)) return;
    await _playOpeningVoice(sound);
    if (!_playingIntroAlive(gen)) return;
    _revealMicGuide();
  }

  bool _playingIntroAlive(int gen) {
    return mounted &&
        _stage == _TutorialRpStage.playing &&
        gen == _playingIntroGen;
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
      if (!mounted || _stage != _TutorialRpStage.playing) return;
      if (_micPermissionGranted) await _armMicSession();
    } catch (e) {
      debugPrint('[DEBUG] tutorial mic prepare: $e');
    }
    if (!mounted || _stage != _TutorialRpStage.playing) return;
    setState(() => _micEnabled = true);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _stage != _TutorialRpStage.playing || !_micEnabled) {
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
      _micGuide = _TutorialMicGuide.holding;
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
      await session.setActive(true);
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
      if (!cancel) _restoreMicGuide(_TutorialMicGuide.tooShort);
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
    _speechLevelSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
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

  void _restoreMicGuide(_TutorialMicGuide guide, {bool revealHint = false}) {
    if (!mounted || _answeredTurnCount >= _turnCount) return;
    setState(() {
      _micEnabled = true;
      _sending = false;
      _showRecordingBubble = false;
      _micPulsing = _showHelloGuide;
      _showMicPointer = _showHelloGuide;
      _micGuide = guide;
      if (revealHint) _hintCoachReady = true;
    });
  }

  Future<void> _sendAudio(List<int> bytes) async {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _restoreMicGuide(_TutorialMicGuide.afterVoice);
      return;
    }
    setState(() {
      _sending = true;
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
      final showTranslation = Localizations.localeOf(context).languageCode != 'en';
      final aiText = response.aiText ?? '';
      final aiMsgId = response.aiMsgId;
      final soundFuture = SudaApiClient.getTutorialAiAudio(
        accessToken: token,
        sessionId: sessionId,
      );
      var missionJustCompleted = false;
      setState(() {
        _lines.add(_TutorialLine.user(response.userText ?? ''));
        if ((response.narration ?? '').isNotEmpty) {
          _lines.add(_TutorialLine.narration(response.narration!));
        }
        if (!showTranslation) _lines.add(_TutorialLine.ai(aiText));
        _answeredTurnCount = (_answeredTurnCount + 1).clamp(0, _turnCount);
        final done = response.missionCompletedIndex;
        if (done != null && done >= 0 && done == _completedMissions) {
          _completedMissionIndexes.add(done);
          _flashMissionIndex = done;
          _showMissionCompletedFlash = true;
          _completedMissions = done + 1;
          missionJustCompleted = true;
        }
        _showHelloGuide = false;
        _hintEnglish = null;
        _hintNative = null;
        _hintAnswerOpen = false;
        _hintPlayingIndex = null;
        if (aiMsgId != null) _lastAiMsgId = aiMsgId;
      });
      armHint = _answeredTurnCount == 1 && !_hintCoachDismissed;
      _scrollTalkToEnd();
      if (missionJustCompleted) _playMissionSuccess();
      if (showTranslation) {
        final translation = aiMsgId == null
            ? null
            : await _fetchTranslation(sessionId, aiMsgId);
        if (!mounted) return;
        setState(() {
          final line = _TutorialLine.ai(aiText);
          line.translation = translation;
          _lines.add(line);
        });
        _scrollTalkToEnd();
      }
      try {
        final sound = await soundFuture;
        if (mounted) await _playOpeningVoice(sound);
      } catch (e) {
        debugPrint('[DEBUG] tutorial ai audio: $e');
      }
      if (!mounted) return;
      await _armMicSession();
      if (!mounted) return;
      if (_answeredTurnCount >= _turnCount) {
        setState(() {
          _sending = false;
          _micEnabled = false;
          _micPulsing = false;
          _showRecordingBubble = false;
        });
        return;
      }
      _restoreMicGuide(
        _TutorialMicGuide.afterVoice,
        revealHint: armHint,
      );
    } on TutorialAudioTooShortException {
      _restoreMicGuide(_TutorialMicGuide.tooShort);
    } on TutorialNoSpeechException {
      _restoreMicGuide(_TutorialMicGuide.noSpeech);
    } catch (e) {
      debugPrint('[DEBUG] tutorial user audio: $e');
      _restoreMicGuide(
        _TutorialMicGuide.afterVoice,
        revealHint: armHint,
      );
    } finally {
      if (_micLoadingRotation.isAnimating) _micLoadingRotation.stop();
    }
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

  /// 목적지·이유 고정 힌트. 인사 Hello는 첫 마이크 안내라 힌트에 넣지 않는다.
  (String, String?) _localHint() {
    final index = _completedMissions <= 1 ? 0 : 1;
    const english = [
      'SUDA City, please.',
      "I'm moving there today.",
    ];
    final code = Localizations.localeOf(context).languageCode;
    const ko = ['수다 빌리지로 가주세요.', '오늘 그곳으로 이사 가요.'];
    const pt = ['Para SUDA City, por favor.', 'Estou me mudando para lá hoje.'];
    final native = switch (code) {
      'ko' => ko[index],
      'pt' => pt[index],
      _ => null,
    };
    return (english[index], native);
  }

  void _applyHint(String english, String? native) {
    final shownNative = (native ?? '').trim();
    setState(() {
      _hintEnglish = english.trim().isEmpty ? null : english.trim();
      _hintNative = shownNative.isEmpty ? null : shownNative;
      _hintAnswerOpen = shownNative.isEmpty;
      _hintCoachDismissed = _hintEnglish != null;
      _hintPlayingIndex = null;
    });
    _scrollHintIntoView();
  }

  Future<void> _onHintTap() async {
    if (_answeredTurnCount < 1 || _hintEnglish != null) return;
    final local = _localHint();
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
      _applyHint(english, hint.translatedHint);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_talkScroll.hasClients) return;
      _talkScroll.animateTo(
        _talkScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
  bool get _mustTapHint => _hintCoachReady && !_hintCoachDismissed;

  bool get _showMicGuideBubble =>
      _showMicGuide &&
      ((_micGuide == _TutorialMicGuide.holding && _micHeld) ||
          _micGuide == _TutorialMicGuide.tooShort ||
          _micGuide == _TutorialMicGuide.noSpeech ||
          (_showHelloGuide && _micGuide == _TutorialMicGuide.afterVoice));

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
    final missionLabels = [
      l10n.tutorialRoleplayMission1,
      l10n.tutorialRoleplayMission2,
      l10n.tutorialRoleplayMission3,
    ];

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
                Opacity(
                  opacity: bgOpacity,
                  child: TutorialRoleplayBackdrop(blurAmount: blurAmount),
                ),
                if (_blurUi.value > 0)
                  FadeTransition(
                    opacity: _chromeOpacity,
                    child: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: _stage == _TutorialRpStage.missionGuide
                                  ? KeyedSubtree(
                                      key: const ValueKey('guide'),
                                      child: _buildMissionGuideBody(
                                        l10n,
                                        theme,
                                        missionLabels,
                                      ),
                                    )
                                  : KeyedSubtree(
                                      key: const ValueKey('playing'),
                                      child: _buildPlayingBody(l10n, theme),
                                    ),
                            ),
                          ),
                          _PlayingLikeDisabledFooter(
                            loadingRotationController: _micLoadingRotation,
                            micGuide: _showMicGuideBubble
                                ? _micGuideText(l10n)
                                : null,
                            showHintCoach: _mustTapHint,
                            hintGuide: l10n.tutorialRoleplayHintGuide,
                            showMicPointer: _showMicPointer && _showHelloGuide,
                            guideNearMic: !_showHelloGuide,
                            guideReserveText: l10n.tutorialRoleplayHoldHello,
                            micEnabled: _micEnabled && !_mustTapHint,
                            micLoading: _sending,
                            hintEnabled: _hintCoachReady,
                            showMicPulse: _micPulsing,
                            onMicHoldStart: _onMicHoldStart,
                            onMicHoldEnd: _onMicHoldEnd,
                            onHintTap: _onHintTap,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMissionGuideBody(
    AppLocalizations l10n,
    TextTheme theme,
    List<String> missions,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onMissionGuideContinue,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            const Spacer(flex: 2),
            _StaggerFade(
              visible: _showMissionsTitle,
              child: Text(
                l10n.tutorialRoleplayMissions,
                textAlign: TextAlign.center,
                style: theme.headlineLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _StaggerFade(
              visible: _showMissionBox,
              child: _MissionListBox(missions: missions),
            ),
            const SizedBox(height: 18),
            _StaggerFade(
              visible: _showBubble,
              child: _GuideBubble(
                mainText: l10n.tutorialRoleplayGuideMissionMain,
                subText: l10n.tutorialRoleplayGuideMissionTapContinue,
                showPointer: _showPointer,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
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
                        visible: _showNarration,
                        child: _TutorialNarration(
                          text: l10n.tutorialRoleplayNarration1,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                        const SizedBox(height: 14),
                        if (line.kind == _TutorialLineKind.user)
                          _TutorialUserBubble(text: line.text)
                        else if (line.kind == _TutorialLineKind.narration)
                          _TutorialNarration(text: line.text)
                        else
                          _TutorialAiBubble(
                            english: line.text,
                            translation: showTranslation ? line.translation : null,
                          ),
                      ],
                      if (_hintEnglish != null) ...[
                        const SizedBox(height: 14),
                        KeyedSubtree(
                          key: _hintCardKey,
                          child: _RoleplayHintCard(
                          label: l10n.roleplayHintLabel,
                          showAnswerLabel: l10n.roleplayHintShowAnswer,
                          english: _hintEnglish!,
                          native: _hintNative,
                          answerOpen: _hintAnswerOpen,
                          playingIndex: _hintPlayingIndex,
                          onReveal: () => setState(() => _hintAnswerOpen = true),
                          onWord: (index) => unawaited(_playHintSound(wordIndex: index)),
                          onSentence: () => unawaited(_playHintSound()),
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
                        : _completedMissions.clamp(0, _turnCount - 1),
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

enum _TutorialLineKind { user, narration, ai }

class _TutorialLine {
  final _TutorialLineKind kind;
  final String text;
  String? translation;

  _TutorialLine.user(this.text) : kind = _TutorialLineKind.user;
  _TutorialLine.narration(this.text) : kind = _TutorialLineKind.narration;
  _TutorialLine.ai(this.text) : kind = _TutorialLineKind.ai;
}

/// 본편 `playing_hint_mixin` 힌트 상자와 같은 막대·번역·버튼·점선 단어.
class _RoleplayHintCard extends StatelessWidget {
  static const _bg = Color(0xFF194847);
  static const _accent = Color(0xFF80D7CF);
  static const _bar = Color(0xFF054544);
  static const _play = Color(0xFF0CABA8);
  static const _button = Color(0xFF076766);
  static const _buttonText = Color(0xFF1B3B3B);

  final String label;
  final String showAnswerLabel;
  final String english;
  final String? native;
  final bool answerOpen;
  final int? playingIndex;
  final VoidCallback onReveal;
  final void Function(int index)? onWord;
  final VoidCallback? onSentence;

  const _RoleplayHintCard({
    required this.label,
    required this.showAnswerLabel,
    required this.english,
    required this.native,
    required this.answerOpen,
    required this.playingIndex,
    required this.onReveal,
    this.onWord,
    this.onSentence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNative = native != null && native!.isNotEmpty;
    final showEnglish = answerOpen || !hasNative;
    final labelStyle =
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{})
            ?.copyWith(color: _accent) ??
        theme.textTheme.bodyMedium?.copyWith(color: _accent);
    final buttonStyle =
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{})
            ?.copyWith(color: _buttonText) ??
        theme.textTheme.bodyMedium?.copyWith(color: _buttonText);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bar,
              borderRadius: BorderRadius.circular(13.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
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
                Text(label, style: labelStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
          if (hasNative)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(
                native!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: _accent),
              ),
            ),
          if (!showEnglish)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: Material(
                    color: _button,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: onReveal,
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Text(
                          showAnswerLabel,
                          style: buttonStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            _HintAnswerWords(
              english: english,
              playingIndex: playingIndex,
              onWord: onWord,
              onSentence: onSentence,
            ),
        ],
      ),
    );
  }
}

class _HintAnswerWords extends StatelessWidget {
  final String english;
  final int? playingIndex;
  final void Function(int index)? onWord;
  final VoidCallback? onSentence;

  const _HintAnswerWords({
    required this.english,
    required this.playingIndex,
    this.onWord,
    this.onSentence,
  });

  @override
  Widget build(BuildContext context) {
    final words = english
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final headline =
        Theme.of(context).textTheme.headlineSmall ??
        Theme.of(context).textTheme.bodyLarge;
    final playing = playingIndex != null;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: GestureDetector(
                onTap: onSentence,
                behavior: HitTestBehavior.opaque,
                child: Image.asset(
                  playing
                      ? 'assets/images/icons/megaphone_fill.png'
                      : 'assets/images/icons/megaphone.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
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
                      highlighted:
                          playingIndex == -1 || playingIndex == i,
                      onTap: onWord == null ? null : () => onWord!(i),
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

class _HintWord extends StatelessWidget {
  final String word;
  final TextStyle? headline;
  final bool highlighted;
  final VoidCallback? onTap;

  const _HintWord({
    required this.word,
    required this.headline,
    required this.highlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = headline?.copyWith(
      color: highlighted ? _RoleplayHintCard._play : Colors.white,
      height: 1.35,
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
                color: _RoleplayHintCard._play,
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

  _HintRingPainter({required this.innerRadius, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final center = Offset(size.width / 2, size.height / 2);
    final color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _HintAimRingsState._innerStroke;
    final outer = Paint()
      ..color = color.withValues(alpha: (opacity * 0.85).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = _HintAimRingsState._outerStroke;
    canvas.drawCircle(center, innerRadius, inner);
    canvas.drawCircle(center, innerRadius + _HintAimRingsState._gap, outer);
  }

  @override
  bool shouldRepaint(covariant _HintRingPainter oldDelegate) =>
      oldDelegate.innerRadius != innerRadius || oldDelegate.opacity != opacity;
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
              offset: Offset(
                _HintCoachBubble.tailEndInset + _HintCoachBubble.tailWidth / 2,
                -4 + (1 - t) * 18,
              ),
              child: Opacity(
                opacity: t,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(decoration: TextDecoration.none),
                  child: _HintCoachBubble(text: widget.guide),
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

/// 힌트 버튼 위에 붙는 안내. 꼬리는 버튼 가운데를 가리킨다.
class _HintCoachBubble extends StatelessWidget {
  static const tailWidth = 18.0;
  static const tailEndInset = 27.0;

  final String text;

  const _HintCoachBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.headlineSmall;
    final style = TextStyle(
      fontFamily: heading?.fontFamily,
      fontFamilyFallback: heading?.fontFamilyFallback,
      fontSize: heading?.fontSize ?? 20,
      fontWeight: heading?.fontWeight ?? FontWeight.w700,
      fontVariations: heading?.fontVariations,
      letterSpacing: heading?.letterSpacing,
      color: Colors.white,
      decoration: TextDecoration.none,
    );
    final maxWidth = (MediaQuery.sizeOf(context).width - 72).clamp(200.0, 340.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFF0CABA8),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Text(text, textAlign: TextAlign.center, style: style),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: const Padding(
            padding: EdgeInsetsDirectional.only(end: _HintCoachBubble.tailEndInset),
            child: CustomPaint(
              size: Size(_HintCoachBubble.tailWidth, 12),
              painter: _HintCoachTailPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HintCoachTailPainter extends CustomPainter {
  const _HintCoachTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0CABA8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

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
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

/// Playing AI 말풍선과 동일 톤. 번역 버튼 없이 번역 문장 상시 노출(영어 로케일 제외).
class _TutorialAiBubble extends StatelessWidget {
  final String english;
  final String? translation;

  const _TutorialAiBubble({required this.english, this.translation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final textStyle = theme.bodyMedium?.copyWith(color: Colors.white);
    final translationStyle =
        theme.labelSmall?.copyWith(color: const Color(0xFF777373));

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

/// 시안: radius 26 · 흰 6.8% 채우기 + Playing 미션 패널과 동일 BackdropFilter blur 12.
class _MissionListBox extends StatelessWidget {
  static const _radius = 26.0;
  /// 시안 채우기 `#FFFFFF` 6.8%.
  static final _fill = Colors.white.withValues(alpha: 0.068);

  final List<String> missions;

  const _MissionListBox({required this.missions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.36),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              children: [
                for (var i = 0; i < missions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/icons/rps2_mission_off.png',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          missions[i],
                          style: theme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideBubble extends StatelessWidget {
  static const _fill = Color(0xFF0CABA8);
  static const _sub = Color(0xFF054544);

  final String mainText;
  final String subText;
  final bool showPointer;

  const _GuideBubble({
    required this.mainText,
    required this.subText,
    required this.showPointer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 10),
          painter: const _BubbleTailPainter(color: _fill),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                mainText,
                textAlign: TextAlign.center,
                style: theme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subText,
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium?.copyWith(color: _sub),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: _sub,
                          size: 20,
                        ),
                      ],
                    ),
                    if (showPointer)
                      const Positioned(
                        right: -80,
                        top: -22,
                        child: IgnorePointer(
                          child: TutorialPointer(size: 120),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
          child: _MicGuideBubble(text: reserve),
        ),
        child,
      ],
    );
  }
}

class _MicGuideBubble extends StatelessWidget {
  static const _fill = Color(0xFF0CABA8);

  final String text;

  const _MicGuideBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text.rich(
            TextSpan(
              style: theme.headlineSmall?.copyWith(color: Colors.white),
              children: _helloSpans(text),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        CustomPaint(
          size: const Size(18, 10),
          painter: const _BubbleTailDownPainter(color: _fill),
        ),
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

class _BubbleTailDownPainter extends CustomPainter {
  final Color color;

  const _BubbleTailDownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailDownPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;

  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// `ic_mic_ripple_01`~`04` 루프. 흰 버튼 지름은 Playing 마이크(100)에 맞춤.
class _TutorialMicRipple extends StatefulWidget {
  static const frames = [
    'assets/images/tutorial/ic_mic_ripple_01.png',
    'assets/images/tutorial/ic_mic_ripple_02.png',
    'assets/images/tutorial/ic_mic_ripple_03.png',
    'assets/images/tutorial/ic_mic_ripple_04.png',
  ];

  /// 에셋 462, 흰 원 지름 300 → 화면 마이크 100.
  static const displaySize = 462 * roleplayMicDefaultSize / 300;

  const _TutorialMicRipple();

  @override
  State<_TutorialMicRipple> createState() => _TutorialMicRippleState();
}

class _TutorialMicRippleState extends State<_TutorialMicRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final index =
            (_controller.value * _TutorialMicRipple.frames.length).floor() %
            _TutorialMicRipple.frames.length;
        return Image.asset(
          _TutorialMicRipple.frames[index],
          width: _TutorialMicRipple.displaySize,
          height: _TutorialMicRipple.displaySize,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

/// Playing `buildPlayingFooter` 녹음 모드와 동일 크기·위치. 타이핑 토글만 비노출(빈 40슬롯).
class _PlayingLikeDisabledFooter extends StatelessWidget {
  final AnimationController loadingRotationController;
  final String? micGuide;
  final bool showHintCoach;
  final String hintGuide;
  final bool showMicPointer;

  /// 첫 발화 후 펄스가 없으므로 가이드를 마이크 쪽으로 내린다.
  final bool guideNearMic;

  /// 누르는 순간 문구가 줄어도 마이크가 움직이지 않게 잡아 두는 높이.
  final String? guideReserveText;
  final bool micEnabled;
  final bool micLoading;
  final bool hintEnabled;
  final bool showMicPulse;
  final VoidCallback onMicHoldStart;
  final VoidCallback onHintTap;
  final void Function({required bool cancel}) onMicHoldEnd;

  const _PlayingLikeDisabledFooter({
    required this.loadingRotationController,
    this.micGuide,
    this.showHintCoach = false,
    this.hintGuide = '',
    this.showMicPointer = false,
    this.guideNearMic = false,
    this.guideReserveText,
    this.micEnabled = false,
    this.micLoading = false,
    this.hintEnabled = false,
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
                reserveText: guideNearMic ? null : guideReserveText,
                child: _EnterFade(child: _MicGuideBubble(text: micGuide!)),
              ),
              SizedBox(height: guideNearMic ? 12 : 48),
            ] else ...[
              const SizedBox(height: 24),
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
                      bottom: roleplayMicBottomInsetFromStackBottom +
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
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/icons/lightball.png',
                                      height: 24,
                                      width: 24,
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
                  if (showMicPointer)
                    const Positioned(
                      key: ValueKey('tutorialMicPointer'),
                      right: 74,
                      bottom: -6,
                      child: IgnorePointer(
                        child: TutorialPointer(
                          size: 120,
                          holdGesture: true,
                        ),
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
