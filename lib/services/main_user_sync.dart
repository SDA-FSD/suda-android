import '../models/user_models.dart';

/// Main(`_MyAppState`)의 `_user`와 서브 플로우(튜토리얼 등)에서 갱신된 사용자를 맞출 때 사용.
class MainUserSync {
  MainUserSync._();

  static final MainUserSync instance = MainUserSync._();

  void Function(UserDto user)? _listener;

  void register(void Function(UserDto user) listener) {
    _listener = listener;
  }

  void unregister() {
    _listener = null;
  }

  void notifyUserUpdated(UserDto user) {
    _listener?.call(user);
  }
}
