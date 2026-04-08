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
  - prd  : `841694444330-g8gn852m4somers2668v46k3mm69p7dg.apps.googleusercontent.com`

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
    - 메인 라우트가 서브에서 pop으로 다시 보일 때 `lib/main.dart` `_syncUserOnMainRouteReturn`에서 호출해 `_user` 전역 동기화(GNB·탭 공통). 레벨·진행률은 `getUserProfile`이 담당.
  - `SudaApiClient.getUserProfile()`: 프로필 부가 정보 조회 (`GET /v1/users/profile`, 응답: ProfileDto(userDto, currentLevel, progressPercentage))
  - `SudaApiClient.getUserTicket()`: 티켓 개수 조회 (`GET /v1/users/ticket`, 파라메터 없음, 응답: UserTicketDto(beforeTicketCount, finalTicketCount, dailyTicketGrantYn?)). `dailyTicketGrantYn == 'Y'`이면 HomeScreen에서 출석 보상 팝업 노출.
  - `SudaApiClient.claimDailyTicket()`: 데일리 티켓 수령 (`PUT /v1/users/tickets/daily`, 응답: QuestResultDto). `completeYn == 'Y'`이면 `surveySuccessToast` 노출 + 티켓 재조회.
  - `SudaApiClient.getRoleplayResults()`: 롤플레이 결과 목록 페이징 (`GET /v1/roleplays/results?pageNum=0`, 0-based, 9개씩, 응답: SudaAppPage\<RpSimpleResultDto\>, RpSimpleResultDto: resultId, imgPath, starResult, createdAt)
  - `SudaApiClient.getRoleplayResultReload()`: 운영자용 리프레시 테스트 (`GET /v1/roleplays/results-reload/{resultId}`, 2xx 시 RoleplayResultDto 반환, 그 외 null. History 상단 별 탭 시 호출)
  - `SudaApiClient.updateName()`: 사용자 이름 변경 (`PUT /v1/users?name=...`)
  - `SudaApiClient.registerPushToken()`: 푸시 토큰 등록 (`POST /users/push-token`)
    - Request body: `{ "deviceType": "ANDROID", "pushToken": "<토큰값>", "languageCode": "en|ko|pt" }`
    - 응답 처리하지 않음 (에러 발생 시에도 무시)
  - `SudaApiClient.getHomeContents()`: 홈 화면 콘텐츠 통합 조회 (`GET /v1/home/contents`)
    - 응답: `HomeDto` (restYn, restStartsAt, restEndsAt, banners, roleplays)
    - banners: `List<MainHomeBannerDto>` (imgPath, overlayText)
    - roleplays: `List<AppHomeRoleplayGroupDto>` (roleplayCategoryDto, list)
    - restYn/restStartsAt/restEndsAt은 `RestStatusService.instance`에 저장 (어떤 스크린에서도 접근 가능)
  - `SudaApiClient.getLatestVersion()`: 최신 버전 정보 조회 (`GET /v1/latest-version`)
    - 응답: `VersionDto` (latestVersion, forceUpdateYn, androidMarketLink?, appleMarketLink?)
    - 최신 버전 정보는 `TokenStorage.saveLatestVersion()`으로 영구 저장
    - 저장된 버전 정보는 `TokenStorage.loadLatestVersion()`으로 조회 가능
- **RestStatusService**: `lib/services/rest_status_service.dart`
  - 서비스 점검 대응용 restYn, restStartsAt, restEndsAt 전역 보관
  - `GET /v1/home/contents` 응답 시 `RestStatusService.instance.update()`로 초기화/업데이트
  - 어떤 스크린에서도 `RestStatusService.instance.restYn` 등으로 접근 가능
  - `shouldShowRestOverlay()`: Overview 진입 전 휴식 레이어 노출 여부 (restYn=='Y' 또는 N이면서 UTC now가 restStartsAt~restEndsAt 사이)
- **휴식 안내 레이어 (RestOverlay)**: `lib/widgets/rest_overlay.dart`
  - Overview 진입 시 `RoleplayRouter.pushOverview`에서 restYn 확인 후, 필요 시 레이어 노출·스크린 이동 중단
  - 배경: BackdropFilter sigma 6 + Color(0x59000000) (오버레이 공통)
  - 닫기: close.svg 24×24, 좌상 30,30, 40×40 탭 영역
  - 콘텐츠 영역: width 80%, height width×1.2+60, 중앙
  - 이미지: rest_full_layer_pt.png (pt) / rest_full_layer_en.png, radius 50, border 12 #80D7CF, 외곽 40px 그라데이션
  - 타이틀: "THE REST DAY" h1 검정, 80D7CF 배경, 높이 60, 반원
  - 타이머: restEndsAt 있을 때만, 0CABA8 배경, HH:MM:SS 카운트다운, 매 초 갱신
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
  - 재사용: `AppContentDialog.show(context, content: Widget, { showOkayButton, okayButtonLabel, onOkayPressed, barrierDismissible })`. 본문은 `content`에 위젯으로 전달(여러 스타일 텍스트·버튼·클릭 가능 텍스트 등). `okayButtonLabel` 기본값은 `'Okay'`.
  - 배경: 노출 중 하단 화면 터치 불가. 배경 레이어는 오버레이 공통: `Color(0x66000000)`(검정 40%).
  - 팝업 카드: 가로 80%·세로 50% 디스플레이, 테두리 10·#80D7CF·radius 30. 카드 내부 배경은 `#1E1E1E` 60%(`Color(0x991E1E1E)`) 반투명 + BackdropFilter sigma 6 블러를 사용. 내부 상단 20 패딩·`close.svg` 28×28 좌측(탭 시 닫힘), 본문 좌우 30·하단 30 마진(`showOkayButton`일 때 12). 옵션으로 하단 테두리를 덮는 "Okay" 버튼(높이 44, 최대 가로 70%, #0CABA8, StadiumBorder, ElevatedButton) 노출 가능.

- **텍스트 언어 규칙**
  - **기본 원칙**: 사용자에게 표시되는 모든 기본 텍스트는 영어로 작성
  - **예외**: 사용자 언어에 따라 동적으로 변경되는 텍스트는 언어별 처리
    - 예: LoginScreen의 약관 문구 (`_getTermsText()` 메서드로 언어별 처리)
    - 예: SettingScreen의 약관 제목 (언어별 처리)
  - **적용 범위**: 
    - AlertDialog, SnackBar, 버튼 텍스트 등 모든 UI 텍스트
    - 에러 메시지, 알림 메시지 등
  - **주의사항**: 사용자 이름이나 동적 데이터가 포함된 메시지도 기본 언어는 영어로 작성

## 9. 앱 시작 화면 (네이티브 스플래시 · 커스텀 스플래시)
- **네이티브 스플래시**
  - **패키지**: `flutter_native_splash` (버전 2.3.10 이상) 사용
  - **설정**: `pubspec.yaml`의 `flutter_native_splash` 섹션에서 관리
  - **디자인 사양**: 이미지 없음, 어두운 단색 배경(`#121212`)만 노출 (Android 12+ 대응 포함)
  - **생성 명령**: `dart run flutter_native_splash:create`
  - **동작**: 앱 실행 시 자동 표시, `FlutterNativeSplash.preserve()`로 유지, JWT 확인 후 `FlutterNativeSplash.remove()` 호출
- **진입 흐름**
  - **앱 실행 시**: 네이티브 스플래시(배경색만) → **CustomSplashScreen** → LoginScreen 또는 (토큰 유효 시) HomeScreen
  - **로그아웃 시**: 곧바로 LoginScreen (CustomSplashScreen 미표시)
- **커스텀 스플래시**: `lib/screens/custom_splash.dart` (CustomSplashScreen). 토큰 없음인 앱 실행 시에만 노출되며, `onComplete` 콜백 후 LoginScreen으로 전환. 애니메이션·로고 노출 등은 추후 정의.
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
  - `lib/utils/default_toast.dart`: Overlay 기반 토스트 공통 처리 (배경 #353535/경고 #E4382A 85% 투명도, body-default 흰색, min height 48, 하단 60px, 좌우 반원)
  - 토스트 전체 목록 및 테스트 가이드: `.docs/TOAST_CATALOG.md`
  - **Default Markdown** (`lib/utils/default_markdown.dart`): 서버 텍스트의 `***`(볼드+이탤릭), `**`(볼드), `*`(이탤릭)만 파싱해 `TextSpan` 리스트로 변환하는 공통 로직. `***` → `**` → `*` 순서로 처리하며 중첩 미지원. 줄바꿈은 기존 그대로 유지. 적용 구역: **Opening** 시나리오 영역(`RoleplayOpeningScreen`의 scenario), **Ending** 콘텐츠 영역(`RoleplayEndingScreen`·`ReviewEndingScreen`의 content).
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
- **스토어/테스트 배포용 빌드번호 상향**: `pubspec.yaml` 버전을 `1.0.9+12`에서 `1.0.9+13`으로 변경(버전명 1.0.9 유지).
- **Main 복귀 시 `UserDto` 동기화 + 프로필 역할 분리**: 메인 라우트(첫 화면)가 서브 스크린 pop으로 다시 보일 때 `MainRouteAwareWrapper.onReturnToRoute`에서 `homeTabSelectedCounter`·`profileReturnCounter` 갱신 직후 `SudaApiClient.getCurrentUser`(`GET /v1/users`)를 비동기 호출해 `_MyAppState._user`를 best-effort 갱신. 구현: `lib/main.dart` `_syncUserOnMainRouteReturn`. GNB·Home·Profile에 전달되는 `user`가 롤플레이·설정 등 서브 종료 직후 맞춰짐. **레벨·진행률·ProfileDto**는 기존처럼 프로필 표면에서 `getUserProfile`(`GET /v1/users/profile`, `ProfileScreen._refreshProfile`) 한 번. `profileReturnCounter`는 프로필 탭이 계속 활성인 채 서브만 닫을 때 `didUpdateWidget` 갱신 트리거 유지(대체 설계 전까지 보수적 유지). 설정에서 프로필로 돌아올 때 쓰던 `ProfileScreen._openSettings`의 `addPostFrameCallback`으로 `widget.user`를 로컬 `_user`에 복사하던 보완은 제거(전역 동기화에 위임).
- **Playing 힌트 말풍선**: 힌트 텍스트 `GET /v1/roleplay-sessions/{sessionId}/hint`(문자열). 전체 발음 `GET .../hint/sound`, 단어 발음 `GET .../hint/sound/{index}`(JSON·`cdnYn`/`cdnPath`/`sound`). 라이트볼 탭 직후 로딩 플레이스홀더(회색 메가폰·스피너) 노출, 실패·빈 응답 시 행 제거. 성공 시 배경 `#194847` 70%·가로 `bodyWidth`·좌측 열(세로 중앙) 메가폰·우측 `Wrap` 본문 `headlineSmall`·기본 흰색·단어/메가폰 탭 시 재생 중 `#0CABA8`·점선 밑줄 `#0CABA8`(대시 길이 3·간격 3·선 두께 1.5, 상세 `.docs/CONTEXT_ROLEPLAY.md`)·텍스트 로드 후 스크롤 최하단 정렬. 말풍선 생명주기 안 발음 캐시(`full`, `w0`…); user-message 직전 힌트 행 제거 시 재생 구독 해제·`_audioPlayer.stop()`. 구현: `lib/api/endpoints/roleplay_api.dart` `getHintAudio`·`getHintWordAudio`, `lib/screens/roleplay/playing.dart`.
- **Playing AI 말풍선 너비**: 고정 `bodyWidth * 0.7` 제거. `ConstrainedBox(maxWidth: …)`로 내용 높이에 맞춘 최소 너비·최대는 `bodyWidth`에서 번역 아이콘(24)·아이콘 앞 간격(5)·아바타(40)·아바타-말풍선 간격(5) 제외(`lib/screens/roleplay/playing.dart` `_buildAiMessage`). 사용자/힌트 말풍선·나레이션은 변경 없음.
- **앱 버전 1.0.9**: `pubspec.yaml` 버전을 `1.0.8+11`에서 `1.0.9+12`으로 변경.
- **LoginScreen 캐치프레이즈·약관**: 좌우 패딩 각 `screenWidth * 0.1`(본문 가로 약 80%). `loginCatchphrase` l10n, 하단 `Spacer` 9·문구·1·버튼·1·약관·1(총 12).
- **앱 버전 1.0.8 배포**: `pubspec.yaml` 버전을 `1.0.7+10`에서 `1.0.8+11`으로 변경.
- **스토어 업로드용 빌드번호 상향**: `pubspec.yaml` 버전을 `1.0.7+9`에서 `1.0.7+10`으로 변경(버전명 1.0.7 유지).
- **AppsFlyer 커스텀 이벤트 연동**: Agreement 완료(서버 200 성공 직후, Home 이동 전) 시 `terms_agreed`, Roleplay Playing 최초 노출 시 `rp_started` 전송하도록 반영.
- **AppsFlyer SDK 연동(prd 기준)**: `lib/services/appsflyer_service.dart` 추가, `main()`에서 앱 시작 시 초기화. `AppConfig.isPrd`일 때만 SDK init/start 수행하도록 제한.
- **광고 ID 권한 정합성 반영**: `android/app/src/main/AndroidManifest.xml`에 `com.google.android.gms.permission.AD_ID` 권한 추가(Play Console 광고 ID 선언과 실제 아티팩트 권한 일치 목적).
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
  - `GET /v1/home/contents` 통합 API 연동 (배너+롤플레이) 및 무한 루프 `PageView` 배너 구현
  - 100% 너비 정사각형 형태, `BorderRadius: 20` 적용
  - 디바이스 언어 설정을 고려한 다국어 텍스트 오버레이 로직 적용
- **메인스크린 상태 보존 및 성능 최적화**:
  - `IndexedStack` 도입으로 Home과 Profile 화면 이동 시 기존 스크롤 위치 및 상태 유지
  - Profile 화면 진입 시마다 사용자 정보를 배경에서 최신화하는 Silent Refresh 로직 구현
  - 홈 콘텐츠 통합 API (`GET /v1/home/contents`)로 배너·롤플레이 동시 로드
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
- **GNB 오버레이·블러**: GNB는 본문 위에 덮는 형태로 배치(AppScaffold Stack 하단 Positioned). 배경은 오버레이 공통: BackdropFilter sigma 6 + Color(0x59000000).
- **GNB 아이콘화**: GNB 메뉴 3종을 텍스트에서 아이콘으로 전환. 공통 위젯 `lib/widgets/gnb_bar.dart`(GnbBar). Alarm: gnb_alarm.png / gnb_alarm_pressed.png, 높이 24, 좌측 33. Home: gnb_home.png / gnb_home_pressed.png, 너비 24, 정중앙. Profile: userDto.profileImgUrl 원형 28x28(비활성)·24x24+흰 테두리 2(활성), 우측 33. profileImgUrl이 null/empty면 `assets/images/icons/default_profile_image.png` 사용. 탭 영역: 좌 30% / 중앙 30% / 우 30%.
- **Roleplay Ending 스크린 개선**: 닫기 버튼 없음. role.endingList 첫 요소(RoleplayEndingDto) 기반 title/content/이미지. Playing에서 ending 전환 확정 시 imgPath+CDN으로 이미지 preload. 이미지 있으면 1.5x→1x 2초 축소 후 80% 검정 레이어·콘텐츠 fade-in; 없으면 바로 레이어·콘텐츠. 상단 50% title+content, 하단 50% endingHowWas+별 5개(40×40 gap 5)+Next 버튼. Next 탭 시 버튼 텍스트 fade-out과 동시에 버튼에서 #0CABA8 풍선 확장(2s) 후 Result 전환. `PUT /v1/roleplays/results/{rpResultId}?star={star}` 호출(응답 무시). Result 진입 시 박스레이어에 별점·mainTitle·subTitle 순차 노출(각 300ms 후) 후 박스 축소. 본문레이어 추후 지침. `.docs/CONTEXT_SCREEN.md` 14·17, `.docs/CONTEXT_ROLEPLAY.md` 참조.
- **RoleplayResultDto·Result 스크린 박스레이어**: DTO에 mainTitle·subTitle 필드 추가(서버 non-null). Result 박스레이어: 별점·mainTitle·subTitle 순차 노출 후 박스 축소. **Result 본문레이어**: like_at_result·likePoint(그라데이션)·Mission(missionResult 아이콘)·Words·Lv 프로그레스바(getUserProfile)·Good Points·To Improve·Got it! 버튼(Overview). `.docs/CONTEXT_SCREEN.md` §17 참조.
- **Result 본문 애니메이션 5~8단계**: 박스 축소(4단계) 완료 후 300ms 대기 → 5·7·8 동시 시작. 5: Mission 아이콘 N*n→missionResult 한 번에 전환(Y 있으면 진동). 7: likePoint 0→결과 500ms. 8: beforeLevel/beforeProgress→afterLevel/afterProgress 500ms(레벨업 시 surveySuccessToast). 5 후 300ms → 6: words 0→결과 300ms(words>0이면 진동). 초기값: Mission N*n, words 0, likePoint 0, Lv/진행률 before*.
- **Main Screen 물리 뒤로가기**: Home 탭에서만 앱 종료, Alarm/Profile 탭에서는 Home으로 이동. `lib/main.dart`에서 IndexedStack을 `PopScope`(canPop: home일 때만 true)로 감싸 처리. `.docs/CONTEXT_SCREEN.md` Main Screen·비교표 반영.
- **Profile 롤플레이 히스토리**: Progress box 아래 세로 스크롤 영역에 롤플레이 결과 썸네일 그리드. `GET /v1/roleplays/results?pageNum=0` 페이징(0부터 9개씩), 3열 32%·CDN prepend·캐시·shimmer 로딩·스크롤 시 append. 썸네일 탭 시 HistoryScreen(Sub) 진입(resultId 전달). History에서 ReviewChatScreen/ReviewEndingScreen 진입. 상세는 `.docs/CONTEXT_SCREEN.md` §19·20·21.
  - 프로필 탭 재진입·서브 복귀 시 `GET /v1/users/profile`는 항상 호출. 히스토리 0페이지 재조회는 **마지막 API 페이지까지 로드했고** 스크롤이 목록 하단(끝에서 200px 이내)일 때만 수행해, 중간 페이지 열람·스크롤 위치를 유지한다. 최초 마운트(`initState`)는 목록 비어 있으므로 0페이지 로드 유지.
- **신규 스크린 (History·Review)**: HistoryScreen(Profile 진입, 롤플레이 결과 요약·Result 유사), ReviewChatScreen(History 진입, 채팅 열람), ReviewEndingScreen(History 진입, 엔딩 열람·Ending 유사). 파일: `lib/screens/roleplay/history.dart`, `review_chat.dart`, `review_ending.dart`.
- **HistoryScreen 구현**: resultId로 `getRoleplayResult`만 조회 후 스크린 상태로만 보관(RoleplayStateService 미사용). GET /v1/users/profile 미호출, 레벨·프로그레스바 영역 미노출. History↔ReviewChat/ReviewEnding 구간 동안 동일 result 유지, 나갈 때·새 진입 시 갱신. Result와 유사 레이아웃(박스 210·본문, Lv/프로그레스바 제외), 초기 애니메이션 없음. Got it 버튼 노출만(동작 없음), Report 문구 없음. View Chat 탭 시 ReviewChatScreen에 RoleplayResultDto 전달하여 진입. **상단 별 3개 탭**: `GET /v1/roleplays/results-reload/{resultId}` 호출(운영자용 리프레시 테스트). 2xx 응답 시에만 화면을 새 RoleplayResultDto로 갱신, 그 외·에러 시 아무 동작 없음. 요청 진행 중에는 중복 탭 무시(화면상 인터랙션 없음).
- **RoleplayResultDto**: 응답에 `avatarImgPath` 포함(Review Chat에서 AI 아바타 표시용). 내부 모델은 subTitle 다음에 avatarImgPath 필드.
- **ReviewChatScreen 구현**: History에서 RoleplayResultDto 전달받아 채팅 이력 표시. 헤더 중앙 "Chat History"(Setting 계열 스타일), 좌상단 뒤로가기(header_arrow_back). chatHistory는 List\<SudaJson\>이며 key로 발화자 구분(USER / AI_CHARACTER / AI_NARRATOR / SYSTEM_MISSION), value를 그대로 표시. Playing과 동일 말풍선·나레이션·미션 배치 및 스타일(사용자 우측 흰색, AI 좌측 티얼+avatarImgPath 아바타, 나레이션/미션 중앙).
- **ReviewEndingScreen 구현**: History "View Ending" 탭 시 `GET /v1/roleplays/{rpId}/roles/{rpRoleId}/endings/{endingId}` 호출, 응답 RoleplayEndingDto·이미지 프리로드 후 진입(버튼에 Opening과 동일 뱅글 로딩). Sub Screen. 헤더 "View Ending"+뒤로가기. 본문: 이미지(BoxFit.cover·높이 100%·비율 유지·좌우 잘림 가능) → 2s 후 레이어·타이틀(상단 25%)·콘텐츠(하단 75%) 페이드인. 버튼 없음.
- **엔딩 API**: `SudaApiClient.getRoleplayEnding(accessToken, rpId, rpRoleId, endingId)` → RoleplayEndingDto.
- **세션 초기화 응답 분기**: Opening→Playing 세션 초기화(`POST /v1/roleplay-sessions`) 200 응답의 `sessionId` 기준: '0'=티켓 부족(기존 공통 팝업+외부 Okay 버튼, Opening 유지), '-10'=추가 티켓 설문 유도 팝업(내부 버튼형, Opening 유지), '-20'=푸시 동의 유도 팝업, '-30'=앱 링크 공유 유도 팝업(공유시트 닫힘 후 `POST /v1/users/quests/{questId}`), '-40'=스토어 리뷰 유도 팝업(인앱리뷰 성공 반환 후 `POST /v1/users/quests/{questId}`), 그 외=Playing 진입. `.docs/CONTEXT_ROLEPLAY.md` 6-3 참조.
- **-10 분기 Survey 진입**: Opening의 `sessionId == '-10'` 팝업에서 "Answer now ✅" 탭 시 `RoleplayRouter.pushSurvey()`로 Sub Screen `RoleplaySurveyScreen`(`lib/screens/roleplay/survey.dart`) 진입. "Maybe later" 탭 시 팝업만 닫음.
- **Survey 3단계 구현**:
  - 헤더는 타이틀 없이 닫기(X)만 사용. 진입 시 1단계부터 시작.
  - 진행바: 3분할(각 32%, h8, radius4), 활성 바 그라데이션 `#076766 -> #0CABA8`, 비활성 `#353535`.
  - 단계/값 매핑: 1단계 연령(1~5), 2단계 성별(1~3), 3단계 유입경로(1~5).
  - 3단계 선택 시 `POST /v1/users/survey` 호출(body: age/gender/source 문자열 숫자).
  - 응답 `200 + 'Y'`면 성공 토스트(l10n), 그 외(200의 N 포함·4xx·5xx·timeout) `"Survey Failed"` 경고 토스트 후 화면 닫기.
  - 제출 중 선택지 버튼 비활성화.
- **홈 화면 티켓 배지**: 상단 우측에 티켓 아이콘(`assets/images/icons/ticket.png` 38×20) + finalTicketCount 표시(body-caption 흰색). 앱 구동 후 첫 노출 시·GNB 홈 탭 선택 시·물리 뒤로가기로 홈 복귀 시·**서브 스크린에서 pop으로 복귀 시** `GET /v1/users/ticket` 갱신. 서브 복귀 감지는 `RouteObserver` + `MainRouteAwareWrapper`(lib/widgets/main_route_aware_wrapper.dart)의 `didPopNext`로 처리. 응답 `finalTicketCount`를 티켓 수치에 바로 반영.
- **PushAgreementScreen**: 설정 > Notification 진입. 푸시 알림 ON/OFF 토글. `PUT /v1/users/push-agreement?agreementYn=Y|N` 호출 후 `QuestResultDto(completeYn)` 응답 처리.
  - `completeYn == 'Y'`: 티켓 보상 지급으로 간주, `surveySuccessToast` 토스트 노출 후 PushAgreementScreen 자동 닫기.
  - 그 외(`N` 포함): 기존처럼 토글 상태만 반영(추가 토스트/자동 닫기 없음).
  - Opening `sessionId == '-20'` 분기에서 PushAgreementScreen으로 진입할 수 있음. `.docs/CONTEXT_SCREEN.md` §5.1.
- **-30 분기 공유 퀘스트**: Opening의 `sessionId == '-30'` 팝업에서 "Share link 💬" 탭 시 Play Store 링크(`https://play.google.com/store/apps/details?id=kr.sudatalk.app`) 공유시트를 노출.
  - 공유시트 닫힘 감지 후 `POST /v1/users/quests/{questId}` 호출 (`questId = sessionId`)
  - 응답 `QuestResultDto.completeYn == 'Y'`인 경우에만 `surveySuccessToast` 토스트 노출, 그 외 별도 처리 없음.
- **-40 분기 리뷰 퀘스트**: Opening의 `sessionId == '-40'` 팝업에서 "Leave Stars ⭐" 탭 시 OS 인앱리뷰 API를 호출.
  - 인앱리뷰 호출 성공 반환 시 `POST /v1/users/quests/{questId}` 호출 (`questId = sessionId`)
  - 응답 `QuestResultDto.completeYn == 'Y'`인 경우에만 `surveySuccessToast` 토스트 노출, 그 외 별도 처리 없음.
**앱 버전 1.0.9**: `pubspec.yaml`의 `version` 값(예: 1.0.9+13)을 단일 사실 기준으로 사용. Setting 화면 하단: 개인정보·이용약관·오픈소스 블록 위로 조정, 그 아래 버전 텍스트 `v x.x.x` (fontSize 11, 흰색, 중앙 정렬) 노출.
- 버전 비교 및 강제 업데이트 로직은 `VersionCheckService`에서 `AppVersionService.getAppVersion()` 결과와 서버 응답 `latestVersion`를 비교하여 처리.
**버전 관리 원칙**: 신규 기능 개발 전 버전 상향이 필요할 때는 `pubspec.yaml`의 `version`만 관리(예: 1.0.9+13 → 1.0.10+14). 코드 내 버전 상수는 두지 않고, 런타임에 `AppVersionService`로 조회.
- **푸시 appPath 연동**: FCM data에 `appPath` 포함 시 알림 클릭 후 해당 스크린으로 이동. 비로그인/미동의 시 `PendingAppPathService`에 보관, Home 진입 시 적용. 지원 경로·정의는 `.docs/CONTEXT_SCREEN.md` appPath 섹션. `lib/services/pending_app_path_service.dart`, `main.dart`(getInitialMessage·onMessageOpenedApp·_applyPendingAppPath).
- **NotificationBoxScreen 알림 페이징**: Alarm 탭(Main Screen) 진입 시 `/v1/users/notification?pageNum=0`으로 알림 목록 조회, 스크롤 하단 도달 시 `pageNum=1`, `2`, `3`… 순차 호출(전부 0-based). 응답이 빈 리스트이면 더 이상 호출하지 않음. 목록은 GNB 오버레이에 가리지 않도록 `ListView` 하단에 `MediaQuery.padding.bottom + GnbBar.contentHeight`만큼 패딩. 응답 DTO는 `NotificationDto(id, title(List<SudaJson>), content(List<SudaJson>), imgPath, appPath, sendFinishedAt)`이며, title/content는 `SudaJsonUtil.localizedText`로 사용자 언어에 맞게 표시. `sendFinishedAt`은 서버 UTC+0 시각; ISO에 타임존이 없으면 UTC로 간주해 파싱 후 로컬 날짜 기준 상대 표시(l10n Today / n일 전 등, bodySmall·#635F5F·우측). 결과가 없을 때는 본문 중앙에 "No notification yet"(l10n.notificationsEmpty)을 body-default 흰색 텍스트로 노출.
- **공지사항 화면**: AnnouncementsScreen (`GET /v1/notice` page/size 페이징), AnnouncementDetailScreen (`GET /v1/notice/{id}`). 카드: 제목·본문 1줄 말줄임, publishedAt YYYY-MM-DD 우하단. 빈 상태 l10n.noticesEmpty. showYn='n' 또는 삭제/404 시: 상세 페이지 대신 AppContentDialog 팝업으로 l10n.postNoLongerAvailable(게시물이 삭제되었거나 존재하지 않습니다) 안내, 버튼 l10n.backToHome(홈으로 가기).
- **Tutorial 스크린 추가**: Overview → Opening 전환 전 TUTORIAL metaInfo 조건 분기
  - `lib/screens/roleplay/tutorial.dart` (RoleplayTutorialScreen): 5페이지 슬라이드, 상단 dot indicator, 마지막 페이지 탭으로 완료
  - 조건: `userDto.metaInfo`의 `TUTORIAL != 'Y'`인 경우 노출, 이미 완료 시 즉시 Opening으로 skip
  - 언어별 이미지: `assets/images/tutorials/{ko|pt|en}/tutorial-{1~5}.png` (pubspec에 3개 경로 추가)
  - API: `POST /v1/users/tutorial` (`SudaApiClient.completeTutorial()`)
  - 완료 직후 `getCurrentUser`로 사용자 재조회 → `RoleplayStateService.setUser` 및 `MainUserSync.notifyUserUpdated`로 Main/Home의 `UserDto`(metaInfo `TUTORIAL` 포함) 동기화. `getCurrentUser` 실패 시 로컬 meta 패치(`_updateLocalUserTutorialDone`) 후 동일 notify.
  - `MainUserSync`: `lib/services/main_user_sync.dart` — Main `_MyAppState`가 `register`/`unregister`로 리스너 연결
  - `RoleplayRouter.pushTutorial()`, `RoleplayRouter.replaceWithOpeningFromTutorial()` 추가
  - Overview `_navigateToOpening()` → `pushTutorial()` 로 변경
- **Android 서명 정책 변경(Flavor 기준)**: `android/app/build.gradle.kts`에서 local/dev/stg는 debug/release 모두 디버그 키스토어 사용, prd는 debug/release 모두 `android/key.properties`의 릴리스 키스토어 사용. prd 빌드에서 `key.properties`가 없으면 빌드 실패.

## 14. 공통 오버레이 이펙트(Effect Overlay) 구조
- **목적**: 특정 스크린의 UI 위에 “레이어처럼 나타났다 사라지는” 공통 애니메이션을 재생하고, 스크린은 **효과 종료 시점**을 감지해 다음 UI를 그릴 수 있도록 한다.
- **전역 오버레이 서비스**: `lib/services/effect_overlay_service.dart`
  - `EffectOverlayService.show(...)`: 필요 시에만 `OverlayEntry`를 삽입해 효과를 재생한다.
  - 효과가 끝나면 `EffectOverlayService.complete()`로 `OverlayEntry`를 제거하고 `Future`를 resolve한다.
  - 기본 정책은 **동시 재생 1개(새 호출 시 replace)** 로 단순하게 유지한다.
- **앵커(목표 좌표) 레지스트리**: `lib/services/effect_anchor_registry.dart`
  - UI 요소의 화면상 좌표(Rect)가 필요할 때(예: 티켓이 “홈 티켓 배지” 위치로 날아감) `GlobalKey` 기반으로 `Rect`를 조회한다.
  - 현재 앵커: `EffectAnchorId.ticketBadge` → Home 헤더의 티켓 배지 위치(`lib/screens/home.dart`).
- **개별 효과 API**: `lib/effects/like_progress_effect.dart`
  - `LikeProgressEffect.play(context, params, onCompleted?)` 형태로 호출한다.
  - 파라미터/연출은 효과별 위젯(오버레이)에서 구현하며, 종료 콜백은 fade-out 등 정상화까지 완료된 뒤 1회 호출한다.
  - `LikeProgressOverlay`의 Phase 6 카운터 구간 시작 시 엄지 아이콘 주변에 `like_progress_star.png` 반짝임이 동시 3~5개 생성된다. 각 별은 시작 시점·위치 후보 4곳·크기(width 20~30)·주기를 미세하게 달리하며, 빠른 fade-in 후 soft fade-out(+소폭 scale-up) 1cycle을 반복한다. 활성 반짝임끼리는 최소 거리 검사를 적용해 겹침을 줄인다.
  - Phase 6 프로그레스바 진행 중에는 `VibrationPreset.rapidTapFeedback`를 반복 재생한다. 레벨업으로 티켓 이미지가 생성될 때의 진동은 앞뒤로 짧게 쉰 뒤 `VibrationPreset.doubleBuzz`로 재생하고, 이후 프로그레스 진동을 다시 이어간다.
  - 반짝임은 Phase 8 진입 전까지 재생되며, Phase 8에서는 dim, 엄지, 반짝임, 수치 영역이 함께 전체 fade-out 된다. bg 이미지는 Phase 7 종료와 동시에 즉시 화면에서 제거한다.

## 13. 리팩토링 계획 문서
- 롤플레이 기능 준비를 위한 리팩토링 작업 분해 문서는 `REFACTOR.md`에 기록
