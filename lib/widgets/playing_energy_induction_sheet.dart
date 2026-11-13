import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/user_models.dart';
import '../utils/energy_icon.dart';

enum PlayingEnergyInductionResult { seeOptions, closed }

const _energyZeroColor = Color(0xFFE60000);
const _ctaPurple = Color(0xFF8A38F5);

/// Playing 에너지 0 첫 차단 시 대화 유도 바텀시트.
/// 시트 chrome은 Out of Energy 충전 시트와 동일(blur + black 30% + 흰 Sweep 보더).
Future<PlayingEnergyInductionResult?> showPlayingEnergyInductionSheet(
  BuildContext context, {
  required UserEnergyDto? energy,
}) {
  return showModalBottomSheet<PlayingEnergyInductionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    builder: (ctx) => _PlayingEnergyInductionSheet(energy: energy),
  );
}

class _PlayingEnergyInductionSheet extends StatelessWidget {
  final UserEnergyDto? energy;

  const _PlayingEnergyInductionSheet({required this.energy});

  static const _sheetRadius = BorderRadius.vertical(top: Radius.circular(24));
  // 충전 시트와 동일 — soft floor·하단 seam
  static const _sheetBorderGradient = SweepGradient(
    startAngle: 1.5707963267948966,
    colors: [
      Color(0x29FFFFFF),
      Color(0x4FFFFFFF),
      Color(0x1AFFFFFF),
      Color(0x4FFFFFFF),
      Color(0x1AFFFFFF),
      Color(0x29FFFFFF),
    ],
    stops: [0.0, 0.12, 0.37, 0.62, 0.87, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;
    final theme = Theme.of(context).textTheme;
    final nowUtc = DateTime.now().toUtc();
    final count = energy?.energyCount ?? 0;
    final iconPath = energy == null
        ? 'assets/images/icons/energy.png'
        : energyIconAssetPath(energy!, nowUtc);

    return Padding(
      padding: EdgeInsets.only(top: media.size.height * 0.18),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: _sheetRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.30),
                  ),
                ),
              ),
              Padding(
                // SafeArea와 이중으로 bottom을 넣지 않음 — 닫기가 하단에 가깝게.
                padding: EdgeInsets.fromLTRB(24, 20, 24, 8 + bottom),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              l10n.playingEnergyInductionEnergyLabel,
                              style: theme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    height: 1,
                                  ) ??
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              iconPath,
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$count',
                              style: theme.bodySmall?.copyWith(
                                    color: count == 0
                                        ? _energyZeroColor
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ) ??
                                  TextStyle(
                                    color: count == 0
                                        ? _energyZeroColor
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.playingEnergyInductionTitle,
                        textAlign: TextAlign.center,
                        style: theme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Image.asset(
                          'assets/images/icons/roleplay_energy_sad.png',
                          width: 88,
                          height: 88,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.playingEnergyInductionBody,
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.35,
                            ) ??
                            TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 18,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(
                            PlayingEnergyInductionResult.seeOptions,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ctaPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.playingEnergyInductionCta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(
                          PlayingEnergyInductionResult.closed,
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.outOfEnergyClose,
                          style: theme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SweepBorderPainter(
                      gradient: _sheetBorderGradient,
                      borderRadius: _sheetRadius,
                      strokeWidth: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SweepBorderPainter extends CustomPainter {
  final Gradient gradient;
  final BorderRadius borderRadius;
  final double strokeWidth;

  const _SweepBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rrect = borderRadius.toRRect(Offset.zero & size).deflate(half);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(rrect.outerRect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SweepBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
