import 'package:flutter/material.dart';

import '../../widgets/gnb_bar.dart';

/// Claimable 전면 시트 자리만. RankScreenDto에 claimable 없음 — 지금은 절대 show 하지 말 것.
///
/// GNB를 덮으면 안 됨: max height = 화면에서 GNB(contentHeight + SafeArea bottom)를 뺀 영역.
/// AppScaffold GNB 오버레이는 시트 위가 아니라 그대로 보임.
class RankClaimableSheet extends StatelessWidget {
  const RankClaimableSheet({super.key, required this.child});

  final Widget child;

  /// 시트 max height (GNB 영역 제외).
  static double maxHeightOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return size.height - padding.bottom - GnbBar.contentHeight;
  }

  /// 후속 API 연동 시 사용할 show 헬퍼. 현재는 호출하지 않는다.
  static Future<T?> showPlaceholderNeverCall<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    assert(
      false,
      'RankClaimableSheet must not be shown until claimable API exists',
    );
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (ctx) {
        final maxH = maxHeightOf(ctx);
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Material(
              color: const Color(0xFF1A1A1A),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: builder(ctx),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => child;
}
