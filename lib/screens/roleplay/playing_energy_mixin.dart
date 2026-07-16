import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';

import '../../services/energy_refresh_bus.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/energy_timer_refetch.dart';
import '../../widgets/energy_info_popup.dart';
import '../../widgets/playing_energy_indicator.dart';

/// Playing 화면 에너지 상태·충전 타이머·로컬 차감.
mixin PlayingEnergyMixin<T extends StatefulWidget> on State<T> {
  VoidCallback? onPlayingEnergyIndicatorEndRoleplay;

  UserEnergyDto? _playingEnergy;
  Timer? _playingEnergyTimer;
  bool _playingEnergyRefetching = false;
  final EnergyTimerRefetchTracker _playingRefetchTracker =
      EnergyTimerRefetchTracker();
  bool _energyRefreshBusAttached = false;

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: PlayingEnergyIndicator(energy: _playingEnergy),
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
      await showPlayingEnergyInsufficientPopup(
        context,
        onEndRoleplay: () {
          onPlayingEnergyIndicatorEndRoleplay?.call();
        },
      );
    } else {
      await showEnergyInfoPopup(context);
    }
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
      final dto = await SudaApiClient.getUserEnergy(accessToken: token);
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
