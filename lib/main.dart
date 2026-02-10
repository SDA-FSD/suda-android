import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'services/auth_service.dart';
import 'services/token_storage.dart';
import 'services/suda_api_client.dart';
import 'services/version_check_service.dart';
import 'services/token_refresh_service.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/alarm_message.dart';
import 'screens/agreement.dart';
import 'config/app_config.dart';
import 'utils/language_util.dart';
import 'theme/app_theme.dart';
import 'widgets/main_route_aware_wrapper.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 방향을 세로로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 시스템 네비게이션 바 색상을 앱 기본 배경(#121212)과 통일
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase 초기화 (FlutterNativeSplash 이전에 실행)
  await Firebase.initializeApp();
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Navigator를 MaterialApp 빌드 전에도 접근할 수 있도록 GlobalKey 사용
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();
  
  GoogleSignInAccount? _googleUser;
  String? _accessToken;
  UserDto? _user;
  bool _isLoading = true;
  String _currentMainScreen = 'home'; // 'alarm' | 'home' | 'profile'
  int _homeTabSelectedCounter = 0; // 홈 탭 선택 시 증가 → HomeScreen 티켓 갱신
  bool _hasCheckedVersion = false; // 버전 체크 실행 여부
  bool _needsAgreement = false; // 서비스 이용 동의 필요 여부

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // initState에서는 버전 체크를 실행하지 않음
    // MaterialApp 빌드 후 builder에서 실행
  }

  @override
  void dispose() {
    TokenRefreshService.instance.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[DEBUG] lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      if (_accessToken != null) {
        debugPrint('[DEBUG] lifecycle: resumed -> refresh start');
        TokenRefreshService.instance.start();
        debugPrint('[DEBUG] lifecycle: resumed -> onAppResumed');
        TokenRefreshService.instance.onAppResumed();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      debugPrint('[DEBUG] lifecycle: stop refresh');
      TokenRefreshService.instance.stop();
    }
  }

  /// 버전 체크 후 인증 상태 확인
  Future<void> _checkVersionAndAuth() async {
    // 버전 체크 실행 (VersionCheckService 사용)
    final versionCheckPassed = await VersionCheckService.checkVersion(_navigatorKey);
    
    if (!versionCheckPassed) {
      // 버전 체크 실패 또는 강제 업데이트 필요 시 JWT 처리 진행하지 않음
      return;
    }

    // 버전 체크 통과 시 기존 JWT 처리 진행
    await _checkAuthStatus();
  }

  /// 로그인 상태 확인 및 자동 로그인 시도
  Future<void> _checkAuthStatus() async {
    // 1) 저장된 JWT 토큰 확인
    final storedAccessToken = await TokenStorage.loadAccessToken();

    // 언어 코드 저장 (앱 실행 시 항상 최신 언어 코드로 업데이트)
    final languageCode = LanguageUtil.getCurrentLanguageCode();
    await TokenStorage.saveLanguageCode(languageCode);

    if (storedAccessToken == null) {
      TokenRefreshService.instance.stop();
      // 저장된 토큰이 없으면 네이티브 스플래시 제거 후 로그아웃 상태로 진입
      FlutterNativeSplash.remove();
      setState(() {
        _accessToken = null;
        _googleUser = null;
        _user = null;
        _isLoading = false;
      });
      return;
    }

    try {
      // 2) 토큰이 유효한지 서버에서 한 번 검증
      final user = await SudaApiClient.getCurrentUser(
        accessToken: storedAccessToken,
      );

      // 3) 서비스 이용 동의 여부 확인 (SUDA_AGREEMENT == 'Y')
      bool needsAgreement = true;
      if (user.metaInfo != null) {
        for (var meta in user.metaInfo!) {
          if (meta.key == 'SUDA_AGREEMENT' && meta.value == 'Y') {
            needsAgreement = false;
            break;
          }
        }
      }

      // 4) Google 계정 정보는 UI 표시용 부가 정보 (실패해도 JWT 기반 로그인 상태는 유지)
      final account = await AuthService.signInSilently();

      // 프로필 이미지 프리캐시
      if (user.profileImgUrl != null && user.profileImgUrl!.isNotEmpty) {
        if (mounted) {
          precacheImage(NetworkImage(user.profileImgUrl!), context);
        }
      }

      // 네이티브 스플래시 제거 후 화면 전환
      FlutterNativeSplash.remove();
      TokenRefreshService.instance.start();
      setState(() {
        _accessToken = storedAccessToken;
        _googleUser = account ?? AuthService.currentUser;
        _user = user;
        _needsAgreement = needsAgreement;
        _isLoading = false;
      });
    } catch (_) {
      // 4) 401/403/기타 에러 발생 시 토큰 삭제 후 네이티브 스플래시 제거 및 로그아웃 상태로 전환
      await TokenStorage.clearTokens();
      TokenRefreshService.instance.stop();
      FlutterNativeSplash.remove();
      setState(() {
        _accessToken = null;
        _googleUser = null;
        _user = null;
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
      _googleUser = result.account;
    });

    // 2) 저장된 JWT 토큰 로드 (LoginScreen에서 이미 저장됨)
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      if (!mounted) return;
      TokenRefreshService.instance.stop();
      setState(() {
        _accessToken = null;
        _user = null;
      });
      return;
    }

    // 언어 코드 저장 (로그인 시에도 최신 언어 코드로 업데이트)
    final languageCode = LanguageUtil.getCurrentLanguageCode();
    await TokenStorage.saveLanguageCode(languageCode);

    try {
      // 3) JWT를 사용하여 사용자 정보 조회
      final user = await SudaApiClient.getCurrentUser(accessToken: token);
      if (!mounted) return;
      
      // 4) 서비스 이용 동의 여부 확인
      bool needsAgreement = true;
      if (user.metaInfo != null) {
        for (var meta in user.metaInfo!) {
          if (meta.key == 'SUDA_AGREEMENT' && meta.value == 'Y') {
            needsAgreement = false;
            break;
          }
        }
      }

      // 프로필 이미지 프리캐시
      if (user.profileImgUrl != null && user.profileImgUrl!.isNotEmpty) {
        if (mounted) {
          precacheImage(NetworkImage(user.profileImgUrl!), context);
        }
      }

      // 5) 상태 업데이트 (화면 전환 트리거)
      TokenRefreshService.instance.start();
      setState(() {
        _accessToken = token;
        _user = user;
        _needsAgreement = needsAgreement;
      });
    } catch (error) {
      // 5) 실패 시 토큰 삭제 및 로그인 상태 초기화
      await TokenStorage.clearTokens();
      TokenRefreshService.instance.stop();
      if (!mounted) return;
      setState(() {
        _accessToken = null;
        _user = null;
      });
    }
  }

  /// 로그아웃 시 호출
  void _onSignOut() {
    // UI에서는 HomeScreen/ProfileScreen -> LoginScreen 전환만 담당,
    // 실제 토큰 삭제는 ProfileScreen의 로그아웃 핸들러에서 처리.
    TokenRefreshService.instance.stop();
    setState(() {
      _googleUser = null;
      _accessToken = null;
      _currentMainScreen = 'home'; // 로그아웃 후 다시 로그인 시 Home 화면으로
    });
  }

  /// GNB를 통한 화면 전환
  void _navigateToHome() {
    setState(() {
      _currentMainScreen = 'home';
      _homeTabSelectedCounter++;
    });
  }

  /// GNB를 통한 화면 전환
  void _navigateToAlarm() {
    setState(() {
      _currentMainScreen = 'alarm';
    });
  }

  /// GNB를 통한 화면 전환
  void _navigateToProfile() {
    setState(() {
      _currentMainScreen = 'profile';
    });
  }

  /// 동의 완료 시 호출
  void _onAgreementComplete() {
    setState(() {
      _needsAgreement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routeObserver],
      title: 'SUDA',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('pt'),
      ],
      locale: Locale(LanguageUtil.getCurrentLanguageCode()),
      // MaterialApp 빌드 후 첫 프레임이 그려진 후 버전 체크 실행
      builder: (BuildContext context, Widget? child) {
        // MaterialApp이 빌드된 후 한 번만 실행
        if (!_hasCheckedVersion) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasCheckedVersion) {
              _hasCheckedVersion = true;
              _checkVersionAndAuth();
            }
          });
        }
        return child ?? const SizedBox.shrink();
      },
      theme: AppTheme.themeData,
      home: _accessToken == null
          ? LoginScreen(onSignIn: _onSignIn)
          : _needsAgreement
              ? AgreementScreen(
                  accessToken: _accessToken!,
                  onAgreementComplete: _onAgreementComplete,
                )
              : MainRouteAwareWrapper(
                  routeObserver: _routeObserver,
                  onReturnToRoute: () {
                    setState(() => _homeTabSelectedCounter++);
                  },
                  child: PopScope(
                    canPop: _currentMainScreen == 'home',
                    onPopInvokedWithResult: (bool didPop, _) {
                      if (!didPop && _currentMainScreen != 'home') {
                        setState(() {
                          _currentMainScreen = 'home';
                          _homeTabSelectedCounter++;
                        });
                      }
                    },
                    child: IndexedStack(
                      index: _currentMainScreen == 'alarm'
                          ? 0
                          : _currentMainScreen == 'home'
                              ? 1
                              : 2,
                      children: [
                        AlarmMessageScreen(
                        onNavigateToHome: _navigateToHome,
                        onNavigateToProfile: _navigateToProfile,
                        onNavigateToAlarm: _navigateToAlarm,
                        isActive: _currentMainScreen == 'alarm',
                        user: _user,
                        ),
                        HomeScreen(
                        onNavigateToAlarm: _navigateToAlarm,
                        onNavigateToProfile: _navigateToProfile,
                        user: _user,
                        homeTabSelectedCounter: _homeTabSelectedCounter,
                        ),
                        ProfileScreen(
                        onNavigateToHome: _navigateToHome,
                        onNavigateToAlarm: _navigateToAlarm,
                        onSignOut: _onSignOut,
                        user: _user,
                        onUserUpdated: (user) {
                          setState(() {
                            _user = user;
                          });
                        },
                        isActive: _currentMainScreen == 'profile',
                        ),
                      ],
                      ),
                    ),
                  ),
    );
  }
}
