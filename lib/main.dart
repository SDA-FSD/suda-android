import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_service.dart';
import 'services/token_storage.dart';
import 'services/suda_api_client.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'config/app_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoogleSignInAccount? _currentUser;
  String? _accessToken;
  SudaUser? _currentUserInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// 로그인 상태 확인 및 자동 로그인 시도
  Future<void> _checkAuthStatus() async {
    // 1) 저장된 JWT 토큰 확인
    final storedAccessToken = await TokenStorage.loadAccessToken();

    if (storedAccessToken == null) {
      // 저장된 토큰이 없으면 바로 로그아웃 상태로 진입
      setState(() {
        _accessToken = null;
        _currentUser = null;
        _currentUserInfo = null;
        _isLoading = false;
      });
      return;
    }

    try {
      // 2) 토큰이 유효한지 서버에서 한 번 검증
      final user = await SudaApiClient.getCurrentUser(
        accessToken: storedAccessToken,
      );

      // 3) Google 계정은 부가 정보용 (없어도 로그인 상태로 간주 가능)
      final account = await AuthService.signInSilently();

      setState(() {
        _accessToken = storedAccessToken;
        _currentUser = account ?? AuthService.currentUser;
        _currentUserInfo = user;
        _isLoading = false;
      });
    } catch (_) {
      // 4) 401/403/기타 에러 발생 시 토큰 삭제 후 로그아웃 상태로 전환
      await TokenStorage.clearTokens();
      setState(() {
        _accessToken = null;
        _currentUser = null;
        _currentUserInfo = null;
        _isLoading = false;
      });
    }
  }

  /// 로그인 성공 시 호출
  /// 
  /// Google 로그인 후 JWT 토큰을 로드하고 사용자 정보를 조회한 뒤 화면 전환
  Future<void> _onSignIn(GoogleSignInResult result) async {
    // 1) Google 계정 정보 저장
    setState(() {
      _currentUser = result.account;
    });

    // 2) 저장된 JWT 토큰 로드 (LoginScreen에서 이미 저장됨)
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _accessToken = null;
        _currentUserInfo = null;
      });
      return;
    }

    try {
      // 3) JWT를 사용하여 사용자 정보 조회
      final user = await SudaApiClient.getCurrentUser(accessToken: token);
      if (!mounted) return;
      
      // 4) 상태 업데이트 (화면 전환 트리거)
      setState(() {
        _accessToken = token;
        _currentUserInfo = user;
      });
    } catch (error) {
      // 5) 실패 시 토큰 삭제 및 로그인 상태 초기화
      await TokenStorage.clearTokens();
      if (!mounted) return;
      setState(() {
        _accessToken = null;
        _currentUserInfo = null;
      });
      // 에러 로그 출력
      print('Failed to get user info after login: $error');
    }
  }

  /// 로그아웃 시 호출
  void _onSignOut() {
    // UI에서는 HomeScreen -> LoginScreen 전환만 담당,
    // 실제 토큰 삭제는 HomeScreen의 로그아웃 핸들러에서 처리.
    setState(() {
      _currentUser = null;
      _accessToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUDA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const LoadingScreen()
          : _accessToken == null
              ? LoginScreen(onSignIn: _onSignIn)
              : HomeScreen(
                  onSignOut: _onSignOut,
                  userInfo: _currentUserInfo,
                ),
    );
  }
}
