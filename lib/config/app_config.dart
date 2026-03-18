/// 앱 환경 설정 클래스
/// Flutter run/build 시 --dart-define=ENV=local 형태로 전달
class AppConfig {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  
  static bool get isLocal => env == 'local';
  static bool get isDev => env == 'dev';
  static bool get isStg => env == 'stg';
  static bool get isPrd => env == 'prd';

  // 환경별 API Base URL (예시 - 실제 값으로 교체 필요)
  static String get apiBaseUrl {
    switch (env) {
      case 'local':
        // Android 에뮬레이터에서 호스트 머신의 localhost에 접속하려면 10.0.2.2 사용
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

