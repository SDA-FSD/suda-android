/// 에너지 detail 재조회가 필요할 때 배지·Playing 등 리스너에 알림.
class EnergyRefreshBus {
  EnergyRefreshBus._();

  static final EnergyRefreshBus instance = EnergyRefreshBus._();

  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}
