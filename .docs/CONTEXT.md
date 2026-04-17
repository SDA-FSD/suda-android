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
    - 응답: `HomeDto` (restYn, restStartsAt, restEndsAt, banners, roleplays, **notiboxUnreadYn**)
    - **notiboxUnreadYn**: 알림함(notibox)에 사용자 기준 미읽음이 있으면 `Y`, 없으면 `N`. 홈·GNB 알림 탭 배지 판단에 사용(`main.dart`·`HomeScreen` 로드 시 `RestStatusService.instance.update(..., notiboxUnreadYn: ...)` 동기화).
    - banners: `List<MainHomeBannerDto>` (imgPath, overlayText)
    - roleplays: `List<AppHomeRoleplayGroupDto>` (roleplayCategoryDto, list)
    - restYn/restStartsAt/restEndsAt·notiboxUnreadYn은 `GET /v1/home/contents` 처리 시 `RestStatusService.instance.update()`로 보관 (어떤 스크린에서도 접근 가능)
  - `SudaApiClient.getNotifications()`: 알림함 목록 페이징 (`GET /v1/users/notification?pageNum=…`, `UserApi.getNotifications`) — 응답 원소 `NotificationDto`에 **readYn**(`Y`/`N`) 포함.
  - `SudaApiClient.markNotificationRead()`: 알림 읽음 처리 (`POST /v1/users/notification/{notificationId}/read`, `UserApi.markNotificationRead`) — 응답 `QuestResultDto`.
  - `SudaApiClient.getLatestVersion()`: 최신 버전 정보 조회 (`GET /v1/latest-version`)
    - 응답: `VersionDto` (latestVersion, forceUpdateYn, androidMarketLink?, appleMarketLink?)
    - 최신 버전 정보는 `TokenStorage.saveLatestVersion()`으로 영구 저장
    - 저장된 버전 정보는 `TokenStorage.loadLatestVersion()`으로 조회 가능
- **RestStatusService**: `lib/services/rest_status_service.dart`
  - 서비스 점검 대응용 restYn, restStartsAt, restEndsAt·**notiboxUnreadYn** 전역 보관
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
- **RoleplayOpeningScreen / RoleplayPlayingScreen** 전면 배경: `overviewImgPath`가 있으면 공통 위젯 `RoleplayOverviewBackdrop`(`lib/widgets/roleplay_overview_backdrop.dart`, Overview와 동일 CDN URL·캐시). 상세는 `.docs/CONTEXT_SCREEN.md` §12·§13.

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

- **표준 팝업 (DefaultPopup)**: `lib/widgets/default_popup.dart`
  - 목적: 기존의 자유로운 콘텐츠 구성 패턴을 유지하되, **표준 슬롯(topWidget/title/body/buttons)**과 **표준 프레임 규격**을 제공한다.
  - 재사용: `DefaultPopup.show(context, { topWidget, titleText, bodyWidget, buttons, barrierDismissible })`.
  - 배경/테두리/블러(고정): 배경 검정 40%, 테두리 10·#80D7CF, radius 30, 내부 배경 `#1E1E1E` 60% + blur sigma 6.
  - 닫기 UX: 좌상단 닫기 아이콘은 사용하지 않으며, 필요 시 `buttons`에 **text 타입의 닫기 버튼**을 포함한다(라벨은 하드코딩 금지, 예: `l10n.surveyMaybeLater`). 탭 시 팝업 닫힘 후 콜백 실행 규칙은 동일.
  - 카드 높이: 고정 높이 없이 내용에 따라 결정되되, **최대 높이는 화면 높이의 80%**로 캡되며 초과 시 **`topWidget + titleText + bodyWidget + buttons` 영역만 스크롤**(닫기 아이콘은 스크롤 미포함).
  - 본문 영역 패딩: 상 20 / 좌·우·하 16. `bodyWidget` 내부 레이아웃은 호출부 자율이며, `DefaultPopup`은 **topWidget ↔ title ↔ body ↔ buttons 사이**에만 세로 20 간격을 보장한다.
  - 버튼: `primary`(스펙상 이름은 `default`이나 Dart 예약어 회피, full width, height 44, #0CABA8, Stadium, `ElevatedButtonTheme` 병합) / `text`(`TextButtonTheme` 병합, 흰색 텍스트). 버튼 탭 시 **항상 팝업을 닫은 뒤** 콜백을 호출한다.
  - 마이그레이션: 팝업 UI는 **점진적으로** `DefaultPopup`으로 옮긴다(동시 대량 치환 금지).
  - Dev 확인(Lab): `lib/screens/setting/lab.dart`의 `kLabDefaultPopupOptions`에 전환 완료 팝업을 등록한다. Lab 화면 상단 **Default Popup Test**는 드롭다운 선택 + **Show Popup**으로 재현한다.

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
  - `lib/utils/default_toast.dart`: Overlay 기반 토스트 공통 처리 (배경 #353535/경고 #E4382A 85% 투명도, body-default 흰색, 좌우 패딩 16·세로 패딩 12·minHeight 없음, 하단 60px, 좌우 반원, 가로는 max 90% 디스플레이 내에서 짧은 문구는 콘텐츠 너비에 맞춤·`Align` widthFactor/heightFactor 1). **토스트 pill 탭** 시 표시 타이머를 끊고 **자동 사라짐과 동일한 fade-out**(동일 1초)으로 닫힘; 배경 UI 히트는 막지 않음.
  - 토스트 전체 목록 및 테스트 가이드: `.docs/TOAST_CATALOG.md`
  - **Default Markdown** (`lib/utils/default_markdown.dart`): 서버 텍스트의 `***`(볼드+이탤릭), `**`(볼드), `*`(이탤릭)만 파싱해 `TextSpan` 리스트로 변환하는 공통 로직. `***` → `**` → `*` 순서로 처리하며 중첩 미지원. 줄바꿈은 기존 그대로 유지. 적용 구역: **Ending** 콘텐츠 영역(`RoleplayEndingScreen`·`ReviewEndingScreen`의 content). (`RoleplayOpeningScreen` 시나리오는 일반 `Text`·`bodyLarge` 흰색.)
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

최근 작업 메모(이력)는 `.docs/CONTEXT_HISTORY.md`에 보관한다. 상세 항목은 해당 문서를 참조한다.

## 13. 공통 오버레이 이펙트(Effect Overlay) 구조
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
  - Phase 1(500ms): 딤은 알파 0→1. **BG(`like_progress_bg.png`)·엄지(`like_at_result.png`)** 는 동일 구간에서 스케일 2.0→0.7·Y 0→-50과 함께, **앞쪽 약 300ms(phase1 진행 `t` 0~0.6)** 에 알파 0→1(`Curves.easeOut`) 페이드인하며 **`t=0`(스케일 2.0)에서는 완전 투명**이다.
  - 파라미터/연출은 효과별 위젯(오버레이)에서 구현하며, 종료 콜백은 fade-out 등 정상화까지 완료된 뒤 1회 호출한다.
  - `LikeProgressOverlay`의 Phase 6 카운터 구간 시작 시 엄지 아이콘 주변에 `like_progress_star.png` 반짝임이 동시 3~5개 생성된다. 각 별은 시작 시점·위치 후보 4곳·크기(width 20~30)·주기를 미세하게 달리하며, 빠른 fade-in 후 soft fade-out(+소폭 scale-up) 1cycle을 반복한다. 활성 반짝임끼리는 최소 거리 검사를 적용해 겹침을 줄인다.
  - Phase 6 프로그레스바 진행 중에는 `VibrationPreset.rapidTapFeedback`를 반복 재생한다. 레벨업으로 티켓 이미지가 생성될 때의 진동은 앞뒤로 짧게 쉰 뒤 `VibrationPreset.doubleBuzz`로 재생하고, 이후 프로그레스 진동을 다시 이어간다.
  - 반짝임은 Phase 8 진입 전까지 재생되며, Phase 8에서는 dim, 엄지, 반짝임, 수치 영역이 함께 전체 fade-out 된다. bg 이미지는 Phase 7 종료와 동시에 즉시 화면에서 제거한다.
