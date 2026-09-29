import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Progress 탭 레벨업 리워드 트랙. 시작점 마커 없음. 탭은 선물만.
class LevelUpProgressTrack extends StatelessWidget {
  static const double barHeight = 5;
  static const double tickSize = 20;
  static const double checkSize = 24;
  static const double giftSize = 40;

  /// 끝 체크 오른쪽 끝과 선물 왼쪽 사이 간격.
  static const double giftGap = 8;
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
          final barWidth = (width - giftSize - checkSize / 2 - giftGap).clamp(
            0.0,
            width,
          );
          final fill = _fill.clamp(0.0, 1.0);
          final barCenterY = yBar + barHeight / 2;
          Offset tickCenter(int index) {
            final t = (index + 1) / 3.0;
            return Offset(barWidth * t, barCenterY);
          }

          final giftCenterX = width - giftSize / 2;
          final glowRadius = (giftCenterX + 20) * 0.075;
          final showGlow = claimable && !claiming;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (showGlow)
                Positioned(
                  left: giftCenterX - glowRadius,
                  top: barCenterY - glowRadius,
                  width: glowRadius * 2,
                  height: glowRadius * 2,
                  child: const _TrackGlow(),
                ),
              Positioned(
                left: 0,
                top: yBar,
                width: barWidth,
                height: barHeight,
                child: _DashedStadiumBar(fill: fill),
              ),
              Positioned(
                left: width - giftSize,
                top: barCenterY - giftSize / 2,
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
                  left:
                      tickCenter(i).dx -
                      _markerSize(currentLevel >= labels[i]) / 2,
                  top:
                      tickCenter(i).dy -
                      _markerSize(currentLevel >= labels[i]) / 2,
                  child: _LevelTick(checked: currentLevel >= labels[i]),
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

  static double _markerSize(bool checked) => checked ? checkSize : tickSize;
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
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _RewardBoxGift oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
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
          : Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _wobble,
                  builder: (context, child) {
                    final angle =
                        math.sin(_wobble.value * 2 * math.pi) * _amplitude;
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: Image.asset(
                    'assets/images/achievement/reward_box.png',
                    width: LevelUpProgressTrack.giftSize,
                    height: LevelUpProgressTrack.giftSize,
                    fit: BoxFit.contain,
                  ),
                ),
                if (_shake)
                  const Positioned(right: -2, top: -3, child: _ClaimableDot()),
              ],
            ),
    );
  }
}

/// 수령 가능일 때 바 뒤에 깔리는 원형 후광. 선물 40px 슬롯 밖에 둔다.
class _TrackGlow extends StatefulWidget {
  const _TrackGlow();

  @override
  State<_TrackGlow> createState() => _TrackGlowState();
}

class _TrackGlowState extends State<_TrackGlow>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1400);

  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: _period)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_glow.value);
          return CustomPaint(
            painter: _TrackGlowPainter(pulse: 0.86 + 0.14 * t),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _TrackGlowPainter extends CustomPainter {
  final double pulse;

  const _TrackGlowPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 * pulse;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xE6FFF44F), Color(0xB3FFF44F), Color(0x00FFF44F)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _TrackGlowPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
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

class _ClaimableDot extends StatelessWidget {
  const _ClaimableDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFFFF5252),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x66FF5252), blurRadius: 3)],
      ),
    );
  }
}

class _LevelTick extends StatelessWidget {
  final bool checked;

  const _LevelTick({required this.checked});

  @override
  Widget build(BuildContext context) {
    if (checked) {
      return SvgPicture.asset(
        'assets/images/icons/check_mint.svg',
        width: LevelUpProgressTrack.checkSize,
        height: LevelUpProgressTrack.checkSize,
      );
    }
    return SizedBox(
      width: LevelUpProgressTrack.tickSize,
      height: LevelUpProgressTrack.tickSize,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0x5CFFFFFF)),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x2EFFFFFF), Color(0x1AFFFFFF)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
