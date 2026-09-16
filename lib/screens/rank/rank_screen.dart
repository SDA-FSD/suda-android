import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
  static const _likeIcon = 'assets/images/like_at_result.png';

  /// Figma 440 프레임 기준 포디움(왕관 top→포디움 베이스 bottom).
  static const _figmaFrameW = 440.0;
  static const _figmaPodiumOriginY = 71.0;
  // Figma Podium 베이스: x34 y290 w384 h150 → bottom 440
  static const _figmaPodiumBaseX = 34.0;
  static const _figmaPodiumBaseY = 290.0;
  static const _figmaPodiumBaseW = 384.0;
  static const _figmaPodiumBaseH = 150.0;
  static const _figmaPodiumBottomY = _figmaPodiumBaseY + _figmaPodiumBaseH;
  static const _figmaPodiumH = _figmaPodiumBottomY - _figmaPodiumOriginY;
  /// 포디움 로컬 원점 (34,290) 기준 큰 숫자.
  /// 각 단(rect) 안에 Center 배치 — Figma absolute top(142~164)은 단 밖이라 클리핑됨.
  static const _podiumNumFontSize = 64.0;
  // 2등 단: x0~133, y65~133
  static const _num2CellLeft = 0.0;
  static const _num2CellTop = 65.0;
  static const _num2CellW = 133.0;
  static const _num2CellH = 68.0;
  // 1등 단: x132~259, y2~148
  static const _num1CellLeft = 132.0;
  static const _num1CellTop = 2.0;
  static const _num1CellW = 127.0;
  static const _num1CellH = 146.0;
  // 3등 단: x259~385, y82~150
  static const _num3CellLeft = 259.0;
  static const _num3CellTop = 82.0;
  static const _num3CellW = 126.0;
  static const _num3CellH = 68.0;
  /// 4~10 리스트가 한 화면에 들어가도록 포디움이 비워 줄 높이.
  /// row = margin 2+2 + padding 6+6 + avatar 40.
  static const _listRowH = 56.0;
  static const _listHeaderH = 24.0;
  static const _podiumListGap = 16.0;
  static const _listBlockH =
      _podiumListGap + _listHeaderH + _listRowH * 7;
  static const _minPodiumH = 200.0;

  RankScreenDto? _screen;
  // ignore: unused_field — 후속 claimable / my placement (CONTEXT §42). 리스트에 끼워 넣지 않음.
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

  String get _titleText {
    final phase = _screen?.period?.phase;
    if (phase == 'ANNOUNCE') return "This Week's Results";
    return 'Weekly Ranking';
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

  /// 서버 topEntries 순서·rank 그대로. 4~10만 표시 (빈 슬롯/내 행 끼워넣기 없음).
  List<RankEntryDto> get _listEntries {
    final list = _screen?.topEntries ?? const <RankEntryDto>[];
    return list.where((e) => e.rank >= 4 && e.rank <= 10).toList();
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
                  final podiumH = _podiumHeightFor(constraints);
                  final contentH = podiumH + _listBlockH;
                  return SingleChildScrollView(
                    physics: contentH > constraints.maxHeight + 1
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          _buildPodium(context, constraints),
                          const SizedBox(height: 12),
                          _buildListHeader(context),
                          const SizedBox(height: 4),
                          ..._listEntries.map(
                            (e) => _RankListRow(
                              entry: e,
                              defaultProfile: _defaultProfile,
                              premiumBadge: _premiumBadge,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                _titleText,
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
              Text(
                formatRemaining(_remaining, l10n),
                style: theme.bodySmall?.copyWith(color: countdownFg),
              ),
            ],
          ),
        ],
      ],
    );
  }

  double _podiumScale(BoxConstraints bodyConstraints) {
    final maxW = bodyConstraints.maxWidth;
    if (!maxW.isFinite || maxW <= 0) return 1;
    var s = maxW / _figmaFrameW;
    final bodyH = bodyConstraints.maxHeight;
    if (bodyH.isFinite) {
      final maxPodiumH =
          (bodyH - _listBlockH).clamp(_minPodiumH, _figmaPodiumH * s);
      if (_figmaPodiumH * s > maxPodiumH) {
        s = maxPodiumH / _figmaPodiumH;
      }
    }
    return s;
  }

  double _podiumHeightFor(BoxConstraints bodyConstraints) {
    final first = _entryAt(1);
    final second = _entryAt(2);
    final third = _entryAt(3);
    if (first == null && second == null && third == null) return 0;
    return _figmaPodiumH * _podiumScale(bodyConstraints);
  }

  Widget _buildPodium(BuildContext context, BoxConstraints bodyConstraints) {
    final first = _entryAt(1);
    final second = _entryAt(2);
    final third = _entryAt(3);
    if (first == null && second == null && third == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 가로 스케일 후, 4~10 리스트 높이를 남기도록 포디움(프로필·왕관·뱃지 비율 유지) 축소.
        final s = _podiumScale(bodyConstraints);

        double x(double figmaX) => figmaX * s;
        double y(double figmaY) => (figmaY - _figmaPodiumOriginY) * s;
        double podiumLocalX(double localX) => x(_figmaPodiumBaseX + localX);
        double podiumLocalY(double localY) => y(_figmaPodiumBaseY + localY);

        final podiumNumberStyle =
            Theme.of(context).textTheme.headlineLarge!.copyWith(
                  fontSize: _podiumNumFontSize * s,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: 0,
                );

        final podiumPaintW = (_figmaPodiumBaseW + 1.0) * s;
        final podiumPaintH = _figmaPodiumBaseH * s;

        return SizedBox(
          width: constraints.maxWidth,
          height: _figmaPodiumH * s,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _figmaFrameW * s,
              height: _figmaPodiumH * s,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // wireframe 9선 — RankPodiumBasePainter (Podium.png 금지)
                  Positioned(
                    left: x(_figmaPodiumBaseX),
                    top: y(_figmaPodiumBaseY),
                    width: podiumPaintW,
                    height: podiumPaintH,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.85,
                        child: CustomPaint(
                          size: Size(podiumPaintW, podiumPaintH),
                          painter: RankPodiumBasePainter(scale: s),
                        ),
                      ),
                    ),
                  ),
                  // 큰 숫자 — 각 단 rect 중앙 (z: wireframe 위 · 아바타 아래)
                  Positioned(
                    left: podiumLocalX(_num2CellLeft),
                    top: podiumLocalY(_num2CellTop),
                    width: _num2CellW * s,
                    height: _num2CellH * s,
                    child: Center(
                      child: PodiumRankNumber(
                        digit: '2',
                        style: podiumNumberStyle,
                        blendMode: BlendMode.softLight,
                      ),
                    ),
                  ),
                  Positioned(
                    left: podiumLocalX(_num3CellLeft),
                    top: podiumLocalY(_num3CellTop),
                    width: _num3CellW * s,
                    height: _num3CellH * s,
                    child: Center(
                      child: PodiumRankNumber(
                        digit: '3',
                        style: podiumNumberStyle,
                        blendMode: BlendMode.softLight,
                      ),
                    ),
                  ),
                  Positioned(
                    left: podiumLocalX(_num1CellLeft),
                    top: podiumLocalY(_num1CellTop),
                    width: _num1CellW * s,
                    height: _num1CellH * s,
                    child: Center(
                      child: PodiumRankNumber(
                        digit: '1',
                        style: podiumNumberStyle,
                        blendMode: BlendMode.plus,
                      ),
                    ),
                  ),
                  // 2위 (왼쪽)
                  Positioned(
                    left: x(36),
                    top: y(192),
                    child: _PodiumSlot(
                      entry: second,
                      scale: s,
                      winnerFrame: false,
                      showCrown: false,
                      defaultProfile: _defaultProfile,
                      premiumBadge: _premiumBadge,
                      likeIcon: _likeIcon,
                      crownAsset: _podiumCrown,
                    ),
                  ),
                  // 3위 (오른쪽)
                  Positioned(
                    left: x(312),
                    top: y(212),
                    child: _PodiumSlot(
                      entry: third,
                      scale: s,
                      winnerFrame: false,
                      showCrown: false,
                      defaultProfile: _defaultProfile,
                      premiumBadge: _premiumBadge,
                      likeIcon: _likeIcon,
                      crownAsset: _podiumCrown,
                    ),
                  ),
                  // 1위 (중앙)
                  Positioned(
                    left: x(167.31),
                    top: y(128),
                    child: _PodiumSlot(
                      entry: first,
                      scale: s,
                      winnerFrame: true,
                      showCrown: true,
                      defaultProfile: _defaultProfile,
                      premiumBadge: _premiumBadge,
                      likeIcon: _likeIcon,
                      crownAsset: _podiumCrown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF8A8A8A),
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('Rank', style: style)),
          Expanded(child: Text('Player', style: style)),
          SizedBox(
            width: 48,
            child: Text('Like', style: style, textAlign: TextAlign.right),
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
    required this.winnerFrame,
    required this.showCrown,
    required this.defaultProfile,
    required this.premiumBadge,
    required this.likeIcon,
    required this.crownAsset,
  });

  final RankEntryDto? entry;
  final double scale;
  final bool winnerFrame;
  final bool showCrown;
  final String defaultProfile;
  final String premiumBadge;
  final String likeIcon;
  final String crownAsset;

  static const _boxW = 104.0;
  static const _boxH = 115.5;
  static const _badge = 30.0;
  static const _badgeLeft = 76.69;
  static const _badgeTop = 76.0;
  /// Figma 아바타 박스 폭과 동일 — 원 지름.
  static const _avatarOuter = 104.0;
  static const _borderW = 3.5;
  // 왕관 Figma(160,71,154.77×118.33) − 1위 박스(167.31,128). 보정 스케일/넛지 금지.
  static const _crownW = 154.77;
  static const _crownH = 118.33;
  static const _crownLeft = 160.0 - 167.31; // -7.31
  static const _crownTop = 71.0 - 128.0; // -57

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final name = (entry?.name ?? '').trim();
    final displayName =
        entry == null ? '' : (name.isEmpty ? '—' : name);
    final isPremium = entry?.subscribedYn == 'Y';

    return SizedBox(
      width: _boxW * s,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _boxW * s,
            height: _boxH * s,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
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
                    // Paywall `_cardShadow`와 동일 (Figma 바깥쪽 그림자 20/20/20, #000 30%).
                    outerShadowScale: s,
                  ),
                ),
                if (showCrown)
                  Positioned(
                    left: _crownLeft * s,
                    top: _crownTop * s,
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
                if (entry != null)
                  Positioned(
                    left: _badgeLeft * s,
                    top: _badgeTop * s,
                    child: _PodiumLevelBadge(
                      level: entry!.level,
                      size: _badge * s,
                      fontSize: 20 * s,
                    ),
                  ),
              ],
            ),
          ),
          if (entry != null) ...[
            SizedBox(height: 4 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    // 4~10위와 동일 (스케일 고정 14)
                    style: const TextStyle(
                      fontFamily: 'ChironHeiHK',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontVariations: [FontVariation('wght', 700)],
                      fontSize: 14,
                      height: 1.1,
                    ),
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    premiumBadge,
                    width: 14,
                    height: 14,
                  ),
                ],
              ],
            ),
            SizedBox(height: 2 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  likeIcon,
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry!.weeklyLike}',
                  style: const TextStyle(
                    fontFamily: 'ChironHeiHK',
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontVariations: [FontVariation('wght', 400)],
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
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
    required this.entry,
    required this.defaultProfile,
    required this.premiumBadge,
  });

  final RankEntryDto entry;
  final String defaultProfile;
  final String premiumBadge;

  static const _listAvatarOuter = 40.0;
  static const _listBorderW = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final name = (entry.name ?? '').trim();
    final displayName = name.isEmpty ? '—' : name;
    final highlight = entry.isMe;
    final isPremium = entry.subscribedYn == 'Y';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? const Color(0x3380D7CF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: const Color(0x6680D7CF), width: 1)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: theme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RankProfileFrame(
                imgPath: entry.imgPath,
                outer: _listAvatarOuter,
                borderWidth: _listBorderW,
                style: isPremium
                    ? _RankProfileFrameStyle.premium
                    : _RankProfileFrameStyle.free,
                defaultAsset: defaultProfile,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: _LevelBadge(level: entry.level, compact: true),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'ChironHeiHK',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontVariations: [FontVariation('wght', 700)],
                      fontSize: 14,
                      height: 1.1,
                    ),
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, 1),
                    child: Image.asset(premiumBadge, width: 14, height: 14),
                  ),
                ],
              ],
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
                '${entry.weeklyLike}',
                style: const TextStyle(
                  fontFamily: 'ChironHeiHK',
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontVariations: [FontVariation('wght', 400)],
                  fontSize: 14,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
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

  /// 1~3위 `_PodiumLevelBadge`와 동일: #0CABA8 원형 + white w700.
  @override
  Widget build(BuildContext context) {
    final size = compact ? 16.0 : 18.0;
    final fontSize = compact ? 9.0 : 10.0;
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
