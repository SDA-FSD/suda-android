import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../l10n/app_localizations.dart';
import '../models/user_models.dart';
import 'default_popup.dart';

class ProfileAchievementsSection extends StatelessWidget {
  final List<RankedPlaceAchievementDto> achievements;

  const ProfileAchievementsSection({
    super.key,
    required this.achievements,
  });

  static const _hPad = 24.0;
  static const _colGap = 12.0;
  static const _titleGap = 6.0;
  static const _progressGap = 4.0;
  static const _progressColor = Color(0xFF635F5F);
  static const _popupImageSize = 96.0;

  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final items = achievements.isEmpty
        ? const [
            RankedPlaceAchievementDto(place: 1, progressCount: 0),
            RankedPlaceAchievementDto(place: 2, progressCount: 0),
            RankedPlaceAchievementDto(place: 3, progressCount: 0),
          ]
        : achievements;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: _colGap),
            Expanded(
              child: _AchievementCell(
                item: items[i],
                grayscale: _grayscale,
                titleGap: _titleGap,
                progressGap: _progressGap,
                progressColor: _progressColor,
                popupImageSize: _popupImageSize,
              ),
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
  final RankedPlaceAchievementDto item;
  final ColorFilter grayscale;
  final double titleGap;
  final double progressGap;
  final Color progressColor;
  final double popupImageSize;

  const _AchievementCell({
    required this.item,
    required this.grayscale,
    required this.titleGap,
    required this.progressGap,
    required this.progressColor,
    required this.popupImageSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final copy = _copyFor(l10n, item.place);
    final titleStyle = theme.bodySmall?.copyWith(color: Colors.white);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPopup(context, l10n, theme, copy),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _MedalImage(
              asset: copy.asset,
              grayscale: !item.unlocked,
              filter: grayscale,
            ),
          ),
          SizedBox(height: titleGap),
          SizedBox(
            height: 18,
            width: double.infinity,
            child: _MarqueeTitle(text: copy.title, style: titleStyle),
          ),
          if (item.progressCount > 0) ...[
            SizedBox(height: progressGap),
            Text(
              l10n.profileAchievementCount(item.progressCount),
              textAlign: TextAlign.center,
              style: theme.bodySmall?.copyWith(color: progressColor),
            ),
          ],
        ],
      ),
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
              asset: copy.asset,
              grayscale: !item.unlocked,
              filter: grayscale,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.profileAchievementCount(item.progressCount),
            textAlign: TextAlign.center,
            style: theme.bodySmall?.copyWith(color: progressColor),
          ),
          const SizedBox(height: 20),
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
