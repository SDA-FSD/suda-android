import 'dart:async' show Timer, unawaited;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/english_level_util.dart';
import '../../utils/suda_json_util.dart';
import '../../widgets/roleplay_configuration_panel.dart';
import '../../widgets/roleplay_overview_backdrop.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../models/series_models.dart';
import '../../utils/language_util.dart';
import '../../widgets/roleplay_mission_panel.dart';
import '../../widgets/roleplay_turn_bar_area.dart';
import 'playing_conversation_mixin.dart';
import 'playing_hint_mixin.dart';
import 'playing_input_mixin.dart';

/// S2 Roleplay Playing Screen (Full Screen)
///
/// S1 구현 백업: `playing_backup.dart`
class RoleplayPlayingScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayPlayingScreen({super.key, this.showCloseButton = true});

  @override
  State<RoleplayPlayingScreen> createState() => _RoleplayPlayingScreenState();
}

class _RoleplayPlayingScreenState extends State<RoleplayPlayingScreen>
    with
        TickerProviderStateMixin,
        PlayingConversationMixin,
        PlayingHintMixin,
        PlayingInputMixin {
  static const List<int> _speedRateSteps = [70, 100, 120, 150];

  bool _showExitLayer = false;
  bool _showConfigurationPanel = false;
  late bool _autoHintEnabled;
  late int _speedIndex;
  late final int _turnCount;
  late List<Color> _turnBarColors;
  late List<String?> _turnLabelTexts;
  late List<Color?> _turnLabelColors;
  late final List<RpS2CefrMissionDto> _missions;
  int _activeMissionIndex = 0;
  int _completedMissionCount = 0;
  int _completedSpeechCount = 0;
  final Set<int> _completedMissionIndexes = {};
  int? _animatingMissionIndex;
  int? _pendingActiveMissionIndex;
  bool _keepMissionCompletedBackground = false;
  int _missionAnimationSerial = 0;
  final List<Timer> _turnEffectTimers = [];
  Timer? _missionCompleteTimer;

  @override
  void initState() {
    super.initState();
    initPlayingInput();
    _autoHintEnabled = _resolveDefaultAutoHint();
    _speedIndex = _resolveInitialSpeedIndex();
    _turnCount = _resolveRequiredSpeechCount();
    _missions = _resolveMissions();
    _turnBarColors = List<Color>.filled(
      _turnCount,
      RoleplayTurnBarArea.defaultBarColor,
    );
    _turnLabelTexts = List<String?>.filled(_turnCount, null);
    _turnLabelColors = List<Color?>.filled(_turnCount, null);
    handleRpS2UserMessageResponse = _handleRpS2UserMessageResponse;
    playingHintPrepareForAiMessageHandler = preparePlayingHintForAiMessage;
    playingHintResetIconForAiStartHandler = resetHintIconForAiStart;
    deactivateUserTurnHandler = deactivateUserTurn;
    playingAiVoicePlaybackCompletedHandler = _onAiVoicePlaybackCompleted;
    deactivateUserTurn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) startAiOpeningFlow();
    });
  }

  bool _resolveDefaultAutoHint() {
    final level = EnglishLevelUtil.readLevelFromUser(
      SeriesStateService.instance.user,
    );
    return switch (level) {
      'Pre-A1' || 'A1' || 'A2' => true,
      _ => false,
    };
  }

  int _resolveInitialSpeedIndex() {
    final metaInfo = SeriesStateService.instance.user?.metaInfo;
    var initialRate = 100;
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
    final index = _speedRateSteps.indexOf(initialRate);
    if (index >= 0) return index;
    final defaultIndex = _speedRateSteps.indexOf(100);
    return defaultIndex >= 0 ? defaultIndex : 1;
  }

  void _onAiVoicePlaybackCompleted() {
    if (!mounted) return;
    if (_autoHintEnabled) {
      unawaited(_showAutoHintThenActivateUserTurn());
    } else {
      onHintAvailableAfterAi();
      _applyPendingActiveMissionForNextTurn();
      activateUserTurn();
    }
  }

  Future<void> _showAutoHintThenActivateUserTurn() async {
    await showPlayingHint();
    if (!mounted) return;
    _applyPendingActiveMissionForNextTurn();
    activateUserTurn(enableHintButton: false);
  }

  Future<void> _handleRpS2UserMessageResponse(
    RpS2UserMessageResponseDto response,
  ) async {
    stopPlayingAnalyzingBlink();
    final turnIndex = _completedSpeechCount;
    final userText = response.userText?.trim() ?? '';
    final nextCompletedSpeechCount = _completedSpeechCount + 1;
    final reachedRequiredSpeechCount =
        _turnCount > 0 && nextCompletedSpeechCount >= _turnCount;
    final narrationText = response.narration?.trim() ?? '';
    final aiText = response.aiText?.trim() ?? '';
    final shouldAnalyzeResult =
        reachedRequiredSpeechCount && narrationText.isEmpty && aiText.isEmpty;

    Future<RpS2SoundResDto?>? aiAudioFuture;
    if (!shouldAnalyzeResult && aiText.isNotEmpty) {
      aiAudioFuture = _fetchAiMessageAudio();
    }

    if (userText.isNotEmpty) {
      await showPlayingUserMessage(userText);
    }
    if (!mounted) return;
    setState(() => _completedSpeechCount = nextCompletedSpeechCount);

    _animateTurnBarGrade(turnIndex, response.userGrade);
    _handleMissionCompleted(response.missionCompletedIndex);

    if (shouldAnalyzeResult) {
      startPlayingAnalyzingBlink();
      return;
    }

    await _showNarrationPhase(narrationText);
    if (!mounted) return;

    if (aiText.isEmpty) {
      _applyPendingActiveMissionForNextTurn();
      activateUserTurn();
      return;
    }

    final results = await Future.wait<Object?>([
      Future<void>.delayed(const Duration(milliseconds: 500)),
      aiAudioFuture ?? Future<RpS2SoundResDto?>.value(null),
    ]);
    if (!mounted) return;
    final aiSound = results[1] as RpS2SoundResDto?;
    await showPlayingAiMessage(
      text: aiText,
      cdnYn: aiSound?.cdnYn,
      cdnPath: aiSound?.cdnPath,
      soundBytes: aiSound?.file,
    );
  }

  Future<void> _showNarrationPhase(String narrationText) async {
    if (narrationText.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await showPlayingNarration(narrationText);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
  }

  Future<RpS2SoundResDto?> _fetchAiMessageAudio() async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) {
      return null;
    }
    try {
      return await SudaApiClient.getRpS2AiMessageAudio(
        accessToken: accessToken,
        rpSessionId: sessionId,
      );
    } catch (e) {
      debugPrint('[DEBUG] RpS2 AI audio error: $e');
      return null;
    }
  }

  void _animateTurnBarGrade(int index, String? rawGrade) {
    if (index < 0 || index >= _turnCount) return;
    final grade = (rawGrade ?? '').toUpperCase();
    final color = switch (grade) {
      'A' => const Color(0xFF0CABA8),
      'B' => const Color(0xFF62FF00),
      'C' => const Color(0xFFFFB700),
      'D' => const Color(0xFFFF0000),
      _ => const Color(0xFFFFB700),
    };
    final label = _turnGradeLabel(grade);
    setState(() {
      _turnBarColors[index] = color;
      _turnLabelTexts[index] = null;
      _turnLabelColors[index] = color;
    });
    _turnEffectTimers.add(
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _turnLabelTexts[index] = label;
          _turnLabelColors[index] = color;
        });
      }),
    );
    _turnEffectTimers.add(
      Timer(const Duration(milliseconds: 1350), () {
        if (!mounted) return;
        setState(() {
          _turnLabelTexts[index] = null;
          _turnBarColors[index] = color.withValues(alpha: 0.4);
        });
      }),
    );
  }

  String _turnGradeLabel(String grade) {
    final isPortuguese = LanguageUtil.getCurrentLanguageCode() == 'pt';
    return switch (grade) {
      'A' => isPortuguese ? 'bah!' : 'wow!',
      'B' => 'ok!',
      'C' => isPortuguese ? 'nhé…' : 'hmm…',
      'D' => isPortuguese ? 'oxi?' : 'oh…',
      _ => isPortuguese ? 'nhé…' : 'hmm…',
    };
  }

  void _handleMissionCompleted(int? completedIndex) {
    if (completedIndex == null) return;
    if (completedIndex < 0 || completedIndex >= _missions.length) return;
    if (_completedMissionIndexes.contains(completedIndex)) {
      debugPrint(
        '[DEBUG] RpS2 duplicate missionCompletedIndex ignored: $completedIndex',
      );
      return;
    }
    _missionCompleteTimer?.cancel();
    setState(() {
      _activeMissionIndex = completedIndex;
      _completedMissionIndexes.add(completedIndex);
      _completedMissionCount = _completedMissionIndexes.length;
      _animatingMissionIndex = completedIndex;
      _keepMissionCompletedBackground = true;
      _missionAnimationSerial += 1;
    });
    _missionCompleteTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final nextIndex = _firstIncompleteMissionIndex();
      setState(() {
        _animatingMissionIndex = null;
        _pendingActiveMissionIndex = nextIndex;
      });
    });
  }

  void _applyPendingActiveMissionForNextTurn() {
    final nextIndex = _pendingActiveMissionIndex;
    if (nextIndex == null) return;
    if (nextIndex == _activeMissionIndex) {
      _pendingActiveMissionIndex = null;
      return;
    }
    setState(() {
      _activeMissionIndex = nextIndex;
      _pendingActiveMissionIndex = null;
      _keepMissionCompletedBackground = false;
    });
  }

  int? _firstIncompleteMissionIndex() {
    for (var i = 0; i < _missions.length; i++) {
      if (!_completedMissionIndexes.contains(i)) return i;
    }
    return null;
  }

  List<Widget> _buildConversationWithHint(double bodyWidth) {
    final children = buildConversationEntryWidgets(bodyWidth);
    final hint = buildHintBubble(bodyWidth);
    if (hint == null) return children;
    return [
      ...children,
      if (children.isNotEmpty) const SizedBox(height: 14),
      KeyedSubtree(key: activeHintEntry!.key, child: hint),
    ];
  }

  @override
  void dispose() {
    for (final timer in _turnEffectTimers) {
      timer.cancel();
    }
    _missionCompleteTimer?.cancel();
    disposePlayingHint();
    disposePlayingConversation();
    disposePlayingInput();
    super.dispose();
  }

  List<RpS2CefrMissionDto> _resolveMissions() {
    final episode = SeriesStateService.instance.selectedEpisode;
    final user = SeriesStateService.instance.user;
    if (episode == null) return const [];

    final cefrCode = EnglishLevelUtil.readLevelFromUser(user);
    return episode.cefrMap[cefrCode]?.missions ?? const [];
  }

  /// `selectedEpisode.cefrMap[사용자 ENGLISH_LEVEL].requiredSpeechCount`
  int _resolveRequiredSpeechCount() {
    final episode = SeriesStateService.instance.selectedEpisode;
    final user = SeriesStateService.instance.user;
    if (episode == null) return 0;

    final cefrCode = EnglishLevelUtil.readLevelFromUser(user);
    final count = episode.cefrMap[cefrCode]?.requiredSpeechCount;
    if (count == null || count < 1) return 0;
    return count;
  }

  void _handleBackButton() {
    setState(() => _showExitLayer = true);
  }

  void _dismissExitLayer() {
    if (mounted) setState(() => _showExitLayer = false);
  }

  void _confirmExit(BuildContext context) {
    _dismissExitLayer();
    if (context.mounted) RoleplayRouter.popToOverview(context);
  }

  void _onHamburgerTap() {
    setState(() => _showConfigurationPanel = !_showConfigurationPanel);
  }

  void _dismissConfigurationPanel() {
    if (!_showConfigurationPanel) return;
    setState(() => _showConfigurationPanel = false);
  }

  void _onAutoHintChanged(bool value) {
    setState(() => _autoHintEnabled = value);
  }

  void _onSpeedIndexChanged(int nextIndex) {
    if (_speedIndex == nextIndex) return;
    setState(() => _speedIndex = nextIndex);
    _updateSpeedRate(_speedRateSteps[nextIndex]);
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
      // S1과 동일: 에러 무시
    }
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
                    letterSpacing: -0.38,
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

  @override
  Widget build(BuildContext context) {
    final episode = SeriesStateService.instance.selectedEpisode;
    final title = episode == null
        ? ''
        : SudaJsonUtil.localizedMapText(episode.title);

    final thumbnailPath = episode?.thumbnailImgPath;
    final backdropUrl = (thumbnailPath != null && thumbnailPath.isNotEmpty)
        ? '${AppConfig.cdnBaseUrl}$thumbnailPath'
        : null;
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackButton();
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
            onClose: _handleBackButton,
            title: title.isEmpty ? null : title,
            belowHeader: _turnCount > 0
                ? RoleplayTurnBarArea(
                    turnCount: _turnCount,
                    barColors: _turnBarColors,
                    labelTexts: _turnLabelTexts,
                    labelColors: _turnLabelColors,
                  )
                : null,
            belowHeaderHeight: _turnCount > 0
                ? RoleplayTurnBarArea.areaHeight
                : 0,
            body: buildPlayingBody(
              topOverlay: RoleplayMissionPanel(
                missions: _missions,
                activeMissionIndex: _activeMissionIndex,
                completedCount: _completedMissionCount,
                completedMissionIndexes: _completedMissionIndexes,
                animatingMissionIndex: _animatingMissionIndex,
                animationSerial: _missionAnimationSerial,
                keepCompletedBackground: _keepMissionCompletedBackground,
              ),
              conversationBuilder: _buildConversationWithHint,
            ),
            footer: buildPlayingFooter(),
          ),
          if (widget.showCloseButton && _showConfigurationPanel)
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _dismissConfigurationPanel(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
          if (widget.showCloseButton && _showConfigurationPanel)
            Positioned(
              top: topInset + 56,
              right: 24,
              child: RoleplayConfigurationPanel(
                autoHintEnabled: _autoHintEnabled,
                onAutoHintChanged: _onAutoHintChanged,
                speedIndex: _speedIndex,
                onSpeedIndexChanged: _onSpeedIndexChanged,
              ),
            ),
          if (widget.showCloseButton)
            Positioned(
              top: topInset + 16,
              right: 16,
              child: GestureDetector(
                onTap: _onHamburgerTap,
                behavior: HitTestBehavior.opaque,
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
          if (_showExitLayer) Positioned.fill(child: _buildExitLayer(context)),
        ],
      ),
    );
  }
}
