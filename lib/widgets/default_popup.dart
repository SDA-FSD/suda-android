import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum DefaultPopupButtonType {
  /// Primary action (spec name: "default"): full-width, height 44, stadium,
  /// uses `ElevatedButtonTheme`.
  primary,

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

/// 표준 팝업 프레임(배경/카드/닫기) + 선택적 title/body/buttons 슬롯.
///
/// - `bodyWidget` 내부 레이아웃은 호출부 자율.
/// - `DefaultPopup`은 **title ↔ body ↔ buttons** 사이에만 세로 20 간격을 보장한다.
/// - 버튼 탭 시: **항상 팝업을 닫은 뒤** `onPressed`를 호출한다.
class DefaultPopup extends StatelessWidget {
  final String? titleText;
  final Widget? bodyWidget;
  final List<DefaultPopupButton> buttons;
  final bool barrierDismissible;

  const DefaultPopup({
    super.key,
    this.titleText,
    this.bodyWidget,
    this.buttons = const [],
    this.barrierDismissible = false,
  });

  static Future<void> show(
    BuildContext context, {
    String? titleText,
    Widget? bodyWidget,
    List<DefaultPopupButton> buttons = const [],
    bool barrierDismissible = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (ctx) => DefaultPopup(
        titleText: titleText,
        bodyWidget: bodyWidget,
        buttons: buttons,
        barrierDismissible: barrierDismissible,
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;

    const overlayColor = Color(0x66000000); // black 40%

    final trimmedTitle = titleText?.trim();
    final title = trimmedTitle;
    final hasTitle = title != null && title.isNotEmpty;

    final body = bodyWidget;
    final hasBody = body != null;
    final hasButtons = buttons.isNotEmpty;

    return PopScope(
      canPop: barrierDismissible,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
              child: const ColoredBox(color: overlayColor),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.8,
                maxHeight: screenHeight * 0.8,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 10,
                        color: const Color(0xFF80D7CF),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: ColoredBox(
                          color: const Color(0x991E1E1E),
                          child: Column(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (hasTitle) ...[
                                              Text(
                                                title,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ],
                                            if (hasTitle && (hasBody || hasButtons))
                                              const SizedBox(height: 20),
                                            if (hasBody) body,
                                            if ((hasTitle || hasBody) && hasButtons)
                                              const SizedBox(height: 20),
                                            if (hasButtons)
                                              ..._buildButtons(context),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
      if (i > 0) out.add(const SizedBox(height: 20));
      final b = buttons[i];
      out.add(
        SizedBox(
          height: 44,
          width: double.infinity,
          child: switch (b.type) {
            DefaultPopupButtonType.primary => ElevatedButton(
                onPressed: () => _popThenCallback(context, b.onPressed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CABA8),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ).merge(elevatedBase),
                child: Text(b.label),
              ),
            DefaultPopupButtonType.text => TextButton(
                onPressed: () => _popThenCallback(context, b.onPressed),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ).merge(textBase),
                child: Text(b.label),
              ),
          },
        ),
      );
    }
    return out;
  }
}
