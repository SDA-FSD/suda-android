import 'dart:async' show StreamSubscription, unawaited;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../api/endpoints/series_api.dart';
import '../../config/app_config.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/english_level_util.dart';
import 'ios_audio_teardown.dart';

/// S2 Playing — **단계 1(AI 시작 말풍선·음성·번역)** 및 힌트 트리거 훅.
/// 나레이션·사용자 턴·후속 AI는 `.docs/CONTEXT_ROLEPLAY_S2.md` §「S2 Playing 턴 엔진」참조.
class PlayingConversationLayout {
  PlayingConversationLayout._();

  /// 본문 Column 상단 gap (턴바 직하).
  static const double bodyTopGap = 8;

  /// 미션 패널 오버레이 top (본문 Stack 내, [bodyTopGap] 아래).
  static const double missionPanelTop = 2;

  /// 본문 스크롤 영역 상단부터 첫 말풍선까지 고정 여백 (미션 패널에 가리지 않도록).
  static const double firstBubbleTopOffset = 68;

  /// 미션 패널 하단까지 본문 상단 페이드 (`#121212` 100% → 0%).
  static const Color topContentFadeColor = Color(0xFF121212);

  /// `RoleplayScaffold` 본문·푸터 좌우 `Padding` — 상단 페이드 레이어는 이 inset을 상쇄해 디스플레이 전폭으로 확장.
  static const double scaffoldBodyHorizontalInset = 24;
}

enum PlayingConversationEntryType { ai, user, narration, recording }

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

  factory PlayingConversationEntry.recording() {
    return PlayingConversationEntry._(
      type: PlayingConversationEntryType.recording,
      text: '',
    );
  }

  bool get isAi => type == PlayingConversationEntryType.ai;

  /// `conversationIndex`(rpMsgId) 부여 대상 여부. recording·힌트는 제외(S1 `consumesIndex` 동일).
  bool get consumesConversationIndex =>
      type != PlayingConversationEntryType.recording;
}

mixin PlayingConversationMixin<T extends StatefulWidget> on State<T> {
  final List<PlayingConversationEntry> _conversationEntries = [];
  PlayingConversationEntry? _recordingEntry;
  AudioPlayer _audioPlayer = AudioPlayer();
  int _nextConversationIndex = 1;
  bool _hasStartedAiOpening = false;
  bool _iosPlayingAudioSessionReady = false;
  int _voiceSeq = 0;
  StreamSubscription<PlayerState>? _aiPlaybackSub;
  String? _iosAudioPath;

  /// AI 음성 재생 완료 시 힌트 트리거.
  VoidCallback? playingAiVoicePlaybackCompletedHandler;

  /// 세션 404 시 finish 분기 (`PlayingFinishMixin.onRpS2SessionNotFound`).
  VoidCallback? playingSessionNotFoundHandler;

  /// AI 말풍선 직전 힌트 영역 정리.
  VoidCallback? playingHintPrepareForAiMessageHandler;

  /// AI 말풍선 직전 힌트 아이콘 리셋.
  VoidCallback? playingHintResetIconForAiStartHandler;

  /// AI 시작 시 사용자 입력 비활성.
  VoidCallback? deactivateUserTurnHandler;
  void Function({GlobalKey? anchorKey})? scrollPlayingBodyToBottomHandler;
  void Function({required GlobalKey anchorKey})?
      scrollToRevealBubbleIfNeededHandler;

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
    _voiceSeq++;
    _aiPlaybackSub?.cancel();
    _aiPlaybackSub = null;
    final old = _audioPlayer;
    final path = _iosAudioPath;
    _iosAudioPath = null;
    if (Platform.isIOS) {
      IosAudioTeardown.enqueue(() async {
        try {
          await old.stop();
        } catch (_) {}
        try {
          await old.dispose();
        } catch (_) {}
        _deleteAudioFileAt(path);
      });
    } else {
      old.dispose();
      _deleteAudioFileAt(path);
    }
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
    scrollPlayingBodyToBottomHandler?.call(anchorKey: entry.key);
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

  void showPlayingRecordingEntry() {
    if (_recordingEntry != null) return;
    final entry = PlayingConversationEntry.recording();
    _recordingEntry = entry;
    unawaited(_addEntry(entry));
  }

  void removePlayingRecordingEntry() {
    final entry = _recordingEntry;
    if (entry == null) return;
    setState(() {
      _conversationEntries.remove(entry);
    });
    _recordingEntry = null;
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

  Future<void> stopPlayingConversationAudio() async {
    _voiceSeq++;
    _aiPlaybackSub?.cancel();
    _aiPlaybackSub = null;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// 녹음 탭 경로 — 재생 중이 아니면 stop을 await하지 않는다.
  Future<void> stopPlayingConversationAudioForRecording() async {
    if (!_audioPlayer.playing) {
      _voiceSeq++;
      _aiPlaybackSub?.cancel();
      _aiPlaybackSub = null;
      return;
    }
    try {
      await stopPlayingConversationAudio()
          .timeout(const Duration(milliseconds: 150));
    } catch (_) {}
  }

  void _deleteIosAudioFile() {
    final path = _iosAudioPath;
    _iosAudioPath = null;
    _deleteAudioFileAt(path);
  }

  static void _deleteAudioFileAt(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  static String _detectAudioExt(Uint8List bytes) {
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45) {
      return 'wav';
    }
    return 'mp3';
  }

  /// Playing iOS는 TTS·녹음 모두 `playAndRecord`를 유지한다.
  /// `playback`으로 되돌리면 탭 시 category 전환으로 초반 발화가 잘린다.
  Future<void> _activateIosPlaybackSession() async {
    if (_iosPlayingAudioSessionReady) return;
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
      _iosPlayingAudioSessionReady = true;
    } catch (e) {
      debugPrint('[DEBUG] RpS2 iOS audio session: $e');
    }
  }

  Future<void> _recreateAudioPlayerIos() async {
    _aiPlaybackSub?.cancel();
    _aiPlaybackSub = null;
    final old = _audioPlayer;
    _audioPlayer = AudioPlayer();
    IosAudioTeardown.enqueue(() async {
      try {
        await old.stop();
      } catch (_) {}
      try {
        await old.dispose();
      } catch (_) {}
    });
    await IosAudioTeardown.wait();
  }

  Future<Uint8List> _downloadCdnBytes(String url) async {
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw StateError(
        'cdn http ${resp.statusCode} bytes=${resp.bodyBytes.length}',
      );
    }
    return Uint8List.fromList(resp.bodyBytes);
  }

  Future<AudioSource> _loadIosFromBytes(Uint8List bytes) async {
    _deleteIosAudioFile();
    final ext = _detectAudioExt(bytes);
    final path =
        '${Directory.systemTemp.path}/suda_ai_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(path).writeAsBytes(bytes, flush: true);
    _iosAudioPath = path;
    final source = AudioSource.file(path);
    // iOS는 setAudioSource 직후 duration이 null/0인 경우가 많다. 0ms로 보고
    // 실패 처리하면 재생 없이 말풍선·힌트만 나간다.
    await _audioPlayer.setFilePath(path).timeout(const Duration(seconds: 8));
    return source;
  }

  Future<AudioSource?> _prepareAiVoice({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    if (Platform.isIOS) {
      return _prepareAiVoiceIos(
        cdnYn: cdnYn,
        cdnPath: cdnPath,
        soundBytes: soundBytes,
      );
    }
    return _prepareAiVoiceAndroid(
      cdnYn: cdnYn,
      cdnPath: cdnPath,
      soundBytes: soundBytes,
    );
  }

  Future<AudioSource?> _prepareAiVoiceAndroid({
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

  Future<AudioSource?> _prepareAiVoiceIos({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    _voiceSeq++;
    await IosAudioTeardown.wait();
    await _activateIosPlaybackSession();
    try {
      await _audioPlayer.stop().timeout(IosAudioTeardown.jobTimeout);
    } catch (_) {
      await _recreateAudioPlayerIos();
    }

    Future<AudioSource?> load() async {
      Uint8List? bytes =
          (soundBytes != null && soundBytes.isNotEmpty) ? soundBytes : null;
      if (bytes == null && cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
        final url = '${AppConfig.cdnBaseUrl}$cdnPath';
        bytes = await _downloadCdnBytes(url);
      }
      if (bytes == null || bytes.isEmpty) {
        debugPrint(
          '[DEBUG] RpS2 AI voice source empty: cdnYn=$cdnYn cdnPath=$cdnPath bytes=${soundBytes?.length ?? 0}',
        );
        return null;
      }
      return _loadIosFromBytes(bytes);
    }

    try {
      return await load();
    } catch (e) {
      debugPrint('[DEBUG] RpS2 iOS AI voice prepare error: $e');
      await _recreateAudioPlayerIos();
      await _activateIosPlaybackSession();
      try {
        if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
          final url = '${AppConfig.cdnBaseUrl}$cdnPath';
          final downloaded = await _downloadCdnBytes(url);
          return await _loadIosFromBytes(downloaded);
        }
        return await load();
      } catch (e2) {
        debugPrint('[DEBUG] RpS2 iOS AI voice prepare retry error: $e2');
        return null;
      }
    }
  }

  Future<void> _playPreparedAiVoice(
    AudioSource source, {
    required bool notifyOnComplete,
  }) async {
    if (Platform.isIOS) {
      await _playPreparedAiVoiceIos(
        notifyOnComplete: notifyOnComplete,
      );
      return;
    }
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

  Future<void> _playPreparedAiVoiceIos({
    required bool notifyOnComplete,
  }) async {
    final seq = _voiceSeq;
    _aiPlaybackSub?.cancel();
    _aiPlaybackSub = null;
    var notified = false;

    void maybeNotify() {
      if (!notifyOnComplete || notified || seq != _voiceSeq) return;
      notified = true;
      _aiPlaybackSub?.cancel();
      _aiPlaybackSub = null;
      _notifyAiVoicePlaybackCompleted();
    }

    var playStarted = false;
    var playReturned = false;
    _aiPlaybackSub = _audioPlayer.playerStateStream.listen((state) {
      if (!playStarted || seq != _voiceSeq) return;
      if (state.processingState == ProcessingState.completed) {
        maybeNotify();
      } else if (playReturned &&
          state.processingState == ProcessingState.idle &&
          !state.playing) {
        maybeNotify();
      }
    });

    playStarted = true;
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[DEBUG] RpS2 iOS AI voice play error: $e');
      maybeNotify();
      return;
    }
    playReturned = true;
    if (!mounted || seq != _voiceSeq) return;
    if (_audioPlayer.processingState == ProcessingState.completed) {
      maybeNotify();
    } else if (_audioPlayer.processingState == ProcessingState.idle &&
        !_audioPlayer.playing) {
      maybeNotify();
    }
  }

  Future<void> _addEntry(
    PlayingConversationEntry entry, {
    bool revealImmediately = false,
  }) async {
    if (entry.consumesConversationIndex) {
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
      scrollPlayingBodyToBottomHandler?.call(anchorKey: entry.key);
      if (!mounted) return;
      if (!revealImmediately) {
        setState(() => entry.isVisible = true);
        scrollPlayingBodyToBottomHandler?.call(anchorKey: entry.key);
      }
    });
  }

  Future<void> _toggleTranslation(PlayingConversationEntry entry) async {
    if (!entry.isAi) return;
    if (entry.conversationIndex == null) return;
    if (entry.translationText != null) {
      final willExpand = !entry.isTranslationExpanded;
      setState(() {
        entry.isTranslationExpanded = willExpand;
      });
      if (willExpand) {
        _scheduleTranslationReveal(entry);
      }
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
        rpMsgId: entry.conversationIndex!,
      );
      if (!mounted) return;
      setState(() {
        entry.translationText = translated;
        entry.isTranslationLoading = false;
      });
      _scheduleTranslationReveal(entry);
    } on RpS2SessionNotFoundException catch (_) {
      if (!mounted) return;
      setState(() {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
      });
      playingSessionNotFoundHandler?.call();
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        entry.isTranslationLoading = false;
        entry.isTranslationExpanded = false;
      });
    }
  }

  void _scheduleTranslationReveal(PlayingConversationEntry entry) {
    scrollToRevealBubbleIfNeededHandler?.call(anchorKey: entry.key);
  }

  List<Widget> buildConversationEntryWidgets(
    double bodyWidth, {
    bool omitRecording = false,
  }) {
    return [
      for (final entry in _conversationEntries)
        if (!(omitRecording &&
            entry.type == PlayingConversationEntryType.recording))
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
              PlayingConversationEntryType.recording => _buildRecordingBubble(
                entry,
              ),
            },
          ),
    ];
  }

  Widget? buildActiveRecordingEntryWidget() {
    final entry = _recordingEntry;
    if (entry == null) return null;
    return KeyedSubtree(
      key: entry.key,
      child: _buildRecordingBubble(entry),
    );
  }

  Widget _buildNarration(PlayingConversationEntry entry) {
    if (entry.text.isEmpty) return const SizedBox.shrink();
    // bodySmall 기본 height 1.2 — 이탤릭 glyph 여유를 위해 1.27로 소폭 상향.
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontStyle: FontStyle.italic,
      height: 1.27,
    );
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: _NarrationRevealText(
          text: entry.text,
          style: style,
          onContentGrowth: () => scrollPlayingBodyToBottomHandler?.call(
            anchorKey: entry.key,
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessage(double bodyWidth, PlayingConversationEntry entry) {
    if (entry.text.isEmpty) return const SizedBox.shrink();
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.white);
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
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(entry.text, style: textStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBubble(PlayingConversationEntry entry) {
    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const _RecordingWaveDots(),
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
    ).textTheme.bodyMedium?.copyWith(color: Colors.white);
    final translationStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: const Color(0xFF777373));

    return AnimatedOpacity(
      opacity: entry.isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF353535),
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
  final VoidCallback? onContentGrowth;

  const _NarrationRevealText({
    required this.text,
    this.style,
    this.onContentGrowth,
  });

  @override
  State<_NarrationRevealText> createState() => _NarrationRevealTextState();
}

class _NarrationRevealTextState extends State<_NarrationRevealText> {
  static const Duration _lineDuration = Duration(milliseconds: 260);
  /// 이탤릭 glyph가 line metric 밖으로 나가는 경우를 위한 줄 여유(px).
  static const double _lineExtraHeight = 1;
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
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) {
      _lines = [widget.text];
      _lineHeights = [painter.height + _lineExtraHeight];
    } else {
      _lines = _visualLinesFromPainter(painter, widget.text);
      _lineHeights = metrics
          .map((metric) => metric.height + _lineExtraHeight)
          .toList();
    }
    _scheduleReveal();
  }

  /// [painter]가 [maxWidth]로 접은 시각 줄. 공백 유무와 무관.
  /// 가운데 정렬이므로 y=0 히트테스트는 쓰지 않고 offset만 순회한다.
  static List<String> _visualLinesFromPainter(TextPainter painter, String text) {
    if (text.isEmpty) return [text];
    final lines = <String>[];
    var offset = 0;
    var guard = 0;
    while (offset < text.length && guard <= text.length) {
      guard++;
      final range = painter.getLineBoundary(
        TextPosition(offset: offset, affinity: TextAffinity.downstream),
      );
      if (!range.isValid) break;
      var start = range.start;
      var end = range.end;
      if (start < 0) start = 0;
      if (end > text.length) end = text.length;
      if (end < start) break;
      if (end == start) {
        if (offset < text.length && text[offset] == '\n') {
          lines.add('');
          offset++;
          continue;
        }
        offset++;
        continue;
      }
      var line = text.substring(start, end);
      if (line.endsWith('\r\n')) {
        line = line.substring(0, line.length - 2);
      } else if (line.endsWith('\n') || line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      lines.add(line);
      var next = end;
      if (next < text.length && (text[next] == '\n' || text[next] == '\r')) {
        if (text[next] == '\r' &&
            next + 1 < text.length &&
            text[next + 1] == '\n') {
          next += 2;
        } else {
          next++;
        }
      }
      if (next <= offset) next = offset + 1;
      offset = next;
    }
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
        widget.onContentGrowth?.call();
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
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
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

/// S1 `playing_backup` `_WaveDots`와 동일 애니메이션(900ms sin 파도). 점 색만 S2 흰색.
class _RecordingWaveDots extends StatefulWidget {
  const _RecordingWaveDots();

  @override
  State<_RecordingWaveDots> createState() => _RecordingWaveDotsState();
}

class _RecordingWaveDotsState extends State<_RecordingWaveDots>
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
                    color: Colors.white,
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
