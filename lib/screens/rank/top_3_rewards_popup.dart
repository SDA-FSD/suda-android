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
  );
}

class _Top3RewardsBody extends StatelessWidget {
  const _Top3RewardsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final rows = <(String, List<String>)>[
      (
        l10n.rankTop3Place1,
        [l10n.rankTop3Badge1, l10n.rankTop3Likes100, l10n.rankTop3Box3],
      ),
      (
        l10n.rankTop3Place2,
        [l10n.rankTop3Badge2, l10n.rankTop3Likes60, l10n.rankTop3Box2],
      ),
      (
        l10n.rankTop3Place3,
        [l10n.rankTop3Badge3, l10n.rankTop3Likes50, l10n.rankTop3Box1],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place,
          style: theme.titleSmall?.copyWith(
            color: const Color(0xFFFFD8A4),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '• $item',
              style: theme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
