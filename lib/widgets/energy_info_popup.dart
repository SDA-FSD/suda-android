import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_refresh_service.dart';
import '../services/token_storage.dart';
import 'default_popup.dart';

const _pink = Color(0xFFFF00A6);
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

  final l10n = AppLocalizations.of(context)!;
  await DefaultPopup.show(
    context,
    titleText: l10n.energyInfoTitle,
    bodyWidget: EnergyInfoPopupBody(
      initialEnergy: energy,
      accessToken: accessToken,
    ),
    buttons: [
      DefaultPopupButton(
        type: DefaultPopupButtonType.primary,
        label: l10n.ticketInfoButtonOkay,
        onPressed: () {},
      ),
    ],
  );
}

class EnergyInfoPopupBody extends StatefulWidget {
  final UserEnergyDto initialEnergy;
  final String accessToken;

  const EnergyInfoPopupBody({
    super.key,
    required this.initialEnergy,
    required this.accessToken,
  });

  @override
  State<EnergyInfoPopupBody> createState() => _EnergyInfoPopupBodyState();
}

class _EnergyInfoPopupBodyState extends State<EnergyInfoPopupBody> {
  late UserEnergyDto _energy;
  Timer? _timer;
  bool _isRefetching = false;

  @override
  void initState() {
    super.initState();
    _energy = widget.initialEnergy;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onTick() async {
    if (!mounted || _isRefetching) return;
    final nowUtc = DateTime.now().toUtc();

    final shouldRefetch = _energy.isUnlimitedActiveAt(nowUtc)
        ? !_isUnlimitedStillActive(nowUtc)
        : (!_energy.isEnergyFull && _energy.rechargeRemaining(nowUtc) == Duration.zero);

    if (shouldRefetch) {
      await _refetchEnergy();
      return;
    }
    setState(() {});
  }

  bool _isUnlimitedStillActive(DateTime nowUtc) {
    final endsAt = _energy.unlimitedEndsAt;
    return endsAt != null && endsAt.isAfter(nowUtc);
  }

  Future<void> _refetchEnergy() async {
    if (_isRefetching || !mounted) return;
    _isRefetching = true;
    try {
      final dto = await SudaApiClient.getUserEnergy(
        accessToken: widget.accessToken,
      );
      if (!mounted) return;
      setState(() => _energy = dto);
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
            final barWidth = rowWidth - 24;
            return Center(
              child: SizedBox(
                width: rowWidth,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/icons/energy.png',
                      width: 24,
                      height: 24,
                    ),
                    SizedBox(
                      width: barWidth,
                      height: 20,
                      child: isUnlimited
                          ? _UnlimitedEnergyBar()
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
              child: Text(label, style: fractionStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlimitedEnergyBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _progressFill, width: 2),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/icons/unlimited.png',
          width: 18,
          height: 18,
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
