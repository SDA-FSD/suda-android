import 'package:flutter/widgets.dart';

import '../services/effect_overlay_service.dart';
import '../widgets/effects/ribbon_burst_overlay.dart';

/// 화면 중앙에서 직사각형 리본이 터져 흩어지는 3D 폭죽 오버레이.
/// 주간랭킹 claim 등 보조 연출. 딤/입력 가로채기 없음.
class RibbonBurstEffect {
  RibbonBurstEffect._();

  static Future<void> play(
    BuildContext context, {
    VoidCallback? onCompleted,
  }) async {
    final handle = EffectOverlayService.show(
      context: context,
      builder: (_) => RibbonBurstOverlay(
        onCompleted: () {
          EffectOverlayService.complete();
          onCompleted?.call();
        },
      ),
    );
    await handle.completed;
  }
}
