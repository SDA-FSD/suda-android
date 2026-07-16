import '../models/user_models.dart';

/// 에너지 1초 타이머 tick마다 서버 재조회 필요 여부 판단.
/// - 무제한 활성 → 비활성 전환 시 1회 refetch
/// - 일반 모드 충전 00:00 시 refetch
/// - 구독 만료 시각 경과 시 1회 refetch (`subscriptionExpiredAt`)
class EnergyTimerRefetchTracker {
  bool _wasUnlimitedActive = false;
  bool _wasSubscriptionActive = false;

  void syncFrom(UserEnergyDto energy, DateTime nowUtc) {
    _wasUnlimitedActive = energy.isUnlimitedActiveAt(nowUtc);
    _wasSubscriptionActive = energy.isSubscribedActiveAt(nowUtc);
  }

  bool shouldRefetch(UserEnergyDto energy, DateTime nowUtc) {
    final isUnlimitedNow = energy.isUnlimitedActiveAt(nowUtc);
    final unlimitedJustEnded = _wasUnlimitedActive && !isUnlimitedNow;
    _wasUnlimitedActive = isUnlimitedNow;

    final isSubscribedNow = energy.isSubscribedActiveAt(nowUtc);
    final subscriptionJustExpired =
        _wasSubscriptionActive && !isSubscribedNow;
    _wasSubscriptionActive = isSubscribedNow;

    if (unlimitedJustEnded || subscriptionJustExpired) return true;

    if (isUnlimitedNow) return false;

    final isFull =
        energy.maxEnergyCount > 0 && energy.energyCount == energy.maxEnergyCount;
    if (isFull) return false;

    return _rechargeRemaining(energy, nowUtc) == Duration.zero;
  }

  Duration _rechargeRemaining(UserEnergyDto energy, DateTime nowUtc) {
    final last = energy.lastAutoChargedAt;
    if (last == null) return Duration.zero;
    final next = last.add(const Duration(minutes: 30));
    final remaining = next.difference(nowUtc);
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }
}
