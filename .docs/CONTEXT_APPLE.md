# CONTEXT_APPLE — iOS 시뮬레이터만의 주의점

출시 계획: `.docs/CONTEXT_IOS.md`  
**빌드 명령(공통):** `.docs/CONTEXT.md` §2

## Simulator ≠ Android Emulator
- 별도 앱 **Simulator**. IDE 안에 안 붙음 → `open -a Simulator`
- `flutter devices`에 ios가 없으면 먼저 부팅:

```bash
xcrun simctl list devices available | rg "iPhone|Booted|Shutdown"
xcrun simctl boot "iPhone 17"   # 또는 UDID
open -a Simulator
flutter devices                 # ios 줄이 보여야 함
```

기본 기기(이 Mac, 없으면 `simctl list`로 갱신):  
`iPhone 17` · `541F3961-8182-4414-9065-678C697363DF`

## Firebase / Google 로그인 (자동)
- Firebase 원본: `ios/Runner/Firebase/GoogleService-Info.{local,dev,prd}.plist` (841694 · FCM 등)
- Sign-In (local/dev non-prod 회원): `GoogleSignIn.{local,dev}.plist` — GCP **558349443875** iOS OAuth `CLIENT_ID`
- 빌드 페이즈 → `copy_google_service_info.sh`: Firebase plist 복사 + `generated_google_signin_client.dart` 생성
- env별 `SERVER_CLIENT_ID`: local/dev=558349 Web, prd=841694 Web (`AppConfig`와 동일)
- URL scheme: 841694 iOS 3종 `Info.plist` 등록됨. 558349 OAuth 발급 후 `register_google_signin_url_schemes.sh` 실행

### local/dev iOS Google 로그인 (558349) — 설정됨
- local: `558349443875-n542t9u0uald3fn0mfq1ni64be9r07nd…` → `GoogleSignIn.local.plist`
- dev: `558349443875-7quvithfufd1ps0i426vb56sut9s9ku9…` → `GoogleSignIn.dev.plist`
- `Info.plist` URL scheme 5종(841694×3 + 558349×2). 재빌드 후 `[Auth] iosClientId=558349…` · `hasIdToken=true` 확인

| 증상 | 조치 |
|------|------|
| Firebase not initialized | `Runner/Firebase/`에 해당 env plist 있는지 |
| 구글 로그인 시 앱 종료 | `Info.plist` URL scheme / 클린 재빌드 |
| 검정 스플래시 무한 | `main()` `getInitialMessage` 2초 timeout (`CONTEXT_IOS` 열린 이슈) |
| `iOS … is not installed` | Xcode → Settings → Platforms |
