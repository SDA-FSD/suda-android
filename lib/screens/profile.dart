import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/suda_api_client.dart';
import '../utils/sub_screen_route.dart';
import '../widgets/app_scaffold.dart';
import 'setting/setting.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onSignOut;
  final UserDto? user;
  final ValueChanged<UserDto>? onUserUpdated;
  final bool isActive; // 화면 활성 상태 여부 추가
  
  const ProfileScreen({
    super.key,
    this.onNavigateToHome,
    this.onSignOut,
    this.user,
    this.onUserUpdated,
    this.isActive = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserDto? _user;
  int? _currentLevel; // 이번 단계에서는 UI에 노출하지 않음
  int? _progressPercentage; // 이번 단계에서는 UI에 노출하지 않음
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfile();
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 활성 상태로 전환될 때마다 프로필 갱신
    if (!oldWidget.isActive && widget.isActive) {
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;

      final profile = await SudaApiClient.getUserProfile(accessToken: token);
      if (!mounted) return;

      setState(() {
        _user = profile.user;
        _currentLevel = profile.currentLevel;
        _progressPercentage = profile.progressPercentage;
      });
      widget.onUserUpdated?.call(profile.user);
    } catch (e) {
      // 프로필 화면은 "자연스럽게 갱신"이 목표라, 실패 시에도 UI는 기존 메모리 값으로 유지
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      await TokenStorage.clearTokens();
      if (mounted) {
        widget.onSignOut?.call();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      SubScreenRoute(
        page: SettingScreen(
          onSignOut: _handleSignOut,
          user: _user ?? widget.user,
        ),
      ),
    );
    await _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final user = _user ?? widget.user;
    final name = user?.name ?? '';
    final profileImgUrl = user?.profileImgUrl;
    final roleplayCount = user?.roleplayCount ?? 0;
    final wordsSpokenCount = user?.wordsSpokenCount ?? 0;
    final likePoint = user?.likePoint ?? 0;

    return AppScaffold(
      showBackButton: false,
      actions: [
        GestureDetector(
          onTap: _openSettings,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/icons/header_setting.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
      ],
      usePadding: false, // 풀-폭 그라데이션을 위해 본문 패딩 제거
      bottomNavigationBar: _buildGNB(context),
      body: Stack(
        children: [
          // 1) 프로필 박스 배경 그라데이션 (상단 80 지점부터 시작)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Color(0xFF43716D),
                      Colors.black,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 2) 실제 콘텐츠
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 0), // AppScaffold의 top 80 패딩 이후 바로 시작

                // profile box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        _ProfileAvatar(profileImgUrl: profileImgUrl),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ProfileStat(
                                        title: 'Role Play',
                                        value: roleplayCount.toString(),
                                      ),
                                    ),
                                    const _ProfileStatDivider(),
                                    Expanded(
                                      child: _ProfileStat(
                                        title: 'Words',
                                        value: wordsSpokenCount.toString(),
                                      ),
                                    ),
                                    const _ProfileStatDivider(),
                                    Expanded(
                                      child: _ProfileStat(
                                        title: 'Like',
                                        value: likePoint.toString(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // progress box
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Lv. ${_currentLevel ?? 0}',
                        style: theme.labelSmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProgressBar(
                          progressPercentage: _progressPercentage ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGNB(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            border: Border(
              top: BorderSide(
                color: Colors.grey[800]!,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home 버튼 (왼쪽)
              Expanded(
                child: InkWell(
                  onTap: widget.onNavigateToHome,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Home',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
              // Profile 버튼 (오른쪽)
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
// ... (이후 클래스들 유지)
  final String? profileImgUrl;

  const _ProfileAvatar({required this.profileImgUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(4), // border thickness = 4
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF80D7CF),
                Color(0xFF43716D),
              ],
            ),
          ),
          child: ClipOval(
            child: (profileImgUrl != null && profileImgUrl!.isNotEmpty)
                ? Image.network(
                    profileImgUrl!,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: Color(0xFF1E1E1E),
                        child: Center(
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      );
                    },
                  )
                : const ColoredBox(
                    color: Color(0xFF1E1E1E),
                    child: Center(
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.bodySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.bodyMedium?.copyWith(color: const Color(0xFF80D7CF)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 44,
      color: const Color(0xFF1E1E1E),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int progressPercentage;

  const _ProgressBar({required this.progressPercentage});

  @override
  Widget build(BuildContext context) {
    final p = (progressPercentage.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            // base
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFF635F5F)),
            ),
            // progress
            FractionallySizedBox(
              widthFactor: p,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: const ColoredBox(color: Color(0xFF80D7CF)),
            ),
          ],
        ),
      ),
    );
  }
}
