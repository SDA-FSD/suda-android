import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/user_profile_avatar.dart';
import 'tutorial_roleplay_backdrop.dart';

/// Username→Intro 프로토타입 `.go`와 동일한 스테이지 (0=Username쪽, 1=Intro 최종).
class TutorialIntroStage extends StatelessWidget {
  static const accent = Color(0xFF0CABA8);
  static const designW = 880.0;
  static const designH = 1818.0;
  static const easeIos = Cubic(0.32, 0.72, 0, 1);
  static const easeOut = Cubic(0.22, 1, 0.36, 1);
  static const totalMs = 1700.0;
  static const duration = Duration(milliseconds: 1700);

  /// 0~1 progress.
  final double progress;
  final String? imgPath;
  final String displayName;

  /// null이면 Start 버튼은 보이는 장식만(탭 없음).
  final VoidCallback? onStartTutorial;
  final bool startLoading;

  const TutorialIntroStage({
    super.key,
    required this.progress,
    required this.displayName,
    this.imgPath,
    this.onStartTutorial,
    this.startLoading = false,
  });

  static double local(double t, double startMs, double durMs) {
    final start = startMs / totalMs;
    final end = (startMs + durMs) / totalMs;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// 프로토타입 `.go #rest` / `#bg`
  static double restOpacity(double t) {
    // opacity 0 over 320ms from 40ms
    return 1.0 - local(t, 40, 320);
  }

  /// 프로토타입 `.go #bg`: opacity 900ms ease-out, delay 80ms.
  static double bgOpacity(double t) {
    return Curves.easeOut.transform(local(t, 80, 900));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final u = size.width / designW;
    final t = progress.clamp(0.0, 1.0);

    // 가로 중앙. 아바타 top/크기·문구·CTA 모두 화면 높이 비율 → 기기마다 동일.
    // 최종: 아바타 top 24% · 아바타 높이 11.7% · 문구 gap 1% · CTA 74.5%.
    final avatarCurve = easeIos.transform(local(t, 0, 950));
    const endScale = 0.7746;
    final avScale = 1.0 + (endScale - 1.0) * avatarCurve;
    const avHeightEndFrac = 0.117;
    // 애니 중 scale은 end 기준 상대값 (최종 avScale=endScale일 때 11.7%)
    final avSize = size.height * avHeightEndFrac * (avScale / endScale);
    final avLeft = (size.width - avSize) / 2;
    const avTopStartFrac = 508 / designH;
    const avTopEndFrac = 0.24;
    final avTopFrac =
        avTopStartFrac + (avTopEndFrac - avTopStartFrac) * avatarCurve;
    final avTop = size.height * avTopFrac;
    final textTop = avTop + avSize + size.height * 0.01;

    final line1 = _fadeSlide(t, delayMs: 520, durMs: 800);
    final line2 = _fadeSlide(t, delayMs: 640, durMs: 800);
    final cta = _fadeSlide(t, delayMs: 1020, durMs: 800, isCta: true);

    final title = l10n.tutorialIntroTitle(displayName);
    final parts = title.split('\n');
    final firstLine = parts.isNotEmpty ? parts.first : title;
    final secondLine = parts.length > 1 ? parts.sublist(1).join('\n') : '';
    final titleStyle = theme.headlineLarge?.copyWith(color: Colors.white);

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: bgOpacity(t),
          child: const TutorialRoleplayBackdrop(blurAmount: 1),
        ),
        Positioned(
          left: avLeft,
          top: avTop,
          width: avSize,
          height: avSize,
          child: UserProfileAvatar(
            imgPath: imgPath,
            isPremium: false,
            size: avSize,
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: textTop,
          child: Column(
            children: [
              Opacity(
                opacity: line1.opacity,
                child: Transform.translate(
                  offset: Offset(0, line1.dy * u),
                  child: Text(
                    firstLine,
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
              ),
              if (secondLine.isNotEmpty)
                Opacity(
                  opacity: line2.opacity,
                  child: Transform.translate(
                    offset: Offset(0, line2.dy * u),
                    child: Text(
                      secondLine,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: size.height * (1354 / designH),
          child: Opacity(
            opacity: cta.opacity,
            child: Transform.translate(
              offset: Offset(0, cta.dy * u),
              child: Transform.scale(
                scale: cta.scale,
                child: Center(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (onStartTutorial == null || startLoading)
                          ? null
                          : onStartTutorial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: accent.withOpacity(0.6),
                        disabledForegroundColor: Colors.white.withOpacity(0.8),
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                      ),
                      child: startLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/icons/play_white.svg',
                                  width: 18,
                                  height: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.tutorialIntroStart),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static _FadeSlide _fadeSlide(
    double t, {
    required int delayMs,
    required int durMs,
    bool isCta = false,
  }) {
    final curved =
        easeOut.transform(local(t, delayMs.toDouble(), durMs.toDouble()));
    return _FadeSlide(
      opacity: curved,
      dy: 18 * (1 - curved),
      scale: isCta ? (0.96 + 0.04 * curved) : 1,
    );
  }
}

class _FadeSlide {
  final double opacity;
  final double dy;
  final double scale;
  const _FadeSlide({
    required this.opacity,
    required this.dy,
    this.scale = 1,
  });
}
