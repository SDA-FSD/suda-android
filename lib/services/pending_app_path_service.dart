import 'package:flutter/foundation.dart';

/// 푸시에서 소비할 appPath + (있으면) 알림함 앵커용 id.
class PendingPushNavigation {
  const PendingPushNavigation({
    required this.path,
    this.notificationId,
  });

  final String path;
  final int? notificationId;
}

/// 푸시 알림 클릭 시 이동할 appPath를 로그인/동의 완료 전까지 보관하는 서비스.
/// Main 진입 시 한 번 `takePending()`으로 소비한다.
/// [pendingNotifier] 변경 시 리스너가 setState를 호출해 이미 Main이 보이는 상태에서도 적용을 트리거할 수 있다.
class PendingAppPathService {
  PendingAppPathService._();

  static final PendingAppPathService instance = PendingAppPathService._();

  String? _path;
  int? _notificationId;

  /// 알림 클릭으로 path가 설정될 때 알려주는 notifier. Main이 이미 보일 때 rebuild 트리거용.
  final ValueNotifier<String?> pendingNotifier = ValueNotifier<String?>(null);

  void set(String? path, {String? notificationId}) {
    if (path != null && path.isNotEmpty) {
      _path = path;
    }
    var notify = _path != null && _path!.isNotEmpty;
    if (notificationId != null && notificationId.isNotEmpty) {
      final parsed = int.tryParse(notificationId);
      if (parsed != null) {
        _notificationId = parsed;
        notify = true;
      }
    }
    if (notify) {
      pendingNotifier.value =
          _path != null && _path!.isNotEmpty ? _path : '';
    }
  }

  bool get hasPendingNavigation =>
      (_path != null && _path!.isNotEmpty) || _notificationId != null;

  /// path·notificationId를 함께 소비. path 또는 id만 있어도 반환한다.
  PendingPushNavigation? takePending() {
    final p = _path;
    final n = _notificationId;
    _path = null;
    _notificationId = null;
    pendingNotifier.value = null;
    if ((p == null || p.isEmpty) && n == null) {
      return null;
    }
    return PendingPushNavigation(
      path: p ?? '',
      notificationId: n,
    );
  }
}
