import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Progress 탭 레벨업 리워드 트랙. 시작점 마커 없음. 탭은 선물만.
class LevelUpProgressTrack extends StatelessWidget {
  static const double barHeight = 5;
  static const double tickSize = 20;
  static const double giftSize = 40;
  static const double labelBelow = 25;
  static const Color mint = Color(0xFF80D7CF);
  static const Color labelColor = Color(0x61FEFEFE);

  final int currentLevel;
  final int progressPercentage;
  final int rewardLevel;
  final bool claiming;
  final bool claimable;
  final VoidCallback? onGiftTap;

  const LevelUpProgressTrack({
    super.key,
    required this.currentLevel,
    required this.progressPercentage,
    required this.rewardLevel,
    this.claiming = false,
    this.claimable = false,
    this.onGiftTap,
  });

  int get _rewardLevel => rewardLevel < 3 ? 3 : rewardLevel;

  double get _fill {
    final r = _rewardLevel;
    final s = r - 3;
    final l = currentLevel;
    final p = (progressPercentage.clamp(0, 100)) / 100.0;
    if (l >= r) return 1.0;
    if (l <= s) return p / 3.0;
    return ((l - s) + p) / 3.0;
  }

  @override
  Widget build(BuildContext context) {
    final r = _rewardLevel;
    final labels = [r - 2, r - 1, r];
    final theme = Theme.of(context).textTheme;
    const labelReserve = 18.0;
    const yBar = giftSize / 2 - barHeight / 2;
    return SizedBox(
      height: yBar + barHeight + labelBelow + labelReserve,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final barWidth = (width - giftSize / 2).clamp(0.0, width);
          final fill = _fill.clamp(0.0, 1.0);
          Offset tickCenter(int index) {
            final t = (index + 1) / 3.0;
            return Offset(barWidth * t, yBar + barHeight / 2);
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: yBar,
                width: barWidth,
                height: barHeight,
                child: _DashedStadiumBar(fill: fill),
              ),
              for (var i = 0; i < 2; i++)
                Positioned(
                  left: tickCenter(i).dx - tickSize / 2,
                  top: tickCenter(i).dy - tickSize / 2,
                  child: _GlassyTick(checked: currentLevel >= labels[i]),
                ),
              Positioned(
                left: tickCenter(2).dx - giftSize / 2,
                top: tickCenter(2).dy - giftSize / 2,
                width: giftSize,
                height: giftSize,
                child: _RewardBoxGift(
                  claimable: claimable,
                  claiming: claiming,
                  onTap: onGiftTap,
                ),
              ),
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: tickCenter(i).dx - 28,
                  top: yBar + barHeight + labelBelow - 12,
                  width: 56,
                  child: Text(
                    'Lv.${labels[i]}',
                    textAlign: TextAlign.center,
                    style: theme.bodySmall?.copyWith(color: labelColor),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RewardBoxGift extends StatefulWidget {
  final bool claimable;
  final bool claiming;
  final VoidCallback? onTap;

  const _RewardBoxGift({
    required this.claimable,
    required this.claiming,
    this.onTap,
  });

  @override
  State<_RewardBoxGift> createState() => _RewardBoxGiftState();
}

class _RewardBoxGiftState extends State<_RewardBoxGift>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1200);
  static const _amplitude = 0.12;

  late final AnimationController _wobble;

  bool get _shake => widget.claimable && !widget.claiming;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(vsync: this, duration: _period);
    _syncWobble();
  }

  @override
  void didUpdateWidget(covariant _RewardBoxGift oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWobble();
  }

  void _syncWobble() {
    if (_shake) {
      if (!_wobble.isAnimating) {
        _wobble.repeat();
      }
    } else if (_wobble.isAnimating || _wobble.value != 0) {
      _wobble
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.claiming ? null : widget.onTap,
      child: widget.claiming
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LevelUpProgressTrack.mint,
                ),
              ),
            )
          : AnimatedBuilder(
              animation: _wobble,
              builder: (context, child) {
                final angle = math.sin(_wobble.value * 2 * math.pi) * _amplitude;
                return Transform.rotate(angle: angle, child: child);
              },
              child: Image.asset(
                'assets/images/achievement/reward_box.png',
                width: LevelUpProgressTrack.giftSize,
                height: LevelUpProgressTrack.giftSize,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

class _DashedStadiumBar extends StatelessWidget {
  final double fill;

  const _DashedStadiumBar({required this.fill});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LevelUpProgressTrack.barHeight,
      child: CustomPaint(painter: _StadiumTrackPainter(fill: fill)),
    );
  }
}

class _StadiumTrackPainter extends CustomPainter {
  final double fill;

  const _StadiumTrackPainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final stadium = Path()..addRRect(rrect);
    final fillW = (size.width * fill.clamp(0.0, 1.0));

    if (fillW < size.width) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(fillW, 0, size.width - fillW, size.height));
      final dashPaint = Paint()
        ..color = LevelUpProgressTrack.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      const dash = 4.0;
      const gap = 3.0;
      for (final metric in stadium.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final next = (distance + dash).clamp(0.0, metric.length);
          canvas.drawPath(metric.extractPath(distance, next), dashPaint);
          distance = next + gap;
        }
      }
      canvas.restore();
    }

    if (fillW > 0) {
      canvas.save();
      canvas.clipPath(stadium);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillW, size.height),
        Paint()..color = LevelUpProgressTrack.mint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumTrackPainter oldDelegate) =>
      oldDelegate.fill != fill;
}

class _GlassyTick extends StatelessWidget {
  final bool checked;

  const _GlassyTick({required this.checked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LevelUpProgressTrack.tickSize,
      height: LevelUpProgressTrack.tickSize,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.36),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: checked
                ? Center(
                    child: Image.asset(
                      'assets/images/icons/check_raw.png',
                      width: 12,
                      height: 12,
                      fit: BoxFit.contain,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
