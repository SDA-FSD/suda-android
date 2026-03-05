import 'package:flutter/material.dart';
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
import '../../widgets/app_content_dialog.dart';
import '../../utils/sub_screen_route.dart';
import '../setting/push_agreement.dart';

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
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=kr.sudatalk.app';

  void _restoreButton() {
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _shareAppLinkAndSubmitQuest({
    required BuildContext context,
    required String questId,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: _playStoreUrl),
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

  Future<void> _requestInAppReviewAndSubmitQuest({
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

  Future<void> _claimDailyTicket(
      BuildContext context, String accessToken) async {
    try {
      final result = await SudaApiClient.claimDailyTicket(
        accessToken: accessToken,
      );
      if (!context.mounted) return;
      if (result.completeYn == 'Y') {
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.surveySuccessToast);
      }
    } catch (_) {
      // 실패 시 별도 처리 없음
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
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context).textTheme;
          await AppContentDialog.show(
            context,
            content: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      l10n.dailyTicketTitle,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      l10n.dailyTicketContent,
                      style: theme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            showOkayButton: true,
            okayButtonLabel: l10n.dailyTicketButton,
            onOkayPressed: () => _claimDailyTicket(context, accessToken),
          );
          _restoreButton();
          return;
        }
        if (sessionId == '0') {
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context).textTheme;
          await AppContentDialog.show(
            context,
            content: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      l10n.noTicketsTitle,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Text(
                      l10n.noTicketsBody,
                      style: theme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            showOkayButton: true,
          );
          _restoreButton();
          return;
        }
        if (sessionId == '-10') {
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context).textTheme;
          await AppContentDialog.show(
            context,
            content: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.noTicketsTitle,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.surveyPromptLine1,
                          style: theme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          l10n.surveyPromptLine2,
                          style: theme.bodyLarge?.copyWith(
                            color: const Color(0xFF0CABA8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.64,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              RoleplayRouter.pushSurvey(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CABA8),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 18,
                              ),
                              elevation: 0,
                            ),
                            child: Text(l10n.surveyAnswerNowButton),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.surveyMaybeLater,
                            style: theme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            showOkayButton: false,
          );
          _restoreButton();
          return;
        }
        if (sessionId == '-20') {
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context).textTheme;
          await AppContentDialog.show(
            context,
            content: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.noTicketsTitle,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.surveyPromptLine1,
                          style: theme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          l10n.pushTicketPromptLine2,
                          style: theme.bodyLarge?.copyWith(
                            color: const Color(0xFF0CABA8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.64,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                SubScreenRoute(
                                  page: const PushAgreementScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CABA8),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 18,
                              ),
                              elevation: 0,
                            ),
                            child: Text(l10n.pushTicketTurnOnButton),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.surveyMaybeLater,
                            style: theme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            showOkayButton: false,
          );
          _restoreButton();
          return;
        }
        if (sessionId == '-30') {
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context).textTheme;
          await AppContentDialog.show(
            context,
            content: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.noTicketsTitle,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.surveyPromptLine1,
                          style: theme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          l10n.shareTicketPromptLine2,
                          style: theme.bodyLarge?.copyWith(
                            color: const Color(0xFF0CABA8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.64,
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _shareAppLinkAndSubmitQuest(
                                context: context,
                                questId: sessionId,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CABA8),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 18,
                              ),
                              elevation: 0,
                            ),
                            child: Text(l10n.shareTicketButton),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.surveyMaybeLater,
                            style: theme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            showOkayButton: false,
          );
          _restoreButton();
          return;
        }
        if (sessionId == '-40') {
          final l10n = AppLocalizations.of(context)!;
          final theme = Theme.of(context).textTheme;
          await AppContentDialog.show(
            context,
            content: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.noTicketsTitle,
                      style: theme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.surveyPromptLine1,
                          style: theme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          l10n.reviewTicketPromptLine2,
                          style: theme.bodyLarge?.copyWith(
                            color: const Color(0xFF0CABA8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.64,
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _requestInAppReviewAndSubmitQuest(
                                context: context,
                                questId: sessionId,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CABA8),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 18,
                              ),
                              elevation: 0,
                            ),
                            child: Text(l10n.reviewTicketButton),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            l10n.surveyMaybeLater,
                            style: theme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            showOkayButton: false,
          );
          _restoreButton();
          return;
        }
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

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // opening screen이 이미 pop되었으므로 overview로 자동으로 돌아감
        // Navigator.pop()이 자동으로 처리함
      },
      child: RoleplayScaffold(
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
                  fontWeight: FontWeight.w300,
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
              Text(
                SudaJsonUtil.localizedText(selectedRole?.scenario),
                style: theme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Let's Start"),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
