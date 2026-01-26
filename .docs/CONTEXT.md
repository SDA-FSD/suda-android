# Suda Application 프로젝트 컨텍스트

## 1. 프로젝트 목적
- **Flutter기반 모듈**: AI와 영어로 대화할 수 있는 교육용 애플리케이션
- **API 서버와 통신** suda-api 프로젝트에서 제공하는 API를 호출하여 동작

## 2. 개발 환경 전제 조건
- 대부분의 변경 작업 진행 시, IDE 외부에서 에뮬레이터 및 `flutter run` 상태임을 전제로 행동할 것
- **테스트 디바이스 정보**:
  - **A30** (기본 테스트 디바이스): 갤럭시 모델 (SM A305N, Android 11 / SDK 30, 디바이스 ID: R59M801MDFM)
    - 재설치 명령 시 별도 디바이스 지정이 없으면 이 디바이스에 설치
    - 재설치 명령: `adb -s R59M801MDFM install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`
  - **A23** (추가 테스트 디바이스): 갤럭시 모델 (SM A235N, Android 14 / SDK 34, 디바이스 ID: R59T901DRQV)
    - 재설치 명령: `adb -s R59T901DRQV install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`
  - **A16** (추가 테스트 디바이스): 갤럭시 모델 (Android 15 / SDK 35, 디바이스 ID: RF9XB00CX9J)
    - 재설치 명령: `adb -s RF9XB00CX9J install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`
  - **참고**: 앞으로 이 문서에서 "A30", "A23", "A16"이라는 별칭으로 각 기기를 지칭할 수 있습니다.
  - **ADB 팁**:
    - `adb`가 인식되지 않으면 `export PATH=$PATH:~/Library/Android/sdk/platform-tools`로 경로 추가
    - 다중 기기 설치 예시:
      - `adb -s R59M801MDFM install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s R59T901DRQV install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s RF9XB00CX9J install -r build/app/outputs/flutter-apk/app-dev-debug.apk`

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
  - 환경별 CDN URL 설정값 관리
    - local/dev/stg: `https://cdn.dev-sudatalk.kr`
    - prd  : `https://cdn.sudatalk.kr`
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
  - `SudaApiClient.getCurrentUser()`: JWT를 사용하여 사용자 정보 조회 (`/v1/users`)
  - `SudaApiClient.getUserProfile()`: 프로필 부가 정보 조회 (`GET /v1/users/profile`, 응답: ProfileDto(userDto, currentLevel, progressPercentage))
  - `SudaApiClient.updateName()`: 사용자 이름 변경 (`PUT /v1/users?name=...`)
  - `SudaApiClient.registerPushToken()`: 푸시 토큰 등록 (`POST /users/push-token`)
    - Request body: `{ "deviceType": "ANDROID", "pushToken": "<토큰값>", "languageCode": "en|ko|pt" }`
    - 응답 처리하지 않음 (에러 발생 시에도 무시)
  - `SudaApiClient.getHomeBanners()`: 홈 화면 배너 목록 조회 (`GET /v1/home/banners`)
    - 응답: `List<MainHomeBannerDto>` (imgPath, overlayText)
  - `SudaApiClient.getHomeRoleplayGroups()`: 홈 화면 카테고리별 롤플레이 목록 전체 조회 (`GET /v1/home/roleplays/all`)
    - 응답: `List<AppHomeRoleplayGroupDto>` (roleplayCategoryDto, list)
  - `SudaApiClient.getRoleplaysByCategory()`: 카테고리별 롤플레이 목록 페이징 조회 (`GET /v1/home/roleplays`)
    - 파라미터: `roleplayCategoryId`, `pageNum`
    - 응답: `SudaAppPage<AppHomeRoleplayDto>` (content, number, size, last, first)
  - `SudaApiClient.getRoleplayOverview()`: 롤플레이 오버뷰 조회 (`GET /v1/roleplays/{roleplayId}/overview`)
    - 응답: `RoleplayOverviewDto` (roleplay, availableRoleIds, starResultMap, similarRoleplayList)
  - `SudaApiClient.getLatestVersion()`: 최신 버전 정보 조회 (`GET /v1/latest-version`)
    - 응답: `VersionDto` (latestVersion, forceUpdateYn, androidMarketLink?, appleMarketLink?)
    - 최신 버전 정보는 `TokenStorage.saveLatestVersion()`으로 영구 저장
    - 저장된 버전 정보는 `TokenStorage.loadLatestVersion()`으로 조회 가능
- JWT 토큰 저장: `lib/services/token_storage.dart` (flutter_secure_storage 사용)
- **버전 체크 및 강제 업데이트**: `lib/services/version_check_service.dart`
  - `VersionCheckService.checkVersion()`: 앱 실행 시 최신 버전 정보 확인 및 강제 업데이트 여부 판단
  - 앱 실행 시 MaterialApp 빌드 후 첫 프레임 렌더링 완료 시점에 실행
  - 버전 체크 API 호출 성공 시 최신 버전 정보를 영구 저장 영역에 저장
  - 강제 업데이트 필요 시 (`latestVersion > appVersion && forceUpdateYn == "Y"`): 팝업 표시 후 앱 종료
  - 버전 체크 실패 시 (네트워크 에러 등): Network Error 팝업 표시 후 앱 종료
  - 버전 체크 통과 시에만 JWT 체크 진행
- **앱 다이얼로그 서비스**: `lib/services/app_dialog_service.dart`
  - `AppDialogService.showForceUpdateDialog()`: 강제 업데이트 팝업 표시
  - `AppDialogService.showNetworkErrorDialog()`: 네트워크 에러 팝업 표시
  - NavigatorKey를 사용하여 MaterialApp의 Navigator에 접근
- **언어 코드 관리**: `lib/utils/language_util.dart` 및 `lib/services/token_storage.dart`
  - 앱 실행 시 및 로그인 시 디바이스 언어 코드를 자동으로 보존 데이터 영역에 저장
  - `LanguageUtil.getCurrentLanguageCode()`: 현재 디바이스의 ISO 639-1 언어 코드 반환 (예: 'ko', 'en', 'pt')
- `TokenStorage.saveLanguageCode()`: 언어 코드 저장 (SharedPreferences 사용)
  - `TokenStorage.loadLanguageCode()`: 저장된 언어 코드 조회 (서버 API 호출 시 사용)
  - 로그아웃 시 언어 코드도 함께 삭제 (`TokenStorage.clearTokens()`)
- **사용자 정보 모델**: `UserDto` 클래스
  - `metaInfo` 필드는 `List<SudaJson>` 타입
  - `SudaJson`: `key`, `value` 필드를 가진 구조체

## 5. 앱 아이콘 관리
- **아이콘 원본**: `assets/images/app_icon.png` (1000px 이상의 큰 크기)
- **자동 생성**: `flutter_launcher_icons` 패키지 사용
  - 설정: `pubspec.yaml`의 `flutter_launcher_icons` 섹션
  - 실행: `flutter pub run flutter_launcher_icons`
  - iOS alpha channel 자동 제거 (App Store 제출용)
  - Android, iOS, Web, Windows 모든 플랫폼 아이콘 자동 생성

## 6. 스토리지 정책 (캐시 vs 보존 데이터)
- **캐시 데이터 (Cache)**
  - 정의: 서버/앱에서 언제든 다시 받을 수 있고, OS 또는 사용자가 삭제해도 문제가 없는 데이터
  - 예: 썸네일/임시 이미지, 서버에서 재다운로드 가능한 오디오(TTS 등), 일시적인 프리뷰/임시 파일
  - 저장 위치 (Android 기준): `getCacheDir()` 계열
    - Flutter: `path_provider`의 `getTemporaryDirectory()` 또는 `getApplicationCacheDirectory()` 사용
  - 삭제 정책:
    - OS/사용자/앱의 "캐시 삭제" 기능에 의해 자유롭게 삭제될 수 있음
    - 캐시 정리 시 이 영역만 정리하는 것을 원칙으로 함
  - **이미지 처리 규칙**: 이미지 관련 처리 시 캐시 사용 여부를 작업 전에 확인 요청

- **보존 데이터 (Persistent Data)**
  - 정의: 다시 얻기 어렵거나, 사용자의 자산/오프라인 사용을 위해 **의도적인 초기화 없이는 유지되어야 하는 데이터**
  - 예: 사용자 녹음 파일, 오프라인용으로 다운로드한 컨텐츠, 학습 기록, 앱 설정/선호도 등
  - 저장 위치 (Android 기준): `getFilesDir()` 계열
    - Flutter: `path_provider`의 `getApplicationDocumentsDirectory()`(파일), `SharedPreferences`(설정/작은 데이터)
  - 삭제 정책:
    - "로그아웃", "앱 초기화" 등 명시적인 액션이 있을 때에만 삭제
    - 일반적인 캐시 정리나 OS의 임의 삭제 대상이 아님

## 7. 스크린 정의

**스크린 관련 상세 정보는 `.docs/CONTEXT_SCREEN.md` 문서를 참조하세요.**

해당 문서에는 다음 정보가 포함되어 있습니다:
- 각 스크린의 정의 파일 경로 및 클래스명
- 스크린 용도 및 역할
- 이전 스크린 정보 (진입점)
- 이후 스크린 정보 (이동 가능한 다른 스크린)
- 스크린 내부 구현 특이사항
- 스크린 네비게이션 흐름도

**⚠️ 중요**: 스크린 관련 작업(추가/수정/삭제) 시 반드시 `CONTEXT_SCREEN.md` 문서도 함께 업데이트해야 합니다.

## 7-1. Roleplay 스크린 컨텍스트

- Roleplay 관련 스크린 흐름 및 데이터 정책은 `.docs/CONTEXT_ROLEPLAY.md`를 참조합니다.

## 8. 스타일 / 디자인 / 배치 규칙

- **스타일/디자인/레이아웃의 사실 기준**: `.docs/CONTEXT_STYLE.md`
  - 텍스트 타이포그래피(heading1/2/3, body, caption 등)
  - 폰트/버튼 폰트 정의 및 사용 규칙
  - 기본 배경색, 텍스트 정렬, Sub Screen 밝기 규칙 등 공통 UI 규칙
- 새로운 UI를 설계하거나 기존 화면의 스타일을 수정할 때,  
  **코드 변경과 함께 반드시 `CONTEXT_STYLE.md`도 업데이트**해야 합니다.
- **앱 전역 테마 설정**: `lib/theme/app_theme.dart`
  - MaterialApp에서 사용할 ThemeData를 정의
  - `AppTheme.themeData`를 사용하여 일관된 테마 적용

- **텍스트 언어 규칙**
  - **기본 원칙**: 사용자에게 표시되는 모든 기본 텍스트는 영어로 작성
  - **예외**: 사용자 언어에 따라 동적으로 변경되는 텍스트는 언어별 처리
    - 예: LoginScreen의 약관 문구 (`_getTermsText()` 메서드로 언어별 처리)
    - 예: SettingScreen의 약관 제목 (언어별 처리)
  - **적용 범위**: 
    - AlertDialog, SnackBar, 버튼 텍스트 등 모든 UI 텍스트
    - 에러 메시지, 알림 메시지 등
  - **주의사항**: 사용자 이름이나 동적 데이터가 포함된 메시지도 기본 언어는 영어로 작성

## 9. 앱 시작 화면 (네이티브 스플래시)
- **패키지**: `flutter_native_splash` (버전 2.3.10 이상) 사용
- **설정**: `pubspec.yaml`의 `flutter_native_splash` 섹션에서 관리
- **디자인 사양**: 로고 미표시, 어두운 배경색(`#121212`)만 노출 (Android 12+ 대응 포함)
- **생성 명령**: `dart run flutter_native_splash:create`
- **동작 방식**:
  - 앱 실행 시 네이티브 스플래시 자동 표시 (배경색만 노출)
  - `FlutterNativeSplash.preserve()`로 Flutter 엔진 초기화 후에도 유지
  - JWT 토큰 확인 및 서버 검증 완료 후 `FlutterNativeSplash.remove()` 호출
  - 네이티브 스플래시 제거 후 LoginScreen 또는 HomeScreen으로 직접 전환
- **LoadingScreen 제거**: 네이티브 스플래시가 로딩 역할을 대체하므로 Flutter LoadingScreen은 제거됨

## 10. 푸시 알림
- **Firebase Messaging**: `firebase_messaging` 패키지 사용 (버전 15.0.0 이상)
- **푸시 토큰 등록**: HomeScreen의 `initState()`에서 자동 등록
  - `_performInitialization()` 메서드에서 처리 (한 번만 실행)
  - Firebase Messaging 토큰 획득 후 서버에 전송
  - API: `POST /users/push-token` (`SudaApiClient.registerPushToken()`)
  - Request body: `{ "deviceType": "ANDROID", "pushToken": "<토큰값>" }`
  - 응답 처리하지 않음 (에러 발생 시에도 무시)
- **등록 시점**: HomeScreen 표시 시 자동 등록 (두 경로 모두 적용)
  - 경로 1: Splash > Login > Home (로그인 후)
  - 경로 2: Splash > Home (자동 로그인)
- **확장성**: `_performInitialization()` 메서드는 확장 가능한 구조로 설계
  - 향후 푸시 클릭을 통한 진입 시 타겟 스크린으로 이동 등 추가 가능

## 11. 코드 구조 및 리팩토링

- **main.dart 크기 관리**: 현재 약 227줄 (리팩토링 전 425줄)
  - 기능별로 서비스 클래스로 분리하여 유지보수성 향상
  - 다이얼로그, 버전 체크, 테마 설정 등을 별도 파일로 분리
- **서비스 클래스 구조**:
  - `lib/services/version_check_service.dart`: 버전 체크 및 강제 업데이트 로직
  - `lib/services/app_dialog_service.dart`: 앱 전역 다이얼로그 관리
  - `lib/theme/app_theme.dart`: 앱 전역 테마 설정
  - `lib/services/roleplay_state_service.dart`: Roleplay 단일 컨텍스트 보관
- **공통 UI 유틸**:
  - `lib/utils/app_toast.dart`: SnackBar 기반 토스트 공통 처리
- **리팩토링 원칙**: 
  - 단일 책임 원칙: 각 서비스는 하나의 책임만 담당
  - 재사용성: 공통 기능은 서비스로 분리하여 재사용
  - 테스트 용이성: 서비스 클래스는 독립적으로 테스트 가능
- **로깅 정책**:
  - 디버그 로그는 `debugPrint()` 사용 (Flutter 권장 방법)
  - `debugPrint()`는 릴리즈 빌드에서 자동으로 최소화되거나 제거됨
  - `print()` 대신 `debugPrint()` 사용으로 성능 및 보안 개선
  - 디버그 로그는 `[DEBUG]` 접두사를 사용하여 구분

## 12. 최근 작업 메모
- Firebase Messaging 설치 및 dev용 `google-services.json` 위치: `android/app/src/dev/google-services.json`
- 홈 화면 복구: `lib/screens/main_home.dart` 추가 (`HomeScreen` 사용)
- 빌드/설치: `flutter build apk --flavor dev --debug -t lib/main.dart --dart-define=ENV=dev` 후  
  `flutter install --use-application-binary build/app/outputs/flutter-apk/app-dev-debug.apk -d R59M801MDFM`
- 네트워크 체크 제거: 앱 실행 시 네트워크 연결 확인 로직 제거 (`lib/main.dart`의 `_ensureConnectivity()` 메서드 삭제)
- 스플래시 화면 개선: 네이티브 스플래시 활용 및 LoadingScreen 제거
  - `flutter_native_splash` 패키지 추가 및 설정
  - 네이티브 스플래시에 로고 이미지 추가
  - 네이티브 스플래시가 Flutter 엔진 초기화 및 JWT 처리 완료까지 유지
  - LoadingScreen 제거 (`lib/screens/loading_screen.dart` 삭제)
  - 네이티브 스플래시 → LoginScreen/HomeScreen 직접 전환
- 푸시 토큰 등록 기능 추가: HomeScreen 초기화 시 자동 등록
  - `HomeScreen.initState()`에서 `_performInitialization()` 호출 (한 번만 실행)
  - Firebase Messaging 토큰 획득 후 서버에 전송 (`POST /users/push-token`)
  - 확장 가능한 구조로 설계 (향후 푸시 클릭 처리 등 추가 가능)
- 화면 방향 고정: 앱 전체 방향을 세로(Portrait)로 고정
  - `lib/main.dart`: `SystemChrome.setPreferredOrientations` 적용
  - `android/app/src/main/AndroidManifest.xml`: `android:screenOrientation="portrait"` 설정
- 에셋 구조 재구성: SVG 아이콘들을 전용 폴더로 이동
  - 이동 경로: `assets/images/*.svg` -> `assets/images/icons/*.svg`
  - `pubspec.yaml`: `assets/images/icons/` 경로 추가
  - 관련 스크린 및 위젯 코드 참조 경로 업데이트 완료- ProfileScreen 레이아웃 최적화 및 오버플로우 해결
  - 고정 높이(`height: 100`) 제거 및 콘텐츠 기반 유연한 레이아웃 적용
  - `SingleChildScrollView` 도입으로 다양한 화면 크기 및 폰트 설정 대응
  - `Stack` 내 배경 그라데이션 영역 확대(100 -> 120)
- **홈 화면 배너 시스템 구축**:
  - `shimmer` 패키지 도입으로 로딩 스켈레톤 UI 구현
  - `GET /v1/home/banners` API 연동 및 무한 루프 `PageView` 배너 구현
  - 100% 너비 정사각형 형태, `BorderRadius: 20` 적용
  - 디바이스 언어 설정을 고려한 다국어 텍스트 오버레이 로직 적용- **홈 화면 카테고리별 롤플레이 목록 추가**:
  - `marquee` 패키지 도입으로 흐르는 타이틀 텍스트 구현
  - `GET /v1/home/roleplays/all` 및 `GET /v1/home/roleplays` API 연동
  - 카테고리별 가로 스크롤 리스트 및 레이지 로딩(Lazy Loading) 페이징 구현
  - 30% 너비 썸네일, radius 10, 음영 박스 오버레이 타이틀 적용
  - 카테고리명(100px) 및 썸네일 리스트에 Shimmer 로딩 스켈레톤 적용
- **메인스크린 상태 보존 및 성능 최적화**:
  - `IndexedStack` 도입으로 Home과 Profile 화면 이동 시 기존 스크롤 위치 및 상태 유지
  - Profile 화면 진입 시마다 사용자 정보를 배경에서 최신화하는 Silent Refresh 로직 구현
  - 배너 및 롤플레이 리스트의 렌더링 우선순위 최적화 (배너 완료 후 롤플레이 로드)
- 로그인 UX 개선: 로그인 성공 플로우에서는 스피너 유지, 실패 확정 시에만 로딩 종료
