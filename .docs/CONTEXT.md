# Suda Application 프로젝트 컨텍스트

## 1. 프로젝트 목적
- **Flutter기반 모듈**: AI와 영어로 대화할 수 있는 교육용 애플리케이션
- **API 서버와 통신** suda-api 프로젝트에서 제공하는 API를 호출하여 동작

## 2. 개발 환경 전제 조건
- 대부분의 변경 작업 진행 시, IDE 외부에서 에뮬레이터 및 `flutter run` 상태임을 전제로 행동할 것
- **기본 테스트 디바이스**: 갤럭시 모델 (SM A305N, 디바이스 ID: R59M801MDFM)
  - 재설치 명령 시 별도 디바이스 지정이 없으면 이 디바이스에 설치
  - 재설치 명령: `adb -s R59M801MDFM install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`

## 3. 환경별 설정 관리
- **Android Flavor**: local/dev/stg/prd 환경별로 분리 관리
  - 각 환경별 패키지명: `kr.sudatalk.app.{env}` (prd는 suffix 없음)
  - 환경별 Google Client ID: `android/app/src/{env}/res/values/strings.xml`
  - 빌드 방법: `flutter run --flavor {env} -t lib/main.dart --dart-define=ENV={env}`
- **Dart 환경 설정**: `lib/config/app_config.dart`에서 환경별 설정 관리
  - 환경 변수: `--dart-define=ENV=local|dev|stg|prd` 형태로 전달
  - 환경별 API URL 등 설정값 관리
    - local: `http://10.0.2.2:8083` (Android 에뮬레이터용)
    - dev  : `https://api.dev-sudatalk.kr`
    - stg  : `https://api.stg-sudatalk.kr`
    - prd  : `https://api.sudatalk.kr`
  - 환경별 Google Server Client ID (idToken 발급용)
    - local: `558349443875-ceevp4cjf86ubp0p066qm5hsujukljg4.apps.googleusercontent.com`
    - dev  : `558349443875-ceevp4cjf86ubp0p066qm5hsujukljg4.apps.googleusercontent.com`
    - prd  : `12033207645-hemqk3f2jgbs9h883em7g6u86nilntkt.apps.googleusercontent.com`

## 4. 인증 및 API 통신
- **Google 로그인 연동**: `lib/services/auth_service.dart`
  - Google Sign-In을 통해 idToken 추출
  - `AuthService.signInWithGoogle()`: Google 로그인 및 idToken 반환
- **API 서버 연동**: `lib/services/suda_api_client.dart`
  - `SudaApiClient.loginWithGoogle()`: idToken을 서버에 전달하여 JWT 발급
  - `SudaApiClient.getCurrentUser()`: JWT를 사용하여 사용자 정보 조회 (`/users/me`)
  - JWT 토큰 저장: `lib/services/token_storage.dart` (SharedPreferences 사용)
- **사용자 정보 모델**: `SudaUser` 클래스
  - `metaInfo` 필드는 `List<SudaJson>` 타입
  - `SudaJson`: `key`, `value` 필드를 가진 구조체

## 5. 앱 아이콘 관리
- **아이콘 원본**: `assets/images/app_icon.png` (1000px 이상의 큰 크기)
- **자동 생성**: `flutter_launcher_icons` 패키지 사용
  - 설정: `pubspec.yaml`의 `flutter_launcher_icons` 섹션
  - 실행: `flutter pub run flutter_launcher_icons`
  - iOS alpha channel 자동 제거 (App Store 제출용)
  - Android, iOS, Web, Windows 모든 플랫폼 아이콘 자동 생성