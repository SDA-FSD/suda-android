import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/app_toast.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
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
      setState(() {
        _canSubmit = canSubmit;
      });
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
          AppToast.show(
            context,
            l10n.feedbackSuccess,
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Failed to send feedback: $e',
          backgroundColor: Colors.red,
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

    return AppScaffold(
      centerTitle: l10n.settingsFeedback,
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
                    color: const Color(0xFF8D8D8D), // 흰색과 1a1a1a 사잇값 (약간 흐린 회색)
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
          const SizedBox(height: 24), // 하단 여백 추가
        ],
      ),
    );
  }
}
