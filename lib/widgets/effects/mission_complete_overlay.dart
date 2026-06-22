import 'package:flutter/material.dart';

/// 미션 완료 shine — root overlay, 미션 아이콘 중심에 정렬.
class MissionCompleteOverlay extends StatefulWidget {
  static const String effectAsset =
      'assets/images/mission_complete_effect.png';

  /// PNG 전체 폭 대비 중앙 핑크 원(checkmark) 직경 비율(1597px 에셋 기준 ≈0.19).
  /// [effectWidthFactor]는 **에셋 전체** 크기 기준이며, 눈에 보이는 원은 그보다 훨씬 작다.
  static const double effectWidthFactor = 2 / 3;

  /// 아이콘 anchor 중심 대비 shine 정렬 미세 보정(논리 px).
  static const Offset effectCenterOffset = Offset(2, 2);

  final GlobalKey anchorKey;
  final VoidCallback onCompleted;

  const MissionCompleteOverlay({
    super.key,
    required this.anchorKey,
    required this.onCompleted,
  });

  @override
  State<MissionCompleteOverlay> createState() => _MissionCompleteOverlayState();
}

class _MissionCompleteOverlayState extends State<MissionCompleteOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  Offset? _anchorCenter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward().then((_) {
        if (mounted) widget.onCompleted();
      });
    _scheduleAnchorResolve();
  }

  void _scheduleAnchorResolve() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final center = _resolveAnchorCenter();
      if (center != null && center != _anchorCenter) {
        setState(() => _anchorCenter = center);
      } else if (_anchorCenter == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final retryCenter = _resolveAnchorCenter();
          if (retryCenter != null && retryCenter != _anchorCenter) {
            setState(() => _anchorCenter = retryCenter);
          }
        });
      }
    });
  }

  Offset? _resolveAnchorCenter() {
    final context = widget.anchorKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft + renderObject.size.center(Offset.zero);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityForProgress(double value) {
    if (value <= 1 / 3) {
      return (value * 3).clamp(0.0, 1.0);
    }
    return ((1 - value) * 1.5).clamp(0.0, 1.0);
  }

  double _rotationForProgress(double value) {
    final rotationDirection = (value * 8).round().isEven ? 1.0 : -1.0;
    return 0.08 * rotationDirection;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final effectSize = screenSize.width * MissionCompleteOverlay.effectWidthFactor;
    final center = _anchorCenter;
    final effectCenter = center != null ? center + MissionCompleteOverlay.effectCenterOffset : null;

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (effectCenter != null)
                Positioned(
                  left: effectCenter.dx - effectSize / 2,
                  top: effectCenter.dy - effectSize / 2,
                  width: effectSize,
                  height: effectSize,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final value = _controller.value;
                      return Opacity(
                        opacity: _opacityForProgress(value),
                        child: Transform.rotate(
                          angle: _rotationForProgress(value),
                          alignment: Alignment.center,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      MissionCompleteOverlay.effectAsset,
                      width: effectSize,
                      height: effectSize,
                      fit: BoxFit.contain,
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
