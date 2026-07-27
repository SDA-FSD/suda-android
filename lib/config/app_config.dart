import 'package:flutter/foundation.dart';

/// 앱 환경 설정 클래스
/// Flutter run/build 시 --dart-define=ENV=local 형태로 전달
class AppConfig {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  static const String _iosLocalApiUrl = String.fromEnvironment(
    'IOS_LOCAL_API_URL',
    defaultValue: 'http://localhost:8083',
  );
  
  static bool get isLocal => env == 'local';
  static bool get isDev => env == 'dev';
  static bool get isStg => env == 'stg';
  static bool get isPrd => env == 'prd';

  // 환경별 API Base URL (예시 - 실제 값으로 교체 필요)
  static String get apiBaseUrl {
    switch (env) {
      case 'local':
        // iOS Simulator는 localhost, 실기기는 IOS_LOCAL_API_URL로 Mac의
        // LAN/.local 주소를 전달한다. Android Emulator는 10.0.2.2를 사용한다.
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return _iosLocalApiUrl;
        }
        return 'http://10.0.2.2:8083';
      case 'dev':
        return 'https://api.dev-sudatalk.kr';
      case 'stg':
        return 'https://api.stg-sudatalk.kr';
      case 'prd':
        return 'https://api.sudatalk.kr';
      default:
        return 'http://localhost:8083';
    }
  }

  // 환경별 CDN Base URL
  static String get cdnBaseUrl {
    switch (env) {
      case 'local':
      case 'dev':
      case 'stg':
        return 'https://cdn.dev-sudatalk.kr';
      case 'prd':
        return 'https://cdn.sudatalk.kr';
      default:
        return 'https://cdn.dev-sudatalk.kr';
    }
  }

  // 환경 이름
  static String get environmentName {
    switch (env) {
      case 'local':
        return 'Local';
      case 'dev':
        return 'Development';
      case 'stg':
        return 'Staging';
      case 'prd':
        return 'Production';
      default:
        return 'Unknown';
    }
  }

  static String? get googleServerClientId {
    switch (env) {
      case 'local':
        return '558349443875-ceevp4cjf86ubp0p066qm5hsujukljg4.apps.googleusercontent.com';
      case 'dev':
        return '558349443875-ceevp4cjf86ubp0p066qm5hsujukljg4.apps.googleusercontent.com';
      case 'prd':
        return '841694444330-g8gn852m4somers2668v46k3mm69p7dg.apps.googleusercontent.com';
      default:
        return null;
    }
  }

}

