import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../effects/like_progress_effect.dart';
import '../../l10n/app_localizations.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/full_screen_route.dart';
import '../../widgets/app_content_dialog.dart';
import '../../widgets/app_scaffold.dart';
import '../roleplay/result_v2.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  bool _guarded = false;
  bool _showOkayButton = false;
  bool _toastIsWarning = false;
  static const _stylePreviewLines = ['말해요!?', 'Talk', 'E sua vez primeiro!'];
  final TextEditingController _rpResultIdController = TextEditingController();
  bool _rpResultTestLoading = false;

  @override
  void dispose() {
    _rpResultIdController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guarded) return;
    _guarded = true;

    if (!AppConfig.isDev) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _showTestPopup() async {
    final theme = Theme.of(context).textTheme;
    final textStyle = theme.bodyLarge?.copyWith(color: Colors.white);

    final message = [
      'Test Popup, Test Popup, Test Popup,',
      'Test Popup, Test Popup, Test Popup,',
    ].join('\n');

    await AppContentDialog.show(
      context,
      content: Center(
        child: Text(message, style: textStyle, textAlign: TextAlign.center),
      ),
      showOkayButton: _showOkayButton,
      barrierDismissible: true,
    );
  }

  void _showTestToast() {
    final message = 'Test Popup, Test Toast';
    DefaultToast.show(context, message, isError: _toastIsWarning);
  }

  Future<void> _openRpResultV2FromInput() async {
    if (_rpResultTestLoading) return;
    final raw = _rpResultIdController.text.trim();
    final resultId = int.tryParse(raw);
    if (resultId == null || resultId <= 0) {
      DefaultToast.show(context, 'Invalid resultId', isError: true);
      return;
    }

    setState(() => _rpResultTestLoading = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        DefaultToast.show(context, 'Not signed in', isError: true);
        return;
      }
      final dto = await SudaApiClient.getRoleplayResult(
        accessToken: token,
        resultId: resultId,
      );
      RoleplayStateService.instance.setCachedResult(dto);
      if (!mounted) return;

      await Navigator.push(
        context,
        FullScreenRoute(
          transition: FullScreenTransition.bottomUp,
          settings: RouteSettings(name: RoleplayResultScreenV2.routeName),
          page: Container(
            color: const Color(0xFF0CABA8), // 전환 중 배경 플리커 완화
            child: const RoleplayResultScreenV2(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'RP Result Test failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _rpResultTestLoading = false);
    }
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(height: 1, thickness: 1, color: Color(0xFF353535)),
    );
  }

  Widget _buildStylePreview(
    BuildContext context, {
    required String label,
    required TextStyle? style,
  }) {
    final theme = Theme.of(context).textTheme;
    final previewStyle = style?.copyWith(color: Colors.white);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.labelSmall?.copyWith(color: const Color(0xFF80D7CF)),
          ),
          const SizedBox(height: 8),
          for (final line in _stylePreviewLines) ...[
            Text(line, style: previewStyle),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return AppScaffold(
      centerTitle: l10n.settingsFsdLaboratory,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Popup Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _showOkayButton,
              onChanged: (v) => setState(() => _showOkayButton = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF0CABA8),
              checkColor: Colors.white,
              title: Text(
                'Show Okay button',
                style: theme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showTestPopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Show Popup'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Default Toast Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _toastIsWarning,
              onChanged: (v) => setState(() => _toastIsWarning = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF0CABA8),
              checkColor: Colors.white,
              title: Text(
                'Warning (red)',
                style: theme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showTestToast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Show Toast'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'RP Result Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rpResultIdController,
              keyboardType: TextInputType.number,
              style: theme.bodyLarge?.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'resultId',
                hintStyle: theme.bodyMedium?.copyWith(color: const Color(0xFF635F5F)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF353535)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF353535)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF80D7CF)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _rpResultTestLoading ? null : _openRpResultV2FromInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(_rpResultTestLoading ? 'Loading...' : 'RP Result Test'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Like Effect Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _playLikeEffect(
                  const LikeProgressEffectParams(
                    asIsLikePoint: 36,
                    toBeLikePoint: 72,
                    asIsLevel: 36,
                    toBeLevel: 36,
                    asIsProgress: 25,
                    toBeProgress: 75,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Simple Like Effect'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _playLikeEffect(
                  const LikeProgressEffectParams(
                    asIsLikePoint: 36,
                    toBeLikePoint: 172,
                    asIsLevel: 36,
                    toBeLevel: 38,
                    asIsProgress: 25,
                    toBeProgress: 75,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Levelup Like Effect'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Style',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildStylePreview(
              context,
              label: 'headlineLarge',
              style: theme.headlineLarge,
            ),
            _buildStylePreview(
              context,
              label: 'headlineMedium',
              style: theme.headlineMedium,
            ),
            _buildStylePreview(
              context,
              label: 'headlineSmall',
              style: theme.headlineSmall,
            ),
            _buildStylePreview(
              context,
              label: 'bodyLarge',
              style: theme.bodyLarge,
            ),
            _buildStylePreview(
              context,
              label: 'bodyMedium',
              style: theme.bodyMedium,
            ),
            _buildStylePreview(
              context,
              label: 'bodySmall',
              style: theme.bodySmall,
            ),
            _buildStylePreview(
              context,
              label: 'labelSmall',
              style: theme.labelSmall,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _playLikeEffect(LikeProgressEffectParams params) async {
    await LikeProgressEffect.play(context, params: params);
  }
}
