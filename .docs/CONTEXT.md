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
- 남은 작업(stg Firebase 등): `CONTEXT_IOS.md`

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
- **Custom (iOS 심사):** LoginScreen 중앙 로고 **5연타**(진입 애니 완료 후) → Email/Password dialog → `POST /v1/auth/custom` `{ id, password, deviceId }`. **ENV 제한 없음**(local/dev/stg/prd 모두, iOS만). 응답·후처리는 Apple과 동일(`SudaAuthTokens` → `saveTokens` → `onSignIn`)
  - iOS: local/dev/prd. AOS: **dev/prd only** (local·stg AOS 미지원)
  - AOS Services ID: `AppConfig.appleServicesId`. redirect → 서버가 `signinwithapple` intent
  - Login UI: **iOS는 Apple 위**, **AOS는 Google 위**
- JWT·deviceId: `TokenStorage` (secure storage). deviceId는 최초 1회 생성
- 언어: `LanguageUtil`의 플랫폼 `languageCode` → `TokenStorage` SharedPreferences. 로그아웃 시 토큰과 함께 삭제
- 정적 UI l10n: `lib/l10n/app_en.arb`가 canonical이고 `flutter gen-l10n` 생성물도 같은 디렉터리에 커밋한다. 지원 locale은 `en`, `ko`, `pt`(ID는 generic `pt`, 문구는 브라질 포르투갈어), `es_419`, `ja`, `zh_Hans`, `zh_Hant`, `fr`, `de`, `it`, `vi`, `th`, `id`, `ms`, `fil`, `hi`, `ar`, `tr`, `ru`, `pl`, `nl`.
  - Flutter fallback 요건으로 `app_es.arb`는 `es_419`, `app_zh.arb`는 `zh_Hans`와 locale ID 외 동일하게 유지한다. `l10n.yaml`은 기본 fallback `en`과 중남미 스페인어 선택을 위해 `es_419`를 우선한다.
  - AOS 13+ 앱 언어 목록: `android/app/src/main/res/xml/locales_config.xml` + Manifest `android:localeConfig`. 위 21개만 등록(하이픈 태그 `es-419`/`zh-Hans`/`zh-Hant`). 폴백 전용 `es`/`zh`는 목록에 넣지 않음.
  - `MaterialApp`은 `AppLocalizations.localizationsDelegates`/`supportedLocales`를 사용하며 플랫폼 locale의 region/script를 보존한다. API·동적 콘텐츠(`SudaJson`·맵, Opening `briefingAudio`)는 서버 키 대소문자 구분 BCP 47(`ko-KR`) → languageCode(`ko`) → `en` 순으로 조회한다 (`LanguageUtil.localizationLookupKeys`).
  - **[강제] UI 문자열 추가·변경 시 전체 locale 확장:** 사용자/작업 입력이 `en`·`ko`·`pt`만 있어도, agent는 “나머지 언어 번역할까?”를 **묻지 말고** 위 지원 locale **전부(21개)**의 `app_*.arb`에 동일 키를 즉시 작성·저장한다. `en`을 의미 canonical로, `ko`/`pt`를 문맥 참고로 쓰며, 키·`@` metadata·placeholder 이름/타입·`@@TIME@@`·의도된 개행·ICU 형태를 보존한다. `app_es.arb`는 `es_419`와, `app_zh.arb`는 `zh_Hans`와 locale ID 외 동기화한다. 저장 후 `flutter gen-l10n`까지 수행하고, 생성 Dart도 커밋 대상에 포함한다. 부분 locale만 남기는 것은 금지.
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
- Enable Notifications 슬롯: detail `showEnablePushFreeChargeYn=Y` **그리고** `screen` ∈ {`home`,`opening`,`opening_insufficient`}. 탭 시 impression `productId=enable_push_free_charge` → `GET /v1/users` → PushAgreement Sub Screen. `completeYn=Y`면 토스트(에너지 팝업 경로만) + 제거 애니 + detail 재조회. Setting>Notification 자동닫힘은 토스트 없음. OFF→ON OS 권한: iOS FCM settings, AOS `Permission.notification`. iOS ON 성공 시 `POST /v1/users/push-token` 추가(실토큰만, 상세 `CONTEXT_SCREEN.md` PushAgreement)

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
- Lab: Setting > Lab (`AppConfig.isDev` · `kDebugMode`). **prd release 미노출**. Tutorial 미리보기: 21 locale 선택 후 Open Tutorial (`RoleplayTutorialScreen(preview: true)`)

롤플레이 상세: `CONTEXT_ROLEPLAY_S2.md`.

## 7-2. IAP (현행)

에너지 팝업 INAPP 3종 + Enable Notifications(비IAP) + Paywall Premium 월/연. `IapPurchaseService`. Lab Query/Buy 콘솔 없음.

| 구분 | AOS productId | iOS productId | basePlanId (stat) | 진입 |
|------|---------------|---------------|-------------------|------|
| INAPP | `unlimited_energy_10_minute` | 동일 | consumable | 에너지 팝업 |
| INAPP | `energy_capacity_6` / `energy_capacity_7` | 동일 | — | 에너지 팝업 |
| 비IAP | `enable_push_free_charge` | 동일 | — | 에너지 팝업(home/opening/opening_insufficient) |
| SUBS | `subscription_premium` | `premium_monthly` / `premium_yearly` (그룹 `22321554`, level 1) | `bp-premium-monthly` / `bp-premium-yearly` | Paywall |

- Billing 키는 **productId만** (`po-…` 아님). ID는 앱 하드코딩
- verify `POST /v1/purchases/verify`. AOS body 변경 없음 `{ purchaseToken, productId, offerSessionId?, paywallSessionId?, basePlanId? }`. iOS만 `platform:"IOS"` + StoreKit 2 JWS 전체(`serverVerificationData`). 구독 iOS `productId`는 ASC ID. `basePlanId`는 클라가 `bp-premium-*`로 매핑(**stat 전용**, entitlement는 Apple JWS/ASSN)
- 응답 `{ successYn, pendingYn, finishYn }`. AOS는 `finishYn` 무시(consume/ack 서버). **iOS는 `finishYn=Y`만** `completePurchase`. Play `PurchaseStatus.pending` 또는 verify `pendingYn=Y`는 **실패가 아님**: overlay 종료 + `energyPurchasePendingApproval` 토스트 + **현재 화면 유지**. unfinished/pending인 **같은 productId**만 재구매 disable(전면 UI·다른 상품은 열림). 이후 purchased는 orphan verify. 지급은 웹훅+다음 energy refresh.
- Restore/Change Plan verify: `offerSessionId`/`paywallSessionId` 없음. Restore는 트랜잭션당 1회, **소모품 호출 금지**. 미finish 재시도: iOS는 다음 `purchaseStream`(StoreKit 재전달) + 같은 verify. **AOS는 `purchaseStream` + `queryPastPurchases`**. **앱 기동 즉시** `ensureListening`(Home 대기 없음). 토큰 없으면 unfinished queue, overlay 없음. JWT 세션 복원은 queue를 verify. **신규 로그인**의 pre-login unfinished는 iOS `appAccountToken` 미전송이라 현재 계정에 붙이지 않음(finish 안 함). AOS는 `obfuscatedAccountId`가 현재 userId 해시와 같을 때만 verify. 서버 idempotency는 **transactionId 단위**(originalTransactionId는 구독 chain 식별, renewal 중복 처리 금지). Home `ensureListening`은 idempotent. `purchaseToken`당 verify 1회.
- Paywall impression: mount `POST /v1/impressions/subscriptions` `{screen}` → sessionId. CTA `PUT` `{paywallSessionId, basePlanId}`. Lab skip. Restore/Change Plan은 `store_purchase_completed` 집계 안 함
- Change Plan: 월간 구독자만 (`subscriptionBasePlanId==bp-premium-monthly`) → 연간. AOS `ReplacementMode.withoutProration`. iOS 같은 그룹 `premium_yearly` 구매(다음 renewal crossgrade). verify 직후 simple은 계속 monthly
- Restore UI: **Paywall 하단 링크 + Setting Account 다음 행, iOS만**. 에너지 팝업에는 없음
- 에너지 팝업 구매 성공: 해당 슬롯 1초 숨김 애니 후 `GET energy/detail` refetch. **AOS resume grace 최대 10s**(Play 시트 dismiss). 매칭 스트림이 오면 즉시 종료(purchased→verify, pending→승인대기 토스트). 만료 시 `queryPastPurchases`로 purchased/pending 회수, 없으면 `storeDismissed`. **iOS overlay:** 상품 조회·verify만 전면 스피너. **StoreKit 시트 구간 스피너 없음**(buy 직전 `storeSheet`). resume 후 15s UI watchdog은 overlay만 해제(`processing`), 트랜잭션은 취소하지 않음. verify HTTP timeout은 failure가 아니라 `processing` + retry/orphan, **finish 안 함**. 늦은 성공은 화면이 바뀌어도 토스트(`iapPurchaseCompleted`) 또는 Paywall Completed 최소 1회. **AOS는 Play 시트 뒤 스피너 유지.** AOS도 미ack/미consume orphan verify. iOS orphan/simple bus가 와도 팝업은 detail을 다시 받아 같은 애니로 슬롯을 가림. Paywall/에너지 팝업 dispose `abandonPendingPurchase`는 UI Future만 닫고, 스토어 런치 이후 inFlight는 유지. 이후 콜백은 세션을 이어받아 orphan verify.
- Speech Feedback: `feedbackLockedYn=='Y'` → Paywall. 구독 성공 시 history 재조회에만 `?reason=subscription`. `'N'` → feedback TTS 준비 후 펼침+재생(실패 시 펼침만). 접기는 잠금 검사 없음. 상세 `CONTEXT_ROLEPLAY_S2.md`
- **제약:** 상품은 prd 패키지 `kr.sudatalk.app`. verify `packageName`은 ENV 고정 → **산 패키지 = API ENV**. 스토어본↔유선본 상호 업데이트 불가. iOS IAP 테스트는 **prd + TestFlight**
- `appAccountToken` 안 보냄. 로그인 전 unfinished를 신규 로그인 계정에 자동 귀속하지 않음. ASSN V2 `POST /v1/billing/webhook` (반영 배치 약 2분)

## 8. 스타일
사실 기준: `CONTEXT_STYLE.md`. UI 수정 시 그쪽도 갱신. 테마: `lib/theme/app_theme.dart`.

- **DefaultPopup** `lib/widgets/default_popup.dart` — 점진 마이그레이션. 라벨 하드코딩 금지
- 사용자 표시 기본 텍스트는 **영어**. 언어별 동적 문구만 예외
- **RTL 크롬:** `ar` 등에서 헤더 leading/trailing은 `PositionedDirectional`·`AlignmentDirectional`·`TextAlign.start`. 학습 영어(미션·힌트·채팅)와 마이크 드래그 취소(물리 왼쪽)는 LTR/좌표 유지. 진행 바 fill·장식 절대좌표는 미러하지 않음.

## 9. 스플래시·Login
네이티브 스플래시 `#121212` + 중앙 스틸. `FlutterNativeSplash.preserve` → JWT 후 remove. Login은 동일 스틸에서 페이드/로고 이동/포스터 마키(상세 `CONTEXT_SCREEN.md` Login). CustomSplash·LoadingScreen 없음. 로그아웃 → 곧장 Login.

## 10. 푸시
`firebase_messaging`. Home `initState`에서 `POST /v1/users/push-token` (`deviceType` ANDROID|IOS, `languageCode`, `languageTag` BCP 47 예: `ko-KR`, 실패 무시). `LanguageUtil.getCurrentLanguageTag()` = `platformDispatcher.locale.toLanguageTag()` (region 없으면 languageCode만).
- AOS: FCM 토큰 없으면 호출 안 함.
- iOS: APNs 대기 **최대 3초**. 알림 거부·APNs/FCM 실패여도 `pushToken=""` + `languageCode`/`languageTag`는 보냄. 이후 토큰이 생기면 같은 API로 재등록.

클릭 `appPath`: 비로그인·동의 전은 `PendingAppPathService`. 경로 표·규칙은 `CONTEXT_SCREEN.md` appPath.

## 10-1. FPM
dev·prd만 ON. `PerfMonitoringService` + `SudaHttpClient` `HttpMetric`(query 제외). iOS 네이티브 연동은 추후.

커스텀 트레이스: `home_load`, `series_overview_load`, `roleplay_session_start`, `roleplay_screen_ready`, `roleplay_turn_total`, `audio_upload`, `feedback_screen_ready`, `purchase_before_token`, `purchase_after_token`.

**URL 패턴 목록·추가 절차:** `CONTEXT_FPM_CUSTOM_URL.md`.

## 11. 코드 습관
- 폰트: 풀 가변 `ChironHeiHK` / `ChironGoRoundTC` (`assets/fonts/*-VariableFont_wght.ttf`). 상세 `CONTEXT_STYLE.md`
- 로그: `debugPrint('[DEBUG] …')` (`print` 금지)
- 토스트: `lib/utils/default_toast.dart`
- 서버 마크다운 `***`/`**`/`*`: `lib/utils/default_markdown.dart` (Ending content, 공지, 알림함, Opening briefing)
- Like 진행 오버레이: `EffectOverlayService` + `LikeProgressEffect` (`lib/effects/like_progress_effect.dart`). 동시 1개. 앵커 `EffectAnchorId.energyBadge`

## 12. 이력
`.docs/CONTEXT_HISTORY.md` (오래된 것: `CONTEXT_HISTORY_ARCHIVE.md`)
