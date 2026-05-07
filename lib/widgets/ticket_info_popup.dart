import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_refresh_service.dart';
import '../services/token_storage.dart';
import 'default_popup.dart';
import 'level_progress_bar.dart';

/// 홈 티켓 배지 탭 시 `GET /v1/users/profile`로 레벨·진행·남은 Likes를 받아 표준 팝업으로 안내한다.
/// 프로필 조회 실패 시에도 티켓 안내(본문 1·2)만 표시한다.
Future<void> showTicketInfoPopup(BuildContext context) async {
  await TokenRefreshService.instance.refreshIfNeeded();
  if (!context.mounted) return;
  final accessToken = await TokenStorage.loadAccessToken();
  if (!context.mounted || accessToken == null) return;

  ProfileDto? profile;
  try {
    profile = await SudaApiClient.getUserProfile(accessToken: accessToken);
  } catch (_) {
    profile = null;
  }
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  final baseStyle = theme.bodyLarge?.copyWith(color: Colors.white) ??
      const TextStyle(color: Colors.white);
  final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

  const pink = Color(0xFFFF00A6);
  final italicStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
  final pinkHighlight = italicStyle.copyWith(
    color: pink,
    fontWeight: FontWeight.bold,
  );

  final likesRemaining = profile?.likesToNextLevel;
  final showLikesLine = likesRemaining != null && likesRemaining >= 0;
  final displayLevel =
      profile != null ? max(0, profile.currentLevel) : 0;

  final bodyChildren = <Widget>[
    FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        l10n.ticketInfoBody1,
        style: baseStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
      ),
    ),
    const SizedBox(height: 20),
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ticketInfoHowToPrefix.trimRight(),
          style: baseStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: l10n.ticketInfoDailyCheckIn, style: boldStyle),
              TextSpan(text: l10n.ticketInfoHowToOr),
              TextSpan(text: l10n.ticketInfoLevelUp, style: boldStyle),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    if (profile != null) ...[
      const SizedBox(height: 20),
      Center(
        child: FractionallySizedBox(
          widthFactor: 0.86,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Lv. $displayLevel',
                style: theme.labelSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LevelProgressBar(
                  progressPercentage: profile.progressPercentage,
                ),
              ),
            ],
          ),
        ),
      ),
      if (showLikesLine) ...[
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            style: italicStyle,
            children: [
              TextSpan(text: l10n.ticketInfoLikesPrefix),
              TextSpan(
                text: '$likesRemaining Likes',
                style: pinkHighlight,
              ),
              TextSpan(text: l10n.ticketInfoLikesSuffix),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  ];

  await DefaultPopup.show(
    context,
    titleText: l10n.ticketInfoTitle,
    bodyWidget: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: bodyChildren,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.ticketInfoButtonOkay,
        onPressed: () {},
      ),
    ],
  );
}
