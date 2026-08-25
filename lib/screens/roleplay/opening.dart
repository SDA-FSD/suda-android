import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../config/app_config.dart';
import '../../widgets/energy_header_badge.dart';
import '../../widgets/energy_info_popup.dart';
import '../../widgets/roleplay_overview_backdrop.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../services/perf_monitoring_service.dart';
import '../../utils/default_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../services/token_refresh_service.dart';
import '../../routes/roleplay_router.dart';
import '../../utils/suda_json_util.dart';
import '../../utils/default_markdown.dart';
import 'ios_audio_teardown.dart';

/// Roleplay Opening Screen (Full Screen)
///
/// Roleplay 시작 전 오프닝 화면
class RoleplayOpeningScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayOpeningScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<RoleplayOpeningScreen> createState() => _RoleplayOpeningScreenState();
}

class _RoleplayOpeningScreenState extends State<RoleplayOpeningScreen> {
  bool _isLoading = false;
  final AudioPlayer _briefingAudioPlayer = AudioPlayer();

  void _restoreButton() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_precacheAiCharacterImage());
      unawaited(_playBriefingAudio());
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final player = _briefingAudioPlayer;
      IosAudioTeardown.enqueue(() async {
        try {
          await player.stop();
        } catch (_) {}
        try {
          await player.dispose();
        } catch (_) {}
      });
    } else {
      unawaited(_stopBriefingAudio());
      unawaited(_briefingAudioPlayer.dispose());
    }
    super.dispose();
  }

  Future<void> _stopBriefingAudio() async {
    try {
      await _briefingAudioPlayer.stop();
    } catch (_) {
      // ignore
    }
  }

  /// language tag → languageCode → `en`. 없으면 재생하지 않음(다른 언어로 폴백하지 않음).
  String? _resolveBriefingAudioPath(Map<String, String> briefingAudio) {
    return SudaJsonUtil.localizedMapTextOrNull(briefingAudio);
  }

  Future<void> _playBriefingAudio() async {
    final episode = SeriesStateService.instance.selectedEpisode;
    final path = _resolveBriefingAudioPath(episode?.briefingAudio ?? const {});
    if (path == null) return;

    final url = path.startsWith('http')
        ? path
        : '${AppConfig.cdnBaseUrl}$path';
    try {
      await _briefingAudioPlayer.setUrl(url);
      if (!mounted) return;
      await _briefingAudioPlayer.play();
    } catch (_) {
      // 네트워크/디코드 실패 무시
    }
  }

  Future<void> _precacheAiCharacterImage() async {
    final path =
        SeriesStateService.instance.selectedEpisode?.aiCharacter?.rpImgPath;
    if (path == null || path.isEmpty) return;
    if (!mounted) return;
    final url = '${AppConfig.cdnBaseUrl}$path';
    try {
      await precacheImage(CachedNetworkImageProvider(url), context);
    } catch (_) {
      // preload 실패는 Playing에서 재시도
    }
  }

  /// Start 탭 시 마이크 권한: 허용됨 → true / 요청 후 허용 → true /
  /// 거부 → 안내 / 영구거부 → 설정 유도(복귀 후 사용자가 다시 Start).
  Future<bool> _ensureMicrophonePermission(BuildContext context) async {
    var status = await Permission.microphone.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;

    // iOS: 한 번 거절하면 시스템 팝업이 다시 안 뜸 → 설정 안내
    if (status.isPermanentlyDenied || status.isRestricted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.microphonePermissionDenied),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.accountGoBack),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    DefaultToast.show(context, l10n.microphonePermissionDenied);
    return false;
  }

  Future<void> _navigateToPlaying(BuildContext context) async {
    await TokenRefreshService.instance.refreshIfNeeded();

    final micOk = await _ensureMicrophonePermission(context);
    if (!micOk) {
      _restoreButton();
      return;
    }

    if (!context.mounted) {
      _restoreButton();
      return;
    }
    final accessToken = await TokenStorage.loadAccessToken();
    if (!context.mounted) {
      _restoreButton();
      return;
    }
    if (accessToken == null) {
      DefaultToast.show(context, 'Authentication required.');
      _restoreButton();
      return;
    }

    final seriesId = SeriesStateService.instance.seriesId;
    final episodeId = SeriesStateService.instance.selectedEpisodeId;
    if (seriesId == null || episodeId == null) {
      DefaultToast.show(context, 'Cannot start roleplay');
      _restoreButton();
      return;
    }

    try {
      await PerfMonitoringService.instance.start('roleplay_session_start');
      final session = await SudaApiClient.createRpS2Session(
        accessToken: accessToken,
        seriesId: seriesId,
        episodeId: episodeId,
      );
      if (!context.mounted) {
        _restoreButton();
        return;
      }
      final sessionId = session.sessionId;
      if (sessionId == null || sessionId.isEmpty) {
        DefaultToast.show(context, 'Cannot start roleplay');
        _restoreButton();
        return;
      }
      if (sessionId == '0') {
        await showEnergyInsufficientPopup(
          context,
          screen: EnergyOfferScreen.openingInsufficient,
        );
        _restoreButton();
        return;
      }
      if (sessionId.startsWith('-')) {
        DefaultToast.show(context, 'Cannot start roleplay');
        _restoreButton();
        return;
      }
      SeriesStateService.instance.setSession(session);
      await _precacheAiCharacterImage();
      if (!context.mounted) {
        _restoreButton();
        return;
      }
      await _stopBriefingAudio();
      if (!context.mounted) {
        _restoreButton();
        return;
      }
      RoleplayRouter.replaceWithPlaying(context);
    } catch (e) {
      if (!context.mounted) {
        _restoreButton();
        return;
      }
      if (e.toString().contains('HTTP 500')) {
        DefaultToast.show(context, 'Cannot start roleplay');
        _restoreButton();
        return;
      }
      DefaultToast.show(context, 'Cannot start roleplay');
      _restoreButton();
    } finally {
      await PerfMonitoringService.instance.stop('roleplay_session_start');
    }
  }

  @override
  Widget build(BuildContext context) {
    final episode = SeriesStateService.instance.selectedEpisode;

    final title = episode == null
        ? ''
        : SudaJsonUtil.localizedMapText(episode.title);
    final aiCharacterName = episode?.aiCharacter?.name ?? '';
    final briefing = episode == null
        ? ''
        : SudaJsonUtil.localizedMapText(episode.briefing);

    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final thumbnailPath = episode?.thumbnailImgPath;
    final backdropUrl = (thumbnailPath != null && thumbnailPath.isNotEmpty)
        ? '${AppConfig.cdnBaseUrl}$thumbnailPath'
        : null;
    final topInset = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // opening screen이 이미 pop되었으므로 overview로 자동으로 돌아감
        // Navigator.pop()이 자동으로 처리함
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
            title: title.isEmpty ? null : title,
            titleStyle: RoleplayScaffold.episodeTitleStyle(theme),
            titleMaxLines: 1,
            centerTitleInHeaderActionRow: true,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.roleplayOpeningAiCharacter,
                    style: theme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    aiCharacterName,
                    style: theme.headlineLarge?.copyWith(
                      color: const Color(0xFF0CABA8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    l10n.roleplayOpeningScenario,
                    style: theme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      style: theme.bodyLarge?.copyWith(color: Colors.white),
                      children: DefaultMarkdown.buildSpans(
                        briefing,
                        theme.bodyLarge?.copyWith(color: Colors.white) ??
                            const TextStyle(color: Colors.white),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            footer: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          await _navigateToPlaying(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0CABA8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF0CABA8),
                    disabledForegroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text("Let's Start"),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.roleplayOpeningAiDisclaimer,
                  style: theme.labelSmall?.copyWith(
                    color: const Color(0xFF8C8C8C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            top: topInset + 16,
            right: 16,
            child: const EnergyHeaderBadge(
              energyOfferScreen: EnergyOfferScreen.opening,
            ),
          ),
        ],
      ),
    );
  }
}
