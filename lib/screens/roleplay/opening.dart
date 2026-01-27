import 'package:flutter/material.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../services/roleplay_state_service.dart';
import '../../utils/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../services/token_refresh_service.dart';
import '../../routes/roleplay_router.dart';
import '../../utils/suda_json_util.dart';

/// Roleplay Opening Screen (Full Screen)
/// 
/// Roleplay 시작 전 오프닝 화면
class RoleplayOpeningScreen extends StatelessWidget {
  final bool showCloseButton;

  const RoleplayOpeningScreen({
    super.key,
    this.showCloseButton = true,
  });

  Future<void> _navigateToPlaying(BuildContext context) async {
    await TokenRefreshService.instance.refreshIfNeeded();
    // 1. 마이크 권한 확인
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      // 권한 허용 시 playing으로 전환
      if (!context.mounted) return;
      RoleplayRouter.replaceWithPlaying(context);
    } else {
      // 권한 거부 시 안내
      if (!context.mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      AppToast.show(context, l10n.microphonePermissionDenied);
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
        showCloseButton: showCloseButton,
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
            ElevatedButton(
              onPressed: () => _navigateToPlaying(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0CABA8),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                elevation: 0,
              ),
              child: const Text("Let's Start"),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
