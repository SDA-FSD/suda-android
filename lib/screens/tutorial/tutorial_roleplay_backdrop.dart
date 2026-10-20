import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../widgets/roleplay_overview_backdrop.dart'
    show
        kRoleplayOverviewBackdropBlurSigma,
        kRoleplayOverviewBackdropDim,
        kRoleplayOverviewBackdropImageScale;

/// Tutorial Roleplay 배경 (`tutorial_rp_bg.png`).
/// [blurAmount] 0=선명, 1=기존 Playing과 동일 blur·딤.
class TutorialRoleplayBackdrop extends StatelessWidget {
  static const assetPath = 'assets/images/tutorial/tutorial_rp_bg.png';

  /// 0~1. Playing 배경 blur/딤 강도에 맞춤.
  final double blurAmount;

  const TutorialRoleplayBackdrop({super.key, this.blurAmount = 0});

  @override
  Widget build(BuildContext context) {
    final t = blurAmount.clamp(0.0, 1.0);
    final sigma = kRoleplayOverviewBackdropBlurSigma * t;
    final dimOpacity = kRoleplayOverviewBackdropDim.a * t;

    Widget image = const DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
      ),
      child: SizedBox.expand(),
    );

    if (t > 0.001) {
      image = Transform.scale(
        scale: 1 + (kRoleplayOverviewBackdropImageScale - 1) * t,
        alignment: Alignment.center,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: image,
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF121212),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (dimOpacity > 0.001)
              ColoredBox(
                color: Color.fromRGBO(0, 0, 0, dimOpacity),
              ),
          ],
        ),
      ),
    );
  }
}
