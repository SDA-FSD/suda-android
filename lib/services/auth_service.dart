import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Google 로그인 결과 (서버 연동용 idToken 포함)
class GoogleSignInResult {
  final GoogleSignInAccount account;
  final String? idToken;

  const GoogleSignInResult({
    required this.account,
    required this.idToken,
  });
}

/// Google 로그인 서비스
class AuthService {
  static GoogleSignIn? _googleSignInInstance;

  static GoogleSignIn get _googleSignIn {
    if (_googleSignInInstance == null) {
      _googleSignInInstance = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: AppConfig.googleServerClientId,
      );
    }
    return _googleSignInInstance!;
  }

  /// 현재 로그인된 사용자 정보
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Google 로그인 + idToken 추출
  ///
  /// - 성공 시: [GoogleSignInResult] 반환
  /// - 사용자가 취소한 경우: null 반환
  static Future<GoogleSignInResult?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 로그인 플로우를 취소한 경우
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      return GoogleSignInResult(
        account: account,
        idToken: idToken,
      );
    } catch (error) {
      // 에러는 최소한으로 로깅만 하고 상위로 전달
      print('Google Sign-In Error: $error');
      rethrow;
    }
  }

  /// Google 로그아웃
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      print('Google Sign-Out Error: $error');
      rethrow;
    }
  }

  /// 현재 로그인 상태 확인
  static Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// 자동 로그인 시도 (이전에 로그인한 경우)
  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final GoogleSignInAccount? account =
          await _googleSignIn.signInSilently();
      return account;
    } catch (error) {
      print('Silent Sign-In Error: $error');
      return null;
    }
  }
}

