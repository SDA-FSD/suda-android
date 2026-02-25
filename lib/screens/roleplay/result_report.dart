import 'package:flutter/material.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../services/roleplay_state_service.dart';
import '../../utils/default_toast.dart';

/// Roleplay Result Report Screen (Sub Screen)
///
/// Result 화면에서만 진입. 사용자가 느낀 불편함을 수집하는 용도.
/// 내부 표현·구성은 failed_report와 동일. Send 시 POST /v1/roleplays/results/{roleplayResultId}/report 사용.
/// 성공(200) 시 스크린 닫고 부모 Result에서 Report 문구 숨김. Android 백버튼 또는 X 버튼 시 Result로 복귀.
class RoleplayResultReportScreen extends StatefulWidget {
  static const String routeName = '/roleplay/result_report';

  const RoleplayResultReportScreen({super.key});

  @override
  State<RoleplayResultReportScreen> createState() => _RoleplayResultReportScreenState();
}

class _RoleplayResultReportScreenState extends State<RoleplayResultReportScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateSubmitState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSubmitState);
    _controller.dispose();
    super.dispose();
  }

  void _updateSubmitState() {
    final canSubmit = _controller.text.trim().isNotEmpty;
    if (canSubmit != _canSubmit) {
      setState(() => _canSubmit = canSubmit);
    }
  }

  Future<void> _handleSend() async {
    if (!_canSubmit || _isSubmitting) return;

    final resultId = RoleplayStateService.instance.cachedResult?.id;
    if (resultId == null) {
      if (mounted) {
        DefaultToast.show(
          context,
          'No result id',
          isError: true,
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.sendResultReport(
          accessToken: token,
          roleplayResultId: resultId,
          content: _controller.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(
          context,
          'Failed to send report: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {},
      child: RoleplayScaffold(
        showCloseButton: true,
        onClose: () => Navigator.of(context).pop(),
        title: l10n.reportTitle,
        body: Column(
          children: [
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: theme.bodyLarge?.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.feedbackPlaceholder,
                    hintStyle: theme.bodyLarge?.copyWith(
                      color: const Color(0xFF8D8D8D),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  autofocus: true,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_canSubmit && !_isSubmitting) ? _handleSend : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF353535),
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.feedbackSend),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        footer: const SizedBox.shrink(),
      ),
    );
  }
}
