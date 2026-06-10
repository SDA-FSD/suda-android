import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/series_models.dart';
import '../../../utils/default_toast.dart';
import '../../../utils/suda_json_util.dart';

enum _EpisodePlayButtonKind { replay, unlock, locked }

class SeriesEpisodeTabContent extends StatefulWidget {
  final RpS2SeriesOverviewDto overview;
  final void Function(RpS2SeriesEpisodeDto episode)? onPlayEpisode;
  final int scrollToUnlockToken;

  const SeriesEpisodeTabContent({
    super.key,
    required this.overview,
    this.onPlayEpisode,
    this.scrollToUnlockToken = 0,
  });

  @override
  State<SeriesEpisodeTabContent> createState() => _SeriesEpisodeTabContentState();
}

class _SeriesEpisodeTabContentState extends State<SeriesEpisodeTabContent> {
  static const _episodeLabelColor = Color(0xFF635F5F);
  static const _mint = Color(0xFF0CABA8);
  static const _tealDark = Color(0xFF054544);
  static const _lockedFill = Color(0xFF353535);
  static const _lockedText = Color(0xFF8C8C8C);
  static const _blockGap = 30.0;
  static const _sideGap = 12.0;
  static const _starSize = 16.0;
  static const _starGap = 2.0;
  static const _thumbRadius = 10.0;
  static const _scaffoldBackground = Color(0xFF121212);
  static const _unlockBlockBackground = Color(0xFF1E1E1E);
  /// overview 탭 영역 좌우 패딩(24)과 동일 — 디스플레이 전체 너비까지 확장
  static const _unlockBlockHorizontalBleed = 24.0;
  static const _unlockBlockVerticalBleed = 8.0;
  static const _playButtonHeight = 38.0;
  static const _summaryButtonGap = 4.0;
  static const _scrollToUnlockDuration = Duration(milliseconds: 450);
  static const _floatingHeaderReserve = 56.0;

  final GlobalKey _unlockBlockKey = GlobalKey();
  int _lastScrollToken = -1;

  RpS2SeriesOverviewDto get overview => widget.overview;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToUnlock();
  }

  @override
  void didUpdateWidget(SeriesEpisodeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToUnlockToken != oldWidget.scrollToUnlockToken ||
        widget.overview != oldWidget.overview) {
      _scheduleScrollToUnlock();
    }
  }

  void _scheduleScrollToUnlock() {
    if (_lastScrollToken == widget.scrollToUnlockToken) return;
    _lastScrollToken = widget.scrollToUnlockToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToUnlockIfNeeded();
    });
  }

  void _scrollToUnlockIfNeeded() {
    final targetContext = _unlockBlockKey.currentContext;
    if (targetContext == null) return;

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final media = MediaQuery.of(targetContext);
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final visibleTop = media.padding.top + _floatingHeaderReserve;
    final visibleBottom = media.size.height - media.padding.bottom;

    if (bottom > visibleTop && top < visibleBottom) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: _scrollToUnlockDuration,
      curve: Curves.easeInOut,
      alignment: 0.35,
    );
  }

  int? _firstUnlockIndex() {
    for (int i = 0; i < overview.episodes.length; i++) {
      if (!overview.bestScoreMap.containsKey(overview.episodes[i].id)) {
        return i;
      }
    }
    return null;
  }

  _EpisodePlayButtonKind _buttonKind(int index, int? firstUnlockIndex) {
    final episode = overview.episodes[index];
    if (overview.bestScoreMap.containsKey(episode.id)) {
      return _EpisodePlayButtonKind.replay;
    }
    if (firstUnlockIndex == index) {
      return _EpisodePlayButtonKind.unlock;
    }
    return _EpisodePlayButtonKind.locked;
  }

  int _starCount(int episodeId) {
    final score = overview.bestScoreMap[episodeId];
    if (score == null) return 0;
    return score.clamp(0, 3);
  }

  Widget _buildStars(int activeCount) {
    final count = activeCount.clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < count;
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : _starGap),
          child: Image.asset(
            isActive
                ? 'assets/images/icons/star_on.png'
                : 'assets/images/icons/star_off.png',
            width: _starSize,
            height: _starSize,
          ),
        );
      }),
    );
  }

  Widget _buildThumbnail({
    required double width,
    required String? thumbnailPath,
    required int starCount,
  }) {
    final imageHeight = width * 1.35;
    final imageUrl = thumbnailPath != null && thumbnailPath.isNotEmpty
        ? '${AppConfig.cdnBaseUrl}$thumbnailPath'
        : null;

    return SizedBox(
      width: width,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_thumbRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl == null
                ? const ColoredBox(color: Color(0xFF353535))
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: width,
                    height: imageHeight,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    errorWidget: (context, url, error) =>
                        const ColoredBox(color: Color(0xFF353535)),
                  ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.125,
                widthFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00121212),
                        _scaffoldBackground,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.25,
                widthFactor: 1,
                child: Center(child: _buildStars(starCount)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _playLabelStyle(BuildContext context, {required Color color}) {
    final base = Theme.of(context).elevatedButtonTheme.style?.textStyle
        ?.resolve(const {});
    return base?.copyWith(color: color) ??
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation('wght', 600)],
            );
  }

  Widget _buildPlayButton(
    BuildContext context,
    AppLocalizations l10n,
    _EpisodePlayButtonKind kind,
    VoidCallback? onTap,
  ) {
    const radius = BorderRadius.all(Radius.circular(_playButtonHeight / 2));

    Widget inner;
    switch (kind) {
      case _EpisodePlayButtonKind.replay:
        inner = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/icons/play.png',
                width: 11,
                height: 14,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.seriesOverviewPlay,
                style: _playLabelStyle(context, color: Colors.white),
              ),
            ],
          ),
        );
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                colors: [_mint, _tealDark],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: SizedBox(
                  height: _playButtonHeight,
                  width: double.infinity,
                  child: inner,
                ),
              ),
            ),
          ),
        );
      case _EpisodePlayButtonKind.unlock:
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: radius,
            ),
            child: SizedBox(
              height: _playButtonHeight,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/icons/play.png',
                    width: 11,
                    height: 14,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.seriesOverviewPlay,
                    style: _playLabelStyle(context, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      case _EpisodePlayButtonKind.locked:
        return GestureDetector(
          onTap: () {
            DefaultToast.show(context, l10n.seriesOverviewEpisodeLockedToast);
          },
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _lockedFill,
              borderRadius: radius,
            ),
            child: SizedBox(
              height: _playButtonHeight,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/icons/lock.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.seriesOverviewLocked,
                    style: _playLabelStyle(context, color: _lockedText),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _wrapUnlockBlockHighlight(Widget child) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Positioned(
          left: -_unlockBlockHorizontalBleed,
          right: -_unlockBlockHorizontalBleed,
          top: -_unlockBlockVerticalBleed,
          bottom: -_unlockBlockVerticalBleed,
          child: const ColoredBox(color: _unlockBlockBackground),
        ),
        child,
      ],
    );
  }

  Widget _buildEpisodeBlock(
    BuildContext context,
    RpS2SeriesEpisodeDto episode,
    int episodeNumber,
    _EpisodePlayButtonKind buttonKind, {
    Key? blockKey,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leftWidth = screenWidth * 0.25;
    final title = SudaJsonUtil.localizedMapText(episode.title);
    final summary = SudaJsonUtil.localizedMapText(episode.summary);
    final starCount = _starCount(episode.id);

    final block = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftWidth,
            child: Column(
              children: [
                _buildThumbnail(
                  width: leftWidth,
                  thumbnailPath: episode.thumbnailImgPath,
                  starCount: starCount,
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: _sideGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.seriesOverviewEpisodeNumber(episodeNumber),
                  style: theme.labelSmall?.copyWith(
                    color: _episodeLabelColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontVariations: const [FontVariation('wght', 400)],
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation('wght', 700)],
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: theme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontVariations: const [FontVariation('wght', 400)],
                    ),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: _summaryButtonGap),
                _buildPlayButton(
                  context,
                  l10n,
                  buttonKind,
                  buttonKind == _EpisodePlayButtonKind.replay ||
                          buttonKind == _EpisodePlayButtonKind.unlock
                      ? () => widget.onPlayEpisode?.call(episode)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Widget result = block;
    if (buttonKind == _EpisodePlayButtonKind.unlock) {
      result = _wrapUnlockBlockHighlight(block);
    }
    if (blockKey != null) {
      result = KeyedSubtree(key: blockKey, child: result);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final episodes = overview.episodes;
    if (episodes.isEmpty) return const SizedBox.shrink();

    final firstUnlockIndex = _firstUnlockIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < episodes.length; i++) ...[
          if (i > 0) const SizedBox(height: _blockGap),
          _buildEpisodeBlock(
            context,
            episodes[i],
            i + 1,
            _buttonKind(i, firstUnlockIndex),
            blockKey: i == firstUnlockIndex ? _unlockBlockKey : null,
          ),
        ],
      ],
    );
  }
}
