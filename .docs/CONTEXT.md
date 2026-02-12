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
  - **Q51** (추가 테스트 디바이스): LM-Q510N (Android 11 / SDK 30, 디바이스 ID: LMQ510NDYLFEIQCL76)
    - 재설치 명령: `adb -s LMQ510NDYLFEIQCL76 install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`
  - **S8** (추가 테스트 디바이스): 갤럭시 모델 (SM G955N, Android 9 / SDK 28, 디바이스 ID: ce041714d2f6348e0d)
    - 재설치 명령: `adb -s ce041714d2f6348e0d install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`
  - **참고**: 앞으로 이 문서에서 "A30", "A23", "A16", "Q51", "S8"이라는 별칭으로 각 기기를 지칭할 수 있습니다.
  - **ADB 팁**:
    - `adb`가 인식되지 않으면 `export PATH=$PATH:~/Library/Android/sdk/platform-tools`로 경로 추가
    - 다중 기기 설치 예시:
      - `adb -s R59M801MDFM install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s R59T901DRQV install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s RF9XB00CX9J install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s LMQ510NDYLFEIQCL76 install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s ce041714d2f6348e0d install -r build/app/outputs/flutter-apk/app-dev-debug.apk`

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
- **API 서버 연동**: `lib/api/suda_api_client.dart`
  - 구현 분리 구조:
    - HTTP/refresh 공통: `lib/api/client/suda_http_client.dart`
    - 도메인별 엔드포인트: `lib/api/endpoints/*`
    - DTO/모델: `lib/models/*`
  - 기존 경로 호환: `lib/services/suda_api_client.dart`는 re-export용 래퍼
  - `SudaApiClient.loginWithGoogle()`: idToken과 deviceId를 서버에 전달하여 JWT 발급
  - `SudaApiClient.refreshToken()`: refreshToken과 deviceId로 JWT 갱신 (rotate 반영)
  - `SudaApiClient.logout()`: refreshToken과 deviceId로 서버 로그아웃 통지
  - `SudaApiClient.getCurrentUser()`: JWT를 사용하여 사용자 정보 조회 (`/v1/users`)
  - `SudaApiClient.getUserProfile()`: 프로필 부가 정보 조회 (`GET /v1/users/profile`, 응답: ProfileDto(userDto, currentLevel, progressPercentage))
  - `SudaApiClient.getUserTicket()`: 티켓 개수 조회 (`GET /v1/users/ticket`, 파라메터 없음, 응답: UserTicketDto(beforeTicketCount, finalTicketCount))
  - `SudaApiClient.getRoleplayResults()`: 롤플레이 결과 목록 페이징 (`GET /v1/roleplays/results?pageNum=0`, 0-based, 9개씩, 응답: SudaAppPage\<RpSimpleResultDto\>, RpSimpleResultDto: resultId, imgPath, starResult, createdAt)
  - `SudaApiClient.updateName()`: 사용자 이름 변경 (`PUT /v1/users?name=...`)
  - `SudaApiClient.registerPushToken()`: 푸시 토큰 등록 (`POST /users/push-token`)
    - Request body: `{ "deviceType": "ANDROID", "pushToken": "<토큰값>", "languageCode": "en|ko|pt" }`
    - 응답 처리하지 않음 (에러 발생 시에도 무시)
  - `SudaApiClient.getHomeBanners()`: 홈 화면 배너 목록 조회 (`GET /v1/home/banners`)
    - 응답: `List<MainHomeBannerDto>` (imgPath, overlayText)
  - `SudaApiClient.getLatestVersion()`: 최신 버전 정보 조회 (`GET /v1/latest-version`)
    - 응답: `VersionDto` (latestVersion, forceUpdateYn, androidMarketLink?, appleMarketLink?)
    - 최신 버전 정보는 `TokenStorage.saveLatestVersion()`으로 영구 저장
    - 저장된 버전 정보는 `TokenStorage.loadLatestVersion()`으로 조회 가능
- JWT 토큰 저장: `lib/services/token_storage.dart` (flutter_secure_storage 사용)
- deviceId 저장: `TokenStorage.getDeviceId()`로 최초 1회 생성 후 secure storage에 영구 보관
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
  - 주요 필드: `provider`, `sub`, `name`, `email`, `profileImgUrl`
  - 통계 필드: `roleplayCount`, `wordsSpokenCount`, `likePoint`
  - `firstLoginYn` 필드는 최초 로그인 여부 표기
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
- Roleplay 세션 `sessionId`는 인메모리 공통 상태로 보관하고 롤플레이 종료 시 삭제됩니다.

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

- **공통 콘텐츠 팝업 (AppContentDialog)**: `lib/widgets/app_content_dialog.dart`
  - 재사용: `AppContentDialog.show(context, content: Widget, { showOkayButton, onOkayPressed, barrierDismissible })`. 본문은 `content`에 위젯으로 전달(여러 스타일 텍스트·버튼·클릭 가능 텍스트 등).
  - 배경: 노출 중 하단 화면 터치 불가. 배경 레이어는 GNB와 동일 수치(BackdropFilter sigma 6 + Color 0x598C8C8C).
  - 팝업 카드: 가로 60%·최소 세로 50% 디스플레이, 테두리 10·#80D7CF·radius 30, 내부 상단 30 패딩·14×14 `close.svg` 우측(탭 시 닫힘), 본문 좌우 30·하단 30 마진. 옵션으로 하단 테두리 아래 30 마진 뒤 "Okay" 버튼(높이 44, 가로 40%, #0CABA8, StadiumBorder, ElevatedButton) 노출 가능.

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
- **푸시 알림 클릭 시 스크린 이동 (appPath)**:
  - FCM data payload에 `appPath`(문자열)를 넣으면, 알림 클릭 시 해당 경로의 스크린으로 이동한다.
  - **비로그인·동의 전**: appPath는 `PendingAppPathService`에 보관되며, 로그인·동의 완료 후 Home 진입 시 한 번 적용된다.
  - **이미 Main(Home) 진입 후**: 백그라운드에서 알림 클릭 시에도 동일하게 pending에 넣고, 다음 프레임에 적용한다.
  - 지원 경로·정의·신규 스크린 시 확인 절차는 `.docs/CONTEXT_SCREEN.md`의 **appPath (푸시 딥링크 경로)** 섹션을 따른다.

## 11. 코드 구조 및 리팩토링

- **main.dart 크기 관리**: 현재 약 227줄 (리팩토링 전 425줄)
  - 기능별로 서비스 클래스로 분리하여 유지보수성 향상
  - 다이얼로그, 버전 체크, 테마 설정 등을 별도 파일로 분리
- **서비스 클래스 구조**:
  - `lib/services/version_check_service.dart`: 버전 체크 및 강제 업데이트 로직
  - `lib/services/app_dialog_service.dart`: 앱 전역 다이얼로그 관리
  - `lib/theme/app_theme.dart`: 앱 전역 테마 설정
  - `lib/services/token_refresh_service.dart`: Access Token 선제 갱신 타이머 및 동시 refresh 단일화
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
  - 디바이스 언어 설정을 고려한 다국어 텍스트 오버레이 로직 적용
- **메인스크린 상태 보존 및 성능 최적화**:
  - `IndexedStack` 도입으로 Home과 Profile 화면 이동 시 기존 스크롤 위치 및 상태 유지
  - Profile 화면 진입 시마다 사용자 정보를 배경에서 최신화하는 Silent Refresh 로직 구현
  - 배너 및 롤플레이 리스트의 렌더링 우선순위 최적화 (배너 완료 후 롤플레이 로드)
- 로그인 UX 개선: 로그인 성공 플로우에서는 스피너 유지, 실패 확정 시에만 로딩 종료
- Roleplay Playing 헤더 우측 속도 슬라이더 UI 및 speed-rate API 연동 추가
- Roleplay Playing 하단 녹음 영역 UI 정비: 서비스메시지(20) + 녹음버튼(120) 구조 및 상태 테스트 플로우 추가
- Roleplay Playing 본문 영역에 AI 시작 메시지 UI/타이핑 구조 추가 (CDN/byte 음성 처리 포함)
- Roleplay Playing 나레이션 fade-in 노출 및 사용자 턴 활성화 처리 추가
- Roleplay Playing 사용자 턴 입력 처리(녹음/타이핑, 말풍선 누적, 짧은 녹음 안내) 추가
- Roleplay Playing 번역 인덱스/번역 토글 및 미션 실패 처리 추가
- Roleplay Playing 힌트 아이콘 동작 개선: 힌트 탭 시 API 호출·힌트 말풍선(점선 테두리·투명·흰글씨), 턴당 1회·중복 비활성화, 3초 유휴 시 500ms 깜빡임, user-message 생성 시 힌트 말풍선 제거
- Roleplay Playing resultId 종료 분기·Result API·캐시·종료 메시지: `.docs/CONTEXT_ROLEPLAY.md` 6-5, 6-9, 7, 10 참조 (상세는 해당 문서에만 정리)
- **GNB 3탭 전환**: NotificationBoxScreen(구 AlarmMessageScreen)을 Sub → Main Screen으로 변경, GNB 구성을 Alarm / Home / Profile 3탭으로 확장. HomeScreen 우측 상단 Info 아이콘(Alarm push) 제거, GNB Alarm 탭으로만 알림함(Notification Box) 접근. `.docs/CONTEXT_SCREEN.md` 참조.
- **GNB 오버레이·블러**: GNB는 본문 위에 덮는 형태로 배치(AppScaffold Stack 하단 Positioned). 배경은 playing 슬라이더와 동일: BackdropFilter sigma 6 + Color(0x598C8C8C).
- **GNB 아이콘화**: GNB 메뉴 3종을 텍스트에서 아이콘으로 전환. 공통 위젯 `lib/widgets/gnb_bar.dart`(GnbBar). Alarm: gnb_alarm.png / gnb_alarm_pressed.png, 높이 24, 좌측 33. Home: gnb_home.png / gnb_home_pressed.png, 너비 24, 정중앙. Profile: userDto.profileImgUrl 원형 28x28(비활성)·24x24+흰 테두리 2(활성), 우측 33. 탭 영역: 좌 30% / 중앙 30% / 우 30%.
- **Roleplay Ending 스크린 개선**: 닫기 버튼 없음. role.endingList 첫 요소(RoleplayEndingDto) 기반 title/content/이미지. Playing에서 ending 전환 확정 시 imgPath+CDN으로 이미지 preload. 이미지 있으면 1.5x→1x 2초 축소 후 80% 검정 레이어·콘텐츠 fade-in; 없으면 바로 레이어·콘텐츠. 상단 50% title+content, 하단 50% endingHowWas+별 5개(40×40 gap 5)+Next 버튼. Next 탭 시 버튼 텍스트 fade-out과 동시에 버튼에서 #0CABA8 풍선 확장(2s) 후 Result 전환. `PUT /v1/roleplays/results/{rpResultId}?star={star}` 호출(응답 무시). Result 진입 시 박스레이어에 별점·mainTitle·subTitle 순차 노출(각 300ms 후) 후 박스 축소. 본문레이어 추후 지침. `.docs/CONTEXT_SCREEN.md` 14·17, `.docs/CONTEXT_ROLEPLAY.md` 참조.
- **RoleplayResultDto·Result 스크린 박스레이어**: DTO에 mainTitle·subTitle 필드 추가(서버 non-null). Result 박스레이어: 별점·mainTitle·subTitle 순차 노출 후 박스 축소. **Result 본문레이어**: like_at_result·likePoint(그라데이션)·Mission(missionResult 아이콘)·Words·Lv 프로그레스바(getUserProfile)·Good Points·To Improve·Got it! 버튼(Overview). `.docs/CONTEXT_SCREEN.md` §17 참조.
- **Main Screen 물리 뒤로가기**: Home 탭에서만 앱 종료, Alarm/Profile 탭에서는 Home으로 이동. `lib/main.dart`에서 IndexedStack을 `PopScope`(canPop: home일 때만 true)로 감싸 처리. `.docs/CONTEXT_SCREEN.md` Main Screen·비교표 반영.
- **Profile 롤플레이 히스토리**: Progress box 아래 세로 스크롤 영역에 롤플레이 결과 썸네일 그리드. `GET /v1/roleplays/results?pageNum=0` 페이징(0부터 9개씩), 3열 32%·CDN prepend·캐시·shimmer 로딩·스크롤 시 append. 썸네일 탭 시 HistoryScreen(Sub) 진입(resultId 전달). History에서 ReviewChatScreen/ReviewEndingScreen 진입. 상세는 `.docs/CONTEXT_SCREEN.md` §19·20·21.
- **신규 스크린 (History·Review)**: HistoryScreen(Profile 진입, 롤플레이 결과 요약·Result 유사), ReviewChatScreen(History 진입, 채팅 열람), ReviewEndingScreen(History 진입, 엔딩 열람·Ending 유사). 파일: `lib/screens/roleplay/history.dart`, `review_chat.dart`, `review_ending.dart`.
- **HistoryScreen 구현**: resultId로 `getRoleplayResult`·`getUserProfile` 조회 후 스크린 상태로만 보관(RoleplayStateService 미사용). History↔ReviewChat/ReviewEnding 구간 동안 동일 result 유지, 나갈 때·새 진입 시 갱신. Result와 동일 레이아웃(박스 210·본문), 초기 애니메이션 없음. Got it 버튼 노출만(동작 없음), Report 문구 없음. View Chat 탭 시 ReviewChatScreen에 RoleplayResultDto 전달하여 진입.
- **RoleplayResultDto**: 응답에 `avatarImgPath` 포함(Review Chat에서 AI 아바타 표시용). 내부 모델은 subTitle 다음에 avatarImgPath 필드.
- **ReviewChatScreen 구현**: History에서 RoleplayResultDto 전달받아 채팅 이력 표시. 헤더 중앙 "Chat History"(Setting 계열 스타일), 좌상단 뒤로가기(header_arrow_back). chatHistory는 List\<SudaJson\>이며 key로 발화자 구분(USER / AI_CHARACTER / AI_NARRATOR / SYSTEM_MISSION), value를 그대로 표시. Playing과 동일 말풍선·나레이션·미션 배치 및 스타일(사용자 우측 흰색, AI 좌측 티얼+avatarImgPath 아바타, 나레이션/미션 중앙).
- **ReviewEndingScreen 구현**: History "View Ending" 탭 시 `GET /v1/roleplays/{rpId}/roles/{rpRoleId}/endings/{endingId}` 호출, 응답 RoleplayEndingDto·이미지 프리로드 후 진입(버튼에 Opening과 동일 뱅글 로딩). Sub Screen. 헤더 "View Ending"+뒤로가기. 본문: 이미지(BoxFit.cover·높이 100%·비율 유지·좌우 잘림 가능) → 2s 후 레이어·타이틀(상단 25%)·콘텐츠(하단 75%) 페이드인. 버튼 없음.
- **엔딩 API**: `SudaApiClient.getRoleplayEnding(accessToken, rpId, rpRoleId, endingId)` → RoleplayEndingDto.
- **세션 초기화 티켓 부족**: Opening→Playing 세션 초기화(`POST /v1/roleplay-sessions`) 200 응답에서 `sessionId`가 '0'인 경우 티켓 부족으로 간주, 얼럿 "(임시)no tickets" 후 Opening 유지. `.docs/CONTEXT_ROLEPLAY.md` 6-3 참조.
- **홈 화면 티켓 배지**: 상단 우측에 티켓 아이콘(`assets/images/icons/ticket.png` 38×20) + finalTicketCount 표시(body-caption 흰색). 앱 구동 후 첫 노출 시·GNB 홈 탭 선택 시·물리 뒤로가기로 홈 복귀 시·**서브 스크린에서 pop으로 복귀 시** `GET /v1/users/ticket` 갱신. 서브 복귀 감지는 `RouteObserver` + `MainRouteAwareWrapper`(lib/widgets/main_route_aware_wrapper.dart)의 `didPopNext`로 처리. 감소 시 즉시 치환, 증가 시 500ms 내 단계 증가 + 단계마다 `Vibration.vibrate(duration: 80)` (Result 스크린과 동일).
- **앱 버전 1.0.1**: `pubspec.yaml` 1.0.1+2, `AppConfig.appVersion` 1.0.1. Setting 화면 하단: 개인정보·이용약관·오픈소스 블록 위로 조정, 그 아래 버전 텍스트 `v x.x.x` (fontSize 11, 흰색, 중앙 정렬) 노출.
- **푸시 appPath 연동**: FCM data에 `appPath` 포함 시 알림 클릭 후 해당 스크린으로 이동. 비로그인/미동의 시 `PendingAppPathService`에 보관, Home 진입 시 적용. 지원 경로·정의는 `.docs/CONTEXT_SCREEN.md` appPath 섹션. `lib/services/pending_app_path_service.dart`, `main.dart`(getInitialMessage·onMessageOpenedApp·_applyPendingAppPath).

## 13. 리팩토링 계획 문서
- 롤플레이 기능 준비를 위한 리팩토링 작업 분해 문서는 `REFACTOR.md`에 기록
