import 'dart:async';

import 'package:flutter/foundation.dart';

/// iOS AVPlayer 해제를 직렬화한다. `State.dispose`는 sync라
/// `AudioPlayer.dispose()`를 await하지 못해, 빠른 재진입 시 `-11800`이 난다.
/// stop/dispose가 네이티브에서 멈추면 큐 전체가 영구 대기가 되므로 job마다 timeout.
class IosAudioTeardown {
  IosAudioTeardown._();

  static const Duration jobTimeout = Duration(seconds: 2);

  static Future<void> _tail = Future<void>.value();

  static Future<void> wait() async {
    try {
      await _tail.timeout(jobTimeout);
    } on TimeoutException {
      debugPrint('[DEBUG] iOS audio teardown wait timeout, reset');
      _tail = Future<void>.value();
    }
  }

  static void enqueue(Future<void> Function() job) {
    _tail = _tail.then((_) async {
      try {
        await job().timeout(jobTimeout);
      } catch (_) {}
    });
  }
}
