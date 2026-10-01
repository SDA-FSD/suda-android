import 'dart:async' show Timer, unawaited;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:shimmer/shimmer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/series_models.dart';
import '../../../utils/default_toast.dart';
import '../../../utils/suda_json_util.dart';
import '../../../widgets/cdn_thumb_image.dart';

enum _EpisodePlayButtonKind { replay, unlock, locked }

/// `bestScoreMap`에 없는 첫 에피소드. 전부 완료면 null.
int? seriesOverviewFirstUnlockIndex(RpS2SeriesOverviewDto overview) {
  for (var i = 0; i < overview.episodes.length; i++) {
    if (!overview.bestScoreMap.containsKey(overview.episodes[i].id)) {
      return i;
    }
  }
  return null;
}

/// 진행대기가 정확히 다음 1칸으로 옮겨졌고, 그 칸은 아직 점수가 없을 때.
bool seriesOverviewUnlockAdvanced({
  required RpS2SeriesOverviewDto before,
  required RpS2SeriesOverviewDto after,
}) {
  final beforeEpisodes = before.episodes;
  final afterEpisodes = after.episodes;
  if (beforeEpisodes.isEmpty ||
      beforeEpisodes.length != afterEpisodes.length) {
    return false;
  }
  for (var i = 0; i < beforeEpisodes.length; i++) {
    if (beforeEpisodes[i].id != afterEpisodes[i].id) return false;
  }
  final from = seriesOverviewFirstUnlockIndex(before);
  final to = seriesOverviewFirstUnlockIndex(after);
  if (from == null || to == null || to != from + 1) return false;
  final completedId = beforeEpisodes[from].id;
  if (!after.bestScoreMap.containsKey(completedId)) return false;
  if (after.bestScoreMap.containsKey(afterEpisodes[to].id)) return false;
  return true;
}

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

class _SeriesEpisodeTabContentState extends State<SeriesEpisodeTabContent>
    with SingleTickerProviderStateMixin {
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
  static const _unlockAdvanceHold = Duration(milliseconds: 300);
  static const _unlockAdvanceDuration = Duration(milliseconds: 1000);
  /// 1s 안의 비율은 기존 컷(자물쇠 180, 슬라이드 220)과 같다.
  static const _lockPopEnd = 180 / 520;
  static const _playSlideEnd = (180 + 220) / 520;

  final GlobalKey _listKey = GlobalKey();
  /// 행마다 고정. 해금 연출에서 키를 옮기면 썸네일 위젯이 다시 생겨 shimmer가 번쩍인다.
  final Map<int, GlobalKey> _rowKeys = {};
  late final AnimationController _advanceController;

  int _lastScrollToken = -1;
  int _advanceGeneration = 0;
  int _anchorAttempts = 0;
  int? _advanceFrom;
  int? _advanceTo;
  bool _anchorsReady = false;
  bool _advanceTicksEnabled = false;
  bool _episodeButtonsLocked = false;
  bool _unlockHapticPlayed = false;
  Timer? _advanceHoldTimer;
  RpS2SeriesOverviewDto? _heldOverview;
  double _fromTop = 0;
  double _toTop = 0;
  double _fromHeight = 0;
  double _toHeight = 0;

  RpS2SeriesOverviewDto get overview => _heldOverview ?? widget.overview;

  bool get _isAdvancing => _advanceFrom != null && _advanceTo != null;

  @override
  void initState() {
    super.initState();
    _advanceController = AnimationController(
      vsync: this,
      duration: _unlockAdvanceDuration,
    );
    _advanceController.addListener(() {
      if (!mounted || !_advanceTicksEnabled || _advanceFrom == null) return;
      _playUnlockHapticIfNeeded();
      setState(() {});
    });
    _advanceController.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      if (!_advanceTicksEnabled) return;
      setState(() {
        _advanceFrom = null;
        _advanceTo = null;
        _anchorsReady = false;
        _advanceTicksEnabled = false;
      });
    });
    _scheduleScrollToUnlock();
  }

  @override
  void didUpdateWidget(SeriesEpisodeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final advanced = seriesOverviewUnlockAdvanced(
      before: oldWidget.overview,
      after: widget.overview,
    );
    if (advanced) {
      final generation = ++_advanceGeneration;
      _advanceHoldTimer?.cancel();
      _advanceTicksEnabled = false;
      _advanceFrom = null;
      _advanceTo = null;
      _anchorsReady = false;
      _anchorAttempts = 0;
      _heldOverview = oldWidget.overview;
      _episodeButtonsLocked = true;
      _unlockHapticPlayed = false;
      if (_advanceController.value != 0) {
        _advanceController.value = 0;
      }
      final from = seriesOverviewFirstUnlockIndex(oldWidget.overview);
      final to = seriesOverviewFirstUnlockIndex(widget.overview);
      _advanceHoldTimer = Timer(_unlockAdvanceHold, () {
        if (!mounted || generation != _advanceGeneration) return;
        setState(() {
          _heldOverview = null;
          _advanceFrom = from;
          _advanceTo = to;
          _anchorsReady = false;
          _anchorAttempts = 0;
        });
        _scheduleScrollToUnlock(advanceGeneration: generation);
      });
      return;
    }
    final overviewChanged = widget.overview != oldWidget.overview;
    final tokenChanged =
        widget.scrollToUnlockToken != oldWidget.scrollToUnlockToken;
    if (!overviewChanged && !tokenChanged) return;

    _advanceHoldTimer?.cancel();
    _heldOverview = null;
    _episodeButtonsLocked = false;
    if (_isAdvancing) {
      _advanceTicksEnabled = false;
      _advanceController.stop();
      _advanceFrom = null;
      _advanceTo = null;
      _anchorsReady = false;
    }
    _scheduleScrollToUnlock();
  }

  @override
  void dispose() {
    _advanceHoldTimer?.cancel();
    _advanceController.dispose();
    super.dispose();
  }

  void _scheduleScrollToUnlock({int? advanceGeneration}) {
    if (advanceGeneration == null &&
        _lastScrollToken == widget.scrollToUnlockToken) {
      return;
    }
    _lastScrollToken = widget.scrollToUnlockToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (advanceGeneration != null) {
        _beginAdvanceMotion(advanceGeneration);
        return;
      }
      _scrollToUnlockIfNeeded();
    });
  }

  void _beginAdvanceMotion(int generation) {
    if (!mounted || !_isAdvancing || generation != _advanceGeneration) return;
    if (!_tryCaptureAnchors()) {
      if (_anchorAttempts++ >= 5) {
        _advanceTicksEnabled = false;
        _advanceFrom = null;
        _advanceTo = null;
        _anchorsReady = false;
        _episodeButtonsLocked = false;
        if (mounted) setState(() {});
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _beginAdvanceMotion(generation);
      });
      return;
    }
    _anchorAttempts = 0;
    _episodeButtonsLocked = false;
    setState(() {});
    _advanceTicksEnabled = true;
    _advanceController.forward(from: 0);
    _scrollToUnlockIfNeeded(duration: _unlockAdvanceDuration);
  }

  void _playUnlockHapticIfNeeded() {
    if (_unlockHapticPlayed || _advanceController.value < _lockPopEnd) return;
    _unlockHapticPlayed = true;
    unawaited(_vibrateUnlock());
  }

  /// 자물쇠가 사라지고 Play가 들어오기 시작하는 순간. 짧은 강타 뒤 무거운 한 방.
  Future<void> _vibrateUnlock() async {
    try {
      await Vibration.vibrate(
        pattern: [0, 30, 40, 160],
        intensities: [0, 255, 0, 255],
        sharpness: 1,
      );
    } catch (_) {}
  }

  bool _tryCaptureAnchors() {
    final listBox = _listKey.currentContext?.findRenderObject();
    final fromBox = _rowKey(_advanceFrom!).currentContext?.findRenderObject();
    final toBox = _rowKey(_advanceTo!).currentContext?.findRenderObject();
    if (listBox is! RenderBox ||
        !listBox.hasSize ||
        fromBox is! RenderBox ||
        !fromBox.hasSize ||
        toBox is! RenderBox ||
        !toBox.hasSize) {
      return false;
    }
    _fromTop = listBox.globalToLocal(fromBox.localToGlobal(Offset.zero)).dy;
    _toTop = listBox.globalToLocal(toBox.localToGlobal(Offset.zero)).dy;
    _fromHeight = fromBox.size.height;
    _toHeight = toBox.size.height;
    _anchorsReady = true;
    return true;
  }

  void _scrollToUnlockIfNeeded({Duration? duration}) {
    final targetIndex = _isAdvancing
        ? _advanceTo
        : seriesOverviewFirstUnlockIndex(overview);
    if (targetIndex == null || targetIndex <= 0) return;

    final targetContext = _rowKey(targetIndex).currentContext;
    if (targetContext == null) return;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: duration ?? _scrollToUnlockDuration,
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
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

    return SizedBox(
      width: width,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_thumbRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnailPath == null || thumbnailPath.isEmpty
                ? const ColoredBox(color: Color(0xFF353535))
                : CdnThumbImage(
                    path: thumbnailPath,
                    slot: CdnThumbSlot.episodeCard,
                    fit: BoxFit.cover,
                    width: width,
                    height: imageHeight,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFF2A2A2A),
                      highlightColor: const Color(0xFF3F3F3F),
                      child: Container(
                        width: width,
                        height: imageHeight,
                        color: Colors.white,
                      ),
                    ),
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

  Widget _playLabelRow(BuildContext context, AppLocalizations l10n) {
    return Row(
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
    );
  }

  static const _playRadius = BorderRadius.all(Radius.circular(_playButtonHeight / 2));

  Widget _buildPlayButton(
    BuildContext context,
    AppLocalizations l10n,
    _EpisodePlayButtonKind kind,
    VoidCallback? onTap,
  ) {
    switch (kind) {
      case _EpisodePlayButtonKind.replay:
        return _replayChrome(
          context,
          onTap: onTap,
          borderWidth: 1,
          innerColor: Theme.of(context).scaffoldBackgroundColor,
          edgeColor: _tealDark,
          child: _playLabelRow(context, l10n),
        );
      case _EpisodePlayButtonKind.unlock:
        return _solidPlayButton(
          onTap: onTap,
          color: _mint,
          child: _playLabelRow(context, l10n),
        );
      case _EpisodePlayButtonKind.locked:
        return GestureDetector(
          onTap: () {
            DefaultToast.show(context, l10n.seriesOverviewEpisodeLockedToast);
          },
          behavior: HitTestBehavior.opaque,
          child: _lockedChrome(
            context,
            l10n,
            iconScale: 1,
            labelOpacity: 1,
          ),
        );
    }
  }

  /// 채움 Play(t=0)에서 테두리 Play(t=1)로 모프.
  Widget _buildReplayMorphButton(
    BuildContext context,
    AppLocalizations l10n,
    double t,
    VoidCallback? onTap,
  ) {
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    return _replayChrome(
      context,
      onTap: onTap,
      borderWidth: t,
      innerColor: Color.lerp(_mint, scaffold, t)!,
      edgeColor: Color.lerp(_mint, _tealDark, t)!,
      child: _playLabelRow(context, l10n),
    );
  }

  /// 자물쇠가 커졌다 사라진 뒤, 진행대기 Play가 오른쪽에서 들어온다.
  Widget _buildUnlockArriveButton(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback? onTap,
  ) {
    final t = _advanceController.value;
    final lockT = (t / _lockPopEnd).clamp(0.0, 1.0);
    final double iconScale;
    final double lockOpacity;
    if (lockT < 0.4) {
      iconScale = lerpDouble(1, 1.25, lockT / 0.4)!;
      lockOpacity = 1;
    } else {
      final shrink = (lockT - 0.4) / 0.6;
      iconScale = lerpDouble(1.25, 0, shrink)!;
      lockOpacity = 1 - shrink;
    }
    final slideT = ((t - _lockPopEnd) / (_playSlideEnd - _lockPopEnd))
        .clamp(0.0, 1.0);
    final slide = Curves.easeOutCubic.transform(slideT);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _playButtonHeight,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _lockedChrome(
              context,
              l10n,
              iconScale: iconScale,
              labelOpacity: lockOpacity,
            ),
            if (t >= _lockPopEnd)
              ClipRRect(
                borderRadius: _playRadius,
                child: FractionalTranslation(
                  translation: Offset(1 - slide, 0),
                  child: _solidPlayButton(
                    onTap: null,
                    color: _mint,
                    child: _playLabelRow(context, l10n),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _replayChrome(
    BuildContext context, {
    required double borderWidth,
    required Color innerColor,
    required Color edgeColor,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final innerRadius = BorderRadius.circular(
      (_playButtonHeight / 2 - borderWidth).clamp(0.0, _playButtonHeight / 2),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _playRadius,
          gradient: LinearGradient(
            colors: [_mint, edgeColor],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: innerRadius,
              color: innerColor,
            ),
            child: SizedBox(
              height: _playButtonHeight,
              width: double.infinity,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _solidPlayButton({
    required Color color,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: _playRadius,
        ),
        child: SizedBox(
          height: _playButtonHeight,
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }

  Widget _lockedChrome(
    BuildContext context,
    AppLocalizations l10n, {
    required double iconScale,
    required double labelOpacity,
  }) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _lockedFill,
        borderRadius: _playRadius,
      ),
      child: SizedBox(
        height: _playButtonHeight,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: iconScale,
              child: Opacity(
                opacity: labelOpacity.clamp(0.0, 1.0),
                child: Image.asset(
                  'assets/images/icons/lock.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Opacity(
              opacity: labelOpacity.clamp(0.0, 1.0),
              child: Text(
                l10n.seriesOverviewLocked,
                style: _playLabelStyle(context, color: _lockedText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GlobalKey _rowKey(int index) => _rowKeys.putIfAbsent(index, GlobalKey.new);

  Widget _buildEpisodeBlock(
    BuildContext context,
    RpS2SeriesEpisodeDto episode,
    int episodeNumber,
    _EpisodePlayButtonKind buttonKind, {
    Key? blockKey,
    bool highlight = false,
    Widget? playButton,
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
                playButton ??
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

    return KeyedSubtree(
      key: blockKey,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          if (highlight)
            const Positioned(
              left: -_unlockBlockHorizontalBleed,
              right: -_unlockBlockHorizontalBleed,
              top: -_unlockBlockVerticalBleed,
              bottom: -_unlockBlockVerticalBleed,
              child: ColoredBox(color: _unlockBlockBackground),
            ),
          KeyedSubtree(key: const ValueKey('episode-body'), child: block),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodes = overview.episodes;
    if (episodes.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final firstUnlockIndex = seriesOverviewFirstUnlockIndex(overview);
    final showMovingHighlight = _isAdvancing && _anchorsReady;
    final travel = showMovingHighlight
        ? Curves.easeInOut.transform(_advanceController.value)
        : 0.0;

    final column = Column(
      key: _listKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < episodes.length; i++) ...[
          if (i > 0) const SizedBox(height: _blockGap),
          _buildEpisodeBlock(
            context,
            episodes[i],
            i + 1,
            _buttonKind(i, firstUnlockIndex),
            blockKey: _rowKey(i),
            highlight: _showsStaticHighlight(i, firstUnlockIndex),
            playButton: _playButtonFor(context, l10n, i, episodes[i]),
          ),
        ],
      ],
    );

    if (!showMovingHighlight) return _ignoreEpisodeButtons(column);

    final top = lerpDouble(_fromTop, _toTop, travel)! - _unlockBlockVerticalBleed;
    final height =
        lerpDouble(_fromHeight, _toHeight, travel)! +
        _unlockBlockVerticalBleed * 2;

    return _ignoreEpisodeButtons(
      Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -_unlockBlockHorizontalBleed,
            right: -_unlockBlockHorizontalBleed,
            top: top,
            height: height,
            child: const IgnorePointer(
              child: ColoredBox(color: _unlockBlockBackground),
            ),
          ),
          column,
        ],
      ),
    );
  }

  Widget _ignoreEpisodeButtons(Widget child) {
    if (!_episodeButtonsLocked) return child;
    return IgnorePointer(child: child);
  }

  bool _showsStaticHighlight(int index, int? firstUnlockIndex) {
    if (_isAdvancing) {
      return !_anchorsReady && index == _advanceFrom;
    }
    return index == firstUnlockIndex;
  }

  Widget? _playButtonFor(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    RpS2SeriesEpisodeDto episode,
  ) {
    if (!_isAdvancing) return null;
    void onPlay() => widget.onPlayEpisode?.call(episode);
    if (index == _advanceFrom) {
      final t = Curves.easeInOut.transform(_advanceController.value);
      return _buildReplayMorphButton(context, l10n, t, onPlay);
    }
    if (index == _advanceTo) {
      return _buildUnlockArriveButton(context, l10n, onPlay);
    }
    return null;
  }
}
