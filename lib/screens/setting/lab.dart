import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../effects/like_progress_effect.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../models/user_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/rank_like_overlay.dart';
import '../../services/series_state_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/default_toast.dart';
import '../../utils/sub_screen_route.dart';
import '../../widgets/main_reregistration_restricted_popup.dart'
    show
        showMainReregistrationRestrictedAuthCheckDefaultPopupForLab,
        showMainReregistrationRestrictedSignInDefaultPopupForLab;
import '../../widgets/energy_info_popup.dart' show showEnergyPopupForLab;
import '../../widgets/app_scaffold.dart';
import '../profile.dart'
    show showProfileDeleteSavedExpressionDefaultPopupForLab;
import 'announcements.dart'
    show showAnnouncementsPostNoLongerAvailableDefaultPopupForLab;
import '../roleplay/try_again.dart';
import '../onboarding/first_cefr_level.dart';
import '../onboarding/first_profile_image.dart';
import '../series/cefr_level_up_popup.dart'
    show showCefrLevelUpPopupForLab;
import '../onboarding/tutorial/intro.dart';
import '../onboarding/tutorial/roleplay.dart';
import '../paywall/paywall.dart';
import '../paywall/paywall_completed.dart';
import '../rank/ranking.dart';
import '../reward/reward_unboxing.dart';
import '../../models/character_reward_models.dart';
import '../../utils/paywall_impression_screen.dart';

/// Lab에서 재현 가능한 `DefaultPopup` 목록.
/// `DefaultPopup` 전환이 완료될 때마다 여기에 **한 항목씩** 추가한다.
///
/// 라벨 규칙: 괄호로 분기/sessionId를 붙이지 않는다.
final List<LabDefaultPopupOption> kLabDefaultPopupOptions = [
  LabDefaultPopupOption(
    id: 'series_cefr_level_up',
    label: 'Series: Next CEFR level',
    show: showCefrLevelUpPopupForLab,
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

class _LabTutorialLocaleOption {
  const _LabTutorialLocaleOption({
    required this.id,
    required this.locale,
    required this.label,
  });

  final String id;
  final Locale locale;
  final String label;
}

/// Lab 튜토리얼 미리보기 언어. 폴백 전용 `es`/`zh`는 제외(21개).
const List<_LabTutorialLocaleOption> _kLabTutorialLocaleOptions = [
  _LabTutorialLocaleOption(id: 'en', locale: Locale('en'), label: 'en'),
  _LabTutorialLocaleOption(id: 'ko', locale: Locale('ko'), label: 'ko'),
  _LabTutorialLocaleOption(id: 'pt', locale: Locale('pt'), label: 'pt'),
  _LabTutorialLocaleOption(
    id: 'es_419',
    locale: Locale('es', '419'),
    label: 'es_419',
  ),
  _LabTutorialLocaleOption(id: 'ja', locale: Locale('ja'), label: 'ja'),
  _LabTutorialLocaleOption(
    id: 'zh_Hans',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    label: 'zh_Hans',
  ),
  _LabTutorialLocaleOption(
    id: 'zh_Hant',
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    label: 'zh_Hant',
  ),
  _LabTutorialLocaleOption(id: 'fr', locale: Locale('fr'), label: 'fr'),
  _LabTutorialLocaleOption(id: 'de', locale: Locale('de'), label: 'de'),
  _LabTutorialLocaleOption(id: 'it', locale: Locale('it'), label: 'it'),
  _LabTutorialLocaleOption(id: 'vi', locale: Locale('vi'), label: 'vi'),
  _LabTutorialLocaleOption(id: 'th', locale: Locale('th'), label: 'th'),
  _LabTutorialLocaleOption(id: 'id', locale: Locale('id'), label: 'id'),
  _LabTutorialLocaleOption(id: 'ms', locale: Locale('ms'), label: 'ms'),
  _LabTutorialLocaleOption(id: 'fil', locale: Locale('fil'), label: 'fil'),
  _LabTutorialLocaleOption(id: 'hi', locale: Locale('hi'), label: 'hi'),
  _LabTutorialLocaleOption(id: 'ar', locale: Locale('ar'), label: 'ar'),
  _LabTutorialLocaleOption(id: 'tr', locale: Locale('tr'), label: 'tr'),
  _LabTutorialLocaleOption(id: 'ru', locale: Locale('ru'), label: 'ru'),
  _LabTutorialLocaleOption(id: 'pl', locale: Locale('pl'), label: 'pl'),
  _LabTutorialLocaleOption(id: 'nl', locale: Locale('nl'), label: 'nl'),
];

class LabScreen extends StatefulWidget {
  final VoidCallback? onSignOut;

  const LabScreen({super.key, this.onSignOut});

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  bool _guarded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guarded) return;
    _guarded = true;

    if (!AppConfig.isDev && !kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    }
  }

  void _openGroup(Widget page) {
    Navigator.push(context, SubScreenRoute(page: page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      centerTitle: l10n.settingsFsdLaboratory,
      body: ListView(
        children: [
          _LabIndexRow(
            label: 'Onboarding',
            onTap: () => _openGroup(const _LabOnboardingPage()),
          ),
          _LabIndexRow(
            label: 'Roleplay',
            onTap: () => _openGroup(const _LabRoleplayPage()),
          ),
          _LabIndexRow(
            label: 'Monetization',
            onTap: () => _openGroup(const _LabMonetizationPage()),
          ),
          _LabIndexRow(
            label: 'Ranking',
            onTap: () => _openGroup(const _LabRankingPage()),
          ),
          _LabIndexRow(
            label: 'Feedback',
            onTap: () => _openGroup(const _LabFeedbackPage()),
          ),
          _LabIndexRow(
            label: 'Style',
            onTap: () => _openGroup(const _LabStylePage()),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFF353535)),
          const SizedBox(height: 8),
          _LabIndexRow(
            label: 'Account',
            onTap: () => _openGroup(_LabAccountPage(onSignOut: widget.onSignOut)),
          ),
        ],
      ),
    );
  }
}

class _LabIndexRow extends StatelessWidget {
  const _LabIndexRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}

class _LabActionRow extends StatelessWidget {
  const _LabActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.bodyLarge?.copyWith(
                  color: enabled ? Colors.white : const Color(0xFF635F5F),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: enabled ? const Color(0xFF9E9E9E) : const Color(0xFF353535),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabPage extends StatelessWidget {
  const _LabPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      centerTitle: title,
      body: ListView(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            children[i],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

InputDecoration _labDropdownDecoration() {
  return InputDecoration(
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
  );
}

class _LabOnboardingPage extends StatefulWidget {
  const _LabOnboardingPage();

  @override
  State<_LabOnboardingPage> createState() => _LabOnboardingPageState();
}

class _LabOnboardingPageState extends State<_LabOnboardingPage> {
  String _selectedTutorialLocaleId = 'en';

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

  Future<void> _openFirstProfileImageScreen() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => FirstProfileImageScreen(
          onComplete: (_) => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  Future<void> _openTutorialIntroScreen() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const _TutorialIntroPreview(),
      ),
    );
  }

  Future<void> _openTutorialPreview() async {
    _LabTutorialLocaleOption? found;
    for (final o in _kLabTutorialLocaleOptions) {
      if (o.id == _selectedTutorialLocaleId) {
        found = o;
        break;
      }
    }
    if (found == null || !mounted) return;
    await RoleplayRouter.pushTutorialPreview(context, locale: found.locale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return _LabPage(
      title: 'Onboarding',
      children: [
        _LabActionRow(
          label: 'Open First CEFR Level',
          onTap: () => unawaited(_openFirstCefrLevelScreen()),
        ),
        _LabActionRow(
          label: 'Open First Profile Image',
          onTap: () => unawaited(_openFirstProfileImageScreen()),
        ),
        _LabActionRow(
          label: 'Open Tutorial Intro',
          onTap: () => unawaited(_openTutorialIntroScreen()),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: _labDropdownDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedTutorialLocaleId,
              dropdownColor: const Color(0xFF1E1E1E),
              style: theme.bodyLarge?.copyWith(color: Colors.white),
              items: [
                for (final o in _kLabTutorialLocaleOptions)
                  DropdownMenuItem<String>(
                    value: o.id,
                    child: Text(o.label),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedTutorialLocaleId = v);
              },
            ),
          ),
        ),
        _LabActionRow(
          label: 'Open Tutorial',
          onTap: () => unawaited(_openTutorialPreview()),
        ),
      ],
    );
  }
}

class _LabRoleplayPage extends StatelessWidget {
  const _LabRoleplayPage();

  void _seedLabS2TryAgainState() {
    SeriesStateService.instance.setSeriesOverview(
      seriesId: 1,
      overview: const RpS2SeriesOverviewDto(
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

  Future<void> _openTryAgainScreen(BuildContext context) async {
    _seedLabS2TryAgainState();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoleplayTryAgainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LabPage(
      title: 'Roleplay',
      children: [
        _LabActionRow(
          label: 'Open Try Again Screen',
          onTap: () => unawaited(_openTryAgainScreen(context)),
        ),
        _LabActionRow(
          label: 'Open Try Again Report Screen',
          onTap: () => unawaited(RoleplayRouter.pushTryAgainReport(context)),
        ),
      ],
    );
  }
}

class _LabMonetizationPage extends StatefulWidget {
  const _LabMonetizationPage();

  @override
  State<_LabMonetizationPage> createState() => _LabMonetizationPageState();
}

class _LabMonetizationPageState extends State<_LabMonetizationPage> {
  bool _energyPopupPlaying = false;
  bool _energyPopupUnlimited = false;
  bool _energyPopupSubscribed = false;
  bool _energyPopupShowUnlimited = false;
  bool _energyPopupShowCapacity6 = false;
  bool _energyPopupShowCapacity7 = false;
  bool _energyPopupForceGoPremium = false;
  bool _energyPopupForceEnablePush = false;
  final TextEditingController _energyPopupCountController =
      TextEditingController(text: '3');

  @override
  void dispose() {
    _energyPopupCountController.dispose();
    super.dispose();
  }

  int _parseEnergyPopupCount() {
    final parsed = int.tryParse(_energyPopupCountController.text.trim());
    if (parsed == null) return 0;
    return parsed.clamp(0, 5);
  }

  Future<void> _showEnergyPopupTest() async {
    final count = _parseEnergyPopupCount();
    if (_energyPopupCountController.text.trim() != '$count') {
      _energyPopupCountController.text = '$count';
    }
    await showEnergyPopupForLab(
      context,
      playing: _energyPopupPlaying,
      unlimited: _energyPopupUnlimited,
      energyCount: count,
      subscribed: _energyPopupSubscribed,
      showUnlimitedPurchase: _energyPopupShowUnlimited,
      showCapacity6Purchase: _energyPopupShowCapacity6,
      showCapacity7Purchase: _energyPopupShowCapacity7,
      forceShowGoPremium: _energyPopupForceGoPremium,
      forceShowEnablePush: _energyPopupForceEnablePush,
    );
  }

  Widget _checkbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context).textTheme;
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFF0CABA8),
      checkColor: Colors.white,
      title: Text(label, style: theme.bodyLarge?.copyWith(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return _LabPage(
      title: 'Monetization',
      children: [
        _LabActionRow(
          label: 'Open Paywall',
          onTap: () => unawaited(
            PaywallScreen.push(context, screen: PaywallImpressionScreen.lab),
          ),
        ),
        _LabActionRow(
          label: 'Open Paywall Completed',
          onTap: () => unawaited(PaywallCompletedScreen.push(context)),
        ),
        const SizedBox(height: 16),
        Text(
          'Energy Popup',
          style: theme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        _checkbox(
          label: 'playing',
          value: _energyPopupPlaying,
          onChanged: (v) => setState(() => _energyPopupPlaying = v),
        ),
        _checkbox(
          label: '무제한 모드',
          value: _energyPopupUnlimited,
          onChanged: (v) => setState(() => _energyPopupUnlimited = v),
        ),
        _checkbox(
          label: '구독중 (subscribedYn=Y)',
          value: _energyPopupSubscribed,
          onChanged: (v) => setState(() => _energyPopupSubscribed = v),
        ),
        _checkbox(
          label: 'show Unlimited Pass',
          value: _energyPopupShowUnlimited,
          onChanged: (v) => setState(() => _energyPopupShowUnlimited = v),
        ),
        _checkbox(
          label: 'show Capacity 6',
          value: _energyPopupShowCapacity6,
          onChanged: (v) => setState(() => _energyPopupShowCapacity6 = v),
        ),
        _checkbox(
          label: 'show Capacity 7',
          value: _energyPopupShowCapacity7,
          onChanged: (v) => setState(() => _energyPopupShowCapacity7 = v),
        ),
        _checkbox(
          label: 'force Go Premium',
          value: _energyPopupForceGoPremium,
          onChanged: (v) => setState(() => _energyPopupForceGoPremium = v),
        ),
        _checkbox(
          label: 'force Enable Notifications',
          value: _energyPopupForceEnablePush,
          onChanged: (v) => setState(() => _energyPopupForceEnablePush = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _energyPopupCountController,
          keyboardType: TextInputType.number,
          style: theme.bodyLarge?.copyWith(color: Colors.white),
          decoration: _labDropdownDecoration().copyWith(
            labelText: 'Energy count (0~5)',
            labelStyle: theme.bodyMedium?.copyWith(
              color: const Color(0xFF9E9E9E),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        _LabActionRow(
          label: 'Show Energy Popup',
          onTap: () => unawaited(_showEnergyPopupTest()),
        ),
      ],
    );
  }
}

class _LabRankingPage extends StatelessWidget {
  const _LabRankingPage();

  Future<void> _openRanking(
    BuildContext context, {
    RankBumpPreview? rankBumpPreview,
    bool forceAnnouncePhase = false,
    bool forceRankingRewardClaimPreview = false,
    int? forceRankingRewardClaimPlace,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Ranking(
          rankBumpPreview: rankBumpPreview,
          forceAnnouncePhase: forceAnnouncePhase,
          forceRankingRewardClaimPreview: forceRankingRewardClaimPreview,
          forceRankingRewardClaimPlace: forceRankingRewardClaimPlace ?? 1,
          isActive: true,
          onNavigateToHome: () => Navigator.of(routeContext).pop(),
          onNavigateToAlarm: () => Navigator.of(routeContext).pop(),
          onNavigateToProfile: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  Future<void> _openRewardUnboxing(BuildContext context) async {
    final items = CharacterRewardClaimDto.labUnboxingPreviewItems();
    await RewardUnboxing.preload(context, items);
    if (!context.mounted) return;
    await RewardUnboxing.push(context, items);
  }

  @override
  Widget build(BuildContext context) {
    return _LabPage(
      title: 'Ranking',
      children: [
        _LabActionRow(
          label: 'Play Ranking Bump (on screen)',
          onTap: () => unawaited(
            _openRanking(context, rankBumpPreview: RankBumpPreview.onScreen),
          ),
        ),
        _LabActionRow(
          label: 'Play Ranking Bump (sticky)',
          onTap: () => unawaited(
            _openRanking(context, rankBumpPreview: RankBumpPreview.sticky),
          ),
        ),
        _LabActionRow(
          label: 'Open Ranking Announce Preview',
          onTap: () => unawaited(
            _openRanking(context, forceAnnouncePhase: true),
          ),
        ),
        _LabActionRow(
          label: 'Open Ranking Reward Claim Preview (1st)',
          onTap: () => unawaited(
            _openRanking(
              context,
              forceAnnouncePhase: true,
              forceRankingRewardClaimPreview: true,
              forceRankingRewardClaimPlace: 1,
            ),
          ),
        ),
        _LabActionRow(
          label: 'Open Ranking Reward Claim Preview (2nd)',
          onTap: () => unawaited(
            _openRanking(
              context,
              forceAnnouncePhase: true,
              forceRankingRewardClaimPreview: true,
              forceRankingRewardClaimPlace: 2,
            ),
          ),
        ),
        _LabActionRow(
          label: 'Open Ranking Reward Claim Preview (3rd)',
          onTap: () => unawaited(
            _openRanking(
              context,
              forceAnnouncePhase: true,
              forceRankingRewardClaimPreview: true,
              forceRankingRewardClaimPlace: 3,
            ),
          ),
        ),
        _LabActionRow(
          label: 'Open Reward Unboxing',
          onTap: () => unawaited(_openRewardUnboxing(context)),
        ),
      ],
    );
  }
}

class _LabFeedbackPage extends StatefulWidget {
  const _LabFeedbackPage();

  @override
  State<_LabFeedbackPage> createState() => _LabFeedbackPageState();
}

class _LabFeedbackPageState extends State<_LabFeedbackPage> {
  static const _longToastTestMessage =
      'Test Popup, Test Toast, 가나다라마바사아자차카타파하';

  bool _toastIsWarning = false;
  String? _selectedLabDefaultPopupId;

  @override
  void initState() {
    super.initState();
    if (kLabDefaultPopupOptions.isNotEmpty) {
      _selectedLabDefaultPopupId = kLabDefaultPopupOptions.first.id;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return _LabPage(
      title: 'Feedback',
      children: [
        Text(
          'Default Popup',
          style: theme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        if (kLabDefaultPopupOptions.isEmpty)
          Text(
            'No migrated DefaultPopup yet. Entries are added in '
            '`kLabDefaultPopupOptions` after each migration.',
            style: theme.bodyMedium?.copyWith(color: const Color(0xFF9E9E9E)),
          )
        else
          InputDecorator(
            decoration: _labDropdownDecoration(),
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
                onChanged: (v) => setState(() => _selectedLabDefaultPopupId = v),
              ),
            ),
          ),
        _LabActionRow(
          label: 'Show Popup',
          onTap: kLabDefaultPopupOptions.isEmpty
              ? null
              : () => unawaited(_showSelectedLabDefaultPopup()),
        ),
        const SizedBox(height: 16),
        Text(
          'Toast',
          style: theme.headlineSmall?.copyWith(color: Colors.white),
        ),
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
        _LabActionRow(
          label: 'Show Toast',
          onTap: () => DefaultToast.show(
            context,
            'Test Popup, Test Toast',
            isError: _toastIsWarning,
          ),
        ),
        _LabActionRow(
          label: 'Show Toast(Long Text)',
          onTap: () => DefaultToast.show(
            context,
            _longToastTestMessage,
            isError: _toastIsWarning,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Like Effect',
          style: theme.headlineSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        _LabActionRow(
          label: 'Simple Like Effect',
          onTap: () => unawaited(
            LikeProgressEffect.play(
              context,
              params: const LikeProgressEffectParams(
                asIsLikePoint: 36,
                toBeLikePoint: 72,
                asIsLevel: 36,
                toBeLevel: 36,
                asIsProgress: 25,
                toBeProgress: 75,
              ),
            ),
          ),
        ),
        _LabActionRow(
          label: 'Levelup Like Effect',
          onTap: () => unawaited(
            LikeProgressEffect.play(
              context,
              params: const LikeProgressEffectParams(
                asIsLikePoint: 36,
                toBeLikePoint: 172,
                asIsLevel: 36,
                toBeLevel: 38,
                asIsProgress: 25,
                toBeProgress: 75,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabStylePage extends StatelessWidget {
  const _LabStylePage();

  static const _lines = ['말해요!?', 'Talk', 'E sua vez primeiro!'];

  Widget _preview(BuildContext context, String label, TextStyle? style) {
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
          for (final line in _lines) ...[
            Text(line, style: previewStyle),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return _LabPage(
      title: 'Style',
      children: [
        _preview(context, 'heading1 (headlineLarge)', theme.headlineLarge),
        _preview(context, 'heading2 (headlineMedium)', theme.headlineMedium),
        _preview(context, 'heading3 (headlineSmall)', theme.headlineSmall),
        _preview(context, 'body-default (bodyLarge)', theme.bodyLarge),
        _preview(context, 'body-secondary (bodyMedium)', theme.bodyMedium),
        _preview(context, 'body-caption (bodySmall)', theme.bodySmall),
        _preview(context, 'body-tiny (labelSmall)', theme.labelSmall),
        _preview(context, 'body-tiny2 (labelMini)', theme.labelMini),
      ],
    );
  }
}

class _LabAccountPage extends StatefulWidget {
  const _LabAccountPage({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  State<_LabAccountPage> createState() => _LabAccountPageState();
}

class _LabAccountPageState extends State<_LabAccountPage> {
  bool _removingMetaInfo = false;

  Future<void> _removeMetaInfo() async {
    if (_removingMetaInfo) return;
    setState(() => _removingMetaInfo = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('missing access token');
      }
      await SudaApiClient.clearMetaInfo(accessToken: token);
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
      await AuthService.signOut();
      await TokenStorage.clearTokens();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      widget.onSignOut?.call();
    } catch (error) {
      if (mounted) {
        DefaultToast.show(context, 'Remove MetaInfo failed: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _removingMetaInfo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LabPage(
      title: 'Account',
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _removingMetaInfo ? null : () => unawaited(_removeMetaInfo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0CABA8),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF0CABA8),
              disabledForegroundColor: Colors.white54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Remove MetaInfo'),
          ),
        ),
      ],
    );
  }
}

/// Lab: Tutorial Intro → (mic) → Tutorial Roleplay.
class _TutorialIntroPreview extends StatefulWidget {
  const _TutorialIntroPreview();

  @override
  State<_TutorialIntroPreview> createState() => _TutorialIntroPreviewState();
}

class _TutorialIntroPreviewState extends State<_TutorialIntroPreview> {
  bool _roleplay = false;

  @override
  Widget build(BuildContext context) {
    if (_roleplay) {
      return TutorialRoleplayScreen(
        preview: true,
        onSkip: () => Navigator.of(context).pop(),
      );
    }
    return TutorialIntroScreen(
      preview: true,
      user: const UserDto(id: 0, name: 'Jeeeeun Priscilla', imgPath: 'DEFAULT:4'),
      onStartTutorial: () => setState(() => _roleplay = true),
    );
  }
}
