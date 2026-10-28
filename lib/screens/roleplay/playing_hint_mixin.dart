import 'dart:async' show StreamSubscription, unawaited;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../api/endpoints/series_api.dart';
import '../../l10n/app_localizations.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/language_util.dart';
import '../../widgets/roleplay_overview_backdrop.dart';
import 'playing_conversation_mixin.dart';

class PlayingHintEntry {
  final GlobalKey key = GlobalKey();
  int? rpMsgId;
  bool isVisible = false;
  bool isLoading = false;
  String? hintText;
  String? translatedHint;
  bool showAnswerBody = false;
  bool englishHintDeliveredPutSent = false;
  bool hintSentenceHighlightActive = false;
  int? hintWordHighlightIndex;
  final Map<String, TtsResultDto> hintAudioCache = {};
}

/// S2 Playing 힌트 영역·API·음성 재생 (S1 `playing_backup` 힌트 박스 기반).
mixin PlayingHintMixin<T extends StatefulWidget>
    on State<T>, PlayingConversationMixin<T> {
  PlayingHintEntry? _hintEntry;
  bool _isFetchingHint = false;
  StreamSubscription<PlayerState>? _hintPlaybackSub;
  void Function({GlobalKey? anchorKey})? scrollPlayingHintToBottomHandler;
  Listenable? playingHintSceneryTick;
  VoidCallback? onPlayingHintClosedByUser;

  PlayingHintEntry? get activeHintEntry => _hintEntry;

  void disposePlayingHint() {
    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
  }

  void preparePlayingHintForAiMessage() {
    _resetHintPlaybackHighlight();
    dismissPlayingHint();
  }

  void dismissPlayingHint() {
    if (_hintEntry == null) return;
    setState(() => _hintEntry = null);
  }

  Future<void> showPlayingHint() async {
    if (!mounted) return;
    final existing = _hintEntry;
    if (existing != null &&
        (existing.isLoading || (existing.hintText?.isNotEmpty ?? false))) {
      if (!existing.isVisible) {
        setState(() => existing.isVisible = true);
        if (existing.showAnswerBody) {
          _acknowledgeHintEnglishDeliveredBestEffort(existing);
        }
        _scrollHintToVisible(existing);
      }
      return;
    }
    if (_isFetchingHint) return;
    final rpMsgId = _resolveLastAiRpMsgId();
    if (rpMsgId == null) return;

    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;

    _isFetchingHint = true;
    final entry = PlayingHintEntry()
      ..rpMsgId = rpMsgId
      ..isLoading = true
      ..isVisible = true;
    setState(() => _hintEntry = entry);
    _scrollHintToVisible(entry);

    try {
      final dto = await SudaApiClient.getRpS2Hint(
        accessToken: accessToken,
        rpSessionId: sessionId,
        rpMsgId: rpMsgId,
      );
      if (!mounted) return;
      final hint = dto.hint?.trim() ?? '';
      if (hint.isEmpty) {
        debugPrint('[DEBUG] RpS2 hint empty: rpMsgId=$rpMsgId');
        setState(() => _hintEntry = null);
        return;
      }
      final isEnglishUser = LanguageUtil.getCurrentLanguageCode() == 'en';
      final translated = dto.translatedHint?.trim() ?? '';
      final revealEnglishImmediately = isEnglishUser || translated.isEmpty;
      final stillOpen = entry.isVisible;
      setState(() {
        entry.isLoading = false;
        entry.hintText = hint;
        entry.translatedHint = translated.isEmpty ? null : translated;
        entry.showAnswerBody = revealEnglishImmediately;
        entry.isVisible = stillOpen;
      });
      if (revealEnglishImmediately && stillOpen) {
        _acknowledgeHintEnglishDeliveredBestEffort(entry);
      }
      if (stillOpen) _scrollHintToVisible(entry);
    } on RpS2SessionNotFoundException catch (_) {
      if (!mounted) return;
      setState(() => _hintEntry = null);
      playingSessionNotFoundHandler?.call();
    } catch (e) {
      debugPrint('[DEBUG] RpS2 hint API error: $e');
      if (!mounted) return;
      setState(() => _hintEntry = null);
    } finally {
      _isFetchingHint = false;
    }
  }

  int? _resolveLastAiRpMsgId() {
    final index = lastAiConversationIndex;
    if (index == null) return null;
    return index;
  }

  void _scrollHintToVisible(PlayingHintEntry entry) {
    if (!mounted) return;
    scrollPlayingHintToBottomHandler?.call(anchorKey: entry.key);
  }

  void _resetHintPlaybackHighlight() {
    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
    final entry = _hintEntry;
    if (entry == null) return;
    if (!entry.hintSentenceHighlightActive &&
        entry.hintWordHighlightIndex == null) {
      return;
    }
    setState(() {
      entry.hintSentenceHighlightActive = false;
      entry.hintWordHighlightIndex = null;
    });
  }

  void closePlayingHint() {
    final entry = _hintEntry;
    if (entry == null || !entry.isVisible) return;
    final stopAudio =
        entry.hintSentenceHighlightActive ||
        entry.hintWordHighlightIndex != null;
    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
    setState(() {
      entry.isVisible = false;
      entry.hintSentenceHighlightActive = false;
      entry.hintWordHighlightIndex = null;
    });
    if (stopAudio) unawaited(stopPlayingConversationAudio());
    onPlayingHintClosedByUser?.call();
  }

  void _revealHintAnswerBody(PlayingHintEntry entry) {
    _acknowledgeHintEnglishDeliveredBestEffort(entry);
    setState(() => entry.showAnswerBody = true);
    _scrollHintToVisible(entry);
  }

  void _acknowledgeHintEnglishDeliveredBestEffort(PlayingHintEntry entry) {
    if (entry.englishHintDeliveredPutSent) return;
    final rpMsgId = entry.rpMsgId;
    if (rpMsgId == null) return;
    entry.englishHintDeliveredPutSent = true;
    unawaited(_acknowledgeHintEnglishDeliveredAsync(rpMsgId));
  }

  Future<void> _acknowledgeHintEnglishDeliveredAsync(int rpMsgId) async {
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      final sessionId = SeriesStateService.instance.sessionId;
      if (accessToken == null || sessionId == null || sessionId.isEmpty) {
        return;
      }
      await SudaApiClient.markRpS2HintDelivered(
        accessToken: accessToken,
        rpSessionId: sessionId,
        rpMsgId: rpMsgId,
      );
    } catch (e) {
      debugPrint('[DEBUG] RpS2 hint delivered PUT ignored: $e');
    }
  }

  Widget? buildHintBubble(double bodyWidth) {
    final entry = _hintEntry;
    if (entry == null || !entry.isVisible) return null;
    final l10n = AppLocalizations.of(context)!;
    final text = entry.hintText ?? '';
    if (!entry.isLoading && text.isEmpty) return null;

    final isEnglishUser = LanguageUtil.getCurrentLanguageCode() == 'en';
    final native = entry.translatedHint;
    final hasNative = !isEnglishUser && native != null && native.isNotEmpty;
    final imagePath =
        SeriesStateService.instance.selectedEpisode?.thumbnailImgPath;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: bodyWidth),
        child: _PlayingHintCard(
          sceneryTick: playingHintSceneryTick,
          imagePath: imagePath,
          loading: entry.isLoading,
          label: l10n.roleplayHintLabel,
          nativeText: hasNative ? native : null,
          showRevealButton: hasNative && !entry.showAnswerBody,
          revealLabel: l10n.roleplayHintShowAnswer,
          showEnglish: !entry.isLoading && entry.showAnswerBody,
          englishLabel: l10n.roleplayHintEnglishLabel,
          english: text,
          sentencePlaying: entry.hintSentenceHighlightActive,
          wordPlayingIndex: entry.hintWordHighlightIndex,
          onClose: closePlayingHint,
          onReveal: () => _revealHintAnswerBody(entry),
          onSentence: () => unawaited(_onHintMegaphoneTap(entry)),
          onWord: (index) => unawaited(_onHintWordTap(entry, index)),
        ),
      ),
    );
  }

  Future<void> _onHintMegaphoneTap(PlayingHintEntry entry) async {
    if (entry.isLoading) return;
    setState(() {
      entry.hintSentenceHighlightActive = true;
      entry.hintWordHighlightIndex = null;
    });
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;
    await _playHintAudio(
      entry,
      'full',
      () => SudaApiClient.getRpS2HintSound(
        accessToken: accessToken,
        rpSessionId: sessionId,
      ),
    );
  }

  Future<void> _onHintWordTap(PlayingHintEntry entry, int wordIndex) async {
    if (entry.isLoading) return;
    setState(() {
      entry.hintSentenceHighlightActive = false;
      entry.hintWordHighlightIndex = wordIndex;
    });
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;
    await _playHintAudio(
      entry,
      'w$wordIndex',
      () => SudaApiClient.getRpS2HintWordSound(
        accessToken: accessToken,
        rpSessionId: sessionId,
        wordIndex: wordIndex,
      ),
    );
  }

  Future<void> _playHintAudio(
    PlayingHintEntry entry,
    String cacheKey,
    Future<TtsResultDto> Function() fetch,
  ) async {
    final sessionId = SeriesStateService.instance.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    _hintPlaybackSub?.cancel();
    _hintPlaybackSub = null;
    await stopPlayingConversationAudio();

    late TtsResultDto dto;
    try {
      if (entry.hintAudioCache.containsKey(cacheKey)) {
        dto = entry.hintAudioCache[cacheKey]!;
      } else {
        dto = await fetch();
        entry.hintAudioCache[cacheKey] = dto;
      }
    } on RpS2SessionNotFoundException catch (_) {
      if (mounted) {
        setState(() {
          entry.hintSentenceHighlightActive = false;
          entry.hintWordHighlightIndex = null;
        });
        playingSessionNotFoundHandler?.call();
      }
      return;
    } catch (e) {
      debugPrint('[DEBUG] RpS2 hint audio error: $e');
      if (mounted) {
        setState(() {
          entry.hintSentenceHighlightActive = false;
          entry.hintWordHighlightIndex = null;
        });
      }
      return;
    }
    if (!mounted) return;

    final source = await preparePlayingVoice(
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

    _hintPlaybackSub = playingAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _hintPlaybackSub?.cancel();
        _hintPlaybackSub = null;
        if (!mounted) return;
        // 재생 하이라이트만 해제 — 힌트 박스 내용(showAnswerBody·번역 등)은 유지.
        setState(() {
          entry.hintSentenceHighlightActive = false;
          entry.hintWordHighlightIndex = null;
        });
      }
    });
    await playPreparedHintVoice(source);
  }
}

/// 본편 힌트 상자. 온보딩 `_ClassicHintCard`와 같은 레이아웃.
class _PlayingHintCard extends StatelessWidget {
  static const _bg = Color(0xFF0CABA8);
  static const _accent = Color(0xFF80D7CF);
  static const _playback = Color(0xFF054544);
  static const _buttonFill = Color(0xFFEDEDED);
  static const _buttonText = Color(0xFF0CABA8);
  static const _blurSigma = 15.0;

  final Listenable? sceneryTick;
  final String? imagePath;
  final bool loading;
  final String label;
  final String? nativeText;
  final bool showRevealButton;
  final String revealLabel;
  final bool showEnglish;
  final String englishLabel;
  final String english;
  final bool sentencePlaying;
  final int? wordPlayingIndex;
  final VoidCallback onClose;
  final VoidCallback onReveal;
  final VoidCallback onSentence;
  final void Function(int index) onWord;

  const _PlayingHintCard({
    required this.sceneryTick,
    required this.imagePath,
    required this.loading,
    required this.label,
    required this.nativeText,
    required this.showRevealButton,
    required this.revealLabel,
    required this.showEnglish,
    required this.englishLabel,
    required this.english,
    required this.sentencePlaying,
    required this.wordPlayingIndex,
    required this.onClose,
    required this.onReveal,
    required this.onSentence,
    required this.onWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNative = nativeText != null && nativeText!.isNotEmpty;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(color: _accent);
    final nativeStyle = theme.textTheme.bodyLarge?.copyWith(
      color: Colors.white,
    );
    final englishLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: _accent,
    );
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
    final headline = theme.textTheme.headlineSmall ?? theme.textTheme.bodyLarge;
    final playing = sentencePlaying || wordPlayingIndex != null;
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
          child: Text(
            nativeText!,
            textAlign: TextAlign.start,
            style: nativeStyle,
          ),
        ),
      if (showRevealButton)
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
      if (loading)
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: Center(
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
                    _PlayingHintWord(
                      word: words[i],
                      headline: headline,
                      textColor: (sentencePlaying || wordPlayingIndex == i)
                          ? _playback
                          : Colors.white,
                      underlineColor: (sentencePlaying || wordPlayingIndex == i)
                          ? _playback
                          : Colors.white,
                      onTap: () => onWord(i),
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
            child: _PlayingHintFrostedScene(
              tick: sceneryTick,
              imagePath: imagePath,
            ),
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
                      showEnglish ? 12 : 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: top,
                    ),
                  ),
                ),
                if (showEnglish) ...[
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

class _PlayingHintFrostedScene extends StatefulWidget {
  final Listenable? tick;
  final String? imagePath;

  const _PlayingHintFrostedScene({required this.tick, required this.imagePath});

  @override
  State<_PlayingHintFrostedScene> createState() =>
      _PlayingHintFrostedSceneState();
}

class _PlayingHintFrostedSceneState extends State<_PlayingHintFrostedScene> {
  @override
  void initState() {
    super.initState();
    widget.tick?.addListener(_retick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _PlayingHintFrostedScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) {
      oldWidget.tick?.removeListener(_retick);
      widget.tick?.addListener(_retick);
    }
  }

  @override
  void dispose() {
    widget.tick?.removeListener(_retick);
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
    final path = widget.imagePath;
    final scenery = path != null && path.isNotEmpty
        ? RoleplayOverviewBackdrop(imagePath: path)
        : const ColoredBox(color: Color(0xFF121212));
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
                  sigmaX: _PlayingHintCard._blurSigma,
                  sigmaY: _PlayingHintCard._blurSigma,
                ),
                child: scenery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayingHintWord extends StatelessWidget {
  final String word;
  final TextStyle? headline;
  final Color textColor;
  final Color underlineColor;
  final VoidCallback onTap;

  const _PlayingHintWord({
    required this.word,
    required this.headline,
    required this.textColor,
    required this.underlineColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = headline?.copyWith(
      color: textColor,
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
              painter: _HintDottedUnderlinePainter(color: underlineColor),
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
      color != oldDelegate.color;
}
