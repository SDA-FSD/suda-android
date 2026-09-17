import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:marquee/marquee.dart';

import '../../l10n/app_localizations.dart';
import '../../models/rank_models.dart';
import '../../models/user_models.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gnb_bar.dart';
import 'rank_claimable_sheet.dart';
import 'rank_podium_painter.dart';
import 'top_3_rewards_popup.dart';

/// Weekly Ranking Main Screen (GNB Ranking 탭).
/// GET /v1/rank/period/current + GET /v1/rank/entries.
/// myEntry는 API 필드 없이 entries의 isMe(또는 userId)로 찾고 sticky/inline만 적용.
class RankScreen extends StatefulWidget {
  const RankScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToAlarm,
    this.onNavigateToProfile,
    this.isActive = false,
    this.user,
    this.showNotiboxUnreadBadge = false,
  });

  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToAlarm;
  final VoidCallback? onNavigateToProfile;
  final bool isActive;
  final UserDto? user;
  final bool showNotiboxUnreadBadge;

  static const String routeName = '/rank';

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  static const _defaultProfile =
      'assets/images/icons/default_profile_image.png';
  static const _premiumBadge = 'assets/images/icons/premium_verified_badge.png';
  static const _podiumCrown = 'assets/images/icons/ranking_1st_crown.png';

  /// Figma 440 프레임 기준 포디움(왕관 top→포디움 베이스 bottom).
  static const _figmaFrameW = 440.0;
  static const _figmaPodiumOriginY = 71.0;
  // 포디움 베이스: 폭 408(+24 균등), 440 프레임 안 좌우 여백 균등(baseX=16).
  static const _figmaPodiumBaseX = RankPodiumGeometry.baseXInFrame;
  static const _figmaPodiumBaseY = 290.0;
  static const _figmaPodiumBaseW = RankPodiumGeometry.width;
  static const _figmaPodiumBaseH = 150.0;
  static const _figmaPodiumBottomY = _figmaPodiumBaseY + _figmaPodiumBaseH;
  static const _figmaPodiumH = _figmaPodiumBottomY - _figmaPodiumOriginY;

  /// 포디움 단 폭·로컬 x (= wireframe 세로 경계와 동일).
  static const _step2W = RankPodiumGeometry.step2W;
  static const _step1W = RankPodiumGeometry.step1W;
  static const _step3W = RankPodiumGeometry.step3W;
  static const _step1LocalX = RankPodiumGeometry.step1LocalX;
  static const _step3LocalX = RankPodiumGeometry.step3LocalX;

  /// 포디움 큰 숫자 폰트 크기 (Figma 440 기준 × s).
  static const _podiumNumFontSize = 64.0;

  /// sticky(`_RankListRow`) 높이. 리스트 하단 패딩으로 마지막 행이 sticky에 가리지 않게 함.
  static const _stickyListBottomPad = 56.0;

  RankScreenDto? _screen;

  /// 스냅샷에서 찾은 나. sticky/inline용. (live ripple 없음 — API myEntry 없음)
  RankEntryDto? _myEntryKept;
  List<RankEntryDto> _listRows = const [];
  String? _snapshotMinute;
  int? _nextPageNum;
  bool _hasMorePages = false;
  bool _loadingMore = false;
  bool _inlineMeVisible = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _meRowKey = GlobalKey();
  bool _loading = true;
  bool _loadFailed = false;

  /// phaseEndsAt - serverNow 기준 남은 시간. 기기 시계만으로 절대시각 계산하지 않음.
  Duration _remainingAtFetch = Duration.zero;
  DateTime? _fetchedAtLocal;
  Timer? _tickTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadScreen());
  }

  @override
  void didUpdateWidget(covariant RankScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _jumpToListTop();
      unawaited(_loadScreen());
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScreen() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _screen = null;
          _loading = false;
          _loadFailed = true;
        });
        return;
      }
      final dto = await SudaApiClient.getRankScreen(accessToken: token);
      if (!mounted) return;
      _myEntryKept = _resolveMe(dto.myEntry, dto.listEntries, dto.topEntries);
      _listRows = dto.listEntries;
      _snapshotMinute = dto.snapshotMinute;
      _nextPageNum = dto.nextPageNum;
      _hasMorePages = dto.hasMore;
      _inlineMeVisible = false;
      debugPrint(
        'rank screen loaded rows=${_listRows.length} hasMore=$_hasMorePages '
        'next=$_nextPageNum total=${dto.total} liveRankSize=${dto.period?.liveRankSize} '
        'snap=$_snapshotMinute',
      );
      _applyCountdown(dto.period);
      setState(() {
        _screen = dto;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 탭 복귀·리로드 시 항상 4위부터
        _jumpToListTop();
        _updateInlineMeVisibility();
        // page0(≤50)만으로는 끝이 안 보일 수 있음 → 바로 다음 page 로드 시도
        unawaited(_loadMore());
      });
      // Claimable 시트: RankScreenDto에 claimable 없음 — 절대 show 하지 않음.
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _applyCountdown(RankPeriodDto? period) {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (period?.phaseEndsAt == null || period?.serverNow == null) {
      _remainingAtFetch = Duration.zero;
      _fetchedAtLocal = null;
      _remaining = Duration.zero;
      return;
    }
    final ends = period!.phaseEndsAt!;
    final serverNow = period.serverNow!;
    var rem = ends.difference(serverNow);
    if (rem.isNegative) rem = Duration.zero;
    _remainingAtFetch = rem;
    _fetchedAtLocal = DateTime.now();
    _remaining = rem;
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _fetchedAtLocal == null) return;
      final elapsed = DateTime.now().difference(_fetchedAtLocal!);
      var next = _remainingAtFetch - elapsed;
      if (next.isNegative) next = Duration.zero;
      setState(() => _remaining = next);
    });
  }

  String _titleText(AppLocalizations l10n) {
    final phase = _screen?.period?.phase;
    if (phase == 'ANNOUNCE') return "This Week's Results";
    return l10n.rankWeeklyTitle;
  }

  /// 랭킹 종료까지 남은 시간.
  /// ≥48h → 일(+en `days left`), 24h~48h → 1일, 1h~24h → 시, <1h → 분(`min`).
  static String formatRemaining(Duration d, AppLocalizations l10n) {
    if (d <= Duration.zero) return '0';
    final days = d.inDays;
    if (days >= 1) return l10n.rankCountdownDays(days);
    final hours = d.inHours;
    if (hours >= 1) return l10n.rankCountdownHours(hours);
    final minutes = d.inMinutes;
    if (minutes <= 0) return '0';
    return l10n.rankCountdownMinutes(minutes);
  }

  RankEntryDto? _entryAt(int rank) {
    final list = _screen?.topEntries ?? const <RankEntryDto>[];
    for (final e in list) {
      if (e.rank == rank) return e;
    }
    return null;
  }

  RankEntryDto? _resolveMe(
    RankEntryDto? hint,
    List<RankEntryDto> listRows,
    List<RankEntryDto> topEntries,
  ) {
    if (hint != null) return hint.copyWith(isMe: true);
    final id = widget.user?.id;
    for (final e in [...topEntries, ...listRows]) {
      if (e.isMe || (id != null && e.userId == id)) {
        return e.copyWith(isMe: true);
      }
    }
    return null;
  }

  List<RankEntryDto> _buildDisplayRows() {
    final meId = widget.user?.id;
    final me = _myEntryKept;
    final base = [..._listRows]..sort((a, b) => a.rank.compareTo(b.rank));
    return base
        .map((e) {
          final isMe = e.isMe ||
              (meId != null && e.userId == meId) ||
              (me != null && e.userId == me.userId);
          return e.copyWith(isMe: isMe);
        })
        .toList();
  }

  void _jumpToListTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    _updateInlineMeVisibility();
    _requestLoadMoreIfNeeded();
  }

  void _requestLoadMoreIfNeeded() {
    if (!_hasMorePages || _nextPageNum == null || _loadingMore) return;
    if (!_scrollController.hasClients) {
      unawaited(_loadMore());
      return;
    }
    final pos = _scrollController.position;
    // maxScrollExtent가 작거나(첫 페이지가 화면을 다 못 채움) 하단 근처면 다음 page
    if (pos.maxScrollExtent <= 240 ||
        pos.pixels >= pos.maxScrollExtent - 480) {
      unawaited(_loadMore());
    }
  }

  void _updateInlineMeVisibility() {
    final me = _myEntryKept;
    if (me == null || me.rank <= 10) {
      if (_inlineMeVisible) setState(() => _inlineMeVisible = false);
      return;
    }
    if (!_scrollController.hasClients) {
      if (_inlineMeVisible) setState(() => _inlineMeVisible = false);
      return;
    }
    final ctx = _meRowKey.currentContext;
    if (ctx == null) {
      if (_inlineMeVisible) setState(() => _inlineMeVisible = false);
      return;
    }
    final render = ctx.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(render);
    if (viewport == null) {
      if (_inlineMeVisible) setState(() => _inlineMeVisible = false);
      return;
    }
    final position = _scrollController.position;
    final itemTop = viewport.getOffsetToReveal(render, 0.0).offset;
    final itemBottom = itemTop + render.size.height;
    final pixels = position.pixels;
    final visible =
        itemBottom > pixels && itemTop < pixels + position.viewportDimension;
    if (visible != _inlineMeVisible) {
      setState(() => _inlineMeVisible = visible);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMorePages || _nextPageNum == null) return;
    final token = await TokenStorage.loadAccessToken();
    if (token == null || token.isEmpty) return;
    final requestingPage = _nextPageNum!;
    setState(() => _loadingMore = true);
    try {
      final page = await SudaApiClient.getRankEntries(
        accessToken: token,
        pageNum: requestingPage,
        snapshotMinute: _snapshotMinute,
      );
      if (!mounted) return;
      debugPrint(
        'rank loadMore page=$requestingPage entries=${page.entries.length} '
        'hasMore=${page.hasMore} next=${page.nextPageNum} total=${page.total}',
      );
      final merged = [..._listRows];
      final seen = merged.map((e) => e.userId).toSet();
      for (final entry in page.entries) {
        if (entry.rank < 4) continue;
        if (seen.add(entry.userId)) {
          merged.add(entry);
        }
      }
      final me = _myEntryKept ??
          _resolveMe(null, merged, _screen?.topEntries ?? const []);
      final bool inferredHasMore;
      final int? inferredNext;
      if (page.entries.isEmpty) {
        // 빈 page면 서버 플래그만 신뢰 (무한 재요청 방지)
        inferredHasMore = page.hasMore;
        inferredNext = page.nextPageNum;
      } else {
        final maxRank = merged.isEmpty
            ? 0
            : merged.map((e) => e.rank).reduce((a, b) => a > b ? a : b);
        inferredHasMore = page.hasMore ||
            (page.total > 0 && maxRank < page.total);
        inferredNext = page.nextPageNum ??
            (inferredHasMore ? requestingPage + 1 : null);
      }
      setState(() {
        _listRows = merged;
        _nextPageNum = inferredNext;
        _hasMorePages = inferredHasMore && inferredNext != null;
        _loadingMore = false;
        if (me != null) _myEntryKept = me;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateInlineMeVisibility();
        if (_myEntryKept == null && _hasMorePages) {
          unawaited(_loadMore());
        } else {
          _requestLoadMoreIfNeeded();
        }
      });
    } catch (e, st) {
      debugPrint('rank loadMore FAILED page=$requestingPage: $e\n$st');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Claimable 레이어 자리만 분리 — 현재 child는 본문만, 시트는 띄우지 않음.
    final periodNull = _screen != null && _screen!.period == null;
    final showContent =
        !_loading && !periodNull && !(_loadFailed && _screen == null);
    final hasMeOnScreen = (_screen?.topEntries ?? const <RankEntryDto>[]).any(
      (e) => e.isMe,
    );
    // 실제 미참여만. (리스트에 내가 있으면 오버레이 금지)
    final showNotRanked =
        showContent &&
        _screen != null &&
        _myEntryKept == null &&
        !hasMeOnScreen;
    final showSticky = showContent &&
        _myEntryKept != null &&
        _myEntryKept!.rank > 10 &&
        !_inlineMeVisible;

    return RankClaimableSheet(
      child: AppScaffold(
        showBackButton: false,
        usePadding: false,
        bodyTopPadding: 16,
        backgroundColor: const Color(0xFF0D011F),
        background: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF843DF2), Color(0xFF0D011F)],
            ),
          ),
        ),
        bottomNavigationBar: GnbBar(
          isHomeActive: false,
          isAlarmActive: false,
          isRankActive: true,
          isProfileActive: false,
          showNotiboxUnreadBadge: widget.showNotiboxUnreadBadge,
          onHomeTap: widget.onNavigateToHome,
          onAlarmTap: widget.onNavigateToAlarm,
          onRankTap: () {},
          onProfileTap: widget.onNavigateToProfile,
          user: widget.user,
        ),
        // GNB와 동일 Stack · 전체 폭 · GNB 위 4px
        aboveBottomBar: showNotRanked
            ? _RankNotRankedOverlay(onPlayNow: widget.onNavigateToHome)
            : showSticky
            ? _RankMyEntrySticky(
                entry: _myEntryKept!,
                defaultProfile: _defaultProfile,
                premiumBadge: _premiumBadge,
              )
            : null,
        body: _buildBody(
          context,
          // sticky 가능 구간은 토글과 무관하게 패딩 유지(나타남/사라짐 점프 방지)
          listBottomPad: (_myEntryKept != null && _myEntryKept!.rank > 10)
              ? _stickyListBottomPad
              : 0,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {double listBottomPad = 0}) {
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + GnbBar.contentHeight;
    final periodNull = _screen != null && _screen!.period == null;
    const side = 24.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: side),
            child: _buildHeader(context),
          ),
          const SizedBox(height: 8),
          if (_loading && _screen == null)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (periodNull)
            const Expanded(child: SizedBox.shrink())
          else if (_loadFailed && _screen == null)
            Expanded(
              child: Center(
                child: TextButton(
                  onPressed: () => unawaited(_loadScreen()),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 포디움/헤더는 좌우 24. 리스트는 전체 폭(본인 하이라이트 full-bleed).
                  final contentConstraints = BoxConstraints(
                    maxWidth: (constraints.maxWidth - side * 2).clamp(
                      0.0,
                      double.infinity,
                    ),
                    maxHeight: constraints.maxHeight,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: side),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPodium(context, contentConstraints),
                            const SizedBox(height: 12),
                            _buildListHeader(context, contentConstraints),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final displayRows = _buildDisplayRows()
                                .where((e) => e.rank >= 4)
                                .toList();
                            final itemCount =
                                displayRows.length + (_loadingMore ? 1 : 0);
                            return ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.only(bottom: listBottomPad),
                              clipBehavior: Clip.hardEdge,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: itemCount,
                              itemBuilder: (context, index) {
                                if (index >= displayRows.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final entry = displayRows[index];
                                if (_hasMorePages &&
                                    index >= displayRows.length - 5) {
                                  unawaited(_loadMore());
                                }
                                return _RankListRow(
                                  key: entry.isMe ? _meRowKey : null,
                                  rank: entry.rank,
                                  entry: entry,
                                  defaultProfile: _defaultProfile,
                                  premiumBadge: _premiumBadge,
                                  contentHorizontal: side,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final showCountdown = _screen?.period != null;
    // 피그마: ? 18. 타이틀 옆 갭은 살짝 여유(6). 왼쪽 스페이서로 타이틀 가로 중앙 유지.
    const helpSize = 18.0;
    const helpGap = 6.0;
    // 카운트다운: 순백 대신 반투명 화이트 (피그마 톤).
    const countdownFg = Color(0xB3FFFFFF); // ~70%
    final titleStyle = theme.headlineMedium?.copyWith(
      color: Colors.white,
      height: 1.0,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: helpGap + helpSize),
            Flexible(
              child: Text(
                _titleText(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
            ),
            const SizedBox(width: helpGap),
            GestureDetector(
              onTap: () => unawaited(showTop3RewardsPopup(context)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Image.asset(
                  'assets/images/icons/help_circle.png',
                  width: helpSize,
                  height: helpSize,
                ),
              ),
            ),
          ],
        ),
        if (showCountdown) ...[
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: 0.7,
                child: Image.asset(
                  'assets/images/icons/clock.png',
                  width: 15,
                  height: 15,
                ),
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: const Offset(0, -1.0),
                child: Text(
                  formatRemaining(_remaining, l10n),
                  style: theme.bodySmall?.copyWith(color: countdownFg),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 포디움 스케일: 가로만 (contentWidth/440).
  /// 1~10을 한 화면에 맞추려고 높이로 줄이지 않음 — 스크롤 허용.
  double _podiumScale(BoxConstraints bodyConstraints) {
    final maxW = bodyConstraints.maxWidth;
    if (!maxW.isFinite || maxW <= 0) return 1;
    return maxW / _figmaFrameW;
  }

  static const _podiumDown = 22.0;

  Widget _buildPodium(BuildContext context, BoxConstraints bodyConstraints) {
    final first = _entryAt(1);
    final second = _entryAt(2);
    final third = _entryAt(3);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 가로 스케일만 적용 — 프로필·왕관·선·숫자 동일 비율.
        final s = _podiumScale(bodyConstraints);

        // 포디움 베이스 중심을 화면 가로 중앙에 고정. s = maxW/440 유지.
        final contentMidX = _figmaPodiumBaseX + _figmaPodiumBaseW / 2.0;
        final originX = constraints.maxWidth / 2.0 - contentMidX * s;
        double x(double figmaX) => originX + figmaX * s;
        double y(double figmaY) => (figmaY - _figmaPodiumOriginY) * s;
        // 프로필은 두고 선·숫자만 아래로 (좋아요와 가로선 겹침 해소).
        const podiumDown = _podiumDown;
        double podiumY(double figmaY) => y(figmaY + podiumDown);
        // 가로선 우측이 width+0.5 이므로 +1 여유.
        final podiumPaintW = (_figmaPodiumBaseW + 1.0) * s;
        final podiumPaintH = _figmaPodiumBaseH * s;

        return SizedBox(
          width: constraints.maxWidth,
          height: (_figmaPodiumH + podiumDown) * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // wireframe
              Positioned(
                left: x(_figmaPodiumBaseX),
                top: podiumY(_figmaPodiumBaseY),
                width: podiumPaintW,
                height: podiumPaintH,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(podiumPaintW, podiumPaintH),
                    painter: RankPodiumBasePainter(scale: s),
                  ),
                ),
              ),
              // 단 안 숫자 1/2/3 (선과 함께 하향)
              Positioned(
                left: x(_figmaPodiumBaseX),
                top: podiumY(_figmaPodiumBaseY + 65),
                width: _step2W * s,
                height: 68 * s,
                child: IgnorePointer(
                  child: Center(
                    child: PodiumRankNumber(
                      digit: '2',
                      scale: s,
                      style: TextStyle(
                        fontSize: _podiumNumFontSize * s,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x(_figmaPodiumBaseX + _step1LocalX),
                top: podiumY(_figmaPodiumBaseY + 2),
                width: _step1W * s,
                height: 146 * s,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 6 * s),
                      child: PodiumRankNumber(
                        digit: '1',
                        scale: s,
                        style: TextStyle(
                          fontSize: _podiumNumFontSize * s,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x(_figmaPodiumBaseX + _step3LocalX),
                top: podiumY(_figmaPodiumBaseY + 82),
                width: _step3W * s,
                height: 68 * s,
                child: IgnorePointer(
                  child: Center(
                    child: PodiumRankNumber(
                      digit: '3',
                      scale: s,
                      style: TextStyle(
                        fontSize: _podiumNumFontSize * s,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              // 2위 — 프로필 Y 유지, 슬롯 전체 왼쪽
              Positioned(
                left: x(_figmaPodiumBaseX) - 12 * s,
                top: y(192),
                width: _step2W * s,
                child: _PodiumSlot(
                  entry: second,
                  scale: s,
                  stepWidth: _step2W,
                  winnerFrame: false,
                  showCrown: false,
                  defaultProfile: _defaultProfile,
                  premiumBadge: _premiumBadge,
                  crownAsset: _podiumCrown,
                ),
              ),
              // 3위 — 프로필 Y 유지, 슬롯 전체 오른쪽
              Positioned(
                left: x(_figmaPodiumBaseX + _step3LocalX) + 12 * s,
                top: y(212),
                width: _step3W * s,
                child: _PodiumSlot(
                  entry: third,
                  scale: s,
                  stepWidth: _step3W,
                  winnerFrame: false,
                  showCrown: false,
                  defaultProfile: _defaultProfile,
                  premiumBadge: _premiumBadge,
                  crownAsset: _podiumCrown,
                ),
              ),
              // 1위
              Positioned(
                left: x(_figmaPodiumBaseX + _step1LocalX),
                top: y(128),
                width: _step1W * s,
                child: _PodiumSlot(
                  entry: first,
                  scale: s,
                  stepWidth: _step1W,
                  winnerFrame: true,
                  showCrown: true,
                  defaultProfile: _defaultProfile,
                  premiumBadge: _premiumBadge,
                  crownAsset: _podiumCrown,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 헤더 높이. 폰트 14 클리핑 방지용으로 여유.
  static const _headerBoxH = 20.0;

  Widget _buildListHeader(BuildContext context, BoxConstraints _) {
    // BlendMode.overlay는 스크롤 시 레이어 분리로 순백 플래시 → #9742FF 고정.
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      color: const Color(0xFF9742FF),
      fontSize: 14,
      height: 1.0,
    );

    // Rank/Player: 이전 위치 유지. Like만 top을 더 내려 같은 줄로 맞춤.
    return SizedBox(
      height: _headerBoxH,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 3,
            child: Text('Rank', style: style, softWrap: false),
          ),
          Positioned(
            left: 48,
            top: 3,
            child: Text('Player', style: style, softWrap: false),
          ),
          Positioned(
            right: 20,
            top: 8,
            child: Text('Like', style: style, softWrap: false),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.scale,
    required this.stepWidth,
    required this.winnerFrame,
    required this.showCrown,
    required this.defaultProfile,
    required this.premiumBadge,
    required this.crownAsset,
  });

  final RankEntryDto? entry;
  final double scale;

  /// 단(=가로선) 폭 — 아바타·이름·좋아요를 이 폭 기준 가운데 정렬.
  final double stepWidth;
  final bool winnerFrame;
  final bool showCrown;
  final String defaultProfile;
  final String premiumBadge;
  final String crownAsset;

  static const _boxH = 126.0;
  static const _badge = 34.0;
  static const _badgeFont = 22.0;

  /// 아바타 112 기준 우하단 뱃지 (기존 104 비율 유지).
  static const _badgeLeft = 84.0;
  static const _badgeTop = 83.0;

  /// 프로필·뱃지 약간 키움 (레이아웃 동일). 아바타 104→114 중심 고정 확대.
  static const _avatarOuter = 114.0;
  static const _borderW = 3.8;
  // 왕관: Figma bbox 상대좌표. 크기 고정, 아바타 확대분(5px)만 위치 보정.
  // 원래(104 기준) left=-7.31, top=-57 → 114 좌상단 이동분(-5,-5) 반영.
  static const _crownW = 154.77;
  static const _crownH = 118.33;
  static const _crownLeftOnAvatar = -7.31 - 5.0 + 12.0; // -0.31
  static const _crownTopOnAvatar = -57.0 - 5.0 + 3.0; // -59
  static const _likesToLineGap = 8.0;

  /// 이름 ↔ 좋아요 간격.
  static const _nameToLikesGap = 5.0;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final name = (entry?.name ?? '').trim();
    // 빈자리·이름 없음 → "—".
    final displayName = name.isEmpty ? '—' : name;
    final isPremium = entry?.subscribedYn == 'Y';
    const attrSize = 14.0;
    final avatarLeft = (stepWidth - _avatarOuter) / 2.0;

    return SizedBox(
      width: stepWidth * s,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: stepWidth * s,
            height: _boxH * s,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: avatarLeft * s,
                  child: _RankProfileFrame(
                    imgPath: entry?.imgPath,
                    outer: _avatarOuter * s,
                    borderWidth: _borderW * s,
                    style: winnerFrame
                        ? _RankProfileFrameStyle.winner
                        : (isPremium
                              ? _RankProfileFrameStyle.premium
                              : _RankProfileFrameStyle.podiumFree),
                    defaultAsset: defaultProfile,
                    outerShadowScale: s,
                  ),
                ),
                if (entry != null)
                  Positioned(
                    left: (avatarLeft + _badgeLeft) * s,
                    top: _badgeTop * s,
                    child: _PodiumLevelBadge(
                      level: entry!.level,
                      size: _badge * s,
                      fontSize: _badgeFont * s,
                    ),
                  ),
                if (showCrown)
                  Positioned(
                    left: (avatarLeft + _crownLeftOnAvatar) * s,
                    top: _crownTopOnAvatar * s,
                    child: IgnorePointer(
                      child: Image.asset(
                        crownAsset,
                        width: _crownW * s,
                        height: _crownH * s,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4 * s),
          SizedBox(
            width: stepWidth * s,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'ChironHeiHK',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontVariations: [FontVariation('wght', 700)],
                      fontSize: attrSize,
                      height: 1.1,
                    ),
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(width: 4),
                  Image.asset(premiumBadge, width: attrSize, height: attrSize),
                ],
              ],
            ),
          ),
          if (entry != null) ...[
            SizedBox(height: _nameToLikesGap * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/like_at_result.png',
                  width: attrSize,
                  height: attrSize,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry!.weeklyLike}',
                  style: const TextStyle(
                    fontFamily: 'ChironHeiHK',
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontVariations: [FontVariation('wght', 400)],
                    fontSize: attrSize,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: _likesToLineGap * s),
        ],
      ),
    );
  }
}

enum _RankProfileFrameStyle { winner, premium, free, podiumFree }

/// 1위: 흰→금. 2·3위 일반: 흰→#0CABA8. 그 외: Profile과 동일.
class _RankProfileFrame extends StatelessWidget {
  const _RankProfileFrame({
    required this.imgPath,
    required this.outer,
    required this.borderWidth,
    required this.style,
    required this.defaultAsset,
    this.outerShadowScale,
  });

  final String? imgPath;
  final double outer;
  final double borderWidth;
  final _RankProfileFrameStyle style;
  final String defaultAsset;

  /// non-null이면 Paywall `_cardShadow`(Offset/Blur 20, #000000 30%) 적용·스케일.
  final double? outerShadowScale;

  static const _winnerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFB700)],
  );

  static const _premiumGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF80D7CF), Color(0xFF8A38F5)],
  );

  static const _freeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF80D7CF), Color(0xFF43716D)],
  );

  /// 2·3위 일반 유저 (SVG: 위 #FFFFFF → 아래 #0CABA8).
  static const _podiumFreeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFF0CABA8)],
  );

  static const _innerFill = Colors.white;
  static const _podiumFreeInnerFill = Color(0xFFD9D9D9);

  /// `paywall.dart` `_cardShadow`와 동일 스펙.
  static const _figmaOuterShadowColor = Color(0x4D000000);
  static const _figmaOuterShadow = 20.0;

  @override
  Widget build(BuildContext context) {
    final inner = (outer - borderWidth * 2).clamp(1.0, outer);
    final Gradient gradient = switch (style) {
      _RankProfileFrameStyle.winner => _winnerGradient,
      _RankProfileFrameStyle.premium => _premiumGradient,
      _RankProfileFrameStyle.free => _freeGradient,
      _RankProfileFrameStyle.podiumFree => _podiumFreeGradient,
    };
    final innerFill = style == _RankProfileFrameStyle.podiumFree
        ? _podiumFreeInnerFill
        : _innerFill;
    final shadowScale = outerShadowScale;
    final shadows = shadowScale == null
        ? null
        : <BoxShadow>[
            BoxShadow(
              color: _figmaOuterShadowColor,
              offset: Offset(
                _figmaOuterShadow * shadowScale,
                _figmaOuterShadow * shadowScale,
              ),
              blurRadius: _figmaOuterShadow * shadowScale,
              spreadRadius: 0,
            ),
          ];

    return Container(
      width: outer,
      height: outer,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: innerFill,
        ),
        clipBehavior: Clip.antiAlias,
        child: _RankAvatar(
          imgPath: imgPath,
          size: inner,
          defaultAsset: defaultAsset,
          placeholderColor: style == _RankProfileFrameStyle.podiumFree
              ? const Color(0xFF938F99)
              : null,
        ),
      ),
    );
  }
}

class _PodiumLevelBadge extends StatelessWidget {
  const _PodiumLevelBadge({
    required this.level,
    required this.size,
    required this.fontSize,
  });

  final int level;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF0CABA8),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$level',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _RankListRow extends StatelessWidget {
  const _RankListRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.defaultProfile,
    required this.premiumBadge,
    this.contentHorizontal = 24,
  });

  final int rank;
  final RankEntryDto? entry;
  final String defaultProfile;
  final String premiumBadge;

  /// 행 콘텐츠 좌우 inset. isMe 하이라이트는 리스트 전체 폭(각진 모서리).
  final double contentHorizontal;

  static const _listAvatarOuter = 40.0;
  static const _listBorderW = 2.0;

  @override
  Widget build(BuildContext context) {
    final isEmpty = entry == null;
    final name = (entry?.name ?? '').trim();
    final displayName = (isEmpty || name.isEmpty) ? '—' : name;
    final isMe = entry?.isMe == true;
    final isPremium = !isEmpty && entry!.subscribedYn == 'Y';
    final likeText = isEmpty ? '—' : '${entry!.weeklyLike}';
    const nameStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: [FontVariation('wght', 700)],
      fontSize: 14,
      height: 1.1,
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RankProfileFrame(
                imgPath: entry?.imgPath,
                outer: _listAvatarOuter,
                borderWidth: _listBorderW,
                style: isPremium
                    ? _RankProfileFrameStyle.premium
                    : _RankProfileFrameStyle.free,
                defaultAsset: defaultProfile,
              ),
              if (!isEmpty)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: _LevelBadge(level: entry!.level, compact: true),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const badgeGap = 4.0;
                const badgeSize = 14.0;
                final badgeReserve = isPremium ? badgeGap + badgeSize : 0.0;
                final nameMax = (constraints.maxWidth - badgeReserve).clamp(
                  0.0,
                  double.infinity,
                );
                final textDir = Directionality.of(context);
                final textPainter = TextPainter(
                  text: TextSpan(text: displayName, style: nameStyle),
                  maxLines: 1,
                  textDirection: textDir,
                )..layout();
                final textW = textPainter.width;
                final needsMarquee = textW > nameMax;
                final nameW = needsMarquee ? nameMax : textW;

                return Row(
                  children: [
                    SizedBox(
                      width: nameW,
                      height: 16,
                      child: needsMarquee
                          ? Marquee(
                              text: displayName,
                              style: nameStyle,
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              blankSpace: 24,
                              velocity: 30,
                              pauseAfterRound: const Duration(seconds: 2),
                              startPadding: 0,
                              accelerationDuration: const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration: const Duration(
                                milliseconds: 500,
                              ),
                              decelerationCurve: Curves.easeOut,
                            )
                          : Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                displayName,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: nameStyle,
                              ),
                            ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: badgeGap),
                      Transform.translate(
                        offset: const Offset(0, 1),
                        child: Image.asset(
                          premiumBadge,
                          width: badgeSize,
                          height: badgeSize,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/like_at_result.png',
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 4),
              Text(
                likeText,
                style: const TextStyle(
                  fontFamily: 'ChironHeiHK',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontVariations: [FontVariation('wght', 700)],
                  fontSize: 14,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // softLight는 스크롤 시 레이어 분리로 순백 플래시 → #542493 고정.
    // isMe: 리스트(=화면) 전체 폭 · 각진 모서리(radius 없음).
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: isMe ? const Color(0xFF542493) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: contentHorizontal),
        child: row,
      ),
    );
  }
}

class _RankAvatar extends StatelessWidget {
  const _RankAvatar({
    required this.imgPath,
    required this.size,
    required this.defaultAsset,
    this.placeholderColor,
  });

  final String? imgPath;
  final double size;
  final String defaultAsset;
  final Color? placeholderColor;

  Widget _placeholder() {
    final img = Image.asset(
      defaultAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    if (placeholderColor == null) return img;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(placeholderColor!, BlendMode.srcIn),
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imgPath?.trim();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                // 랭킹 imgPath는 풀 URL. CDN prefix 붙이지 않음.
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, this.compact = false});

  final int level;
  final bool compact;

  /// 1~3위 `_PodiumLevelBadge`와 동일 (#0CABA8 배경 · 흰 글자 · border 없음).
  @override
  Widget build(BuildContext context) {
    final size = compact ? 16.0 : 18.0;
    final fontSize = compact ? 9.0 : 10.0;
    return _PodiumLevelBadge(level: level, size: size, fontSize: fontSize);
  }
}

/// GNB 위 고정 내 순위. inline 행이 보이면 숨긴다.
class _RankMyEntrySticky extends StatelessWidget {
  const _RankMyEntrySticky({
    required this.entry,
    required this.defaultProfile,
    required this.premiumBadge,
  });

  final RankEntryDto entry;
  final String defaultProfile;
  final String premiumBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _RankListRow(
        rank: entry.rank,
        entry: entry,
        defaultProfile: defaultProfile,
        premiumBadge: premiumBadge,
      ),
    );
  }
}

/// 주간 랭킹 미참여(myEntry == null) 하단 고정 오버레이.
/// 화면 전체 폭 · 각진 모서리. blur 9.2 · #8A38F5 64%.
class _RankNotRankedOverlay extends StatelessWidget {
  const _RankNotRankedOverlay({this.onPlayNow});

  final VoidCallback? onPlayNow;

  static const _bg = Color(0xA38A38F5); // #8A38F5 @ 64%
  static const _blurSigma = 9.2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elevatedBase = Theme.of(context).elevatedButtonTheme.style;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.zero,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            decoration: const BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.rankNotRankedYetTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ChironGoRoundTC',
                    fontFamilyFallback: ['ChironHeiHK'],
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontVariations: [FontVariation('wght', 700)],
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.rankNotRankedYetBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'ChironGoRoundTC',
                    fontFamilyFallback: ['ChironHeiHK'],
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    fontVariations: [FontVariation('wght', 400)],
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 44,
                  // TODO: rankPlayNow ko/pt 공식 카피 확정 시 ARB 갱신 (현재 en "play now" 유지).
                  child: ElevatedButton(
                    onPressed: onPlayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ).merge(elevatedBase),
                    child: Text(l10n.rankPlayNow),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
