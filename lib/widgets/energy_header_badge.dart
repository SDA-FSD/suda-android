import 'dart:async';

import 'package:flutter/material.dart';

import '../services/effect_anchor_registry.dart';
import '../services/energy_refresh_bus.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/energy_icon.dart';
import '../utils/energy_timer_refetch.dart';
import 'energy_info_popup.dart';

const _energyZeroColor = Color(0xFFE60000);

/// 홈·Opening 등 우상단 에너지/무제한 배지. 탭 시 에너지 정보 팝업.
class EnergyHeaderBadge extends StatefulWidget {
  /// 변경 시 `GET /v1/users/energy/detail` 재조회 (예: Home 탭 재진입).
  final int? refreshCounter;

  /// true면 `EffectAnchorId.energyBadge` 앵커로 등록 (Home Like 이펙트 등).
  final bool registerEnergyBadgeAnchor;

  /// IndexedStack 비가시·백그라운드일 때 false → 타이머/GET pause.
  /// DTO bus 알림은 받아 두었다가 표시에 쓴다.
  final bool active;

  /// 에너지 DTO 적용 시 (번개 아이콘과 동일 소스). Home 프리미엄 뱃지 등.
  final ValueChanged<UserEnergyDto>? onEnergyChanged;

  const EnergyHeaderBadge({
    super.key,
    this.refreshCounter,
    this.registerEnergyBadgeAnchor = false,
    this.active = true,
    this.onEnergyChanged,
  });

  @override
  State<EnergyHeaderBadge> createState() => _EnergyHeaderBadgeState();
}

class _EnergyHeaderBadgeState extends State<EnergyHeaderBadge> {
  final GlobalKey _anchorKey = GlobalKey();
  UserEnergyDto? _energy;
  Timer? _periodicTimer;
  bool _isRefetching = false;
  String? _accessToken;
  final EnergyTimerRefetchTracker _refetchTracker = EnergyTimerRefetchTracker();

  /// 탭 활성 + 현재 라우트(위 스크린/다이얼로그 없음).
  bool get _isLive {
    if (!widget.active) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  @override
  void initState() {
    super.initState();
    if (widget.registerEnergyBadgeAnchor) {
      EffectAnchorRegistry.instance.registerKey(
        EffectAnchorId.energyBadge,
        _anchorKey,
      );
    }
    EnergyRefreshBus.instance.addListener(_onEnergyRefreshBus);
    unawaited(_bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPeriodicTimer();
  }

  @override
  void didUpdateWidget(EnergyHeaderBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameActive = widget.active && !oldWidget.active;
    final counterChanged = widget.refreshCounter != null &&
        widget.refreshCounter != oldWidget.refreshCounter;

    if (becameActive || (counterChanged && widget.active)) {
      unawaited(_fetchEnergy());
    } else if (!widget.active && oldWidget.active) {
      _periodicTimer?.cancel();
      _periodicTimer = null;
    } else {
      _syncPeriodicTimer();
    }
  }

  @override
  void dispose() {
    EnergyRefreshBus.instance.removeListener(_onEnergyRefreshBus);
    _periodicTimer?.cancel();
    if (widget.registerEnergyBadgeAnchor) {
      EffectAnchorRegistry.instance.unregister(
        EffectAnchorId.energyBadge,
        _anchorKey,
      );
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (widget.active) {
      await _fetchEnergy();
    }
  }

  void _onEnergyRefreshBus(UserEnergyDto? energy) {
    if (energy != null) {
      _applyEnergy(energy);
      return;
    }
    if (!_isLive) return;
    unawaited(_fetchEnergy());
  }

  void _applyEnergy(UserEnergyDto dto) {
    if (!mounted) return;
    setState(() => _energy = dto);
    widget.onEnergyChanged?.call(dto);
    _refetchTracker.syncFrom(dto, DateTime.now().toUtc());
    _syncPeriodicTimer();
  }

  Future<void> _fetchEnergy() async {
    final token = _accessToken ?? await TokenStorage.loadAccessToken();
    if (token == null) return;
    _accessToken = token;
    try {
      final dto = await SudaApiClient.getUserEnergy(accessToken: token);
      if (!mounted) return;
      _applyEnergy(dto);
    } catch (_) {
      // 실패 시 표시값 유지
    }
  }

  void _syncPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;

    if (!_isLive) return;

    final energy = _energy;
    if (energy == null) return;
    final nowUtc = DateTime.now().toUtc();
    final needsTimer = energy.isUnlimitedActiveAt(nowUtc) ||
        !_isEnergyFull(energy) ||
        energy.needsSubscriptionExpiryWatch(nowUtc);
    if (!needsTimer) return;

    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onPeriodicTick());
    });
  }

  Future<void> _onPeriodicTick() async {
    if (!mounted || _isRefetching) return;
    if (!_isLive) {
      _periodicTimer?.cancel();
      _periodicTimer = null;
      return;
    }
    final energy = _energy;
    if (energy == null) return;
    final nowUtc = DateTime.now().toUtc();

    final shouldRefetch = _refetchTracker.shouldRefetch(energy, nowUtc);

    setState(() {});
    if (!shouldRefetch) return;

    _isRefetching = true;
    try {
      await _fetchEnergy();
    } finally {
      _isRefetching = false;
    }
  }

  bool _isEnergyFull(UserEnergyDto energy) =>
      energy.maxEnergyCount > 0 &&
      energy.energyCount == energy.maxEnergyCount;

  String _formatUnlimitedRemaining(DateTime endsAt) {
    final nowUtc = DateTime.now().toUtc();
    var remaining = endsAt.difference(nowUtc);
    if (remaining.isNegative) remaining = Duration.zero;
    final totalSeconds = remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _onTap() async {
    await showEnergyInfoPopup(context);
    if (!mounted) return;
    await _fetchEnergy();
  }

  @override
  Widget build(BuildContext context) {
    final badge = GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Align(
          alignment: Alignment.topRight,
          child: _buildBadge(context),
        ),
      ),
    );

    if (widget.registerEnergyBadgeAnchor) {
      return KeyedSubtree(key: _anchorKey, child: badge);
    }
    return badge;
  }

  Widget _buildBadge(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
        );
    final energy = _energy;
    final nowUtc = DateTime.now().toUtc();

    if (energy != null && energy.isUnlimitedActiveAt(nowUtc)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            energyIconAssetPath(energy, nowUtc),
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 5),
          Text(
            _formatUnlimitedRemaining(energy.unlimitedEndsAt!),
            style: textStyle,
          ),
        ],
      );
    }

    final count = energy?.energyCount ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          energy == null
              ? 'assets/images/icons/energy.png'
              : energyIconAssetPath(energy, nowUtc),
          width: 24,
          height: 24,
        ),
        Text(
          '$count',
          style: count == 0
              ? textStyle?.copyWith(color: _energyZeroColor) ??
                  const TextStyle(
                    color: _energyZeroColor,
                    fontWeight: FontWeight.w700,
                  )
              : textStyle,
        ),
      ],
    );
  }
}
