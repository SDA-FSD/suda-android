import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../widgets/roleplay_configuration_panel.dart';
import '../../widgets/roleplay_scaffold.dart';

/// Roleplay Try Again Report Screen (Sub Screen)
///
/// Try Again 화면에서만 진입. 사용자가 느낀 불편함을 수집하는 용도.
/// Feedback 스크린과 동일한 본문 구조(입력창 + 제출 버튼). sendFeedback API 사용.
/// 성공 시 feedbackSuccess 토스트 후 pop(true). Android 백버튼 또는 X 버튼 시 Try Again으로 복귀.
class RoleplayTryAgainReportScreen extends StatefulWidget {
  static const String routeName = '/roleplay/try_again_report';

  const RoleplayTryAgainReportScreen({super.key});

  @override
  State<RoleplayTryAgainReportScreen> createState() =>
      _RoleplayTryAgainReportScreenState();
}

class _RoleplayTryAgainReportScreenState
    extends State<RoleplayTryAgainReportScreen> {
  static const Color _gradientBottom = Color(0xFF076664);
  static const Color _gradientTop = Color(0xFF032929);

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

    setState(() => _isSubmitting = true);

    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.sendFeedback(
          accessToken: token,
          content: _controller.text.trim(),
        );

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          DefaultToast.show(context, l10n.feedbackSuccess);
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

  Widget _buildGlazedInputArea(TextTheme theme, String hintText) {
    const radius = RoleplayConfigurationPanel.panelBorderRadius;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.36),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                style: theme.bodyLarge?.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hintText,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _gradientTop),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_gradientBottom, _gradientTop],
                  ),
                ),
              ),
            ),
          ),
          RoleplayScaffold(
            backgroundColor: Colors.transparent,
            showCloseButton: true,
            onClose: () => Navigator.of(context).pop(),
            title: l10n.reportTitle,
            body: Column(
              children: [
                const SizedBox(height: 15),
                Expanded(
                  child: _buildGlazedInputArea(
                    theme,
                    l10n.feedbackPlaceholder,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_canSubmit && !_isSubmitting) ? _handleSend : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0CABA8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF353535),
                        disabledForegroundColor: Colors.white38,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
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
                ),
                const SizedBox(height: 24),
              ],
            ),
            footer: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
