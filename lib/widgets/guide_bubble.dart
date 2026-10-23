import 'package:flutter/material.dart';

enum GuideBubbleTail { top, bottom, left, right }

/// 짧은 안내 말풍선. 위치는 부모가 정하고, 화면 가장자리까지 둘 수 있다.
class GuideBubble extends StatefulWidget {
  static const Color fill = Color(0xFF0CABA8);
  static const double radius = 12;
  static const double tailLength = 8;
  static const double tailWidth = 14;

  final String text;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  /// 있으면 [text] 대신 이 스팬을 그린다. 기본 스타일은 [textStyle].
  final List<InlineSpan>? spans;
  final GuideBubbleTail tail;

  /// 말풍선 모서리 반지름. 기본은 [radius].
  final double cornerRadius;

  /// true면 꼭지를 꼬리 변의 가운데에 둔다([tailOffsetFromEnd] 무시).
  final bool tailCentered;

  /// 꼭지 중심이 꼬리 변의 끝에서 떨어진 거리.
  /// 위·아래 꼭지는 오른쪽 끝 기준, 좌·우 꼭지는 아래 끝 기준.
  final double tailOffsetFromEnd;
  final bool wobble;
  final VoidCallback? onTap;

  /// 말풍선 전체 최대 폭. 기본은 [defaultMaxWidth].
  final double maxWidth;

  /// true면 채우기 아래에 그림자를 그린다. X 0, Y 4, blur 4, spread 0, #000000 25%.
  final bool dropShadow;

  static const double defaultMaxWidth = 260;

  const GuideBubble({
    super.key,
    required this.text,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.spans,
    this.tail = GuideBubbleTail.top,
    this.cornerRadius = radius,
    this.tailCentered = false,
    this.tailOffsetFromEnd = 20,
    this.wobble = false,
    this.onTap,
    this.maxWidth = defaultMaxWidth,
    this.dropShadow = false,
  });

  @override
  State<GuideBubble> createState() => _GuideBubbleState();
}

class _GuideBubbleState extends State<GuideBubble>
    with SingleTickerProviderStateMixin {
  AnimationController? _wobble;

  @override
  void initState() {
    super.initState();
    _syncWobble();
  }

  @override
  void didUpdateWidget(covariant GuideBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wobble != widget.wobble) _syncWobble();
  }

  void _syncWobble() {
    if (widget.wobble) {
      _wobble ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);
    } else {
      _wobble?.dispose();
      _wobble = null;
    }
  }

  @override
  void dispose() {
    _wobble?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          decoration: TextDecoration.none,
        );
    final tail = GuideBubble.tailLength;
    final padding = switch (widget.tail) {
      GuideBubbleTail.top => EdgeInsets.fromLTRB(14, 10 + tail, 14, 10),
      GuideBubbleTail.bottom => EdgeInsets.fromLTRB(14, 10, 14, 10 + tail),
      GuideBubbleTail.left => EdgeInsets.fromLTRB(14 + tail, 10, 14, 10),
      GuideBubbleTail.right => EdgeInsets.fromLTRB(14, 10, 14 + tail, 10),
    };
    Widget bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: CustomPaint(
        painter: _GuideBubblePainter(
          tail: widget.tail,
          tailOffsetFromEnd: widget.tailOffsetFromEnd,
          cornerRadius: widget.cornerRadius,
          tailCentered: widget.tailCentered,
          dropShadow: widget.dropShadow,
        ),
        child: Padding(
          padding: padding,
          child: widget.spans == null
              ? Text(
                  widget.text,
                  style: style,
                  textAlign: widget.textAlign,
                )
              : Text.rich(
                  TextSpan(style: style, children: widget.spans),
                  textAlign: widget.textAlign,
                ),
        ),
      ),
    );
    if (_wobble != null) {
      bubble = AnimatedBuilder(
        animation: _wobble!,
        builder: (context, child) {
          final dy = (_wobble!.value - 0.5) * 8;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: bubble,
      );
    }
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: bubble,
    );
  }
}

class _GuideBubblePainter extends CustomPainter {
  final GuideBubbleTail tail;
  final double tailOffsetFromEnd;
  final double cornerRadius;
  final bool tailCentered;
  final bool dropShadow;

  const _GuideBubblePainter({
    required this.tail,
    required this.tailOffsetFromEnd,
    required this.cornerRadius,
    required this.tailCentered,
    required this.dropShadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = cornerRadius;
    const tailLen = GuideBubble.tailLength;
    const tailW = GuideBubble.tailWidth;
    final body = switch (tail) {
      GuideBubbleTail.top => Rect.fromLTWH(
        0,
        tailLen,
        size.width,
        size.height - tailLen,
      ),
      GuideBubbleTail.bottom => Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height - tailLen,
      ),
      GuideBubbleTail.left => Rect.fromLTWH(
        tailLen,
        0,
        size.width - tailLen,
        size.height,
      ),
      GuideBubbleTail.right => Rect.fromLTWH(
        0,
        0,
        size.width - tailLen,
        size.height,
      ),
    };
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));
    final center = _tailCenter(size, body);
    final half = tailW / 2;
    switch (tail) {
      case GuideBubbleTail.top:
        path
          ..moveTo(center - half, body.top)
          ..lineTo(center, 0)
          ..lineTo(center + half, body.top);
      case GuideBubbleTail.bottom:
        path
          ..moveTo(center - half, body.bottom)
          ..lineTo(center, size.height)
          ..lineTo(center + half, body.bottom);
      case GuideBubbleTail.left:
        path
          ..moveTo(body.left, center - half)
          ..lineTo(0, center)
          ..lineTo(body.left, center + half);
      case GuideBubbleTail.right:
        path
          ..moveTo(body.right, center - half)
          ..lineTo(size.width, center)
          ..lineTo(body.right, center + half);
    }
    path.close();
    if (dropShadow) {
      canvas.drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            4 * 0.57735 + 0.5,
          ),
      );
    }
    canvas.drawPath(path, Paint()..color = GuideBubble.fill);
  }

  double _tailCenter(Size size, Rect body) {
    final along = switch (tail) {
      GuideBubbleTail.top || GuideBubbleTail.bottom => size.width,
      GuideBubbleTail.left || GuideBubbleTail.right => size.height,
    };
    if (tailCentered) return along / 2;
    final raw = along - tailOffsetFromEnd;
    final min = cornerRadius + GuideBubble.tailWidth / 2;
    final max = along - min;
    if (max <= min) return along / 2;
    return raw.clamp(min, max);
  }

  @override
  bool shouldRepaint(covariant _GuideBubblePainter oldDelegate) {
    return tail != oldDelegate.tail ||
        tailOffsetFromEnd != oldDelegate.tailOffsetFromEnd ||
        cornerRadius != oldDelegate.cornerRadius ||
        tailCentered != oldDelegate.tailCentered ||
        dropShadow != oldDelegate.dropShadow;
  }
}
