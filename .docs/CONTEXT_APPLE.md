# CONTEXT_APPLE — iOS(Apple) 로컬 실행 치트시트

출시·계정·StoreKit 계획은 `.docs/CONTEXT_IOS.md`.  
**이 문서는 “dev 앱을 iOS 시뮬레이터에 띄우기”만** 다룬다. Android 에뮬레이터와 달리 **Simulator는 별도 macOS 앱**이다(Android Studio 안에 안 붙음).

## 0) 한 줄 목표

```bash
# 저장소 루트에서
flutter run --flavor dev -d <IOS_DEVICE_ID> --dart-define=ENV=dev
```

성공 시: iPhone 시뮬레이터에 SUDA 로그인 화면. Bundle ID는 `kr.sudatalk.app.dev`.

## 1) 사전 체크 (없으면 여기서 멈춤)

순서대로. 하나라도 실패하면 다음으로 가지 말 것.

| # | 확인 | 명령 / 기준 |
|---|------|-------------|
| 1 | Xcode | `xcodebuild -version` → Xcode 있음 |
| 2 | CocoaPods | `pod --version` |
| 3 | iOS SDK | `xcodebuild -showsdks`에 `iphonesimulator` |
| 4 | Flutter iOS | `flutter doctor`에 Xcode ✓ (Simulator runtime 경고면 Xcode → Settings → Platforms에서 iOS 설치) |
| 5 | Firebase plist | 파일 존재: `ios/Runner/GoogleService-Info.plist` (없으면 Firebase init 크래시). Bundle ID는 `kr.sudatalk.app.dev`여야 함 |
| 6 | 작업 디렉터리 | 저장소 루트 `/…/suda` |

## 2) 시뮬레이터 존재·부팅

```bash
# 목록 (Booted / Shutdown)
xcrun simctl list devices available | rg "iPhone|iPad|iOS"

# Flutter가 보는 기기 (부팅된 것만 ios로 잡히는 경우가 많음)
flutter devices
```

- 목록이 비면: Xcode에서 iOS runtime 설치 후 재시도.
- `flutter devices`에 iOS가 없고 `simctl`에만 Shutdown이면 **부팅 필요**:

```bash
# 이름 또는 UDID. 예: iPhone 17
xcrun simctl boot "iPhone 17"
# 또는
xcrun simctl boot "541F3961-8182-4414-9065-678C697363DF"

open -a Simulator
flutter devices   # iPhone … • <UDID> • ios 가 보여야 함
```

권장 기본 기기(이 Mac 기준, 바뀌면 `simctl list`로 갱신):  
`iPhone 17` · UDID `541F3961-8182-4414-9065-678C697363DF` · runtime iOS 26.3

## 3) 실행 (dev만)

```bash
cd /path/to/suda
flutter run --flavor dev -d "541F3961-8182-4414-9065-678C697363DF" --dart-define=ENV=dev
```

- `-d`에는 `flutter devices`의 **ios UDID**(또는 고유한 이름 접두)를 쓴다. Android 기기 ID를 넣지 말 것.
- `flutter run`에는 `--no-codesign` 없음(시뮬레이터는 기본으로 됨).
- 첫 빌드는 `pod install` 포함으로 수 분 걸릴 수 있음.
- 화면이 안 보이면 Dock에서 **Simulator** 앱을 연다. IDE 안에 에뮬창이 생기지 않는다.

## 4) 정상 / 실패 판별

| 로그·증상 | 의미 | 조치 |
|-----------|------|------|
| `Firebase has not been correctly initialized` | plist 없음/미포함 | `ios/Runner/GoogleService-Info.plist` 넣고 Xcode Resources에 포함 확인 |
| 검정 스플래시만 무한 | 예전엔 `getInitialMessage` hang | `lib/main.dart`에 2초 timeout 방어가 있어야 함. 상세: `CONTEXT_IOS.md` 「열린 이슈」 |
| `flutter: [BOOT] runApp()` 이후 로그인 UI | 정상 기동 | — |
| `iOS … is not installed` | runtime 미설치 | Xcode → Settings → Platforms |
| `No devices found` / ios 없음 | 시뮬 미부팅 | §2 `simctl boot` + `open -a Simulator` |

## 5) 하지 말 것

- Android `adb` / `R59M…` 디바이스로 iOS 실행 시도
- Firebase 콘솔의 “iOS SDK Podfile에 수동 추가”를 Flutter `Podfile`에 임의 삽입 (`flutter_install_all_ios_pods`가 처리)
- 상용 App Store ID를 **dev** Firebase 앱에 기입
- 출시·IAP·Apple 로그인 작업을 이 문서만 보고 진행 (`CONTEXT_IOS.md`)

## 6) 관련 경로

- 계획/열린 이슈: `.docs/CONTEXT_IOS.md`
- 앱 사실 기준: `.docs/CONTEXT.md` §3 iOS
- plist: `ios/Runner/GoogleService-Info.plist`
- scheme: `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme`
