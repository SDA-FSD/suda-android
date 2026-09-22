import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:marquee/marquee.dart';

import '../../l10n/app_localizations.dart';
import '../../models/rank_models.dart';
import '../../models/user_models.dart';
import '../../models/character_reward_models.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gnb_bar.dart';
import '../../utils/full_screen_route.dart';
import '../reward/reward_unboxing.dart';
import 'ranking_reward_claim.dart';
import 'rank_crown_avatar.dart';
import 'rank_podium_painter.dart';
import 'top_3_rewards_popup.dart';

enum _MeRowSlot { below, visible, above }

/// Ranking (GNB Ranking 탭).
/// GET /v1/rank/period/current + /entries + /entries/me.
/// sticky/미참여는 `/entries/me`(동일 snapshotMinute). 목록 inline은 userId/isMe.
/// sticky는 자기 행이 뷰포트보다 **아래**일 때만 (상위 랭커를 보는 중).
class Ranking extends StatefulWidget {
  const Ranking({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToAlarm,
    this.onNavigateToProfile,
    this.isActive = false,
    this.user,
    this.showNotiboxUnreadBadge = false,

    /// Lab 미리보기: 서버 phase와 무관하게 ANNOUNCE UI 강제.
    this.forceAnnouncePhase = false,

    /// Lab: Ranking Reward Claim 패널을 GNB 위 전면 오버레이로 표시.
    this.forceRankingRewardClaimPreview = false,

    /// Lab: Ranking Reward Claim 등수 (1|2|3). [forceRankingRewardClaimPreview]일 때만 사용.
    this.forceRankingRewardClaimPlace = 1,
  });

  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToAlarm;
  final VoidCallback? onNavigateToProfile;
  final bool isActive;
  final UserDto? user;
  final bool showNotiboxUnreadBadge;
  final bool forceAnnouncePhase;
  final bool forceRankingRewardClaimPreview;
  final int forceRankingRewardClaimPlace;

  static const String routeName = '/rank';

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> with TickerProviderStateMixin {
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

  static const _stickyFadeDuration = Duration(milliseconds: 150);

  RankScreenDto? _screen;

  /// `/entries/me` 결과. null = 미참여(스냅샷 기준). live ripple 없음.
  RankEntryDto? _myEntryKept;

  /// `/entries/me` 호출 완료 여부. false면 sticky/미참여 판정 보류.
  bool _myEntryResolved = false;
  List<RankEntryDto> _listRows = const [];
  String? _snapshotMinute;
  int? _nextPageNum;
  bool _hasMorePages = false;
  bool _loadingMore = false;

  /// 자기 행 vs 리스트 뷰포트. 미로드(키 없음)는 below.
  _MeRowSlot _meRowSlot = _MeRowSlot.below;

  /// 로드·탭 복귀 직후는 sticky 즉시. 이후 스크롤 토글만 페이드.
  bool _stickyFadeEnabled = false;
  late final AnimationController _stickyFadeController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _meRowKey = GlobalKey();
  bool _loading = true;
  bool _loadFailed = false;

  /// phaseEndsAt - serverNow 기준 남은 시간. 기기 시계만으로 절대시각 계산하지 않음.
  Duration _remainingAtFetch = Duration.zero;
  DateTime? _fetchedAtLocal;
  Timer? _tickTimer;
  Duration _remaining = Duration.zero;

  /// Lab `forceRankingRewardClaimPreview` 또는 claimable API 후 GNB 위 전면 패널.
  bool _rankingRewardClaimVisible = false;
  RankEntryDto? _rankingRewardClaimEntry;
  int _rankingRewardClaimPlace = 1;

  /// GET claimable 응답. Claim POST body.
  List<int> _rankingRewardClaimableIds = const [];
  int _rankingRewardClaimLoadGen = 0;
  bool _rankingRewardClaimSubmitting = false;

  /// DefaultPopup(showDialog)과 동일 계열: 페이드 + 살짝 스케일(중앙).
  late final AnimationController _rankingRewardClaimAppearController;
  late final Animation<double> _rankingRewardClaimFade;
  late final Animation<double> _rankingRewardClaimScale;

  @override
  void initState() {
    super.initState();
    _stickyFadeController = AnimationController(
      vsync: this,
      duration: _stickyFadeDuration,
    );
    _rankingRewardClaimAppearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    final curved = CurvedAnimation(
      parent: _rankingRewardClaimAppearController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _rankingRewardClaimFade = curved;
    _rankingRewardClaimScale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(curved);
    _scrollController.addListener(_onScroll);
    if (widget.forceRankingRewardClaimPreview) {
      _rankingRewardClaimVisible = true;
      _rankingRewardClaimPlace = widget.forceRankingRewardClaimPlace.clamp(
        1,
        3,
      );
      _rankingRewardClaimEntry = RankingRewardClaimPanel.labMock(
        rank: _rankingRewardClaimPlace,
        imgPath: widget.user?.profileImgUrl,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_rankingRewardClaimAppearController.forward());
      });
    }
    unawaited(_loadScreen());
  }

  @override
  void didUpdateWidget(covariant Ranking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _jumpToListTop();
      unawaited(_loadScreen());
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _stickyFadeController.dispose();
    _rankingRewardClaimAppearController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScreen() async {
    // 재진입: 기존 sticky/리스트를 숨기지 않고 백그라운드 갱신 (진입 시 1초 공백 방지)
    final keepUi = _screen != null;
    if (!keepUi) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    } else {
      _loadFailed = false;
    }
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
      // sticky 기준은 /entries/me. 목록 page isMe 스캔으로 덮지 않음.
      _myEntryKept = dto.myEntry;
      _myEntryResolved = true;
      _listRows = dto.listEntries;
      _snapshotMinute = dto.snapshotMinute;
      _nextPageNum = dto.nextPageNum;
      _hasMorePages = dto.hasMore;
      _meRowSlot = _MeRowSlot.below;
      _stickyFadeEnabled = false;
      debugPrint(
        'ranking loaded rows=${_listRows.length} hasMore=$_hasMorePages '
        'next=$_nextPageNum total=${dto.total} liveRankSize=${dto.period?.liveRankSize} '
        'snap=$_snapshotMinute my=${_myEntryKept?.rank}',
      );
      _applyCountdown(dto.period);
      setState(() {
        _screen = dto;
        _loading = false;
      });
      _syncStickyFade(instant: true);
      unawaited(_maybeShowRankingRewardClaim(dto));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 탭 복귀·리로드 시 항상 4위부터
        _jumpToListTop();
        _updateMeRowSlot();
        _stickyFadeEnabled = true;
        // 화면 미충전 시만 다음 page (내 순위 탐색용 loadMore 금지 — /me가 담당)
        _requestLoadMoreIfNeeded();
      });
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
    if (period == null || period.serverNow == null) {
      _remainingAtFetch = Duration.zero;
      _fetchedAtLocal = null;
      _remaining = Duration.zero;
      return;
    }
    // COLLECT: 현재 phase 종료(발표 시작). ANNOUNCE/Lab미리보기: 다음 주간 랭킹(COLLECT) 시작.
    final announceUi = period.phase == 'ANNOUNCE' || widget.forceAnnouncePhase;
    final ends = announceUi
        ? (period.nextCollectStartsAt ?? period.phaseEndsAt)
        : period.phaseEndsAt;
    if (ends == null) {
      _remainingAtFetch = Duration.zero;
      _fetchedAtLocal = null;
      _remaining = Duration.zero;
      return;
    }
    final serverNow = period.serverNow!;
    var rem = ends.difference(serverNow);
    if (rem.isNegative) rem = Duration.zero;
    _remainingAtFetch = rem;
    _fetchedAtLocal = DateTime.now();
    _remaining = rem;
    // ANNOUNCE HH:MM:SS는 1초, COLLECT 헤더(일/시/분)는 30초.
    final tick = announceUi
        ? const Duration(seconds: 1)
        : const Duration(seconds: 30);
    _tickTimer = Timer.periodic(tick, (_) {
      if (!mounted || _fetchedAtLocal == null) return;
      final elapsed = DateTime.now().difference(_fetchedAtLocal!);
      var next = _remainingAtFetch - elapsed;
      if (next.isNegative) next = Duration.zero;
      setState(() => _remaining = next);
    });
  }

  /// ANNOUNCE 카운트다운 `HH:MM:SS`. 0 미만이면 `00:00:00`.
  static String formatRemainingHms(Duration d) {
    var total = d.inSeconds;
    if (total < 0) total = 0;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  String _titleText(AppLocalizations l10n) {
    if (_isAnnouncePhase) return l10n.rankAnnounceTitle;
    return l10n.rankWeeklyTitle;
  }

  bool get _isAnnouncePhase =>
      widget.forceAnnouncePhase || _screen?.period?.phase == 'ANNOUNCE';

  /// ANNOUNCE 전용 배경 장식 (그라디언트 위 · 콘텐츠 아래).
  /// Figma 440 로컬 좌표 × s(contentWidth/440).
  static const _announceSunburst = 'assets/images/sunburst_pattern.png';
  static const _announceConfetti = 'assets/images/confetti.png';
  static const _announceDecorFrameW = 440.0;

  Widget _buildAnnounceDecorLayers(double contentWidth) {
    final s = contentWidth / _announceDecorFrameW;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: -255 * s,
          top: -3 * s,
          width: 949 * s,
          height: 949 * s,
          child: _SoftLightLayer(
            child: Image.asset(
              _announceSunburst,
              width: 949 * s,
              height: 949 * s,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Positioned(
          left: -15 * s,
          top: 12 * s,
          width: 453 * s,
          height: 185 * s,
          child: Image.asset(
            _announceConfetti,
            width: 453 * s,
            height: 185 * s,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildRankBackground() {
    const gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF843DF2), Color(0xFF0D011F)],
        ),
      ),
    );
    if (!_isAnnouncePhase) return gradient;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [gradient, if (w > 0) _buildAnnounceDecorLayers(w)],
        );
      },
    );
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

  List<RankEntryDto> _buildDisplayRows() {
    final meId = widget.user?.id;
    final me = _myEntryKept;
    final base = [..._listRows]..sort((a, b) => a.rank.compareTo(b.rank));
    return base.map((e) {
      final isMe =
          e.isMe ||
          (meId != null && e.userId == meId) ||
          (me != null && e.userId == me.userId);
      return e.copyWith(isMe: isMe);
    }).toList();
  }

  void _jumpToListTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    _updateMeRowSlot();
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
    if (pos.maxScrollExtent <= 240 || pos.pixels >= pos.maxScrollExtent - 480) {
      unawaited(_loadMore());
    }
  }

  void _updateMeRowSlot() {
    final next = _computeMeRowSlot();
    if (next == _meRowSlot) return;
    _meRowSlot = next;
    _syncStickyFade();
  }

  _MeRowSlot _computeMeRowSlot() {
    final me = _myEntryKept;
    if (me == null || me.rank <= 10) return _MeRowSlot.below;
    if (!_scrollController.hasClients) return _meRowSlot;
    final ctx = _meRowKey.currentContext;
    // 화면 밖이면 builder가 행을 버림. null을 below로 보면 지나간 뒤 append 때 sticky가 다시 켜짐.
    if (ctx == null) return _meRowSlot;
    final render = ctx.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return _meRowSlot;
    final viewport = RenderAbstractViewport.maybeOf(render);
    if (viewport == null) return _meRowSlot;
    final position = _scrollController.position;
    final itemTop = viewport.getOffsetToReveal(render, 0.0).offset;
    final itemBottom = itemTop + render.size.height;
    final pixels = position.pixels;
    // GNB에 가린 구간은 육안 가시 영역에서 제외. sticky 슬롯은 포함(핸드오프).
    final viewportBottom =
        pixels + position.viewportDimension - GnbBar.contentHeight;
    if (itemBottom <= pixels) return _MeRowSlot.above;
    if (itemTop >= viewportBottom) return _MeRowSlot.below;
    return _MeRowSlot.visible;
  }

  void _syncStickyFade({bool instant = false}) {
    final me = _myEntryKept;
    final eligible = !_isAnnouncePhase && me != null && me.rank > 10;
    final wanted = eligible && _meRowSlot == _MeRowSlot.below;
    if (!eligible) {
      _stickyFadeController.value = 0;
      return;
    }
    if (instant || !_stickyFadeEnabled) {
      _stickyFadeController.value = wanted ? 1.0 : 0.0;
      return;
    }
    if (wanted) {
      unawaited(_stickyFadeController.forward());
    } else {
      unawaited(_stickyFadeController.reverse());
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
        inferredHasMore =
            page.hasMore || (page.total > 0 && maxRank < page.total);
        inferredNext =
            page.nextPageNum ?? (inferredHasMore ? requestingPage + 1 : null);
      }
      setState(() {
        _listRows = merged;
        _nextPageNum = inferredNext;
        _hasMorePages = inferredHasMore && inferredNext != null;
        _loadingMore = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateMeRowSlot();
        _requestLoadMoreIfNeeded();
      });
    } catch (e, st) {
      debugPrint('rank loadMore FAILED page=$requestingPage: $e\n$st');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ranking Reward Claim 레이어는 본문 위 풀스크린(GNB 유지).
    final periodNull = _screen != null && _screen!.period == null;
    final showContent =
        !_loading && !periodNull && !(_loadFailed && _screen == null);
    final hasMeOnScreen = (_screen?.topEntries ?? const <RankEntryDto>[]).any(
      (e) => e.isMe,
    );
    // /entries/me null = 미참여. 해석 전이면 오버레이 금지.
    // sticky·미참여 오버레이는 COLLECT(주간 랭킹)만. ANNOUNCE(순위 발표)에는 절대 노출하지 않음.
    final isCollectRank = showContent && !_isAnnouncePhase;
    final showNotRanked =
        isCollectRank &&
        _screen != null &&
        _myEntryResolved &&
        _myEntryKept == null &&
        !hasMeOnScreen;
    final stickyEligible =
        isCollectRank && _myEntryKept != null && _myEntryKept!.rank > 10;

    final showRankingRewardClaimLayer =
        _rankingRewardClaimEntry != null &&
        (_rankingRewardClaimVisible ||
            _rankingRewardClaimAppearController.isAnimating);

    final gnb = GnbBar(
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
    );

    // 랭킹 본문 + GNB는 Scaffold. Ranking Reward Claim은 풀스크린 레이어
    // (등장: DefaultPopup과 동일 계열 — dim + 페이드 + 중앙 스케일).
    // 배경은 GNB 뒤까지, GNB는 레이어 위에 다시 올려 글래시.
    final scaffold = AppScaffold(
      showBackButton:
          widget.forceAnnouncePhase || widget.forceRankingRewardClaimPreview,
      usePadding: false,
      bodyTopPadding: 16,
      backgroundColor: const Color(0xFF0D011F),
      background: _buildRankBackground(),
      bottomNavigationBar: showRankingRewardClaimLayer ? null : gnb,
      aboveBottomBar: showRankingRewardClaimLayer
          ? null
          : showNotRanked
          ? _RankNotRankedOverlay(onPlayNow: widget.onNavigateToHome)
          : stickyEligible
          ? AnimatedBuilder(
              animation: _stickyFadeController,
              builder: (context, child) {
                final v = _stickyFadeController.value;
                if (v <= 0 && !_stickyFadeController.isAnimating) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  ignoring: v < 0.05,
                  child: Opacity(opacity: v, child: child),
                );
              },
              child: _RankMyEntrySticky(
                entry: _myEntryKept!,
                defaultProfile: _defaultProfile,
                premiumBadge: _premiumBadge,
              ),
            )
          : null,
      body: _buildBody(context),
    );

    if (!showRankingRewardClaimLayer) {
      return scaffold;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        scaffold,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _rankingRewardClaimAppearController,
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // DefaultPopup dim: black 40%
                  Opacity(
                    opacity: _rankingRewardClaimAppearController.value.clamp(
                      0.0,
                      1.0,
                    ),
                    child: const ColoredBox(color: Color(0x66000000)),
                  ),
                  FadeTransition(
                    opacity: _rankingRewardClaimFade,
                    child: ScaleTransition(
                      scale: _rankingRewardClaimScale,
                      alignment: Alignment.center,
                      child: RankingRewardClaimPanel(
                        entry: _rankingRewardClaimEntry!,
                        place: _rankingRewardClaimPlace,
                        submitting: _rankingRewardClaimSubmitting,
                        onClaim: _rankingRewardClaimSubmitting
                            ? null
                            : () => unawaited(_onRankingRewardClaim()),
                        paintBackground: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: gnb),
      ],
    );
  }

  Future<void> _maybeShowRankingRewardClaim(RankScreenDto dto) async {
    if (widget.forceRankingRewardClaimPreview) return;
    if (dto.period?.phase != 'ANNOUNCE') return;
    final periodId = dto.period?.periodId;
    if (periodId == null) return;
    final me = dto.myEntry;
    if (me == null) return;
    final place = me.rank;
    if (place < 1 || place > 3) return;

    final gen = ++_rankingRewardClaimLoadGen;
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || token.isEmpty) return;
      final ids = await SudaApiClient.getRankingRewardClaimableIds(
        accessToken: token,
        periodId: periodId,
      );
      if (!mounted || gen != _rankingRewardClaimLoadGen) return;
      if (ids.isEmpty) return;
      _rankingRewardClaimableIds = ids;
      debugPrint(
        'ranking reward claimable periodId=$periodId place=$place '
        'ids=$_rankingRewardClaimableIds',
      );
      setState(() {
        _rankingRewardClaimVisible = true;
        _rankingRewardClaimPlace = place;
        _rankingRewardClaimEntry = me;
      });
      unawaited(_rankingRewardClaimAppearController.forward());
    } catch (err) {
      debugPrint('ranking reward claimable failed: $err');
    }
  }

  Future<void> _onRankingRewardClaim() async {
    if (_rankingRewardClaimSubmitting) return;
    _rankingRewardClaimSubmitting = true;
    setState(() {});
    List<CharacterRewardClaimDto> items;
    try {
      if (widget.forceRankingRewardClaimPreview &&
          _rankingRewardClaimableIds.isEmpty) {
        items = [CharacterRewardClaimDto.labMock()];
      } else {
        final token = await TokenStorage.loadAccessToken();
        if (token == null || token.isEmpty) {
          throw Exception('no token');
        }
        items = await SudaApiClient.claimRankingCharacterRewards(
          accessToken: token,
          userCharacterRewardIds: _rankingRewardClaimableIds,
        );
      }
    } catch (err) {
      debugPrint('ranking reward claim failed: $err');
      if (mounted) {
        setState(() => _rankingRewardClaimSubmitting = false);
        showRankingRewardClaimErrorToast(context);
      }
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      await _dismissRankingRewardClaim();
      if (widget.forceRankingRewardClaimPreview && mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }
    await RewardUnboxing.preload(context, items);
    if (!mounted) return;
    _pushRewardUnboxingThenHideClaim(items);
  }

  /// Unboxing fade-in으로 Claim을 덮은 뒤에 Claim 레이어를 제거. 랭킹 본문 플래시 방지.
  void _pushRewardUnboxingThenHideClaim(List<CharacterRewardClaimDto> items) {
    final route = FullScreenRoute<void>(
      page: RewardUnboxing(
        items: items,
        onNavigateToProfile: widget.onNavigateToProfile,
      ),
      transition: FullScreenTransition.fade,
    );
    unawaited(Navigator.of(context).push(route));

    void hideClaim() {
      if (!mounted) return;
      _rankingRewardClaimAppearController.value = 0;
      setState(() {
        _rankingRewardClaimVisible = false;
        _rankingRewardClaimSubmitting = false;
        _rankingRewardClaimableIds = const [];
      });
    }

    void listen(Animation<double> anim) {
      if (anim.status == AnimationStatus.completed) {
        hideClaim();
        return;
      }
      late final void Function(AnimationStatus) listener;
      listener = (status) {
        if (status != AnimationStatus.completed) return;
        anim.removeStatusListener(listener);
        hideClaim();
      };
      anim.addStatusListener(listener);
    }

    final existing = route.animation;
    if (existing != null) {
      listen(existing);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anim = route.animation;
      if (anim == null) {
        hideClaim();
        return;
      }
      listen(anim);
    });
  }

  Future<void> _dismissRankingRewardClaim() async {
    if (!_rankingRewardClaimAppearController.isDismissed) {
      await _rankingRewardClaimAppearController.reverse();
    }
    if (!mounted) return;
    setState(() {
      _rankingRewardClaimVisible = false;
      _rankingRewardClaimSubmitting = false;
    });
  }

  Widget _buildBody(BuildContext context) {
    final periodNull = _screen != null && _screen!.period == null;
    const side = 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isAnnouncePhase) const SizedBox(height: 64),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: side),
          child: _isAnnouncePhase
              ? _buildAnnounceHeader(context)
              : _buildHeader(context),
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
        else if (_isAnnouncePhase)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ANNOUNCE: 타이틀 + 1~3 포디움 + (아래) You Rank/Like 배지.
                // 포디움 레이아웃/스케일은 그대로 — 배지만 포디움 아래 공백 후 추가.
                final contentConstraints = BoxConstraints(
                  maxWidth: (constraints.maxWidth - side * 2).clamp(
                    0.0,
                    double.infinity,
                  ),
                  maxHeight: constraints.maxHeight,
                );
                final s = contentConstraints.maxWidth / _figmaFrameW;
                // 포디움 SizedBox 하단(figma 71+369+22=462) → 배지 top 493 → 간격 31.
                final badgeGap =
                    (493.0 -
                        (_figmaPodiumOriginY + _figmaPodiumH + _podiumDown)) *
                    s;
                final me = _myEntryKept;
                // 배지 하단(493+71=564) → Next Ranking 타이틀 y=639 → 간격 75.
                final nextGap = 75 * s;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: side),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPodium(context, contentConstraints),
                        if (me != null) ...[
                          SizedBox(
                            height: badgeGap.clamp(0.0, double.infinity),
                          ),
                          _AnnounceYouBadge(
                            scale: s * _AnnounceYouBadge.groupScale,
                            rank: me.rank,
                            weeklyLike: me.weeklyLike,
                          ),
                        ],
                        SizedBox(height: nextGap),
                        _AnnounceNextRankingBlock(
                          scale: s,
                          countdownText: formatRemainingHms(_remaining),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                            padding: const EdgeInsets.only(
                              bottom: GnbBar.contentHeight,
                            ),
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
    );
  }

  /// ANNOUNCE 결과 헤더: 타이틀만 (도움말·카운트다운 없음).
  Widget _buildAnnounceHeader(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    // Outer Shadow: X0 Y4 Blur4 Spread0 #000000 25%.
    const announceTitleShadow = Shadow(
      offset: Offset(0, 4),
      blurRadius: 4,
      color: Color(0x40000000),
    );
    final titleStyle = theme.headlineMedium?.copyWith(
      color: Colors.white,
      height: 1.0,
      shadows: const [announceTitleShadow],
    );
    return Text(
      l10n.rankAnnounceTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: titleStyle,
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

  static const _boxH = RankCrownAvatar.boxH;
  static const _avatarOuter = RankCrownAvatar.avatarOuter;
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
                  child: RankCrownAvatar(
                    scale: s,
                    imgPath: entry?.imgPath,
                    frameStyle: winnerFrame
                        ? RankProfileFrameStyle.winner
                        : (isPremium
                              ? RankProfileFrameStyle.premium
                              : RankProfileFrameStyle.podiumFree),
                    defaultAsset: defaultProfile,
                    crownAsset: crownAsset,
                    showCrown: showCrown,
                    level: entry?.level,
                    showLevelBadge: entry != null,
                    outerShadowScale: s,
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

class _RankListRow extends StatelessWidget {
  const _RankListRow({
    super.key,
    required this.rank,
    required this.entry,
    required this.defaultProfile,
    required this.premiumBadge,
    this.contentHorizontal = 24,
    this.flushTop = false,
  });

  final int rank;
  final RankEntryDto? entry;
  final String defaultProfile;
  final String premiumBadge;

  /// 행 콘텐츠 좌우 inset. isMe 하이라이트는 리스트 전체 폭(각진 모서리).
  final double contentHorizontal;

  /// sticky: 상단 margin 제거(하이라이트가 위로 붙음). 하단만 2 유지.
  final bool flushTop;

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
              RankProfileFrame(
                imgPath: entry?.imgPath,
                outer: _listAvatarOuter,
                borderWidth: _listBorderW,
                style: isPremium
                    ? RankProfileFrameStyle.premium
                    : RankProfileFrameStyle.free,
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
    // sticky(flushTop): 상단 공백 없이 하단만 2.
    return Container(
      width: double.infinity,
      margin: flushTop
          ? const EdgeInsets.only(bottom: 2)
          : const EdgeInsets.symmetric(vertical: 2),
      color: isMe ? const Color(0xFF542493) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: contentHorizontal),
        child: row,
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
    return RankPodiumLevelBadge(level: level, size: size, fontSize: fontSize);
  }
}

/// GNB 위 고정 내 순위. 자기 행이 뷰포트보다 아래일 때만 표시.
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
        flushTop: true,
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

/// ANNOUNCE "Next Ranking Starts in:" + 카운트다운 (배지 아래).
/// 440: 타이틀 softLight Bold32 @ y639 / 카운트다운 순백 Bold20 @ y729 · 폭 268 중앙.
/// 남은 시간: `_applyCountdown`의 nextCollectStartsAt(없으면 phaseEndsAt).
class _AnnounceNextRankingBlock extends StatelessWidget {
  const _AnnounceNextRankingBlock({
    required this.scale,
    required this.countdownText,
  });

  final double scale;
  final String countdownText;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final l10n = AppLocalizations.of(context)!;
    final width = 268 * s;
    // 타이틀 y639 → 카운트다운 y729 = 간격 90 (스케일 전).
    final gap = (729 - 639) * s;

    final titleStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      fontSize: 32 * s,
      height: 1.15,
    );
    final countdownStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      fontSize: 20 * s,
      height: 1.0,
    );

    return SizedBox(
      width: width,
      height: (729 - 639 + 24) * s,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SoftLightLayer(
              child: Text(
                l10n.rankAnnounceNextStartsIn,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
            ),
          ),
          Positioned(
            top: gap,
            left: 0,
            right: 0,
            child: Text(
              countdownText,
              textAlign: TextAlign.center,
              style: countdownStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// ANNOUNCE "You: Rank / Like" 배지 (포디움 아래).
/// 440 기준: 외곽 208×71 rx15 white softLight / pill 52×28 rx14 #D9D9D9 softLight.
/// 내부(y12~56)는 외곽 세로 중앙. [groupScale]로 카드 전체만 확대(내부 비율 유지).
class _AnnounceYouBadge extends StatelessWidget {
  const _AnnounceYouBadge({
    required this.scale,
    required this.rank,
    required this.weeklyLike,
  });

  /// 파워포인트 그룹 확대처럼 카드 전체에 곱하는 배율.
  static const groupScale = 1.35;

  final double scale;
  final int rank;
  final int weeklyLike;

  static const _likeAsset = 'assets/images/like_at_result.png';

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final l10n = AppLocalizations.of(context)!;
    final rankStr = '$rank';
    final likeStr = '$weeklyLike';

    const youStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: [FontVariation('wght', 700)],
      height: 1.0,
    );
    const labelStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      color: Colors.white,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      fontVariations: [FontVariation('wght', 400)],
      height: 1.0,
    );
    const valueStyle = TextStyle(
      fontFamily: 'ChironHeiHK',
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: [FontVariation('wght', 700)],
      height: 1.0,
    );

    final youFs = 14 * s;
    final labelFs = 12 * s;
    final valueFs = 14 * s;
    final iconSize = 14 * s;

    // pill 내부: Rank 값 좌우 여유(figma pill70 / value79 → 9). Like: icon+값.
    final rankValueW = _measure(
      rankStr,
      valueStyle.copyWith(fontSize: valueFs),
    );
    final likeValueW = _measure(
      likeStr,
      valueStyle.copyWith(fontSize: valueFs),
    );
    final rankPillW = (rankValueW + 18 * s).clamp(52 * s, double.infinity);
    final likePillW = (iconSize + 2 * s + likeValueW + 12 * s).clamp(
      52 * s,
      double.infinity,
    );

    // Like pill이 Rank pill과 겹치면 오른쪽으로 민다 (기본 x=139).
    final rankPillLeft = 70 * s;
    final likePillLeft = (139 * s).clamp(
      rankPillLeft + rankPillW + 8 * s,
      double.infinity,
    );
    final outerW = (208 * s).clamp(
      likePillLeft + likePillW + 17 * s,
      double.infinity,
    );
    // 외곽을 71로 키우고, figma y12~56(높이44) 콘텐츠 블록을 세로 중앙 정렬.
    const contentMinY = 12.0;
    const contentMaxY = 56.0; // pill top28 + h28
    const contentH = contentMaxY - contentMinY;
    final outerH = 71 * s;
    final contentTop = (outerH - contentH * s) / 2;

    double cy(double figmaY) => contentTop + (figmaY - contentMinY) * s;

    return SizedBox(
      width: outerW,
      height: outerH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _SoftLightLayer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15 * s),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20 * s,
            top: cy(33),
            child: Text(
              l10n.rankAnnounceYou,
              style: youStyle.copyWith(fontSize: youFs),
            ),
          ),
          Positioned(
            left: 81 * s,
            top: cy(12),
            child: Text(
              l10n.rankAnnounceRank,
              style: labelStyle.copyWith(fontSize: labelFs),
            ),
          ),
          Positioned(
            left: 157 * s,
            top: cy(12),
            child: Text(
              l10n.rankAnnounceLike,
              style: labelStyle.copyWith(fontSize: labelFs),
            ),
          ),
          Positioned(
            left: rankPillLeft,
            top: cy(28),
            width: rankPillW,
            height: 28 * s,
            child: _SoftLightPill(
              child: Center(
                child: Text(
                  rankStr,
                  style: valueStyle.copyWith(fontSize: valueFs),
                ),
              ),
            ),
          ),
          Positioned(
            left: likePillLeft,
            top: cy(28),
            width: likePillW,
            height: 28 * s,
            child: _SoftLightPill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _likeAsset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  SizedBox(width: 2 * s),
                  Text(likeStr, style: valueStyle.copyWith(fontSize: valueFs)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

/// Rank/Like 숫자 배경만 softLight. 숫자·아이콘은 일반 합성(순백).
class _SoftLightPill extends StatelessWidget {
  const _SoftLightPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: _SoftLightLayer(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9),
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// ANNOUNCE sunburst: 배경 그라디언트 위에 softLight 합성.
/// PNG 알파가 이미 ~14%이므로 레이어 opacity를 또 곱하지 않음.
class _SoftLightLayer extends SingleChildRenderObjectWidget {
  const _SoftLightLayer({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSoftLightLayer();
  }
}

class _RenderSoftLightLayer extends RenderProxyBox {
  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.canvas.saveLayer(
      offset & size,
      Paint()..blendMode = BlendMode.softLight,
    );
    context.paintChild(child!, offset);
    context.canvas.restore();
  }
}
