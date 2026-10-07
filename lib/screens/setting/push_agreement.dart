import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
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
import '../../utils/language_util.dart';

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
  bool _categoriesReady = false;
  int _categoryLoadGen = 0;
  bool _practiceOn = true;
  bool _energyOn = true;
  bool _learningOn = true;
  bool _newsOn = true;
  bool _rankingOn = true;
  bool _socialOn = true;

  @override
  void initState() {
    super.initState();
    _isOn = _initialOnFromUser(widget.user);
    unawaited(_loadCategories());
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
        child: Column(
          children: [
            _buildBlock(
              theme: theme,
              title: l10n.pushNotifications,
              description: l10n.pushNotificationsDesc,
              isOn: _isOn,
              onTap: _isUpdating ? null : _onToggleTap,
            ),
            if (_categoriesReady) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: Color(0xFF353535)),
              const SizedBox(height: 8),
              IgnorePointer(
                ignoring: !_isOn,
                child: AnimatedOpacity(
                  opacity: _isOn ? 1 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
              _buildBlock(
                theme: theme,
                title: l10n.pushPracticeReminders,
                description: l10n.pushPracticeRemindersDesc,
                isOn: _practiceOn,
                onTap: !_isOn || _isUpdating
                    ? null
                    : () => _onCategoryTap(
                          current: _practiceOn,
                          apply: (next) => _practiceOn = next,
                          practiceRemindersYn: _yn(!_practiceOn),
                        ),
              ),
              _buildBlock(
                theme: theme,
                title: l10n.pushEnergyUpdates,
                description: l10n.pushEnergyUpdatesDesc,
                isOn: _energyOn,
                onTap: !_isOn || _isUpdating
                    ? null
                    : () => _onCategoryTap(
                          current: _energyOn,
                          apply: (next) => _energyOn = next,
                          energyUpdatesYn: _yn(!_energyOn),
                        ),
              ),
              _buildBlock(
                theme: theme,
                title: l10n.pushLearningUpdates,
                description: l10n.pushLearningUpdatesDesc,
                isOn: _learningOn,
                onTap: !_isOn || _isUpdating
                    ? null
                    : () => _onCategoryTap(
                          current: _learningOn,
                          apply: (next) => _learningOn = next,
                          learningUpdatesYn: _yn(!_learningOn),
                        ),
              ),
              _buildBlock(
                theme: theme,
                title: l10n.pushNewsEvents,
                description: l10n.pushNewsEventsDesc,
                isOn: _newsOn,
                onTap: !_isOn || _isUpdating
                    ? null
                    : () => _onCategoryTap(
                          current: _newsOn,
                          apply: (next) => _newsOn = next,
                          newsEventsYn: _yn(!_newsOn),
                        ),
              ),
              _buildBlock(
                theme: theme,
                title: l10n.pushRankingUpdates,
                description: l10n.pushRankingUpdatesDesc,
                isOn: _rankingOn,
                onTap: !_isOn || _isUpdating
                    ? null
                    : () => _onCategoryTap(
                          current: _rankingOn,
                          apply: (next) => _rankingOn = next,
                          rankingUpdatesYn: _yn(!_rankingOn),
                        ),
              ),
              _buildBlock(
                theme: theme,
                title: l10n.pushSocialUpdates,
                description: l10n.pushSocialUpdatesDesc,
                isOn: _socialOn,
                onTap: !_isOn || _isUpdating
                    ? null
                    : () => _onCategoryTap(
                          current: _socialOn,
                          apply: (next) => _socialOn = next,
                          socialUpdatesYn: _yn(!_socialOn),
                        ),
              ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlock({
    required TextTheme theme,
    required String title,
    required String description,
    required bool isOn,
    required VoidCallback? onTap,
  }) {
    return Container(
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
                  Text(
                    title,
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
                    description,
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
              onTap: onTap,
              child: _buildToggle(isOn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(bool isOn) {
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
      final granted = await _isOsNotificationAllowed();
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
        if (nextOn && Platform.isIOS) {
          unawaited(_registerIosPushTokenIfPossible());
        }
        if (result.completeYn == 'Y') {
          Navigator.of(context).pop(true);
          return;
        }
        if (nextOn && !_categoriesReady) {
          unawaited(_loadCategories());
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

  Future<void> _loadCategories() async {
    final gen = ++_categoryLoadGen;
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null || !mounted || gen != _categoryLoadGen) return;
      final dto = await SudaApiClient.getPushAgreement(accessToken: token);
      if (!mounted || gen != _categoryLoadGen) return;
      setState(() {
        _practiceOn = dto.practiceRemindersYn == 'Y';
        _energyOn = dto.energyUpdatesYn == 'Y';
        _learningOn = dto.learningUpdatesYn == 'Y';
        _newsOn = dto.newsEventsYn == 'Y';
        _rankingOn = dto.rankingUpdatesYn == 'Y';
        _socialOn = dto.socialUpdatesYn == 'Y';
        _categoriesReady = true;
      });
    } catch (e) {
      if (!mounted || gen != _categoryLoadGen) return;
      DefaultToast.show(
        context,
        'Failed to update: $e',
        isError: true,
      );
    }
  }

  Future<void> _onCategoryTap({
    required bool current,
    required void Function(bool next) apply,
    String? practiceRemindersYn,
    String? energyUpdatesYn,
    String? learningUpdatesYn,
    String? newsEventsYn,
    String? rankingUpdatesYn,
    String? socialUpdatesYn,
  }) async {
    if (!_isOn || _isUpdating) return;
    final next = !current;
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
      await SudaApiClient.updatePushCategories(
        accessToken: token,
        practiceRemindersYn: practiceRemindersYn,
        energyUpdatesYn: energyUpdatesYn,
        learningUpdatesYn: learningUpdatesYn,
        newsEventsYn: newsEventsYn,
        rankingUpdatesYn: rankingUpdatesYn,
        socialUpdatesYn: socialUpdatesYn,
      );
      if (mounted) {
        Vibration.vibrate(duration: 80);
        setState(() {
          apply(next);
          _isUpdating = false;
        });
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

  String _yn(bool on) => on ? 'Y' : 'N';

  /// iOS: `permission_handler` 알림 매크로가 꺼져 있어 `Permission.notification`이
  /// 항상 denied. Home과 같이 FCM settings를 쓴다. AOS는 기존 POST_NOTIFICATIONS.
  Future<bool> _isOsNotificationAllowed() async {
    if (Platform.isIOS) {
      final messaging = FirebaseMessaging.instance;
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await messaging.requestPermission();
      }
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return Permission.notification.isGranted;
  }

  /// iOS ON 직후 FCM 토큰을 한 번 더 올린다. Home 등록이 APNs 타이밍으로
  /// 빈 토큰일 수 있음. 실토큰이 있을 때만 POST(빈 값으로 덮어쓰지 않음). AOS 없음.
  Future<void> _registerIosPushTokenIfPossible() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return;
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (await messaging.getAPNSToken() == null) {
        if (!DateTime.now().isBefore(deadline)) return;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      final pushToken = await messaging.getToken();
      if (pushToken == null || pushToken.isEmpty) return;
      final access = await TokenStorage.loadAccessToken();
      if (access == null) return;
      await SudaApiClient.registerPushToken(
        accessToken: access,
        pushToken: pushToken,
        languageTag: LanguageUtil.getCurrentLanguageTag(),
      );
    } catch (_) {}
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
