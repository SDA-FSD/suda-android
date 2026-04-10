import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../../l10n/app_localizations.dart';
import '../../models/common_models.dart';
import '../../models/user_models.dart';
import '../../services/token_storage.dart';
import '../../services/suda_api_client.dart';
import '../../widgets/app_scaffold.dart';
import '../../utils/default_toast.dart';

class PushAgreementScreen extends StatefulWidget {
  final UserDto? user;
  final ValueChanged<UserDto>? onUserUpdated;

  const PushAgreementScreen({super.key, this.user, this.onUserUpdated});

  @override
  State<PushAgreementScreen> createState() => _PushAgreementScreenState();
}

class _PushAgreementScreenState extends State<PushAgreementScreen> {
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
    _isOn = _initialOnFromUser(widget.user);
  }

  /// metaInfo PUSH_AGREEMENT == 'Y'인 경우만 ON, 그 외 OFF
  static bool _initialOnFromUser(UserDto? user) {
    if (user?.metaInfo == null) return false;
    for (final meta in user!.metaInfo!) {
      if (meta.key == 'PUSH_AGREEMENT' && meta.value == 'Y') return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return AppScaffold(
      centerTitle: l10n.settingsNotification,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: _boxBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 제목: body-default급 강조 (ChironGoRoundTC 18 w600)
                      Text(
                        l10n.pushNotifications,
                        style: const TextStyle(
                          fontFamily: 'ChironGoRoundTC',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontVariations: [FontVariation('wght', 600)],
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 설명: body-caption (14 w400), theme 상 bodySmall
                      Text(
                        l10n.pushNotificationsDesc,
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
                GestureDetector(
                  onTap: _isUpdating ? null : _onToggleTap,
                  child: _buildToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    const thumbMargin = 2.0;
    final thumbLeft = _isOn ? _trackWidth - thumbMargin - _thumbSize : thumbMargin;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: _isOn ? _trackOn : _trackOff,
        borderRadius: BorderRadius.circular(_trackHeight / 2),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            left: thumbLeft,
            top: (_trackHeight - _thumbSize) / 2,
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

  Future<void> _onToggleTap() async {
    if (_isUpdating) return;
    final nextOn = !_isOn;

    // OFF → ON: OS 알림 권한 확인 후 막혀 있으면 권한 모달 표시, PUT 생략
    if (nextOn) {
      final granted = await Permission.notification.isGranted;
      if (!granted) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showNotificationPermissionDialog(l10n: l10n);
        }
        return;
      }
    }

    setState(() => _isUpdating = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        if (mounted) {
          setState(() => _isUpdating = false);
          DefaultToast.show(context, 'Authentication required.');
        }
        return;
      }
      final result = await SudaApiClient.updatePushAgreement(
        accessToken: token,
        agreementYn: nextOn ? 'Y' : 'N',
      );
      if (mounted) {
        Vibration.vibrate(duration: 80);
        setState(() {
          _isOn = nextOn;
          _isUpdating = false;
        });
        _updateAppUserMetaInfo(nextOn);
        if (result.completeYn == 'Y') {
          final l10n = AppLocalizations.of(context)!;
          DefaultToast.show(context, l10n.surveySuccessToast);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        DefaultToast.show(
          context,
          'Failed to update: $e',
          isError: true,
        );
      }
    }
  }

  void _showNotificationPermissionDialog({required AppLocalizations l10n}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationPermissionBlockedTitle),
        content: Text(l10n.notificationPermissionBlockedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.accountGoBack),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  void _updateAppUserMetaInfo(bool pushAgreementOn) {
    final user = widget.user;
    if (user == null || widget.onUserUpdated == null) return;
    final value = pushAgreementOn ? 'Y' : 'N';
    final existing = user.metaInfo ?? [];
    final updated = <SudaJson>[];
    var found = false;
    for (final meta in existing) {
      if (meta.key == 'PUSH_AGREEMENT') {
        updated.add(SudaJson(key: 'PUSH_AGREEMENT', value: value));
        found = true;
      } else {
        updated.add(meta);
      }
    }
    if (!found) {
      updated.add(SudaJson(key: 'PUSH_AGREEMENT', value: value));
    }
    widget.onUserUpdated!(user.copyWith(metaInfo: updated));
  }
}
