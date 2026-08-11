# iOS — 남은 case-by-case

일상 빌드·시뮬·Firebase plist·Google scheme·마이크·스플래시 hang 방어는 **`.docs/CONTEXT.md` §2**.

iOS는 골격·로그인·푸시 토큰 `deviceType=IOS`까지 들어갔고, 이제 아래만 필요할 때 연다.

## 열린 이슈 (유지)
- `FirebaseMessaging.getInitialMessage()` hang → `main()` **2초 timeout**. 근본 원인(APNs/시뮬)은 미해결. timeout은 원인 수정 후에도 유지.

## 아직 안 함
- **StoreKit** IAP (현재 `IapPurchaseService`는 Play). 월/연 상품 ID 매핑·restore·서버 JWS 검증
- **stg** Firebase plist / Google iOS OAuth
- 강제업데이트 iOS: `VersionDto.appleMarketLink` + iOS에서 `SystemNavigator.pop()` 지양
- iPad 회귀·ATT(필요할 때만)
- FPM iOS 네이티브 플러그인 (Dart 헬퍼는 있음)

## 마이크 (Opening Start)
앱 기동 시 요청하지 않음. `RoleplayOpeningScreen` Start → status/request → 영구거부 시 설정 안내만, 복귀 후 사용자가 다시 Start.  
필수: `Info.plist` `NSMicrophoneUsageDescription` + Podfile `PERMISSION_MICROPHONE=1`. UX: `CONTEXT_ROLEPLAY_S2.md` Opening Start.

## App Store 상수 (출시 때)
- Team `DWBJM357N6` · Apple ID `future.strategy.division@gmail.com`
- 운영 Bundle `kr.sudatalk.app`. 버전은 `pubspec.yaml` 공통
- Export: `ITSAppUsesNonExemptEncryption=false`
- NSE 버전: `NotificationService.xcconfig`가 Flutter `FLUTTER_BUILD_NAME`/`NUMBER`와 동기화 (ITMS-90473 재발 방지)
- 업로드: `flutter build ipa --flavor prd` 후 exportArchive upload
