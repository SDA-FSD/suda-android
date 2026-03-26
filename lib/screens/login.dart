import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../config/app_config.dart';
import '../utils/default_toast.dart';
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

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _logoSlideAnim;
  late Animation<double> _textLogoOpacityAnim;
  late Animation<double> _gradientOpacityAnim;
  late Animation<double> _bottomOpacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoSlideAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _textLogoOpacityAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    _gradientOpacityAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    _bottomOpacityAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1) Google 로그인 (idToken 포함)
      final result = await AuthService.signInWithGoogle();
      if (!mounted) {
        return;
      }
      if (result == null) {
        // 로그인 플로우가 취소됐거나 Google 페이지 진입 못한 경우
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final account = result.account;

      // 2) idToken이 없는 경우 (에뮬레이터/환경 문제 등)
      if (result.idToken == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          DefaultToast.show(context, l10n.loginErrorIdToken, isError: true);
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 3) SUDA 서버에 Google ID Token 전달 (JWT 발급 요청)
      final deviceId = await TokenStorage.getDeviceId();
      final tokens = await SudaApiClient.loginWithGoogle(
        idToken: result.idToken!,
        deviceId: deviceId,
      );

      // 4) 발급받은 SUDA JWT 토큰 저장
      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      // 5) 상위로 Google 로그인 결과 전달 (UI/상태 전환용)
      widget.onSignIn?.call(result);

      // 6) 이 시점 이후에도 LoginScreen에 머무르는 경우(에러/차단 등)를 대비해 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.loginErrorFailed(error.toString()), isError: true);
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

  Widget _buildLoginButton(double screenWidth) {
    final buttonWidth = screenWidth * 0.4;
    return _isLoading
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
          );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const backgroundColor = Color(0xFF121212);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Stack(
            children: [
              // 2-1: logo_splash 가로 중앙, 위로 300 이동 (빠른가속>늦은가속 = easeOut)
              Center(
                child: Transform.translate(
                  offset: Offset(0, -150 * _logoSlideAnim.value),
                  child: Transform.scale(
                    scale: 0.8,
                    child: Image.asset(
                      'assets/images/logo_splash.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // 2-2: logo_suda_text 가로·세로 정중앙에 fade-in
              Center(
                child: Opacity(
                  opacity: _textLogoOpacityAnim.value,
                  child: Transform.scale(
                    scale: 0.8,
                    child: Image.asset(
                      'assets/images/logo_suda_text.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // 2-3: 하단→중앙 그라데이션 fade-in
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: screenHeight * 0.5,
                child: Opacity(
                  opacity: _gradientOpacityAnim.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFF0CABA8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 2-4: 캐치프레이즈·구글 로그인·약관 fade-in (Spacer 9:문구:1:버튼:1:약관:1, 총 비율 12)
              Positioned.fill(
                child: Opacity(
                  opacity: _bottomOpacityAnim.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 9),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: Text(
                          AppLocalizations.of(context)!.loginCatchphrase,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                        ),
                      ),
                      const Spacer(flex: 1),
                      _buildLoginButton(screenWidth),
                      const Spacer(flex: 1),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: _buildTermsText(context),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
