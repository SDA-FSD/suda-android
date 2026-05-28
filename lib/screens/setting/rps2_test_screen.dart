import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:record/record.dart';

import '../../l10n/app_localizations.dart';
import '../../models/rps2_test_models.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/language_util.dart';
import '../../widgets/app_scaffold.dart';

class RpS2TestScreen extends StatefulWidget {
  const RpS2TestScreen({super.key, required this.initialTotalTurns});

  final int initialTotalTurns;

  @override
  State<RpS2TestScreen> createState() => _RpS2TestScreenState();
}

enum _BubbleRole { ai, user, narration }

class _RpS2Bubble {
  const _RpS2Bubble({required this.role, required this.text});

  final _BubbleRole role;
  final String text;
}

class _RpS2TestScreenState extends State<RpS2TestScreen> {
  /// Playing(`playing.dart`)과 동일: 500ms 미만 녹음은 STT 전송하지 않음.
  static const int _minRecordingDurationMs = 500;

  static const Color _pageBg = Color(0xFF121212);
  static const Color _aiBubbleColor = Color(0xFF0CABA8);
  static const Color _progressIdleColor = Color(0x66635F5F);
  static const Color _progressActiveColor = Color(0xFFFFAAE1);
  static const String _screenTitle = 'What Job Do I Even Want?';

  final AudioRecorder _recorder = AudioRecorder();
  final ScrollController _scrollController = ScrollController();

  final List<_RpS2Bubble> _bubbles = [
    const _RpS2Bubble(role: _BubbleRole.ai, text: 'Hey, Kevin! Over here!'),
  ];

  late final List<String> _missionLabels;
  final Set<int> _completedMissionIndexes = <int>{};

  bool _isRecording = false;
  bool _isProcessing = false;
  DateTime? _recordingStartedAt;
  int _currentTurn = 0;
  late int _totalTurns;
  String? _scoreOverlayText;
  Timer? _scoreOverlayTimer;

  @override
  void initState() {
    super.initState();
    _totalTurns = widget.initialTotalTurns < 1 ? 1 : widget.initialTotalTurns;
    _missionLabels = _resolveMissionLabels();
  }

  @override
  void dispose() {
    _scoreOverlayTimer?.cancel();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _cancelRecording() async {
    _recordingStartedAt = null;
    await _stopRecording(discard: true);
    if (mounted) setState(() {});
  }

  Future<void> _beginRecording() async {
    if (_isRecording) return;

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
        '${Directory.systemTemp.path}/rps2_test_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingStartedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (!mounted) return;
    setState(() => _isRecording = true);
  }

  Future<void> _finishRecordingAndSend() async {
    if (!_isRecording) return;

    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    final durationMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    final path = await _stopRecording();

    if (durationMs < _minRecordingDurationMs) {
      _deleteRecordingFile(path);
      if (mounted) {
        setState(() {});
        DefaultToast.show(
          context,
          AppLocalizations.of(context)!.holdMicrophoneToSpeak,
        );
      }
      return;
    }

    if (path == null || path.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await File(path).readAsBytes();
      _deleteRecordingFile(path);
      if (bytes.isEmpty) {
        throw Exception('empty audio');
      }
      await _submitUserAudio(bytes);
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'RpS2 Test failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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

  Future<void> _submitUserAudio(Uint8List audioData) async {
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      if (!mounted) return;
      DefaultToast.show(context, 'Not signed in', isError: true);
      return;
    }

    final res = await SudaApiClient.postRpS2TestUserMessage(
      accessToken: token,
      audioData: audioData,
    );
    if (!mounted) return;

    final userText = res.userText.trim();
    final narration = res.narration.trim();
    final answer = res.answer.trim();

    if (userText.isNotEmpty) {
      _bubbles.add(_RpS2Bubble(role: _BubbleRole.user, text: userText));
    }

    _currentTurn = (_currentTurn + 1).clamp(0, _totalTurns);
    _showScoreOverlay(_normalizeScoreText(res.score));
    _markMissionCompleted(res.mission);

    setState(() {});
    _scrollToBottom();

    // 나레이션을 AI 발화 직전에 보여 주기 위해 순차 삽입
    if (narration.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      _bubbles.add(_RpS2Bubble(role: _BubbleRole.narration, text: narration));
      setState(() {});
      _scrollToBottom();
    }

    if (answer.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      _bubbles.add(_RpS2Bubble(role: _BubbleRole.ai, text: answer));
      setState(() {});
      _scrollToBottom();
    }
  }

  void _showScoreOverlay(String text) {
    _scoreOverlayTimer?.cancel();
    setState(() => _scoreOverlayText = text);
    _scoreOverlayTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _scoreOverlayText = null);
    });
  }

  void _markMissionCompleted(int missionRaw) {
    if (missionRaw < 0) return;
    // 백엔드 값이 0-based/1-based 혼재 가능성을 모두 수용
    final zeroBased = missionRaw <= 2 ? missionRaw : missionRaw - 1;
    if (zeroBased >= 0 && zeroBased < _missionLabels.length) {
      _completedMissionIndexes.add(zeroBased);
    }
  }

  List<String> _resolveMissionLabels() {
    final lang = LanguageUtil.getCurrentLanguageCode();
    if (lang == 'ko') {
      return const [
        'Mia에게 미래에 대해 어떻게 느끼는지 말하세요.',
        '무엇을 하는 것을 좋아하는지 말하세요.',
        '원하는 직업 하나를 말하세요.',
      ];
    }
    if (lang == 'pt') {
      return const [
        'Conte para Mia como você se sente em relação ao seu futuro.',
        'Conte para Mia o que você gosta de fazer.',
        'Conte para Mia uma profissão que você quer.',
      ];
    }
    return const [
      'Tell Mia how you feel about your future.',
      'Tell Mia what you like doing.',
      'Tell Mia one job you want.',
    ];
  }

  String _normalizeScoreText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Score';
    return text;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppScaffold(
      backgroundColor: _pageBg,
      showBackButton: false,
      bodyTopPadding: 8,
      usePadding: false,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTopSection(theme),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: _bubbles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildBubble(theme, _bubbles[index]),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: _buildMicButton(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(TextTheme theme) {
    final scoreVisible = _scoreOverlayText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLocalHeader(theme),
        const SizedBox(height: 4),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: scoreVisible
                ? Text(
                    _scoreOverlayText!,
                    key: const ValueKey('score_text'),
                    textAlign: TextAlign.center,
                    style: theme.labelSmall?.copyWith(
                      color: const Color(0xFFFFAAE1),
                      fontSize: 10,
                      height: 1.0,
                    ),
                  )
                : Text(
                    '$_currentTurn / $_totalTurns',
                    key: const ValueKey('turn_count_text'),
                    textAlign: TextAlign.center,
                    style: theme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _totalTurns; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < _currentTurn
                        ? _progressActiveColor
                        : _progressIdleColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (i < _totalTurns - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _buildMissionCard(theme),
      ],
    );
  }

  Widget _buildLocalHeader(TextTheme theme) {
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/icons/header_arrow_back.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              _screenTitle,
              style: theme.headlineSmall?.copyWith(
                color: Colors.white,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(TextTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF353535)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _missionLabels.length; i++) ...[
            _buildMissionRow(theme, i),
            if (i < _missionLabels.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMissionRow(TextTheme theme, int index) {
    final completed = _completedMissionIndexes.contains(index);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? _aiBubbleColor : Colors.transparent,
            border: Border.all(color: const Color(0xFF7A7A7A), width: 1.5),
          ),
          child: completed
              ? const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _missionLabels[index],
            style: theme.labelSmall?.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(TextTheme theme, _RpS2Bubble bubble) {
    switch (bubble.role) {
      case _BubbleRole.user:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bubble.text,
              style: theme.bodyLarge?.copyWith(color: Colors.black),
            ),
          ),
        );
      case _BubbleRole.ai:
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E2E2E),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'M',
                  style: theme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(maxWidth: 240, minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _aiBubbleColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bubble.text,
                  style: theme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      case _BubbleRole.narration:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            bubble.text,
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  Widget _buildMicButton(TextTheme theme) {
    final processing = _isProcessing;
    final recording = _isRecording;
    return Listener(
      onPointerDown: (_) {
        if (processing) return;
        _beginRecording();
      },
      onPointerUp: (_) {
        if (processing) return;
        _finishRecordingAndSend();
      },
      onPointerCancel: (_) => _cancelRecording(),
      child: AbsorbPointer(
        child: SizedBox(
          width: 110,
          height: 110,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor:
                  recording ? const Color(0xFFE4382A) : Colors.white,
              foregroundColor:
                  recording ? Colors.white : const Color(0xFF202020),
              elevation: 0,
              padding: EdgeInsets.zero,
            ),
            child: processing
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF202020),
                    ),
                  )
                : Icon(
                    Icons.mic_rounded,
                    size: 48,
                    color: recording ? Colors.white : const Color(0xFF202020),
                  ),
          ),
        ),
      ),
    );
  }
}
