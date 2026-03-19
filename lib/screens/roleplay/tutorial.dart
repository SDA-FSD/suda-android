import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/language_util.dart';
import '../../models/common_models.dart';
import '../../models/user_models.dart';

class RoleplayTutorialScreen extends StatefulWidget {
  const RoleplayTutorialScreen({super.key});

  static const String routeName = '/roleplay/tutorial';

  @override
  State<RoleplayTutorialScreen> createState() => _RoleplayTutorialScreenState();
}

class _RoleplayTutorialScreenState extends State<RoleplayTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingUser = true;
  bool _isSubmitting = false;

  static const int _totalPages = 5;

  static const List<Color> _pageColors = [
    Color(0xFF0CABA8),
    Color(0xFFFF00A6),
    Color(0xFFFFB700),
    Color(0xFF0CABA8),
    Color(0xFF8A38F5),
  ];

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkTutorialStatus() async {
    UserDto? user = RoleplayStateService.instance.user;

    if (user == null) {
      final accessToken = await TokenStorage.loadAccessToken();
      if (!mounted) return;
      if (accessToken != null) {
        try {
          user = await SudaApiClient.getCurrentUser(accessToken: accessToken);
          RoleplayStateService.instance.setUser(user);
        } catch (_) {
          // 조회 실패 시 튜토리얼 노출
        }
      }
    }

    if (!mounted) return;

    final tutorialDone = user?.metaInfo?.any(
          (m) => m.key == 'TUTORIAL' && m.value == 'Y',
        ) ??
        false;

    if (tutorialDone) {
      RoleplayRouter.replaceWithOpeningFromTutorial(context);
      return;
    }

    setState(() => _isCheckingUser = false);
  }

  String _imagePath(int pageIndex) {
    final num = pageIndex + 1;
    final lang = LanguageUtil.getCurrentLanguageCode();
    final folder = (lang == 'ko' || lang == 'pt') ? lang : 'en';
    return 'assets/images/tutorials/$folder/tutorial-$num.png';
  }

  void _updateLocalUserTutorialDone() {
    final currentUser = RoleplayStateService.instance.user;
    if (currentUser == null) return;
    final updatedMeta = [
      ...(currentUser.metaInfo ?? []).where((m) => m.key != 'TUTORIAL'),
      const SudaJson(key: 'TUTORIAL', value: 'Y'),
    ];
    RoleplayStateService.instance.setUser(
      currentUser.copyWith(metaInfo: updatedMeta),
    );
  }

  void _vibrate() {
    Vibration.vibrate(duration: 80, amplitude: 200);
  }

  void _handleTap() {
    if (_isSubmitting) return;
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleComplete();
    }
  }

  Future<void> _handleComplete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (accessToken == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await SudaApiClient.completeTutorial(accessToken: accessToken);
      if (!mounted) return;
      _updateLocalUserTutorialDone();
      RoleplayRouter.replaceWithOpeningFromTutorial(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      DefaultToast.show(context, 'Failed to save tutorial. Please try again.', isError: true);
    }
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.4),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0CABA8)),
        ),
      );
    }

    return PopScope(
      canPop: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _pageColors[_currentPage],
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildDotIndicator(),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _totalPages,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _vibrate();
                      },
                      itemBuilder: (context, index) {
                        return ColoredBox(
                          color: _pageColors[index],
                          child: Center(
                            child: Image.asset(
                              _imagePath(index),
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
