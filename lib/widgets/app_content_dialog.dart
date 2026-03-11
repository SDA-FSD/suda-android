import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 재사용 가능한 콘텐츠 팝업.
///
/// 불투명·블러 배경 위에 카드 형태로 노출되며, 노출 중 하단 화면 터치 불가.
/// 디자인 규격: `.docs/CONTEXT.md` §8 공통 팝업 참조.
class AppContentDialog extends StatelessWidget {
  final Widget content;
  final bool showOkayButton;
  final String okayButtonLabel;
  final VoidCallback? onOkayPressed;
  final bool barrierDismissible;

  const AppContentDialog({
    super.key,
    required this.content,
    this.showOkayButton = false,
    this.okayButtonLabel = 'Okay',
    this.onOkayPressed,
    this.barrierDismissible = false,
  });

  /// [context]에 팝업을 띄우고, 사용자가 닫을 때까지 대기한다.
  ///
  /// [content]: 팝업 본문(여러 스타일 텍스트·버튼·클릭 가능 텍스트 등 위젯으로 구성).
  /// [showOkayButton]: true면 하단에 버튼 노출(탭 시 팝업 닫힘).
  /// [okayButtonLabel]: 버튼 문구. 기본값 'Okay'.
  static Future<void> show(
    BuildContext context, {
    required Widget content,
    bool showOkayButton = false,
    String okayButtonLabel = 'Okay',
    VoidCallback? onOkayPressed,
    bool barrierDismissible = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (ctx) => AppContentDialog(
        content: content,
        showOkayButton: showOkayButton,
        okayButtonLabel: okayButtonLabel,
        onOkayPressed: onOkayPressed,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    const overlayColor = Color(0x59000000);

    return PopScope(
      canPop: barrierDismissible,
      child: Stack(
        children: [
          // 1) 불투명·블러 배경 (GNB와 동일 수치)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: overlayColor),
              ),
            ),
          ),
          // 2) 팝업 카드 (바탕: 가로 80%, 세로 50% 고정). Okay 버튼은 (3) 하단 테두리를 덮는 형태.
          Center(
            child: SizedBox(
              width: screenWidth * 0.8,
              height: screenHeight * 0.5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 3) 실제 팝업 (테두리 박스)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).dialogBackgroundColor,
                      border: Border.all(
                        width: 10,
                        color: const Color(0xFF80D7CF),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 30,
                            top: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    Navigator.of(context).pop(),
                                child: SvgPicture.asset(
                                  'assets/images/icons/close.svg',
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30,
                              right: 30,
                              bottom: showOkayButton ? 12 : 30,
                            ),
                            child: content,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showOkayButton)
                    Positioned(
                      left: screenWidth * 0.2,
                      bottom: -17,
                      width: screenWidth * 0.4,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOkayPressed?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CABA8),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: Text(okayButtonLabel),
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
}
