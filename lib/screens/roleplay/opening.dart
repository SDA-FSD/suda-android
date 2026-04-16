import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import '../../config/app_config.dart';
import '../../widgets/roleplay_overview_backdrop.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../l10n/app_localizations.dart';
import '../../services/token_refresh_service.dart';
import '../../routes/roleplay_router.dart';
import '../../utils/suda_json_util.dart';
import '../../utils/default_markdown.dart';
import '../../widgets/daily_ticket_popup.dart';
import '../../widgets/default_popup.dart';
import '../../utils/sub_screen_route.dart';
import '../setting/push_agreement.dart';

const String _kOpeningPlayStoreShareUrl =
    'https://play.google.com/store/apps/details?id=kr.sudatalk.app';

/// Roleplay Opening Screen (Full Screen)
///
/// Roleplay 시작 전 오프닝 화면
class RoleplayOpeningScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayOpeningScreen({super.key, this.showCloseButton = true});

  @override
  State<RoleplayOpeningScreen> createState() => _RoleplayOpeningScreenState();
}

class _RoleplayOpeningScreenState extends State<RoleplayOpeningScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;

  final AudioPlayer _ticketPlayer = AudioPlayer();
  late final AnimationController _ticketFadeIn1Controller;
  late final AnimationController _ticketFadeIn2Controller;
  late final Animation<double> _ticketOpacity1;
  late final Animation<double> _ticketOpacity2;
  bool _showTicketPhase1 = false;
  bool _showTicketPhase2 = false;

  void _restoreButton() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _ticketFadeIn1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ticketFadeIn2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ticketOpacity1 = CurvedAnimation(
      parent: _ticketFadeIn1Controller,
      curve: Curves.easeOut,
    );
    _ticketOpacity2 = CurvedAnimation(
      parent: _ticketFadeIn2Controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _ticketFadeIn1Controller.dispose();
    _ticketFadeIn2Controller.dispose();
    _ticketPlayer.dispose();
    super.dispose();
  }

  Future<void> _playTicketConsumeEffect() async {
    try {
      setState(() {
        _showTicketPhase1 = true;
        _showTicketPhase2 = false;
      });

      await _ticketFadeIn1Controller.forward(from: 0);

      try {
        await _ticketPlayer.setAsset('assets/sounds/ticket.mp3');
        await _ticketPlayer.seek(Duration.zero);
        _ticketPlayer.play();
      } catch (_) {}

      setState(() {
        _showTicketPhase2 = true;
      });
      await _ticketFadeIn2Controller.forward(from: 0);

      Vibration.vibrate(duration: 80);

      setState(() {
        _showTicketPhase1 = false;
      });

      await Future.delayed(const Duration(seconds: 1));
    } catch (_) {
      // 이펙트 실패는 조용히 무시하고 다음 단계로 진행
    }
  }

  Future<void> _navigateToPlaying(BuildContext context) async {
    await TokenRefreshService.instance.refreshIfNeeded();
    // 1. 마이크 권한 확인
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      if (!context.mounted) return;
      final accessToken = await TokenStorage.loadAccessToken();
      if (!context.mounted) return;
      if (accessToken == null) {
        DefaultToast.show(context, 'Authentication required.');
        _restoreButton();
        return;
      }

      final roleplayId = RoleplayStateService.instance.roleplayId;
      final roleId = RoleplayStateService.instance.roleId;
      if (roleplayId == null || roleId == null) {
        DefaultToast.show(context, 'Cannot start roleplay');
        _restoreButton();
        return;
      }

      try {
        final session = await SudaApiClient.createRoleplaySession(
          accessToken: accessToken,
          roleplayId: roleplayId,
          roleId: roleId,
        );
        if (!context.mounted) return;
        final sessionId = session.sessionId;
        if (sessionId == null || sessionId.isEmpty) {
          DefaultToast.show(context, 'Cannot start roleplay');
          _restoreButton();
          return;
        }
        if (sessionId == '-99') {
          await showRoleplayOpeningDailyTicketDefaultPopup(
            context,
            accessToken,
          );
          _restoreButton();
          return;
        }
        if (sessionId == '0') {
          await showRoleplayOpeningNoTicketsDefaultPopup(context);
          _restoreButton();
          return;
        }
        if (sessionId == '-10') {
          await showRoleplayOpeningSurveyQuestDefaultPopup(context);
          _restoreButton();
          return;
        }
        if (sessionId == '-20') {
          await showRoleplayOpeningPushNotificationQuestDefaultPopup(context);
          _restoreButton();
          return;
        }
        if (sessionId == '-30') {
          await showRoleplayOpeningShareQuestDefaultPopup(context, sessionId);
          _restoreButton();
          return;
        }
        if (sessionId == '-40') {
          await showRoleplayOpeningInAppReviewQuestDefaultPopup(
            context,
            sessionId,
          );
          _restoreButton();
          return;
        }
        await _playTicketConsumeEffect();
        RoleplayStateService.instance.setSessionId(sessionId);
        RoleplayStateService.instance.setSession(session);
        RoleplayRouter.replaceWithPlaying(context);
      } catch (e) {
        if (!context.mounted) return;
        if (e.toString().contains('HTTP 500')) {
          DefaultToast.show(context, 'Cannot start roleplay');
          _restoreButton();
          return;
        }
        DefaultToast.show(context, 'Cannot start roleplay');
        _restoreButton();
      }
    } else {
      // 권한 거부 시 안내
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      DefaultToast.show(context, l10n.microphonePermissionDenied);
      _restoreButton();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = RoleplayStateService.instance.overview;
    final roleplay = overview?.roleplay;
    final roleId = RoleplayStateService.instance.roleId;

    // 선택된 역할 정보 찾기
    final selectedRole = roleplay?.roleList?.firstWhere(
      (r) => r.id == roleId,
      orElse: () => roleplay.roleList!.first,
    );

    // 1. 영어 타이틀 추출
    final titleEn = SudaJsonUtil.englishText(roleplay?.title);

    // 2. 듀레이션 포맷팅 (00:05:00 -> 05:00)
    String durationFormatted = '00:00';
    if (roleplay?.duration != null && roleplay!.duration!.isNotEmpty) {
      final parts = roleplay.duration!.split(':');
      if (parts.length >= 3) {
        durationFormatted = '${parts[1]}:${parts[2]}';
      }
    }

    final theme = Theme.of(context).textTheme;

    final overviewImgPath = roleplay?.overviewImgPath;
    final backdropUrl = (overviewImgPath != null && overviewImgPath.isNotEmpty)
        ? '${AppConfig.cdnBaseUrl}$overviewImgPath'
        : null;

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
            title: titleEn,
            duration: durationFormatted,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 중앙에 쫀쫀하게 모임
                children: [
                  Text(
                    'Your Role',
                    style: theme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    SudaJsonUtil.localizedText(selectedRole?.name),
                    style: theme.headlineLarge?.copyWith(
                      color: const Color(0xFF0CABA8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Scenario',
                    style: theme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      style: theme.bodyLarge?.copyWith(color: Colors.white),
                      children: DefaultMarkdown.buildSpans(
                        SudaJsonUtil.localizedText(selectedRole?.scenario),
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
                SizedBox(
                  height: 40,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_showTicketPhase1)
                          FadeTransition(
                            opacity: _ticketOpacity1,
                            child: Image.asset(
                              'assets/images/icons/ticket.png',
                              width: 40,
                              height: 20,
                            ),
                          ),
                        if (_showTicketPhase2)
                          FadeTransition(
                            opacity: _ticketOpacity2,
                            child: Image.asset(
                              'assets/images/icons/ticket_used.png',
                              width: 44,
                              height: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
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
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `sessionId == '-99'` daily ticket popup (`DefaultPopup`).
Future<void> showRoleplayOpeningDailyTicketDefaultPopup(
  BuildContext context,
  String accessToken,
) => showDailyTicketDefaultPopup(context, accessToken);

/// `sessionId == '0'` no tickets popup (`DefaultPopup`). Primary uses "Okay".
Future<void> showRoleplayOpeningNoTicketsDefaultPopup(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  await DefaultPopup.show(
    context,
    titleText: l10n.noTicketsTitle,
    bodyWidget: Text(
      l10n.noTicketsBody,
      style: theme.bodyLarge?.copyWith(color: Colors.white),
      textAlign: TextAlign.center,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: 'Okay',
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: same as [showRoleplayOpeningNoTicketsDefaultPopup].
Future<void> showRoleplayOpeningNoTicketsDefaultPopupForLab(
  BuildContext context,
) => showRoleplayOpeningNoTicketsDefaultPopup(context);

/// `sessionId == '-10'` survey quest nudge (`DefaultPopup`).
Future<void> showRoleplayOpeningSurveyQuestDefaultPopup(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  final outer = context;
  await DefaultPopup.show(
    context,
    titleText: l10n.noTicketsTitle,
    bodyWidget: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.surveyPromptLine1,
          style: theme.bodyLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        Text(
          l10n.surveyPromptLine2,
          style: theme.bodyLarge?.copyWith(color: const Color(0xFF0CABA8)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.surveyAnswerNowButton,
        onPressed: () {
          RoleplayRouter.pushSurvey(outer);
        },
      ),
      DefaultPopupButton(
        type: DefaultPopupButtonType.text,
        label: l10n.surveyMaybeLater,
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: same as [showRoleplayOpeningSurveyQuestDefaultPopup].
Future<void> showRoleplayOpeningSurveyQuestDefaultPopupForLab(
  BuildContext context,
) => showRoleplayOpeningSurveyQuestDefaultPopup(context);

/// `sessionId == '-20'` push notification quest nudge (`DefaultPopup`).
Future<void> showRoleplayOpeningPushNotificationQuestDefaultPopup(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  final outer = context;
  await DefaultPopup.show(
    context,
    titleText: l10n.noTicketsTitle,
    bodyWidget: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.surveyPromptLine1,
          style: theme.bodyLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        Text(
          l10n.pushTicketPromptLine2,
          style: theme.bodyLarge?.copyWith(color: const Color(0xFF0CABA8)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.pushTicketTurnOnButton,
        onPressed: () {
          if (!outer.mounted) return;
          Navigator.push(
            outer,
            SubScreenRoute(page: const PushAgreementScreen()),
          );
        },
      ),
      DefaultPopupButton(
        type: DefaultPopupButtonType.text,
        label: l10n.surveyMaybeLater,
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: same as [showRoleplayOpeningPushNotificationQuestDefaultPopup].
Future<void> showRoleplayOpeningPushNotificationQuestDefaultPopupForLab(
  BuildContext context,
) => showRoleplayOpeningPushNotificationQuestDefaultPopup(context);

Future<void> shareAppLinkAndSubmitQuestFromOpening({
  required BuildContext context,
  required String questId,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(text: _kOpeningPlayStoreShareUrl),
    );

    final accessToken = await TokenStorage.loadAccessToken();
    if (!context.mounted || accessToken == null) return;

    final result = await SudaApiClient.postUserQuest(
      accessToken: accessToken,
      questId: questId,
    );
    if (!context.mounted) return;
    if (result.completeYn == 'Y') {
      final l10n = AppLocalizations.of(context)!;
      DefaultToast.show(context, l10n.surveySuccessToast);
    }
  } catch (_) {
    // 공유시트/퀘스트 API 실패는 별도 노출 없이 무시한다.
  }
}

/// `sessionId == '-30'` share quest nudge (`DefaultPopup`).
Future<void> showRoleplayOpeningShareQuestDefaultPopup(
  BuildContext context,
  String questId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  final outer = context;
  await DefaultPopup.show(
    context,
    titleText: l10n.noTicketsTitle,
    bodyWidget: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.surveyPromptLine1,
          style: theme.bodyLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        Text(
          l10n.shareTicketPromptLine2,
          style: theme.bodyLarge?.copyWith(color: const Color(0xFF0CABA8)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.shareTicketButton,
        onPressed: () {
          unawaited(
            shareAppLinkAndSubmitQuestFromOpening(
              context: outer,
              questId: questId,
            ),
          );
        },
      ),
      DefaultPopupButton(
        type: DefaultPopupButtonType.text,
        label: l10n.surveyMaybeLater,
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: same popup; quest id fixed to `-30`.
Future<void> showRoleplayOpeningShareQuestDefaultPopupForLab(
  BuildContext context,
) => showRoleplayOpeningShareQuestDefaultPopup(context, '-30');

Future<void> requestInAppReviewAndSubmitQuestFromOpening({
  required BuildContext context,
  required String questId,
}) async {
  try {
    final review = InAppReview.instance;
    final canReview = await review.isAvailable();
    if (!canReview) return;

    await review.requestReview();

    final accessToken = await TokenStorage.loadAccessToken();
    if (!context.mounted || accessToken == null) return;

    final result = await SudaApiClient.postUserQuest(
      accessToken: accessToken,
      questId: questId,
    );
    if (!context.mounted) return;
    if (result.completeYn == 'Y') {
      final l10n = AppLocalizations.of(context)!;
      DefaultToast.show(context, l10n.surveySuccessToast);
    }
  } catch (_) {
    // 인앱리뷰/퀘스트 API 실패는 별도 노출 없이 무시한다.
  }
}

/// `sessionId == '-40'` in-app review quest nudge (`DefaultPopup`).
Future<void> showRoleplayOpeningInAppReviewQuestDefaultPopup(
  BuildContext context,
  String questId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  final outer = context;
  await DefaultPopup.show(
    context,
    titleText: l10n.noTicketsTitle,
    bodyWidget: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.surveyPromptLine1,
          style: theme.bodyLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        Text(
          l10n.reviewTicketPromptLine2,
          style: theme.bodyLarge?.copyWith(color: const Color(0xFF0CABA8)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.reviewTicketButton,
        onPressed: () {
          unawaited(
            requestInAppReviewAndSubmitQuestFromOpening(
              context: outer,
              questId: questId,
            ),
          );
        },
      ),
      DefaultPopupButton(
        type: DefaultPopupButtonType.text,
        label: l10n.surveyMaybeLater,
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: same popup; quest id fixed to `-40`.
Future<void> showRoleplayOpeningInAppReviewQuestDefaultPopupForLab(
  BuildContext context,
) => showRoleplayOpeningInAppReviewQuestDefaultPopup(context, '-40');
