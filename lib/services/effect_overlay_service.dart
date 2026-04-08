import 'dart:async';

import 'package:flutter/widgets.dart';

class EffectOverlayHandle {
  final Future<void> completed;
  final void Function() dismiss;

  const EffectOverlayHandle({
    required this.completed,
    required this.dismiss,
  });
}

class EffectOverlayService {
  EffectOverlayService._();

  static OverlayEntry? _currentEntry;
  static Completer<void>? _currentCompleter;

  static EffectOverlayHandle show({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    dismiss();

    final completer = Completer<void>();
    _currentCompleter = completer;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => builder(ctx),
    );
    _currentEntry = entry;

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);

    return EffectOverlayHandle(
      completed: completer.future,
      dismiss: dismiss,
    );
  }

  static void complete() {
    final completer = _currentCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _currentCompleter = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void dismiss() {
    final completer = _currentCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _currentCompleter = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

