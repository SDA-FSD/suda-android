import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../widgets/onboarding_step_bar.dart';
import '../widgets/user_profile_avatar.dart';
import 'tutorial/tutorial_intro_stage.dart';

/// 온보딩(meta `ONBOARDING_USERNAME` != Y)의 이름 확인·수정 Full Screen.
class FirstUsernameScreen extends StatefulWidget {
  final UserDto? user;
  final void Function(UserDto? updatedUser) onComplete;
  final bool preview;

  const FirstUsernameScreen({
    super.key,
    this.user,
    required this.onComplete,
    this.preview = false,
  });

  @override
  State<FirstUsernameScreen> createState() => _FirstUsernameScreenState();
}

class _FirstUsernameScreenState extends State<FirstUsernameScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF121212);
  static const _hintColor = Color(0xFF8C8C8C);
  static const _fieldColor = Color(0xFF353535);
  static const _fieldHeight = 56.0;
  static const _avatarGap = 16.0;
  static const _keyboardAvatarSize = 48.0;
  static const _animationDuration = Duration(milliseconds: 300);

  late final TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();
  late final AnimationController _toIntro;
  bool _isSubmitting = false;
  bool _transitioning = false;
  UserDto? _completedUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _toIntro = AnimationController(
      vsync: this,
      duration: TutorialIntroStage.duration,
    );
    _toIntro.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete(_completedUser);
      }
    });
  }

  @override
  void dispose() {
    _toIntro.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      !_transitioning &&
      _nameController.text.trim().isNotEmpty;

  String get _displayName {
    final fromField = _nameController.text.trim();
    final raw = (_completedUser?.name ??
            (fromField.isNotEmpty ? fromField : widget.user?.name?.trim())) ??
        '';
    if (raw.isEmpty) return 'Friend';
    return raw;
  }

  String? get _imgPath => _completedUser?.imgPath ?? widget.user?.imgPath;

  Future<void> _playTransitionToIntro(UserDto? updated) async {
    _completedUser = updated ??
        widget.user?.copyWith(name: _nameController.text.trim());
    setState(() => _transitioning = true);
    await _toIntro.forward(from: 0);
  }

  Future<void> _onConfirm() async {
    if (!_canSubmit) return;
    _nameFocusNode.unfocus();
    if (widget.preview) {
      await _playTransitionToIntro(
        widget.user?.copyWith(name: _nameController.text.trim()) ??
            UserDto(id: 0, name: _nameController.text.trim()),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    var saved = false;
    UserDto? updated;
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateName(
          accessToken: token,
          name: _nameController.text.trim(),
        );
        saved = true;
        unawaited(_postOnboardingUsernameBestEffort(token));
        try {
          updated = await SudaApiClient.getCurrentUser(accessToken: token);
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.requestFailed, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (saved) {
          await _playTransitionToIntro(updated);
        }
      }
    }
  }

  Future<void> _postOnboardingUsernameBestEffort(String accessToken) async {
    try {
      await SudaApiClient.postOnboardingUsername(accessToken: accessToken);
    } catch (_) {
      // best-effort: ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = keyboardInset > 0 && !_transitioning;
    // 키보드와 무관하게 상단 1/3 고정 → 타이틀이 진행 막대에 붙지 않음.
    final titleBandHeight = screenHeight / 3;

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
          if (!_transitioning) _nameFocusNode.unfocus();
        },
        child: Scaffold(
          backgroundColor: _backgroundColor,
          resizeToAvoidBottomInset: false,
          body: AnimatedBuilder(
            animation: _toIntro,
            builder: (context, _) {
              final t = _toIntro.value;
              final restOpacity = _transitioning
                  ? TutorialIntroStage.restOpacity(t)
                  : 1.0;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: restOpacity,
                    child: IgnorePointer(
                      ignoring: _transitioning,
                      child: withOnboardingStepBar(
                        step: 4,
                        body: Column(
                          children: [
                            SizedBox(
                              height: titleBandHeight,
                              child: _buildTopSection(l10n, theme),
                            ),
                            Expanded(
                              child: AnimatedPadding(
                                duration: _animationDuration,
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.only(
                                  bottom: isKeyboardVisible
                                      ? keyboardInset + 16
                                      : 0,
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: _buildNameSection(
                                        theme,
                                        isKeyboardVisible,
                                        hideAvatar: _transitioning,
                                      ),
                                    ),
                                    if (isKeyboardVisible)
                                      _buildActions(l10n, theme)
                                    else
                                      Expanded(
                                        child: _buildBottomSection(l10n, theme),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_transitioning)
                    TutorialIntroStage(
                      progress: t,
                      displayName: _displayName,
                      imgPath: _imgPath,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(AppLocalizations l10n, TextTheme theme) {
    return onboardingTitle(l10n.firstUsernameTitle, theme);
  }

  /// 아바타 + 이름 필드(하단 정렬). 키보드 시 아바타만 48·좌측.
  /// 전환 중에는 스테이지 아바타만 쓰므로 여기 아바타는 숨긴다.
  Widget _buildNameSection(
    TextTheme theme,
    bool isKeyboardVisible, {
    bool hideAvatar = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxAvatarSize =
            constraints.maxHeight - _fieldHeight - _avatarGap;
        final fullAvatarSize =
            maxAvatarSize.clamp(0.0, constraints.maxWidth * 0.5);
        final avatarSize =
            isKeyboardVisible ? _keyboardAvatarSize : fullAvatarSize;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedAlign(
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                alignment: isKeyboardVisible
                    ? AlignmentDirectional.centerStart
                        .resolve(Directionality.of(context))
                    : Alignment.center,
                child: AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeOutCubic,
                  width: avatarSize,
                  height: avatarSize,
                  child: hideAvatar
                      ? const SizedBox.shrink()
                      : LayoutBuilder(
                          builder: (context, box) {
                            if (box.maxWidth < 2) {
                              return const SizedBox.shrink();
                            }
                            return UserProfileAvatar(
                              imgPath: widget.user?.imgPath,
                              isPremium: false,
                              size: box.maxWidth,
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: _avatarGap),
              _buildNameField(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameField(TextTheme theme) {
    return GestureDetector(
      onTap: () => _nameFocusNode.requestFocus(),
      child: Container(
        width: double.infinity,
        height: _fieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _nameFocusNode.unfocus(),
                textInputAction: TextInputAction.done,
                style: theme.headlineSmall?.copyWith(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/images/icons/edit.svg',
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 힌트 + Confirm. 키보드 위·하단 밴드 공통.
  Widget _buildActions(AppLocalizations l10n, TextTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.firstCefrLevelSettingsHint,
            style: theme.labelSmall?.copyWith(
              color: _hintColor,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _canSubmit ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.6),
                disabledForegroundColor: Colors.black.withOpacity(0.6),
                elevation: 0,
                shape: const StadiumBorder(),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(l10n.actionConfirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(AppLocalizations l10n, TextTheme theme) {
    return Column(
      children: [
        const Expanded(child: SizedBox.shrink()),
        Expanded(child: Center(child: _buildActions(l10n, theme))),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
