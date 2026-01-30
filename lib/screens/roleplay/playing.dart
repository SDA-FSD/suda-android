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
import '../../widgets/roleplay_scaffold.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/suda_json_util.dart';

/// Roleplay Playing Screen (Full Screen)
/// 
/// Roleplay 진행 중 화면
class RoleplayPlayingScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayPlayingScreen({
    super.key,
    this.showCloseButton = true,
  });

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
  Timer? _typingTimer;
  bool _hasHandledInitialTurn = false;
  Future<RoleplayNarrationDto?>? _pendingNarration;
  bool _isHintEnabled = false;
  final List<_ConversationEntry> _conversationEntries = [];
  _ConversationEntry? _recordingEntry;
  Timer? _serviceMessageTimer;
  bool _isServiceMessageVisible = false;
  String? _serviceMessageText;
  int _nextConversationIndex = 0;
  bool _wasMissionActive = false;
  final Map<int, _MissionStatus> _missionStatuses = {};
  final Map<int, _MissionStatus> _animatingSteps = {};
  double _dragOffsetX = 0;
  bool _isCancelHovered = false;
  bool _isPointerDown = false;
  _MicButtonState _micState = _MicButtonState.defaultState;
  _InputMode _inputMode = _InputMode.recording;
  final FocusNode _typingFocusNode = FocusNode();
  final TextEditingController _typingController = TextEditingController();
  bool _isTypingEnabled = true;
  bool _isSpeedPanelVisible = false;
  int _speedIndex = 0;
  int _committedSpeedIndex = 0;
  late final AnimationController _loadingRotationController;
  late final AnimationController _arrowPulseController;
  static const double _headerTopSpacing = 108;
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
    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialTurn();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _typingTimer?.cancel();
    _serviceMessageTimer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    _typingFocusNode.dispose();
    _typingController.dispose();
    _loadingRotationController.dispose();
    _arrowPulseController.dispose();
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
    });
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

  void _handleUserStart() {
    // TODO: show user-start guide popup before enabling recording input.
    _activateUserTurn();
  }

  Future<void> _handleAiStart() async {
    _setUserTurn(false);
    _setMicState(_MicButtonState.disabled, resetDrag: true);
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
    entry.visibleText = text;
    _setHintEnabled(false);
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
    _typingTimer?.cancel();
    if (audioSource != null) {
      unawaited(_playPreparedAiVoice(audioSource));
    }
    _typingTimer = Timer(
      Duration(milliseconds: delayMs),
      () {
        if (!mounted) return;
        _showNarrationAfterTyping();
      },
    );
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
    const delayMs = 150;
    const maxRetries = 20;
    final delays = List.generate(
      maxRetries,
      (_) => const Duration(milliseconds: delayMs),
    );
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
            '[DEBUG] Narration received: ${attempt}번째 대기(${delayMs}ms) 후',
          );
        }
        return result;
      } catch (e) {
        final message = e.toString();
        final shouldRetry =
            message.contains('HTTP 202') || message.contains('HTTP 500');
        if (!shouldRetry || attempt >= delays.length) {
          if (attempt >= delays.length) {
            debugPrint(
              '[DEBUG] Narration: ${maxRetries}회 재시도 소진 후 실패 (last: $e)',
            );
          }
          return null;
        }
        await Future.delayed(delays[attempt]);
        attempt += 1;
      }
    }
  }

  Future<void> _showNarrationAfterTyping() async {
    final narration = await _pendingNarration;
    if (!mounted) return;
    if (narration == null) return;
    if (narration.text == null || narration.text!.isEmpty) return;
    final step = narration.currentStep;
    if (step != null) {
      _setProgressToStep(step);
    }
    _wasMissionActive = narration.missionActiveYn == 'Y';
    final entry = _ConversationEntry.narration(narration: narration);
    await _addEntry(entry);
    if (narration.resultId != null) {
      _showServiceMessage('Roleplay finish detected.');
      return;
    }
    _activateUserTurn();
  }

  void _activateUserTurn() {
    _setUserTurn(true);
    _setMicState(_MicButtonState.defaultState, resetDrag: true);
    _setHintEnabled(true);
    _setTypingEnabled(true);
    if (_inputMode == _InputMode.typing) {
      _typingFocusNode.requestFocus();
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
      final source =
          AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'));
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    return null;
  }

  Future<Duration?> _playPreparedAiVoice(AudioSource? source) async {
    if (source == null) return null;
    await _audioPlayer.play();
    debugPrint(
      '[DEBUG] AI voice play: ${DateTime.now().toIso8601String()}',
    );
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

  void _setSpeedIndexFromOffset({
    required double dy,
    required double railHeight,
    required bool commit,
  }) {
    final stepGap = railHeight / (_speedRateSteps.length - 1);
    final nextIndex = (dy / stepGap).round().clamp(0, _speedRateSteps.length - 1);
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
      (_micState == _MicButtonState.defaultState ||
          _micState == _MicButtonState.pressed) &&
      _isUserTurn;

  void _setMicState(_MicButtonState next, {bool resetDrag = false}) {
    if (_micState == next) return;
    setState(() {
      _micState = next;
      if (resetDrag) {
        _dragOffsetX = 0;
        _isCancelHovered = false;
      }
    });
    _syncLoadingAnimation();
    if (next == _MicButtonState.pressed) {
      _beginRecording();
    }
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

  void _handleMicTapDown(TapDownDetails details) {
    if (_micState != _MicButtonState.defaultState || !_isUserTurn) return;
    debugPrint('[DEBUG] Mic TapDown');
    _isPointerDown = true;
    _setMicState(_MicButtonState.pressed, resetDrag: true);
  }

  void _handleMicPanStart(DragStartDetails details) {
    if (!_isUserTurn) return;
    if (_micState == _MicButtonState.loading ||
        _micState == _MicButtonState.disabled) {
      return;
    }
    debugPrint('[DEBUG] Mic PanStart state=$_micState');
    _isPointerDown = true;
    if (_micState == _MicButtonState.defaultState) {
      _setMicState(_MicButtonState.pressed, resetDrag: true);
    }
  }

  void _handleMicPanUpdate({
    required double deltaX,
    required double maxLeftOffset,
    required double cancelRightX,
    required double cancelCenterX,
    required double centerX,
  }) {
    if (_micState != _MicButtonState.pressed) return;
    final nextOffset = (_dragOffsetX + deltaX).clamp(maxLeftOffset, 0.0);
    final buttonLeft = centerX + nextOffset - (_micPressedSize / 2);
    final cancelHovered = buttonLeft <= cancelCenterX;
    final offsetChanged = nextOffset != _dragOffsetX;
    final cancelChanged = cancelHovered != _isCancelHovered;
    if (!offsetChanged && !cancelChanged) return;
    setState(() {
      _dragOffsetX = nextOffset;
      _isCancelHovered = cancelHovered;
    });
  }

  void _handleMicTapCancel() {
    _isPointerDown = false;
    debugPrint(
      '[DEBUG] Mic TapCancel state=$_micState -> '
      '${_micState == _MicButtonState.pressed ? "cancelRecording+default" : "default"}',
    );
    if (_micState == _MicButtonState.pressed) {
      _cancelRecording();
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
    }
  }

  void _handleMicTapUp() {
    _isPointerDown = false;
    final wasPressed = _micState == _MicButtonState.pressed;
    final cancelHovered = _isCancelHovered;
    final path = !wasPressed
        ? 'return(notPressed)'
        : cancelHovered
            ? 'cancel'
            : 'finish';
    debugPrint(
      '[DEBUG] Mic TapUp state=$_micState isCancelHovered=$cancelHovered -> $path',
    );
    if (!wasPressed) return;
    if (cancelHovered) {
      _cancelRecording();
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
      return;
    }
    _finishRecording();
  }

  void _handleSend() {
    if (!_isTypingEnabled || !_isUserTurn) return;
    final text = _typingController.text.trim();
    if (text.isEmpty) return;
    _typingController.clear();
    _setTypingEnabled(false);
    _setUserTurn(false);
    _setHintEnabled(false);
    _sendUserMessageText(text);
  }

  void _cancelRecording() {
    debugPrint('[DEBUG] Recording cancelled');
    _stopRecording(discard: true);
    _removeRecordingEntry();
  }

  Future<void> _beginRecording() async {
    if (_isRecording) return;
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
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
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
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
      _showHoldToSpeakMessage();
      debugPrint('[DEBUG] Recording finish -> short(duration<500)');
      return;
    }
    if (path == null) {
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
      debugPrint('[DEBUG] Recording finish -> no path');
      return;
    }
    final bytes = await File(path).readAsBytes();
    _deleteRecordingFile(path);
    _setMicState(_MicButtonState.loading, resetDrag: true);
    _setUserTurn(false);
    _setHintEnabled(false);
    debugPrint('[DEBUG] Recording finish -> sending audio');
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

  TextStyle _cancelTextStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    return (baseStyle ?? const TextStyle()).copyWith(
      color: const Color(0xFF0CABA8),
    );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.size.width;
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
    final bubbleWidth = bodyWidth * 0.7;
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
        );
    final translationText = entry.translationText;
    final translationStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
        );
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: bubbleWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAiAvatar(),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0CABA8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Opacity(
                                opacity: 0,
                                child: Text(
                                  messageText,
                                  style: textStyle,
                                ),
                              ),
                              Text(
                                entry.visibleText ?? '',
                                style: textStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () => _toggleTranslation(entry),
                  child: Image.asset(
                    'assets/images/icons/translation_grey.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
            if (entry.isTranslationExpanded && translationText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 45),
                child: Text(
                  translationText,
                  style: translationStyle,
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

  Widget _buildNarration(
    BuildContext context,
    _ConversationEntry entry,
  ) {
    final narration = entry.narration;
    if (narration == null || narration.text == null) {
      return const SizedBox.shrink();
    }
    final isMission = narration.missionActiveYn == 'Y';
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        );
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
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
        );
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
            child: Text(
              text,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBubble(
    BuildContext context,
    _ConversationEntry entry,
  ) {
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
        _ConversationEntryType.ai =>
          _buildAiMessage(context, bodyWidth, entry),
        _ConversationEntryType.narration => _buildNarration(context, entry),
        _ConversationEntryType.user =>
          _buildUserMessage(context, bodyWidth, entry),
        _ConversationEntryType.recording => _buildRecordingBubble(context, entry),
      },
    );
  }

  String _micAssetForState(_MicButtonState state, bool cancelHover) {
    if (state == _MicButtonState.pressed && cancelHover) {
      return 'assets/images/buttons/mic_btn_default.png';
    }
    return switch (state) {
      _MicButtonState.defaultState => 'assets/images/buttons/mic_btn_default.png',
      _MicButtonState.pressed => 'assets/images/buttons/mic_btn_pressed.png',
      _MicButtonState.loading => 'assets/images/buttons/mic_btn_loading.png',
      _MicButtonState.disabled => 'assets/images/buttons/mic_btn_disabled.png',
    };
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

  void _showServiceMessage(String message) {
    _serviceMessageTimer?.cancel();
    setState(() {
      _serviceMessageText = message;
      _isServiceMessageVisible = true;
    });
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
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
      _setUserTurn(true);
      _setHintEnabled(true);
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
    final text = response.text ?? '';
    if (text.isNotEmpty) {
      final entry = _ConversationEntry.user(text: text);
      await _addEntry(entry);
      _setMicState(_MicButtonState.disabled, resetDrag: true);
      debugPrint('[DEBUG] User bubble shown, requesting AI response');
    }
    if (_wasMissionActive) {
      if (response.missionCompleteYn == 'Y') {
        _setMissionSuccess(_currentStep);
      } else if (response.missionCompleteYn == 'N') {
        _setMissionFailed(_currentStep);
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
    entry.isTranslationLoading = true;
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = RoleplayStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) {
      entry.isTranslationLoading = false;
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
        entry.isTranslationExpanded = true;
      });
    } catch (_) {
      // ignore translation errors
    } finally {
      entry.isTranslationLoading = false;
    }
  }

  Future<RoleplayAiMessageDto?> _fetchAiMessageWithRetry({
    required String accessToken,
    required String sessionId,
  }) async {
    const delayMs = 100;
    const maxRetries = 20;
    final delays = List.generate(
      maxRetries,
      (_) => const Duration(milliseconds: delayMs),
    );
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
            '[DEBUG] AI response received: ${attempt}번째 대기(${delayMs}ms) 후',
          );
        }
        return result;
      } catch (e) {
        final message = e.toString();
        final shouldRetry =
            message.contains('HTTP 202') || message.contains('HTTP 500');
        if (!shouldRetry || attempt >= delays.length) {
          if (attempt >= delays.length) {
            debugPrint(
              '[DEBUG] AI response: ${maxRetries}회 재시도 소진 후 실패 (last: $e)',
            );
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

  double _micSizeForState(_MicButtonState state, bool cancelHover) {
    if (state == _MicButtonState.pressed && cancelHover) {
      return _micDefaultSize;
    }
    return switch (state) {
      _MicButtonState.defaultState => _micDefaultSize,
      _MicButtonState.pressed => _micPressedSize,
      _MicButtonState.loading => _micDefaultSize,
      _MicButtonState.disabled => _micDefaultSize,
    };
  }

  Widget _buildMicButton() {
    final cancelHover = _micState == _MicButtonState.pressed && _isCancelHovered;
    final size = _micSizeForState(_micState, cancelHover);
    final asset = _micAssetForState(_micState, cancelHover);
    final image = Image.asset(
      asset,
      width: size,
      height: size,
    );
    final content = _micState == _MicButtonState.loading
        ? RotationTransition(
            turns: _loadingRotationController,
            child: image,
          )
        : image;

    return AnimatedContainer(
      duration: Duration.zero,
      curve: Curves.easeOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: content,
    );
  }

  Widget _buildDragArrows({
    required double cancelRightX,
    required double areaHeight,
    required double anchorLeftX,
  }) {
    const iconSize = 16.0;
    const gap = 5.0;
    const count = 3;
    final groupWidth = (iconSize * count) + (gap * (count - 1));
    final availableWidth = anchorLeftX - cancelRightX;
    if (availableWidth <= groupWidth) {
      return const SizedBox.shrink();
    }
    final groupLeft =
        cancelRightX + ((availableWidth - groupWidth) / 2);

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
              color: const Color(0x598C8C8C),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    '1.5x',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const handleRadius = 12.0;
                        final railHeight = constraints.maxHeight - (handleRadius * 2);
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white),
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
          final progressRatio =
              maxIndex <= 0 ? 0.0 : (_currentStep / maxIndex).clamp(0.0, 1.0);
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
    final shouldAnimate = _animatingSteps.containsKey(stepIndex) &&
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

  Future<bool> _handleBackButton(BuildContext context) async {
    // 뒤로가기 시 얼럿 표시
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification'),
        content: const Text('Exit from page'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (shouldPop == true && context.mounted) {
      // playing screen 삭제하고 overview로 돌아감
      // overview는 Sub Screen이므로 Navigator.popUntil으로 overview까지 pop
      RoleplayRouter.popToOverview(context);
    }

    return false; // PopScope가 자동으로 pop하지 않도록
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

    final durationFormatted = _formatRemaining();
    final durationColor = _remainingSeconds <= 10 ? Colors.red : Colors.white;
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBackButton(context);
        }
      },
      child: Stack(
        children: [
          RoleplayScaffold(
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
            headerTopSpacing: _headerTopSpacing,
            body: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0;
                                i < _conversationEntries.length;
                                i++) ...[
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
                      child: AnimatedOpacity(
                        opacity: _isServiceMessageVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _serviceMessageText ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  if (_inputMode == _InputMode.recording)
                    SizedBox(
                      height: 120,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final areaWidth = constraints.maxWidth;
                          final centerX = areaWidth / 2;
                          final cancelStyle = _cancelTextStyle(context);
                          final cancelWidth =
                              _measureTextWidth('Cancel', cancelStyle);
                          final cancelRight = cancelWidth;
                          final cancelCenter = cancelWidth / 2;
                          final maxLeftOffset = (_micPressedSize / 2) - centerX;
                          final effectiveOffset = _micState == _MicButtonState.pressed
                              ? _dragOffsetX
                              : 0.0;
                          final showArrows = _micState == _MicButtonState.pressed;
                          final shouldShowCancel = _micState == _MicButtonState.pressed;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: shouldShowCancel ? 1 : 0,
                                  child: Text(
                                    'Cancel',
                                    style: cancelStyle,
                                  ),
                                ),
                              ),
                              if (showArrows)
                                _buildDragArrows(
                                  cancelRightX: cancelRight,
                                  areaHeight: 120,
                                  anchorLeftX: centerX - (_micPressedSize / 2),
                                ),
                              Center(
                                child: Transform.translate(
                                  offset: Offset(effectiveOffset, 0),
                                  child: IgnorePointer(
                                    ignoring: !_isMicInteractive,
                                    child: GestureDetector(
                                      onTapDown: _handleMicTapDown,
                                      onTapUp: (_) => _handleMicTapUp(),
                                      onTapCancel: _handleMicTapCancel,
                                      onPanStart: _handleMicPanStart,
                                      onPanUpdate: (details) => _handleMicPanUpdate(
                                        deltaX: details.delta.dx,
                                        maxLeftOffset: maxLeftOffset,
                                        cancelRightX: cancelRight,
                                        cancelCenterX: cancelCenter,
                                        centerX: centerX,
                                      ),
                                      onPanEnd: (_) {
                                        debugPrint('[DEBUG] Mic PanEnd');
                                        _handleMicTapUp();
                                      },
                                      child: _buildMicButton(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                                    enabled: _isTypingEnabled && _isUserTurn,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _handleSend(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: _isTypingEnabled
                                          ? 'Type your message ...'
                                          : 'Wait for your turn ...',
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: const Color(0xFF9B9B9B)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap:
                                    _isTypingEnabled && _isUserTurn ? _handleSend : null,
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
                            onTap: () {
                              final toRecording = _inputMode == _InputMode.typing;
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
                            ignoring: !_isHintEnabled,
                            child: Opacity(
                              opacity: _isHintEnabled ? 1 : 0.4,
                              child: GestureDetector(
                                onTap: _isHintEnabled ? () {} : null,
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
        ],
      ),
    );
  }
}

enum _MissionStatus {
  ready,
  success,
  failed,
}

enum _InputMode {
  recording,
  typing,
}

enum _MicButtonState {
  defaultState,
  pressed,
  loading,
  disabled,
}

enum _ConversationEntryType {
  ai,
  narration,
  user,
  recording,
}

class _ConversationEntry {
  final _ConversationEntryType type;
  final String? text;
  final RoleplayNarrationDto? narration;
  final GlobalKey key = GlobalKey();
  int? conversationIndex;
  bool isVisible = false;
  String? visibleText;
  String? translationText;
  bool isTranslationExpanded = false;
  bool isTranslationLoading = false;

  _ConversationEntry._({
    required this.type,
    this.text,
    this.narration,
    this.visibleText,
  });

  factory _ConversationEntry.ai({required String text}) {
    return _ConversationEntry._(
      type: _ConversationEntryType.ai,
      text: text,
      visibleText: '',
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
    return _ConversationEntry._(
      type: _ConversationEntryType.user,
      text: text,
    );
  }

  factory _ConversationEntry.recording() {
    return _ConversationEntry._(
      type: _ConversationEntryType.recording,
    );
  }

  bool get consumesIndex => type != _ConversationEntryType.recording;
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
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
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
      return Image.asset(
        widget.asset,
        width: widget.size,
        height: widget.size,
      );
    }

    return ScaleTransition(
      scale: _scale,
      child: Image.asset(
        widget.asset,
        width: widget.size,
        height: widget.size,
      ),
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
