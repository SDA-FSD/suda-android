import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

import '../models/user_models.dart';

/// 화면 조작·연출 진동. `DISABLE_VIBRATION=Y`이면 전부 내지 않는다.
class SudaHaptics {
  static int _tapGen = 0;
  static bool _enabled = true;

  static const String metaKey = 'DISABLE_VIBRATION';

  static void apply(UserDto? user) {
    _enabled = !disabledOf(user);
  }

  static void allow(bool on) {
    _enabled = on;
  }

  static bool disabledOf(UserDto? user) {
    final meta = user?.metaInfo;
    if (meta == null) return false;
    for (final item in meta) {
      if (item.key == metaKey && item.value == 'Y') return true;
    }
    return false;
  }

  /// 조작 탭. 같은 호출 스택에서 [negative]가 나오면 탭 진동은 내지 않는다.
  static void tap() {
    final gen = ++_tapGen;
    scheduleMicrotask(() {
      if (gen != _tapGen) return;
      unawaited(vibrate(duration: 50, amplitude: 255));
    });
  }

  /// 마이크 홀드. 탭과 같은 진동.
  static void hold() => tap();

  /// 거부·불가 토스트.
  static void negative() {
    _tapGen++;
    unawaited(
      vibrate(
        pattern: [0, 60, 80, 90],
        intensities: [0, 255, 0, 255],
      ),
    );
  }

  static VoidCallback? bind(VoidCallback? action, {bool haptic = true}) {
    if (action == null || !haptic) return action;
    return () {
      tap();
      action();
    };
  }

  static Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
    VibrationPreset? preset,
  }) async {
    if (!_enabled) return;
    try {
      await Vibration.vibrate(
        duration: duration,
        pattern: pattern,
        repeat: repeat,
        intensities: intensities,
        amplitude: amplitude,
        sharpness: sharpness,
        preset: preset,
      );
    } catch (_) {}
  }
}
