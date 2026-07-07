import '../models/user_models.dart';

/// 에너지 1초 타이머 tick마다 서버 재조회 필요 여부 판단.
/// 무제한 활성 → 비활성 전환 시 1회 refetch, 일반 모드는 충전 00:00 시 refetch.
class EnergyTimerRefetchTracker {
  bool _wasUnlimitedActive = false;

  void syncFrom(UserEnergyDto energy, DateTime nowUtc) {
    _wasUnlimitedActive = energy.isUnlimitedActiveAt(nowUtc);
  }

  bool shouldRefetch(UserEnergyDto energy, DateTime nowUtc) {
    final isUnlimitedNow = energy.isUnlimitedActiveAt(nowUtc);
    final unlimitedJustEnded = _wasUnlimitedActive && !isUnlimitedNow;
    _wasUnlimitedActive = isUnlimitedNow;

    if (unlimitedJustEnded) return true;

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
