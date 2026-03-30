import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'services/auth_service.dart';
import 'services/pending_app_path_service.dart';
import 'services/token_storage.dart';
import 'services/suda_api_client.dart';
import 'services/version_check_service.dart';
import 'services/token_refresh_service.dart';
import 'services/appsflyer_service.dart';
import 'services/main_user_sync.dart';
import 'screens/custom_splash.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/notification_box.dart';
import 'screens/agreement.dart';
import 'screens/roleplay/history.dart';
import 'screens/setting/setting.dart';
import 'routes/roleplay_router.dart';
import 'utils/sub_screen_route.dart';
import 'config/app_config.dart';
import 'utils/language_util.dart';
import 'theme/app_theme.dart';
import 'widgets/app_content_dialog.dart';
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
  await AppsflyerService.initialize();

  // 푸시 알림으로 앱이 켜진 경우 appPath 보관 (로그인/동의 후 Home 진입 시 적용)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage?.data != null && initialMessage!.data['appPath'] != null) {
    final path = initialMessage.data!['appPath'] as String?;
    if (path != null && path.isNotEmpty) {
      PendingAppPathService.instance.set(path);
    }
  }

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
  int _profileReturnCounter = 0; // Profile 탭 활성 상태에서 서브 스크린 pop 복귀 시 증가 → ProfileScreen 프로필 재조회
  bool _hasCheckedVersion = false; // 버전 체크 실행 여부
  bool _needsAgreement = false; // 서비스 이용 동의 필요 여부
  /// 앱 실행(토큰 없음) 시에만 true. CustomSplashScreen 표시 후 onComplete에서 false. 로그아웃 시에는 false로 곧바로 LoginScreen.
  bool _showCustomSplash = false;

  @override
  void initState() {
    super.initState();
    MainUserSync.instance.register(_onMainUserUpdatedFromSubflow);
    WidgetsBinding.instance.addObserver(this);
    // 푸시 알림 클릭(백그라운드/포그라운드) 시 appPath 보관
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final path = message.data['appPath'] as String?;
      if (path != null && path.isNotEmpty) {
        PendingAppPathService.instance.set(path);
      }
    });
    // 이미 Main이 보일 때 pending 설정되면 rebuild하여 적용 트리거
    PendingAppPathService.instance.pendingNotifier.addListener(_onPendingAppPathChanged);
    // initState에서는 버전 체크를 실행하지 않음
    // MaterialApp 빌드 후 builder에서 실행
  }

  void _onPendingAppPathChanged() {
    if (mounted) setState(() {});
  }

  bool _shouldShowReregistrationBlockedPopup(UserDto user) {
    final meta = user.metaInfo;
    if (meta == null || meta.isEmpty) return false;

    final rejected = meta.firstWhere(
      (m) => m.key == 'APPLY_REJECTED',
      orElse: () => const SudaJson(key: '', value: ''),
    );
    if (rejected.key != 'APPLY_REJECTED' || rejected.value.isEmpty) {
      return false;
    }

    try {
      final rejectedAt = DateTime.parse(rejected.value).toUtc();
      final now = DateTime.now().toUtc();
      final diff = now.difference(rejectedAt);
      return diff.inHours >= 0 && diff.inHours < 48;
    } catch (_) {
      // 파싱 실패 시 팝업 노출하지 않음
      return false;
    }
  }

  Future<void> _bestEffortLogoutSideEffects() async {
    // 서버 로그아웃은 best-effort로 시도하고, 실패해도 무시한다.
    try {
      final refreshToken = await TokenStorage.loadRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final deviceId = await TokenStorage.getDeviceId();
        await SudaApiClient.logout(
          refreshToken: refreshToken,
          deviceId: deviceId,
        );
      }
    } catch (_) {}

    // Google 로그아웃 및 로컬 토큰 삭제도 best-effort로 처리한다.
    try {
      await AuthService.signOut();
    } catch (_) {}

    try {
      await TokenStorage.clearTokens();
    } catch (_) {}

    TokenRefreshService.instance.stop();
  }

  void _onMainUserUpdatedFromSubflow(UserDto user) {
    if (!mounted) return;
    if (user.profileImgUrl != null && user.profileImgUrl!.isNotEmpty) {
      precacheImage(NetworkImage(user.profileImgUrl!), context);
    }
    setState(() => _user = user);
  }

  @override
  void dispose() {
    MainUserSync.instance.unregister();
    PendingAppPathService.instance.pendingNotifier.removeListener(_onPendingAppPathChanged);
    TokenRefreshService.instance.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_accessToken != null) {
        TokenRefreshService.instance.start();
        TokenRefreshService.instance.onAppResumed();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
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
      // 저장된 토큰이 없으면 네이티브 스플래시 제거 후 커스텀 스플래시 → 로그인 화면
      FlutterNativeSplash.remove();
      setState(() {
        _accessToken = null;
        _googleUser = null;
        _user = null;
        _isLoading = false;
        _showCustomSplash = true; // 앱 실행 시에만 커스텀 스플래시 표시
      });
      return;
    }

    try {
      // 2) 토큰이 유효한지 서버에서 한 번 검증
      final user = await SudaApiClient.getCurrentUser(
        accessToken: storedAccessToken,
      );

      // 3) 재가입 제한 여부 확인 (APPLY_REJECTED 48시간 이내)
      if (_shouldShowReregistrationBlockedPopup(user)) {
        FlutterNativeSplash.remove();
        if (!mounted) return;

        final popupContext = _navigatorKey.currentContext;
        if (popupContext != null && popupContext.mounted) {
          final l10n = AppLocalizations.of(popupContext);
          final message = l10n != null
              ? l10n.reregistrationRestrictedMessage
              : 'You can sign up again 2 days after deleting your account. Please try again later.';
          final theme = Theme.of(popupContext).textTheme;
          await AppContentDialog.show(
            popupContext,
            content: Center(
              child: Text(
                message,
                style: theme.bodyLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            showOkayButton: true,
          );
        }
        await _bestEffortLogoutSideEffects();
        if (!mounted) return;
        setState(() {
          _googleUser = null;
          _accessToken = null;
          _user = null;
          _isLoading = false;
          _showCustomSplash = true;
        });
        return;
      }

      // 4) 서비스 이용 동의 여부 확인 (SUDA_AGREEMENT == 'Y')
      bool needsAgreement = true;
      if (user.metaInfo != null) {
        for (var meta in user.metaInfo!) {
          if (meta.key == 'SUDA_AGREEMENT' && meta.value == 'Y') {
            needsAgreement = false;
            break;
          }
        }
      }

      // 5) Google 계정 정보는 UI 표시용 부가 정보 (실패해도 JWT 기반 로그인 상태는 유지)
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
      await TokenStorage.clearTokens();
      TokenRefreshService.instance.stop();
      FlutterNativeSplash.remove();
      setState(() {
        _accessToken = null;
        _googleUser = null;
        _user = null;
        _isLoading = false;
        _showCustomSplash = true;
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
      
      // 4) 재가입 제한 여부 확인 (APPLY_REJECTED 48시간 이내)
      if (_shouldShowReregistrationBlockedPopup(user)) {
        if (!mounted) return;

        final popupContext = _navigatorKey.currentContext;
        if (popupContext != null && popupContext.mounted) {
          final l10n = AppLocalizations.of(popupContext);
          final message = l10n != null
              ? l10n.reregistrationRestrictedMessage
              : 'You can sign up again 2 days after deleting your account. Please try again later.';
          final theme = Theme.of(popupContext).textTheme;
          await AppContentDialog.show(
            popupContext,
            content: Center(
              child: Text(
                message,
                style: theme.bodyLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            showOkayButton: true,
          );
        }
        await _bestEffortLogoutSideEffects();
        if (!mounted) return;
        setState(() {
          _googleUser = null;
          _accessToken = null;
          _user = null;
          _needsAgreement = false;
          _showCustomSplash = false;
        });
        return;
      }

      // 5) 서비스 이용 동의 여부 확인
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

      // 6) 상태 업데이트 (화면 전환 트리거)
      TokenRefreshService.instance.start();
      setState(() {
        _accessToken = token;
      _user = user;
      _needsAgreement = needsAgreement;
      });
    } catch (_) {
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
      _showCustomSplash = false; // 로그아웃 시 커스텀 스플래시 없이 곧바로 LoginScreen
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

  /// 푸시로 보관된 appPath를 파싱해 탭 전환 또는 Sub 스크린 push. Main(Home) 진입 후 한 번만 호출.
  void _applyPendingAppPath(String path) {
    final nav = _navigatorKey.currentState;
    final ctx = nav?.context;
    if (ctx == null || !ctx.mounted) return;

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    if (segments.length == 1) {
      switch (segments[0]) {
        case 'home':
          setState(() => _currentMainScreen = 'home');
          return;
        case 'box':
          setState(() => _currentMainScreen = 'alarm');
          return;
        case 'profile':
          setState(() => _currentMainScreen = 'profile');
          return;
      }
    }

    if (segments.length >= 2) {
      if (segments[0] == 'roleplay' &&
          segments.length >= 3 &&
          segments[1] == 'overview') {
        final id = int.tryParse(segments[2]);
        if (id != null) {
          setState(() => _currentMainScreen = 'home');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            RoleplayRouter.pushOverview(
              _navigatorKey.currentState!.context,
              id,
              user: _user,
            );
          });
          return;
        }
      }
      if (segments[0] == 'profile') {
        if (segments.length >= 2 && segments[1] == 'history' &&
            segments.length >= 3) {
          final resultId = int.tryParse(segments[2]);
          if (resultId != null) {
            setState(() => _currentMainScreen = 'profile');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final c = _navigatorKey.currentState?.context;
              if (c != null && c.mounted) {
                Navigator.push(
                  c,
                  SubScreenRoute(
                    page: HistoryScreen(resultId: resultId),
                  ),
                );
              }
            });
            return;
          }
        }
        if (segments.length >= 2 && segments[1] == 'setting') {
          setState(() => _currentMainScreen = 'profile');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final c = _navigatorKey.currentState?.context;
            if (c != null && c.mounted) {
              Navigator.push(
                c,
                SubScreenRoute(
                  page: SettingScreen(
                    onSignOut: _onSignOut,
                    user: _user,
                    onUserUpdated: (user) {
                      if (mounted) setState(() => _user = user);
                    },
                    getCurrentUser: () => _user,
                  ),
                ),
              );
            }
          });
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [
        _routeObserver,
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
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
          ? (_showCustomSplash
              ? CustomSplashScreen(
                  onComplete: () => setState(() => _showCustomSplash = false),
                )
              : LoginScreen(onSignIn: _onSignIn))
          : _needsAgreement
              ? AgreementScreen(
                  accessToken: _accessToken!,
                  onAgreementComplete: _onAgreementComplete,
                )
              : Builder(
                  builder: (_) {
                    final pending = PendingAppPathService.instance.get();
                    if (pending != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final path = PendingAppPathService.instance.take();
                        if (path != null) _applyPendingAppPath(path);
                      });
                    }
                    return MainRouteAwareWrapper(
                  routeObserver: _routeObserver,
                  onReturnToRoute: () {
                    setState(() {
                      _homeTabSelectedCounter++;
                      if (_currentMainScreen == 'profile') {
                        _profileReturnCounter++;
                      }
                    });
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
                        NotificationBoxScreen(
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
                        profileReturnCounter: _profileReturnCounter,
                        ),
                      ],
                    ),
                  ),
                );
                  },
                ),
    );
  }
}
