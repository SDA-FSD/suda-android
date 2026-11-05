/// Home 시리즈 목록을 다시 받으라고 알린다. Overview가 비었을 때 쓴다.
class HomeContentsReload {
  HomeContentsReload._();

  static final HomeContentsReload instance = HomeContentsReload._();

  final List<void Function()> _listeners = [];

  void register(void Function() listener) {
    _listeners.add(listener);
  }

  void unregister(void Function() listener) {
    _listeners.remove(listener);
  }

  void request() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}
