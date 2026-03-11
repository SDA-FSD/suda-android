import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../services/token_storage.dart';
import '../../services/auth_service.dart';
import '../../services/suda_api_client.dart';
import '../../utils/default_toast.dart';
import '../../utils/sub_screen_route.dart';
import '../../widgets/app_scaffold.dart';
import 'account.dart';
import 'language_level.dart';
import 'push_agreement.dart';
import 'feedback.dart';
import '../webview_screen.dart';
import 'open_source_license.dart';

class SettingScreen extends StatelessWidget {
  final VoidCallback? onSignOut;
  final UserDto? user;
  final ValueChanged<UserDto>? onUserUpdated;
  /// PushAgreement 등에서 열 때 항상 최신 user를 쓰기 위한 콜백 (없으면 user 사용)
  final UserDto? Function()? getCurrentUser;

  const SettingScreen({
    super.key,
    this.onSignOut,
    this.user,
    this.onUserUpdated,
    this.getCurrentUser,
  });

  void _navigateToSubScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      SubScreenRoute(page: screen),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // 서버 로그아웃은 best-effort로 시도하고, 실패해도 무시한다.
    try {
      final refreshToken = await TokenStorage.loadRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final deviceId = await TokenStorage.getDeviceId();
        await SudaApiClient.logout(
          refreshToken: refreshToken,
          deviceId: deviceId,
        );
      }
    } catch (_) {}

    try {
      await AuthService.signOut();
      await TokenStorage.clearTokens();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        onSignOut?.call();
      }
    } catch (error) {
      if (context.mounted) {
        DefaultToast.show(context, 'Logout failed: $error', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      centerTitle: l10n.settingsTitle,
      usePadding: false, // 메뉴 전체 너비 클릭을 위해 본문 패딩 제거
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuItem(
            context,
            l10n.settingsAccount,
            () => _navigateToSubScreen(context, AccountScreen(onSignOut: onSignOut)),
          ),
          _buildMenuItem(
            context,
            l10n.settingsNotification,
            () => _navigateToSubScreen(
              context,
              PushAgreementScreen(
                user: getCurrentUser?.call() ?? user,
                onUserUpdated: onUserUpdated,
              ),
            ),
          ),
          _buildMenuItem(
            context,
            l10n.settingsLanguageLevel,
            () => _navigateToSubScreen(context, LanguageLevelScreen(user: user)),
          ),
          _buildMenuItem(
            context,
            l10n.settingsFeedback,
            () => _navigateToSubScreen(context, const FeedbackScreen()),
          ),
          _buildMenuItem(
            context,
            l10n.settingsSignOut,
            () => _handleLogout(context),
          ),
          const Spacer(),
          // 하단 푸터 메뉴 (Privacy, Terms, Open source) — 위로 올림
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildFooterMenuItem(
                    context,
                    l10n.settingsPrivacy,
                    () {
                      _navigateToSubScreen(
                        context,
                        WebViewScreen(
                          url: 'https://sudatalk.kr/public/app/privacy',
                          title: l10n.settingsPrivacy,
                        ),
                      );
                    },
                  ),
                  _buildFooterMenuItem(
                    context,
                    l10n.settingsTerms,
                    () {
                      _navigateToSubScreen(
                        context,
                        WebViewScreen(
                          url: 'https://sudatalk.kr/public/app/terms',
                          title: l10n.settingsTerms,
                        ),
                      );
                    },
                  ),
                  _buildFooterMenuItem(
                    context,
                    l10n.settingsOpenSource,
                    () => _navigateToSubScreen(context, const OpenSourceLicenseScreen()),
                  ),
                ],
              ),
            ),
          ),
          // 버전 정보 (caption보다 작은 크기, 흰색, 중앙 정렬)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: Text(
                'v ${AppConfig.appVersion}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String text, VoidCallback onTap) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF353535),
        highlightColor: const Color(0xFF353535),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            text,
            style: theme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterMenuItem(BuildContext context, String text, VoidCallback onTap) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: theme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }
}
