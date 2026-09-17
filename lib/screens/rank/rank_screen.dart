import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/gnb_bar.dart';
import 'rank_claimable_sheet.dart';
import 'rank_podium_painter.dart';
import 'top_3_rewards_popup.dart';

/// Weekly Ranking Main Screen (GNB Ranking 탭).
/// GET /v1/rank/period/current + GET /v1/rank/entries?pageNum=0 — 1~10만. Claim 시트 없음.
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
  static const _premiumBadge =
      'assets/images/icons/premium_verified_badge.png';
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

  RankScreenDto? _screen;
  /// myEntry: 11위 이하면 리스트에 끼워 넣지 않음. 미참여 오버레이 / 후속 sticky용.
  RankEntryDto? _myEntryKept;
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
    unawaited(_loadScreen());
  }

  @override
  void didUpdateWidget(covariant RankScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      unawaited(_loadScreen());
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
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
      // myEntry: 11위 이하면 리스트에 끼워 넣지 않음. 후속용으로만 보관.
      _myEntryKept = dto.myEntry;
      _applyCountdown(dto.period);
      setState(() {
        _screen = dto;
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    // Claimable 레이어 자리만 분리 — 현재 child는 본문만, 시트는 띄우지 않음.
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
              colors: [
                Color(0xFF843DF2),
                Color(0xFF0D011F),
              ],
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
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + GnbBar.contentHeight;
    final periodNull = _screen != null && _screen!.period == null;

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
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
                  // 타이틀·1~3 포디움·Rank/Player/Like 헤더는 고정.
                  // 4~10위 리스트만 스크롤.
                  // 미참여(myEntry == null)일 때만 하단 고정 오버레이 (sticky와 배타).
                  final showNotRanked = _myEntryKept == null;
                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPodium(context, constraints),
                          const SizedBox(height: 12),
                          _buildListHeader(context, constraints),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                for (var r = 4; r <= 10; r++)
                                  _RankListRow(
                                    rank: r,
                                    entry: _entryAt(r),
                                    defaultProfile: _defaultProfile,
                                    premiumBadge: _premiumBadge,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (showNotRanked)
                        Positioned(
                          left: 0,
                          right: 0,
                          // GNB와 살짝 간격 (본문 bottomInset이 이미 GNB 높이를 뺌).
                          bottom: 12,
                          child: _RankNotRankedOverlay(
                            onPlayNow: widget.onNavigateToHome,
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
  /// 프로필·뱃지 약간 키움 (레이아웃 동일).
  static const _avatarOuter = 114.0;
  static const _borderW = 3.8;
  // 왕관 Figma(160,71) − 1위 아바타 박스(167.31,128) + 우측 보정(아바타 키운 뒤 시각 정렬).
  static const _crownW = 154.77;
  static const _crownH = 118.33;
  static const _crownLeftOnAvatar = 160.0 - 167.31 + 8.0; // -7.31 → +0.69
  static const _crownTopOnAvatar = 71.0 - 128.0; // -57
  static const _likesToLineGap = 8.0;

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
                            : _RankProfileFrameStyle.free),
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
                  Image.asset(
                    premiumBadge,
                    width: attrSize,
                    height: attrSize,
                  ),
                ],
              ],
            ),
          ),
          if (entry != null) ...[
            SizedBox(height: 2 * s),
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

enum _RankProfileFrameStyle { winner, premium, free }

/// 1위: 흰→금. 그 외: Profile과 동일 (premium mint→보라 / free mint→어두운 mint).
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
    };
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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: _RankAvatar(
          imgPath: imgPath,
          size: inner,
          defaultAsset: defaultAsset,
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
    required this.rank,
    required this.entry,
    required this.defaultProfile,
    required this.premiumBadge,
  });

  final int rank;
  final RankEntryDto? entry;
  final String defaultProfile;
  final String premiumBadge;

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
                final badgeReserve =
                    isPremium ? badgeGap + badgeSize : 0.0;
                final nameMax = (constraints.maxWidth - badgeReserve)
                    .clamp(0.0, double.infinity);
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
                              accelerationDuration:
                                  const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration:
                                  const Duration(milliseconds: 500),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: isMe ? const Color(0xFF542493) : null,
      child: row,
    );
  }
}

class _RankAvatar extends StatelessWidget {
  const _RankAvatar({
    required this.imgPath,
    required this.size,
    required this.defaultAsset,
  });

  final String? imgPath;
  final double size;
  final String defaultAsset;

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
                errorWidget: (_, _, _) => Image.asset(
                  defaultAsset,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                defaultAsset,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
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
    return _PodiumLevelBadge(
      level: level,
      size: size,
      fontSize: fontSize,
    );
  }
}

/// 주간 랭킹 미참여(myEntry == null) 하단 고정 오버레이.
/// GNB [BackdropFilter] 패턴 재사용. blur 9.2 · #8A38F5 64%.
class _RankNotRankedOverlay extends StatelessWidget {
  const _RankNotRankedOverlay({this.onPlayNow});

  final VoidCallback? onPlayNow;

  static const _bg = Color(0xA38A38F5); // #8A38F5 @ 64%
  static const _radius = BorderRadius.all(Radius.circular(24));
  static const _blurSigma = 9.2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elevatedBase = Theme.of(context).elevatedButtonTheme.style;

    return ClipRRect(
      borderRadius: _radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: _radius,
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
    );
  }
}
