import 'dart:async' show StreamSubscription, unawaited;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../config/app_config.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/english_level_util.dart';

/// S2 Playing — **단계 1(AI 시작 말풍선·음성·번역)** 및 힌트 트리거 훅.
/// 나레이션·사용자 턴·후속 AI는 `.docs/CONTEXT_ROLEPLAY_S2.md` §「S2 Playing 턴 엔진」참조.
class PlayingConversationLayout {
  PlayingConversationLayout._();

  /// 본문 스크롤 영역 상단부터 첫 말풍선까지 고정 여백 (미션 패널에 가리지 않도록).
  static const double firstBubbleTopOffset = 72;
}

enum PlayingConversationEntryType { ai, user, narration }

class PlayingConversationEntry {
  final GlobalKey key = GlobalKey();
  final PlayingConversationEntryType type;
  final String text;
  int? conversationIndex;
  bool isVisible = false;
  String? translationText;
  bool isTranslationExpanded = false;
  bool isTranslationLoading = false;

  PlayingConversationEntry._({required this.type, required this.text});

  factory PlayingConversationEntry.ai({required String text}) {
    return PlayingConversationEntry._(
      type: PlayingConversationEntryType.ai,
      text: text,
    );
  }

  factory PlayingConversationEntry.user({required String text}) {
    return PlayingConversationEntry._(
      type: PlayingConversationEntryType.user,
      text: text,
    );
  }

  factory PlayingConversationEntry.narration({required String text}) {
    return PlayingConversationEntry._(
      type: PlayingConversationEntryType.narration,
      text: text,
    );
  }

  bool get isAi => type == PlayingConversationEntryType.ai;
}

mixin PlayingConversationMixin<T extends StatefulWidget> on State<T> {
  final List<PlayingConversationEntry> _conversationEntries = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _nextConversationIndex = 0;
  bool _hasStartedAiOpening = false;
  StreamSubscription<PlayerState>? _aiPlaybackSub;

  /// AI 음성 재생 완료 시 힌트 트리거.
  VoidCallback? playingAiVoicePlaybackCompletedHandler;

  /// AI 말풍선 직전 힌트 영역 정리.
  VoidCallback? playingHintPrepareForAiMessageHandler;

  /// AI 말풍선 직전 힌트 아이콘 리셋.
  VoidCallback? playingHintResetIconForAiStartHandler;

  /// AI 시작 시 사용자 입력 비활성.
  VoidCallback? deactivateUserTurnHandler;

  AudioPlayer get playingAudioPlayer => _audioPlayer;

  List<PlayingConversationEntry> get conversationEntries =>
      _conversationEntries;

  int? get lastAiConversationIndex {
    for (final entry in _conversationEntries.reversed) {
      if (entry.isAi) return entry.conversationIndex;
    }
    return null;
  }

  void disposePlayingConversation() {
    _aiPlaybackSub?.cancel();
    _aiPlaybackSub = null;
    _audioPlayer.dispose();
  }

  void startAiOpeningFlow() {
    if (_hasStartedAiOpening) return;
    _hasStartedAiOpening = true;
    unawaited(_handleAiStart());
  }

  String? _resolveStartLine() {
    final episode = SeriesStateService.instance.selectedEpisode;
    final user = SeriesStateService.instance.user;
    if (episode == null) return null;
    final cefrCode = EnglishLevelUtil.readLevelFromUser(user);
    return episode.cefrMap[cefrCode]?.startLine;
  }

  String? _resolveAiAvatarUrl() {
    final path =
        SeriesStateService.instance.selectedEpisode?.aiCharacter?.rpImgPath;
    if (path == null || path.isEmpty) return null;
    return '${AppConfig.cdnBaseUrl}$path';
  }

  Future<void> _handleAiStart() async {
    deactivateUserTurnHandler?.call();
    final starterText = _resolveStartLine();
    if (starterText == null || starterText.isEmpty) return;
    final aiSound = SeriesStateService.instance.session?.aiSound;
    await showPlayingAiMessage(
      text: starterText,
      cdnYn: aiSound?.cdnYn,
      cdnPath: aiSound?.cdnPath,
      soundBytes: aiSound?.file,
    );
  }

  Future<void> showPlayingAiMessage({
    required String text,
    String? cdnYn,
    String? cdnPath,
    Uint8List? soundBytes,
  }) async {
    playingHintPrepareForAiMessageHandler?.call();
    playingHintResetIconForAiStartHandler?.call();
    final entry = PlayingConversationEntry.ai(text: text);
    final audioSource = await _prepareAiVoice(
      cdnYn: cdnYn,
      cdnPath: cdnPath,
      soundBytes: soundBytes,
    );
    if (!mounted) return;
    await _addEntry(entry, revealImmediately: true);
    if (audioSource != null) {
      unawaited(_playPreparedAiVoice(audioSource, notifyOnComplete: true));
    } else {
      _notifyAiVoicePlaybackCompleted();
    }
  }

  Future<void> showPlayingUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    final entry = PlayingConversationEntry.user(text: text.trim());
    await _addEntry(entry);
  }

  Future<void> showPlayingNarration(String text) async {
    if (text.trim().isEmpty) return;
    final entry = PlayingConversationEntry.narration(text: text.trim());
    await _addEntry(entry);
  }

  Future<AudioSource?> preparePlayingVoice({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) {
    return _prepareAiVoice(
      cdnYn: cdnYn,
      cdnPath: cdnPath,
      soundBytes: soundBytes,
    );
  }

  Future<void> playPreparedPlayingVoice(AudioSource source) {
    return _playPreparedAiVoice(source, notifyOnComplete: true);
  }

  /// 힌트 megaphone·단어 재생 — AI 음성 완료 콜백(힌트 재노출)을 붙이지 않음.
  Future<void> playPreparedHintVoice(AudioSource source) {
    return _playPreparedAiVoice(source, notifyOnComplete: false);
  }

  void _notifyAiVoicePlaybackCompleted() {
    playingAiVoicePlaybackCompletedHandler?.call();
  }

  Future<AudioSource?> _prepareAiVoice({
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
    debugPrint(
      '[DEBUG] RpS2 AI voice source empty: cdnYn=$cdnYn cdnPath=$cdnPath bytes=${soundBytes?.length ?? 0}',
    );
    return null;
  }

  Future<void> _playPreparedAiVoice(
    AudioSource source, {
    required bool notifyOnComplete,
  }) async {
    _aiPlaybackSub?.cancel();
    _aiPlaybackSub = null;
    await _audioPlayer.play();
    if (!notifyOnComplete) return;
    _aiPlaybackSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _aiPlaybackSub?.cancel();
        _aiPlaybackSub = null;
        _notifyAiVoicePlaybackCompleted();
      }
    });
  }

  Future<void> _addEntry(
    PlayingConversationEntry entry, {
    bool revealImmediately = false,
  }) async {
    if (entry.isAi) {
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
      if (!revealImmediately) {
        setState(() => entry.isVisible = true);
      }
    });
  }

  Future<void> _toggleTranslation(PlayingConversationEntry entry) async {
    if (!entry.isAi) return;
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
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null) {
      if (!mounted) return;
      setState(() {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
      });
      return;
    }
    try {
      final translated = await SudaApiClient.getRpS2Translation(
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
      if (!mounted) return;
      setState(() {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
      });
    }
  }

  List<Widget> buildConversationEntryWidgets(double bodyWidth) {
    return [
      for (final entry in _conversationEntries)
        KeyedSubtree(
          key: entry.key,
          child: switch (entry.type) {
            PlayingConversationEntryType.ai => _buildAiMessage(
              bodyWidth,
              entry,
            ),
            PlayingConversationEntryType.user => _buildUserMessage(
              bodyWidth,
              entry,
            ),
            PlayingConversationEntryType.narration => _buildNarration(entry),
          },
        ),
    ];
  }

  Widget _buildNarration(PlayingConversationEntry entry) {
    if (entry.text.isEmpty) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontStyle: FontStyle.italic,
    );
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: _NarrationRevealText(text: entry.text, style: style),
      ),
    );
  }

  Widget _buildUserMessage(double bodyWidth, PlayingConversationEntry entry) {
    if (entry.text.isEmpty) return const SizedBox.shrink();
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
            child: Text(entry.text, style: textStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildAiMessage(double bodyWidth, PlayingConversationEntry entry) {
    if (entry.text.isEmpty) {
      return const SizedBox.shrink();
    }
    const aiTranslationIconSize = 24.0;
    const gapBeforeAiTranslationIcon = 5.0;
    const aiAvatarRowWidth = 40.0;
    const gapAvatarToBubble = 5.0;
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
                        entry.text,
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
                          const Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
              onTap: () => unawaited(_toggleTranslation(entry)),
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
    final url = _resolveAiAvatarUrl();
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
}

class _NarrationRevealText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _NarrationRevealText({required this.text, this.style});

  @override
  State<_NarrationRevealText> createState() => _NarrationRevealTextState();
}

class _NarrationRevealTextState extends State<_NarrationRevealText> {
  static const Duration _lineDuration = Duration(milliseconds: 260);
  int _visibleLineCount = 0;
  List<String> _lines = const [];
  List<double> _lineHeights = const [];

  @override
  void didUpdateWidget(covariant _NarrationRevealText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _visibleLineCount = 0;
      _lines = const [];
      _lineHeights = const [];
    }
  }

  void _computeLines(double maxWidth, TextDirection textDirection) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) {
      _lines = [widget.text];
      _lineHeights = [painter.height];
    } else {
      final rawLines = widget.text.split('\n');
      if (rawLines.length == metrics.length) {
        _lines = rawLines;
      } else {
        _lines = _splitTextIntoVisualLines(
          widget.text,
          maxWidth,
          textDirection,
        );
      }
      _lineHeights = metrics.map((metric) => metric.height).toList();
    }
    _scheduleReveal();
  }

  List<String> _splitTextIntoVisualLines(
    String text,
    double maxWidth,
    TextDirection textDirection,
  ) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      final painter = TextPainter(
        text: TextSpan(text: candidate, style: widget.style),
        textDirection: textDirection,
      )..layout(maxWidth: maxWidth);
      if (painter.computeLineMetrics().length > 1 && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines.isEmpty ? [text] : lines;
  }

  void _scheduleReveal() {
    if (_visibleLineCount > 0 || _lines.isEmpty) return;
    for (var i = 0; i < _lines.length; i++) {
      Future<void>.delayed(_lineDuration * i, () {
        if (!mounted) return;
        setState(() {
          _visibleLineCount = math.min(i + 1, _lines.length);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        if (_lines.isEmpty) {
          _computeLines(constraints.maxWidth, textDirection);
        }
        final visibleLines = _lines.take(_visibleLineCount).toList();
        return AnimatedSize(
          duration: _lineDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < visibleLines.length; i++)
                ClipRect(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>('${widget.text}-$i'),
                    tween: Tween(begin: 0, end: 1),
                    duration: _lineDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Align(
                        alignment: Alignment.topCenter,
                        heightFactor: value,
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: SizedBox(
                      height: i < _lineHeights.length ? _lineHeights[i] : null,
                      child: Text(
                        visibleLines[i],
                        textAlign: TextAlign.center,
                        style: widget.style,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
