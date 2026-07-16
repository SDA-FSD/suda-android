import 'dart:async';

import 'package:flutter/material.dart';

/// IAP 런치~서버 verify 완료까지 전면 스피너 + 입력 차단.
///
/// Play Billing UI가 떠 있는 동안에도 아래에 유지되며, 복귀 후 verify 구간을
/// 앱 멈춤으로 오해하지 않게 한다.
class IapBusyOverlay {
  IapBusyOverlay._();

  static Future<T> run<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    final dialogContextCompleter = Completer<BuildContext>();

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        barrierColor: const Color(0x99000000),
        builder: (dialogContext) {
          if (!dialogContextCompleter.isCompleted) {
            dialogContextCompleter.complete(dialogContext);
          }
          return const PopScope(
            canPop: false,
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );

    final dialogContext = await dialogContextCompleter.future;

    try {
      return await action();
    } finally {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    }
  }
}
