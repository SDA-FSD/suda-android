import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../api/suda_api_client.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/common_models.dart';
import '../../models/roleplay_models.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../widgets/app_scaffold.dart';

/// Chat history entry keys (server chatHistory item key).
const String _kChatKeyUser = 'USER';
const String _kChatKeyAiCharacter = 'AI_CHARACTER';
const String _kChatKeyAiNarrator = 'AI_NARRATOR';
const String _kChatKeySystemMission = 'SYSTEM_MISSION';

/// Review Chat Screen (Sub Screen)
///
/// History Screen에서 진입. RoleplayResultDto(채팅 이력·아바타 경로)로 채팅 내용 열람.
/// USER 음성: API가 S3에서 로드해 byte[] 전달. AI 음성: 저장된 CDN 경로 재생.
class ReviewChatScreen extends StatefulWidget {
  final RoleplayResultDto result;

  const ReviewChatScreen({
    super.key,
    required this.result,
  });

  @override
  State<ReviewChatScreen> createState() => _ReviewChatScreenState();
}

class _ReviewChatScreenState extends State<ReviewChatScreen> {
  static const Color _gradientTop = Color(0xFF054544);
  static const Color _gradientBottom = Color(0xFF0CABA8);
  static const Color _overlayBlack40 = Color(0x66000000);
  static const Color _bubblePlayingBg = Color(0xFF80D7CF);
  static const Color _bubblePlayingText = Color(0xFF054544);
  static const Color _aiBubbleIdleBg = Color(0xFF0CABA8);
  static const Color _hintTeal = Color(0xFF80D7CF);
  static const String _speakerIcon = 'assets/images/icons/speaker.png';
  static const double _bubblePaddingH = 12;
  static const double _bubblePaddingV = 10;
  static const double _bubbleRadiusMultiLine = 20;

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _audioSub;
  int _playSeq = 0;

  Map<int, RpReviewChatLineDto> _audioMetaByLine = {};
  bool _metaLoaded = false;
  int? _playingLineIndex;
  int? _loadingLineIndex;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAudioMeta());
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  bool _canPlayLine(int lineIndex, SudaJson item) {
    if (!_metaLoaded) return false;
    final meta = _audioMetaByLine[lineIndex];
    if (meta == null) return false;
    if (item.key == _kChatKeyUser && meta.hasUserAudio) return true;
    if (item.key == _kChatKeyAiCharacter && meta.hasAiCdn) return true;
    return false;
  }

  bool _isLineActive(int lineIndex) =>
      _playingLineIndex == lineIndex || _loadingLineIndex == lineIndex;

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
    )..layout();
    return painter.width <= maxTextWidth + 0.5;
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
      _playingLineIndex = null;
      _loadingLineIndex = null;
    });
  }

  Future<void> _loadAudioMeta() async {
    final resultId = widget.result.id;
    if (resultId == null) {
      if (mounted) setState(() => _metaLoaded = true);
      return;
    }
    final token = await TokenStorage.loadAccessToken();
    if (token == null || !mounted) {
      setState(() => _metaLoaded = true);
      return;
    }
    try {
      final meta = await SudaApiClient.getRoleplayReviewChatAudioMeta(
        accessToken: token,
        resultId: resultId,
      );
      if (!mounted) return;
      final map = <int, RpReviewChatLineDto>{};
      for (final line in meta.lines) {
        map[line.lineIndex] = line;
      }
      setState(() {
        _audioMetaByLine = map;
        _metaLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _metaLoaded = true);
    }
  }

  Future<AudioSource?> _prepareAudio({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
    required bool isWav,
  }) async {
    await _audioPlayer.stop();
    if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
      final url = '${AppConfig.cdnBaseUrl}$cdnPath';
      final source = AudioSource.uri(Uri.parse(url));
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    if (soundBytes != null && soundBytes.isNotEmpty) {
      final mime = isWav ? 'audio/wav' : 'audio/mpeg';
      final source = AudioSource.uri(
        Uri.dataFromBytes(soundBytes, mimeType: mime),
      );
      await _audioPlayer.setAudioSource(source);
      return source;
    }
    return null;
  }

  Future<void> _onBubbleTap(int lineIndex, SudaJson item) async {
    if (_canPlayLine(lineIndex, item)) {
      if (_playingLineIndex == lineIndex && _loadingLineIndex == null) {
        await _stopPlayback();
        return;
      }
      if (_loadingLineIndex == lineIndex) return;
      await _onPlayTap(lineIndex, item);
      return;
    }
    if (item.key == _kChatKeyUser || item.key == _kChatKeyAiCharacter) {
      _showNoAudioToast();
    }
  }

  Future<void> _onPlayTap(int lineIndex, SudaJson item) async {
    final meta = _audioMetaByLine[lineIndex];
    if (meta == null) return;

    final canUser = item.key == _kChatKeyUser && meta.hasUserAudio;
    final canAi = item.key == _kChatKeyAiCharacter && meta.hasAiCdn;
    if (!canUser && !canAi) return;

    _playSeq++;
    final seq = _playSeq;
    _audioSub?.cancel();
    _audioSub = null;
    await _audioPlayer.stop();

    if (!mounted) return;
    setState(() {
      _playingLineIndex = lineIndex;
      _loadingLineIndex = lineIndex;
    });

    try {
      AudioSource? source;
      if (canAi) {
        source = await _prepareAudio(
          cdnYn: meta.aiCdnYn,
          cdnPath: meta.aiCdnPath,
          soundBytes: null,
          isWav: false,
        );
      } else {
        final resultId = widget.result.id;
        final token = await TokenStorage.loadAccessToken();
        if (seq != _playSeq || !mounted) return;
        if (resultId == null || token == null) {
          setState(() {
            _loadingLineIndex = null;
            _playingLineIndex = null;
          });
          _showNoAudioToast();
          return;
        }
        final tts = await SudaApiClient.getRoleplayReviewChatUserSound(
          accessToken: token,
          resultId: resultId,
          lineIndex: lineIndex,
        );
        if (seq != _playSeq || !mounted) return;
        source = await _prepareAudio(
          cdnYn: tts.cdnYn,
          cdnPath: tts.cdnPath,
          soundBytes: tts.sound,
          isWav: true,
        );
      }

      if (seq != _playSeq || !mounted) return;
      setState(() => _loadingLineIndex = null);

      if (source == null) {
        setState(() => _playingLineIndex = null);
        _showNoAudioToast();
        return;
      }

      _audioSub = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioSub?.cancel();
          _audioSub = null;
          if (!mounted || seq != _playSeq) return;
          setState(() => _playingLineIndex = null);
        }
      });
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted || seq != _playSeq) return;
      setState(() {
        _loadingLineIndex = null;
        _playingLineIndex = null;
      });
      _showNoAudioToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Transform.translate(
                offset: const Offset(0, -14),
                child: _buildAudioHint(context, l10n),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bodyWidth = constraints.maxWidth;
                    final history = widget.result.chatHistory ?? [];
                    if (history.isEmpty) {
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < history.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _buildEntry(context, bodyWidth, i, history[i]),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioHint(BuildContext context, AppLocalizations l10n) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _hintTeal,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            _speakerIcon,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            color: _hintTeal,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.reviewChatTapHint,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context,
    double bodyWidth,
    int lineIndex,
    SudaJson item,
  ) {
    final value = item.value;
    if (value.isEmpty) return const SizedBox.shrink();

    switch (item.key) {
      case _kChatKeyUser:
        return _buildUserBubble(context, bodyWidth, lineIndex, item, value);
      case _kChatKeyAiCharacter:
        return _buildAiBubble(context, bodyWidth, lineIndex, item, value);
      case _kChatKeyAiNarrator:
        return _buildNarrationBubble(context, value, isMission: false);
      case _kChatKeySystemMission:
        return _buildNarrationBubble(context, value, isMission: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserBubble(
    BuildContext context,
    double bodyWidth,
    int lineIndex,
    SudaJson item,
    String text,
  ) {
    final isActive = _isLineActive(lineIndex);
    final isLoading = _loadingLineIndex == lineIndex;
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isActive ? _bubblePlayingText : Colors.black,
        );
    final maxBubbleWidth = bodyWidth * 0.7;
    final maxTextWidth = maxBubbleWidth -
        _bubblePaddingH * 2 -
        (isLoading ? 24 : 0);
    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: _bubblePaddingH,
        vertical: _bubblePaddingV,
      ),
      decoration: BoxDecoration(
        color: isActive ? _bubblePlayingBg : Colors.white,
        borderRadius: _bubbleBorderRadius(
          context: context,
          text: text,
          textStyle: textStyle,
          maxTextWidth: maxTextWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, style: textStyle)),
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
          ],
        ],
      ),
    );

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: GestureDetector(
          onTap: () => _onBubbleTap(lineIndex, item),
          behavior: HitTestBehavior.opaque,
          child: bubble,
        ),
      ),
    );
  }

  Widget _buildAiBubble(
    BuildContext context,
    double bodyWidth,
    int lineIndex,
    SudaJson item,
    String text,
  ) {
    final isActive = _isLineActive(lineIndex);
    final isLoading = _loadingLineIndex == lineIndex;
    final bubbleWidth = bodyWidth * 0.7;
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isActive ? _bubblePlayingText : Colors.white,
        );
    final maxTextWidth = bubbleWidth -
        40 -
        5 -
        _bubblePaddingH * 2 -
        (isLoading ? 24 : 0);
    final bubble = AnimatedContainer(
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
          ],
        ],
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: bubbleWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 5),
            Expanded(
              child: GestureDetector(
                onTap: () => _onBubbleTap(lineIndex, item),
                behavior: HitTestBehavior.opaque,
                child: bubble,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final path = widget.result.avatarImgPath;
    if (path == null || path.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
      );
    }
    final url = '${AppConfig.cdnBaseUrl}$path';
    return ClipOval(
      child: Image(
        image: CachedNetworkImageProvider(url),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
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
