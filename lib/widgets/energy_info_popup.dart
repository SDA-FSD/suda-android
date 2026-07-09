import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_refresh_service.dart';
import '../services/token_storage.dart';
import '../utils/energy_timer_refetch.dart';
import 'default_popup.dart';

const _pink = Color(0xFFFF00A6);
const _energyZeroColor = Color(0xFFE60000);
const _progressBg = Color(0xFF635F5F);
const _progressFill = Color(0xFF0CABA8);

/// 홈 에너지 배지 탭 시 `GET /v1/users/energy` 후 에너지 안내 팝업.
Future<void> showEnergyInfoPopup(BuildContext context) async {
  await TokenRefreshService.instance.refreshIfNeeded();
  if (!context.mounted) return;
  final accessToken = await TokenStorage.loadAccessToken();
  if (!context.mounted || accessToken == null) return;

  UserEnergyDto energy;
  try {
    energy = await SudaApiClient.getUserEnergy(accessToken: accessToken);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  await _showEnergyInfoPopupWithEnergy(context, energy, accessToken: accessToken);
}

/// Opening `sessionId == '0'` 등 에너지 부족 시 에너지 정보 팝업(본문 문구만 교체).
Future<void> showEnergyInsufficientPopup(BuildContext context) async {
  await TokenRefreshService.instance.refreshIfNeeded();
  if (!context.mounted) return;
  final accessToken = await TokenStorage.loadAccessToken();
  if (!context.mounted || accessToken == null) return;

  UserEnergyDto energy;
  try {
    energy = await SudaApiClient.getUserEnergy(accessToken: accessToken);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  await _showEnergyInfoPopupWithEnergy(
    context,
    energy,
    accessToken: accessToken,
    messageOverride: l10n.energyInsufficient,
  );
}

/// Playing 에너지 부족(0·402) — 본문은 Home과 동일(충전 타이머), 버튼은 롤플레이 종료.
Future<void> showPlayingEnergyInsufficientPopup(
  BuildContext context, {
  required VoidCallback onEndRoleplay,
}) async {
  await TokenRefreshService.instance.refreshIfNeeded();
  if (!context.mounted) return;
  final accessToken = await TokenStorage.loadAccessToken();
  if (!context.mounted || accessToken == null) return;

  UserEnergyDto energy;
  try {
    energy = await SudaApiClient.getUserEnergy(accessToken: accessToken);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  await DefaultPopup.show(
    context,
    titleText: _resolveEnergyPopupTitle(l10n, energy),
    bodyWidget: EnergyInfoPopupBody(
      initialEnergy: energy,
      accessToken: accessToken,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.endRoleplay,
        onPressed: () {
          onEndRoleplay();
        },
      ),
    ],
  );
}

Future<void> _showEnergyInfoPopupWithEnergy(
  BuildContext context,
  UserEnergyDto energy, {
  required String accessToken,
  bool labMode = false,
  String? messageOverride,
}) async {
  final l10n = AppLocalizations.of(context)!;
  await DefaultPopup.show(
    context,
    titleText: _resolveEnergyPopupTitle(l10n, energy),
    bodyWidget: EnergyInfoPopupBody(
      initialEnergy: energy,
      accessToken: accessToken,
      labMode: labMode,
      messageOverride: messageOverride,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.closePopup,
        onPressed: () {},
      ),
    ],
  );
}

/// Lab: playing·무제한·에너지 수(0~5) 조합으로 에너지 팝업 재현.
Future<void> showEnergyPopupForLab(
  BuildContext context, {
  required bool playing,
  required bool unlimited,
  required int energyCount,
}) async {
  final energy = _buildLabEnergyDto(
    unlimited: unlimited,
    energyCount: energyCount,
  );
  final l10n = AppLocalizations.of(context)!;
  final isPlayingBlocked = playing && !unlimited && energyCount == 0;

  if (isPlayingBlocked) {
    await DefaultPopup.show(
      context,
      titleText: _resolveEnergyPopupTitle(l10n, energy),
      bodyWidget: EnergyInfoPopupBody(
        initialEnergy: energy,
        accessToken: '',
        labMode: true,
      ),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: l10n.endRoleplay,
          onPressed: () {},
        ),
      ],
    );
    return;
  }

  await _showEnergyInfoPopupWithEnergy(
    context,
    energy,
    accessToken: '',
    labMode: true,
  );
}

UserEnergyDto _buildLabEnergyDto({
  required bool unlimited,
  required int energyCount,
}) {
  const maxEnergyCount = 5;
  final count = energyCount.clamp(0, maxEnergyCount);
  final nowUtc = DateTime.now().toUtc();

  if (unlimited) {
    return UserEnergyDto(
      energyCount: count,
      maxEnergyCount: maxEnergyCount,
      unlimitedEndsAt: nowUtc.add(const Duration(minutes: 15)),
    );
  }
  if (count >= maxEnergyCount) {
    return UserEnergyDto(
      energyCount: maxEnergyCount,
      maxEnergyCount: maxEnergyCount,
    );
  }
  return UserEnergyDto(
    energyCount: count,
    maxEnergyCount: maxEnergyCount,
    lastAutoChargedAt: nowUtc.subtract(const Duration(minutes: 15)),
  );
}

String _resolveEnergyPopupTitle(
  AppLocalizations l10n,
  UserEnergyDto energy,
) {
  final nowUtc = DateTime.now().toUtc();
  if (!energy.isUnlimitedActiveAt(nowUtc) && energy.energyCount == 0) {
    return l10n.energyOutOfEnergyTitle;
  }
  return l10n.energyInfoTitle;
}

class EnergyInfoPopupBody extends StatefulWidget {
  final UserEnergyDto initialEnergy;
  final String accessToken;
  final bool labMode;
  final String? messageOverride;

  const EnergyInfoPopupBody({
    super.key,
    required this.initialEnergy,
    required this.accessToken,
    this.labMode = false,
    this.messageOverride,
  });

  @override
  State<EnergyInfoPopupBody> createState() => _EnergyInfoPopupBodyState();
}

class _EnergyInfoPopupBodyState extends State<EnergyInfoPopupBody> {
  late UserEnergyDto _energy;
  Timer? _timer;
  bool _isRefetching = false;
  final EnergyTimerRefetchTracker _refetchTracker = EnergyTimerRefetchTracker();

  @override
  void initState() {
    super.initState();
    _energy = widget.initialEnergy;
    _refetchTracker.syncFrom(_energy, DateTime.now().toUtc());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onTick() async {
    if (!mounted || _isRefetching) return;
    if (widget.labMode) {
      setState(() {});
      return;
    }
    final nowUtc = DateTime.now().toUtc();

    final shouldRefetch = _refetchTracker.shouldRefetch(_energy, nowUtc);

    if (shouldRefetch) {
      await _refetchEnergy();
      return;
    }
    setState(() {});
  }

  Future<void> _refetchEnergy() async {
    if (widget.labMode || _isRefetching || !mounted) return;
    _isRefetching = true;
    try {
      final dto = await SudaApiClient.getUserEnergy(
        accessToken: widget.accessToken,
      );
      if (!mounted) return;
      setState(() => _energy = dto);
      _refetchTracker.syncFrom(dto, DateTime.now().toUtc());
    } catch (_) {
      // 표시값 유지
    } finally {
      _isRefetching = false;
    }
  }

  String _formatMmSs(Duration remaining) {
    var r = remaining;
    if (r.isNegative) r = Duration.zero;
    final totalSeconds = r.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final baseStyle = theme.bodyLarge?.copyWith(color: Colors.white) ??
        const TextStyle(color: Colors.white);
    final timeStyle = baseStyle.copyWith(
      color: _pink,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
    );
    final fractionStyle = theme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    );

    final nowUtc = DateTime.now().toUtc();
    final isUnlimited = _energy.isUnlimitedActiveAt(nowUtc);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;
            final rowWidth = contentWidth - 24;
            final iconGap = isUnlimited ? 5.0 : 0.0;
            final barWidth = rowWidth - 24 - iconGap;
            return Center(
              child: SizedBox(
                width: rowWidth,
                child: Row(
                  children: [
                    Image.asset(
                      isUnlimited
                          ? 'assets/images/icons/unlimited.png'
                          : 'assets/images/icons/energy.png',
                      width: 24,
                      height: 24,
                    ),
                    if (isUnlimited) const SizedBox(width: 5),
                    SizedBox(
                      width: barWidth,
                      height: 20,
                      child: isUnlimited
                          ? _UnlimitedEnergyBar(
                              remainingLabel: _formatMmSs(
                                _energy.unlimitedEndsAt!.difference(nowUtc),
                              ),
                              labelStyle: fractionStyle,
                            )
                          : _EnergyFractionBar(
                              energy: _energy,
                              fractionStyle: fractionStyle,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildMessage(
          l10n: l10n,
          baseStyle: baseStyle,
          timeStyle: timeStyle,
          nowUtc: nowUtc,
          isUnlimited: isUnlimited,
        ),
      ],
    );
  }

  Widget _buildMessage({
    required AppLocalizations l10n,
    required TextStyle baseStyle,
    required TextStyle timeStyle,
    required DateTime nowUtc,
    required bool isUnlimited,
  }) {
    final override = widget.messageOverride;
    if (override != null && override.isNotEmpty) {
      return Text(
        override,
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    if (isUnlimited) {
      final time = _formatMmSs(
        _energy.unlimitedEndsAt!.difference(nowUtc),
      );
      return _highlightTimeText(
        template: l10n.energyInfoUnlimitedEndsIn,
        time: time,
        baseStyle: baseStyle,
        timeStyle: timeStyle,
      );
    }

    if (_energy.isEnergyFull) {
      return Text(
        l10n.energyInfoFull,
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    final time = _formatMmSs(_energy.rechargeRemaining(nowUtc));
    return _highlightTimeText(
      template: l10n.energyInfoRechargeUntil,
      time: time,
      baseStyle: baseStyle,
      timeStyle: timeStyle,
    );
  }
}

Widget _highlightTimeText({
  required String template,
  required String time,
  required TextStyle baseStyle,
  required TextStyle timeStyle,
}) {
  const token = '@@TIME@@';
  final index = template.indexOf(token);
  if (index < 0) {
    return Text(template, style: baseStyle, textAlign: TextAlign.center);
  }
  final before = template.substring(0, index);
  final after = template.substring(index + token.length);
  return Text.rich(
    TextSpan(
      style: baseStyle,
      children: [
        if (before.isNotEmpty) TextSpan(text: before),
        TextSpan(text: time, style: timeStyle),
        if (after.isNotEmpty) TextSpan(text: after),
      ],
    ),
    textAlign: TextAlign.center,
  );
}

class _EnergyFractionBar extends StatelessWidget {
  final UserEnergyDto energy;
  final TextStyle? fractionStyle;

  const _EnergyFractionBar({
    required this.energy,
    required this.fractionStyle,
  });

  @override
  Widget build(BuildContext context) {
    final max = energy.maxEnergyCount;
    final count = energy.energyCount;
    final fraction = max > 0 ? (count / max).clamp(0.0, 1.0) : 0.0;
    final label = '$count/$max';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const Positioned.fill(
            child: ColoredBox(color: _progressBg),
          ),
          FractionallySizedBox(
            widthFactor: fraction,
            heightFactor: 1,
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const ColoredBox(color: _progressFill),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: count == 0
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '0',
                            style: fractionStyle?.copyWith(
                              color: _energyZeroColor,
                            ),
                          ),
                          TextSpan(text: '/$max', style: fractionStyle),
                        ],
                      ),
                    )
                  : Text(label, style: fractionStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlimitedEnergyBar extends StatelessWidget {
  final String remainingLabel;
  final TextStyle? labelStyle;

  const _UnlimitedEnergyBar({
    required this.remainingLabel,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF80D7CF),
              Color(0xFF8A38F5),
            ],
          ),
        ),
        child: Center(
          child: Text(remainingLabel, style: labelStyle),
        ),
      ),
    );
  }
}

extension _UserEnergyPopupX on UserEnergyDto {
  bool get isEnergyFull =>
      maxEnergyCount > 0 && energyCount == maxEnergyCount;

  Duration rechargeRemaining(DateTime nowUtc) {
    final last = lastAutoChargedAt;
    if (last == null) return Duration.zero;
    final next = last.add(const Duration(minutes: 30));
    final remaining = next.difference(nowUtc);
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }
}
