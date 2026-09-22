import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../utils/user_img_path.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/default_popup.dart';
import '../widgets/suda_label_tabs.dart';
import 'other_user_profile.dart';
import 'rank/rank_crown_avatar.dart';

/// 내 프로필 Friends 칸에서 여는 친구·받은 요청 Sub Screen.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const _defaultProfile =
      'assets/images/icons/default_profile_image.png';
  static const _premiumBadge =
      'assets/images/icons/premium_verified_badge.png';

  List<FriendUserDto> _friends = const [];
  List<FriendUserDto> _requests = const [];
  bool _loading = true;
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final list = await SudaApiClient.getFriends(accessToken: token);
      if (!mounted) return;
      setState(() {
        _friends = list.friends;
        _requests = list.incomingRequests;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      DefaultToast.show(context, 'Failed to load friends: $e', isError: true);
    }
  }

  Future<void> _respond(FriendUserDto user, {required bool accept}) async {
    if (!_busyIds.add(user.userId)) return;
    setState(() {});
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;
      if (accept) {
        await SudaApiClient.acceptFriend(
          accessToken: token,
          targetUserId: user.userId,
        );
      } else {
        await SudaApiClient.rejectFriend(
          accessToken: token,
          targetUserId: user.userId,
        );
      }
      if (!mounted) return;
      await _load();
    } on FriendApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (e.isLimitExceeded) {
        final mine = e.limitUserId == null || e.limitUserId != user.userId;
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
      _busyIds.remove(user.userId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _showBlockedPopup() {
    return _showOkBody(
      AppLocalizations.of(context)!.otherUserFriendBlockedBody,
    );
  }

  Future<void> _showOkBody(String body) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    return DefaultPopup.show(
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

  void _openProfile(FriendUserDto user) {
    OtherUserProfileScreen.open(context, user.userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      centerTitle: l10n.friendsTitle,
      background: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF295062)],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SudaLabelTabs(
              expandContent: true,
              tabs: [
                SudaLabelTab(
                  label: SudaTabLabel.l10n((l10n) => l10n.friendsTitle),
                  child: _list(
                    users: _friends,
                    empty: l10n.friendsEmpty,
                  ),
                ),
                SudaLabelTab(
                  label: SudaTabLabel.l10n((l10n) => l10n.friendRequestsTab),
                  child: _list(
                    users: _requests,
                    empty: l10n.friendRequestsEmpty,
                    showResponse: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _list({
    required List<FriendUserDto> users,
    required String empty,
    bool showResponse = false,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          empty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _FriendEntry(
          user: user,
          defaultProfile: _defaultProfile,
          premiumBadge: _premiumBadge,
          busy: _busyIds.contains(user.userId),
          onOpen: () => _openProfile(user),
          onAccept: showResponse ? () => unawaited(_respond(user, accept: true)) : null,
          onDecline: showResponse
              ? () => unawaited(_respond(user, accept: false))
              : null,
        );
      },
    );
  }
}

class _FriendEntry extends StatelessWidget {
  const _FriendEntry({
    required this.user,
    required this.defaultProfile,
    required this.premiumBadge,
    required this.busy,
    required this.onOpen,
    this.onAccept,
    this.onDecline,
  });

  static const _avatarOuter = 40.0;
  static const _borderWidth = 2.0;

  final FriendUserDto user;
  final String defaultProfile;
  final String premiumBadge;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  static const _nameStyle = TextStyle(
    fontFamily: 'ChironHeiHK',
    color: Colors.white,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 14,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (user.name ?? '').trim();
    final displayName = name.isEmpty ? '—' : name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpen,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RankProfileFrame(
                  imgPath: UserImgPath.orFallback(user.imgPath),
                  outer: _avatarOuter,
                  borderWidth: _borderWidth,
                  style: user.isPremium
                      ? RankProfileFrameStyle.premium
                      : RankProfileFrameStyle.free,
                  defaultAsset: defaultProfile,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: RankPodiumLevelBadge(
                    level: user.level,
                    size: 16,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _nameStyle,
                    ),
                  ),
                  if (user.isPremium) ...[
                    const SizedBox(width: 4),
                    Image.asset(premiumBadge, width: 14, height: 14),
                  ],
                ],
              ),
            ),
          ),
          if (onAccept != null && onDecline != null) ...[
            const SizedBox(width: 8),
            _ResponseButton(
              label: l10n.friendRequestAccept,
              color: const Color(0xFF0CABA8),
              onTap: busy ? null : onAccept,
            ),
            const SizedBox(width: 8),
            _ResponseButton(
              label: l10n.friendRequestDecline,
              color: const Color(0xFF353535),
              onTap: busy ? null : onDecline,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  const _ResponseButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
