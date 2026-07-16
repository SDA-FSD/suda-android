import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../api/suda_api_client.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/speech_feedback_premium.dart';
import '../../widgets/app_scaffold.dart';

const String _kRoleUser = 'USER';
const String _kRoleAiCharacter = 'AI_CHARACTER';
const String _kRoleAiNarrator = 'AI_NARRATOR';
const String _kRoleSystemMission = 'SYSTEM_MISSION';

const Color _exprTextPrimary = Color(0xFF121212);
const Color _feedbackTextColor = Color(0xFF635F5F);

/// S2 Result Speech Feedback 헤더 "View Chat" 진입 화면.
class ViewChatScreen extends StatefulWidget {
  const ViewChatScreen({
    super.key,
    required this.history,
  });

  final RpS2UserHistoryDto history;

  @override
  State<ViewChatScreen> createState() => _ViewChatScreenState();
}

class _ViewChatScreenState extends State<ViewChatScreen> {
  static const Color _gradientTop = Color(0xFF054544);
  static const Color _gradientBottom = Color(0xFF0CABA8);
  static const Color _overlayBlack40 = Color(0x66000000);
  static const Color _bubblePlayingBg = Color(0xFF80D7CF);
  static const Color _bubblePlayingText = Color(0xFF054544);
  static const Color _aiBubbleIdleBg = Color(0xFF0CABA8);
  static const Color _megaphoneTintActive = Color(0xFF0CABA8);
  static const String _megaphonePng = 'assets/images/icons/megaphone.png';
  static const String _megaphoneFillPng =
      'assets/images/icons/megaphone_fill.png';
  static const double _bubblePaddingH = 12;
  static const double _bubblePaddingV = 10;
  static const double _bubbleRadiusMultiLine = 20;
  static const Duration _autoPlayGap = Duration(milliseconds: 300);

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _audioSub;
  int _playSeq = 0;

  bool _isAutoPlaying = false;
  int? _playingMsgId;
  int? _loadingMsgId;

  List<RpS2UserHistoryMsgDto> get _messages => widget.history.messages;

  Map<int, RpS2UserFeedbackVo> get _speechFeedback =>
      widget.history.speechFeedback;

  @override
  void dispose() {
    _audioSub?.cancel();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  bool _canPlayMessage(RpS2UserHistoryMsgDto message) {
    final role = message.role;
    if (role == _kRoleUser) {
      return message.audioInputYn == 'Y' && message.id != null;
    }
    if (role == _kRoleAiCharacter) {
      final path = message.audioPath;
      return path != null && path.isNotEmpty;
    }
    return false;
  }

  bool _isMessageActive(int? msgId) =>
      msgId != null && (_playingMsgId == msgId || _loadingMsgId == msgId);

  void _showNoAudioToast() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    DefaultToast.show(context, l10n.reviewChatNoAudioToPlay, isError: true);
  }

  Future<void> _stopPlayback() async {
    _playSeq++;
    _audioSub?.cancel();
    _audioSub = null;
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isAutoPlaying = false;
      _playingMsgId = null;
      _loadingMsgId = null;
    });
  }

  Future<AudioSource?> _prepareAudio({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    await _audioPlayer.stop();
    if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
      final url = '${AppConfig.cdnBaseUrl}$cdnPath';
      final source = AudioSource.uri(Uri.parse(url));
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    if (soundBytes != null && soundBytes.isNotEmpty) {
      final source = AudioSource.uri(
        Uri.dataFromBytes(soundBytes, mimeType: 'audio/mpeg'),
      );
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    return null;
  }

  Future<AudioSource?> _loadMessageSource(
    RpS2UserHistoryMsgDto message,
  ) async {
    if (message.role == _kRoleAiCharacter) {
      return _prepareAudio(
        cdnYn: 'Y',
        cdnPath: message.audioPath,
        soundBytes: null,
      );
    }

    final historyId = widget.history.id;
    final token = await TokenStorage.loadAccessToken();
    if (historyId == null || token == null || message.id == null) {
      return null;
    }

    final tts = await SudaApiClient.getRpS2UserHistoryMessageAudio(
      accessToken: token,
      rpUserHistoryId: historyId,
      rpMsgId: message.id!,
    );
    return _prepareAudio(
      cdnYn: tts.cdnYn,
      cdnPath: tts.cdnPath,
      soundBytes: tts.sound,
    );
  }

  Future<bool> _playMessageAndWait(
    RpS2UserHistoryMsgDto message,
    int seq,
  ) async {
    final msgId = message.id;
    if (msgId == null || !_canPlayMessage(message)) {
      return false;
    }

    _audioSub?.cancel();
    _audioSub = null;
    await _audioPlayer.stop();

    if (!mounted || seq != _playSeq) return false;
    setState(() {
      _playingMsgId = msgId;
      _loadingMsgId = msgId;
    });

    try {
      final source = await _loadMessageSource(message);
      if (!mounted || seq != _playSeq) return false;

      setState(() => _loadingMsgId = null);

      if (source == null) {
        setState(() => _playingMsgId = null);
        return false;
      }

      final completer = Completer<void>();
      _audioSub = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioSub?.cancel();
          _audioSub = null;
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });
      await _audioPlayer.play();
      await completer.future;

      if (!mounted || seq != _playSeq) return false;
      setState(() => _playingMsgId = null);
      return true;
    } catch (_) {
      if (!mounted || seq != _playSeq) return false;
      setState(() {
        _loadingMsgId = null;
        _playingMsgId = null;
      });
      return false;
    }
  }

  Future<void> _onPlayTap(RpS2UserHistoryMsgDto message) async {
    final msgId = message.id;
    if (msgId == null || !_canPlayMessage(message)) return;

    if (_playingMsgId == msgId && _loadingMsgId == null) {
      await _stopPlayback();
      return;
    }
    if (_loadingMsgId == msgId) return;

    if (_isAutoPlaying) {
      setState(() => _isAutoPlaying = false);
    }
    _playSeq++;
    final seq = _playSeq;
    await _playMessageAndWait(message, seq);
  }

  Future<void> _onBubbleTap(RpS2UserHistoryMsgDto message) async {
    if (_canPlayMessage(message)) {
      await _onPlayTap(message);
      return;
    }

    final role = message.role;
    if (role == _kRoleUser || role == _kRoleAiCharacter) {
      _showNoAudioToast();
    }
  }

  Future<void> _onHeaderMegaphoneTap() async {
    if (_isAutoPlaying) {
      await _stopPlayback();
      return;
    }

    final playable = _messages
        .where(_canPlayMessage)
        .where((message) => message.id != null)
        .toList()
      ..sort((a, b) => a.id!.compareTo(b.id!));

    if (playable.isEmpty) {
      _showNoAudioToast();
      return;
    }

    await _stopPlayback();
    _playSeq++;
    final seq = _playSeq;
    if (!mounted) return;
    setState(() => _isAutoPlaying = true);

    for (var i = 0; i < playable.length; i++) {
      if (!mounted || seq != _playSeq) break;

      final played = await _playMessageAndWait(playable[i], seq);
      if (!mounted || seq != _playSeq) break;

      if (i < playable.length - 1 && played) {
        await Future<void>.delayed(_autoPlayGap);
      }
    }

    if (!mounted || seq != _playSeq) return;
    setState(() {
      _isAutoPlaying = false;
      _playingMsgId = null;
      _loadingMsgId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_gradientTop, _gradientBottom],
            ),
          ),
        ),
        const ColoredBox(color: _overlayBlack40),
        AppScaffold(
          centerTitle: 'Chat History',
          showBackButton: true,
          backgroundColor: Colors.transparent,
          usePadding: false,
          actions: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_onHeaderMegaphoneTap()),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Image.asset(
                    _isAutoPlaying ? _megaphoneFillPng : _megaphonePng,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bodyWidth = constraints.maxWidth;
              if (_messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No chat history.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _messages.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _buildEntry(context, bodyWidth, _messages[i]),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntry(
    BuildContext context,
    double bodyWidth,
    RpS2UserHistoryMsgDto message,
  ) {
    final text = message.content?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    switch (message.role) {
      case _kRoleUser:
        return _ViewChatUserCard(
          message: message,
          feedback: message.id == null ? null : _speechFeedback[message.id],
          audioInputEnabled: message.audioInputYn == 'Y',
          isActive: _isMessageActive(message.id),
          isLoading: message.id != null && _loadingMsgId == message.id,
          isPlaying: message.id != null && _playingMsgId == message.id,
          onAudioTap: () => unawaited(_onPlayTap(message)),
        );
      case _kRoleAiCharacter:
        return _buildAiBubble(context, bodyWidth, message, text);
      case _kRoleAiNarrator:
        return _buildNarrationBubble(context, text, isMission: false);
      case _kRoleSystemMission:
        return _buildNarrationBubble(context, text, isMission: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMegaphoneIcon({
    required bool playingActive,
    bool tint = true,
    Color idleColor = _megaphoneTintActive,
  }) {
    return Image.asset(
      playingActive ? _megaphoneFillPng : _megaphonePng,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      color: tint
          ? (playingActive ? _megaphoneTintActive : idleColor)
          : null,
      colorBlendMode: tint ? BlendMode.srcIn : null,
    );
  }

  Widget _buildAiBubble(
    BuildContext context,
    double bodyWidth,
    RpS2UserHistoryMsgDto message,
    String text,
  ) {
    final msgId = message.id;
    final isActive = _isMessageActive(msgId);
    final isLoading = msgId != null && _loadingMsgId == msgId;
    final canPlay = _canPlayMessage(message);
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isActive ? _bubblePlayingText : Colors.white,
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: bodyWidth,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxTextWidth = constraints.maxWidth -
                _bubblePaddingH * 2 -
                (isLoading ? 24 : 0) -
                (canPlay ? 32 : 0);
            return GestureDetector(
              onTap: canPlay ? () => unawaited(_onBubbleTap(message)) : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: _bubblePaddingH,
                  vertical: _bubblePaddingV,
                ),
                decoration: BoxDecoration(
                  color: isActive ? _bubblePlayingBg : _aiBubbleIdleBg,
                  borderRadius: _bubbleBorderRadius(
                    context: context,
                    text: text,
                    textStyle: textStyle,
                    maxTextWidth: maxTextWidth,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: Text(text, style: textStyle)),
                    if (isLoading) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _bubblePlayingText.withValues(alpha: 0.7),
                        ),
                      ),
                    ] else if (canPlay) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => unawaited(_onBubbleTap(message)),
                        behavior: HitTestBehavior.opaque,
                        child: _buildMegaphoneIcon(
                          playingActive:
                              msgId != null && _playingMsgId == msgId,
                          idleColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  BorderRadius _bubbleBorderRadius({
    required BuildContext context,
    required String text,
    required TextStyle? textStyle,
    required double maxTextWidth,
  }) {
    if (_isSingleLineBubble(context, text, textStyle, maxTextWidth)) {
      return BorderRadius.circular(999);
    }
    return BorderRadius.circular(_bubbleRadiusMultiLine);
  }

  bool _isSingleLineBubble(
    BuildContext context,
    String text,
    TextStyle? textStyle,
    double maxTextWidth,
  ) {
    if (text.contains('\n') || maxTextWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: maxTextWidth);
    return !painter.didExceedMaxLines;
  }

  Widget _buildNarrationBubble(
    BuildContext context,
    String text, {
    required bool isMission,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        );
    const missionColor = Color(0xFFFF00A6);
    return Center(
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
                  text,
                  textAlign: TextAlign.center,
                  style: baseStyle?.copyWith(color: missionColor),
                ),
              ],
            )
          : Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle?.copyWith(color: Colors.white),
            ),
    );
  }
}

class _ViewChatUserCard extends StatefulWidget {
  const _ViewChatUserCard({
    required this.message,
    required this.feedback,
    required this.audioInputEnabled,
    required this.isActive,
    required this.isLoading,
    required this.isPlaying,
    required this.onAudioTap,
  });

  final RpS2UserHistoryMsgDto message;
  final RpS2UserFeedbackVo? feedback;
  final bool audioInputEnabled;
  final bool isActive;
  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onAudioTap;

  @override
  State<_ViewChatUserCard> createState() => _ViewChatUserCardState();
}

class _ViewChatUserCardState extends State<_ViewChatUserCard> {
  static const String _megaphonePng = 'assets/images/icons/megaphone.png';
  static const String _megaphoneFillPng =
      'assets/images/icons/megaphone_fill.png';
  static const Color _megaphoneTintActive = Color(0xFF0CABA8);
  static const Color _megaphoneSpinnerColor = Color(0xFF054544);
  static const Duration _expandDuration = Duration(milliseconds: 300);
  static const Curve _expandCurve = Curves.easeInOutCubic;

  bool _expanded = false;

  String get _userSpeech => widget.message.content?.trim() ?? '';

  bool get _hasFeedbackContent {
    final feedbackText = widget.feedback?.feedback?.trim();
    return feedbackText != null && feedbackText.isNotEmpty;
  }

  bool get _hasScore => widget.feedback?.score != null;

  void _onFeedbackTap() {
    if (!_hasFeedbackContent && !_hasScore) return;
    unawaited(_onFeedbackTapAsync());
  }

  Future<void> _onFeedbackTapAsync() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    final allowed = await ensureSubscribedForSpeechFeedback(context);
    if (!mounted || !allowed) return;
    setState(() => _expanded = true);
  }

  Widget _buildExpandedFeedbackText(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final feedbackText = widget.feedback?.feedback?.trim();
    if (!_expanded || feedbackText == null || feedbackText.isEmpty) {
      return const SizedBox(width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        feedbackText,
        style: theme.bodySmall?.copyWith(
          color: _feedbackTextColor,
        ),
      ),
    );
  }

  Widget _buildExpandedScorePanel(BuildContext context) {
    final gradeStyle =
        _ViewChatGradeStyle.resolve(widget.feedback?.grade);
    if (!_expanded || widget.feedback?.score == null) {
      return const SizedBox(width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: _ViewChatScorePanel(
        score: widget.feedback!.score,
        barColor: gradeStyle?.color ?? _ViewChatGradeStyle.gradeA,
      ),
    );
  }

  Widget _buildScoreSpeechDivider() {
    if (!_expanded || widget.feedback?.score == null) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: ColoredBox(
        color: Color(0xFFD9D9D9),
        child: SizedBox(width: double.infinity, height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final showScorePanel = _expanded && _hasScore;
    final showFeedbackButton = _hasFeedbackContent || _hasScore;
    final cardColor = widget.isActive ? const Color(0xFF80D7CF) : Colors.white;
    final speechColor =
        widget.isActive ? const Color(0xFF054544) : _exprTextPrimary;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cardColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AnimatedSize(
          duration: _expandDuration,
          curve: _expandCurve,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.feedback != null)
                  _ViewChatGradeBadge(grade: widget.feedback!.grade),
                AnimatedSize(
                  duration: _expandDuration,
                  curve: _expandCurve,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  child: _buildExpandedScorePanel(context),
                ),
                AnimatedSize(
                  duration: _expandDuration,
                  curve: _expandCurve,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  child: _buildScoreSpeechDivider(),
                ),
                if (!showScorePanel) const SizedBox(height: 8),
                Text(
                  _userSpeech,
                  style: theme.bodyLarge?.copyWith(
                    color: speechColor,
                  ),
                ),
                AnimatedSize(
                  duration: _expandDuration,
                  curve: _expandCurve,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  child: _buildExpandedFeedbackText(context),
                ),
                if (widget.audioInputEnabled || showFeedbackButton) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: widget.audioInputEnabled
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.end,
                    children: [
                      if (widget.audioInputEnabled)
                        GestureDetector(
                          onTap: widget.onAudioTap,
                          behavior: HitTestBehavior.opaque,
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _megaphoneSpinnerColor
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  widget.isPlaying
                                      ? _megaphoneFillPng
                                      : _megaphonePng,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                  color: _megaphoneTintActive,
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                        ),
                      if (showFeedbackButton)
                        _ViewChatFeedbackButton(
                          onTap: _onFeedbackTap,
                          expanded: _expanded,
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

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _onFeedbackTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }
}

class _ViewChatGradeStyle {
  static const Color gradeA = Color(0xFF0CABA8);
  static const Color gradeB = Color(0xFF009628);
  static const Color gradeC = Color(0xFFFFB700);
  static const Color gradeD = Color(0xFFB40000);

  static ({String label, Color color})? resolve(String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A':
        return (label: 'PERFECT', color: gradeA);
      case 'B':
        return (label: 'GOOD', color: gradeB);
      case 'C':
        return (label: 'NEEDS IMPROVEMENT', color: gradeC);
      case 'D':
        return (label: 'UNCLEAR', color: gradeD);
      default:
        return null;
    }
  }
}

class _ViewChatGradeBadge extends StatelessWidget {
  const _ViewChatGradeBadge({required this.grade});

  final String? grade;

  @override
  Widget build(BuildContext context) {
    final resolved = _ViewChatGradeStyle.resolve(grade);
    if (resolved == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    return Text(
      resolved.label,
      textAlign: TextAlign.start,
      style: theme.bodySmall?.copyWith(
        color: resolved.color,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _ViewChatScoreBarTrack extends StatelessWidget {
  const _ViewChatScoreBarTrack({
    required this.scoreValue,
    required this.barColor,
  });

  final String? scoreValue;
  final Color barColor;

  static const Color _trackColor = Color(0xFFD9D9D9);

  static double _progressFactor(String? value) {
    switch (value?.toUpperCase()) {
      case 'GOOD':
        return 1.0;
      case 'FAIR':
        return 0.6;
      case 'POOR':
        return 0.2;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressFactor(scoreValue).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(1.5),
      child: SizedBox(
        height: 3,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _trackColor),
            if (progress > 0)
              FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: ColoredBox(
                  color: barColor,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewChatScorePanel extends StatelessWidget {
  const _ViewChatScorePanel({
    required this.score,
    required this.barColor,
  });

  final RpS2ScoreVo? score;
  final Color barColor;

  static const Color _labelColor = Color(0xFF777373);
  static const double _labelBarGap = 4;
  static const double _rowGap = 8;
  static const double _rowHeight = 14;
  static const double _columnGap = 24;

  static double _labelColumnWidth(
    BuildContext context,
    List<String> labels,
    TextStyle labelStyle,
  ) {
    var maxWidth = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      maxWidth = math.max(maxWidth, painter.width);
    }
    return maxWidth.ceilToDouble();
  }

  Widget _buildScoreRow({
    required String label,
    required String? value,
    required TextStyle labelStyle,
    required double labelWidth,
  }) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: labelStyle),
            ),
          ),
          const SizedBox(width: _labelBarGap),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ViewChatScoreBarTrack(
                scoreValue: value,
                barColor: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn({
    required List<({String label, String? value})> rows,
    required TextStyle labelStyle,
    required double labelWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: _rowGap),
          _buildScoreRow(
            label: rows[i].label,
            value: rows[i].value,
            labelStyle: labelStyle,
            labelWidth: labelWidth,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    final labelStyle = theme.labelSmall?.copyWith(color: _labelColor);
    final resolvedLabelStyle = labelStyle ?? const TextStyle(fontSize: 12);
    final l10n = AppLocalizations.of(context)!;
    final leftRows = <({String label, String? value})>[
      (label: l10n.roleplayResultScoreMeaning, value: score!.meaning),
      (label: l10n.roleplayResultScoreVocabulary, value: score!.vocabulary),
    ];
    final rightRows = <({String label, String? value})>[
      (label: l10n.roleplayResultScoreRelevance, value: score!.relevance),
      (label: l10n.roleplayResultScoreGrammar, value: score!.grammar),
    ];
    final allLabels = [
      ...leftRows.map((row) => row.label),
      ...rightRows.map((row) => row.label),
    ];
    final labelWidth = _labelColumnWidth(
      context,
      allLabels,
      resolvedLabelStyle,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildScoreColumn(
            rows: leftRows,
            labelStyle: resolvedLabelStyle,
            labelWidth: labelWidth,
          ),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          child: _buildScoreColumn(
            rows: rightRows,
            labelStyle: resolvedLabelStyle,
            labelWidth: labelWidth,
          ),
        ),
      ],
    );
  }
}

class _ViewChatFeedbackButton extends StatelessWidget {
  const _ViewChatFeedbackButton({
    required this.onTap,
    required this.expanded,
  });

  final VoidCallback onTap;
  final bool expanded;

  static const String _clickToFoldPng =
      'assets/images/icons/click_to_fold.png';
  static const Color _teal = Color(0xFF0CABA8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: _teal, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Feedback',
              style: theme.labelSmall?.copyWith(color: _teal),
            ),
            const SizedBox(width: 4),
            Transform.flip(
              flipY: !expanded,
              child: Image.asset(
                _clickToFoldPng,
                width: 12,
                height: 12,
                fit: BoxFit.contain,
                color: _teal,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
