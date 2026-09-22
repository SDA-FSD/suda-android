import 'dart:async';
import 'dart:ui' show FontVariation, ImageFilter;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/sub_screen_route.dart';
import '../utils/user_img_path.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/cdn_thumb_image.dart';
import '../widgets/character_rarity_frame.dart';
import '../widgets/default_popup.dart';
import '../widgets/default_profile_avatar.dart';
import '../widgets/profile_achievements_section.dart';
import '../widgets/suda_label_tabs.dart';
import '../widgets/suda_neighbors_row.dart';
import 'rank/rank_crown_avatar.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final int userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  static const String routeName = '/profile';

  static Future<void> open(BuildContext context, int userId) {
    return Navigator.push(
      context,
      SubScreenRoute(page: OtherUserProfileScreen(userId: userId)),
    );
  }

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  static const _shimmerBase = Color(0xFF2A2A2A);
  static const _shimmerHighlight = Color(0xFF3F3F3F);
  static const _premiumBadge = 'assets/images/icons/premium_verified_badge.png';

  OtherUserProfileDto? _profile;
  bool _loading = true;
  bool _friendBusy = false;
  double? _gradTabsY;
  final GlobalKey _tabsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;
      final dto = await SudaApiClient.getOtherUserProfile(
        accessToken: token,
        userId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _profile = dto;
        _loading = false;
      });
      _scheduleGradientMeasure();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scheduleGradientMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _profile?.isPremium != true) return;
      final box = _tabsKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final tabsTop = box.localToGlobal(Offset.zero).dy;
      if (_gradTabsY != tabsTop) {
        setState(() => _gradTabsY = tabsTop);
      }
    });
  }

  Widget? _buildPremiumBackground() {
    if (_profile?.isPremium != true) return null;
    final screenH = MediaQuery.sizeOf(context).height;
    final tabsTop = (_gradTabsY ?? screenH * 0.32).clamp(80.0, screenH * 0.7);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF121212)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: tabsTop + 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF08897D),
                  Color(0xFF1D7185),
                  Color(0xFF32598D),
                  Color(0xFF474196),
                  Color(0xFF5C299E),
                  Color(0xFF4E2583),
                  Color(0xFF361D56),
                  Color(0xFF2A1A3F),
                  Color(0xFF1E1629),
                  Color(0xFF121212),
                ],
                stops: [
                  0.0,
                  0.16,
                  0.32,
                  0.46,
                  0.68,
                  0.78,
                  0.86,
                  0.92,
                  0.97,
                  1.0,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onFriendTap() async {
    final profile = _profile;
    if (profile == null || _friendBusy) return;
    switch (profile.relationStatus) {
      case FriendRelationViewStatus.friend:
        await _confirmUnfriend();
      case FriendRelationViewStatus.outgoingPending:
        await _confirmCancelRequest();
      case FriendRelationViewStatus.rejected:
        await _showBlockedPopup();
      case FriendRelationViewStatus.none:
      case FriendRelationViewStatus.incomingPending:
        await _confirmSendRequest();
    }
  }

  Future<void> _confirmUnfriend() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    await DefaultPopup.show(
      context,
      titleText: l10n.otherUserUnfriendTitle,
      bodyWidget: Text(
        l10n.otherUserUnfriendBody,
        textAlign: TextAlign.center,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primaryLight,
          label: l10n.otherUserUnfriendOk,
          onPressed: () => unawaited(
            _runFriendWrite((token) {
              return SudaApiClient.unfriend(
                accessToken: token,
                targetUserId: widget.userId,
              );
            }),
          ),
        ),
        DefaultPopupButton(
          type: DefaultPopupButtonType.text,
          label: l10n.otherUserUnfriendCancel,
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _confirmCancelRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    await DefaultPopup.show(
      context,
      titleText: l10n.otherUserCancelRequestTitle,
      bodyWidget: Text(
        l10n.otherUserCancelRequestBody,
        textAlign: TextAlign.center,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.otherUserCancelRequestOk,
          onPressed: () => unawaited(
            _runFriendWrite((token) {
              return SudaApiClient.cancelFriendRequest(
                accessToken: token,
                targetUserId: widget.userId,
              );
            }),
          ),
        ),
        DefaultPopupButton(
          type: DefaultPopupButtonType.text,
          label: l10n.otherUserKeepRequest,
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _confirmSendRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final profile = _profile;
    if (profile == null) return;
    await DefaultPopup.show(
      context,
      titleText: l10n.otherUserSendRequestTitle,
      bodyWidget: _SendRequestBody(
        imgPath: profile.imgPath,
        level: profile.currentLevel,
        isPremium: profile.isPremium,
        bodyText: l10n.otherUserSendRequestBody,
        textStyle: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.otherUserSendRequestOk,
          onPressed: () => unawaited(
            _runFriendWrite((token) {
              return SudaApiClient.requestFriend(
                accessToken: token,
                targetUserId: widget.userId,
              );
            }),
          ),
        ),
        DefaultPopupButton(
          type: DefaultPopupButtonType.text,
          label: l10n.otherUserSendRequestCancel,
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _showBlockedPopup() {
    return _showOkBody(
      AppLocalizations.of(context)!.otherUserFriendBlockedBody,
    );
  }

  Future<void> _showOkBody(String body) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    await DefaultPopup.show(
      context,
      bodyWidget: Text(
        body,
        textAlign: TextAlign.center,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.otherUserFriendOk,
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _runFriendWrite(
    Future<FriendRelationDto> Function(String token) action,
  ) async {
    if (_friendBusy) return;
    setState(() => _friendBusy = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;
      final result = await action(token);
      if (!mounted) return;
      final prev = _profile;
      if (prev == null) return;
      var friendCount = prev.friendCount;
      if (prev.relationStatus == FriendRelationViewStatus.friend &&
          result.relationStatus != FriendRelationViewStatus.friend) {
        friendCount = (friendCount - 1).clamp(0, friendCount);
      } else if (prev.relationStatus != FriendRelationViewStatus.friend &&
          result.relationStatus == FriendRelationViewStatus.friend) {
        friendCount += 1;
      }
      setState(() {
        _profile = prev.copyWith(
          relationStatus: result.relationStatus,
          friendCount: friendCount,
          retryAvailableAt: result.retryAvailableAt,
          clearRetryAvailableAt: result.retryAvailableAt == null,
        );
      });
    } on FriendApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (e.isLimitExceeded) {
        final mine = e.limitUserId == null || e.limitUserId != widget.userId;
        await _showOkBody(
          mine ? l10n.otherUserFriendLimitSelf : l10n.otherUserFriendLimitThem,
        );
      } else {
        await _showBlockedPopup();
      }
    } catch (_) {
      if (!mounted) return;
      await _showBlockedPopup();
    } finally {
      if (mounted) setState(() => _friendBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final profile = _profile;
    final showShimmer = _loading && profile == null;
    final name = profile?.name ?? '';
    final isPremium = profile?.isPremium == true;

    if (isPremium) _scheduleGradientMeasure();

    return AppScaffold(
      showBackButton: true,
      usePadding: false,
      background: _buildPremiumBackground(),
      body: Stack(
        children: [
          if (!isPremium)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Color(0xFF43716D), Colors.black],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileAvatar(
                        imgPath: profile?.imgPath,
                        isPremium: isPremium,
                        isLoading: showShimmer,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showShimmer)
                                Shimmer.fromColors(
                                  baseColor: _shimmerBase,
                                  highlightColor: _shimmerHighlight,
                                  child: Container(
                                    width: 140,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                )
                              else if (isPremium)
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Transform.translate(
                                      offset: const Offset(0, 1),
                                      child: Image.asset(
                                        _premiumBadge,
                                        width: 18,
                                        height: 18,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ProfileStat(
                                      title: 'Level',
                                      value: '${profile?.currentLevel ?? 0}',
                                      isLoading: showShimmer,
                                    ),
                                  ),
                                  const _ProfileStatDivider(),
                                  Expanded(
                                    child: _ProfileStat(
                                      title: 'Like',
                                      value: '${profile?.likePoint ?? 0}',
                                      isLoading: showShimmer,
                                    ),
                                  ),
                                  const _ProfileStatDivider(),
                                  Expanded(
                                    child: _ProfileStat(
                                      title: 'Friends',
                                      value: '${profile?.friendCount ?? 0}',
                                      isLoading: showShimmer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _FriendPill(
                                status:
                                    profile?.relationStatus ??
                                    FriendRelationViewStatus.none,
                                busy: _friendBusy || showShimmer,
                                onTap: showShimmer ? null : _onFriendTap,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                KeyedSubtree(
                  key: _tabsKey,
                  child: SudaLabelTabs(
                    labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                    selectedIndex: 0,
                    onTabChanged: (_) {},
                    tabs: [
                      SudaLabelTab(
                        label: SudaTabLabel.l10n((l) => l.profileProgress),
                        child: _buildProgress(context, l10n),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, AppLocalizations l10n) {
    final progress = _profile;
    final unlocked =
        progress?.achievements.where((e) => e.unlocked).toList() ??
        const <RankedPlaceAchievementDto>[];
    final titleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    );
    final emptyStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _ProgressStatCard(
                  top: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/icons/streak.png',
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${progress?.currentStreakDays ?? 0}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  bottom: l10n.profileDayStreak,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _ProgressStatCard(
                  top: Text(
                    _formatSpokenCount(progress?.wordsSpokenCount ?? 0),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  bottom: l10n.profileWordsSpoken,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(l10n.profileSudaNeighbors, style: titleStyle),
        ),
        const SizedBox(height: 10),
        SudaNeighborsRow(
          portraits: progress?.claimedCharacters ?? const [],
          emptyText: l10n.otherUserNeighborsEmpty,
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(l10n.profileAchievements, style: titleStyle),
        ),
        const SizedBox(height: 10),
        if (unlocked.isEmpty)
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  l10n.otherUserAchievementsEmpty,
                  textAlign: TextAlign.center,
                  style: emptyStyle,
                ),
              ),
            ),
          )
        else
          ProfileAchievementsSection(
            achievements: unlocked,
            tapEnabled: false,
            unlockedOnly: true,
          ),
      ],
    );
  }
}

String _formatSpokenCount(int n) {
  if (n >= 1000000) return _formatCompact(n, 1000000, 'M');
  if (n >= 1000) return _formatCompact(n, 1000, 'K');
  return '$n';
}

String _formatCompact(int n, int unit, String suffix) {
  final tenths = (n / unit * 10).truncate();
  if (tenths % 10 == 0) return '${tenths ~/ 10}$suffix';
  return '${tenths ~/ 10}.${tenths % 10}$suffix';
}

class _FriendPill extends StatelessWidget {
  final FriendRelationViewStatus status;
  final bool busy;
  final VoidCallback? onTap;

  const _FriendPill({required this.status, required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).elevatedButtonTheme.style?.textStyle
        ?.resolve(const {WidgetState.disabled});
    final labelStyle =
        (theme ??
                const TextStyle(
                  fontFamily: 'ChironGoRoundTC',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ))
            .copyWith(height: 1);

    late final Color fill;
    late final Color textColor;
    late final String label;
    var friendsBorder = false;
    var showCheck = false;

    switch (status) {
      case FriendRelationViewStatus.friend:
        fill = const Color(0x330CABA8);
        textColor = Colors.white;
        label = l10n.otherUserFriends;
        friendsBorder = true;
        showCheck = true;
      case FriendRelationViewStatus.outgoingPending:
        fill = const Color(0xFF80D7CF);
        textColor = const Color(0xFF0CABA8);
        label = l10n.otherUserRequested;
      case FriendRelationViewStatus.none:
      case FriendRelationViewStatus.incomingPending:
      case FriendRelationViewStatus.rejected:
        fill = const Color(0xFF0CABA8);
        textColor = Colors.white;
        label = l10n.otherUserAddFriend;
    }

    final child = SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: friendsBorder
              ? const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.white, Color(0x00FFFFFF), Colors.white],
                  stops: [0.0, 0.5, 1.0],
                )
              : null,
          color: friendsBorder ? null : fill,
        ),
        child: Padding(
          padding: EdgeInsets.all(friendsBorder ? 1 : 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showCheck) ...[
                      Image.asset(
                        'assets/images/icons/check_raw.png',
                        width: 14,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(label, style: labelStyle.copyWith(color: textColor)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: busy ? 0.7 : 1,
      child: GestureDetector(onTap: busy ? null : onTap, child: child),
    );
  }
}

class _SendRequestBody extends StatelessWidget {
  final String? imgPath;
  final int level;
  final bool isPremium;
  final String bodyText;
  final TextStyle? textStyle;

  const _SendRequestBody({
    required this.imgPath,
    required this.level,
    required this.isPremium,
    required this.bodyText,
    this.textStyle,
  });

  static const _defaultProfile =
      'assets/images/icons/default_profile_image.png';

  @override
  Widget build(BuildContext context) {
    final popupW = MediaQuery.sizeOf(context).width * 0.8;
    final outer = popupW * 0.3;
    final badge = outer * 0.4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: outer + 8,
          height: outer + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RankProfileFrame(
                imgPath: UserImgPath.orFallback(imgPath),
                outer: outer,
                borderWidth: 2,
                style: isPremium
                    ? RankProfileFrameStyle.premium
                    : RankProfileFrameStyle.free,
                defaultAsset: _defaultProfile,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: RankPodiumLevelBadge(
                  level: level,
                  size: badge,
                  fontSize: badge * 0.56,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(bodyText, textAlign: TextAlign.center, style: textStyle),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imgPath;
  final bool isPremium;
  final bool isLoading;

  const _ProfileAvatar({
    required this.imgPath,
    required this.isPremium,
    required this.isLoading,
  });

  static const _defaultColor = UserImgPath.fallbackColor;
  static const _innerSize = 92.0;

  @override
  Widget build(BuildContext context) {
    const borderW = 4.0;
    final inner = ClipOval(child: _inner());
    return Container(
      width: _innerSize + borderW * 2,
      height: _innerSize + borderW * 2,
      padding: const EdgeInsets.all(borderW),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPremium
              ? const [Color(0xFF80D7CF), Color(0xFF8A38F5)]
              : const [Color(0xFF80D7CF), Color(0xFF43716D)],
        ),
      ),
      child: inner,
    );
  }

  Widget _inner() {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF3F3F3F),
        child: const ColoredBox(color: Colors.white),
      );
    }
    final parsed = UserImgPath.parse(imgPath);
    if (parsed.isEmpty) {
      return DefaultProfileAvatar(size: _innerSize, color: _defaultColor);
    }
    if (parsed.isDefault) {
      return DefaultProfileAvatar(
        size: _innerSize,
        color: parsed.defaultColor ?? _defaultColor,
      );
    }
    final path = parsed.cdnPath;
    if (path == null || path.isEmpty) {
      return DefaultProfileAvatar(size: _innerSize, color: _defaultColor);
    }
    final image = CdnThumbImage(
      path: path,
      slot: CdnThumbSlot.profileAvatar,
      width: _innerSize,
      height: _innerSize,
      fit: BoxFit.cover,
    );
    if (parsed.isCharacter) {
      return CharacterRarityFrame(
        rarity: parsed.rarity!,
        size: _innerSize,
        borderWidth: UserImgPath.nestedRarityBorderWidth,
        child: image,
      );
    }
    return ClipOval(child: image);
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;
  final bool isLoading;

  const _ProfileStat({
    required this.title,
    required this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.bodySmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          if (isLoading)
            Shimmer.fromColors(
              baseColor: const Color(0xFF2A2A2A),
              highlightColor: const Color(0xFF3F3F3F),
              child: Container(
                width: 28,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          else
            Text(
              value,
              style: theme.bodyMedium?.copyWith(color: const Color(0xFF80D7CF)),
            ),
        ],
      ),
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, height: 44, color: const Color(0xFF1E1E1E));
  }
}

class _ProgressStatCard extends StatelessWidget {
  final Widget top;
  final String bottom;

  const _ProgressStatCard({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF80D7CF), Color(0x0080D7CF), Color(0xFF80D7CF)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          child: ColoredBox(
            color: const Color(0xFF121212),
            child: ColoredBox(
              color: const Color(0x290CABA8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      child: top,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bottom,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0CABA8),
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
