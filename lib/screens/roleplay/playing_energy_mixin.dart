import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';

import '../../services/energy_refresh_bus.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/energy_timer_refetch.dart';
import '../../widgets/energy_info_popup.dart';
import '../../widgets/out_of_energy_bottom_sheet.dart';
import '../../widgets/playing_energy_indicator.dart';
import '../../widgets/playing_energy_induction_sheet.dart';

/// Playing 화면 에너지 상태·충전 타이머·로컬 차감.
mixin PlayingEnergyMixin<T extends StatefulWidget> on State<T> {
  VoidCallback? onPlayingEnergyIndicatorEndRoleplay;

  UserEnergyDto? _playingEnergy;
  Timer? _playingEnergyTimer;
  bool _playingEnergyRefetching = false;
  final EnergyTimerRefetchTracker _playingRefetchTracker =
      EnergyTimerRefetchTracker();
  bool _energyRefreshBusAttached = false;

  /// 이번 Playing 세션에서 대화 유도 시트를 한 번이라도 닫았는지.
  bool _playingEnergyInductionDismissed = false;

  UserEnergyDto? get playingEnergy => _playingEnergy;

  void initPlayingEnergy() {
    if (!_energyRefreshBusAttached) {
      EnergyRefreshBus.instance.addListener(_onEnergyRefreshBus);
      _energyRefreshBusAttached = true;
    }
    unawaited(_fetchPlayingEnergy());
  }

  void disposePlayingEnergy() {
    if (_energyRefreshBusAttached) {
      EnergyRefreshBus.instance.removeListener(_onEnergyRefreshBus);
      _energyRefreshBusAttached = false;
    }
    _playingEnergyTimer?.cancel();
    _playingEnergyTimer = null;
  }

  void _onEnergyRefreshBus(UserEnergyDto? energy) {
    if (energy != null) {
      if (!mounted) return;
      setState(() => _playingEnergy = energy);
      _playingRefetchTracker.syncFrom(energy, DateTime.now().toUtc());
      _syncPlayingEnergyTimer();
      return;
    }
    unawaited(_fetchPlayingEnergy());
  }

  Widget buildPlayingEnergyFooterIndicator() {
    return GestureDetector(
      onTap: _onPlayingEnergyIndicatorTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicWidth(
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: PlayingEnergyIndicator(energy: _playingEnergy),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onPlayingEnergyIndicatorTap() async {
    final energy = _playingEnergy;
    if (energy == null) return;

    final nowUtc = DateTime.now().toUtc();
    final isUnlimited = energy.isUnlimitedActiveAt(nowUtc);
    if (!isUnlimited && energy.energyCount == 0) {
      await showPlayingEnergyBlockedFlow();
    } else {
      await showEnergyInfoPopup(
        context,
        screen: EnergyOfferScreen.playing,
      );
    }
    if (!mounted) return;
    await _fetchPlayingEnergy();
  }

  /// 마이크/타이핑/배지/402 공통: 첫 차단은 유도 시트, 이후·See options는 충전 시트.
  Future<void> showPlayingEnergyBlockedFlow() async {
    if (!mounted) return;
    if (!_playingEnergyInductionDismissed) {
      final induction = await showPlayingEnergyInductionSheet(
        context,
        energy: _playingEnergy,
      );
      if (!mounted) return;
      _playingEnergyInductionDismissed = true;
      if (induction != PlayingEnergyInductionResult.seeOptions) {
        return;
      }
    }
    await showOpeningOutOfEnergyBottomSheet(
      context,
      screen: EnergyOfferScreen.playingInsufficient,
      playingHeader: true,
    );
    if (!mounted) return;
    await _fetchPlayingEnergy();
  }

  bool hasSpendablePlayingEnergy() {
    final energy = _playingEnergy;
    if (energy == null) return true;
    if (energy.isUnlimitedActiveAt(DateTime.now().toUtc())) return true;
    return energy.energyCount > 0;
  }

  void decrementPlayingEnergyCount() {
    final energy = _playingEnergy;
    if (energy == null) return;
    if (energy.isUnlimitedActiveAt(DateTime.now().toUtc())) return;
    if (energy.energyCount <= 0) return;
    setState(() {
      _playingEnergy = energy.copyWith(energyCount: energy.energyCount - 1);
    });
    _syncPlayingEnergyTimer();
  }

  Future<void> _fetchPlayingEnergy() async {
    final token = await TokenStorage.loadAccessToken();
    if (token == null || !mounted) return;
    try {
      final dto = await SudaApiClient.getUserEnergySimple(accessToken: token);
      if (!mounted) return;
      setState(() => _playingEnergy = dto);
      _playingRefetchTracker.syncFrom(dto, DateTime.now().toUtc());
      _syncPlayingEnergyTimer();
    } catch (_) {
      // 표시값 유지
    }
  }

  void _syncPlayingEnergyTimer() {
    _playingEnergyTimer?.cancel();
    _playingEnergyTimer = null;

    final energy = _playingEnergy;
    if (energy == null) return;
    final nowUtc = DateTime.now().toUtc();
    final needsTimer = energy.isUnlimitedActiveAt(nowUtc) ||
        !_isPlayingEnergyFull(energy) ||
        energy.needsSubscriptionExpiryWatch(nowUtc);
    if (!needsTimer) return;

    _playingEnergyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onPlayingEnergyTick());
    });
  }

  Future<void> _onPlayingEnergyTick() async {
    if (!mounted || _playingEnergyRefetching) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    final energy = _playingEnergy;
    if (energy == null) return;
    final nowUtc = DateTime.now().toUtc();

    final shouldRefetch =
        _playingRefetchTracker.shouldRefetch(energy, nowUtc);

    setState(() {});
    if (!shouldRefetch) return;

    _playingEnergyRefetching = true;
    try {
      await _fetchPlayingEnergy();
    } finally {
      _playingEnergyRefetching = false;
    }
  }

  bool _isPlayingEnergyFull(UserEnergyDto energy) =>
      energy.maxEnergyCount > 0 &&
      energy.energyCount == energy.maxEnergyCount;
}
