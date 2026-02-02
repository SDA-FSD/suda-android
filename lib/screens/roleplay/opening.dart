import 'package:flutter/material.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../services/token_refresh_service.dart';
import '../../routes/roleplay_router.dart';
import '../../utils/suda_json_util.dart';

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

  void _restoreButton() {
    if (mounted) setState(() => _isLoading = false);
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
        AppToast.show(context, 'Authentication required.');
        _restoreButton();
        return;
      }

      final roleplayId = RoleplayStateService.instance.roleplayId;
      final roleId = RoleplayStateService.instance.roleId;
      if (roleplayId == null || roleId == null) {
        AppToast.show(context, 'Cannot start roleplay');
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
          AppToast.show(context, 'Cannot start roleplay');
          _restoreButton();
          return;
        }
        RoleplayStateService.instance.setSessionId(sessionId);
        RoleplayStateService.instance.setSession(session);
        RoleplayRouter.replaceWithPlaying(context);
      } catch (e) {
        if (!context.mounted) return;
        if (e.toString().contains('HTTP 500')) {
          AppToast.show(context, 'Cannot start roleplay');
          _restoreButton();
          return;
        }
        AppToast.show(context, 'Cannot start roleplay');
        _restoreButton();
      }
    } else {
      // 권한 거부 시 안내
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      AppToast.show(context, l10n.microphonePermissionDenied);
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
