import '../models/user_models.dart';

/// 에너지 detail에서 파생한 구독 전역 캐시.
/// `GET /v1/users/energy/detail`·`EnergyRefreshBus.notify(dto)` 성공 시 갱신.
class SubscriptionStatusCache {
  SubscriptionStatusCache._();

  static UserEnergyDto? _energy;

  static void apply(UserEnergyDto? energy) {
    if (energy != null) {
      _energy = energy;
    }
  }

  static bool get hasCache => _energy != null;

  static bool get isSubscribedActive {
    final energy = _energy;
    if (energy == null) return false;
    return energy.isSubscribedActiveAt(DateTime.now().toUtc());
  }
}
