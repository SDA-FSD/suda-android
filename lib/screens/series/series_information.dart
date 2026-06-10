import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../models/user_models.dart';
import '../../utils/english_level_util.dart';
import '../../utils/suda_json_util.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/roleplay_overview_backdrop.dart'
    show kRoleplayOverviewBackdropBlurSigma;

/// Series 상세 정보 Sub Screen. Overview에서 로드된 [overview]를 표시한다.
class SeriesInformationScreen extends StatelessWidget {
  final RpS2SeriesOverviewDto overview;
  final UserDto? user;

  const SeriesInformationScreen({
    super.key,
    required this.overview,
    this.user,
  });

  static const String routeName = '/series/information';

  static const _quoteBarColor = Color(0xFF353535);
  static const _episodeTitleColor = Color(0xFF8C8C8C);
  static const _headerTitleHorizontalInset = 40.0;
  static const _headerTitleTop = 16.0;
  static const _gapAfterHeaderTitle = 40.0;
  static const _minBodyTopPadding = 70.0;
  static const _heroHeightFactor = 0.6;

  static double _heroHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).width * _heroHeightFactor;
  }

  Widget _buildHeroBackground(
    BuildContext context, {
    required String imageUrl,
    required double height,
  }) {
    final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: kRoleplayOverviewBackdropBlurSigma,
                sigmaY: kRoleplayOverviewBackdropBlurSigma,
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: height,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) =>
                    ColoredBox(color: scaffoldBackground),
                errorWidget: (context, url, error) =>
                    ColoredBox(color: scaffoldBackground),
              ),
            ),
            DecoratedBox(
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
          ],
        ),
      ),
    );
  }

  static double _bodyTopPaddingForTitle(
    BuildContext context,
    String title,
    TextStyle? titleStyle,
  ) {
    final maxWidth =
        MediaQuery.sizeOf(context).width - (_headerTitleHorizontalInset * 2);
    final painter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      maxLines: 2,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);

    final padding =
        _headerTitleTop + painter.height + _gapAfterHeaderTitle;
    return padding < _minBodyTopPadding ? _minBodyTopPadding : padding;
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

  TextStyle? _bodySmallWhite(TextTheme theme) {
    return theme.bodySmall?.copyWith(color: Colors.white);
  }

  TextStyle _bodySmallBoldWhite(TextTheme theme) {
    return theme.bodySmall!.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    );
  }

  Widget _buildQuoteBar({required List<Widget> children}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ColoredBox(
            color: _quoteBarColor,
            child: SizedBox(width: 3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageLevelLine(AppLocalizations l10n, TextTheme theme) {
    final cefrCode = EnglishLevelUtil.readLevelFromUser(user);
    final cefrLabel = EnglishLevelUtil.localizedLabel(l10n, cefrCode);
    final bodyStyle = _bodySmallWhite(theme);
    final boldStyle = _bodySmallBoldWhite(theme);

    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(
            text: '${l10n.settingsCefrLevel} : ',
            style: boldStyle,
          ),
          TextSpan(text: '$cefrLabel ($cefrCode)'),
        ],
      ),
    );
  }

  Widget _buildTopicDifficultyLine(
    AppLocalizations l10n,
    TextTheme theme,
    String? complexityLevel,
  ) {
    final bodyStyle = _bodySmallWhite(theme);
    final boldStyle = _bodySmallBoldWhite(theme);
    final iconAsset = _complexityIconAsset(complexityLevel);

    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(
            text: '${l10n.seriesInformationTopicDifficulty} : ',
            style: boldStyle,
          ),
          if (iconAsset != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image.asset(
                iconAsset,
                height: 18,
                fit: BoxFit.fitHeight,
              ),
            ),
        ],
      ),
    );
  }

  List<String> _keyExpressionsForEpisode(
    RpS2SeriesEpisodeDto episode,
    String cefrCode,
  ) {
    final cefr = episode.cefrMap[cefrCode];
    if (cefr == null) return const [];

    return cefr.missions
        .map((mission) => SudaJsonUtil.localizedMapText(mission.keyExpression))
        .where((text) => text.isNotEmpty)
        .toList();
  }

  Widget _buildKeyExpressionList(List<String> expressions, TextTheme theme) {
    if (expressions.isEmpty) return const SizedBox.shrink();

    final captionStyle = theme.bodySmall?.copyWith(color: Colors.white);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < expressions.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: captionStyle),
              Expanded(
                child: Text(
                  expressions[i],
                  style: captionStyle,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEpisodeBlock(
    RpS2SeriesEpisodeDto episode,
    int episodeNumber,
    String cefrCode,
    TextTheme theme,
  ) {
    final learningFunction =
        SudaJsonUtil.localizedMapText(episode.learningFunction);
    final episodeTitle = SudaJsonUtil.localizedMapText(episode.title);
    final keyExpressions = _keyExpressionsForEpisode(episode, cefrCode);

    return _buildQuoteBar(
      children: [
        if (learningFunction.isNotEmpty)
          Text(
            learningFunction,
            style: _bodySmallWhite(theme),
            textAlign: TextAlign.justify,
          ),
        if (learningFunction.isNotEmpty && episodeTitle.isNotEmpty)
          const SizedBox(height: 4),
        if (episodeTitle.isNotEmpty)
          Text(
            '#$episodeNumber $episodeTitle',
            style: theme.labelSmall?.copyWith(
              color: _episodeTitleColor,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              fontVariations: const [FontVariation('wght', 400)],
            ),
          ),
        if (episodeTitle.isNotEmpty && keyExpressions.isNotEmpty)
          const SizedBox(height: 8),
        _buildKeyExpressionList(keyExpressions, theme),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final seriesTitle = SudaJsonUtil.localizedMapText(overview.title);
    final synopsis = SudaJsonUtil.localizedMapText(overview.synopsis);
    final thumbnailPath = overview.thumbnailImgPath;
    final backdropUrl = thumbnailPath != null && thumbnailPath.isNotEmpty
        ? '${AppConfig.cdnBaseUrl}$thumbnailPath'
        : null;
    final headerTitleStyle =
        theme.headlineSmall?.copyWith(color: Colors.white);
    final bodyTopPadding = _bodyTopPaddingForTitle(
      context,
      seriesTitle,
      headerTitleStyle,
    );
    final cefrCode = EnglishLevelUtil.readLevelFromUser(user);
    final heroHeight = _heroHeight(context);
    final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scaffoldBackground),
        if (backdropUrl != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeroBackground(
              context,
              imageUrl: backdropUrl,
              height: heroHeight,
            ),
          ),
        AppScaffold(
          backgroundColor: Colors.transparent,
          showBackButton: true,
          usePadding: true,
          bodyTopPadding: bodyTopPadding,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (synopsis.isNotEmpty)
                  Text(
                    synopsis,
                    style: _bodySmallWhite(theme),
                    textAlign: TextAlign.justify,
                  ),
                const SizedBox(height: 20),
                _buildQuoteBar(
                  children: [
                    _buildLanguageLevelLine(l10n, theme),
                    const SizedBox(height: 4),
                    _buildTopicDifficultyLine(
                      l10n,
                      theme,
                      overview.synopsisComplexityLevel,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  l10n.seriesInformationLearningGoals,
                  style: theme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 20),
                for (int i = 0; i < overview.episodes.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  _buildEpisodeBlock(
                    overview.episodes[i],
                    i + 1,
                    cefrCode,
                    theme,
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: _headerTitleHorizontalInset,
          right: _headerTitleHorizontalInset,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: _headerTitleTop),
              child: IgnorePointer(
                child: Text(
                  seriesTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: headerTitleStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
