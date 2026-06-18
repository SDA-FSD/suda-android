import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../effects/like_progress_effect.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/series_state_service.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/full_screen_route.dart';
import '../../widgets/main_reregistration_restricted_popup.dart'
    show
        showMainReregistrationRestrictedAuthCheckDefaultPopupForLab,
        showMainReregistrationRestrictedSignInDefaultPopupForLab;
import '../../widgets/daily_ticket_popup.dart'
    show showDailyTicketDefaultPopupForLab;
import '../../widgets/app_scaffold.dart';
import '../profile.dart'
    show showProfileDeleteSavedExpressionDefaultPopupForLab;
import 'announcements.dart'
    show showAnnouncementsPostNoLongerAvailableDefaultPopupForLab;
import '../roleplay/opening.dart'
    show
        showRoleplayOpeningNoTicketsDefaultPopupForLab,
        showRoleplayOpeningSurveyQuestDefaultPopupForLab,
        showRoleplayOpeningPushNotificationQuestDefaultPopupForLab,
        showRoleplayOpeningShareQuestDefaultPopupForLab,
        showRoleplayOpeningInAppReviewQuestDefaultPopupForLab;
import '../roleplay/ending.dart';
import '../roleplay/try_again.dart';
import '../roleplay/result_v2.dart';
import '../first_cefr_level.dart';

/// Lab에서 재현 가능한 `DefaultPopup` 목록.
/// `DefaultPopup` 전환이 완료될 때마다 여기에 **한 항목씩** 추가한다.
///
/// 라벨 규칙: 괄호로 분기/sessionId를 붙이지 않는다.
final List<LabDefaultPopupOption> kLabDefaultPopupOptions = [
  LabDefaultPopupOption(
    id: 'roleplay_opening_daily_ticket',
    label: 'Roleplay opening: Daily ticket',
    show: showDailyTicketDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'home_daily_ticket',
    label: 'Home: Daily ticket',
    show: showDailyTicketDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'roleplay_opening_no_tickets',
    label: 'Roleplay opening: No tickets',
    show: showRoleplayOpeningNoTicketsDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'roleplay_opening_survey_quest',
    label: 'Roleplay opening: Survey quest',
    show: showRoleplayOpeningSurveyQuestDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'roleplay_opening_push_notification_quest',
    label: 'Roleplay opening: Push notification quest',
    show: showRoleplayOpeningPushNotificationQuestDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'roleplay_opening_share_quest',
    label: 'Roleplay opening: Share quest',
    show: showRoleplayOpeningShareQuestDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'roleplay_opening_in_app_review_quest',
    label: 'Roleplay opening: In-app review quest',
    show: showRoleplayOpeningInAppReviewQuestDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'profile_delete_saved_expression',
    label: 'Profile: Delete saved expression',
    show: showProfileDeleteSavedExpressionDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'announcements_post_no_longer_available',
    label: 'Announcements: Post no longer available',
    show: showAnnouncementsPostNoLongerAvailableDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'main_reregistration_restricted_auth_check',
    label: 'Main: Re-registration restricted — auth check',
    show: showMainReregistrationRestrictedAuthCheckDefaultPopupForLab,
  ),
  LabDefaultPopupOption(
    id: 'main_reregistration_restricted_sign_in',
    label: 'Main: Re-registration restricted — sign-in',
    show: showMainReregistrationRestrictedSignInDefaultPopupForLab,
  ),
];

class LabDefaultPopupOption {
  LabDefaultPopupOption({
    required this.id,
    required this.label,
    required this.show,
  });

  final String id;
  final String label;
  final Future<void> Function(BuildContext context) show;
}

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  bool _guarded = false;
  bool _toastIsWarning = false;
  String? _selectedLabDefaultPopupId;
  static const _longToastTestMessage = 'Test Popup, Test Toast, 가나다라마바사아자차카타파하';
  static const _stylePreviewLines = ['말해요!?', 'Talk', 'E sua vez primeiro!'];
  final TextEditingController _rpResultIdController = TextEditingController();
  bool _rpResultTestLoading = false;
  bool _endingTestLoading = false;
  static const int _labEndingSeriesId = 2;

  @override
  void dispose() {
    _rpResultIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (kLabDefaultPopupOptions.isNotEmpty) {
      _selectedLabDefaultPopupId = kLabDefaultPopupOptions.first.id;
    }
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

  Future<void> _showSelectedLabDefaultPopup() async {
    final id = _selectedLabDefaultPopupId;
    if (id == null) return;
    LabDefaultPopupOption? found;
    for (final o in kLabDefaultPopupOptions) {
      if (o.id == id) {
        found = o;
        break;
      }
    }
    if (found == null) return;
    await found.show(context);
  }

  void _showTestToast() {
    final message = 'Test Popup, Test Toast';
    DefaultToast.show(context, message, isError: _toastIsWarning);
  }

  void _showTestToastLong() {
    DefaultToast.show(context, _longToastTestMessage, isError: _toastIsWarning);
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
        if (!mounted) return;
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

  Future<void> _openFirstCefrLevelScreen() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => FirstCefrLevelScreen(
          onComplete: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  void _seedLabS2TryAgainState() {
    SeriesStateService.instance.setSeriesOverview(
      seriesId: 1,
      overview: const RpS2SeriesOverviewDto(
        id: 1,
        title: {'en': 'Lab Series'},
        synopsis: {'en': ''},
        endingTitle: {'en': 'Lab Ending'},
        endingContent: {'en': ''},
        episodes: [
          RpS2SeriesEpisodeDto(
            id: 1,
            title: {'en': 'Lab Episode'},
            summary: {'en': ''},
            briefing: {'en': ''},
            learningFunction: {'en': ''},
          ),
        ],
        bestScoreMap: {},
      ),
    );
    SeriesStateService.instance.setSelectedEpisodeId(1);
  }

  Future<void> _openTryAgainScreen() async {
    _seedLabS2TryAgainState();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleplayTryAgainScreen()),
    );
  }

  Future<void> _openEndingScreen() async {
    if (_endingTestLoading) return;

    setState(() => _endingTestLoading = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        if (!mounted) return;
        DefaultToast.show(context, 'Not signed in', isError: true);
        return;
      }

      final overview = await SudaApiClient.getSeriesOverview(
        accessToken: token,
        seriesId: _labEndingSeriesId,
      );
      SeriesStateService.instance.setSeriesOverview(
        seriesId: _labEndingSeriesId,
        overview: overview,
      );
      final episodes = overview.episodes;
      if (episodes.isNotEmpty) {
        SeriesStateService.instance.setSelectedEpisodeId(episodes.last.id);
      }
      SeriesStateService.instance.setCachedUserHistory(
        const RpS2UserHistoryDto(
          id: -1,
          seriesId: _labEndingSeriesId,
          userStarRating: 0,
        ),
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoleplayEndingScreen()),
      );
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Open Ending failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _endingTestLoading = false);
    }
  }

  Future<void> _openTryAgainReportScreen() async {
    if (!mounted) return;
    await RoleplayRouter.pushTryAgainReport(context);
  }

  Widget _buildLabScreenButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0CABA8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
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
              'First CEFR Level',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _openFirstCefrLevelScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Open First CEFR Level'),
              ),
            ),
            _buildSectionDivider(),
            Text(
              'Roleplay Ending',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: _endingTestLoading ? 'Loading…' : 'Open Ending',
              onPressed: () => unawaited(_openEndingScreen()),
            ),
            _buildSectionDivider(),
            Text(
              'Roleplay Try Again',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildLabScreenButton(
              label: 'Open Try Again Screen',
              onPressed: () => unawaited(_openTryAgainScreen()),
            ),
            const SizedBox(height: 8),
            _buildLabScreenButton(
              label: 'Open Try Again Report Screen',
              onPressed: () => unawaited(_openTryAgainReportScreen()),
            ),
            _buildSectionDivider(),
            Text(
              'Default Popup Test',
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (kLabDefaultPopupOptions.isEmpty) ...[
              Text(
                'No migrated DefaultPopup yet. Entries are added in '
                '`kLabDefaultPopupOptions` after each migration.',
                style: theme.bodyMedium?.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ] else ...[
              InputDecorator(
                decoration: InputDecoration(
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedLabDefaultPopupId,
                    dropdownColor: const Color(0xFF1E1E1E),
                    hint: Text(
                      'Select popup',
                      style: theme.bodyLarge?.copyWith(
                        color: const Color(0xFF635F5F),
                      ),
                    ),
                    style: theme.bodyLarge?.copyWith(color: Colors.white),
                    items: [
                      for (final o in kLabDefaultPopupOptions)
                        DropdownMenuItem<String>(
                          value: o.id,
                          child: Text(o.label),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedLabDefaultPopupId = v),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: kLabDefaultPopupOptions.isEmpty
                    ? null
                    : () => unawaited(_showSelectedLabDefaultPopup()),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showTestToastLong,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Show Toast(Long Text)'),
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
                hintStyle: theme.bodyMedium?.copyWith(
                  color: const Color(0xFF635F5F),
                ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _rpResultTestLoading
                    ? null
                    : _openRpResultV2FromInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _rpResultTestLoading ? 'Loading...' : 'RP Result Test',
                ),
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
