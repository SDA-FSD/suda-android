import 'package:flutter/material.dart';

import '../../widgets/default_popup.dart';

/// Weekly Ranking `?` → Top 3 Rewards. 서버 호출 없음. 영어 카피 하드코딩.
Future<void> showTop3RewardsPopup(BuildContext context) {
  return DefaultPopup.show(
    context,
    titleText: 'Top 3 Rewards',
    bodyWidget: const _Top3RewardsBody(),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: 'Okay',
        onPressed: () {},
      ),
    ],
    barrierDismissible: true,
  );
}

class _Top3RewardsBody extends StatelessWidget {
  const _Top3RewardsBody();

  static const _rows = <(String, List<String>)>[
    ('1st', ['Champion Badge', '+100 Likes', '×3 Reward Box']),
    ('2nd', ['Champion Badge', '+60 Likes', '×2 Reward Box']),
    ('3rd', ['Champion Badge', '+50 Likes', '×1 Reward Box']),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Earn Likes each week and compete with other learners for the top spots!',
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _RewardRankBlock(place: _rows[i].$1, items: _rows[i].$2),
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
