import 'dart:async' show StreamSubscription, unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../l10n/app_localizations.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/language_util.dart';
import 'playing_conversation_mixin.dart';

class PlayingHintEntry {
  final GlobalKey key = GlobalKey();
  bool isVisible = false;
  bool isLoading = false;
  String? hintText;
  String? translatedHint;
  bool showAnswerBody = false;
  bool hintSentenceHighlightActive = false;
  int? hintWordHighlightIndex;
  final Map<String, TtsResultDto> hintAudioCache = {};
}

/// S2 Playing 힌트 영역·API·음성 재생 (S1 `playing_backup` 힌트 박스 기반).
mixin PlayingHintMixin<T extends StatefulWidget>
    on State<T>, PlayingConversationMixin<T> {
  static const Color _hintBubbleBg = Color(0xFF194847);
  static const Color _hintPlaybackTeal = Color(0xFF0CABA8);
  static const Color _hintAccent = Color(0xFF80D7CF);
  static const double _hintGuideIconSize = 14;

  /// 로딩 중 본문 최소 높이 — 번역 1줄 + 답변보기 버튼 + 상하 마진 합산.
  static const double _hintLoadingBodyMinHeight = 98;
  static const double _hintWordUnderlineGap = 2;

  PlayingHintEntry? _hintEntry;
  bool _isFetchingHint = false;
  StreamSubscription<PlayerState>? _hintPlaybackSub;
  void Function({GlobalKey? anchorKey})? scrollPlayingHintToBottomHandler;

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
    if (_isFetchingHint || !mounted) return;
    final rpMsgId = _resolveLastAiRpMsgId();
    if (rpMsgId == null) return;

    // 동일 턴 힌트가 이미 로드됐으면 상태(showAnswerBody 등) 유지.
    final existing = _hintEntry;
    if (existing != null &&
        !existing.isLoading &&
        (existing.hintText?.isNotEmpty ?? false)) {
      return;
    }

    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) return;

    _isFetchingHint = true;
    final entry = PlayingHintEntry()
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
      setState(() {
        entry.isLoading = false;
        entry.hintText = hint;
        entry.translatedHint = translated.isEmpty ? null : translated;
        entry.showAnswerBody = isEnglishUser || translated.isEmpty;
        entry.isVisible = true;
      });
      _scrollHintToVisible(entry);
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

  void _revealHintAnswerBody(PlayingHintEntry entry) {
    setState(() => entry.showAnswerBody = true);
    _scrollHintToVisible(entry);
  }

  Widget? buildHintBubble(double bodyWidth) {
    final entry = _hintEntry;
    if (entry == null) return null;
    if (entry.isLoading) {
      return _buildHintBubbleLoading(bodyWidth, entry);
    }
    final text = entry.hintText ?? '';
    if (text.isEmpty) return null;
    return _buildHintBubble(bodyWidth, entry, text);
  }

  Widget _buildHintGuideBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle =
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{})
            ?.copyWith(color: _hintAccent) ??
        theme.textTheme.bodyMedium?.copyWith(color: _hintAccent);

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(_hintAccent, BlendMode.srcIn),
            child: Image.asset(
              'assets/images/icons/lightball.png',
              height: _hintGuideIconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.roleplayHintLabel,
            style: labelStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHintTranslatedSection(PlayingHintEntry entry) {
    final translated = entry.translatedHint;
    if (translated == null || translated.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Text(
        translated,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _hintAccent),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHintShowAnswerButton(double bodyWidth, PlayingHintEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textStyle =
        theme.elevatedButtonTheme.style?.textStyle
            ?.resolve(const <WidgetState>{})
            ?.copyWith(color: const Color(0xFF1B3B3B)) ??
        theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF1B3B3B));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Center(
        child: SizedBox(
          width: bodyWidth * 0.8,
          child: Material(
            color: const Color(0xFF076766),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => _revealHintAnswerBody(entry),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Text(
                  l10n.roleplayHintShowAnswer,
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintAnswerBody(PlayingHintEntry entry, String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final theme = Theme.of(context).textTheme;
    final headline = theme.headlineSmall ?? theme.bodyLarge;

    return Padding(
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
                child: Image.asset(
                  _isHintMegaphonePlaying(entry)
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
  }

  Widget _buildHintBubble(
    double bodyWidth,
    PlayingHintEntry entry,
    String text,
  ) {
    final isEnglishUser = LanguageUtil.getCurrentLanguageCode() == 'en';
    final hasTranslated = entry.translatedHint?.isNotEmpty ?? false;
    final showTranslated = !isEnglishUser && hasTranslated;
    final showButton = !isEnglishUser && !entry.showAnswerBody && hasTranslated;

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
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHintGuideBar(context),
                  if (showTranslated) _buildHintTranslatedSection(entry),
                  if (showButton) _buildHintShowAnswerButton(bodyWidth, entry),
                  if (entry.showAnswerBody) _buildHintAnswerBody(entry, text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBubbleLoading(double bodyWidth, PlayingHintEntry entry) {
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
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHintGuideBar(context),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _hintLoadingBodyMinHeight,
                    ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isHintMegaphonePlaying(PlayingHintEntry entry) {
    return entry.hintSentenceHighlightActive ||
        entry.hintWordHighlightIndex != null;
  }

  Color _hintWordTextColor(PlayingHintEntry entry, int wordIndex) {
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
    required PlayingHintEntry entry,
    required int wordIndex,
    required String word,
    required TextStyle? headline,
  }) {
    final wordStyle = headline?.copyWith(
      color: _hintWordTextColor(entry, wordIndex),
      height: 1.35,
      fontStyle: FontStyle.italic,
    );
    final underlineWidth = _measureHintWordWidth(word, wordStyle);
    return GestureDetector(
      onTap: () => unawaited(_onHintWordTap(entry, wordIndex)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(word, style: wordStyle),
          const SizedBox(height: _hintWordUnderlineGap),
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
    await playingAudioPlayer.stop();

    late TtsResultDto dto;
    try {
      if (entry.hintAudioCache.containsKey(cacheKey)) {
        dto = entry.hintAudioCache[cacheKey]!;
      } else {
        dto = await fetch();
        entry.hintAudioCache[cacheKey] = dto;
      }
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
