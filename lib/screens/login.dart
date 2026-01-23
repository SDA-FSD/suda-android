import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../config/app_config.dart';
import '../utils/language_util.dart';
import 'webview_screen.dart';

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
      // 1) Google 로그인 (idToken 포함)
      final result = await AuthService.signInWithGoogle();
      if (result == null || !mounted) {
        // 로그인 플로우가 취소됐거나 Google 페이지 진입 못한 경우
        return;
      }

      final account = result.account;

      // 2) idToken이 없는 경우 (에뮬레이터/환경 문제 등)
      if (result.idToken == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.loginErrorIdToken),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 3) SUDA 서버에 Google ID Token 전달 (JWT 발급 요청)
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
    } catch (error, stackTrace) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginErrorFailed(error.toString())),
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

  /// 약관 문구 위젯 빌드
  Widget _buildTermsText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final template = l10n.loginTermsTemplate(l10n.loginTermsTitle, l10n.loginPrivacyTitle);
    final termsText = l10n.loginTermsTitle;
    final privacyText = l10n.loginPrivacyTitle;
    
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.bodySmall?.copyWith(
      color: Colors.white,
    ) ?? const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    );

    // 텍스트를 {terms}와 {privacy} 기준으로 분리
    // ARB 파일에서 사용된 placeholder 이름을 기준으로 분할
    final parts = template.split(RegExp(RegExp.escape(termsText) + r'|' + RegExp.escape(privacyText)));
    final linkColor = const Color(0xFF80D7CF);

    // 이용약관 링크 recognizer
    final termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              url: 'https://sudatalk.kr/public/app/terms',
              title: termsText,
            ),
          ),
        );
      };

    // 개인정보처리방침 링크 recognizer
    final privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              url: 'https://sudatalk.kr/public/app/privacy',
              title: privacyText,
            ),
          ),
        );
      };

    return RichText(
      textAlign: TextAlign.center,
      softWrap: true,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: parts[0]), // 첫 번째 부분
          TextSpan(
            text: termsText,
            style: baseStyle.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: termsRecognizer,
          ),
          TextSpan(text: parts[1]), // 중간 부분
          TextSpan(
            text: privacyText,
            style: baseStyle.copyWith(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: privacyRecognizer,
          ),
          if (parts.length > 2) TextSpan(text: parts[2]), // 마지막 부분
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.4; // 디바이스 너비의 40%

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 상단 여백 (로고를 중앙에 배치하기 위한 공간)
          const Spacer(),
          const Spacer(),
          const Spacer(),
          // 로고 (디바이스 가로 크기의 50%, 비율 유지)
          Image.asset(
            'assets/images/logo_3d.png',
            width: screenWidth * 0.5,
            fit: BoxFit.contain,
          ),
          // 하단 여백의 1/3
          const Spacer(),
          // 로그인 버튼 (첫 번째 구분지점)
          _isLoading
              ? SizedBox(
                  width: buttonWidth,
                  height: 50,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _handleGoogleSignIn,
                  child: SizedBox(
                    width: buttonWidth,
                    height: 50,
                    child: Image.asset(
                      'assets/images/android_dark_rd_SI.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.login,
                            size: 24,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
          // 하단 여백의 1/3
          const Spacer(),
          // 약관 문구 (두 번째 구분지점, 중앙 정렬, 흰색 글씨, 좌우 20% 마진)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.2),
            child: _buildTermsText(context),
          ),
          // 하단 여백의 1/3
          const Spacer(),
        ],
      ),
    );
  }
}
