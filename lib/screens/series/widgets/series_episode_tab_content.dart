import 'dart:async' show Timer, unawaited;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/app_config.dart';
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

/// 진행 대기가 앞으로 갔을 때, 연출할 마지막 한 칸.
/// [from]은 새 진행 대기 직전(방금 끝낸 칸), [to]는 새 진행 대기.
class SeriesOverviewUnlockStep {
  final int from;
  final int to;

  const SeriesOverviewUnlockStep({required this.from, required this.to});
}

SeriesOverviewUnlockStep? seriesOverviewLastUnlockStep({
  required RpS2SeriesOverviewDto before,
  required RpS2SeriesOverviewDto after,
}) {
  final beforeEpisodes = before.episodes;
  final afterEpisodes = after.episodes;
  if (beforeEpisodes.isEmpty ||
      beforeEpisodes.length != afterEpisodes.length) {
    return null;
  }
  for (var i = 0; i < beforeEpisodes.length; i++) {
    if (beforeEpisodes[i].id != afterEpisodes[i].id) return null;
  }
  final oldFrontier = seriesOverviewFirstUnlockIndex(before);
  final newFrontier = seriesOverviewFirstUnlockIndex(after);
  if (oldFrontier == null || newFrontier == null || newFrontier <= oldFrontier) {
    return null;
  }
  final from = newFrontier - 1;
  final completedId = afterEpisodes[from].id;
  if (!after.bestScoreMap.containsKey(completedId)) return null;
  if (after.bestScoreMap.containsKey(afterEpisodes[newFrontier].id)) {
    return null;
  }
  return SeriesOverviewUnlockStep(from: from, to: newFrontier);
}

RpS2SeriesOverviewDto seriesOverviewHoldBeforeUnlock(
  RpS2SeriesOverviewDto after,
  int from,
) {
  final scores = Map<int, int>.from(after.bestScoreMap)
    ..remove(after.episodes[from].id);
  return after.copyWith(bestScoreMap: scores);
}

/// 마지막 에피소드가 이번 갱신에서 처음 클리어된 경우.
bool seriesOverviewEndingJustUnlocked({
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
  final lastId = afterEpisodes.last.id;
  return !before.bestScoreMap.containsKey(lastId) &&
      after.bestScoreMap.containsKey(lastId);
}

/// Lab이 켠 뒤, 다음 Overview 로드가 한 번 가져간다.
class SeriesEndingUnlockPreview {
  SeriesEndingUnlockPreview._();

  static bool _armed = false;

  static void arm() => _armed = true;

  static bool take() {
    final armed = _armed;
    _armed = false;
    return armed;
  }
}

class SeriesEpisodeTabContent extends StatefulWidget {
  final RpS2SeriesOverviewDto overview;
  final void Function(RpS2SeriesEpisodeDto episode)? onPlayEpisode;
  final int scrollToUnlockToken;
  final int endingUnlockToken;
  final bool holdEndingUnlocked;
  final VoidCallback? onEndingUnlockSettled;
  final VoidCallback? onOpenEnding;

  const SeriesEpisodeTabContent({
    super.key,
    required this.overview,
    this.onPlayEpisode,
    this.scrollToUnlockToken = 0,
    this.endingUnlockToken = 0,
    this.holdEndingUnlocked = false,
    this.onEndingUnlockSettled,
    this.onOpenEnding,
  });

  @override
  State<SeriesEpisodeTabContent> createState() => _SeriesEpisodeTabContentState();
}

class _SeriesEpisodeTabContentState extends State<SeriesEpisodeTabContent>
    with TickerProviderStateMixin {
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
  static const _endingGap = 40.0;
  static const _endingCardHeight = 170.0;
  static const _endingImageWidthFactor = 0.35;
  static const _endingTextWidthFactor = 0.75;
  static const _endingBorderWidth = 2.0;
  static const _endingCardFill = Color(0xFF232323);
  static const _endingUnlockDuration = Duration(milliseconds: 700);
  static const _endingUnlockHold = Duration(milliseconds: 500);
  static const _endingShakeDuration = Duration(milliseconds: 360);
  static const _endingIconSize = 36.0;
  static const _endingGlyphSize = 22.0;
  static const _endingLineGap = 8.0;
  static const _endingLockBlur = 12.0;
  static const _unlockCircle = Color(0xFF80D7CF);
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
  late final AnimationController _endingController;
  late final AnimationController _endingShakeController;
  int _endingSeq = 0;
  bool _endingUnlockPlaying = false;

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
        if (!_endingUnlockPlaying) _episodeButtonsLocked = false;
      });
    });
    _endingController = AnimationController(
      vsync: this,
      duration: _endingUnlockDuration,
    );
    _endingShakeController = AnimationController(
      vsync: this,
      duration: _endingShakeDuration,
    );
    _endingController.addListener(() {
      if (!mounted || !_endingUnlockPlaying) return;
      setState(() {});
    });
    _endingShakeController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    if (widget.endingUnlockToken > 0) {
      _endingUnlockPlaying = true;
      _episodeButtonsLocked = true;
      final seq = ++_endingSeq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runEndingUnlock(seq));
      });
    } else {
      _scheduleScrollToUnlock();
    }
  }

  @override
  void didUpdateWidget(SeriesEpisodeTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endingUnlockToken != oldWidget.endingUnlockToken) {
      _armEndingUnlock();
      final seq = ++_endingSeq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runEndingUnlock(seq));
      });
      return;
    }
    final step = seriesOverviewLastUnlockStep(
      before: oldWidget.overview,
      after: widget.overview,
    );
    if (step != null) {
      final generation = ++_advanceGeneration;
      _advanceHoldTimer?.cancel();
      _advanceTicksEnabled = false;
      _advanceFrom = null;
      _advanceTo = null;
      _anchorsReady = false;
      _anchorAttempts = 0;
      _heldOverview = seriesOverviewHoldBeforeUnlock(widget.overview, step.from);
      _episodeButtonsLocked = true;
      _unlockHapticPlayed = false;
      if (_advanceController.value != 0) {
        _advanceController.value = 0;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_alignThenHoldUnlock(generation, step.from, step.to));
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
    _endingSeq++;
    _advanceHoldTimer?.cancel();
    _advanceController.dispose();
    _endingController.dispose();
    _endingShakeController.dispose();
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
    // Play는 칸 이동 애니 동안 누르지 못한다.
    setState(() {});
    _advanceTicksEnabled = true;
    _advanceController.forward(from: 0);
  }

  /// 홀드 전에 방금 끝낸 칸이 위에 오게 맞춘 뒤, 300ms 후 해금 연출을 시작한다.
  Future<void> _alignThenHoldUnlock(int generation, int from, int to) async {
    if (!mounted || generation != _advanceGeneration) return;
    final targetContext = _rowKey(from).currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (targetContext != null &&
        renderObject is RenderBox &&
        renderObject.hasSize) {
      try {
        await Scrollable.ensureVisible(
          targetContext,
          duration: _scrollToUnlockDuration,
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } catch (_) {}
    }
    if (!mounted || generation != _advanceGeneration) return;
    _advanceHoldTimer?.cancel();
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
    bool connectToEnding = false,
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
          if (connectToEnding)
            Positioned(
              left: leftWidth / 2 - 0.5,
              width: 1,
              top: leftWidth * 1.35,
              bottom: -_endingGap,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_tealDark, _mint],
                    ),
                  ),
                ),
              ),
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
            connectToEnding: i == episodes.length - 1,
            playButton: _playButtonFor(context, l10n, i, episodes[i]),
          ),
        ],
        const SizedBox(height: _endingGap),
        _buildEndingCard(),
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

  bool get _endingCleared {
    if (widget.holdEndingUnlocked) return true;
    final episodes = overview.episodes;
    if (episodes.isEmpty) return false;
    return overview.bestScoreMap.containsKey(episodes.last.id);
  }

  double get _endingMs =>
      _endingController.value * _endingUnlockDuration.inMilliseconds;

  double get _endingLockOpacity {
    if (!_endingUnlockPlaying) return _endingCleared ? 0 : 1;
    final ms = _endingMs;
    if (ms >= 150) return 0;
    return 1 - ms / 150;
  }

  double get _endingUnlockScale {
    if (!_endingUnlockPlaying) return _endingCleared ? 1 : 0;
    final ms = _endingMs;
    if (ms < 80) return 0;
    if (ms >= 480) return 1;
    final u = (ms - 80) / (480 - 80);
    if (u < 0.5) return lerpDouble(0.2, 1.12, u / 0.5)!;
    return lerpDouble(1.12, 1, (u - 0.5) / 0.5)!;
  }

  double get _endingDim {
    if (!_endingUnlockPlaying) return _endingCleared ? 0 : 0.7;
    final ms = _endingMs;
    if (ms >= 250) return 0;
    return lerpDouble(0.7, 0, ms / 250)!;
  }

  double get _endingBlur {
    if (!_endingUnlockPlaying) return _endingCleared ? 0 : _endingLockBlur;
    final ms = _endingMs;
    if (ms >= 250) return 0;
    return lerpDouble(_endingLockBlur, 0, ms / 250)!;
  }

  double get _endingCardScale {
    if (!_endingUnlockPlaying) return 1;
    final ms = _endingMs;
    if (ms < 200) return lerpDouble(1, 1.06, ms / 200)!;
    if (ms < 400) return lerpDouble(1.06, 1, (ms - 200) / 200)!;
    return 1;
  }

  double get _endingLockedCaptionOpacity {
    if (!_endingUnlockPlaying) return _endingCleared ? 0 : 1;
    final ms = _endingMs;
    if (ms >= 150) return 0;
    return 1 - ms / 150;
  }

  double get _endingTitleOpacity {
    if (!_endingUnlockPlaying) return _endingCleared ? 1 : 0;
    final ms = _endingMs;
    if (ms < 150) return 0;
    if (ms >= 400) return 1;
    return (ms - 150) / 250;
  }

  double get _endingTitleScale {
    if (!_endingUnlockPlaying) return 1;
    final ms = _endingMs;
    if (ms < 150 || ms >= 400) return 1;
    return lerpDouble(1.12, 1, (ms - 150) / 250)!;
  }

  double get _endingShakeDx {
    final t = _endingShakeController.value;
    if (t == 0) return 0;
    return math.sin(t * 3 * math.pi * 2) * 8;
  }

  void _armEndingUnlock() {
    _advanceHoldTimer?.cancel();
    _advanceTicksEnabled = false;
    _advanceController.stop();
    _endingShakeController.stop();
    _endingShakeController.value = 0;
    _heldOverview = null;
    _advanceFrom = null;
    _advanceTo = null;
    _anchorsReady = false;
    _endingUnlockPlaying = true;
    _episodeButtonsLocked = true;
    _endingController.value = 0;
  }

  Future<void> _runEndingUnlock(int seq) async {
    if (!mounted || seq != _endingSeq) return;
    final position = Scrollable.maybeOf(context)?.position;
    if (position != null && position.hasContentDimensions) {
      try {
        await position.animateTo(
          position.maxScrollExtent,
          duration: _scrollToUnlockDuration,
          curve: Curves.easeInOut,
        );
      } catch (_) {}
    }
    if (!mounted || seq != _endingSeq) return;
    await Future<void>.delayed(_endingUnlockHold);
    if (!mounted || seq != _endingSeq) return;
    unawaited(_vibrateEndingShake());
    try {
      await _endingController.forward(from: 0);
    } catch (_) {}
    if (!mounted || seq != _endingSeq) return;
    setState(() {
      _endingUnlockPlaying = false;
      _episodeButtonsLocked = false;
    });
    widget.onEndingUnlockSettled?.call();
  }

  Future<void> _vibrateEndingShake() async {
    try {
      await Vibration.vibrate(
        pattern: [30, 45, 75, 45, 75, 45],
        intensities: [0, 255, 0, 255, 0, 255],
        sharpness: 1,
      );
    } catch (_) {}
  }

  void _onEndingTap() {
    if (_endingUnlockPlaying) return;
    if (_endingCleared) {
      widget.onOpenEnding?.call();
      return;
    }
    if (_endingShakeController.isAnimating) return;
    unawaited(_vibrateEndingShake());
    _endingShakeController.forward(from: 0);
  }

  Widget _endingIconBadge({
    required Color color,
    required Widget icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox(
        width: _endingIconSize,
        height: _endingIconSize,
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildEndingCard() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final innerHeight = _endingCardHeight - _endingBorderWidth * 2;
    final innerRadius = BorderRadius.circular(
      (_playButtonHeight / 2 - _endingBorderWidth)
          .clamp(0.0, _playButtonHeight / 2),
    );
    final titleStyle = theme.bodyLarge?.copyWith(color: _mint);
    final captionStyle = theme.labelSmall?.copyWith(color: Colors.white);
    final endingTitle = SudaJsonUtil.localizedMapText(overview.endingTitle);
    final lockOpacity = _endingLockOpacity.clamp(0.0, 1.0);
    final unlockScale = _endingUnlockScale;
    final lockedCaptionOpacity = _endingLockedCaptionOpacity.clamp(0.0, 1.0);
    final titleOpacity = _endingTitleOpacity.clamp(0.0, 1.0);

    final card = GestureDetector(
      onTap: _onEndingTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _endingCardHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: _playRadius,
            gradient: LinearGradient(colors: [_mint, _tealDark]),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_endingBorderWidth),
            child: ClipRRect(
              borderRadius: innerRadius,
              child: ColoredBox(
                color: _endingCardFill,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dpr = MediaQuery.devicePixelRatioOf(context);
                    final imageWidth =
                        (constraints.maxWidth * _endingImageWidthFactor * dpr)
                                .round() /
                            dpr;
                    final textWidth =
                        (constraints.maxWidth * _endingTextWidthFactor * dpr)
                                .round() /
                            dpr;
                    return Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _EndingArtwork(
                      path: overview.endingImgPath,
                      width: imageWidth,
                      height: innerHeight,
                      dim: _endingDim.clamp(0.0, 1.0),
                      blur: _endingBlur,
                    ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: textWidth,
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SizedBox(
                              width: _endingIconSize,
                              height: _endingIconSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: lockOpacity,
                                    child: _endingIconBadge(
                                      color: _lockedFill,
                                      icon: const ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        child: Image(
                                          image: AssetImage(
                                            'assets/images/icons/lock.png',
                                          ),
                                          width: _endingGlyphSize,
                                          height: _endingGlyphSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (unlockScale > 0)
                                    Transform.scale(
                                      scale: unlockScale,
                                      child: _endingIconBadge(
                                        color: _unlockCircle,
                                        icon: const ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                            Color(0xFF353535),
                                            BlendMode.srcIn,
                                          ),
                                          child: Image(
                                            image: AssetImage(
                                              'assets/images/icons/unlock.png',
                                            ),
                                            width: _endingGlyphSize,
                                            height: _endingGlyphSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: _endingLineGap),
                          Text(
                            l10n.seriesOverviewEndingLabel,
                            textAlign: TextAlign.center,
                            style: titleStyle,
                          ),
                          const SizedBox(height: _endingLineGap),
                          Align(
                            child: FractionallySizedBox(
                              widthFactor: 0.8,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: lockedCaptionOpacity,
                                    child: Text(
                                      l10n.seriesOverviewEndingLockedCaption,
                                      textAlign: TextAlign.center,
                                      style: captionStyle,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: titleOpacity,
                                    child: Transform.scale(
                                      scale: _endingTitleScale,
                                      child: Text(
                                        endingTitle,
                                        textAlign: TextAlign.center,
                                        style: captionStyle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Transform.translate(
      offset: Offset(_endingShakeDx, 0),
      child: Transform.scale(
        scale: _endingCardScale,
        alignment: Alignment.center,
        child: card,
      ),
    );
  }

  Widget _ignoreEpisodeButtons(Widget child) {
    if (!_episodeButtonsLocked && !_endingUnlockPlaying) return child;
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

class _EndingArtwork extends StatefulWidget {
  final String? path;
  final double width;
  final double height;
  final double dim;
  final double blur;

  const _EndingArtwork({
    required this.path,
    required this.width,
    required this.height,
    required this.dim,
    required this.blur,
  });

  @override
  State<_EndingArtwork> createState() => _EndingArtworkState();
}

class _EndingArtworkState extends State<_EndingArtwork> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;
  String? _resolvedPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_EndingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _resolve();
  }

  void _resolve() {
    final path = widget.path;
    if (path == null || path.isEmpty) {
      _stop();
      if (_info != null || _resolvedPath != null) {
        setState(() {
          _info = null;
          _resolvedPath = null;
        });
      }
      return;
    }
    if (_resolvedPath == path && _stream != null) return;
    _stop();
    _resolvedPath = path;
    final provider = CachedNetworkImageProvider('${AppConfig.cdnBaseUrl}$path');
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _stream = stream;
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _info = info);
    }, onError: (_, _) {
      if (!mounted) return;
      setState(() => _info = null);
    });
    stream.addListener(_listener!);
  }

  void _stop() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final image = info?.image;
    final dim = widget.dim <= 0
        ? null
        : ColoredBox(
            color: const Color(0xFF121212).withValues(alpha: widget.dim),
          );
    final pictureHeight = image == null
        ? widget.height
        : widget.width * image.height / image.width;
    final picture = image == null
        ? const ColoredBox(color: Color(0xFF121212))
        : RawImage(image: image, fit: BoxFit.fill);
    final frame = SizedBox(
      width: widget.width,
      height: pictureHeight,
      child: picture,
    );
    final blurred = widget.blur <= 0
        ? frame
        : ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: widget.blur,
              sigmaY: widget.blur,
              tileMode: TileMode.decal,
            ),
            child: frame,
          );
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            clipBehavior: Clip.hardEdge,
            child: OverflowBox(
              alignment: Alignment.center,
              minWidth: widget.width,
              maxWidth: widget.width,
              minHeight: pictureHeight,
              maxHeight: pictureHeight,
              child: blurred,
            ),
          ),
          ?dim,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0x00232323),
                  Color(0x00232323),
                  Color(0xFF232323),
                ],
                stops: [0, 0.75, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
