import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import 'default_popup.dart';

Future<void> claimDailyTicketAfterPopup(
  BuildContext context,
  String accessToken, {
  Future<void> Function()? onSuccess,
}) async {
  try {
    final result = await SudaApiClient.claimDailyTicket(
      accessToken: accessToken,
    );
    if (!context.mounted) return;
    if (result.completeYn == 'Y') {
      final l10n = AppLocalizations.of(context)!;
      DefaultToast.show(context, l10n.surveySuccessToast);
      if (onSuccess != null) {
        await onSuccess();
      }
    }
  } catch (_) {
    // 실패 시 별도 처리 없음
  }
}

/// Daily ticket grant popup (`DefaultPopup`).
///
/// [onClaimSuccess]: e.g. Home refreshes ticket count after claim.
Future<void> showDailyTicketDefaultPopup(
  BuildContext context,
  String accessToken, {
  Future<void> Function()? onClaimSuccess,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  await DefaultPopup.show(
    context,
    topWidget: Center(
      child: Image.asset(
        'assets/images/icons/ticket_with_1.png',
        width: 56,
        height: 29,
        fit: BoxFit.contain,
      ),
    ),
    titleText: l10n.dailyTicketTitle,
    bodyWidget: Text(
      l10n.dailyTicketContent,
      style: theme.bodyLarge?.copyWith(color: Colors.white),
      textAlign: TextAlign.center,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.dailyTicketButton,
        onPressed: () {
          unawaited(
            claimDailyTicketAfterPopup(
              context,
              accessToken,
              onSuccess: onClaimSuccess,
            ),
          );
        },
      ),
      DefaultPopupButton(
        type: DefaultPopupButtonType.text,
        label: l10n.surveyMaybeLater,
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: [showDailyTicketDefaultPopup] after loading access token.
Future<void> showDailyTicketDefaultPopupForLab(
  BuildContext context,
) async {
  final accessToken = await TokenStorage.loadAccessToken();
  if (!context.mounted) return;
  if (accessToken == null) {
    DefaultToast.show(context, 'Not signed in', isError: true);
    return;
  }
  await showDailyTicketDefaultPopup(context, accessToken);
}
