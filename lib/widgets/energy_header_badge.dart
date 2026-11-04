import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../services/effect_anchor_registry.dart';
import '../services/energy_refresh_bus.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/energy_icon.dart';
import '../utils/energy_timer_refetch.dart';
import 'energy_info_popup.dart';

const _energyZeroColor = Color(0xFFE60000);
const _timerMint = Color(0xFF0CABA8);
const _timerCharging = Color(0x99FFFFFF); // white 60%
const _clockAsset = 'assets/images/icons/clock.png';

/// 홈·Opening 등 우상단 에너지/무제한 배지. 탭 시 에너지 정보 팝업.
class EnergyHeaderBadge extends StatefulWidget {
  /// 변경 시 `GET /v1/users/energy/simple` 재조회 (예: Home 탭 재진입).
  final int? refreshCounter;

  /// true면 `EffectAnchorId.energyBadge` 앵커로 등록 (Home Like 이펙트 등).
  final bool registerEnergyBadgeAnchor;

  /// IndexedStack 비가시·백그라운드일 때 false → 타이머/GET pause.
  /// DTO bus 알림은 받아 두었다가 표시에 쓴다.
  final bool active;

  /// 에너지 offer impression 통계용 `screen` 값.
  /// 서버 contract이므로 임의 수정 금지(정해진 값만 전달).
  final String energyOfferScreen;

  /// 에너지 DTO 적용 시 (번개 아이콘과 동일 소스). Home 프리미엄 뱃지 등.
  final ValueChanged<UserEnergyDto>? onEnergyChanged;

  /// 48 탭 영역 안에서의 배지 정렬. Overview CEFR과 수평 맞출 때 `centerRight`.
  final AlignmentGeometry contentAlignment;

  const EnergyHeaderBadge({
    super.key,
    this.refreshCounter,
    this.registerEnergyBadgeAnchor = false,
    this.active = true,
    this.energyOfferScreen = EnergyOfferScreen.home,
    this.onEnergyChanged,
    this.contentAlignment = Alignment.topRight,
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
      final dto = await SudaApiClient.getUserEnergySimple(accessToken: token);
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

  Future<void> _onTap() async {
    await showEnergyInfoPopup(
      context,
      screen: widget.energyOfferScreen,
    );
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
          alignment: widget.contentAlignment,
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
    final countStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
        );
    final energy = _energy;
    final nowUtc = DateTime.now().toUtc();

    if (energy == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/icons/energy.png',
            width: 24,
            height: 24,
          ),
          Text('0', style: countStyle),
        ],
      );
    }

    final unlimited = energy.isUnlimitedActiveAt(nowUtc);
    final full = !unlimited && _isEnergyFull(energy);
    final timerColor = (unlimited || full) ? _timerMint : _timerCharging;
    final timerLabel = unlimited
        ? formatEnergyMmSs(energyUnlimitedRemaining(energy, nowUtc))
        : full
            ? 'Full'
            : formatEnergyMmSs(energyRechargeRemaining(energy, nowUtc));

    final count = energy.energyCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TimerGlassPill(label: timerLabel, foreground: timerColor),
        const SizedBox(width: 6),
        Image.asset(
          energyIconAssetPath(energy, nowUtc),
          width: 24,
          height: 24,
        ),
        if (!unlimited)
          Text(
            '$count',
            style: count == 0
                ? countStyle?.copyWith(color: _energyZeroColor) ??
                    const TextStyle(
                      color: _energyZeroColor,
                      fontWeight: FontWeight.w700,
                    )
                : countStyle,
          ),
      ],
    );
  }
}

class _TimerGlassPill extends StatelessWidget {
  const _TimerGlassPill({
    required this.label,
    required this.foreground,
  });

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.36),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  child: Image.asset(
                    _clockAsset,
                    width: 12,
                    height: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(label, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
