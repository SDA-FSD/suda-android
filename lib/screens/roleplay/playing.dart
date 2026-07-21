import 'dart:async' show Timer, unawaited;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../services/perf_monitoring_service.dart';
import '../../utils/english_level_util.dart';
import '../../utils/suda_json_util.dart';
import '../../effects/mission_complete_effect.dart';
import '../../widgets/roleplay_configuration_panel.dart';
import '../../widgets/roleplay_overview_backdrop.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../models/series_models.dart';
import '../../utils/language_util.dart';
import '../../widgets/roleplay_mission_panel.dart';
import '../../widgets/roleplay_turn_bar_area.dart';
import 'playing_conversation_mixin.dart';
import 'playing_energy_mixin.dart';
import 'playing_finish_mixin.dart';
import 'playing_hint_mixin.dart';
import 'playing_input_mixin.dart';

/// S2 Roleplay Playing Screen (Full Screen)
///
/// S2 Playing 화면.
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
        PlayingInputMixin,
        PlayingFinishMixin,
        PlayingEnergyMixin {
  static const List<int> _speedRateSteps = [70, 100, 120, 150];
  static const double _playingHeaderTopSpacing = 60;

  bool _showExitLayer = false;
  bool _showConfigurationPanel = false;
  late bool _autoHintEnabled;
  late int _speedIndex;
  late final int _turnCount;
  late List<Color> _turnBarColors;
  late List<String?> _turnLabelTexts;
  late List<Color?> _turnLabelColors;
  late List<bool> _turnLabelFadeOuts;
  late final List<RpS2CefrMissionDto> _missions;
  int _activeMissionIndex = 0;
  int _completedMissionCount = 0;
  int _completedSpeechCount = 0;
  final Set<int> _completedMissionIndexes = {};
  final GlobalKey _missionIconAnchorKey = GlobalKey();
  final List<Timer> _turnEffectTimers = [];
  Timer? _missionCompleteTimer;
  bool _lastTurnAwaitingAiPresentation = false;

  bool _showMissionCompletedFlash = false;
  double _missionPanelOpacity = 1;

  @override
  void initState() {
    super.initState();
    initPlayingInput();
    initPlayingEnergy();
    checkCanSpendPlayingEnergy = hasSpendablePlayingEnergy;
    onPlayingEnergySpent = decrementPlayingEnergyCount;
    playingEnergyFooterBuilder = buildPlayingEnergyFooterIndicator;
    onPlayingEnergyExitRequested = () {
      if (mounted) setState(() => _showExitLayer = true);
    };
    onPlayingEnergyIndicatorEndRoleplay = () {
      if (mounted) setState(() => _showExitLayer = true);
    };
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
    _turnLabelFadeOuts = List<bool>.filled(_turnCount, false);
    handleRpS2UserMessageResponse = _handleRpS2UserMessageResponse;
    playingHintPrepareForAiMessageHandler = preparePlayingHintForAiMessage;
    playingHintResetIconForAiStartHandler = resetHintIconForAiStart;
    deactivateUserTurnHandler = deactivateUserTurn;
    scrollPlayingBodyToBottomHandler = scrollPlayingBodyToBottom;
    scrollToRevealBubbleIfNeededHandler = scrollToRevealBubbleIfNeeded;
    scrollPlayingHintToBottomHandler = scrollPlayingBodyToBottom;
    playingAiVoicePlaybackCompletedHandler = _onAiVoicePlaybackCompleted;
    playingSessionNotFoundHandler = onRpS2SessionNotFound;
    deactivateUserTurn();
    unawaited(PerfMonitoringService.instance.start('roleplay_screen_ready'));
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

  double _scaffoldBodyLeadHeight() {
    final turnBarHeight =
        _turnCount > 0 ? RoleplayTurnBarArea.areaHeight : 0.0;
    return _playingHeaderTopSpacing +
        turnBarHeight +
        PlayingConversationLayout.bodyTopGap;
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
    if (_lastTurnAwaitingAiPresentation) {
      _lastTurnAwaitingAiPresentation = false;
      onLastTurnPresentationComplete();
      return;
    }
    if (_autoHintEnabled) {
      unawaited(_showAutoHintThenActivateUserTurn());
    } else {
      onHintAvailableAfterAi();
      activateUserTurn();
    }
  }

  Future<void> _showAutoHintThenActivateUserTurn() async {
    await showPlayingHint();
    if (!mounted) return;
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

    if (userText.isNotEmpty) {
      await showPlayingUserMessage(userText);
    }
    if (!mounted) return;
    setState(() => _completedSpeechCount = nextCompletedSpeechCount);

    _animateTurnBarGrade(turnIndex, response.userGrade);
    _handleMissionCompleted(response.missionCompletedIndex);

    final narrationText = response.narration?.trim() ?? '';
    final aiText = response.aiText?.trim() ?? '';
    if (reachedRequiredSpeechCount) {
      startPlayingAnalyzingBlink(
        message: response.serviceMessage?.trim(),
      );
    }

    Future<RpS2SoundResDto?>? aiAudioFuture;
    if (aiText.isNotEmpty) {
      aiAudioFuture = _fetchAiMessageAudio();
    }

    await _showNarrationPhase(narrationText);
    if (!mounted) return;

    if (aiText.isEmpty) {
      if (reachedRequiredSpeechCount) {
        _beginLastTurnFinishFlow(awaitAiPresentation: false);
      } else {
        activateUserTurn();
      }
      return;
    }

    final results = await Future.wait<Object?>([
      Future<void>.delayed(const Duration(milliseconds: 500)),
      aiAudioFuture ?? Future<RpS2SoundResDto?>.value(null),
    ]);
    if (!mounted) return;
    final aiSound = results[1] as RpS2SoundResDto?;
    if (reachedRequiredSpeechCount) {
      _beginLastTurnFinishFlow(awaitAiPresentation: true);
    }
    await showPlayingAiMessage(
      text: aiText,
      cdnYn: aiSound?.cdnYn,
      cdnPath: aiSound?.cdnPath,
      soundBytes: aiSound?.file,
    );
  }

  void _beginLastTurnFinishFlow({required bool awaitAiPresentation}) {
    requestFinishAfterLastUserResponse();
    if (awaitAiPresentation) {
      _lastTurnAwaitingAiPresentation = true;
    } else {
      onLastTurnPresentationComplete();
    }
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
      _turnLabelTexts[index] = label;
      _turnLabelColors[index] = color;
      _turnLabelFadeOuts[index] = false;
    });
    _scheduleTurnGradeDim(index);
  }

  void _scheduleTurnGradeDim(int index) {
    _turnEffectTimers.add(
      Timer(RoleplayTurnBarArea.turnGradeHighlightDuration, () {
        if (!mounted || index < 0 || index >= _turnCount) return;
        if (_turnLabelTexts[index] == null) return;
        setState(() => _turnLabelFadeOuts[index] = true);
        _turnEffectTimers.add(
          Timer(RoleplayTurnBarArea.labelFadeOutDuration, () {
            if (!mounted || index < 0 || index >= _turnCount) return;
            setState(() {
              _turnLabelTexts[index] = null;
              final baseColor = _turnLabelColors[index];
              if (baseColor != null) {
                _turnBarColors[index] = baseColor.withValues(
                  alpha: RoleplayTurnBarArea.pastTurnBarOpacity,
                );
              }
              _turnLabelFadeOuts[index] = false;
            });
          }),
        );
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
      _showMissionCompletedFlash = true;
    });
    MissionCompleteEffect.play(context, anchorKey: _missionIconAnchorKey);
    _missionCompleteTimer = Timer(
      RoleplayMissionPanel.completedBackgroundDuration,
      () {
        if (!mounted) return;
        final nextIndex = _firstIncompleteMissionIndex();
        setState(() {
          _showMissionCompletedFlash = false;
          if (nextIndex != null) {
            _activeMissionIndex = nextIndex;
          } else {
            _missionPanelOpacity = 0;
          }
        });
      },
    );
  }

  int? _firstIncompleteMissionIndex() {
    for (var i = 0; i < _missions.length; i++) {
      if (!_completedMissionIndexes.contains(i)) return i;
    }
    return null;
  }

  List<Widget> _buildConversationWithHint(double bodyWidth) {
    final hint = buildHintBubble(bodyWidth);
    final hasActiveHint = hint != null;
    final children = buildConversationEntryWidgets(
      bodyWidth,
      omitRecording: hasActiveHint,
    );
    if (!hasActiveHint) return children;

    final recordingWidget = buildActiveRecordingEntryWidget();
    return [
      ...children,
      if (children.isNotEmpty) const SizedBox(height: 14),
      KeyedSubtree(key: activeHintEntry!.key, child: hint),
      if (recordingWidget != null) ...[
        const SizedBox(height: 14),
        recordingWidget,
      ],
    ];
  }

  @override
  void dispose() {
    unawaited(PerfMonitoringService.instance.stop('roleplay_screen_ready'));
    for (final timer in _turnEffectTimers) {
      timer.cancel();
    }
    _missionCompleteTimer?.cancel();
    disposePlayingHint();
    disposePlayingConversation();
    disposePlayingInput();
    disposePlayingEnergy();
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

  Future<void> _confirmExit(BuildContext context) async {
    _dismissExitLayer();
    await teardownPlayingRecording();
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
                  onTap: () => unawaited(_confirmExit(context)),
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
    final theme = Theme.of(context);
    final episode = SeriesStateService.instance.selectedEpisode;
    final title = episode == null
        ? ''
        : SudaJsonUtil.localizedMapText(episode.title);

    final thumbnailPath = episode?.thumbnailImgPath;
    final backdropUrl = (thumbnailPath != null && thumbnailPath.isNotEmpty)
        ? '${AppConfig.cdnBaseUrl}$thumbnailPath'
        : null;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const systemChromeColor = Color(0xFF121212);

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
          if (topInset > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset,
              child: const ColoredBox(color: systemChromeColor),
            ),
          if (bottomInset > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomInset,
              child: const ColoredBox(color: systemChromeColor),
            ),
          RoleplayScaffold(
            backgroundColor: backdropUrl != null ? Colors.transparent : null,
            showCloseButton: widget.showCloseButton,
            onClose: _handleBackButton,
            title: title.isEmpty ? null : title,
            titleStyle: RoleplayScaffold.episodeTitleStyle(theme.textTheme),
            titleMaxLines: 1,
            headerTopSpacingDelta: -10,
            centerTitleInHeaderActionRow: true,
            belowHeader: _turnCount > 0
                ? RoleplayTurnBarArea(
                    turnCount: _turnCount,
                    barColors: _turnBarColors,
                    labelTexts: _turnLabelTexts,
                    labelColors: _turnLabelColors,
                    labelFadeOuts: _turnLabelFadeOuts,
                  )
                : null,
            belowHeaderHeight: _turnCount > 0
                ? RoleplayTurnBarArea.areaHeight
                : 0,
            body: buildPlayingBody(
              scaffoldBodyLeadHeight: _scaffoldBodyLeadHeight(),
              missionPanelOpacity: _missionPanelOpacity,
              topOverlay: RoleplayMissionPanel(
                missions: _missions,
                activeMissionIndex: _activeMissionIndex,
                completedCount: _completedMissionCount,
                completedMissionIndexes: _completedMissionIndexes,
                showCompletedBackgroundFlash: _showMissionCompletedFlash,
                missionIconAnchorKey: _missionIconAnchorKey,
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
