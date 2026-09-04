import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// 풀 가변 TTF를 첫 프레임 전에 등록한다. 스플래시 해제는 JWT 경로를 따른다.
class AppFontPreload {
  static const _assets = <String, String>{
    'ChironHeiHK': 'assets/fonts/ChironHeiHK-VariableFont_wght.ttf',
    'ChironGoRoundTC': 'assets/fonts/ChironGoRoundTC-VariableFont_wght.ttf',
  };

  static Future<void> load() async {
    await Future.wait([
      for (final entry in _assets.entries)
        _loadFamily(entry.key, entry.value),
    ]);
  }

  static Future<void> _loadFamily(String family, String asset) async {
    final data = await rootBundle.load(asset);
    await ui.loadFontFromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      fontFamily: family,
    );
  }
}
