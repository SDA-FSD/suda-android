import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../widgets/roleplay_mic_button_area.dart';
import '../../widgets/roleplay_mission_panel.dart';
import 'playing_conversation_mixin.dart';
import 'playing_hint_mixin.dart';

enum _PlayingInputMode { recording, typing }

enum _PlayingMicButtonState { defaultState, loading, disabled }

enum _PendingRecordingAction { finish, cancel }

/// S2 Playing 입력·푸터 비즈니스 (S1 `playing_backup` 이식).
///
/// API 호출·본문 말풍선 연동은 추후. [activateUserTurn]은 턴 엔진이 사용자 발화 준비 시 호출.
mixin PlayingInputMixin<T extends StatefulWidget>
    on
        State<T>,
        TickerProviderStateMixin<T>,
        PlayingConversationMixin<T>,
        PlayingHintMixin<T> {
  static const int _minRecordingDurationMs = 500;

  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _recordingStartedAt;
  bool _isRecording = false;
  bool _isRecordingStarting = false;
  _PendingRecordingAction? _pendingRecordingAction;
  bool _isUserTurn = false;
  bool _isHintEnabled = false;
  bool _hintUsedThisTurn = false;
  Timer? _hintIdleTimer;
  Timer? _serviceMessageTimer;
  final ScrollController _bodyScrollController = ScrollController();
  bool _isServiceMessageVisible = false;
  String? _serviceMessageText;
  Color? _serviceMessageColor;
  _PlayingMicButtonState _micState = _PlayingMicButtonState.defaultState;
  _PlayingInputMode _inputMode = _PlayingInputMode.recording;
  final FocusNode _typingFocusNode = FocusNode();
  final TextEditingController _typingController = TextEditingController();
  bool _isTypingEnabled = true;
  bool _isInputLocked = false;
  late final AnimationController _loadingRotationController;
  late final AnimationController _hintBlinkController;
  late final AnimationController _analyzingBlinkController;
  bool _isAnalyzingBlinking = false;
  double _missionPanelHeight = RoleplayMissionPanel.collapsedHeight;
  final GlobalKey _missionPanelSizeKey = GlobalKey();
  Future<void> Function(RpS2UserMessageResponseDto response)?
  handleRpS2UserMessageResponse;

  bool get isUserTurn => _isUserTurn;

  bool get _isMicInteractive =>
      _micState == _PlayingMicButtonState.defaultState && _isUserTurn;

  void initPlayingInput() {
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
  }

  void disposePlayingInput() {
    _hintIdleTimer?.cancel();
    _serviceMessageTimer?.cancel();
    _bodyScrollController.dispose();
    _recorder.dispose();
    _typingFocusNode.dispose();
    _typingController.dispose();
    _loadingRotationController.dispose();
    _hintBlinkController.dispose();
    _analyzingBlinkController.dispose();
  }

  /// S2 턴 흐름에서 사용자 발화 준비 시점에 호출 (S1 `_activateUserTurn` 이식).
  void activateUserTurn({bool enableHintButton = true}) {
    _hintUsedThisTurn = !enableHintButton;
    _isInputLocked = false;
    _setUserTurn(true);
    _setMicState(_PlayingMicButtonState.defaultState);
    _setHintEnabled(enableHintButton);
    _setTypingEnabled(true);
    if (_inputMode == _PlayingInputMode.typing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_inputMode == _PlayingInputMode.typing &&
            _isTypingEnabled &&
            _isUserTurn &&
            _typingFocusNode.context != null) {
          _typingFocusNode.requestFocus();
        }
      });
    }
    if (_inputMode == _PlayingInputMode.recording) {
      _showHoldToSpeakMessage();
      _hintIdleTimer?.cancel();
      _hintIdleTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_isUserTurn &&
            _inputMode == _PlayingInputMode.recording &&
            _isHintEnabled &&
            !_hintUsedThisTurn) {
          _hintBlinkController.repeat(reverse: true);
        }
      });
    }
  }

  void deactivateUserTurn() {
    _setUserTurn(false);
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    _setMicState(_PlayingMicButtonState.disabled);
  }

  /// AI 말풍선 노출 직전 — 힌트 아이콘 비활성·깜빡임 해제.
  void resetHintIconForAiStart() {
    _hintUsedThisTurn = false;
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
  }

  /// 오토힌트 OFF — AI 음성 종료 후 힌트 아이콘 활성 + 3초 idle blink.
  void onHintAvailableAfterAi() {
    _hintUsedThisTurn = false;
    _setHintEnabled(true);
    _cancelHintIdleAndBlink();
    _hintIdleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_isHintEnabled && !_hintUsedThisTurn) {
        _hintBlinkController.repeat(reverse: true);
      }
    });
  }

  /// 본문: 스크롤 영역 + 상·하단 페이드 + 미션 패널 오버레이.
  Widget buildPlayingBody({
    required double scaffoldBodyLeadHeight,
    required Widget topOverlay,
    required double missionPanelOpacity,
    required List<Widget> Function(double bodyWidth) conversationBuilder,
  }) {
    final missionPanelFadeExtent = _missionPanelHeight * missionPanelOpacity;
    final fadeHeight =
        scaffoldBodyLeadHeight +
        PlayingConversationLayout.missionPanelTop +
        missionPanelFadeExtent;
    final footerLowerHeight = _inputMode == _PlayingInputMode.recording
        ? roleplayMicFooterStackHeight
        : 10 + 44 + 10 + roleplayFooterIconRowHeight;
    final bottomFadeExtension =
        footerLowerHeight +
        PlayingConversationLayout.scaffoldFooterBottomGap +
        MediaQuery.paddingOf(context).bottom;
    final bottomFadeHeight =
        PlayingConversationLayout.bottomContentFadeBodyExtent +
        bottomFadeExtension;
    final fadeHorizontalBleed =
        PlayingConversationLayout.scaffoldBodyHorizontalInset;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: PlayingConversationLayout.bodyTopGap),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final children = conversationBuilder(constraints.maxWidth);
                  return SingleChildScrollView(
                    controller: _bodyScrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (children.isNotEmpty)
                          const SizedBox(
                            height:
                                PlayingConversationLayout.firstBubbleTopOffset,
                          ),
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          children[i],
                        ],
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: -scaffoldBodyLeadHeight,
                left: -fadeHorizontalBleed,
                right: -fadeHorizontalBleed,
                height: fadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PlayingConversationLayout.topContentFadeColor,
                          PlayingConversationLayout.topContentFadeColor
                              .withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -bottomFadeExtension,
                left: -fadeHorizontalBleed,
                right: -fadeHorizontalBleed,
                height: bottomFadeHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          PlayingConversationLayout.bottomContentFadeColor,
                          PlayingConversationLayout.bottomContentFadeColor
                              .withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: PlayingConversationLayout.missionPanelTop,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: missionPanelOpacity,
                  duration:
                      RoleplayMissionPanel.completedBackgroundFadeDuration,
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    ignoring: missionPanelOpacity < 1,
                    child: NotificationListener<SizeChangedLayoutNotification>(
                      onNotification: (notification) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final renderBox =
                              _missionPanelSizeKey.currentContext
                                      ?.findRenderObject()
                                  as RenderBox?;
                          if (renderBox == null || !renderBox.hasSize) return;
                          final nextHeight = renderBox.size.height;
                          if (nextHeight != _missionPanelHeight) {
                            setState(() => _missionPanelHeight = nextHeight);
                          }
                        });
                        return false;
                      },
                      child: SizeChangedLayoutNotifier(
                        child: KeyedSubtree(
                          key: _missionPanelSizeKey,
                          child: topOverlay,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PlayingConversationLayout.bodyTopGap),
      ],
    );
  }

  void scrollPlayingBodyToBottom({GlobalKey? anchorKey}) {
    void performScroll() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final anchorContext = anchorKey?.currentContext;
        if (anchorContext != null) {
          Scrollable.ensureVisible(
            anchorContext,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 1.0,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
        if (!_bodyScrollController.hasClients) return;
        final position = _bodyScrollController.position;
        position.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }

    performScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) => performScroll());
    Future<void>.delayed(const Duration(milliseconds: 280), performScroll);
    Future<void>.delayed(const Duration(milliseconds: 480), performScroll);
  }

  void showPlayingServiceMessage(String message, {bool persistent = false}) {
    _showServiceMessage(message, persistent: persistent);
  }

  void startPlayingAnalyzingBlink({String? message}) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedMessage =
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : l10n.roleplayAnalyzing;
    _serviceMessageTimer?.cancel();
    if (!_analyzingBlinkController.isAnimating) {
      _analyzingBlinkController.repeat(reverse: true);
    }
    setState(() {
      _serviceMessageText = resolvedMessage;
      _serviceMessageColor = null;
      _isServiceMessageVisible = true;
      _isAnalyzingBlinking = true;
    });
  }

  void stopPlayingAnalyzingBlink() {
    if (_analyzingBlinkController.isAnimating) {
      _analyzingBlinkController.stop();
    }
    _analyzingBlinkController.reset();
    if (!mounted) return;
    setState(() {
      _isAnalyzingBlinking = false;
      _isServiceMessageVisible = false;
    });
  }

  Widget _buildFooterIconRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _isInputLocked
                ? null
                : () {
                    final toRecording =
                        _inputMode == _PlayingInputMode.typing;
                    if (!toRecording) {
                      _cancelHintIdleAndBlink();
                    }
                    setState(() {
                      _inputMode = toRecording
                          ? _PlayingInputMode.recording
                          : _PlayingInputMode.typing;
                    });
                    if (toRecording && _isUserTurn) {
                      _showHoldToSpeakMessage();
                    }
                  },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Image.asset(
                  _inputMode == _PlayingInputMode.typing
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
            ignoring: !_isHintEnabled || _isInputLocked,
            child: AnimatedBuilder(
              animation: _hintBlinkController,
              builder: (context, child) {
                final baseOpacity = _isHintEnabled ? 1.0 : 0.4;
                final blinkOpacity = _hintBlinkController.isAnimating
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
    );
  }

  Widget buildPlayingFooter() {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          if (_inputMode == _PlayingInputMode.recording)
            SizedBox(
              height: roleplayMicFooterStackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: roleplayFooterIconRowHeight,
                    child: _buildFooterIconRow(),
                  ),
                  Positioned.fill(
                    child: RoleplayMicButtonArea(
                      isInteractive: _isMicInteractive && !_isInputLocked,
                      isLoading: _micState == _PlayingMicButtonState.loading,
                      isDisabled: _micState == _PlayingMicButtonState.disabled,
                      loadingRotationController: _loadingRotationController,
                      onPressStart: _onMicPressStart,
                      onPressEnd: _onMicPressEnd,
                      onPressCancel: _onMicPressCancel,
                    ),
                  ),
                ],
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
                            enabled:
                                _isTypingEnabled &&
                                _isUserTurn &&
                                !_isInputLocked,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSend(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: _isInputLocked
                                  ? ''
                                  : (_isTypingEnabled
                                        ? l10n.roleplayTypeMessagePlaceholder
                                        : 'Wait for your turn ...'),
                              hintStyle: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF9B9B9B)),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap:
                            _isTypingEnabled && _isUserTurn && !_isInputLocked
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
          if (_inputMode != _PlayingInputMode.recording)
            SizedBox(
              height: roleplayFooterIconRowHeight,
              child: _buildFooterIconRow(),
            ),
        ],
      ),
    );
  }

  void _setUserTurn(bool isUserTurn) {
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
    setState(() => _isHintEnabled = isEnabled);
  }

  void _setTypingEnabled(bool isEnabled) {
    if (!mounted) return;
    setState(() => _isTypingEnabled = isEnabled);
  }

  void _setMicState(_PlayingMicButtonState next) {
    if (_micState == next) return;
    setState(() => _micState = next);
    _syncLoadingAnimation();
  }

  void _syncLoadingAnimation() {
    if (_micState == _PlayingMicButtonState.loading) {
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

  void _cancelHintIdleAndBlink() {
    _hintIdleTimer?.cancel();
    _hintIdleTimer = null;
    if (_hintBlinkController.isAnimating) {
      _hintBlinkController.stop();
      _hintBlinkController.reset();
    }
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
      setState(() => _isServiceMessageVisible = false);
      _serviceMessageTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _serviceMessageText = null);
      });
    });
  }

  void _onMicPressStart() {
    unawaited(_beginRecording());
  }

  void _onMicPressEnd(bool cancel) {
    if (cancel) {
      unawaited(_cancelRecording());
    } else {
      unawaited(_finishRecording());
    }
  }

  void _onMicPressCancel() {
    unawaited(_cancelRecording());
  }

  void _handleSend() {
    if (!_isTypingEnabled || !_isUserTurn || _isInputLocked) return;
    final text = _typingController.text.trim();
    if (text.isEmpty) return;
    _typingController.clear();
    _isInputLocked = true;
    _setTypingEnabled(false);
    _setUserTurn(false);
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    dismissPlayingHint();
    unawaited(_sendUserMessageText(text));
  }

  Future<void> _onHintTap() async {
    if (!_isHintEnabled || _isFetchingHintForTap) return;
    _isFetchingHintForTap = true;
    _hintUsedThisTurn = true;
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    try {
      await showPlayingHint();
    } finally {
      _isFetchingHintForTap = false;
    }
  }

  bool _isFetchingHintForTap = false;

  Future<void> _beginRecording() async {
    if (_isRecording || _isRecordingStarting) return;
    _cancelHintIdleAndBlink();

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      DefaultToast.show(
        context,
        'Cannot start without microphone permission.',
        isError: true,
      );
      return;
    }

    final path =
        '${Directory.systemTemp.path}/rps2_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingStartedAt = DateTime.now();
    _isRecordingStarting = true;
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    } catch (e) {
      debugPrint('[DEBUG] S2 recording start error: $e');
      _isRecordingStarting = false;
      _recordingStartedAt = null;
      _pendingRecordingAction = null;
      if (!mounted) return;
      _setMicState(_PlayingMicButtonState.defaultState);
      return;
    }
    _isRecordingStarting = false;
    if (!mounted) return;
    setState(() => _isRecording = true);
    showPlayingRecordingEntry();
    final pendingAction = _pendingRecordingAction;
    _pendingRecordingAction = null;
    if (pendingAction == _PendingRecordingAction.cancel) {
      unawaited(_cancelRecording());
    } else if (pendingAction == _PendingRecordingAction.finish) {
      unawaited(_finishRecording());
    }
  }

  Future<void> _cancelRecording() async {
    if (_isRecordingStarting && !_isRecording) {
      _pendingRecordingAction = _PendingRecordingAction.cancel;
      return;
    }
    _recordingStartedAt = null;
    await _stopRecording(discard: true);
    removePlayingRecordingEntry();
    if (!mounted) return;
    setState(() => _isRecording = false);
    _setMicState(_PlayingMicButtonState.defaultState);
  }

  Future<void> _finishRecording() async {
    if (_isRecordingStarting && !_isRecording) {
      _pendingRecordingAction = _PendingRecordingAction.finish;
      return;
    }
    if (!_isRecording) {
      _setMicState(_PlayingMicButtonState.defaultState);
      _showHoldToSpeakMessage();
      return;
    }
    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    final durationMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    final path = await _stopRecording();
    removePlayingRecordingEntry();
    if (!mounted) return;
    setState(() => _isRecording = false);

    if (durationMs < _minRecordingDurationMs) {
      _deleteRecordingFile(path);
      _setMicState(_PlayingMicButtonState.defaultState);
      _showHoldToSpeakMessage();
      return;
    }
    if (path == null) {
      _setMicState(_PlayingMicButtonState.defaultState);
      return;
    }
    final bytes = await File(path).readAsBytes();
    _deleteRecordingFile(path);
    _setMicState(_PlayingMicButtonState.loading);
    _isInputLocked = true;
    _setUserTurn(false);
    _setHintEnabled(false);
    _cancelHintIdleAndBlink();
    dismissPlayingHint();
    await _sendUserMessageAudio(bytes);
  }

  Future<String?> _stopRecording({bool discard = false}) async {
    if (!_isRecording) return null;
    if (discard) {
      await _recorder.cancel();
      return null;
    }
    return _recorder.stop();
  }

  void _deleteRecordingFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  Future<void> _sendUserMessageAudio(Uint8List audioData) async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) {
      _restoreUserTurnAfterSendFailure();
      return;
    }
    late final RpS2UserMessageResponseDto response;
    try {
      response = await SudaApiClient.sendRpS2UserMessageAudio(
        accessToken: accessToken,
        rpSessionId: sessionId,
        audioData: audioData,
      );
    } catch (e, st) {
      debugPrint('[DEBUG] S2 user audio request error: $e\n$st');
      if (!mounted) return;
      _restoreUserTurnAfterSendFailure();
      return;
    }
    if (!mounted) return;
    _setMicState(_PlayingMicButtonState.disabled);
    try {
      await handleRpS2UserMessageResponse?.call(response);
    } catch (e, st) {
      debugPrint('[DEBUG] S2 user audio response handling error: $e\n$st');
      if (!mounted) return;
      _restoreUserTurnAfterSendFailure();
    }
  }

  Future<void> _sendUserMessageText(String text) async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) {
      _restoreUserTurnAfterSendFailure();
      return;
    }
    late final RpS2UserMessageResponseDto response;
    try {
      response = await SudaApiClient.sendRpS2UserMessageText(
        accessToken: accessToken,
        rpSessionId: sessionId,
        text: text,
      );
    } catch (e, st) {
      debugPrint('[DEBUG] S2 user text request error: $e\n$st');
      if (!mounted) return;
      _restoreUserTurnAfterSendFailure();
      return;
    }
    if (!mounted) return;
    try {
      await handleRpS2UserMessageResponse?.call(response);
    } catch (e, st) {
      debugPrint('[DEBUG] S2 user text response handling error: $e\n$st');
      if (!mounted) return;
      _restoreUserTurnAfterSendFailure();
    }
  }

  void _restoreUserTurnAfterSendFailure() {
    _isInputLocked = false;
    _setMicState(_PlayingMicButtonState.defaultState);
    _setTypingEnabled(true);
    _setUserTurn(true);
    if (!_hintUsedThisTurn) _setHintEnabled(true);
  }
}
