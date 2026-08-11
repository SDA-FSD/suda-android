# Suda Application 프로젝트 컨텍스트

사실 기준. 코드 변경 시 이 문서도 갱신한다. 상세는 아래 맵의 전용 문서.

| 문서 | 언제 열까 |
|------|-----------|
| **이 파일** | 항상 |
| `CONTEXT_SCREEN.md` | 스크린 추가/수정 |
| `CONTEXT_STYLE.md` | 타이포·공통 UI |
| `CONTEXT_ROLEPLAY_S2.md` | 롤플레이 플로우·`/rps2` API |
| `CONTEXT_FPM_CUSTOM_URL.md` | FPM URL 패턴 추가 시만 |
| `CONTEXT_IOS.md` | iOS 남은 이슈(StoreKit 등) |
| `KEYSTORE.md` | Android 서명 |
| `CONTEXT_HISTORY.md` | 이력(사실 아님) |

대화에서 **AOS** = Android. iOS는 iOS로 표기.

## 1. 목적
Flutter 교육 앱. AI와 영어로 대화. API는 suda-api (`SudaApiClient`).

**Roleplay는 S2만 현행.** 홈은 시리즈 단위 → `SeriesOverviewScreen` → 에피소드 Play → Tutorial(미완료 시) → Opening → Playing → Ending/Result/Try Again. 복귀는 `RoleplayRouter.popToOverview` → `/series/overview`. 플레이 컨텍스트: `SeriesStateService`.

S1은 단일 RP 단위였고 플레이 경로는 제거됨. `RoleplayOverviewScreen`·`RoleplayApi.getRoleplayOverview`는 딥링크 잔존. `playing_backup` 없음.

## 2. 빌드·실행

루트에서. `{env}` = `local` | `dev` | `stg` | `prd`. iOS **stg Firebase 없음** → stg iOS 빌드 실패가 정상.

```bash
flutter devices
flutter run --flavor {env} -t lib/main.dart --dart-define=ENV={env} -d <DEVICE_ID>
```

APK 재설치: `adb -s <ID> install -r build/app/outputs/flutter-apk/app-{env}-release.apk` (debug면 `app-{env}-debug.apk`)

### Android
```bash
flutter run --flavor dev -t lib/main.dart --dart-define=ENV=dev -d R59M801MDFM
```
| 별칭 | DEVICE_ID |
|------|-----------|
| **A30** (기본) | `R59M801MDFM` |
| A23 | `R59T901DRQV` |
| A16 | `RF9XB00CX9J` |
| S8 | `ce041714d2f6348e0d` |

- `adb` 미인식: `export PATH=$PATH:~/Library/Android/sdk/platform-tools`
- 패키지: `kr.sudatalk.app` + `.local`/`.dev`/`.stg` (prd는 suffix 없음)
- local HTTP: `android/app/src/local` cleartext
- release: R8 ON. AGP 9 호환 `android.builtInKotlin=false`·`android.newDsl=false` 유지

### iOS
```bash
# 시뮬 없으면
xcrun simctl boot "iPhone 17"   # 또는 UDID
open -a Simulator
flutter run --flavor dev -t lib/main.dart --dart-define=ENV=dev -d 541F3961-8182-4414-9065-678C697363DF
```
- 기본 시뮬: iPhone 17 `541F3961-8182-4414-9065-678C697363DF`
- Bundle ID: Android와 동일 규칙 (stg는 골격만)
- Firebase plist·Google URL scheme: 빌드가 `ios/scripts/copy_google_service_info.sh`로 처리. **수동 스왑 금지**
- `--no-codesign`은 `flutter run`에 없음(시뮬 OK)
- **열린 이슈:** `getInitialMessage` hang → `main()` 2초 timeout 유지. 근본 원인 수정 후에도 timeout은 유지
- 마이크: Opening Start에서만 요청. iOS `PERMISSION_MICROPHONE=1` + `NSMicrophoneUsageDescription` 필수
- 남은 작업(StoreKit·stg Firebase 등): `CONTEXT_IOS.md`

| 증상 | 조치 |
|------|------|
| Firebase not initialized | `ios/Runner/Firebase/`에 해당 env plist |
| 구글 로그인 시 앱 종료 | `Info.plist` URL scheme / 클린 재빌드 |
| 검정 스플래시 무한 | `getInitialMessage` 2초 timeout |
| `iOS … is not installed` | Xcode → Settings → Platforms |

## 3. 환경 (`lib/config/app_config.dart`)

| ENV | API | CDN | Google server client (idToken) |
|-----|-----|-----|--------------------------------|
| local | `http://10.0.2.2:8083` (AOS 에뮬; iOS는 `localhost`/`IOS_LOCAL_API_URL`) | `https://cdn.dev-sudatalk.kr` | local/dev 공용 Web† |
| dev | `https://api.dev-sudatalk.kr` | 상동 | † |
| stg | `https://api.stg-sudatalk.kr` | 상동 | Android도 미비 |
| prd | `https://api.sudatalk.kr` | `https://cdn.sudatalk.kr` | prd Web |

† local/dev: `558349443875-ceevp4cjf86ubp0p066qm5hsujukljg4…` / prd: `841694444330-g8gn852m4somers2668v46k3mm69p7dg…` (`app_config.dart` 원천)

- AOS Google 문자열: `android/app/src/{env}/res/values/strings.xml`
- iOS Firebase 원본: `ios/Runner/Firebase/GoogleService-Info.{local,dev,prd}.plist` → 빌드 시 전체 복사 → `Runner/GoogleService-Info.plist`
- **회원 이원화:** non-prod idToken aud=558349 Web / prd aud=841694 Web. Firebase(FCM)는 841694 plist 유지
- **iOS Sign-In (local/dev):** `GoogleSignIn.{local,dev}.plist`(GCP 558349 iOS OAuth) → `generated_google_signin_client.dart` → `AuthService.clientId`
- URL scheme: `Info.plist`에 841694×3 + 558349×2 (`register_google_signin_url_schemes.sh`)

## 4. 인증·API

구조: `lib/api/suda_api_client.dart` → HTTP `lib/api/client/suda_http_client.dart` · 엔드포인트 `lib/api/endpoints/*` · DTO `lib/models/*`. `lib/services/suda_api_client.dart`는 re-export.

- **Google:** `AuthService.signInWithGoogle()` → idToken → `loginWithGoogle()` JWT
- **Apple:** `signInWithApple()` — identityToken·**raw nonce**(요청은 SHA-256 hex)·최초 email/fullName. `POST /v1/auth/apple`. provider=`apple`(이메일 같아도 별계정). `authorizationCode`는 로그인 필수 아님
  - iOS: local/dev/prd. AOS: **dev/prd only** (local·stg AOS 미지원)
  - AOS Services ID: `AppConfig.appleServicesId`. redirect → 서버가 `signinwithapple` intent
  - Login UI: **iOS는 Apple 위**, **AOS는 Google 위**
- JWT·deviceId: `TokenStorage` (secure storage). deviceId는 최초 1회 생성
- 언어: `LanguageUtil` ISO 639-1 → `TokenStorage` SharedPreferences. 로그아웃 시 토큰과 함께 삭제
- `UserDto`: provider/sub/name/email/profileImgUrl, 통계, `metaInfo`(`SudaJson`). `upsertMetaInfo` / `hasMetaInfoValue`
- Main 복귀 시 `_syncUserOnMainRouteReturn` → `GET /v1/users`. 레벨·진행률은 `GET /v1/users/profile`
- Tutorial 실노출: `POST /v1/users/tutorial-shown` (실패 무시)
- Series Overview 첫 진입: `POST /v1/users/first-overview` + 클라 `FIRST_OVERVIEW=Y` 즉시 주입

### 에너지
- **simple** `GET /v1/users/energy/simple`: 배지·Playing·구독 상태 등. 상품 플래그 없음
- **detail** `GET /v1/users/energy/detail?screen=…`: 팝업 오픈·팝업 재조회·구매 후만
- Playing 중 **사용자 발화 처리마다** 1 소비. Start 시 소비 없음
- 구독 아이콘: `lib/utils/energy_icon.dart`. 배지 `EnergyHeaderBadge`. 팝업 `showEnergyInfoPopup`
- 비가시(비활성 탭·위 라우트)면 타이머·GET 중단. 결제 성공은 `EnergyRefreshBus`로 추가 GET 없이 반영
- Playing 0/402 → `showPlayingEnergyInsufficientPopup` → `endRoleplay`면 Wait 레이어(세션 유지)
- Opening Start `sessionId=='0'` → 에너지 부족 팝업, Opening 유지
- 팝업 INAPP 탭: `POST /v1/impressions/products` (팝업 생명주기 내 동일 키 1회)

### 홈·시리즈
- `GET /v2/home/contents` → banners, seriesList, restYn, notiboxUnreadYn. `RestStatusService`에 rest·배지 동기화
- 썸네일 탭 → `SeriesRouter.pushOverview`. 카테고리 페이징 `GET /v2/home/series`
- rest 중 Overview 진입 시 `RestOverlay` (`shouldShowRestOverlay`)

### 알림함
- `GET /v1/users/notification` (`readYn`, `sendFinishedAt` 30일). 읽음 `POST …/notification/{id}/read`
- GNB 빨간 점: `notiboxUnreadYn`. 목록에 미읽음 없으면 배지 `N` 보정

기타 엔드포인트 세부는 코드·`CONTEXT_ROLEPLAY_S2.md` API 표. 버전 체크: `VersionCheckService` — 강제 업데이트/`forceUpdateYn==Y` 또는 네트워크 실패 시 팝업 후 종료, 통과 후에만 JWT.

## 5. 앱 아이콘
원본 `assets/images/app_icon.png`. `flutter pub run flutter_launcher_icons` (`pubspec.yaml`).

## 6. 스토리지
- **캐시** (`getTemporaryDirectory` 등): 다시 받을 수 있는 것. OS/캐시삭제로 사라져도 됨. **이미지 작업 전 캐시 사용 여부 확인**
- **보존** (`getApplicationDocumentsDirectory` / SharedPreferences): 녹음·설정 등. 로그아웃/초기화 때만 삭제

## 7. 스크린
상세: `CONTEXT_SCREEN.md`. 스크린 작업 시 그쪽도 갱신.

- 동의(`SUDA_AGREEMENT`): Login 위 레이어. 완료 시 `POST /v1/users/agreement` + AppsFlyer `af_complete_registration` → **1회** `FirstCefrLevelScreen` → Confirm `PUT /v1/users/language-level` 후 Home(실패여도 Home). 레이어 닫기(미동의)는 토큰 삭제·비로그인
- Lab: Setting > Lab (`AppConfig.isDev` · `kDebugMode`). **prd release 미노출**

롤플레이 상세: `CONTEXT_ROLEPLAY_S2.md`.

## 7-2. IAP (현행)

에너지 팝업 INAPP 3종 + Paywall Premium 월/연. `IapPurchaseService`. consume/ack는 **서버 verify 전담**. Lab Query/Buy 콘솔 없음.

| 구분 | productId | basePlanId | 진입 |
|------|-----------|------------|------|
| INAPP | `unlimited_energy_10_minute` | consumable | 에너지 팝업 |
| INAPP | `energy_capacity_6` / `energy_capacity_7` | — | 에너지 팝업 |
| SUBS | `subscription_premium` | `bp-premium-monthly` / `bp-premium-yearly` | Paywall |

- Billing 키는 **productId만** (`po-…` 아님). ID는 앱 하드코딩
- verify: `{ purchaseToken, productId, offerSessionId?, paywallSessionId?, basePlanId? }`
- Paywall impression: mount `POST /v1/impressions/subscriptions` `{screen}` → sessionId. CTA `PUT` `{paywallSessionId, basePlanId}`. Lab skip
- Change Plan: 월간 구독자만 (`bp-premium-monthly`) → 연간, `ReplacementMode.withoutProration`
- Speech Feedback: `feedbackLockedYn=='Y'` → Paywall. `'N'` → feedback TTS 준비 후 펼침+재생(실패 시 펼침만). 접기는 잠금 검사 없음. 상세 `CONTEXT_ROLEPLAY_S2.md`
- **제약:** 상품은 prd 패키지 `kr.sudatalk.app`. verify `packageName`은 ENV 고정 → **산 패키지 = API ENV**. 스토어본↔유선본 상호 업데이트 불가
- TBD: restore / 에너지 팝업 알림 설정
- iOS StoreKit: 아직 (`CONTEXT_IOS.md`)

## 8. 스타일
사실 기준: `CONTEXT_STYLE.md`. UI 수정 시 그쪽도 갱신. 테마: `lib/theme/app_theme.dart`.

- **DefaultPopup** `lib/widgets/default_popup.dart` — 점진 마이그레이션. 라벨 하드코딩 금지
- 사용자 표시 기본 텍스트는 **영어**. 언어별 동적 문구만 예외

## 9. 스플래시·Login
네이티브 스플래시 `#121212` + 중앙 스틸. `FlutterNativeSplash.preserve` → JWT 후 remove. Login은 동일 스틸에서 페이드/로고 이동/포스터 마키(상세 `CONTEXT_SCREEN.md` Login). CustomSplash·LoadingScreen 없음. 로그아웃 → 곧장 Login.

## 10. 푸시
`firebase_messaging`. Home `initState`에서 토큰 `POST /v1/users/push-token` (`deviceType` ANDROID|IOS, `languageCode`, 실패 무시).

클릭 `appPath`: 비로그인·동의 전은 `PendingAppPathService`. 경로 표·규칙은 `CONTEXT_SCREEN.md` appPath.

## 10-1. FPM
dev·prd만 ON. `PerfMonitoringService` + `SudaHttpClient` `HttpMetric`(query 제외). iOS 네이티브 연동은 추후.

커스텀 트레이스: `home_load`, `series_overview_load`, `roleplay_session_start`, `roleplay_screen_ready`, `roleplay_turn_total`, `audio_upload`, `feedback_screen_ready`, `purchase_before_token`, `purchase_after_token`.

**URL 패턴 목록·추가 절차:** `CONTEXT_FPM_CUSTOM_URL.md`.

## 11. 코드 습관
- 로그: `debugPrint('[DEBUG] …')` (`print` 금지)
- 토스트: `lib/utils/default_toast.dart`
- 서버 마크다운 `***`/`**`/`*`: `lib/utils/default_markdown.dart` (Ending content, 공지, 알림함, Opening briefing)
- Like 진행 오버레이: `EffectOverlayService` + `LikeProgressEffect` (`lib/effects/like_progress_effect.dart`). 동시 1개. 앵커 `EffectAnchorId.energyBadge`

## 12. 이력
`.docs/CONTEXT_HISTORY.md` (오래된 것: `CONTEXT_HISTORY_ARCHIVE.md`)
