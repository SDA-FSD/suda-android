import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/iap_purchase_service.dart';
import 'default_toast.dart';

/// IAP blocking overlay. 조회·verify만 전면 스피너.
/// iOS StoreKit 시트·processing은 스피너 없음. AOS는 Play 시트 뒤에도 유지.
class IapBlockingOverlayHost extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const IapBlockingOverlayHost({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<IapBlockingOverlayHost> createState() => _IapBlockingOverlayHostState();
}

class _IapBlockingOverlayHostState extends State<IapBlockingOverlayHost> {
  final IapPurchaseService _iap = IapPurchaseService.instance;
  int _lastNoticeSeq = 0;

  @override
  void initState() {
    super.initState();
    _iap.uiPhase.addListener(_onUi);
    _iap.userNotice.addListener(_onNotice);
  }

  @override
  void dispose() {
    _iap.uiPhase.removeListener(_onUi);
    _iap.userNotice.removeListener(_onNotice);
    super.dispose();
  }

  void _onUi() {
    if (mounted) setState(() {});
  }

  void _onNotice() {
    final notice = _iap.userNotice.value;
    if (notice == null || notice.seq == _lastNoticeSeq) return;
    _lastNoticeSeq = notice.seq;

    if (notice.kind == IapPurchaseUserNoticeKind.processing) {
      _showToast((l10n) => l10n.iapPurchaseProcessing);
      return;
    }
    if (notice.kind == IapPurchaseUserNoticeKind.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_iap.isSuccessUiPresented(notice.seq)) return;
        _showToast((l10n) => l10n.iapPurchaseCompleted);
      });
    }
  }

  void _showToast(String Function(AppLocalizations l10n) messageOf) {
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;
    final l10n = AppLocalizations.of(navContext);
    if (l10n == null) return;
    DefaultToast.show(
      navContext,
      messageOf(l10n),
      overlay: widget.navigatorKey.currentState?.overlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final show = _iap.showBlockingOverlay;
    return Stack(
      children: [
        widget.child,
        if (show) ...[
          const ModalBarrier(
            dismissible: false,
            color: Color(0x99000000),
          ),
          const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
