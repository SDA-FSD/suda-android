import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

/// Apple 로그인 결과 (서버 `POST /v1/auth/apple` 연동용)
class AppleSignInResult {
  final String identityToken;
  final String rawNonce;
  final String? authorizationCode;
  final String? email;
  final String? fullName;

  const AppleSignInResult({
    required this.identityToken,
    required this.rawNonce,
    this.authorizationCode,
    this.email,
    this.fullName,
  });
}

/// Google / Apple 로그인 서비스
class AuthService {
  static GoogleSignIn? _googleSignInInstance;

  static GoogleSignIn get _googleSignIn {
    if (_googleSignInInstance == null) {
      _googleSignInInstance = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: AppConfig.googleIosClientId,
        serverClientId: AppConfig.googleServerClientId,
      );
    }
    return _googleSignInInstance!;
  }

  /// 현재 로그인된 Google 사용자 정보
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Google 로그인 + idToken 추출
  ///
  /// - 성공 시: [GoogleSignInResult] 반환
  /// - 사용자가 취소한 경우: null 반환
  static Future<GoogleSignInResult?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[Auth] signIn Google env=${AppConfig.env} '
          'iosClientId=${AppConfig.googleIosClientId ?? "(plist)"} '
          'serverClientId=${AppConfig.googleServerClientId}',
        );
      }

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (kDebugMode) {
        debugPrint(
          '[Auth] Google ok email=${account.email} hasIdToken=${idToken != null}',
        );
      }

      return GoogleSignInResult(
        account: account,
        idToken: idToken,
      );
    } catch (error) {
      rethrow;
    }
  }

  /// Apple 로그인 + identityToken / raw nonce 추출
  ///
  /// - 성공 시: [AppleSignInResult] 반환
  /// - 사용자가 취소한 경우: null 반환
  /// - Apple 요청 nonce: SHA-256(raw) hex / 서버 body: raw
  static Future<AppleSignInResult?> signInWithApple() async {
    if (!AppConfig.isAppleSignInSupported) {
      throw StateError(
        'Apple Sign-In is not supported for env=${AppConfig.env} '
        'platform=$defaultTargetPlatform',
      );
    }

    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    WebAuthenticationOptions? webOptions;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final clientId = AppConfig.appleServicesId;
      final redirectUri = AppConfig.appleRedirectUri;
      if (clientId == null || redirectUri == null) {
        throw StateError('Apple Android Services ID / redirectUri missing');
      }
      webOptions = WebAuthenticationOptions(
        clientId: clientId,
        redirectUri: redirectUri,
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[Auth] signIn Apple env=${AppConfig.env} '
        'platform=$defaultTargetPlatform '
        'servicesId=${AppConfig.appleServicesId ?? "(ios-native)"}',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        webAuthenticationOptions: webOptions,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw StateError('Apple identityToken is null');
      }

      final fullName = _formatAppleFullName(credential.givenName, credential.familyName);

      if (kDebugMode) {
        debugPrint(
          '[Auth] Apple ok hasEmail=${credential.email != null} '
          'hasFullName=${fullName != null}',
        );
      }

      return AppleSignInResult(
        identityToken: identityToken,
        rawNonce: rawNonce,
        authorizationCode: credential.authorizationCode,
        email: credential.email,
        fullName: fullName,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Google 로그아웃 (Apple은 클라이언트 revoke 없음 — JWT 삭제가 주)
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      rethrow;
    }
  }

  /// 현재 Google 로그인 상태 확인
  static Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// 자동 로그인 시도 (이전에 Google 로그인한 경우)
  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final GoogleSignInAccount? account =
          await _googleSignIn.signInSilently();
      return account;
    } catch (error) {
      return null;
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String? _formatAppleFullName(String? givenName, String? familyName) {
    final parts = <String>[
      if (givenName != null && givenName.trim().isNotEmpty) givenName.trim(),
      if (familyName != null && familyName.trim().isNotEmpty) familyName.trim(),
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }
}
