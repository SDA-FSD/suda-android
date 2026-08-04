# iOS 병행 운영·App Store 출시 계획

**빌드·실행 명령:** `.docs/CONTEXT.md` §2  
**시뮬레이터 부팅/Firebase 자동장착만:** `.docs/CONTEXT_APPLE.md`  
이 문서는 출시 단계 계획·열린 이슈용.

## 현재 상태와 확정 범위

- 확정 범위: **iPhone+iPad**, **local/dev/stg/prd 4환경**, **Sign in with Apple 추가**, **에너지 INAPP 3종과 Premium 월/연 구독 전체 지원**.
- **골격·dev 시뮬레이터 기동까지 진행됨(2026-07):** `ios/Podfile`, local/dev/stg/prd scheme, Bundle ID `kr.sudatalk.app[.local|.dev|.stg]`, deployment 15.0, `Runner.entitlements`, 마이크 권한, `AppConfig` iOS local API 분기. Firebase 원본 `ios/Runner/Firebase/GoogleService-Info.{local,dev,prd}.plist` + 빌드 페이즈 `Copy GoogleService-Info`(`ios/scripts/copy_google_service_info.sh`)로 장착본 자동 생성. `Info.plist`에 Google URL scheme 3종 등록. Xcode·시뮬레이터로 `flutter run --flavor dev`·로그인 화면까지 확인.
- **Sign in with Apple 클라 골격(2026-07):** `sign_in_with_apple`, `POST /v1/auth/apple`, Login 플랫폼별 버튼 순서, Android Manifest callback, entitlements `com.apple.developer.applesignin` 이미 포함. Console(dev/prd) 등록 완료. **실연동 검증은 dev API 배포 후**. local Android Apple·stg는 미지원.
- 아직 남은 것: Apple 로그인 **실기기 E2E(dev 배포 후)**, APNs 실연동, StoreKit, 강제업데이트 App Store 링크, iPad 회귀 등(아래 단계 4~9). stg Firebase plist는 미구현.
- Dart Android 가정도 상당수 남음: `[lib/api/endpoints/push_api.dart](lib/api/endpoints/push_api.dart)` `deviceType: ANDROID`, `[lib/services/iap_purchase_service.dart](lib/services/iap_purchase_service.dart)` Play 전용, `[lib/services/app_dialog_service.dart](lib/services/app_dialog_service.dart)` Play Store 위주.

## 마이크 권한 (Opening Start)

- **요청 시점:** 앱 기동이 아니라 **RoleplayOpeningScreen `Let's Start`** 탭 시 (`lib/screens/roleplay/opening.dart`).
- **필수 설정 (둘 다 필요)**
  1. `ios/Runner/Info.plist` — `NSMicrophoneUsageDescription` (사용자에게 보여줄 문구)
  2. `ios/Podfile` `post_install` — `GCC_PREPROCESSOR_DEFINITIONS`에 **`PERMISSION_MICROPHONE=1`**  
     (`permission_handler_apple` 기본값이 0이라 없으면 iOS에서 `Permission.microphone.request()`가 빌드에서 빠져 no-op처럼 동작할 수 있음)
- **흐름:** status 확인 → 필요 시 request → 영구 거부 시 설정 다이얼로그 → (선택) `openAppSettings()` → 앱 복귀 후 Opening(또는 홈) 유지 → 사용자가 **다시 Start**. 자동 재개/스택 복구 없음.
- **로컬 네트워크 권한 팝업:** 불필요 기능이면 Release(`flutter run --release`)로 재현 확인. Debug의 Flutter VM/mDNS만으로 뜨는 경우가 많음. Release에서도 뜨면 SDK(Firebase/AppsFlyer 등) 원인 조사.
- **상세 UX:** `.docs/CONTEXT_ROLEPLAY_S2.md` §4-3 Start.

## 열린 이슈 (잊으면 안 됨)

- **`FirebaseMessaging.getInitialMessage()` iOS hang → 스플래시 영구 정지**
  - **증상:** `lib/main.dart` `main()`에서 `runApp` 전에 `await getInitialMessage()`가 끝나지 않으면 네이티브 스플래시(`#121212`)만 남고 UI가 안 뜸. iPhone 17 시뮬레이터(dev)에서 재현·로그로 확인함.
  - **임시 방어(유지):** 동일 호출에 **2초 `timeout`**. 타임아웃/실패 시에도 `runApp` 진행. 앱 기동 차단을 막는 필수 방어이므로 **근본 원인 수정 후에도 유지**한다.
  - **근본 원인(미해결):** APNs/FCM iOS 연동 미완(시뮬레이터 한계·entitlements·권한·토큰 준비 순서 등 후보). **단계 5에서 원인 규명·실기기 검증**할 것. 닫을 때 이 섹션을 “해결됨”으로 옮기거나 삭제.

## 단계 0 — 계정·권한·정책 사전 점검

- **프로젝트 외부:** 조직 Apple Developer의 Team ID, Account Holder/Admin/App Manager/Developer 역할, 인증서·Identifiers 접근권한, App Store Connect 계약 상태를 확인합니다. 유료 앱 계약, 세금·은행 정보가 미완료면 IAP 등록·판매보다 먼저 끝냅니다.
- **프로젝트/백엔드:** iOS Bundle ID를 Android와 같은 의미로 `kr.sudatalk.app.local`, `.dev`, `.stg`, 운영 `kr.sudatalk.app`으로 고정하고, local/dev/stg가 사용할 Firebase 프로젝트와 Google OAuth Web client를 명시합니다. 현재 stg는 Android Firebase 파일과 Google server client ID도 비어 있으므로 이 단계에서 함께 정리합니다.
- **이유:** Bundle ID는 서명, Firebase, Google 로그인, Sign in with Apple, APNs, StoreKit의 공통 키이며 출시 뒤 변경할 수 없습니다.
- **완료 조건:** 4환경 ID·앱명·API/Firebase 매핑, 조직 역할, 운영 앱의 카테고리·판매 국가·개인정보 책임자가 문서로 확정됩니다.

## 단계 1 — Mac iOS 개발 도구 설치

- **로컬 외부 작업:** App Store 또는 Apple Developer에서 Xcode 26 이상을 설치하고 `xcode-select`, first launch, 라이선스, iOS/iPadOS 26 Simulator runtime을 설정합니다. CocoaPods를 설치하고 `flutter doctor -v`가 iOS 항목까지 통과하도록 합니다.
- **실기기:** 최소 iPhone 1대와 iPad 1대를 조직 팀에 연결하고 Developer Mode·신뢰·자동서명을 확인합니다. 푸시와 실제 StoreKit은 Simulator만으로 최종 검증할 수 없습니다.
- **이유:** 현재는 Command Line Tools만 선택되어 있어 `xcodebuild`, iOS 플러그인 링크, 실행, Archive가 불가능합니다.
- **완료 조건:** `flutter doctor -v`, `xcodebuild -version`, `pod --version`, `flutter devices`에서 Xcode·Simulator·실기기가 정상 인식됩니다.

## 단계 2 — iOS 프로젝트와 4환경 빌드 기반 구축

- **프로젝트 내부:** `[ios/Podfile](ios/Podfile)`과 lockfile을 현재 Flutter 템플릿 기준으로 만들고, `[ios/Flutter](ios/Flutter)`에 환경별 xcconfig, `[ios/Runner.xcodeproj/xcshareddata/xcschemes](ios/Runner.xcodeproj/xcshareddata/xcschemes)`에 local/dev/stg/prd shared scheme을 둡니다. Debug/Profile/Release × 4환경을 연결하고 Bundle ID·표시명·`ENV` dart-define이 한 환경에서 자동으로 일치하게 합니다.
- `[ios/Runner.xcodeproj/project.pbxproj](ios/Runner.xcodeproj/project.pbxproj)`에 조직 Team, 자동서명, iPhone+iPad 대상, deployment target을 반영합니다. 현재 13.0은 Xcode 26 지원 범위를 확인한 뒤 최소 15.0 이상으로 정렬합니다.
- `[ios/Runner/Info.plist](ios/Runner/Info.plist)`은 표시명을 빌드 변수로 받고, `[ios/Runner/Runner.entitlements](ios/Runner/Runner.entitlements)`를 추가해 capability를 코드와 함께 버전 관리합니다.
- **외부:** Apple Developer에 4개 Explicit App ID를 등록하되 App Store Connect 앱 레코드와 판매 상품은 운영 ID에만 연결합니다.
- **이유:** Android flavor와 iOS scheme이 수동으로 어긋나면 운영 앱이 dev API나 잘못된 Firebase/IAP를 사용하는 치명적 사고가 납니다.
- **완료 조건:** 각 환경에서 `flutter build ios --no-codesign --flavor <env> --dart-define=ENV=<env>`가 성공하고 산출물의 Bundle ID·앱명·ENV가 일치합니다.

## 단계 3 — 기본 실행·권한·로컬 네트워크·화면 적합성

- `[lib/config/app_config.dart](lib/config/app_config.dart)`의 local API host를 플랫폼별로 나눕니다. iOS Simulator는 Mac의 `localhost`, 실기기는 Mac의 LAN 주소 또는 HTTPS 개발 도메인을 사용하고, HTTP가 꼭 필요하면 **local configuration에만** ATS 예외를 둡니다.
- `[ios/Runner/Info.plist](ios/Runner/Info.plist)`에 실제 기능 기준의 `NSMicrophoneUsageDescription` 등 권한 문구를 en/ko/pt 정책에 맞춰 추가합니다. 알림 권한은 푸시 단계에서 사용자 맥락과 함께 요청합니다.
- 앱 아이콘의 alpha 제거, `#121212` launch 화면, 네이티브→Flutter splash 전환을 iPhone/iPad에서 확인합니다. 현재 `TARGETED_DEVICE_FAMILY=1,2`이므로 iPad를 단순 호환 모드가 아닌 정식 지원 대상으로 회귀 테스트합니다.
- **이유:** plist 문구 누락은 런타임 종료 또는 심사 거절로 이어지고, Android 전용 local 주소는 iOS에서 통신되지 않습니다.
- **완료 조건:** 4환경 기본 부팅, local/dev API 연결, 마이크 허용·거부·설정 복귀, 세 언어, 작은 iPhone과 13인치 iPad의 핵심 화면이 정상입니다.

## 단계 4 — Firebase·Google 로그인·Sign in with Apple

- **Firebase/Google 외부:** 4개 Bundle ID를 해당 Firebase 프로젝트의 iOS 앱으로 등록하고 환경별 `GoogleService-Info.plist`, iOS OAuth client와 reversed client URL scheme을 발급합니다. plist 선택은 build configuration으로 자동화해 운영 파일 혼입을 막습니다.
- **Google 로그인 내부:** `[lib/services/auth_service.dart](lib/services/auth_service.dart)`와 로그인 UI를 iOS OAuth 설정 및 Apple HIG에 맞추고, iOS Google idToken이 기존 서버 검증을 통과하는지 확인합니다.
- **Apple 로그인 내부·백엔드:** Sign in with Apple capability와 Flutter 인증 모듈을 추가하고, 서버에 Apple identity token/authorization code 검증, `iss/aud/nonce/sub` 확인, 최초 1회 name/email 저장, private relay email, refresh/revoke, 기존 계정 연결·중복 방지 정책을 구현합니다. provider별 자동 로그인·로그아웃도 공통 인증 인터페이스로 정리합니다.
- `[lib/screens/setting/account.dart](lib/screens/setting/account.dart)`의 기존 탈퇴 흐름은 서버 완료를 확인하고 Apple refresh token revoke, 구독 관리 안내, 로컬 토큰 삭제 순서를 보장하도록 점검합니다. 계정 생성 앱은 [앱 안에서 계정 삭제](https://developer.apple.com/support/offering-account-deletion-in-your-app/)가 가능해야 합니다.
- **외부:** App ID에 Sign in with Apple을 켜고 필요 키를 발급합니다. 한국 조직이 신규/변경 Services ID를 웹 로그인에 연결한다면 2026년부터 요구되는 HTTPS server-to-server notification endpoint를 등록하며, account-deleted·consent-revoked·email relay 변경도 서버에서 처리합니다.
- **이유:** Google만으로는 일반 소비자 앱이 [App Review Guideline 4.8](https://developer.apple.com/app-store/review/guidelines/)을 충족하기 어렵고, Apple은 이메일을 첫 인증 때만 제공하므로 서버 설계를 먼저 확정해야 합니다.
- **완료 조건:** 신규·기존 Google 사용자, Apple 공개/가리기 이메일, 취소, 재로그인, 로그아웃, 계정 연결·탈퇴를 Sandbox와 실기기에서 검증합니다.

## 단계 5 — APNs/FCM 푸시 동등 지원

- **외부:** Apple Developer에서 APNs `.p8` key를 만들고 Key ID/Team ID와 함께 Firebase에 업로드합니다. 운영 App ID에는 Push Notifications를 켭니다.
- **내부:** entitlements의 `aps-environment`, Background Modes의 remote notification, Firebase swizzling 정책을 설정합니다. 알림 권한 요청과 APNs token 준비 후 FCM token 취득 순서를 구현하고, `[lib/api/endpoints/push_api.dart](lib/api/endpoints/push_api.dart)`는 플랫폼별 `ANDROID`/`IOS`를 보냅니다.
- **백엔드:** deviceType enum·토큰 저장·발송 경로를 iOS로 확장하고 기존 `appPath`, 알림함, foreground/background/terminated payload를 APNs 제약에 맞춰 시험합니다.
- **열린 이슈 포함:** 상단「`getInitialMessage` iOS hang」근본 원인을 이 단계에서 규명한다(시뮬레이터 vs 실기기). `main()`의 2초 timeout 방어는 제거하지 않는다.
- **이유:** Firebase plist만 추가해서는 APNs 권한·키·토큰 등록이 완료되지 않습니다.
- **완료 조건:** dev/prd 실기기에서 권한 허용/거부, 토큰 갱신, 세 앱 상태, 알림 탭 딥링크, 로그아웃 후 토큰 정책이 통과합니다. `getInitialMessage`가 실기기에서 합리적 시간 내 완료(또는 null)되는지 확인하고, hang 이슈를 문서에서 닫습니다.

## 단계 6 — StoreKit 구매·구독·서버 검증

- **외부:** App Store Connect에서 운영 앱에 consumable 3종, Premium 월/연 auto-renewable subscription을 만들고 구독 그룹, 지역별 가격, 표시명·설명·심사용 스크린샷을 등록합니다. Play의 단일 `subscription_premium`+base plan과 달리 App Store는 월/연 상품 ID를 분리하는 매핑을 확정합니다.
- **내부:** `[lib/services/iap_purchase_service.dart](lib/services/iap_purchase_service.dart)`를 공통 orchestration + Play/StoreKit adapter로 분리합니다. StoreKit 상품 조회·가격, purchase stream, pending/cancel/error, 서버 검증 성공 후 transaction finish, 앱 시작 시 미완료 거래 회복을 구현합니다. consumable은 복원하지 않고 Premium 구독에는 명시적 **Restore Purchases**와 상태/관리 링크를 제공합니다.
- **백엔드:** 기존 Play `purchaseToken/packageName` 검증과 별도로 App Store signed transaction/JWS 또는 App Store Server API 검증, bundleId·environment·product mapping, originalTransactionId 기반 entitlement, 환불·취소·갱신·billing retry를 구현합니다. App Store Server Notifications V2의 Sandbox/Production URL도 등록하고 idempotency를 보장합니다.
- **이유:** 현재 Android 타입 캐스팅과 서버 consume/ack 정책은 StoreKit transaction finish·구독 복원 모델과 호환되지 않습니다. 자동 갱신 구독은 지원 기기 간 entitlement와 복원 수단이 필요합니다.
- **완료 조건:** Xcode StoreKit 테스트 → Sandbox Apple Account 실기기 → TestFlight 순으로 구매 5종, 취소, pending, 중복 탭, 재설치·다른 기기 복원, 갱신/만료/환불, 서버 장애 후 재처리를 검증합니다.

## 단계 7 — 나머지 플랫폼 서비스와 심사 준수

- `[lib/services/app_dialog_service.dart](lib/services/app_dialog_service.dart)`는 `VersionDto.appleMarketLink`를 사용해 App Store를 열고, iOS에서 `SystemNavigator.pop()`으로 앱을 강제 종료하지 않는 차단 UX로 바꿉니다. 서버 최신버전 정책도 Android/iOS 버전을 구분할 수 있는지 확인합니다.
- `[lib/services/appsflyer_service.dart](lib/services/appsflyer_service.dart)`에 Apple App ID를 넣고, 실제 추적 목적에 따라 ATT 요청 여부·시점·`NSUserTrackingUsageDescription`을 결정합니다. 불필요한 추적이면 ATT를 무조건 추가하지 않고 SDK 수집을 최소화합니다.
- Firebase Analytics/Performance의 iOS 수집을 기존 dev/prd ON, local/stg OFF 정책에 맞춥니다. 포함 SDK의 privacy manifest, required-reason API, dSYM 업로드와 개인정보 라벨 입력 근거를 인벤토리화합니다.
- **선택 범위:** 현재 앱의 `appPath`는 푸시 내부 라우팅입니다. 웹 Universal Links/AppsFlyer OneLink가 실제 요구될 때만 Associated Domains·AASA·외부 링크 라우팅을 별도 작업으로 추가합니다.
- **완료 조건:** 강제 업데이트, 분석 이벤트, 성능 trace, 크래시 없는 권한 흐름과 privacy manifest 경고 없는 Archive를 확인합니다.

## 단계 8 — iPad·접근성·회귀 품질

- 로그인, 동의, Home, Series, Roleplay 녹음/키보드, Result, Profile, Setting, Paywall, 팝업을 작은 iPhone·큰 iPhone·11/13인치 iPad에서 검사하고, 과도한 stretch에는 최대 폭/중앙 column을 적용합니다. 세로 고정 정책과 iPad 멀티태스킹 동작도 명시합니다.
- Dynamic Type, VoiceOver label, 대비, Safe Area, 키보드, 마이크·푸시 거부 상태를 확인합니다. iPad 지원을 선언한 만큼 13인치 iPad 스크린샷과 실제 사용성이 심사 대상입니다.
- 기본 템플릿인 `[test/widget_test.dart](test/widget_test.dart)`를 유효한 smoke test로 교체하고 인증·환경·스토어 매핑 단위 테스트와 핵심 integration smoke test를 추가합니다.
- **완료 조건:** 플랫폼 공통 기능은 Android 회귀 없이 통과하고, iPhone/iPad 핵심 여정과 en/ko/pt가 정해진 테스트 매트릭스에서 통과합니다.

## 단계 9 — Archive·TestFlight·App Store Connect

- **App Store Connect 외부:** 운영 Bundle ID로 앱 레코드와 SKU를 만들고 이름/부제/설명/키워드/카테고리/연령등급, 지원 URL, 필수 개인정보처리방침 URL, 저작권, 판매 국가, 암호화 수출규정, 콘텐츠 권리, EU 배포 시 DSA trader 정보를 입력합니다.
- 앱과 Firebase·Google·AppsFlyer·결제 SDK가 수집하는 데이터를 기준으로 [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)를 작성합니다. iPhone은 6.5/6.9인치 중 한 규격, iPad는 13인치 스크린샷을 최소 세트로 준비하고 필요 언어를 현지화합니다.
- `pubspec.yaml`의 version/build를 공통 원천으로 유지하되 Android와 iOS 모두에서 단조 증가하도록 릴리스 규칙을 정합니다. prd Archive를 Validate 후 업로드하고 내부 TestFlight → 외부 TestFlight/Beta Review → 단계적 App Review 순으로 진행합니다.
- 심사 노트에는 로그인 가능한 리뷰 계정 또는 완전한 리뷰 경로, 마이크 사용 이유, 롤플레이 재현법, Apple 로그인, 구매·복원 위치, 계정 삭제 위치, 백엔드 접근 조건을 적습니다. 첫 구독/IAP도 앱 버전과 함께 심사에 연결합니다.
- **완료 조건:** App Store Connect의 missing compliance가 없고 TestFlight 실기기 회귀, IAP/푸시 서버 운영 환경, App Review 제출 준비가 모두 완료됩니다.

## 단계 10 — Android+iOS 지속 유지보수 체계

- CI를 `flutter analyze`·`flutter test`·Android dev build·macOS iOS no-codesign build로 시작하고, 이후 App Store Connect API key를 비밀 저장소에 둔 signed archive/TestFlight 자동화를 추가합니다. 인증서·`.p8`·App Store key·keystore는 절대 Git에 넣지 않습니다.
- 환경 매트릭스, 신규 SDK 추가 시 Android Manifest+iOS plist/entitlements/privacy manifest 동시 점검, 양 플랫폼 릴리스 체크리스트를 코드 리뷰 기준으로 만듭니다.
- `[README.md](README.md)`, `[.docs/CONTEXT.md](.docs/CONTEXT.md)`, `[.docs/CONTEXT_SCREEN.md](.docs/CONTEXT_SCREEN.md)`, `[.docs/CONTEXT_STYLE.md](.docs/CONTEXT_STYLE.md)`, `[.docs/CONTEXT_HISTORY.md](.docs/CONTEXT_HISTORY.md)`에 iOS 빌드·권한·인증·푸시·IAP·화면 변경을 단계별로 반영하고 별도 iOS setup/signing/release 문서를 둡니다.
- **완료 조건:** 새 개발자가 문서만으로 4환경 실행을 재현하고, Android/iOS 변경 누락을 CI와 리뷰 체크리스트가 탐지합니다.

## 권장 실행 단위와 게이트

- **M1 개발 실행:** 단계 0~4 완료 후 Simulator/실기기에서 로그인·Home·마이크까지 실행.
- **M2 기능 패리티:** 단계 5~7 완료 후 푸시·IAP·강제업데이트·분석까지 dev/Sandbox 검증.
- **M3 Universal 품질:** 단계 8 완료 후 iPhone+iPad 회귀와 접근성 통과.
- **M4 출시:** 단계 9 완료 후 TestFlight와 App Review 제출.
- **M5 운영:** 단계 10으로 양 플랫폼 릴리스 자동화·문서 정착.

## 이번 요청의 PATCHES / CHECK

- **PATCHES:** 없음. 저장소 파일, Apple/Firebase/App Store 콘솔을 변경하지 않았습니다.
- **CHECK:** 실제 작업을 시작할 때는 각 M 단위를 다시 5줄 이내 PLAN과 파일별 최소 PATCHES로 나누고, 사용자 확인 후에만 진행합니다.
