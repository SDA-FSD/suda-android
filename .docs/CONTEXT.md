# Suda Application 프로젝트 컨텍스트

## 1. 프로젝트 목적
- **Flutter기반 모듈**: AI와 영어로 대화할 수 있는 교육용 애플리케이션
- **API 서버와 통신** suda-api 프로젝트에서 제공하는 API를 호출하여 동작

## 1-1. Roleplay 시즌 (S1 / S2)
- **S1 (Season 1)**: fade-out 예정. **단일 롤플레이** 단위 노출·플레이. `RoleplayOverviewScreen` → Opening → Playing → … (`GET /v1/roleplays/{roleplayId}/overview`).
- **S2 (Season 2)**: 신규. 여러 롤플레이(**에피소드**)가 하나의 **시리즈**에 묶임. 홈에는 시리즈 단위로 노출하며, 탭 시 `SeriesOverviewScreen`(Sub, `lib/screens/series/overview.dart`)으로 진입. 에피소드 Play → Tutorial → `RoleplayOpeningScreen` → Playing → … 복귀는 `RoleplayRouter.popToOverview`가 `/series/overview`까지 pop. S2 플레이 컨텍스트는 `SeriesStateService`(`lib/services/series_state_service.dart`)에 `RpS2SeriesOverviewDto`·`selectedEpisodeId`·`user`를 보관(다른 시리즈 Overview 진입 시 refresh). 홈 API: `GET /v2/home/contents`, 카테고리 페이징 `GET /v2/home/series?category={enumValue}&pageNum=…`.
- **S1 Opening 연결 해제**: `RoleplayOverviewScreen` 역할 Play 버튼은 Opening/Tutorial로 이동하지 않음(fade-out). S1 Overview 상태는 스크린 삭제 단계에서 정리 예정.

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
  - **S8** (추가 테스트 디바이스): 갤럭시 모델 (SM G955N, Android 9 / SDK 28, 디바이스 ID: ce041714d2f6348e0d)
    - 재설치 명령: `adb -s ce041714d2f6348e0d install -r build/app/outputs/flutter-apk/app-{flavor}-release.apk`
  - **참고**: 앞으로 이 문서에서 "A30", "A23", "A16", "S8"이라는 별칭으로 각 기기를 지칭할 수 있습니다.
  - **ADB 팁**:
    - `adb`가 인식되지 않으면 `export PATH=$PATH:~/Library/Android/sdk/platform-tools`로 경로 추가
    - 다중 기기 설치 예시:
      - `adb -s R59M801MDFM install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s R59T901DRQV install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s RF9XB00CX9J install -r build/app/outputs/flutter-apk/app-dev-debug.apk`
      - `adb -s ce041714d2f6348e0d install -r build/app/outputs/flutter-apk/app-dev-debug.apk`

## 3. 환경별 설정 관리
- **Android Flavor**: local/dev/stg/prd 환경별로 분리 관리
  - 각 환경별 패키지명: `kr.sudatalk.app.{env}` (prd는 suffix 없음)
  - 환경별 Google Client ID: `android/app/src/{env}/res/values/strings.xml`
  - 빌드 방법: `flutter run --flavor {env} -t lib/main.dart --dart-define=ENV={env}`
  - **local 전용**: `android/app/src/local/AndroidManifest.xml`에서 `usesCleartextTraffic=true`를 병합한다. local API가 HTTP(`10.0.2.2:8083`)이므로 Android 9+에서 평문 차단 시 네트워크 오류가 나지 않도록 한다.
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
  - `SudaApiClient.getUserProfile()`: 프로필 부가 정보 조회 (`GET /v1/users/profile`, 응답: ProfileDto(userDto, currentLevel, progressPercentage, likesToNextLevel?)). `likesToNextLevel`은 레벨업까지 남은 Like 수. 백엔드 `suda-api`의 `LevelService.getLikesToNextLevel`·`ProfileDto`에서 계산·직렬화. 최대 레벨이면 JSON null → 미포함 시 클라이언트에서 해당 문구 미노출.
  - `SudaApiClient.getUserEnergy()`: 에너지 상세 조회 (`GET /v1/users/energy/detail`, 파라메터 없음, 응답: UserEnergyDto — energyCount, maxEnergyCount, lastAutoChargedAt?, unlimitedEndsAt?, **subscribedYn**, **subscriptionExpiredAt?**, **showUnlimitedPurchaseYn**, **showCapacity6PurchaseYn**, **showCapacity7PurchaseYn**). HomeScreen 초기화·홈 탭 재진입(`homeTabSelectedCounter`) 시 호출해 우상단 배지 갱신.
    - **재화 정책(에너지)**: 롤플레이 **Playing 중 사용자 발화 처리마다** 소비(Start 시점 소비 없음). 1회 플레이당 약 5~6 소비를 목표. 향후 최대 용량 확대·무제한 이용시간 등 유료화 계획.
    - **구독 아이콘**: `subscribedYn==Y`이고 `subscriptionExpiredAt` 미경과면 무제한→`unlimited_sub.png`, 일반→`energy_sub.png`. 비구독은 기존 `unlimited.png`/`energy.png`. 공통 헬퍼 `lib/utils/energy_icon.dart`. 적용처: `EnergyHeaderBadge`·팝업 본문·`PlayingEnergyIndicator`.
    - **구독 만료 재조회**: `subscriptionExpiredAt` 경과 시 1회 `GET /v1/users/energy/detail` 재조회 (`EnergyTimerRefetchTracker`). 충전(`lastAutoChargedAt`)처럼 1초마다 API를 치지는 않음.
    - **무제한 모드**: `unlimitedEndsAt`이 현재(UTC) 이후이면 unlimited 아이콘(구독 시 `_sub`)(24×24) + 5dp gap + 남은 시간 `MM:SS`(bodyMedium w700, 흰색). 1초 주기 타이머로 갱신, 만료 시 자동 재조회 후 일반 모드 전환.
    - **일반 모드**: `unlimitedEndsAt`이 null 또는 과거이면 energy 아이콘(구독 시 `_sub`)(24×24) + `energyCount`(bodyMedium w700, 흰색). `lastAutoChargedAt` 기준 30분마다 1 충전(최대 `maxEnergyCount`). 가득 차지 않았을 때 충전 타이머 `00:00` 도달 시 detail 재조회.
    - 배지는 `EnergyHeaderBadge`(`lib/widgets/energy_header_badge.dart`). Home·Opening 우상단 공통. 탭 시 `showEnergyInfoPopup`. Home은 `registerEnergyBadgeAnchor: true`·`refreshCounter: homeTabSelectedCounter`(탭 재선택·메인 복귀 시 `main.dart` `homeTabSelectedCounter` 증가로 재조회). Opening·Playing도 화면 체류 중 충전·무제한·구독 만료 시 자동 갱신. 팝업 내 결제 성공 시 `EnergyRefreshBus`로 배지·Playing도 재조회. **에너지 팝업 오픈은 전역 lock**(`energy_info_popup.dart` `_withEnergyPopupLock`)으로 따닥 시 이중 팝업 방지(info/부족/Playing/Lab 공통).
    - **Playing 푸터 에너지**: `PlayingEnergyIndicator` — 녹음 모드 하단 아이콘 행 중앙·타이핑 모드 하단 동일. 일반 energy 아이콘+숫자, 무제한 unlimited 아이콘만(타이머 없음, 구독 시 `_sub`). 탭 영역 48×48 중앙 정렬. 탭 시 무제한 또는 `energyCount > 0`이면 `showEnergyInfoPopup`(닫기), 일반 모드·0이면 `showPlayingEnergyInsufficientPopup`(본문 l10n `energyInfoRechargeUntil`·Home과 동일, 버튼 `endRoleplay`). `user-message` 성공 시 로컬 -1. 에너지 0에서 녹음/타이핑 send 또는 API **402** 시에도 `showPlayingEnergyInsufficientPopup` → `endRoleplay` 탭 시 Wait 나가기 레이어(세션 유지).
    - **에너지 팝업 구매 영역** (`lib/widgets/energy_purchase_section.dart`): 안내문구와 닫기(또는 endRoleplay) 버튼 사이. 노출 순서 — Unlimited Pass(`showUnlimitedPurchaseYn`) → Capacity6 → Capacity7 → Go Premium(`subscribedYn!=Y`, Lab은 force 가능). 버튼 갭 10·radius 20. INAPP 제목(bodyMedium w600)은 폭 부족 시 `marquee` 루프, 부제 `labelSmall`. INAPP 배경은 `#121212` 베이스 레이어 + 테마색 오버레이 레이어(평소 5% / 결제 진행 중 30%, 250ms). Lab에서 스토어 가격 없으면 `R$2,99` 폴백. INAPP은 `IapPurchaseService`(`lib/services/iap_purchase_service.dart`)로 단건 구매·verify·가격 영속 캐시(`IapPriceCache`). 결제 중 다른 구매 버튼 비활성. verify `successYn=Y`면 해당 버튼 1000ms 페이드/축소 후 제거·detail 재조회·배지 동기화(`pendingYn=Y`면 승인대기 토스트). `successYn=N`이면 실패 토스트만. 스토어 취소/실패는 토스트 없이 테마 틴트 5% 복귀. Go Premium → `PaywallScreen.push`(팝업 유지).
    - **에너지 팝업 타이틀**: 무제한 모드 또는 일반 모드·에너지 > 0 → l10n `energyInfoTitle`. 일반 모드·에너지 0 → `energyOutOfEnergyTitle`(en Out of Energy / ko 에너지 부족 / pt Sem energia). Home·Opening·Playing 공통.
    - **에너지 부족 팝업(Opening)**: Start 응답 `sessionId == '0'` 시 `showEnergyInsufficientPopup` — `closePopup`으로 닫기. 구매 버튼도 동일 본문에 포함.
  - `SudaApiClient.getRpS2UserHistories()`: Profile History 목록 페이징 (`GET /rps2/user-histories?pageNum=0`, 0-based, 응답: SudaAppPage\<RpS2SimpleHistoryDto\> — `id`, `imgPath`, `starResult`, `cefrLevel`, `createdAt`)
    - 롤플레이 스택 `popToOverview` 직후 `markProfileHistoryRefreshPending` → 이후 Profile 탭 활성 시 0페이지 재조회(기존 스크롤·페이징 조건 우회). 그 외 탭 재진입은 `ProfileScreen._shouldRefetchHistoryFromStart` 조건부.
  - `SudaApiClient.updateName()`: 사용자 이름 변경 (`PUT /v1/users?name=...`)
  - `SudaApiClient.registerPushToken()`: 푸시 토큰 등록 (`POST /users/push-token`)
    - Request body: `{ "deviceType": "ANDROID", "pushToken": "<토큰값>", "languageCode": "en|ko|pt" }`
    - 응답 처리하지 않음 (에러 발생 시에도 무시)
  - `SudaApiClient.getHomeContents()`: 홈 화면 콘텐츠 통합 조회 (`GET /v2/home/contents`)
    - 응답: `HomeDto` (restYn, restStartsAt, restEndsAt, banners, **seriesList**, **notiboxUnreadYn**)
    - **notiboxUnreadYn**: 알림함(notibox)에 사용자 기준 미읽음이 있으면 `Y`, 없으면 `N`. 홈·GNB 알림 탭 배지 판단에 사용(`main.dart`·`HomeScreen` 로드 시 `RestStatusService.instance.update(..., notiboxUnreadYn: ...)` 동기화).
    - GNB 알림 탭 빨간 점: `main.dart`의 `_showNotiboxUnreadBadge` 계열 상태로 `GnbBar.showNotiboxUnreadBadge`에 전달. 알림함에서 **전 페이지 로드가 끝난 뒤** 로컬 목록에 미읽음이 없으면 `getHomeContents`로 동기화한 뒤에도 `notiboxUnreadYn`이 `Y`로 남는 경우 배지용 값을 `N`으로 보정한다(동기화 실패·일시 불일치 대비). notibox 페이지 크기(10)는 API와 동일하게 `NotificationBoxScreen`·`main.dart`에 상수로 둔다.
    - banners: `List<MainHomeBannerDto>` (imgPath, overlayText, appPath?)
      - `appPath`가 있으면 Home 배너 탭 시 기존 appPath 규칙(`_applyPendingPushNavigation`)으로 화면 이동한다.
    - seriesList: `List<HomeSeriesGroupDto>` (`category`: `HomeCategoryDto` — `enumValue`, `name` Map; `seriesList`: `List<HomeSeriesDto>` — `id`, `title` Map, `thumbnailImgPath`)
      - 홈 화면 카테고리별 가로 썸네일: `lib/screens/home.dart` `CategorySeriesRow`에서 `ListView.separated` 구분 폭 **8**dp. 썸네일 탭 → `SeriesRouter.pushOverview` → `SeriesOverviewScreen`(S2, placeholder).
    - restYn/restStartsAt/restEndsAt·notiboxUnreadYn은 `GET /v2/home/contents` 처리 시 `RestStatusService.instance.update()`로 보관 (어떤 스크린에서도 접근 가능)
  - `SudaApiClient.getSeriesByCategory()`: 홈 카테고리별 시리즈 페이징 (`GET /v2/home/series?category={enumValue}&pageNum=…`, 0-based, size 4 가정). 응답 `SudaAppPage<HomeSeriesDto>`.
  - `SudaApiClient.getSeriesOverview()`: S2 시리즈 Overview (`GET /rps2/series/{seriesId}/overview`, 응답 `RpS2SeriesOverviewDto`). `SeriesOverviewScreen` 진입 시 호출.
  - `SudaApiClient.getSeriesBestScore()`: S2 시리즈 CEFR별 best score (`GET /rps2/series/{seriesId}/best-score`, 응답 `Map<int,int>`). `SeriesOverviewScreen`에서 언어레벨 변경 후 `bestScoreMap` 갱신.
  - `SudaApiClient.getNotifications()`: 알림함 목록 페이징 (`GET /v1/users/notification?pageNum=…`, `UserApi.getNotifications`) — 응답 원소 `NotificationDto`에 **readYn**(`Y`/`N`) 포함. 서버는 `sendFinishedAt` 기준 30일 초과 알림을 내려주지 않으며(배지·목록 일치), 카드 하단 상대 날짜도 동일 필드(`sendFinishedAt`)를 UTC로 파싱 후 로컬 달력 일 단위로 표시(`notification_box.dart`).
  - `SudaApiClient.markNotificationRead()`: 알림 읽음 처리 (`POST /v1/users/notification/{notificationId}/read`, `UserApi.markNotificationRead`) — 응답 `QuestResultDto`. GET에서 30일 초과로 빠진 항목도 서버가 ZSET에 남겨 둔 경우 POST 읽음은 성공할 수 있어, 재진입 시 `readYn`이 되돌아가지 않도록 한다.
  - `SudaApiClient.getLatestVersion(clientVersion: …)`: 최신 버전 정보 조회 (`GET /v1/latest-version?clientVersion={appVersion}`). `clientVersion`은 `AppVersionService.getAppVersion()`(패키지 `versionName`) 값.
    - 응답: `VersionDto` (latestVersion, forceUpdateYn, androidMarketLink?, appleMarketLink?)
    - 최신 버전 정보는 `TokenStorage.saveLatestVersion()`으로 영구 저장
    - 저장된 버전 정보는 `TokenStorage.loadLatestVersion()`으로 조회 가능
- **RestStatusService**: `lib/services/rest_status_service.dart`
  - 서비스 점검 대응용 restYn, restStartsAt, restEndsAt·**notiboxUnreadYn** 전역 보관
  - `GET /v2/home/contents` 응답 시 `RestStatusService.instance.update()`로 초기화/업데이트
  - 어떤 스크린에서도 `RestStatusService.instance.restYn` 등으로 접근 가능
  - `shouldShowRestOverlay()`: Overview 진입 전 휴식 레이어 노출 여부 (restYn=='Y' 또는 N이면서 UTC now가 restStartsAt~restEndsAt 사이)
- **휴식 안내 레이어 (RestOverlay)**: `lib/widgets/rest_overlay.dart`
  - Overview·Series Overview 진입 시 restYn 확인 후, 필요 시 레이어 노출·스크린 이동 중단 (`RoleplayRouter.pushOverview`, `SeriesRouter.pushOverview`)
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
  - `UserDto.upsertMetaInfo(key, value)`: metaInfo의 key/value를 upsert(키 중복 제거 후 1개로 유지)
  - `UserDto.hasMetaInfoValue(key, value)`: metaInfo에 특정 key/value가 존재하는지 체크

- **스크린 노출 통계(클라이언트 best-effort 호출)**
  - Tutorial 스크린이 실제로 노출되는 경우(완료 상태가 아니어서 화면을 보여주기로 확정된 경우): `POST /v1/users/tutorial-shown`
    - requestBody 없음, 응답/실패 무시 (호출만)
  - **Series Overview** 로드 시(`SeriesOverviewScreen._loadOverview`) 사용자의 `metaInfo`에 `FIRST_OVERVIEW == 'Y'`가 아니면 “첫 진입”으로 간주:
    - `POST /v1/users/first-overview` (requestBody 없음, 응답/실패 무시)
    - **중복 호출 방지**를 위해 클라이언트 전역 사용자 상태의 `metaInfo`에 `FIRST_OVERVIEW='Y'`를 즉시 주입한다(`MainUserSync.notifyUserUpdated`로 메인 전역 `_user` 갱신).

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

## 7-0. 인증/동의 플로우 메모
- 서비스 이용 동의(`SUDA_AGREEMENT`)가 필요할 때는 `LoginScreen` 위에 bottom-up 레이어(blur+dim)로 동의 UI를 노출한다. 동의 완료 시 `POST /v1/users/agreement`와 AppsFlyer `af_complete_registration` 이벤트를 호출한 뒤 **동의 직후 1회** `FirstCefrLevelScreen`(`lib/screens/first_cefr_level.dart`)으로 전환한다. Confirm 시 `PUT /v1/users/language-level` 호출 후 Main(Home) 진입(API 실패여도 Home). Lab 진입: Setting > Lab (`AppConfig.isDev` · `kDebugMode`). Lab에서 First CEFR / Paywall / IAP 테스트 가능. **IAP 진행상황은 §7-2**. 레이어를 동의 없이 닫을 때(dim 바깥 탭)는 로컬 JWT/refresh 삭제(`TokenStorage.clearTokens`)·`AuthService.signOut()`·메인 상태 초기화로 비로그인 `LoginScreen`으로 돌아간다.

## 7-1. Roleplay 스크린 컨텍스트

- Roleplay 관련 스크린 흐름 및 데이터 정책은 `.docs/CONTEXT_ROLEPLAY.md`를 참조한다.
- **S2 (Season 2) Roleplay 마이그레이션 진행상황**은 `.docs/CONTEXT_ROLEPLAY_S2.md`를 참조한다.
- Roleplay 세션 `sessionId`는 인메모리 공통 상태로 보관하고 롤플레이 종료 시 삭제됩니다.
- **RoleplayOpeningScreen** (S2): `SeriesStateService.selectedEpisode`의 `thumbnailImgPath` 배경·`title`/`briefing`·`aiCharacter.name` 본문. duration 헤더 없음. Start 시 `POST /rps2/sessions` (`seriesId`, `episodeId`) → `sessionId == '0'`이면 에너지 부족 팝업·Opening 유지, 정상 ID면 `SeriesStateService.setSession` 후 Playing(에너지 소비는 Playing 발화 처리 시).
- **RoleplayPlayingScreen** (S2): `lib/screens/roleplay/playing.dart`. S1 `playing_backup.dart`·세션/결과 API 클라이언트는 **삭제됨**(2026-06). 헤더: `RoleplayScaffold`·episode `title`(로컬 언어)·X→나가기 확인 레이어·우측 `kebab.png` 설정패널. 상세는 `.docs/CONTEXT_SCREEN.md` §13.
- **S1 Roleplay 잔여 코드 정리**(2026-06): `review_chat.dart`·`review_ending.dart`·`playing_backup.dart` 삭제. `result.dart`/`ending.dart`/`result_report.dart` S2 전용화. `RoleplayApi`는 `getRoleplayOverview`(딥링크 overview)·`updateSpeedRate`(Playing 속도)만 유지. Profile Saved는 `GET/DELETE /v1/users/expressions` + S2 TTS sound.

## 7-2. IAP (앱내결제) — 현재 진행상황 (2026-07)

### 한줄 요약
- **에너지 팝업** INAPP 3종 + **Paywall Premium 구독**(월/연) 결제·verify·성공/승인대기 UX 연동. Lab Query/Buy 콘솔은 제거됨.

### 완료됨
- 패키지: `in_app_purchase` + `in_app_purchase_android`
- 공용: `IapPurchaseService` — INAPP·**SUBS**(`subscription_premium` + `bp-premium-monthly`/`bp-premium-yearly` offer 선택)·verify·따닥 방지. 가격 `IapPriceCache`(SUBS는 `productId::basePlanId`). resume 2초 grace(스트림 미수신 시에만)·`abandonPendingPurchase`. 매칭 purchaseStream 수신 후에는 grace 재개 금지(verify 중 `storeDismissed`로 성공 덮어쓰기 방지).
- **IAP+verify 중**: `IapBusyOverlay`(`lib/utils/iap_busy_overlay.dart`) — rootNavigator 전면 dim+흰 스피너, 뒤로가기 불가. 에너지 팝업 INAPP·Paywall Assinar 공통.
- **consume/ack는 서버 verify 전담**. 클라이언트 `buyConsumable(autoConsume: false)`, `completePurchase` 미호출(전 상품: Unlimited·Capacity·Premium).
- Buy 시 obfuscatedAccountId = SHA-256(userId). verify body `{ purchaseToken, productId }` (SUBS도 동일, basePlanId 미포함).
- 응답 `successYn`/`pendingYn`.
- 에너지 팝업: INAPP 구매 + Go Premium → Paywall. pop(true) 시 Go Premium 1000ms 제거 + detail 재조회.
- Paywall: 스토어 가격(연간 raw/12 `/mês` + yearly `/ano`), Assinar agora 결제. 성공 → Completed → pop(true). pending → 토스트+pop(true). N → 실패 토스트.
- Completed: `paywall_completed.dart` (Continuar/X → pop(true)). Lab Preview 유지.
- 앱 버전: `1.2.0+48`

### 상품 ID (Play Console / `IapPurchaseService`)
| 구분 | productId | basePlanId / 비고 | 진입 | verify |
|------|-----------|-------------------|------|--------|
| INAPP | `unlimited_energy_10_minute` | consumable | 에너지 팝업 | O |
| INAPP | `energy_capacity_6` | — | 에너지 팝업 | O |
| INAPP | `energy_capacity_7` | — | 에너지 팝업 | O |
| SUBS | `subscription_premium` | `bp-premium-monthly` | Paywall | O |
| SUBS | `subscription_premium` | `bp-premium-yearly` | Paywall | O |

- Purchase option ID(`po-…`)는 조회 키가 **아님**. Billing에는 **productId**만 넣는다.
- 클라이언트는 Play에서 전 상품 목록을 못 뽑음 → ID는 앱에 하드코딩.

### 반드시 지킬 제약
1. IAP는 **applicationId(=패키지) 단위**. 상품은 prd `kr.sudatalk.app`에 있음 → **dev/local/stg 패키지로는 조회·구매 불가**.
2. 서버 verify의 `packageName`은 body에 없고 **ENV 고정** (local→`.local`, dev→`.dev`, stg→`.stg`, prd→`kr.sudatalk.app`). **산 패키지와 API ENV가 같아야** 함.
3. Lab 메뉴: `AppConfig.isDev || kDebugMode` (`setting.dart` / `lab.dart`). **prd release에서는 Lab 미노출**.
4. 스토어 설치본 ↔ 유선 설치본은 서로 업데이트 불가(정상). IAP 테스트는 한쪽만 쓰면 됨.
5. 라이선스 테스터·상품 Active 필요.

### 아직 안 함 (다음 작업 후보)
- Paywall/Completed 문구 l10n
- restore / 알림 설정 버튼(에너지 팝업 TBD)

### 관련 파일
- IAP 서비스: `lib/services/iap_purchase_service.dart`, `lib/services/iap_price_cache.dart`
- obfuscatedAccountId: `lib/utils/iap_obfuscated_account_id.dart`
- Verify API: `lib/api/endpoints/purchase_api.dart`, `lib/api/suda_api_client.dart`
- 에너지 구매 UI: `lib/widgets/energy_purchase_section.dart`, `lib/widgets/energy_info_popup.dart`
- Paywall: `lib/screens/paywall/paywall.dart`, `lib/screens/paywall/paywall_completed.dart`
- 스크린 문서: `.docs/CONTEXT_SCREEN.md` § PaywallScreen / PaywallCompletedScreen

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
  - 배경/테두리/블러(glassy): radius 16, blur sigma 12, 테두리 흰색 36%·1px, frost 그라데이션 흰색 18%→10%, 그림자 검정 14%·blur 10·offset (0,2). **전체 dim** 검정 40%.
  - 닫기 UX: 좌상단 닫기 아이콘은 사용하지 않으며, 필요 시 `buttons`에 **text 타입의 닫기 버튼**을 포함한다(라벨은 하드코딩 금지, 예: `l10n.closePopup`). 탭 시 팝업 닫힘 후 콜백 실행 규칙은 동일.
  - 카드 높이: 고정 높이 없이 내용에 따라 결정되되, **최대 높이는 화면 높이의 80%**로 캡되며 초과 시 **`topWidget + titleText + bodyWidget + buttons` 영역만 스크롤**(닫기 아이콘은 스크롤 미포함).
  - 본문 영역 패딩: 상 20 / 좌·우·하 16. `bodyWidget` 내부 레이아웃은 호출부 자율이며, `DefaultPopup`은 **topWidget ↔ title ↔ body ↔ buttons 사이**에만 세로 20 간격을 보장한다.
  - 버튼: `primary`(스펙상 이름은 `default`이나 Dart 예약어 회피, height 44, 라벨 너비 shrink-wrap·가운데 정렬, #0CABA8, Stadium, `ElevatedButtonTheme` 병합) / `text`(`TextButtonTheme` 병합, 흰색 텍스트, shrink-wrap·가운데 정렬). 버튼 탭 시 **항상 팝업을 닫은 뒤** 콜백을 호출한다.
  - 마이그레이션: 팝업 UI는 **점진적으로** `DefaultPopup`으로 옮긴다(동시 대량 치환 금지).
  - Dev 확인(Lab): `lib/screens/setting/lab.dart`의 `kLabDefaultPopupOptions`에 전환 완료 팝업을 등록한다. Lab **Default Popup Test**는 드롭다운 선택 + **Show Popup**으로 재현한다. 에너지 팝업은 별도 **Energy Popup Test**(playing·무제한·구독·show Unlimited/6/7·force Go Premium·0~5) 섹션에서 재현한다.

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
- **네이티브 스플래시**
  - **패키지**: `flutter_native_splash` (버전 2.3.10 이상) 사용
  - **설정**: `pubspec.yaml`의 `flutter_native_splash` 섹션에서 관리
  - **디자인 사양**: 어두운 단색 배경(`#121212`) 위에 `assets/images/splash_still_260513.png` 기반 Android 리소스 `splash_still.png`를 가로·세로 정중앙 노출한다. Android는 `launch_background.xml`의 `layer-list`에서 배경 shape + centered bitmap으로 처리한다. **밀도별 `splash_still.png` 픽셀**(논리 165×36dp 정합): mdpi 165×36, hdpi 248×54, xhdpi 330×72, xxhdpi 495×108, xxxhdpi 660×144. **Android 12(API 31)+** 는 시스템 스플래시가 `windowSplashScreenBackground`·`windowSplashScreenAnimatedIcon` 중심이라 `windowBackground` 비트맵이 나오지 않는 경우가 많다. **API 31+만** `assets/images/splash_still_square_v3.png`를 원본으로 한 **`res/drawable-v31/splash_still_square_v3.png`**(정사각형 합성 스틸)을 `windowSplashScreenAnimatedIcon`으로 둔다. 원본 수정 시 Android 쪽 PNG를 동기화한다.
  - **생성 명령**: `dart run flutter_native_splash:create`
  - **동작**: 앱 실행 시 자동 표시, `FlutterNativeSplash.preserve()`로 유지, JWT 확인 후 `FlutterNativeSplash.remove()` 호출
- **진입 흐름**
  - **앱 실행 시**: 네이티브 스플래시(중앙 스틸 이미지) → LoginScreen 또는 (토큰 유효 시) HomeScreen
  - **로그아웃 시**: 곧바로 LoginScreen
- **LoginScreen 진입 연출(개편 중)**: `lib/screens/login.dart`는 네이티브 스플래시와 동일한 중앙 스틸 이미지에서 시작한다. 앱 초기 인증 확인 중에는 `lib/main.dart`의 `_StartupSplashFrame`으로 동일한 Flutter 스틸 프레임을 유지하고, LoginScreen 진입 경로에서는 스틸/로고 자산을 `precacheImage`로 준비한 뒤 첫 Flutter 프레임 이후 `FlutterNativeSplash.remove()`를 호출해 네이티브→Flutter 전환 깜빡임을 줄인다. **모든 동작 전 1000ms 대기** 후, 서로 독립적으로: 중앙 스틸(`splash_still_260513.png`) **500ms** fade-out(`Curves.easeOut`), 로고 파트(`splash_still_logo_part.png`) **1000ms** 스틸 좌측 겹침 위치→화면 정중앙 이동(`Curves.easeOut`, opacity 유지). 콘텐츠 영역은 fade-in 없음. 상단 50% 포스터 각 행은 화면 밖에서 **1000ms** 슬라인 등장(`Curves.easeOutCubic` 감속) 후 마키: 1행 왼쪽→우측 흐름·**60s** 주기, 2행 오른쪽→좌측·**70s**, 3행 왼쪽→우측·**66s**. 로고 아래 노출 영역(환영·버튼·약관)은 하단 바깥에서 **1000ms** 상승(`easeOutCubic`).
- **CustomSplashScreen 제거**: 과거 네이티브 스플래시와 LoginScreen 사이에 표시하던 Flutter 커스텀 스플래시 애니메이션은 더 이상 사용하지 않는다.
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
  - FCM data에 `appPath`(문자열)와, 알림함 연동 시 `notificationId`·`addNotificationBoxYn`이 올 수 있다(suda-back `PushRoutingPayload`와 동일 키).
  - **명시 `appPath`**: 어드민/백이 넣은 경로를 그대로 따른다(백은 이 경우 `notificationId`를 data에서 제거).
  - **`appPath` 없이 알림함만 추가(Add Notibox=Y)**: 백이 `appPath`를 `/app/notification/{알림캠페인 id}` 형태로 넣고 `notificationId`를 동일 id로 둔다. 앱은 Alarm 탭으로 전환한 뒤 `NotificationBoxScreen`에서 해당 `id` 카드를 펼치고 `Scrollable.ensureVisible`(alignment 0)으로 상단에 맞춘다. 목록에 없으면 다음 페이지를 순차 로드해 찾거나, 끝까지 없으면 앵커만 해제한다.
  - **Add Notibox=N·`appPath` 없음**: 백이 `appPath`를 `home`으로 보내며 앱은 홈 탭으로 이동한다.
  - **`addNotificationBoxYn != 'Y'`인데 `appPath`가 비고 `notificationId`만 있는 경우**: pending에 `notificationId`를 넣지 않음(`_storeFcmNavigationFromData`). 적용 단계에서도 id-only 폴백은 `addNotificationBoxYn == 'Y'`일 때만 알림함, 그 외·미수신은 홈(`_applyPendingPushNavigation`).
  - **비로그인·동의 전**: `PendingAppPathService`에 보관 후, 로그인·동의 완료 뒤 Main 진입 시 한 번 `takePending()`으로 적용한다.
  - **이미 Main 진입 후**: 백그라운드에서 알림 탭 시에도 동일하게 pending에 넣고 다음 프레임에 적용한다.
  - `/notice/{noticeId}`는 알림함이 아닌 공지사항 상세(`AnnouncementDetailScreen`)로 직접 진입한다.
  - `/profile/history/{rpUserHistoryId}`는 `HistoryScreen`으로 진입하며, `GET /rps2/user-histories/{rpUserHistoryId}`로 상세를 조회한다.
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
  - **Default Markdown** (`lib/utils/default_markdown.dart`): 서버 텍스트의 `***`(볼드+이탤릭), `**`(볼드), `*`(이탤릭)만 파싱해 `TextSpan` 리스트로 변환하는 공통 로직. `***` → `**` → `*` 순서로 처리하며 중첩 미지원. 줄바꿈은 기존 그대로 유지. 적용 구역: **Ending** 콘텐츠 영역(`RoleplayEndingScreen`·`ReviewEndingScreen`의 content), **공지사항 목록/상세**(`AnnouncementsScreen`·`AnnouncementDetailScreen`), **알림함 목록**(`NotificationBoxScreen` 접힘/펼침 본문), **RoleplayOpeningScreen Briefing**(`bodyLarge`·흰색).
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
  - UI 요소의 화면상 좌표(Rect)가 필요할 때 `GlobalKey` 기반으로 `Rect`를 조회한다.
  - 현재 앵커: `EffectAnchorId.energyBadge` → Home 헤더 `EnergyHeaderBadge` 위치(`lib/screens/home.dart`, `registerEnergyBadgeAnchor: true`).
- **개별 효과 API**: `lib/effects/like_progress_effect.dart`
  - `LikeProgressEffect.play(context, params, onCompleted?)` 형태로 호출한다.
  - Phase 1(500ms): 딤은 알파 0→1. **BG(`like_progress_bg.png`)·엄지(`like_at_result.png`)** 는 동일 구간에서 스케일 2.0→0.7·Y 0→-50과 함께, **앞쪽 약 300ms(phase1 진행 `t` 0~0.6)** 에 알파 0→1(`Curves.easeOut`) 페이드인하며 **`t=0`(스케일 2.0)에서는 완전 투명**이다.
  - 파라미터/연출은 효과별 위젯(오버레이)에서 구현하며, 종료 콜백은 fade-out 등 정상화까지 완료된 뒤 1회 호출한다.
  - `LikeProgressOverlay`의 Phase 6 카운터 구간 시작 시 엄지 아이콘 주변에 `like_progress_star.png` 반짝임이 동시 3~5개 생성된다. 각 별은 시작 시점·위치 후보 4곳·크기(width 20~30)·주기를 미세하게 달리하며, 빠른 fade-in 후 soft fade-out(+소폭 scale-up) 1cycle을 반복한다. 활성 반짝임끼리는 최소 거리 검사를 적용해 겹침을 줄인다.
  - Phase 6 프로그레스바 진행 중에는 `VibrationPreset.rapidTapFeedback`를 반복 재생한다. 레벨업 시 진동은 앞뒤로 짧게 쉰 뒤 `VibrationPreset.doubleBuzz`로 재생하고, 이후 프로그레스 진동을 다시 이어간다.
  - 반짝임은 Phase 8 진입 전까지 재생되며, Phase 8에서는 dim, 엄지, 반짝임, 수치 영역이 함께 전체 fade-out 된다. bg 이미지는 Phase 7 종료와 동시에 즉시 화면에서 제거한다.
