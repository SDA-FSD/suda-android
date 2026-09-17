import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/default_popup.dart';

/// Weekly Ranking `?` → Top 3 Rewards. 서버 호출 없음.
Future<void> showTop3RewardsPopup(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return DefaultPopup.show(
    context,
    titleText: l10n.rankTop3RewardsTitle,
    bodyWidget: const _Top3RewardsBody(),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.rankTop3Okay,
        onPressed: () {},
      ),
    ],
    barrierDismissible: true,
    expandPrimaryButtons: true,
  );
}

class _Top3RewardsBody extends StatelessWidget {
  const _Top3RewardsBody();

  static const _dividerColor = Color(0x33D9D9D9); // #D9D9D9 @ 20%

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final rows = <(String, List<(String, String)>)>[
      (
        l10n.rankTop3Place1,
        [
          ('assets/images/icons/medal_1st.png', l10n.rankTop3Badge1),
          ('assets/images/like_at_result.png', l10n.rankTop3Likes100),
          ('assets/images/icons/reward_box.png', l10n.rankTop3Box3),
        ],
      ),
      (
        l10n.rankTop3Place2,
        [
          ('assets/images/icons/medal_2st.png', l10n.rankTop3Badge2),
          ('assets/images/like_at_result.png', l10n.rankTop3Likes60),
          ('assets/images/icons/reward_box.png', l10n.rankTop3Box2),
        ],
      ),
      (
        l10n.rankTop3Place3,
        [
          ('assets/images/icons/medal_3st.png', l10n.rankTop3Badge3),
          ('assets/images/like_at_result.png', l10n.rankTop3Likes50),
          ('assets/images/icons/reward_box.png', l10n.rankTop3Box1),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ColoredBox(
          color: _dividerColor,
          child: SizedBox(height: 1),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.rankTop3RewardsDesc,
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _RewardRankBlock(place: rows[i].$1, items: rows[i].$2),
        ],
      ],
    );
  }
}

class _RewardRankBlock extends StatelessWidget {
  const _RewardRankBlock({required this.place, required this.items});

  final String place;
  final List<(String, String)> items;

  // DefaultPopup glassy 계열: white fill ~10% + border ~24% (중첩 blur 없음)
  static const _cardBg = Color(0x1AFFFFFF); // white @ 10%
  static const _cardBorder = Color(0x3DFFFFFF); // white @ 24%
  static const _iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    // place: ChironHeiHK Bold 20 → headlineSmall; item: 16 Italic
    final placeStyle = theme.headlineSmall?.copyWith(color: Colors.white);
    final itemStyle = theme.bodyMedium?.copyWith(
      color: Colors.white,
      fontStyle: FontStyle.italic,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              place,
              textAlign: TextAlign.center,
              style: placeStyle,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                children: [
                  Image.asset(
                    items[i].$1,
                    width: _iconSize,
                    height: _iconSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(items[i].$2, style: itemStyle),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
