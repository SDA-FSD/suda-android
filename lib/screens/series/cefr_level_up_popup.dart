import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/default_popup.dart';

/// 다음 난이도 안내. 반환값은 다음 난이도로 바꿀지.
Future<bool> showCefrLevelUpPopup(
  BuildContext context, {
  required String levelLabel,
}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context).textTheme;
  final result = Completer<bool>();

  DefaultPopup.show(
    context,
    barrierDismissible: false,
    titleText: l10n.cefrLevelUpTitle,
    bodyWidget: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.cefrLevelUpBody(levelLabel),
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.cefrLevelUpCaption,
          textAlign: TextAlign.center,
          style: theme.bodySmall?.copyWith(color: const Color(0xFF80D7CF)),
        ),
      ],
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.cefrLevelUpTryNext,
        onPressed: () {
          if (!result.isCompleted) result.complete(true);
        },
      ),
      DefaultPopupButton(
        type: DefaultPopupButtonType.text,
        label: l10n.cefrLevelUpLater,
        onPressed: () {
          if (!result.isCompleted) result.complete(false);
        },
      ),
    ],
  ).catchError((Object _) {
    if (!result.isCompleted) result.complete(false);
  });

  return result.future;
}

Future<void> showCefrLevelUpPopupForLab(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  await showCefrLevelUpPopup(
    context,
    levelLabel: l10n.cefrLevelBasic,
  );
}
