import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';

import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/energy_timer_refetch.dart';
import '../../widgets/playing_energy_indicator.dart';

/// Playing 화면 에너지 상태·충전 타이머·로컬 차감.
mixin PlayingEnergyMixin<T extends StatefulWidget> on State<T> {
  UserEnergyDto? _playingEnergy;
  Timer? _playingEnergyTimer;
  bool _playingEnergyRefetching = false;
  final EnergyTimerRefetchTracker _playingRefetchTracker =
      EnergyTimerRefetchTracker();

  UserEnergyDto? get playingEnergy => _playingEnergy;

  void initPlayingEnergy() {
    unawaited(_fetchPlayingEnergy());
  }

  void disposePlayingEnergy() {
    _playingEnergyTimer?.cancel();
    _playingEnergyTimer = null;
  }

  Widget buildPlayingEnergyFooterIndicator() {
    return PlayingEnergyIndicator(energy: _playingEnergy);
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
      _playingEnergy = UserEnergyDto(
        energyCount: energy.energyCount - 1,
        maxEnergyCount: energy.maxEnergyCount,
        lastAutoChargedAt: energy.lastAutoChargedAt,
        unlimitedEndsAt: energy.unlimitedEndsAt,
      );
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
    final needsTimer =
        energy.isUnlimitedActiveAt(nowUtc) || !_isPlayingEnergyFull(energy);
    if (!needsTimer) return;

    _playingEnergyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onPlayingEnergyTick());
    });
  }

  Future<void> _onPlayingEnergyTick() async {
    if (!mounted || _playingEnergyRefetching) return;
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
