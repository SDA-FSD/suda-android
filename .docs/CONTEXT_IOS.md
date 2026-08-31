# iOS — 남은 case-by-case

일상 빌드·시뮬·Firebase plist·Google scheme·마이크·스플래시 hang 방어는 **`.docs/CONTEXT.md` §2**.

iOS는 골격·로그인·푸시 토큰 `deviceType=IOS`까지 들어갔고, 이제 아래만 필요할 때 연다.

## 열린 이슈 (유지)
- `FirebaseMessaging.getInitialMessage()` hang → `main()` **2초 timeout**. 근본 원인(APNs/시뮬)은 미해결. timeout은 원인 수정 후에도 유지.

## 아직 안 함
- **stg** Firebase plist / Google iOS OAuth
- iPad 회귀·ATT(필요할 때만)
- FPM iOS 네이티브 플러그인 (Dart 헬퍼는 있음)

## StoreKit IAP
- `IapPurchaseService`: AOS Play 유지. iOS는 `premium_monthly`/`premium_yearly` + INAPP 동일 ID. `platform:"IOS"`, JWS, `finishYn=Y`만 finish. StoreKit 시트 구간 blocking overlay 없음. listener는 앱 기동 즉시. Restore는 Paywall+Setting(iOS). 상세 **`.docs/CONTEXT.md` §7-2**
- 테스트: **prd** Bundle `kr.sudatalk.app` · TestFlight. local/dev/stg 상품 없음
- `appAccountToken` 생략. 시뮬은 StoreKit Configuration 없이 실결제 불가

## 마이크 (Opening Start)
앱 기동 시 요청하지 않음. `RoleplayOpeningScreen` Start → status/request → 영구거부 시 설정 안내만, 복귀 후 사용자가 다시 Start.  
필수: `Info.plist` `NSMicrophoneUsageDescription` + Podfile `PERMISSION_MICROPHONE=1`. UX: `CONTEXT_ROLEPLAY_S2.md` Opening Start.
지원 locale별 시스템 마이크 문구는 `Runner/*.lproj/InfoPlist.strings`의 `NSMicrophoneUsageDescription`으로 유지한다(`es`/`es-419`, `zh`/`zh-Hans`/`zh-Hant` 포함).

## App Store 상수 (출시 때)
- Team `DWBJM357N6` · Apple ID `future.strategy.division@gmail.com`
- 운영 Bundle `kr.sudatalk.app`. 버전은 `pubspec.yaml` 공통
- 정적 UI 지원 언어는 `Runner/Info.plist`의 `CFBundleLocalizations`와 Xcode `knownRegions`를 `AppLocalizations.supportedLocales`와 함께 유지한다. Flutter fallback용 `es`·`zh`도 등록한다.
- Export: `ITSAppUsesNonExemptEncryption=false`
- NSE 버전: `NotificationService.xcconfig`가 Flutter `FLUTTER_BUILD_NAME`/`NUMBER`와 동기화 (ITMS-90473 재발 방지)
- 업로드: `flutter build ipa --flavor prd` 후 exportArchive upload
