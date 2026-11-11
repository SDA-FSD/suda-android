import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum DefaultPopupButtonType {
  /// Primary action (spec name: "default"): height 44, width shrink-wrap to label,
  /// stadium, uses `ElevatedButtonTheme`.
  primary,

  /// Primary inverse: white fill, black label. Unfriend confirm 등.
  primaryLight,

  /// Tertiary: uses `TextButtonTheme`.
  text,
}

class DefaultPopupButton {
  final DefaultPopupButtonType type;
  final String label;
  final VoidCallback onPressed;

  const DefaultPopupButton({
    required this.type,
    required this.label,
    required this.onPressed,
  });
}

/// 표준 팝업 프레임(배경/카드/닫기) + 선택적 top/title/body/buttons 슬롯.
///
/// - `bodyWidget` 내부 레이아웃은 호출부 자율.
/// - `DefaultPopup`은 **topWidget ↔ title ↔ body ↔ buttons** 사이에만 세로 20 간격을 보장한다.
/// - 버튼 탭 시: **항상 팝업을 닫은 뒤** `onPressed`를 호출한다.
class DefaultPopup extends StatelessWidget {
  static const double cardBorderRadius = 16;
  static const double sheetGlassBorderRadius = 24;

  final Widget? topWidget;
  final String? titleText;
  final Widget? bodyWidget;
  final List<DefaultPopupButton> buttons;
  final bool barrierDismissible;

  /// When true, primary buttons stretch to the card content width.
  /// Default remains shrink-wrap to label.
  final bool expandPrimaryButtons;

  /// 기본 `0.8`. 에너지 충전 시트처럼 전폭이면 `1.0`.
  final double maxWidthFactor;

  /// true면 하단 에너지 시트와 동일한 glass: `#FFF` 2% + blur 40.
  final bool sheetGlassSurface;

  /// 버튼끼리 세로 간격. 기본 20.
  final double buttonSpacing;

  const DefaultPopup({
    super.key,
    this.topWidget,
    this.titleText,
    this.bodyWidget,
    this.buttons = const [],
    this.barrierDismissible = false,
    this.expandPrimaryButtons = false,
    this.maxWidthFactor = 0.8,
    this.sheetGlassSurface = false,
    this.buttonSpacing = 20,
  });

  static Future<void> show(
    BuildContext context, {
    Widget? topWidget,
    String? titleText,
    Widget? bodyWidget,
    List<DefaultPopupButton> buttons = const [],
    bool barrierDismissible = false,
    bool expandPrimaryButtons = false,
    double maxWidthFactor = 0.8,
    bool sheetGlassSurface = false,
    double buttonSpacing = 20,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (ctx) => DefaultPopup(
        topWidget: topWidget,
        titleText: titleText,
        bodyWidget: bodyWidget,
        buttons: buttons,
        barrierDismissible: barrierDismissible,
        expandPrimaryButtons: expandPrimaryButtons,
        maxWidthFactor: maxWidthFactor,
        sheetGlassSurface: sheetGlassSurface,
        buttonSpacing: buttonSpacing,
      ),
    );
  }

  void _popThenCallback(BuildContext dialogContext, VoidCallback callback) {
    // Close first (as spec), then run callback on the next frame to avoid
    // using a deactivated dialog context subtree.
    Navigator.of(dialogContext).pop();
    final cb = callback;
    SchedulerBinding.instance.addPostFrameCallback((_) => cb());
  }

  List<Widget> _buildMainContentSlots(
    BuildContext context, {
    required bool hasTop,
    required Widget? top,
    required bool hasTitle,
    required String title,
    required bool hasBody,
    required Widget? body,
    required bool hasButtons,
  }) {
    final slots = <Widget>[];

    void addSpacingIfNeeded() {
      if (slots.isEmpty) return;
      slots.add(const SizedBox(height: 20));
    }

    if (hasTop) {
      slots.add(top!);
    }
    if (hasTitle) {
      addSpacingIfNeeded();
      slots.add(
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
      );
    }
    if (hasBody) {
      addSpacingIfNeeded();
      slots.add(body!);
    }
    if (hasButtons) {
      addSpacingIfNeeded();
      slots.addAll(_buildButtons(context));
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;

    final trimmedTitle = titleText?.trim();
    final title = trimmedTitle ?? '';
    final hasTitle = title.isNotEmpty;

    final top = topWidget;
    final hasTop = top != null;

    final body = bodyWidget;
    final hasBody = body != null;
    final hasButtons = buttons.isNotEmpty;

    const overlayColor = Color(0x66000000); // black 40%

    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._buildMainContentSlots(
                        context,
                        hasTop: hasTop,
                        top: top,
                        hasTitle: hasTitle,
                        title: title,
                        hasBody: hasBody,
                        body: body,
                        hasButtons: hasButtons,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    return PopScope(
      canPop: barrierDismissible,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible
                  ? () => Navigator.of(context).pop()
                  : null,
              child: const ColoredBox(color: overlayColor),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * maxWidthFactor.clamp(0.5, 1.0),
                maxHeight: screenHeight * 0.8,
              ),
              child: sheetGlassSurface
                  ? _SheetGlassCard(
                      radius: sheetGlassBorderRadius,
                      child: cardContent,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(cardBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(cardBorderRadius),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                cardBorderRadius,
                              ),
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
                            child: cardContent,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final out = <Widget>[];
    final elevatedBase = Theme.of(context).elevatedButtonTheme.style;
    final textBase = Theme.of(context).textButtonTheme.style;
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) out.add(SizedBox(height: buttonSpacing));
      final b = buttons[i];
      final expandPrimary =
          expandPrimaryButtons &&
          (b.type == DefaultPopupButtonType.primary ||
              b.type == DefaultPopupButtonType.primaryLight);
      out.add(
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: 44,
            width: expandPrimary ? double.infinity : null,
            child: switch (b.type) {
              DefaultPopupButtonType.primary => ElevatedButton(
                onPressed: () => _popThenCallback(context, b.onPressed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ).merge(elevatedBase),
                child: Text(b.label),
              ),
              DefaultPopupButtonType.primaryLight => ElevatedButton(
                onPressed: () => _popThenCallback(context, b.onPressed),
                style: (elevatedBase ?? const ButtonStyle()).merge(
                  ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                child: Text(b.label),
              ),
              DefaultPopupButtonType.text => TextButton(
                onPressed: () => _popThenCallback(context, b.onPressed),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ).merge(textBase),
                child: Text(b.label),
              ),
            },
          ),
        ),
      );
    }
    return out;
  }
}

/// 에너지 부족 하단 시트와 동일: `#FFF` 2% + blur 40 + 유리 각도형 1px stroke.
class _SheetGlassCard extends StatelessWidget {
  final double radius;
  final Widget child;

  const _SheetGlassCard({required this.radius, required this.child});

  static const _borderGradient = SweepGradient(
    startAngle: -1.5707963267948966,
    colors: [
      Color(0x28FFFFFF),
      Color(0x4FFFFFFF),
      Color(0x28FFFFFF),
      Color(0x4FFFFFFF),
      Color(0x28FFFFFF),
      Color(0x28FFFFFF),
    ],
    stops: [0.0, 0.13, 0.37, 0.62, 0.87, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftGlassBorderPainter(
                  gradient: _borderGradient,
                  borderRadius: borderRadius,
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlassBorderPainter extends CustomPainter {
  final Gradient gradient;
  final BorderRadius borderRadius;
  final double strokeWidth;

  const _SoftGlassBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SoftGlassBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
