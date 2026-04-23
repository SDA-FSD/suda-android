import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/roleplay_models.dart';
import '../../widgets/roleplay_overview_backdrop.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/appsflyer_service.dart';
import '../../api/endpoints/roleplay_api.dart' as rp_api;
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/suda_json_util.dart';

/// Roleplay Playing Screen (Full Screen)
///
/// Roleplay 진행 중 화면
class RoleplayPlayingScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayPlayingScreen({super.key, this.showCloseButton = true});

  @override
  State<RoleplayPlayingScreen> createState() => _RoleplayPlayingScreenState();
}

class _RoleplayPlayingScreenState extends State<RoleplayPlayingScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSteps = 0;
  int _currentStep = 0;
  bool _isUserTurn = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _recordingStartedAt;
  bool _isRecording = false;
  Timer? _narrationDelayTimer;
  bool _hasHandledInitialTurn = false;
  Future<RoleplayNarrationDto?>? _pendingNarration;
  bool _isHintEnabled = false;
  bool _hintUsedThisTurn = false;
  Timer? _hintIdleTimer;
  late final AnimationController _hintBlinkController;
  StreamSubscription<PlayerState>? _hintPlaybackSub;
  final List<_ConversationEntry> _conversationEntries = [];
  _ConversationEntry? _recordingEntry;
  Timer? _serviceMessageTimer;
  bool _isServiceMessageVisible = false;
  String? _serviceMessageText;
  Color? _serviceMessageColor;
  int _nextConversationIndex = 0;
  bool _wasMissionActive = false;
  final Map<int, _MissionStatus> _missionStatuses = {};
  final Map<int, _MissionStatus> _animatingSteps = {};
  _MicButtonState _micState = _MicButtonState.defaultState;
  _InputMode _inputMode = _InputMode.recording;
  final FocusNode _typingFocusNode = FocusNode();
  final TextEditingController _typingController = TextEditingController();
  bool _isTypingEnabled = true;
  bool _isSpeedPanelVisible = false;
  int _speedIndex = 0;
  int _committedSpeedIndex = 0;
  late final AnimationController _loadingRotationController;
  late final AnimationController _analyzingBlinkController;
  bool _isTimesupAnalyzing = false;
  bool _isAnalyzingBlinking = false;
  bool _timesupWhileRecording = false;
  bool _pendingAnalyzingAfterAi = false;
  Timer? _analyzingDelayTimer;
  bool _showExitLayer = false;
  static const double _headerTopSpacingDelta = 38;
  static const List<int> _speedRateSteps = [150, 120, 100, 70];

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
    _initializeProgressState();
    _initializeSpeedRate();
    _loadingRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hintBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _analyzingBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AppsflyerService.logEvent('rp_started'));
      _handleInitialTurn();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _narrationDelayTimer?.cancel();
    _serviceMessageTimer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    _typingFocusNode.dispose();
    _typingController.dispose();
    _loadingRotationController.dispose();
    _hintIdleTimer?.cancel();
    _hintIdleTimer = null;
    _hintBlinkController.dispose();
    _analyzingBlinkController.dispose();
    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
    _analyzingDelayTimer?.cancel();
    _analyzingDelayTimer = null;
    super.dispose();
  }

  void _initializeCountdown() {
    final roleplay = RoleplayStateService.instance.overview?.roleplay;
    _remainingSeconds = _parseDurationSeconds(roleplay?.duration);
    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _timer?.cancel();
          _timer = null;
        }
      });
      if (_remainingSeconds == 0) {
        _onTimesupReached();
      }
    });
  }

  void _onTimesupReached() {
    if (_isTimesupAnalyzing || _timesupWhileRecording) return;
    if (_isRecording) {
      _timesupWhileRecording = true;
      return;
    }
    _startTimesupAnalyzing(_TimesupReason.immediate);
  }

  void _initializeProgressState() {
    final overview = RoleplayStateService.instance.overview;
    final roleplay = overview?.roleplay;
    final roleId = RoleplayStateService.instance.roleId;
    final selectedRole = roleplay?.roleList?.firstWhere(
      (r) => r.id == roleId,
      orElse: () => roleplay.roleList!.first,
    );

    _totalSteps = selectedRole?.scenarioFlow?.length ?? 0;
    _currentStep = 0;
    _missionStatuses.clear();

    for (final mission in selectedRole?.missionList ?? const []) {
      final index = mission.scenarioFlowIndex;
      if (index != null) {
        _missionStatuses[index] = _MissionStatus.ready;
      }
    }
  }

  void _initializeSpeedRate() {
    final metaInfo = RoleplayStateService.instance.user?.metaInfo;
    int initialRate = 100;
    if (metaInfo != null) {
      for (final item in metaInfo) {
        if (item.key == 'RP_SPEED_RATE') {
          final parsed = int.tryParse(item.value);
          if (parsed != null) {
            initialRate = parsed;
          }
          break;
        }
      }
    }
    _speedIndex = _speedRateIndexForValue(initialRate);
    _committedSpeedIndex = _speedIndex;
  }

  void _handleInitialTurn() {
    if (_hasHandledInitialTurn) return;
    _hasHandledInitialTurn = true;
    final isUserTurn = RoleplayStateService.instance.isUserTurnYn == 'Y';
    if (isUserTurn) {
      _handleUserStart();
    } else {
      _handleAiStart();
    }
  }

  bool get _isUserStarterRoleplay {
    final roleId = RoleplayStateService.instance.roleId;
    final starterKey =
        RoleplayStateService.instance.overview?.roleplay?.starter?.key;
    if (roleId == null || starterKey == null) return false;
    return roleId.toString() == starterKey;
  }

  void _handleUserStart() {
    _activateUserTurn();
    if (!_isUserStarterRoleplay) return;
    final starterText = _getStarterText();
    if (starterText == null || starterText.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final guideText = l10n?.sayLineBelowToStart ?? '';
    final entry = _ConversationEntry.hintStarter(
      text: starterText,
      guideText: guideText,
    );
    entry.isVisible = true;
    setState(() {
      _conversationEntries.add(entry);
    });
    _hintUsedThisTurn = true;
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    _scrollHintEntryToBottom(entry);
  }

  Future<void> _handleAiStart() async {
    _setUserTurn(false);
    _setMicState(_MicButtonState.disabled);
    final starterText = _getStarterText();
    if (starterText == null || starterText.isEmpty) return;
    final session = RoleplayStateService.instance.session;
    await _showAiMessage(
      text: starterText,
      cdnYn: session?.aiSoundCdnYn,
      cdnPath: session?.aiSoundCdnPath,
      soundBytes: session?.aiSoundFile,
    );
  }

  String? _getStarterText() {
    return RoleplayStateService.instance.overview?.roleplay?.starter?.value;
  }

  RoleplayRoleDto? _getSelectedRole() {
    final roleplay = RoleplayStateService.instance.overview?.roleplay;
    final roles = roleplay?.roleList;
    final roleId = RoleplayStateService.instance.roleId;
    if (roles == null || roles.isEmpty) return null;
    return roles.firstWhere(
      (role) => role.id == roleId,
      orElse: () => roles.first,
    );
  }

  String? _getUserRoleAvatarUrl() {
    final avatarPath = _getSelectedRole()?.avatarImgPath;
    if (avatarPath == null || avatarPath.isEmpty) return null;
    return '${AppConfig.cdnBaseUrl}$avatarPath';
  }

  Future<void> _showAiMessage({
    required String text,
    String? cdnYn,
    String? cdnPath,
    Uint8List? soundBytes,
  }) async {
    final entry = _ConversationEntry.ai(text: text);
    _resetHintPlaybackHighlight();
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    _prepareNarrationAfterAiStart();
    final audioSource = await _prepareAiVoice(
      cdnYn: cdnYn,
      cdnPath: cdnPath,
      soundBytes: soundBytes,
    );
    if (!mounted) return;
    debugPrint('[DEBUG] AI message start: ${DateTime.now().toIso8601String()}');
    _addEntry(entry, revealImmediately: true);
    debugPrint(
      '[DEBUG] AI bubble visible: ${DateTime.now().toIso8601String()}',
    );
    final voiceDuration = _audioPlayer.duration;
    final fallbackMs = (text.length * 70).clamp(500, 15000);
    final delayMs = voiceDuration?.inMilliseconds ?? fallbackMs;
    _narrationDelayTimer?.cancel();
    _analyzingDelayTimer?.cancel();
    _analyzingDelayTimer = null;
    if (_pendingAnalyzingAfterAi) {
      _analyzingDelayTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        _analyzingDelayTimer = null;
        _onAiPlaybackEnded();
      });
    }
    if (audioSource != null) {
      unawaited(_playPreparedAiVoice(audioSource));
    }
    _narrationDelayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _showNarrationAfterAiMessage();
    });
  }

  void _onAiPlaybackEnded() {
    if (!mounted) return;
    if (!_pendingAnalyzingAfterAi) return;
    _pendingAnalyzingAfterAi = false;
    _startAnalyzingBlink();
  }

  void _prepareNarrationAfterAiStart() {
    final sessionId = RoleplayStateService.instance.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _pendingNarration = Future.value(null);
      return;
    }
    _pendingNarration = _fetchNarrationWithRetry(sessionId);
  }

  Future<RoleplayNarrationDto?> _fetchNarrationWithRetry(
    String sessionId,
  ) async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (accessToken == null) return null;
    // 150/250/400/700/1500ms × 3 each = 15 retries
    const delays = [
      Duration(milliseconds: 150),
      Duration(milliseconds: 150),
      Duration(milliseconds: 150),
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
      Duration(milliseconds: 400),
      Duration(milliseconds: 400),
      Duration(milliseconds: 400),
      Duration(milliseconds: 700),
      Duration(milliseconds: 700),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1500),
      Duration(milliseconds: 1500),
      Duration(milliseconds: 1500),
    ];
    int attempt = 0;
    while (true) {
      try {
        final result = await SudaApiClient.getRoleplayNarration(
          accessToken: accessToken,
          rpSessionId: sessionId,
        );
        if (attempt == 0) {
          debugPrint('[DEBUG] Narration received: 대기 없이 최초 호출');
        } else {
          debugPrint(
            '[DEBUG] Narration received: ${attempt}번째 대기(${delays[attempt - 1].inMilliseconds}ms) 후',
          );
        }
        return result;
      } catch (e) {
        final message = e.toString();
        final shouldRetry =
            message.contains('HTTP 202') || message.contains('HTTP 500');
        if (!shouldRetry || attempt >= delays.length) {
          if (attempt >= delays.length) {
            debugPrint('[DEBUG] Narration: 15회 재시도 소진 후 실패 (last: $e)');
          }
          return null;
        }
        await Future.delayed(delays[attempt]);
        attempt += 1;
      }
    }
  }

  Future<void> _showNarrationAfterAiMessage() async {
    final narration = await _pendingNarration;
    if (!mounted) return;
    if (narration == null) {
      _stopAnalyzingBlink();
      _showServiceMessage('Network Error', persistent: true);
      return;
    }
    if (narration.resultId != null) {
      _handleResultIdEnding(narration);
      return;
    }
    if (narration.text == null || narration.text!.isEmpty) {
      debugPrint('[DEBUG] Narration skip: text null or empty');
      _stopAnalyzingBlink();
      return;
    }
    final step = narration.currentStep;
    if (step != null) {
      _setProgressToStep(step);
    }
    _wasMissionActive = narration.missionActiveYn == 'Y';
    _stopAnalyzingBlink();
    final entry = _ConversationEntry.narration(narration: narration);
    await _addEntry(entry);
    _activateUserTurn();
  }

  void _activateUserTurn() {
    _hintUsedThisTurn = false;
    _setUserTurn(true);
    _setMicState(_MicButtonState.defaultState);
    _setHintEnabled(true);
    _setTypingEnabled(true);
    if (_inputMode == _InputMode.typing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_inputMode == _InputMode.typing &&
            _isTypingEnabled &&
            _isUserTurn &&
            _typingFocusNode.context != null) {
          _typingFocusNode.requestFocus();
        }
      });
    }
    if (_inputMode == _InputMode.recording) {
      _showHoldToSpeakMessage();
      _hintIdleTimer?.cancel();
      _hintIdleTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_isUserTurn &&
            _inputMode == _InputMode.recording &&
            _isHintEnabled &&
            !_hintUsedThisTurn) {
          _hintBlinkController.repeat(reverse: true);
        }
      });
    }
  }

  void _setUserTurn(bool isUserTurn) {
    RoleplayStateService.instance.setIsUserTurnYn(isUserTurn ? 'Y' : 'N');
    if (!mounted) return;
    setState(() {
      _isUserTurn = isUserTurn;
      if (!isUserTurn) {
        _isTypingEnabled = false;
      }
    });
  }

  void _setHintEnabled(bool isEnabled) {
    if (!mounted) return;
    setState(() {
      _isHintEnabled = isEnabled;
    });
  }

  void _cancelHintIdleAndBlink() {
    _hintIdleTimer?.cancel();
    _hintIdleTimer = null;
    if (_hintBlinkController.isAnimating) {
      _hintBlinkController.stop();
      _hintBlinkController.reset();
    }
  }

  Future<void> _onHintTap() async {
    if (!_isHintEnabled) return;
    _hintUsedThisTurn = true;
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;

    final entry = _ConversationEntry.hintLoading();
    await _addEntry(entry);

    try {
      final text = await SudaApiClient.getRoleplayHint(
        accessToken: accessToken,
        rpSessionId: sessionId,
      );
      if (!mounted) return;
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        _removeConversationEntry(entry);
        return;
      }
      setState(() {
        entry.hintIsLoading = false;
        entry.text = trimmed;
      });
      _scrollHintEntryToBottom(entry);
    } catch (e) {
      debugPrint('[DEBUG] Hint API error: $e');
      if (!mounted) return;
      _removeConversationEntry(entry);
    }
  }

  void _removeConversationEntry(_ConversationEntry entry) {
    if (!mounted) return;
    setState(() {
      _conversationEntries.remove(entry);
    });
  }

  void _resetHintPlaybackHighlight() {
    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
    var changed = false;
    for (final e in _conversationEntries) {
      if (e.type == _ConversationEntryType.hint &&
          (e.hintSentenceHighlightActive || e.hintWordHighlightIndex != null)) {
        e.hintSentenceHighlightActive = false;
        e.hintWordHighlightIndex = null;
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  void _scrollHintEntryToBottom(_ConversationEntry entry) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = entry.key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onHintMegaphoneTap(_ConversationEntry entry) async {
    if (entry.type != _ConversationEntryType.hint || entry.hintIsLoading) {
      return;
    }
    setState(() {
      entry.hintSentenceHighlightActive = true;
      entry.hintWordHighlightIndex = null;
    });
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;
    await _playHintAudio(
      entry,
      'full',
      () => SudaApiClient.getRoleplayHintAudio(
        accessToken: accessToken,
        rpSessionId: sessionId,
      ),
    );
  }

  Future<void> _onHintWordTap(_ConversationEntry entry, int wordIndex) async {
    if (entry.type != _ConversationEntryType.hint || entry.hintIsLoading) {
      return;
    }
    setState(() {
      entry.hintSentenceHighlightActive = false;
      entry.hintWordHighlightIndex = wordIndex;
    });
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;
    await _playHintAudio(
      entry,
      'w$wordIndex',
      () => SudaApiClient.getRoleplayHintWordAudio(
        accessToken: accessToken,
        rpSessionId: sessionId,
        wordIndex: wordIndex,
      ),
    );
  }

  Future<void> _playHintAudio(
    _ConversationEntry entry,
    String cacheKey,
    Future<TtsResultDto> Function() fetch,
  ) async {
    final sessionId = RoleplayStateService.instance.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    final cache = entry.hintAudioCache;
    if (cache == null) return;

    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
    await _audioPlayer.stop();

    late TtsResultDto dto;
    try {
      if (cache.containsKey(cacheKey)) {
        dto = cache[cacheKey]!;
      } else {
        dto = await fetch();
        cache[cacheKey] = dto;
      }
    } catch (e) {
      debugPrint('[DEBUG] Hint audio error: $e');
      if (mounted) {
        setState(() {
          entry.hintSentenceHighlightActive = false;
          entry.hintWordHighlightIndex = null;
        });
      }
      return;
    }
    if (!mounted) return;

    final source = await _prepareAiVoice(
      cdnYn: dto.cdnYn,
      cdnPath: dto.cdnPath,
      soundBytes: dto.sound,
    );
    if (source == null) {
      if (mounted) {
        setState(() {
          entry.hintSentenceHighlightActive = false;
          entry.hintWordHighlightIndex = null;
        });
      }
      return;
    }

    _hintPlaybackSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _hintPlaybackSub?.cancel();
        _hintPlaybackSub = null;
        if (!mounted) return;
        setState(() {
          entry.hintSentenceHighlightActive = false;
          entry.hintWordHighlightIndex = null;
        });
      }
    });
    await _playPreparedAiVoice(source);
  }

  void _setTypingEnabled(bool isEnabled) {
    if (!mounted) return;
    setState(() {
      _isTypingEnabled = isEnabled;
    });
  }

  Future<AudioSource?> _prepareAiVoice({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    final bytes = soundBytes;
    await _audioPlayer.stop();
    if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
      final url = '${AppConfig.cdnBaseUrl}$cdnPath';
      final source = AudioSource.uri(Uri.parse(url));
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    if (bytes != null && bytes.isNotEmpty) {
      final source = AudioSource.uri(
        Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
      );
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    return null;
  }

  Future<Duration?> _playPreparedAiVoice(AudioSource? source) async {
    if (source == null) return null;
    await _audioPlayer.play();
    debugPrint('[DEBUG] AI voice play: ${DateTime.now().toIso8601String()}');
    return _audioPlayer.duration;
  }

  int _speedRateIndexForValue(int value) {
    final index = _speedRateSteps.indexOf(value);
    if (index >= 0) return index;
    final defaultIndex = _speedRateSteps.indexOf(100);
    return defaultIndex >= 0 ? defaultIndex : 0;
  }

  int _speedRateValueForIndex(int index) {
    final clamped = index.clamp(0, _speedRateSteps.length - 1);
    return _speedRateSteps[clamped];
  }

  void _toggleSpeedPanel() {
    setState(() {
      _isSpeedPanelVisible = !_isSpeedPanelVisible;
    });
  }

  void _dismissSpeedPanel() {
    if (!_isSpeedPanelVisible) return;
    _commitSpeedIndex();
    if (!mounted) return;
    setState(() {
      _isSpeedPanelVisible = false;
    });
  }

  void _setSpeedIndexFromOffset({
    required double dy,
    required double railHeight,
    required bool commit,
  }) {
    final stepGap = railHeight / (_speedRateSteps.length - 1);
    final nextIndex = (dy / stepGap).round().clamp(
      0,
      _speedRateSteps.length - 1,
    );
    if (_speedIndex != nextIndex) {
      setState(() {
        _speedIndex = nextIndex;
      });
    }
    if (commit) {
      _commitSpeedIndex();
    }
  }

  void _commitSpeedIndex() {
    if (_committedSpeedIndex == _speedIndex) return;
    _committedSpeedIndex = _speedIndex;
    _updateSpeedRate(_speedRateValueForIndex(_speedIndex));
  }

  Future<void> _updateSpeedRate(int speedRate) async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (accessToken == null) return;
    try {
      await SudaApiClient.updateRoleplaySpeedRate(
        accessToken: accessToken,
        speedRate: speedRate.toString(),
      );
    } catch (_) {
      // ignore errors per requirement
    }
  }

  int _parseDurationSeconds(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final parts = raw.split(':');
    if (parts.length < 3) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  String _formatRemaining() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _maxStepIndex => _totalSteps <= 0 ? 0 : _totalSteps - 1;

  void _setProgressToStep(int stepIndex) {
    if (!mounted) return;
    final clamped = stepIndex.clamp(0, _maxStepIndex);
    setState(() {
      _currentStep = clamped;
    });
  }

  void _setMissionSuccess(int stepIndex) {
    if (!_missionStatuses.containsKey(stepIndex)) return;
    final previous = _missionStatuses[stepIndex];
    setState(() {
      _missionStatuses[stepIndex] = _MissionStatus.success;
      if (previous != _MissionStatus.success) {
        _animatingSteps[stepIndex] = _MissionStatus.success;
      }
    });
  }

  void _setMissionFailed(int stepIndex) {
    if (!_missionStatuses.containsKey(stepIndex)) return;
    final previous = _missionStatuses[stepIndex];
    setState(() {
      _missionStatuses[stepIndex] = _MissionStatus.failed;
      if (previous != _MissionStatus.failed) {
        _animatingSteps[stepIndex] = _MissionStatus.failed;
      }
    });
  }

  bool get _isMicInteractive =>
      _micState == _MicButtonState.defaultState && _isUserTurn;

  void _setMicState(_MicButtonState next) {
    if (_micState == next) return;
    setState(() {
      _micState = next;
    });
    _syncLoadingAnimation();
  }

  void _onMicPressStart() {
    _beginRecording();
  }

  void _onMicPressEnd(bool cancel) {
    if (cancel) {
      _cancelRecording();
    } else {
      _finishRecording();
    }
  }

  void _onMicPressCancel() {
    _cancelRecording();
  }

  void _syncLoadingAnimation() {
    if (_micState == _MicButtonState.loading) {
      if (!_loadingRotationController.isAnimating) {
        _loadingRotationController.repeat();
      }
    } else {
      if (_loadingRotationController.isAnimating) {
        _loadingRotationController.stop();
      }
      _loadingRotationController.reset();
    }
  }

  void _handleSend() {
    if (!_isTypingEnabled || !_isUserTurn) return;
    final text = _typingController.text.trim();
    if (text.isEmpty) return;
    _typingController.clear();
    _setTypingEnabled(false);
    _setUserTurn(false);
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    _sendUserMessageText(text);
  }

  void _cancelRecording() {
    debugPrint('[DEBUG] Recording cancelled');
    _stopRecording(discard: true);
    _removeRecordingEntry();
    if (_timesupWhileRecording) {
      _timesupWhileRecording = false;
      _startTimesupAnalyzing(_TimesupReason.afterCancel);
    } else {
      _setMicState(_MicButtonState.defaultState);
    }
  }

  Future<void> _beginRecording() async {
    if (_isRecording) return;
    _cancelHintIdleAndBlink();
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final path =
        '${Directory.systemTemp.path}/rp_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingStartedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _isRecording = true;
    _showRecordingEntry();
  }

  Future<void> _finishRecording() async {
    if (!_isRecording) {
      _setMicState(_MicButtonState.defaultState);
      _showHoldToSpeakMessage();
      return;
    }
    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    final durationMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    final path = await _stopRecording();
    _removeRecordingEntry();
    debugPrint(
      '[DEBUG] Recording finish start durationMs=$durationMs hasPath=${path != null}',
    );
    if (durationMs < 500) {
      _deleteRecordingFile(path);
      _setMicState(_MicButtonState.defaultState);
      _showHoldToSpeakMessage();
      debugPrint('[DEBUG] Recording finish -> short(duration<500)');
      if (_timesupWhileRecording) {
        _timesupWhileRecording = false;
        _startTimesupAnalyzing(_TimesupReason.afterCancel);
      }
      return;
    }
    if (path == null) {
      _setMicState(_MicButtonState.defaultState);
      debugPrint('[DEBUG] Recording finish -> no path');
      if (_timesupWhileRecording) {
        _timesupWhileRecording = false;
        _startTimesupAnalyzing(_TimesupReason.afterCancel);
      }
      return;
    }
    final bytes = await File(path).readAsBytes();
    _deleteRecordingFile(path);
    _setMicState(_MicButtonState.loading);
    _setUserTurn(false);
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    debugPrint('[DEBUG] Recording finish -> sending audio');
    if (_timesupWhileRecording) {
      _timesupWhileRecording = false;
      _startTimesupAnalyzing(_TimesupReason.afterFinish);
    }
    await _sendUserMessageAudio(bytes);
  }

  Future<String?> _stopRecording({bool discard = false}) async {
    if (!_isRecording) return null;
    _isRecording = false;
    if (discard) {
      await _recorder.cancel();
      return null;
    }
    return _recorder.stop();
  }

  void _deleteRecordingFile(String? path) {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Widget _buildAiMessage(
    BuildContext context,
    double bodyWidth,
    _ConversationEntry entry,
  ) {
    final messageText = entry.text ?? '';
    if (messageText.isEmpty) {
      return const SizedBox.shrink();
    }
    const double aiTranslationIconSize = 24;
    const double gapBeforeAiTranslationIcon = 5;
    const double aiAvatarRowWidth = 40;
    const double gapAvatarToBubble = 5;
    final maxRowWidthBeforeTranslation =
        bodyWidth - gapBeforeAiTranslationIcon - aiTranslationIconSize;
    final maxAiBubbleWidth = math.max(
      0.0,
      maxRowWidthBeforeTranslation - aiAvatarRowWidth - gapAvatarToBubble,
    );
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.white);
    final translationStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: const Color(0xFF80D7CF));
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAiAvatar(),
            const SizedBox(width: gapAvatarToBubble),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxAiBubbleWidth),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0CABA8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        messageText,
                        style: textStyle,
                        textAlign: TextAlign.start,
                      ),
                      if (entry.isTranslationExpanded) ...[
                        if (entry.translationText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              entry.translationText!,
                              style: translationStyle,
                              textAlign: TextAlign.justify,
                            ),
                          )
                        else if (entry.isTranslationLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: gapBeforeAiTranslationIcon),
            GestureDetector(
              onTap: () => _toggleTranslation(entry),
              child: Image.asset(
                entry.isTranslationExpanded
                    ? 'assets/images/icons/translation_mint.png'
                    : 'assets/images/icons/translation_grey.png',
                width: aiTranslationIconSize,
                height: aiTranslationIconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAvatar() {
    final url = _getUserRoleAvatarUrl();
    if (url == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
      );
    }
    return ClipOval(
      child: Image(
        image: CachedNetworkImageProvider(url),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildNarration(BuildContext context, _ConversationEntry entry) {
    final narration = entry.narration;
    if (narration == null || narration.text == null) {
      return const SizedBox.shrink();
    }
    final isMission = narration.missionActiveYn == 'Y';
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic);
    final missionColor = const Color(0xFFFF00A6);
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: isMission
            ? Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: missionColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Mission',
                      style: baseStyle?.copyWith(color: Colors.white),
                    ),
                  ),
                  Text(
                    narration.text ?? '',
                    textAlign: TextAlign.center,
                    style: baseStyle?.copyWith(color: missionColor),
                  ),
                ],
              )
            : Text(
                narration.text ?? '',
                textAlign: TextAlign.center,
                style: baseStyle?.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildUserMessage(
    BuildContext context,
    double bodyWidth,
    _ConversationEntry entry,
  ) {
    final text = entry.text ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.black);
    final maxBubbleWidth = bodyWidth * 0.7;
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text, style: textStyle),
          ),
        ),
      ),
    );
  }

  static const Color _hintBubbleBg = Color(0xFF194847);
  static const Color _hintPlaybackTeal = Color(0xFF0CABA8);

  /// 단어 텍스트와 점선 밑줄 사이 (논리 픽셀).
  static const double _hintWordUnderlineGap = 2;

  Color _hintMegaphoneTint(_ConversationEntry entry) {
    if (entry.hintSentenceHighlightActive) return _hintPlaybackTeal;
    return Colors.white;
  }

  Color _hintWordTextColor(_ConversationEntry entry, int wordIndex) {
    if (entry.hintSentenceHighlightActive) return _hintPlaybackTeal;
    if (entry.hintWordHighlightIndex == wordIndex) return _hintPlaybackTeal;
    return Colors.white;
  }

  double _measureHintWordWidth(String word, TextStyle? style) {
    final tp = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  Widget _buildHintWordWithDottedUnderline({
    required _ConversationEntry entry,
    required int wordIndex,
    required String word,
    required TextStyle? headline,
  }) {
    final wordStyle = headline?.copyWith(
      color: _hintWordTextColor(entry, wordIndex),
      height: 1.35,
    );
    final underlineWidth = _measureHintWordWidth(word, wordStyle);
    return GestureDetector(
      onTap: () => unawaited(_onHintWordTap(entry, wordIndex)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(word, style: wordStyle),
          SizedBox(height: _hintWordUnderlineGap),
          SizedBox(
            width: underlineWidth,
            height: 3,
            child: CustomPaint(
              painter: _HintDottedUnderlinePainter(color: _hintPlaybackTeal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintGuideBar(BuildContext context, String guideText) {
    final theme = Theme.of(context).textTheme;
    return Container(
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF054544),
        borderRadius: BorderRadius.circular(13.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        guideText,
        style: theme.bodyMedium?.copyWith(color: const Color(0xFF0CABA8)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHintBubble(
    BuildContext context,
    double bodyWidth,
    _ConversationEntry entry,
  ) {
    if (entry.hintIsLoading) {
      return _buildHintBubbleLoading(context, bodyWidth, entry);
    }
    final text = entry.text ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final theme = Theme.of(context).textTheme;
    final headline = theme.headlineSmall ?? theme.bodyLarge;

    final guideText = entry.hintGuideText;
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: GestureDetector(
                onTap: () => unawaited(_onHintMegaphoneTap(entry)),
                behavior: HitTestBehavior.opaque,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    _hintMegaphoneTint(entry),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/icons/megaphone.png',
                    width: 24,
                    height: 24,
                  ),
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
                    _buildHintWordWithDottedUnderline(
                      entry: entry,
                      wordIndex: i,
                      word: words[i],
                      headline: headline,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: bodyWidth),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _hintBubbleBg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (guideText != null && guideText.isNotEmpty)
                  _buildHintGuideBar(context, guideText),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBubbleLoading(
    BuildContext context,
    double bodyWidth,
    _ConversationEntry entry,
  ) {
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: bodyWidth),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hintBubbleBg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF9B9B9B),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/icons/megaphone.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBubble(BuildContext context, _ConversationEntry entry) {
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _WaveDots(),
        ),
      ),
    );
  }

  Widget _buildConversationEntry(
    BuildContext context,
    double bodyWidth,
    _ConversationEntry entry,
  ) {
    return KeyedSubtree(
      key: entry.key,
      child: switch (entry.type) {
        _ConversationEntryType.ai => _buildAiMessage(context, bodyWidth, entry),
        _ConversationEntryType.narration => _buildNarration(context, entry),
        _ConversationEntryType.user => _buildUserMessage(
          context,
          bodyWidth,
          entry,
        ),
        _ConversationEntryType.hint => Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: _buildHintBubble(context, bodyWidth, entry),
        ),
        _ConversationEntryType.recording => _buildRecordingBubble(
          context,
          entry,
        ),
      },
    );
  }

  void _showRecordingEntry() {
    if (_recordingEntry != null) return;
    final entry = _ConversationEntry.recording();
    _recordingEntry = entry;
    _addEntry(entry);
  }

  void _removeRecordingEntry() {
    final entry = _recordingEntry;
    if (entry == null) return;
    setState(() {
      _conversationEntries.remove(entry);
    });
    _recordingEntry = null;
  }

  void _showHoldToSpeakMessage() {
    final l10n = AppLocalizations.of(context)!;
    _showServiceMessage(l10n.holdMicrophoneToSpeak);
  }

  void _showServiceMessage(String message, {bool persistent = false}) {
    _serviceMessageTimer?.cancel();
    setState(() {
      _serviceMessageText = message;
      _serviceMessageColor = null;
      _isServiceMessageVisible = true;
    });
    if (persistent) return;
    _serviceMessageTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isServiceMessageVisible = false;
      });
      _serviceMessageTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _serviceMessageText = null;
        });
      });
    });
  }

  static const Color _endedMessageColor = Color(0xFF0CABA8);

  void _showEndedServiceMessage(String message) {
    _serviceMessageTimer?.cancel();
    _stopAnalyzingBlink();
    setState(() {
      _serviceMessageText = message;
      _serviceMessageColor = _endedMessageColor;
      _isServiceMessageVisible = true;
    });
  }

  int get _totalMissionCount => _missionStatuses.length;

  int get _completedMissionCount =>
      _missionStatuses.values.where((s) => s == _MissionStatus.success).length;

  bool get _allMissionsCompleted =>
      _totalMissionCount > 0 && _completedMissionCount == _totalMissionCount;

  int? get _lastMissionStepIndex {
    if (_missionStatuses.isEmpty) return null;
    return _missionStatuses.keys.reduce(math.max);
  }

  Future<void> _handleResultIdEnding(RoleplayNarrationDto narration) async {
    final resultId = narration.resultId!;
    final l10n = AppLocalizations.of(context)!;

    if (resultId == 0) {
      _showEndedServiceMessage(l10n.roleplayEndedFailed);
      _serviceMessageTimer?.cancel();
      _serviceMessageTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        RoleplayRouter.replaceWithFailed(context);
      });
      return;
    }

    final allCompleted = _allMissionsCompleted;
    final String endedMessage = allCompleted
        ? l10n.roleplayEndedEnding
        : l10n.roleplayEndedComplete;
    _showEndedServiceMessage(endedMessage);

    final accessToken = await TokenStorage.loadAccessToken();
    final Future<RoleplayResultDto?> resultFuture = accessToken != null
        ? SudaApiClient.getRoleplayResult(
            accessToken: accessToken,
            resultId: resultId,
          ).then<RoleplayResultDto?>((r) => r)
        : Future<RoleplayResultDto?>.value(null);

    final futures = <Future<dynamic>>[
      Future<void>.delayed(const Duration(seconds: 3)),
      resultFuture,
    ];
    if (allCompleted && mounted) {
      RoleplayRoleDto? role;
      final roleList =
          RoleplayStateService.instance.overview?.roleplay?.roleList;
      final roleId = RoleplayStateService.instance.roleId;
      if (roleList != null && roleId != null) {
        for (final r in roleList) {
          if (r.id == roleId) {
            role = r;
            break;
          }
        }
      }
      final imgPath = role?.endingList?.isNotEmpty == true
          ? role!.endingList!.first.imgPath
          : null;
      if (imgPath != null && imgPath.isNotEmpty) {
        final imageUrl = '${AppConfig.cdnBaseUrl}$imgPath';
        futures.add(
          precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          ).then((_) => null),
        );
      }
    }

    try {
      await Future.wait(futures);
      if (!mounted) return;
      final result = await resultFuture;
      RoleplayStateService.instance.setCachedResult(result);
    } catch (e) {
      debugPrint('[DEBUG] getRoleplayResult error: $e');
      if (!mounted) return;
      RoleplayStateService.instance.setCachedResult(null);
    }
    if (!mounted) return;
    if (allCompleted) {
      RoleplayRouter.replaceWithEnding(context);
    } else {
      RoleplayRouter.replaceWithResultV2(context);
    }
  }

  void _startAnalyzingBlink() {
    if (!mounted) return;
    if (_isAnalyzingBlinking) return;
    final l10n = AppLocalizations.of(context)!;
    _serviceMessageTimer?.cancel();
    setState(() {
      _isAnalyzingBlinking = true;
      _serviceMessageText = l10n.roleplayAnalyzing;
      _serviceMessageColor = null;
      _isServiceMessageVisible = true;
    });
    _analyzingBlinkController.value = 0.0;
    _analyzingBlinkController.repeat(reverse: true);
  }

  void _startTimesupAnalyzing(_TimesupReason reason) {
    if (_isTimesupAnalyzing) return;
    setState(() {
      _isTimesupAnalyzing = true;
    });
    _startAnalyzingBlink();
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    _setTypingEnabled(false);
    if (reason != _TimesupReason.afterFinish) {
      _setMicState(_MicButtonState.disabled);
      _pollSessionStatusThenDispatch();
    }
  }

  void _stopAnalyzingBlink() {
    _analyzingDelayTimer?.cancel();
    _analyzingDelayTimer = null;
    if (_analyzingBlinkController.isAnimating) {
      _analyzingBlinkController.stop();
    }
    _analyzingBlinkController.reset();
    if (_isAnalyzingBlinking) {
      setState(() {
        _isAnalyzingBlinking = false;
      });
    }
  }

  Future<void> _pollSessionStatusThenDispatch() async {
    final result = await _fetchSessionStatusWithRetry();
    if (!mounted) return;
    if (result == null) {
      _failAnalyzingWithNetworkError();
      return;
    }
    if (result.completedYn == 'Y') {
      final resultId = result.resultId ?? 0;
      _dispatchTimesupResult(resultId);
    } else {
      _failAnalyzingWithNetworkError();
    }
  }

  Future<RoleplaySessionStatusDto?> _fetchSessionStatusWithRetry() async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final status = await _fetchSessionStatusOnce();
        if (status == null) return null;
        if (status.completedYn == 'Y') return status;
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return null;
          continue;
        }
        return status;
      } on rp_api.RoleplaySessionNotFoundException catch (_) {
        if (!mounted) return null;
        _handleSessionNotFound();
        return null;
      } catch (e) {
        debugPrint('[DEBUG] getRoleplaySessionStatus error(attempt=$attempt): $e');
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return null;
          continue;
        }
        return null;
      }
    }
    return null;
  }

  Future<RoleplaySessionStatusDto?> _fetchSessionStatusOnce() async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) return null;
    return SudaApiClient.getRoleplaySessionStatus(
      accessToken: accessToken,
      rpSessionId: sessionId,
    );
  }

  void _dispatchTimesupResult(int resultId) {
    _stopAnalyzingBlink();
    _handleResultIdEnding(RoleplayNarrationDto(resultId: resultId));
  }

  void _failAnalyzingWithNetworkError() {
    _stopAnalyzingBlink();
    _showServiceMessage('Network Error', persistent: true);
  }

  void _handleSessionNotFound() {
    _stopAnalyzingBlink();
    DefaultToast.show(context, 'Roleplay Session Not Found');
    if (context.mounted) {
      RoleplayRouter.popToOverview(context);
    }
  }

  Future<void> _sendUserMessageAudio(Uint8List audioData) async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) return;
    debugPrint('[DEBUG] Send user audio start');
    try {
      final response = await SudaApiClient.sendRoleplayUserMessageAudio(
        accessToken: accessToken,
        rpSessionId: sessionId,
        audioData: audioData,
      );
      await _handleUserMessageResponse(response);
      if (mounted) debugPrint('[DEBUG] Send user audio done');
    } catch (e) {
      debugPrint('[DEBUG] Send user audio error: $e');
      if (!mounted) return;
      _setMicState(_MicButtonState.defaultState);
      _setUserTurn(true);
      if (!_hintUsedThisTurn) _setHintEnabled(true);
    }
  }

  Future<void> _sendUserMessageText(String text) async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) return;
    final response = await SudaApiClient.sendRoleplayUserMessageText(
      accessToken: accessToken,
      rpSessionId: sessionId,
      text: text,
    );
    await _handleUserMessageResponse(response);
  }

  Future<void> _handleUserMessageResponse(
    RoleplayUserMessageResponseDto response,
  ) async {
    if (mounted) {
      final hadHint = _conversationEntries.any(
        (e) => e.type == _ConversationEntryType.hint,
      );
      if (hadHint) {
        _hintPlaybackSub?.cancel();
        _hintPlaybackSub = null;
        unawaited(_audioPlayer.stop());
      }
      setState(() {
        _conversationEntries.removeWhere(
          (e) => e.type == _ConversationEntryType.hint,
        );
      });
    }
    final text = response.text ?? '';
    if (text.isNotEmpty) {
      final entry = _ConversationEntry.user(text: text);
      await _addEntry(entry);
      _setMicState(_MicButtonState.disabled);
      debugPrint('[DEBUG] User bubble shown, requesting AI response');
    }
    if (_wasMissionActive) {
      if (response.missionCompleteYn == 'Y') {
        _setMissionSuccess(_currentStep);
      } else if (response.missionCompleteYn == 'N') {
        _setMissionFailed(_currentStep);
      }
      final lastIndex = _lastMissionStepIndex;
      if (lastIndex != null && _currentStep == lastIndex) {
        _pendingAnalyzingAfterAi = true;
      }
    }
    await _requestAiResponse();
  }

  Future<void> _requestAiResponse() async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) return;
    debugPrint('[DEBUG] AI response request start');
    final aiMessage = await _fetchAiMessageWithRetry(
      accessToken: accessToken,
      sessionId: sessionId,
    );
    if (aiMessage == null || aiMessage.text == null) {
      debugPrint('[DEBUG] AI response skip: null or empty text');
      return;
    }
    debugPrint('[DEBUG] AI response received, showing AI message');
    await _showAiMessage(
      text: aiMessage.text ?? '',
      cdnYn: aiMessage.cdnYn,
      cdnPath: aiMessage.cdnPath,
      soundBytes: aiMessage.sound,
    );
  }

  Future<void> _toggleTranslation(_ConversationEntry entry) async {
    if (entry.type != _ConversationEntryType.ai) return;
    if (entry.conversationIndex == null) return;
    if (entry.translationText != null) {
      setState(() {
        entry.isTranslationExpanded = !entry.isTranslationExpanded;
      });
      return;
    }
    if (entry.isTranslationLoading) return;
    setState(() {
      entry.isTranslationLoading = true;
      entry.isTranslationExpanded = true;
    });
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) {
      if (!mounted) {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
        return;
      }
      setState(() {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
      });
      return;
    }
    try {
      final translated = await SudaApiClient.getRoleplayTranslation(
        accessToken: accessToken,
        rpSessionId: sessionId,
        index: entry.conversationIndex!,
      );
      if (!mounted) return;
      setState(() {
        entry.translationText = translated;
        entry.isTranslationLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
        return;
      }
      setState(() {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
      });
    }
  }

  Future<TtsResultDto?> _fetchAiMessageWithRetry({
    required String accessToken,
    required String sessionId,
  }) async {
    // 150/250/400/700/1500ms × 3 each = 15 retries
    const delays = [
      Duration(milliseconds: 150),
      Duration(milliseconds: 150),
      Duration(milliseconds: 150),
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
      Duration(milliseconds: 400),
      Duration(milliseconds: 400),
      Duration(milliseconds: 400),
      Duration(milliseconds: 700),
      Duration(milliseconds: 700),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1500),
      Duration(milliseconds: 1500),
      Duration(milliseconds: 1500),
    ];
    int attempt = 0;
    while (true) {
      try {
        final result = await SudaApiClient.getRoleplayAiMessage(
          accessToken: accessToken,
          rpSessionId: sessionId,
        );
        if (attempt == 0) {
          debugPrint('[DEBUG] AI response received: 대기 없이 최초 호출');
        } else {
          debugPrint(
            '[DEBUG] AI response received: ${attempt}번째 대기(${delays[attempt - 1].inMilliseconds}ms) 후',
          );
        }
        return result;
      } catch (e) {
        final message = e.toString();
        final shouldRetry =
            message.contains('HTTP 202') || message.contains('HTTP 500');
        if (!shouldRetry || attempt >= delays.length) {
          if (attempt >= delays.length) {
            debugPrint('[DEBUG] AI response: 15회 재시도 소진 후 실패 (last: $e)');
          }
          return null;
        }
        await Future.delayed(delays[attempt]);
        attempt += 1;
      }
    }
  }

  Future<void> _addEntry(
    _ConversationEntry entry, {
    VoidCallback? onRevealed,
    bool revealImmediately = false,
  }) async {
    if (entry.consumesIndex && entry.conversationIndex == null) {
      entry.conversationIndex = _nextConversationIndex;
      _nextConversationIndex += 1;
    }
    setState(() {
      _conversationEntries.add(entry);
      if (revealImmediately) {
        entry.isVisible = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = entry.key.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      if (!mounted) return;
      setState(() {
        entry.isVisible = true;
      });
      onRevealed?.call();
    });
  }

  void _scrollToLastEntry() {
    if (_conversationEntries.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lastEntry = _conversationEntries.last;
      final context = lastEntry.key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildSpeedPanel(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      top: topInset + 56,
      right: _isSpeedPanelVisible ? 24 : -62,
      width: 62,
      height: 250,
      child: IgnorePointer(
        ignoring: !_isSpeedPanelVisible,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: const Color(0x59000000),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    '1.5x',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const handleRadius = 12.0;
                        final railHeight =
                            constraints.maxHeight - (handleRadius * 2);
                        final stepGap =
                            railHeight / (_speedRateSteps.length - 1);
                        final handleCenterY =
                            handleRadius + (stepGap * _speedIndex);
                        final handleTop = handleCenterY - handleRadius;
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (details) => _setSpeedIndexFromOffset(
                            dy: details.localPosition.dy - handleRadius,
                            railHeight: railHeight,
                            commit: true,
                          ),
                          onVerticalDragUpdate: (details) =>
                              _setSpeedIndexFromOffset(
                                dy: details.localPosition.dy - handleRadius,
                                railHeight: railHeight,
                                commit: false,
                              ),
                          onVerticalDragEnd: (_) => _commitSpeedIndex(),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Container(
                                  width: 4,
                                  height: railHeight,
                                  color: Colors.white,
                                ),
                              ),
                              Positioned(
                                top: handleTop,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '0.7x',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return SizedBox(
      height: 18,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const iconSize = 18.0;
          final barWidth = (width - iconSize).clamp(0.0, width);
          final barLeft = (width - barWidth) / 2;
          final maxIndex = _maxStepIndex;
          final progressRatio = maxIndex <= 0
              ? 0.0
              : (_currentStep / maxIndex).clamp(0.0, 1.0);
          final progressWidth = barWidth * progressRatio;
          const barHeight = 3.0;
          final barTop = (18 - barHeight) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: barTop,
                left: barLeft,
                width: barWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: barHeight,
                    color: const Color(0xFF635F5F),
                  ),
                ),
              ),
              Positioned(
                top: barTop,
                left: barLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    height: barHeight,
                    width: progressWidth,
                    color: const Color(0xFFFFAAE1),
                    duration: const Duration(milliseconds: 500),
                  ),
                ),
              ),
              for (final entry in _missionStatuses.entries)
                _buildMissionIcon(
                  barLeft: barLeft,
                  barWidth: barWidth,
                  maxIndex: maxIndex,
                  stepIndex: entry.key,
                  status: entry.value,
                  iconSize: iconSize,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMissionIcon({
    required double barLeft,
    required double barWidth,
    required int maxIndex,
    required int stepIndex,
    required _MissionStatus status,
    required double iconSize,
  }) {
    final ratio = maxIndex <= 0 ? 0.0 : (stepIndex / maxIndex).clamp(0.0, 1.0);
    final left = barLeft + (barWidth * ratio) - (iconSize / 2);
    final asset = switch (status) {
      _MissionStatus.ready => 'assets/images/icons/mission_ready.png',
      _MissionStatus.success => 'assets/images/icons/mission_succeeded.png',
      _MissionStatus.failed => 'assets/images/icons/mission_failed.png',
    };
    final shouldAnimate =
        _animatingSteps.containsKey(stepIndex) &&
        _animatingSteps[stepIndex] == status;

    return Positioned(
      left: left,
      top: 0,
      child: _MissionIconScale(
        asset: asset,
        size: iconSize,
        animate: shouldAnimate,
        onCompleted: () {
          if (!mounted) return;
          setState(() {
            _animatingSteps.remove(stepIndex);
          });
        },
      ),
    );
  }

  void _navigateToEnding(BuildContext context) {
    // playing screen 삭제하고 ending으로 전환
    RoleplayRouter.replaceWithEnding(context);
  }

  void _navigateToFailed(BuildContext context) {
    // playing screen 삭제하고 failed로 전환
    RoleplayRouter.replaceWithFailed(context);
  }

  void _handleBackButton(BuildContext context) {
    setState(() => _showExitLayer = true);
  }

  void _dismissExitLayer() {
    if (mounted) setState(() => _showExitLayer = false);
  }

  void _confirmExit(BuildContext context) {
    _dismissExitLayer();
    if (context.mounted) RoleplayRouter.popToOverview(context);
  }

  @override
  Widget build(BuildContext context) {
    final overview = RoleplayStateService.instance.overview;
    final roleplay = overview?.roleplay;
    if (_totalSteps == 0 && roleplay != null) {
      _initializeProgressState();
    }

    // Opening과 동일한 헤더 표기 규칙
    final titleEn = SudaJsonUtil.englishText(roleplay?.title);

    final overviewImgPath = roleplay?.overviewImgPath;
    final backdropUrl = (overviewImgPath != null && overviewImgPath.isNotEmpty)
        ? '${AppConfig.cdnBaseUrl}$overviewImgPath'
        : null;

    final durationFormatted = _formatRemaining();
    final durationColor = _remainingSeconds <= 10 ? Colors.red : Colors.white;
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBackButton(context);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropUrl != null)
            Positioned.fill(
              child: RoleplayOverviewBackdrop(imageUrl: backdropUrl),
            ),
          RoleplayScaffold(
            backgroundColor: backdropUrl != null ? Colors.transparent : null,
            showCloseButton: widget.showCloseButton,
            onClose: () => _handleBackButton(context),
            title: titleEn,
            duration: durationFormatted,
            durationColor: durationColor,
            headerExtra: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                _buildProgressHeader(),
                const SizedBox(height: 14),
              ],
            ),
            headerTopSpacingDelta: _headerTopSpacingDelta,
            body: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  var i = 0;
                                  i < _conversationEntries.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 14),
                                  _buildConversationEntry(
                                    context,
                                    constraints.maxWidth,
                                    _conversationEntries[i],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            footer: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _analyzingBlinkController,
                        builder: (context, _) {
                          final textWidget = Text(
                            _serviceMessageText ?? '',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _serviceMessageColor ?? Colors.white,
                                ),
                          );
                          if (_isAnalyzingBlinking) {
                            return Opacity(
                              opacity: _isServiceMessageVisible
                                  ? _analyzingBlinkController.value
                                  : 0,
                              child: textWidget,
                            );
                          }
                          return AnimatedOpacity(
                            opacity: _isServiceMessageVisible ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: textWidget,
                          );
                        },
                      ),
                    ),
                  ),
                  if (_inputMode == _InputMode.recording)
                    SizedBox(
                      height: 120,
                      child: _MicButtonArea(
                        isInteractive: _isMicInteractive && !_isTimesupAnalyzing,
                        isLoading: _micState == _MicButtonState.loading,
                        isDisabled: _micState == _MicButtonState.disabled,
                        loadingRotationController: _loadingRotationController,
                        onPressStart: _onMicPressStart,
                        onPressEnd: _onMicPressEnd,
                        onPressCancel: _onMicPressCancel,
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF353535),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: _typingController,
                                    focusNode: _typingFocusNode,
                                    enabled: _isTypingEnabled &&
                                        _isUserTurn &&
                                        !_isTimesupAnalyzing,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _handleSend(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: _isTimesupAnalyzing
                                          ? ''
                                          : (_isTypingEnabled
                                              ? 'Type your message ...'
                                              : 'Wait for your turn ...'),
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF9B9B9B),
                                          ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _isTypingEnabled &&
                                        _isUserTurn &&
                                        !_isTimesupAnalyzing
                                    ? _handleSend
                                    : null,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF353535),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/icons/send.png',
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _isTimesupAnalyzing
                                ? null
                                : () {
                                    final toRecording =
                                        _inputMode == _InputMode.typing;
                                    if (!toRecording) {
                                      _cancelHintIdleAndBlink();
                                    }
                                    setState(() {
                                      _inputMode = toRecording
                                          ? _InputMode.recording
                                          : _InputMode.typing;
                                    });
                                    if (toRecording) {
                                      _scrollToLastEntry();
                                    }
                                  },
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Image.asset(
                                  _inputMode == _InputMode.typing
                                      ? 'assets/images/icons/mic.png'
                                      : 'assets/images/icons/keyboard.png',
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          IgnorePointer(
                            ignoring: !_isHintEnabled || _isTimesupAnalyzing,
                            child: AnimatedBuilder(
                              animation: _hintBlinkController,
                              builder: (context, child) {
                                final baseOpacity = _isHintEnabled ? 1.0 : 0.4;
                                final blinkOpacity =
                                    _hintBlinkController.isAnimating
                                    ? _hintBlinkController.value
                                    : baseOpacity;
                                return Opacity(
                                  opacity: _hintBlinkController.isAnimating
                                      ? blinkOpacity
                                      : baseOpacity,
                                  child: child,
                                );
                              },
                              child: GestureDetector(
                                onTap: _isHintEnabled ? _onHintTap : null,
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
                ],
              ),
            ),
          ),
          if (widget.showCloseButton && _isSpeedPanelVisible)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _dismissSpeedPanel(),
                child: const SizedBox.expand(),
              ),
            ),
          if (widget.showCloseButton)
            Positioned(
              top: topInset + 16,
              right: 16,
              child: GestureDetector(
                onTap: _toggleSpeedPanel,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/kebab.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.showCloseButton) _buildSpeedPanel(context),
          if (_showExitLayer) Positioned.fill(child: _buildExitLayer(context)),
        ],
      ),
    );
  }

  Widget _buildExitLayer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    const guideColor = Color(0xFF0CABA8);
    final padding = MediaQuery.of(context).padding;

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: const Color(0x59000000),
          padding: EdgeInsets.only(
            top: padding.top,
            bottom: padding.bottom,
            left: padding.left + 24,
            right: padding.right + 24,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                Text(
                  l10n.roleplayExitWait,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ChironHeiHK',
                    fontWeight: FontWeight.w700,
                    fontVariations: [FontVariation('wght', 700)],
                    color: Color(0xFFFFFFFF),
                    fontSize: 54,
                    letterSpacing: -0.38, // -0.7% of 54
                  ),
                ),
                Text(
                  l10n.roleplayExitMessage,
                  style: theme.bodyLarge?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: _dismissExitLayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: guideColor,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    elevation: 0,
                  ),
                  child: Text(l10n.roleplayExitKeepPlaying),
                ),
                GestureDetector(
                  onTap: () => _confirmExit(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.roleplayExitExit,
                      style: theme.bodyLarge?.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 힌트 단어 아래 고정 색 점선 (텍스트 장식과 분리).
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
      color != oldDelegate.color;
}

enum _TimesupReason { immediate, afterCancel, afterFinish }

enum _MissionStatus { ready, success, failed }

enum _InputMode { recording, typing }

enum _MicButtonState { defaultState, loading, disabled }

enum _ConversationEntryType { ai, narration, user, hint, recording }

class _ConversationEntry {
  final _ConversationEntryType type;
  String? text;
  final RoleplayNarrationDto? narration;
  final GlobalKey key = GlobalKey();
  int? conversationIndex;
  bool isVisible = false;
  String? translationText;
  bool isTranslationExpanded = false;
  bool isTranslationLoading = false;
  bool hintIsLoading;
  bool hintSentenceHighlightActive = false;
  int? hintWordHighlightIndex;
  Map<String, TtsResultDto>? hintAudioCache;
  String? hintGuideText;

  _ConversationEntry._({
    required this.type,
    this.text,
    this.narration,
    this.hintIsLoading = false,
    this.hintAudioCache,
    this.hintGuideText,
  });

  factory _ConversationEntry.ai({required String text}) {
    return _ConversationEntry._(
      type: _ConversationEntryType.ai,
      text: text,
    );
  }

  factory _ConversationEntry.narration({
    required RoleplayNarrationDto narration,
  }) {
    return _ConversationEntry._(
      type: _ConversationEntryType.narration,
      narration: narration,
    );
  }

  factory _ConversationEntry.user({required String text}) {
    return _ConversationEntry._(type: _ConversationEntryType.user, text: text);
  }

  factory _ConversationEntry.hintLoading() {
    return _ConversationEntry._(
      type: _ConversationEntryType.hint,
      text: null,
      hintIsLoading: true,
      hintAudioCache: <String, TtsResultDto>{},
    );
  }

  factory _ConversationEntry.hintStarter({
    required String text,
    required String guideText,
  }) {
    return _ConversationEntry._(
      type: _ConversationEntryType.hint,
      text: text,
      hintIsLoading: false,
      hintAudioCache: <String, TtsResultDto>{},
      hintGuideText: guideText,
    );
  }

  factory _ConversationEntry.recording() {
    return _ConversationEntry._(type: _ConversationEntryType.recording);
  }

  bool get consumesIndex =>
      type != _ConversationEntryType.recording &&
      type != _ConversationEntryType.hint;
}

const double _micDefaultSize = 100;
const double _micPressedSize = 115;

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// 녹음 버튼 전용 위젯. Listener + ValueNotifier로 제스처 중 상위 setState 없이 UI만 갱신.
class _MicButtonArea extends StatefulWidget {
  final bool isInteractive;
  final bool isLoading;
  final bool isDisabled;
  final AnimationController loadingRotationController;
  final VoidCallback onPressStart;
  final void Function(bool cancel) onPressEnd;
  final VoidCallback onPressCancel;

  const _MicButtonArea({
    required this.isInteractive,
    required this.isLoading,
    required this.isDisabled,
    required this.loadingRotationController,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onPressCancel,
  });

  @override
  State<_MicButtonArea> createState() => _MicButtonAreaState();
}

class _MicButtonAreaState extends State<_MicButtonArea>
    with TickerProviderStateMixin {
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0);
  final ValueNotifier<bool> _isCancelHovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isPressed = ValueNotifier<bool>(false);

  late final AnimationController _arrowPulseController;

  @override
  void initState() {
    super.initState();
    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _isPressed.addListener(_syncArrowPulse);
  }

  void _syncArrowPulse() {
    if (_isPressed.value) {
      if (!_arrowPulseController.isAnimating) {
        _arrowPulseController.repeat();
      }
    } else {
      if (_arrowPulseController.isAnimating) {
        _arrowPulseController.stop();
      }
      _arrowPulseController.reset();
    }
  }

  @override
  void dispose() {
    _isPressed.removeListener(_syncArrowPulse);
    _dragOffset.dispose();
    _isCancelHovered.dispose();
    _isPressed.dispose();
    _arrowPulseController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isInteractive || widget.isLoading || widget.isDisabled) return;
    _isPressed.value = true;
    _dragOffset.value = 0;
    _isCancelHovered.value = false;
    widget.onPressStart();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPressed.value) return;
    // Layout params are computed in build; we need them here. Store in state or pass via closure.
    // We'll compute in build and pass a callback that captures layout. Actually we need to
    // compute offset/cancel in the move handler. So we need centerX, cancelCenter, maxLeftOffset.
    // These depend on constraints. So we need to store the last known layout params when we build,
    // and use them in the move handler. So we store in state: _lastCenterX, _lastCancelCenter, _lastMaxLeftOffset.
    // We set these in build (in ValueListenableBuilder) when we have the constraints.
    final centerX = _lastCenterX;
    final cancelCenter = _lastCancelCenter;
    final maxLeftOffset = _lastMaxLeftOffset;
    if (centerX == null || cancelCenter == null || maxLeftOffset == null)
      return;
    final nextOffset = (_dragOffset.value + event.delta.dx).clamp(
      maxLeftOffset,
      0.0,
    );
    final buttonLeft = centerX + nextOffset - (_micPressedSize / 2);
    final cancelHovered = buttonLeft <= cancelCenter;
    if (nextOffset != _dragOffset.value ||
        cancelHovered != _isCancelHovered.value) {
      _dragOffset.value = nextOffset;
      _isCancelHovered.value = cancelHovered;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isPressed.value) return;
    final cancel = _isCancelHovered.value;
    _isPressed.value = false;
    _dragOffset.value = 0;
    _isCancelHovered.value = false;
    widget.onPressEnd(cancel);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!_isPressed.value) return;
    _isPressed.value = false;
    _dragOffset.value = 0;
    _isCancelHovered.value = false;
    widget.onPressCancel();
  }

  double? _lastCenterX;
  double? _lastCancelCenter;
  double? _lastMaxLeftOffset;

  static String _assetFor(
    bool isPressed,
    bool cancelHover,
    bool isLoading,
    bool isDisabled,
  ) {
    if (isLoading) return 'assets/images/buttons/mic_btn_loading.png';
    if (isDisabled) return 'assets/images/buttons/mic_btn_disabled.png';
    if (isPressed && cancelHover)
      return 'assets/images/buttons/mic_btn_default.png';
    if (isPressed) return 'assets/images/buttons/mic_btn_pressed.png';
    return 'assets/images/buttons/mic_btn_default.png';
  }

  static double _sizeFor(
    bool isPressed,
    bool cancelHover,
    bool isLoading,
    bool isDisabled,
  ) {
    if (isLoading || isDisabled) return _micDefaultSize;
    if (isPressed && cancelHover) return _micDefaultSize;
    if (isPressed) return _micPressedSize;
    return _micDefaultSize;
  }

  Widget _buildButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPressed,
      builder: (context, isPressed, _) {
        return ValueListenableBuilder<double>(
          valueListenable: _dragOffset,
          builder: (context, dragOffset, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isCancelHovered,
              builder: (context, cancelHovered, ___) {
                final size = _sizeFor(
                  isPressed,
                  cancelHovered,
                  widget.isLoading,
                  widget.isDisabled,
                );
                final asset = _assetFor(
                  isPressed,
                  cancelHovered,
                  widget.isLoading,
                  widget.isDisabled,
                );
                final image = Image.asset(asset, width: size, height: size);
                final content = widget.isLoading
                    ? RotationTransition(
                        turns: widget.loadingRotationController,
                        child: image,
                      )
                    : image;
                return Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  child: content,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDragArrows(
    double cancelRightX,
    double areaHeight,
    double anchorLeftX,
  ) {
    const iconSize = 16.0;
    const gap = 5.0;
    const count = 3;
    final groupWidth = (iconSize * count) + (gap * (count - 1));
    final availableWidth = anchorLeftX - cancelRightX;
    if (availableWidth <= groupWidth) return const SizedBox.shrink();
    final groupLeft = cancelRightX + ((availableWidth - groupWidth) / 2);
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _arrowPulseController,
        builder: (context, child) {
          final shift = _arrowPulseController.value;
          return Stack(
            children: [
              Positioned(
                left: groupLeft,
                top: (areaHeight - iconSize) / 2,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlidingGradientTransform(-shift),
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.modulate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (index) {
                      if (index > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(left: gap),
                          child: SvgPicture.asset(
                            'assets/images/icons/header_arrow_back.svg',
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      }
                      return SvgPicture.asset(
                        'assets/images/icons/header_arrow_back.svg',
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth;
        final centerX = areaWidth / 2;
        final cancelStyle =
            Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF0CABA8)) ??
            const TextStyle();
        final cancelWidth = _measureTextWidth('Cancel', cancelStyle);
        final cancelCenter = cancelWidth / 2;
        final maxLeftOffset = (_micPressedSize / 2) - centerX;

        _lastCenterX = centerX;
        _lastCancelCenter = cancelCenter;
        _lastMaxLeftOffset = maxLeftOffset;

        return ValueListenableBuilder<bool>(
          valueListenable: _isPressed,
          builder: (context, isPressed, _) {
            final showArrows = isPressed;
            final shouldShowCancel = isPressed;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: shouldShowCancel ? 1 : 0,
                    child: Text('Cancel', style: cancelStyle),
                  ),
                ),
                if (showArrows)
                  _buildDragArrows(
                    cancelWidth,
                    120,
                    centerX - (_micPressedSize / 2),
                  ),
                Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _dragOffset,
                    builder: (context, dragOffset, __) {
                      final effectiveOffset = isPressed ? dragOffset : 0.0;
                      return Transform.translate(
                        offset: Offset(effectiveOffset, 0),
                        child: IgnorePointer(
                          ignoring: !widget.isInteractive,
                          child: Listener(
                            onPointerDown: _onPointerDown,
                            onPointerMove: _onPointerMove,
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: _buildButton(context),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.size.width;
  }
}

class _MissionIconScale extends StatefulWidget {
  final String asset;
  final double size;
  final bool animate;
  final VoidCallback onCompleted;

  const _MissionIconScale({
    required this.asset,
    required this.size,
    required this.animate,
    required this.onCompleted,
  });

  @override
  State<_MissionIconScale> createState() => _MissionIconScaleState();
}

class _MissionIconScaleState extends State<_MissionIconScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    if (widget.animate) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _MissionIconScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller
      ..reset()
      ..forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Image.asset(widget.asset, width: widget.size, height: widget.size);
    }

    return ScaleTransition(
      scale: _scale,
      child: Image.asset(widget.asset, width: widget.size, height: widget.size),
    );
  }
}

class _WaveDots extends StatefulWidget {
  @override
  State<_WaveDots> createState() => _WaveDotsState();
}

class _WaveDotsState extends State<_WaveDots>
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
    final value = (1 + math.sin(phase)) / 2;
    return 0.3 + (0.7 * value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final opacity = _opacityFor(index, _controller.value);
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
