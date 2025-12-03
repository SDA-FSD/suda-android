import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  /// Google 로그인 성공 시 호출되는 콜백
  /// - [GoogleSignInResult.account]: Google 계정 정보
  /// - [GoogleSignInResult.idToken]: 서버 연동용 idToken (null 가능)
  final Function(GoogleSignInResult)? onSignIn;
  
  const LoginScreen({super.key, this.onSignIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 터미널 로그로도 흐름을 확인
      // ignore: avoid_print
      print('Login button tapped (env=${AppConfig.env})');

      // 1) Google 로그인 (idToken 포함)
      final result = await AuthService.signInWithGoogle();
      if (result == null || !mounted) {
        // 로그인 플로우가 취소됐거나 Google 페이지 진입 못한 경우
        // ignore: avoid_print
        print('GoogleSignIn returned null (user canceled or flow not started)');
        return;
      }

      final account = result.account;

      // 터미널에 GoogleSignIn 결과 정보 출력
      // ignore: avoid_print
      print('GoogleSignInResult: account=${account.email}, idToken=${result.idToken}');

      // 2) idToken이 없는 경우 (에뮬레이터/환경 문제 등)
      if (result.idToken == null) {
        // 터미널에서도 원인 파악할 수 있도록 로그
        // ignore: avoid_print
        print('Google ID Token is null; serverClientId / Web Client ID 설정 확인 필요');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google ID Token을 가져오지 못했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 3) SUDA 서버에 Google ID Token 전달 (JWT 발급 요청)
      // ignore: avoid_print
      print('Posting ID Token to /api/app/v1/auth/google...');
      final tokens = await SudaApiClient.loginWithGoogle(
        idToken: result.idToken!,
      );

      // 4) 발급받은 SUDA JWT 토큰 저장
      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      // 5) 상위로 Google 로그인 결과 전달 (UI/상태 전환용)
      widget.onSignIn?.call(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account.displayName}님, 환영합니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error, stackTrace) {
      // 터미널 로그로도 원인을 확인할 수 있도록 출력
      // ignore: avoid_print
      print('Login failed: $error');
      // ignore: avoid_print
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 로고 또는 타이틀
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Suda',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI와 함께하는 영어 대화',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                // 환경 표시 (개발용)
                if (!AppConfig.isPrd)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppConfig.environmentName,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 48),
                // Google 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              // Google 로고 이미지가 없으면 아이콘 사용
                              return const Icon(
                                Icons.login,
                                size: 24,
                                color: Colors.white,
                              );
                            },
                          ),
                    label: Text(
                      _isLoading ? '로그인 중...' : 'Google로 로그인',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
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

