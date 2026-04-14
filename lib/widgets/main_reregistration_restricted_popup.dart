import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'default_popup.dart';

Future<void> _showMainReregistrationRestrictedMessage(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final message = l10n != null
      ? l10n.reregistrationRestrictedMessage
      : 'You can sign up again 2 days after deleting your account. Please try again later.';
  final theme = Theme.of(context).textTheme;
  await DefaultPopup.show(
    context,
    bodyWidget: Center(
      child: Text(
        message,
        style: theme.bodyLarge?.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: 'Okay',
        onPressed: () {},
      ),
    ],
  );
}

/// `_checkAuthStatus`: re-registration blocked message (`DefaultPopup`).
Future<void> showMainReregistrationRestrictedAuthCheckDefaultPopup(
  BuildContext context,
) =>
    _showMainReregistrationRestrictedMessage(context);

/// `_onSignIn`: same message (`DefaultPopup`).
Future<void> showMainReregistrationRestrictedSignInDefaultPopup(
  BuildContext context,
) =>
    _showMainReregistrationRestrictedMessage(context);

/// Lab: same as [showMainReregistrationRestrictedAuthCheckDefaultPopup].
Future<void> showMainReregistrationRestrictedAuthCheckDefaultPopupForLab(
  BuildContext context,
) =>
    showMainReregistrationRestrictedAuthCheckDefaultPopup(context);

/// Lab: same as [showMainReregistrationRestrictedSignInDefaultPopup].
Future<void> showMainReregistrationRestrictedSignInDefaultPopupForLab(
  BuildContext context,
) =>
    showMainReregistrationRestrictedSignInDefaultPopup(context);
