import 'package:flutter/widgets.dart';

import '../services/effect_overlay_service.dart';
import '../widgets/effects/like_progress_overlay.dart';

class LikeProgressEffectParams {
  final int asIsLikePoint;
  final int toBeLikePoint;
  final int asIsLevel;
  final int toBeLevel;
  final int asIsProgress;
  final int toBeProgress;

  const LikeProgressEffectParams({
    required this.asIsLikePoint,
    required this.toBeLikePoint,
    required this.asIsLevel,
    required this.toBeLevel,
    required this.asIsProgress,
    required this.toBeProgress,
  });
}

class LikeProgressEffect {
  static Future<void> play(
    BuildContext context, {
    required LikeProgressEffectParams params,
    VoidCallback? onCompleted,
  }) async {
    final handle = EffectOverlayService.show(
      context: context,
      builder: (_) => LikeProgressOverlay(
        params: params,
        onCompleted: () {
          EffectOverlayService.complete();
          onCompleted?.call();
        },
      ),
    );

    await handle.completed;
  }
}

