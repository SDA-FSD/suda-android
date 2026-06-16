import 'package:flutter/widgets.dart';

import '../services/effect_overlay_service.dart';
import '../widgets/effects/mission_complete_overlay.dart';

class MissionCompleteEffect {
  MissionCompleteEffect._();

  /// Playing root overlay — [anchorKey] 중심(미션 on/off 아이콘)에 shine 재생.
  static void play(
    BuildContext context, {
    required GlobalKey anchorKey,
    VoidCallback? onCompleted,
  }) {
    EffectOverlayService.show(
      context: context,
      builder: (_) => MissionCompleteOverlay(
        anchorKey: anchorKey,
        onCompleted: () {
          EffectOverlayService.complete();
          onCompleted?.call();
        },
      ),
    );
  }
}
