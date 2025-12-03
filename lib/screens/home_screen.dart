import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/suda_api_client.dart';
import '../config/app_config.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSignOut;
  final SudaUser? userInfo;
  
  const HomeScreen({
    super.key,
    this.onSignOut,
    this.userInfo,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            content: Text('로그아웃 실패: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleUser = AuthService.currentUser;
    final sudaUser = widget.userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사용자 정보 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: (sudaUser?.profileImgUrl ??
                                        googleUser?.photoUrl) !=
                                    null
                            ? NetworkImage(
                                sudaUser?.profileImgUrl ??
                                    googleUser!.photoUrl!,
                              )
                            : null,
                        child: (sudaUser?.profileImgUrl ??
                                    googleUser?.photoUrl) ==
                                null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sudaUser?.name ??
                                  googleUser?.displayName ??
                                  '사용자',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sudaUser?.email ?? googleUser?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 환경 정보 (개발용)
              if (!AppConfig.isPrd)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '환경: ${AppConfig.environmentName}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // 메인 콘텐츠 영역
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'AI와 영어로 대화하기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '곧 기능이 추가될 예정입니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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

