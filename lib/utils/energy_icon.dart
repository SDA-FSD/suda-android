import '../models/user_models.dart';

/// 구독 여부에 따른 에너지/무제한 아이콘 경로 (앱 전역 공통).
String energyIconAssetPath(UserEnergyDto energy, DateTime nowUtc) {
  final subscribed = energy.isSubscribedActiveAt(nowUtc);
  if (energy.isUnlimitedActiveAt(nowUtc)) {
    return subscribed
        ? 'assets/images/icons/unlimited_sub.png'
        : 'assets/images/icons/unlimited.png';
  }
  return subscribed
      ? 'assets/images/icons/energy_sub.png'
      : 'assets/images/icons/energy.png';
}
