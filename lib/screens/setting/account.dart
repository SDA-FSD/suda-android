import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_scaffold.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../services/auth_service.dart';
import '../../utils/default_toast.dart';

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
    _loadUserInfo();
    
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
        setState(() {
          _user = user;
          _nameController.text = user.name ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[800],
                                image: _user?.profileImgUrl != null && _user!.profileImgUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_user!.profileImgUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _user?.profileImgUrl == null || _user!.profileImgUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 60, color: Colors.white54)
                                  : null,
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
      ],
    );
  }
}
