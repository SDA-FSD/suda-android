import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../l10n/app_localizations.dart';
import '../models/user_models.dart';
import 'default_popup.dart';

class ProfileAchievementsSection extends StatelessWidget {
  final List<ProfileAchievementItem> items;
  final bool tapEnabled;
  final bool unlockedOnly;
  final bool showClaim;
  final Future<void> Function(ProfileAchievementItem item)? onClaim;

  const ProfileAchievementsSection({
    super.key,
    required this.items,
    this.tapEnabled = true,
    this.unlockedOnly = false,
    this.showClaim = false,
    this.onClaim,
  });

  static const _hPad = 40.0;
  static const _colGap = 24.0;
  static const _titleGap = 6.0;
  static const _progressGap = 4.0;
  static const _progressColor = Color(0xFF635F5F);
  static const _popupImageSize = 96.0;

  static const _grayscale = ColorFilter.matrix(<double>[
    0.0808,
    0.2718,
    0.0274,
    0,
    -12,
    0.0808,
    0.2718,
    0.0274,
    0,
    -12,
    0.0808,
    0.2718,
    0.0274,
    0,
    -12,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final source = items.isEmpty
        ? const [
            ProfileAchievementItem(place: 1),
            ProfileAchievementItem(place: 2),
            ProfileAchievementItem(place: 3),
          ]
        : items;
    final visible = unlockedOnly
        ? source.where((item) => item.unlocked).toList()
        : source;
    if (visible.isEmpty) return const SizedBox.shrink();
    final rows = <List<ProfileAchievementItem?>>[];
    for (var i = 0; i < visible.length; i += 3) {
      final end = i + 3 > visible.length ? visible.length : i + 3;
      final row = <ProfileAchievementItem?>[...visible.sublist(i, end)];
      while (row.length < 3) {
        row.add(null);
      }
      rows.add(row);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows[r].length; i++) ...[
                  if (i > 0) const SizedBox(width: _colGap),
                  Expanded(
                    child: rows[r][i] == null
                        ? const SizedBox.shrink()
                        : _AchievementCell(
                            item: rows[r][i]!,
                            grayscale: _grayscale,
                            titleGap: _titleGap,
                            progressGap: _progressGap,
                            progressColor: _progressColor,
                            popupImageSize: _popupImageSize,
                            tapEnabled: tapEnabled,
                            showClaim: showClaim,
                            onClaim: onClaim,
                          ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementCopy {
  final String title;
  final String hint;
  final String asset;

  const _AchievementCopy({
    required this.title,
    required this.hint,
    required this.asset,
  });
}

int _activityBadgeLevel(ProfileAchievementItem item, {required bool showClaim}) {
  if (showClaim && item.claimable && item.claimLevel > 0) return item.claimLevel;
  if (item.level <= 0) return 1;
  return item.level;
}

int _activityMaxLevel(String code) {
  return switch (code) {
    'TA' || 'SC' || 'ON' => 4,
    _ => 2,
  };
}

int _activityPopupBadgeLevel(ProfileAchievementItem item, {required bool showClaim}) {
  if (item.level <= 0) return 1;
  final shown = _activityBadgeLevel(item, showClaim: showClaim);
  final max = _activityMaxLevel(item.code);
  if (shown >= max) return max;
  return shown + 1;
}

String _activityAsset(String code, int level) {
  final prefix = switch (code) {
    'HI' => 'HI',
    'TA' => 'TA',
    'SC' => 'SC',
    'ON' => 'ON',
    _ => 'PG',
  };
  return 'assets/images/achievement/$prefix-$level.png';
}

_AchievementCopy _activityCopy(
  AppLocalizations l10n,
  ProfileAchievementItem item, {
  required bool showClaim,
}) {
  final goal = item.goal;
  final badge = _activityBadgeLevel(item, showClaim: showClaim);
  switch (item.code) {
    case 'HI':
      return _AchievementCopy(
        title: l10n.achievementHintSeeker,
        hint: l10n.achievementHintSeekerHint(goal),
        asset: 'assets/images/achievement/HI-$badge.png',
      );
    case 'TA':
      return _AchievementCopy(
        title: l10n.achievementTalkative,
        hint: l10n.achievementTalkativeHint(goal),
        asset: 'assets/images/achievement/TA-$badge.png',
      );
    case 'SC':
      return _AchievementCopy(
        title: l10n.achievementSceneStealer,
        hint: l10n.achievementSceneStealerHint(goal),
        asset: 'assets/images/achievement/SC-$badge.png',
      );
    case 'ON':
      return _AchievementCopy(
        title: l10n.achievementOnARoll,
        hint: l10n.achievementOnARollHint(goal),
        asset: 'assets/images/achievement/ON-$badge.png',
      );
    default:
      return _AchievementCopy(
        title: l10n.achievementPocketGuide,
        hint: l10n.achievementPocketGuideHint(goal),
        asset: 'assets/images/achievement/PG-$badge.png',
      );
  }
}

_AchievementCopy _copyFor(AppLocalizations l10n, int place) {
  switch (place) {
    case 2:
      return _AchievementCopy(
        title: l10n.profileAchievementWeeklyRunnerUp,
        hint: l10n.profileAchievementWeeklyRunnerUpHint,
        asset: 'assets/images/achievement/medal_2st.png',
      );
    case 3:
      return _AchievementCopy(
        title: l10n.profileAchievementWeeklyThird,
        hint: l10n.profileAchievementWeeklyThirdHint,
        asset: 'assets/images/achievement/medal_3st.png',
      );
    default:
      return _AchievementCopy(
        title: l10n.profileAchievementWeeklyChampion,
        hint: l10n.profileAchievementWeeklyChampionHint,
        asset: 'assets/images/achievement/medal_1st.png',
      );
  }
}

class _AchievementCell extends StatelessWidget {
  final ProfileAchievementItem item;
  final ColorFilter grayscale;
  final double titleGap;
  final double progressGap;
  final Color progressColor;
  final double popupImageSize;
  final bool tapEnabled;
  final bool showClaim;
  final Future<void> Function(ProfileAchievementItem item)? onClaim;

  const _AchievementCell({
    required this.item,
    required this.grayscale,
    required this.titleGap,
    required this.progressGap,
    required this.progressColor,
    required this.popupImageSize,
    required this.tapEnabled,
    required this.showClaim,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final copy = item.isActivity
        ? _activityCopy(l10n, item, showClaim: showClaim)
        : _copyFor(l10n, item.place);
    final titleStyle = theme.bodySmall?.copyWith(color: Colors.white);
    final claiming = showClaim && item.claimable;
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tapEnabled ? () => _showPopup(context, l10n, theme, copy) : null,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                _MedalImage(
                  asset: copy.asset,
                  grayscale: !item.unlocked,
                  filter: grayscale,
                ),
                if (claiming)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 9, height: 9),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: titleGap),
        if (claiming)
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0CABA8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const StadiumBorder(),
              ),
              onPressed: onClaim == null ? null : () => onClaim!(item),
              child: Text(
                l10n.achievementClaim,
                style: theme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                ),
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 18,
            width: double.infinity,
            child: _MarqueeTitle(text: copy.title, style: titleStyle),
          ),
          if (item.isActivity) ...[
            SizedBox(height: progressGap),
            Text(
              '${item.progress}/${item.goal}',
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(color: progressColor),
            ),
          ] else if (item.progressCount > 0) ...[
            SizedBox(height: progressGap),
            Text(
              l10n.profileAchievementCount(item.progressCount),
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(color: progressColor),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _showPopup(
    BuildContext context,
    AppLocalizations l10n,
    TextTheme theme,
    _AchievementCopy copy,
  ) {
    return DefaultPopup.show(
      context,
      titleText: copy.title,
      expandPrimaryButtons: true,
      bodyWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: popupImageSize,
            height: popupImageSize,
            child: _MedalImage(
              asset: item.isActivity
                  ? _activityAsset(
                      item.code,
                      _activityPopupBadgeLevel(item, showClaim: showClaim),
                    )
                  : copy.asset,
              grayscale: item.isActivity ? false : !item.unlocked,
              filter: grayscale,
            ),
          ),
          const SizedBox(height: 20),
          if (!item.isActivity)
            Text(
              l10n.profileAchievementCount(item.progressCount),
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(color: progressColor),
            ),
          if (!item.isActivity) const SizedBox(height: 20),
          Text(
            copy.hint,
            textAlign: TextAlign.center,
            style: theme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.profileLevelProgressGotIt,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _MedalImage extends StatelessWidget {
  final String asset;
  final bool grayscale;
  final ColorFilter filter;

  const _MedalImage({
    required this.asset,
    required this.grayscale,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(asset, fit: BoxFit.contain);
    if (!grayscale) return image;
    return ColorFiltered(colorFilter: filter, child: image);
  }
}

class _MarqueeTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _MarqueeTitle({required this.text, required this.style});

  bool _overflows(double maxWidth, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: direction,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overflow = _overflows(
          constraints.maxWidth,
          Directionality.of(context),
        );
        if (!overflow) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            textAlign: TextAlign.center,
            style: style,
          );
        }
        return Marquee(
          text: text,
          style: style,
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 20,
          velocity: 30,
          pauseAfterRound: const Duration(seconds: 2),
          startPadding: 0,
          accelerationDuration: const Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: const Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        );
      },
    );
  }
}
