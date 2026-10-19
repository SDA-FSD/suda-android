import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../utils/default_toast.dart';
import 'tutorial_intro_stage.dart';

/// 온보딩 Username 다음. 프로필·문구·Start Tutorial → 마이크 권한 → Tutorial Roleplay.
class TutorialIntroScreen extends StatefulWidget {
  final UserDto? user;
  final VoidCallback onStartTutorial;
  final bool preview;

  /// Username Confirm 전환을 이미 재생했으면 false(최종 프레임부터).
  final bool playEntrance;

  const TutorialIntroScreen({
    super.key,
    this.user,
    required this.onStartTutorial,
    this.preview = false,
    this.playEntrance = true,
  });

  @override
  State<TutorialIntroScreen> createState() => _TutorialIntroScreenState();
}

class _TutorialIntroScreenState extends State<TutorialIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _requestingMic = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: TutorialIntroStage.duration,
    );
    if (widget.playEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entrance.forward();
      });
    } else {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  String get _displayName {
    final raw = widget.user?.name?.trim() ?? '';
    if (raw.isEmpty) return 'Friend';
    return raw;
  }

  Future<bool> _ensureMicrophonePermission(BuildContext context) async {
    var status = await Permission.microphone.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }
    }

    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.microphonePermissionDenied),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.accountGoBack),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    DefaultToast.show(context, l10n.microphonePermissionDenied);
    return false;
  }

  Future<void> _onStartTutorial() async {
    if (_requestingMic) return;
    setState(() => _requestingMic = true);
    final ok = await _ensureMicrophonePermission(context);
    if (!mounted) return;
    setState(() => _requestingMic = false);
    if (!ok) return;
    widget.onStartTutorial();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.preview,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: AnimatedBuilder(
          animation: _entrance,
          builder: (context, _) {
            return TutorialIntroStage(
              progress: _entrance.value,
              displayName: _displayName,
              imgPath: widget.user?.imgPath,
              onStartTutorial: _onStartTutorial,
              startLoading: _requestingMic,
            );
          },
        ),
      ),
    );
  }
}
