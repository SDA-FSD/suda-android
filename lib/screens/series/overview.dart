import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../services/main_user_sync.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/english_level_util.dart';
import '../../utils/language_util.dart';
import '../../utils/suda_json_util.dart';
import '../../utils/sub_screen_route.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/suda_label_tabs.dart';
import '../../navigation/app_route_observer.dart';
import '../../routes/roleplay_router.dart';
import '../setting/cefr_level.dart';
import 'series_information.dart';
import 'widgets/series_episode_tab_content.dart';

/// Series Overview Screen (Sub Screen, S2)
class SeriesOverviewScreen extends StatefulWidget {
  final int seriesId;
  final UserDto? user;

  const SeriesOverviewScreen({
    super.key,
    required this.seriesId,
    this.user,
  });

  static const String routeName = '/series/overview';

  @override
  State<SeriesOverviewScreen> createState() => _SeriesOverviewScreenState();
}

class _SeriesOverviewScreenState extends State<SeriesOverviewScreen>
    with RouteAware {
  bool _isLoading = true;
  String? _errorMessage;
  RpS2SeriesOverviewDto? _overview;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _titleKey = GlobalKey();
  bool _isFloatingHeaderVisible = true;
  bool _isInfoIconVisible = true;
  int _episodeContentKey = 0;
  int _scrollToUnlockToken = 0;
  bool _isSynopsisExpanded = false;

  static const _heroHeightFactor = 0.6;
  static const _infoIconSize = 24.0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshBestScoreMapIfPending();
  }

  void _refreshBestScoreMapIfPending() {
    if (!SeriesStateService.instance.consumeBestScoreRefreshPending()) {
      return;
    }
    unawaited(_refreshBestScoreMap());
  }

  Future<void> _loadOverview() async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (accessToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _overview = null;
        _isSynopsisExpanded = false;
      });

      if (widget.user != null) {
        SeriesStateService.instance.setUser(widget.user);
      }

      _handleFirstOverviewBestEffort(accessToken);

      final overview = await SudaApiClient.getSeriesOverview(
        accessToken: accessToken,
        seriesId: widget.seriesId,
      );
      if (!mounted) return;

      SeriesStateService.instance.setSeriesOverview(
        seriesId: widget.seriesId,
        overview: overview,
        user: widget.user,
      );

      setState(() {
        _overview = overview;
        _isLoading = false;
        _scrollToUnlockToken++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load series overview.';
      });
    }
  }

  String? _complexityIconAsset(String? level) {
    switch (level?.toUpperCase()) {
      case 'EASY':
        return 'assets/images/icons/scl_easy.png';
      case 'NORMAL':
        return 'assets/images/icons/scl_normal.png';
      case 'HARD':
        return 'assets/images/icons/scl_hard.png';
      default:
        return null;
    }
  }

  double _heroHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).width * _heroHeightFactor;
  }

  void _handleScroll() {
    if (!mounted) return;

    final titleContext = _titleKey.currentContext;
    if (titleContext == null) {
      final nearTop = _scrollController.offset < 1;
      if (nearTop != _isInfoIconVisible) {
        setState(() => _isInfoIconVisible = nearTop);
      }
      return;
    }

    final box = titleContext.findRenderObject();
    if (box is! RenderBox) return;

    final position = box.localToGlobal(Offset.zero);
    final topInset = MediaQuery.of(titleContext).padding.top;
    final heroHeight = _heroHeight(titleContext);
    final shouldShowHeader = position.dy > (topInset + 48);
    final shouldShowInfoIcon = position.dy >= heroHeight;

    if (shouldShowHeader == _isFloatingHeaderVisible &&
        shouldShowInfoIcon == _isInfoIconVisible) {
      return;
    }

    setState(() {
      _isFloatingHeaderVisible = shouldShowHeader;
      _isInfoIconVisible = shouldShowInfoIcon;
    });
  }

  void _openSeriesInformation() {
    final overview = _overview;
    if (overview == null) return;
    Navigator.push(
      context,
      SubScreenRoute(
        page: SeriesInformationScreen(
          overview: overview,
          user: widget.user,
        ),
      ),
    );
  }

  Future<void> _refreshBestScoreMap() async {
    final overview = _overview;
    if (overview == null) return;

    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted || accessToken == null) return;

    try {
      final bestScoreMap = await SudaApiClient.getSeriesBestScore(
        accessToken: accessToken,
        seriesId: widget.seriesId,
      );
      if (!mounted) return;
      final updated = overview.copyWith(bestScoreMap: bestScoreMap);
      SeriesStateService.instance.setSeriesOverview(
        seriesId: widget.seriesId,
        overview: updated,
        user: SeriesStateService.instance.user ?? widget.user,
      );
      setState(() {
        _overview = updated;
        _episodeContentKey++;
        _scrollToUnlockToken++;
      });
    } catch (_) {}
  }

  Future<void> _openCefrLevelScreen() async {
    final levelBefore = EnglishLevelUtil.readLevelFromUser(widget.user);

    await Navigator.push(
      context,
      SubScreenRoute(page: CefrLevelScreen(user: widget.user)),
    );
    if (!mounted) return;

    final levelAfter = EnglishLevelUtil.readLevelFromUser(widget.user);
    if (levelBefore != levelAfter) {
      await _refreshBestScoreMap();
    } else if (mounted) {
      setState(() {});
    }
  }

  Widget _buildLanguageLevelButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final level = EnglishLevelUtil.readLevelFromUser(widget.user);
    final label = EnglishLevelUtil.localizedLabel(l10n, level);
    const pillRadius = 12.0;

    return GestureDetector(
      onTap: _openCefrLevelScreen,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(pillRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(pillRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(pillRadius),
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
              child: SizedBox(
                height: 24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/icons/circle_usa_flag.png',
                      width: 13,
                      height: 13,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        label,
                        style: theme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                    Image.asset(
                      'assets/images/icons/closing_angle_bracket.png',
                      height: 13,
                      fit: BoxFit.fitHeight,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _isFloatingHeaderVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_isFloatingHeaderVisible,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                children: [
                  AppScaffold.backButton(context),
                  const Spacer(),
                  _buildLanguageLevelButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundShimmer(double height) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3F3F3F),
      child: Container(
        width: double.infinity,
        height: height,
        color: Colors.white,
      ),
    );
  }

  int _completionPercent(RpS2SeriesOverviewDto overview) {
    final total = overview.episodes.length;
    if (total == 0) return 0;
    final cleared = overview.bestScoreMap.length;
    return ((cleared / total) * 100).round().clamp(0, 100);
  }

  String _completionLabel(int percent) {
    final langCode = LanguageUtil.getCurrentLanguageCode();
    if (langCode == 'ko') return '$percent% 진행완료';
    if (langCode == 'pt') return '$percent% Completo';
    return '$percent% Complete';
  }

  Widget _buildProgressBarArea(RpS2SeriesOverviewDto overview) {
    final percent = _completionPercent(overview);
    final fraction = percent / 100.0;

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildProgressBarTrack(fraction),
          ),
          const SizedBox(width: 6),
          Text(
            _completionLabel(percent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarTrack(double fraction) {
    const barHeight = 4.0;
    const radius = BorderRadius.all(Radius.circular(2));

    return LayoutBuilder(
      builder: (context, constraints) {
        final clamped = fraction.clamp(0.0, 1.0);
        final fillWidth = constraints.maxWidth * clamped;
        return SizedBox(
          height: barHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF353535),
                  borderRadius: radius,
                ),
              ),
              if (fillWidth > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: SizedBox(
                      width: fillWidth,
                      height: barHeight,
                      child: const ColoredBox(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoIcon({VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        'assets/images/icons/information.png',
        width: _infoIconSize,
        height: _infoIconSize,
      ),
    );
  }

  Widget _buildInfoIconOverlay(double heroHeight) {
    return Positioned(
      top: heroHeight - _infoIconSize,
      right: 16,
      child: AnimatedOpacity(
        opacity: _isInfoIconVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_isInfoIconVisible,
          child: _buildInfoIcon(onTap: _openSeriesInformation),
        ),
      ),
    );
  }

  Widget _buildComplexityTag(String? level) {
    final asset = _complexityIconAsset(level);
    if (asset == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        asset,
        height: 18,
        fit: BoxFit.fitHeight,
      ),
    );
  }

  static const String _firstOverviewMetaKey = 'FIRST_OVERVIEW';

  void _handleFirstOverviewBestEffort(String accessToken) {
    final user = SeriesStateService.instance.user ?? widget.user;
    if (user == null) return;
    if (user.hasMetaInfoValue(key: _firstOverviewMetaKey, value: 'Y')) return;

    unawaited(_postFirstOverviewBestEffort(accessToken));

    final updatedUser =
        user.upsertMetaInfo(key: _firstOverviewMetaKey, value: 'Y');
    SeriesStateService.instance.setUser(updatedUser);
    MainUserSync.instance.notifyUserUpdated(updatedUser);
  }

  Future<void> _postFirstOverviewBestEffort(String accessToken) async {
    try {
      await SudaApiClient.postFirstOverview(accessToken: accessToken);
    } catch (_) {
      // best-effort: ignore
    }
  }

  void _onEpisodePlay(RpS2SeriesEpisodeDto episode) {
    SeriesStateService.instance.setSelectedEpisodeId(episode.id);
    final user = SeriesStateService.instance.user ?? widget.user;
    if (user != null) {
      SeriesStateService.instance.setUser(user);
      RoleplayStateService.instance.setUser(user);
    }
    RoleplayRouter.pushTutorial(context);
  }

  Widget _buildOverviewTabs(
    BuildContext context,
    RpS2SeriesOverviewDto overview,
  ) {
    return SudaLabelTabs(
      contentGap: 24,
      tabs: [
        SudaLabelTab(
          label: SudaTabLabel.l10n((l10n) => l10n.seriesOverviewTabEpisodes),
          child: SeriesEpisodeTabContent(
            key: ValueKey(_episodeContentKey),
            overview: overview,
            onPlayEpisode: _onEpisodePlay,
            scrollToUnlockToken: _scrollToUnlockToken,
          ),
        ),
        SudaLabelTab(
          label: SudaTabLabel.l10n((l10n) => l10n.seriesOverviewTabSimilarTopic),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final theme = Theme.of(context).textTheme;
    final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;
    final heroHeight = _heroHeight(context);
    final thumbnailPath = overview?.thumbnailImgPath;
    final title = overview == null
        ? ''
        : SudaJsonUtil.localizedMapText(overview.title);
    final synopsis = overview == null
        ? ''
        : SudaJsonUtil.localizedMapText(overview.synopsis);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: thumbnailPath == null || thumbnailPath.isEmpty
                ? Container(
                    height: heroHeight,
                    color: scaffoldBackground,
                  )
                : CachedNetworkImage(
                    imageUrl: '${AppConfig.cdnBaseUrl}$thumbnailPath',
                    width: double.infinity,
                    height: heroHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) =>
                        _buildBackgroundShimmer(heroHeight),
                    errorWidget: (context, url, error) => Container(
                      height: heroHeight,
                      color: scaffoldBackground,
                    ),
                  ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: heroHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          scaffoldBackground,
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: scaffoldBackground,
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          key: _titleKey,
                          style: theme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildComplexityTag(overview?.synopsisComplexityLevel),
                        if (overview != null)
                          _buildProgressBarArea(overview),
                        if (synopsis.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(
                              () => _isSynopsisExpanded = !_isSynopsisExpanded,
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              synopsis,
                              style: theme.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.justify,
                              maxLines: _isSynopsisExpanded ? null : 2,
                              overflow: _isSynopsisExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (overview != null) ...[
                          const SizedBox(height: 40),
                          _buildOverviewTabs(context, overview),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildFloatingHeader(context),
          if (overview != null) _buildInfoIconOverlay(heroHeight),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (!_isLoading && _errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
