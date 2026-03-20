import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/appsflyer_service.dart';
import 'webview_screen.dart';
import '../utils/default_toast.dart';
import '../utils/sub_screen_route.dart';

class AgreementScreen extends StatefulWidget {
  final String accessToken;
  final VoidCallback onAgreementComplete;

  const AgreementScreen({
    super.key,
    required this.accessToken,
    required this.onAgreementComplete,
  });

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _isTermsAgreed = false;
  bool _isPrivacyAgreed = false;
  bool _isSubmitting = false;

  void _navigateToWebView(String title, String url) {
    Navigator.push(
      context,
      SubScreenRoute(
        page: WebViewScreen(title: title, url: url),
      ),
    );
  }

  Future<void> _handleAgreement() async {
    if (!_isTermsAgreed || !_isPrivacyAgreed || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await SudaApiClient.updateAgreement(accessToken: widget.accessToken);
      await AppsflyerService.logEvent('terms_agreed');
      widget.onAgreementComplete();
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final isAllAgreed = _isTermsAgreed && _isPrivacyAgreed;

    return PopScope(
      canPop: false, // Full Screen 규칙: 시스템 뒤로가기 제한 (또는 앱 종료 처리 가능)
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1) Heading
                Text(
                  l10n.agreementHeading,
                  textAlign: TextAlign.center,
                  style: theme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 48),

                // 2) Terms Agreement
                _buildAgreementRow(
                  label: l10n.agreementTermsLabel,
                  linkLabel: l10n.agreementDetailsLink,
                  isChecked: _isTermsAgreed,
                  onChanged: (val) => setState(() => _isTermsAgreed = val!),
                  onLinkTap: () => _navigateToWebView(
                    l10n.agreementTermsTitle,
                    'https://sudatalk.kr/public/app/terms',
                  ),
                ),
                const SizedBox(height: 12),

                // 3) Privacy Agreement
                _buildAgreementRow(
                  label: l10n.agreementPrivacyLabel,
                  linkLabel: l10n.agreementDetailsLink,
                  isChecked: _isPrivacyAgreed,
                  onChanged: (val) => setState(() => _isPrivacyAgreed = val!),
                  onLinkTap: () => _navigateToWebView(
                    l10n.agreementPrivacyTitle,
                    'https://sudatalk.kr/public/app/privacy',
                  ),
                ),
                const SizedBox(height: 48),

                // 4) Confirm Button
                ElevatedButton(
                  onPressed: isAllAgreed && !_isSubmitting ? _handleAgreement : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllAgreed ? const Color(0xFF0CABA8) : const Color(0xFF353535),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF353535),
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.agreementButtonConfirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementRow({
    required String label,
    required String linkLabel,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onLinkTap,
  }) {
    final theme = Theme.of(context).textTheme;
    return Row(
      children: [
        Theme(
          data: ThemeData(unselectedWidgetColor: Colors.grey),
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: const Color(0xFF0CABA8),
            checkColor: Colors.white,
          ),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                label,
                style: theme.bodySmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onLinkTap,
                child: Text(
                  linkLabel,
                  style: theme.bodySmall?.copyWith(
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 간단한 플랫폼 분기를 위한 헬퍼 (import 'dart:io' 대신 사용 권장되는 방식이나 여기서는 생략)
class RoundedRectanglePlatform {
  static bool get isAndroid => true; // 프로젝트 컨텍스트상 안드로이드 중심
}
