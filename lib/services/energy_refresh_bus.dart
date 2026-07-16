import '../models/user_models.dart';
import 'subscription_status_cache.dart';

/// 에너지 detail 재조회 알림.
///
/// [energy]가 있으면 리스너는 추가 GET 없이 DTO를 적용한다.
/// null이면 필요 시 GET으로 갱신한다(in-flight coalesce는 UserApi).
class EnergyRefreshBus {
  EnergyRefreshBus._();

  static final EnergyRefreshBus instance = EnergyRefreshBus._();

  final List<void Function(UserEnergyDto? energy)> _listeners = [];

  void addListener(void Function(UserEnergyDto? energy) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(UserEnergyDto? energy) listener) {
    _listeners.remove(listener);
  }

  void notify([UserEnergyDto? energy]) {
    if (energy != null) {
      SubscriptionStatusCache.apply(energy);
    }
    for (final listener in List<void Function(UserEnergyDto? energy)>.of(
      _listeners,
    )) {
      listener(energy);
    }
  }
}