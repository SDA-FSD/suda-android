import 'package:flutter/foundation.dart';

/// 푸시 알림 클릭 시 이동할 appPath를 로그인/동의 완료 전까지 보관하는 서비스.
/// Home 진입 시점에 한 번 소비(적용 후 take)한다.
/// [pendingNotifier] 변경 시 리스너가 setState를 호출해 이미 Main이 보이는 상태에서도 적용을 트리거할 수 있다.
class PendingAppPathService {
  PendingAppPathService._();

  static final PendingAppPathService instance = PendingAppPathService._();

  String? _path;

  /// 알림 클릭으로 path가 설정될 때 알려주는 notifier. Main이 이미 보일 때 rebuild 트리거용.
  final ValueNotifier<String?> pendingNotifier = ValueNotifier<String?>(null);

  void set(String? path) {
    if (path == null || path.isEmpty) return;
    _path = path;
    pendingNotifier.value = path;
  }

  String? get() => _path;

  /// 한 번 소비. 적용 후 호출해 반환값으로 이동하고 내부는 비운다.
  String? take() {
    final p = _path;
    _path = null;
    pendingNotifier.value = null;
    return p;
  }

  void clear() {
    _path = null;
    pendingNotifier.value = null;
  }
}
