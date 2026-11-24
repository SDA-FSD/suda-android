import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_models.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/suda_haptics.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/suda_tap.dart';

class VibrationSettingScreen extends StatefulWidget {
  final UserDto? user;
  final ValueChanged<UserDto>? onUserUpdated;

  const VibrationSettingScreen({
    super.key,
    this.user,
    this.onUserUpdated,
  });

  @override
  State<VibrationSettingScreen> createState() => _VibrationSettingScreenState();
}

class _VibrationSettingScreenState extends State<VibrationSettingScreen> {
  static const Color _boxBg = Color(0xFF353535);
  static const Color _trackOff = Color(0xFF8C8C8C);
  static const Color _trackOn = Color(0xFF80D7CF);
  static const double _trackWidth = 56;
  static const double _trackHeight = 24;
  static const double _thumbSize = 20;

  late bool _isOn;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isOn = !SudaHaptics.disabledOf(widget.user);
  }

  Future<void> _onToggleTap() async {
    if (_isUpdating) return;
    final nextOn = !_isOn;
    setState(() => _isUpdating = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        if (mounted) {
          setState(() => _isUpdating = false);
          DefaultToast.show(context, 'Authentication required.', negative: true);
        }
        return;
      }
      final value = nextOn ? 'N' : 'Y';
      await SudaApiClient.updateVibration(accessToken: token, value: value);
      final updated = widget.user?.upsertMetaInfo(
        key: SudaHaptics.metaKey,
        value: value,
      );
      SudaHaptics.allow(nextOn);
      if (updated != null) widget.onUserUpdated?.call(updated);
      if (mounted) {
        setState(() {
          _isOn = nextOn;
          _isUpdating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isUpdating = false);
        DefaultToast.show(
          context,
          AppLocalizations.of(context)!.requestFailed,
          isError: true,
          negative: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    return AppScaffold(
      centerTitle: l10n.settingsVibration,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _boxBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.settingsVibration,
                            style: const TextStyle(
                              fontFamily: 'ChironGoRoundTC',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontVariations: [FontVariation('wght', 600)],
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.settingsVibrationDesc,
                            style: (theme.bodySmall ?? const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            )).copyWith(color: _trackOn),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SudaTap(
                      onTap: _isUpdating ? null : () => unawaited(_onToggleTap()),
                      child: _toggle(_isOn),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(bool isOn) {
    const thumbMargin = 2.0;
    final thumbLeft = isOn ? _trackWidth - thumbMargin - _thumbSize : thumbMargin;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: isOn ? _trackOn : _trackOff,
        borderRadius: BorderRadius.circular(_trackHeight / 2),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            left: thumbLeft,
            top: thumbMargin,
            child: Container(
              width: _thumbSize,
              height: _thumbSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
