import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/subscription_status_cache.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/sub_screen_route.dart';
import '../../widgets/app_scaffold.dart';
import '../paywall/paywall.dart';
import 'change_plan.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onSignOut;

  const AccountScreen({super.key, this.onSignOut});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  UserDto? _user;
  bool _isLoading = true;
  bool _showDeleteConfirm = false;
  bool _showDeleteProfileImgConfirm = false;
  /// 무료 사용자 Free Plan 카드.
  bool _showFreePlanCard = false;
  /// 구독 활성 Premium 카드.
  bool _showPremiumCard = false;
  DateTime? _subscriptionExpiredAt;

  // 애니메이션 관련
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // 편집 관련 상태
  bool _isEditing = false;
  late TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();
  String _currentIcon = 'assets/images/icons/edit.svg';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    unawaited(_loadUserInfo());
    unawaited(_refreshSubscriptionStatus());

    // 애니메이션 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );

    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        setState(() {
          _isEditing = true;
          _onNameChanged(_nameController.text);
        });
      } else {
        if (_isEditing) {
          _handleUpdateName();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        final user = await SudaApiClient.getCurrentUser(accessToken: token);
        if (!mounted) return;
        setState(() {
          _user = user;
          _nameController.text = user.name ?? '';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshSubscriptionStatus() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;
      final energy = await SudaApiClient.getUserEnergy(accessToken: token);
      if (!mounted) return;
      final subscribed = SubscriptionStatusCache.isSubscribedActive;
      setState(() {
        _showFreePlanCard = !subscribed;
        _showPremiumCard = subscribed;
        _subscriptionExpiredAt = energy.subscriptionExpiredAt;
      });
    } catch (_) {
      // 실패 시 기존 노출 상태 유지
    }
  }

  Future<void> _onFreePlanTap() async {
    final subscribed = await PaywallScreen.push<bool>(context);
    if (!mounted || subscribed != true) return;
    await _refreshSubscriptionStatus();
  }

  void _onChangePlanTap() {
    Navigator.of(context).push(
      SubScreenRoute(page: const ChangePlanScreen()),
    );
  }

  /// en/ko: yyyy/MM/dd, pt: dd/MM/yyyy (로컬 시각).
  String _formatRenewDate(DateTime utc, String languageCode) {
    final local = utc.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    if (languageCode == 'pt') return '$d/$m/$y';
    return '$y/$m/$d';
  }

  Future<void> _handleUpdateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _currentIcon = 'assets/images/icons/red_x.svg');
      return;
    }
    if (newName == _user?.name) {
      setState(() {
        _isEditing = false;
        _currentIcon = 'assets/images/icons/edit.svg';
      });
      return;
    }
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateName(accessToken: token, name: newName);
        await _loadUserInfo();
        setState(() {
          _isEditing = false;
          _currentIcon = 'assets/images/icons/edit.svg';
        });
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Failed to update name: $e', isError: true);
      }
    }
  }

  void _onNameChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() => _currentIcon = 'assets/images/icons/red_x.svg');
    } else {
      setState(() => _currentIcon = 'assets/images/icons/check_mint.svg');
    }
  }

  /// 삭제 확인 모달 열기
  void _openDeleteConfirm() {
    setState(() => _showDeleteConfirm = true);
    _animationController.forward();
  }

  /// 삭제 확인 모달 닫기
  void _closeDeleteConfirm() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _showDeleteConfirm = false);
      }
    });
  }

  void _openDeleteProfileImgConfirm() {
    setState(() => _showDeleteProfileImgConfirm = true);
    _animationController.forward();
  }

  void _closeDeleteProfileImgConfirm() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _showDeleteProfileImgConfirm = false);
      }
    });
  }

  Future<void> _handleDeleteProfileImage() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;

      await SudaApiClient.deleteProfileImage(accessToken: token);
      await _loadUserInfo();
      if (mounted) _closeDeleteProfileImgConfirm();
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Failed to delete profile image: $e', isError: true);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        final refreshToken = await TokenStorage.loadRefreshToken();
        if (refreshToken != null) {
          try {
            final deviceId = await TokenStorage.getDeviceId();
            await SudaApiClient.logout(
              refreshToken: refreshToken,
              deviceId: deviceId,
            );
          } catch (_) {
            // 서버 로그아웃 실패 시에도 로컬 토큰은 삭제
          }
        }
        // (1) 서버 요청은 날리고 기다리지 않음 (Fire-and-forget)
        SudaApiClient.deleteUser(accessToken: token).catchError((e) {
        });
        
        // (2) 로컬 데이터 즉시 정리
        await TokenStorage.clearTokens();
        await AuthService.signOut();
        
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        if (mounted) {
          // (3) 상태를 먼저 로그아웃으로 변경하여 MaterialApp의 home이 LoginScreen을 가리키게 함
          widget.onSignOut?.call();
          
          // (4) 그 다음 모든 서브 화면을 닫음
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const AppScaffold(
        centerTitle: '',
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (_nameFocusNode.hasFocus) _nameFocusNode.unfocus();
          },
          child: AppScaffold(
            centerTitle: l10n.settingsAccount,
            resizeToAvoidBottomInset: false,
            body: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                final hasImage = _user?.profileImgUrl != null &&
                                    _user!.profileImgUrl!.isNotEmpty;
                                if (!hasImage) return;
                                _openDeleteProfileImgConfirm();
                              },
                              child: ClipOval(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[800],
                                    image: (_user?.profileImgUrl != null &&
                                            _user!.profileImgUrl!.isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(_user!.profileImgUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage(
                                            image: AssetImage(
                                              'assets/images/icons/default_profile_image.png',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: (_user?.profileImgUrl != null &&
                                          _user!.profileImgUrl!.isNotEmpty)
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Container(
                                              color: const Color(0x80121212), // #121212 @ 50%
                                            ),
                                            Center(
                                              child: Image.asset(
                                                'assets/images/icons/square_x.png',
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(l10n.accountName, style: theme.headlineMedium?.copyWith(color: const Color(0xFF0CABA8))),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => _nameFocusNode.requestFocus(),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF353535),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
          children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      focusNode: _nameFocusNode,
                                      onChanged: _onNameChanged,
                                      onSubmitted: (_) => _nameFocusNode.unfocus(),
                                      style: theme.headlineSmall?.copyWith(color: Colors.white),
                                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (!_nameFocusNode.hasFocus) {
                                        _nameFocusNode.requestFocus();
                                      } else if (_currentIcon == 'assets/images/icons/check_mint.svg') {
                                        _nameFocusNode.unfocus();
                                      }
                                    },
                                    child: SvgPicture.asset(_currentIcon, width: 24, height: 24),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(l10n.accountInfo, style: theme.headlineMedium?.copyWith(color: const Color(0xFF0CABA8))),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_user?.email ?? '', style: theme.bodyLarge?.copyWith(color: Colors.white)),
                          ),
                          if (_showFreePlanCard || _showPremiumCard) ...[
                            const SizedBox(height: 32),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.accountSubscription,
                                style: theme.headlineMedium?.copyWith(
                                  color: const Color(0xFF0CABA8),
                                  // height 1.2면 일부 글리프 하단이 잘려 보임
                                  height: 1.40,
                                ),
                              ),
                            ),
                            if (_showPremiumCard) ...[
                              // 이름/계정과 동일: 구독↔카드 24.
                              // Change Plan은 그 간격 안 하단 우측(카드와 bottom 12).
                              SizedBox(
                                height: 24,
                                width: double.infinity,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      right: 8,
                                      bottom: 12,
                                      child: GestureDetector(
                                        onTap: _onChangePlanTap,
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              l10n.accountChangePlan,
                                              style: theme.bodySmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontVariations: const [
                                                  FontVariation('wght', 700),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Image.asset(
                                              'assets/images/icons/closing_angle_bracket.png',
                                              height: 13,
                                              fit: BoxFit.fitHeight,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF353535),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/icons/premium_verified_badge.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.accountPremiumTitle,
                                            style: theme.headlineSmall
                                                ?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.accountPremiumSubtitle,
                                            style: theme.bodySmall?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          if (_subscriptionExpiredAt !=
                                              null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.accountPremiumRenewsOn(
                                                _formatRenewDate(
                                                  _subscriptionExpiredAt!,
                                                  Localizations.localeOf(
                                                    context,
                                                  ).languageCode,
                                                ),
                                              ),
                                              style: theme.bodySmall?.copyWith(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 24),
                              if (_showFreePlanCard)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => unawaited(_onFreePlanTap()),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF353535),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/icons/check_green.svg',
                                            width: 24,
                                            height: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.accountFreePlanTitle,
                                                  style: theme.headlineSmall
                                                      ?.copyWith(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  l10n.accountFreePlanSubtitle,
                                                  style: theme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Image.asset(
                                            'assets/images/icons/closing_angle_bracket.png',
                                            height: 13,
                                            fit: BoxFit.fitHeight,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 44),
                            child: GestureDetector(
                              onTap: _openDeleteConfirm,
                              child: Center(
                                child: Text(l10n.accountDelete, style: theme.bodySmall?.copyWith(color: Colors.white54)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 계정 삭제 확인 레이어
        if (_showDeleteConfirm) ...[
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _closeDeleteConfirm,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
                child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      Text(l10n.accountDeleteTitle, style: theme.headlineMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.accountDeleteConfirmText,
                          textAlign: TextAlign.center,
                          style: theme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _closeDeleteConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CABA8),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(l10n.accountGoBack, style: theme.bodyLarge?.copyWith(color: Colors.white)),
                      ),
                      const SizedBox(height: 60),
                      GestureDetector(
                        onTap: _handleDeleteAccount,
                        child: Text(
                          l10n.accountDeleteAction,
                          style: theme.bodySmall?.copyWith(color: const Color(0xFFFF0000)),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],

        // 프로필 이미지 삭제 확인 레이어 (계정 삭제 레이어와 동일 형태, 문구/동작만 변경)
        if (_showDeleteProfileImgConfirm) ...[
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _closeDeleteProfileImgConfirm,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        l10n.accountDeleteProfileImageTitle,
                        style: theme.headlineMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.accountDeleteProfileImageContent,
                          textAlign: TextAlign.center,
                          style: theme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _closeDeleteProfileImgConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CABA8),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.accountGoBack,
                          style: theme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 60),
                      GestureDetector(
                        onTap: _handleDeleteProfileImage,
                        child: Text(
                          l10n.accountDeleteAction,
                          style: theme.bodySmall?.copyWith(color: const Color(0xFFFF0000)),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
