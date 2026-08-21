# Suda Application 스크린 정의서

이 문서는 앱 내 모든 스크린에 대한 상세 정보를 담고 있습니다.  
**스크린 관련 작업 시 이 문서를 함께 업데이트해야 합니다.**

---

## 스크린 타입 정의

앱 내 모든 스크린은 다음 3가지 타입 중 하나로 분류됩니다. 각 타입별로 UI 구성, 네비게이션 방식, 뒤로가기 동작이 다릅니다.

### 1. Full Screen (전체 화면)

**정의**: 독립적으로 표시되는 전체 화면 스크린

**특징**:
- GNB(Global Navigation Bar) 없음
- 독립적인 화면으로 표시
- 시스템 뒤로가기 버튼 클릭 시: **앱 종료**
- 일반적으로 인증 화면 등 초기 진입 화면에 사용

**사용 예시**:
- LoginScreen (로그인 화면)

**구현 규칙**:
- `Scaffold` 사용 (GNB 없음)
- 시스템 뒤로가기 처리: `WillPopScope` 또는 `PopScope`로 앱 종료 처리
- 전체 화면을 독립적으로 구성
- 전환 방식은 기본 일반 노출을 유지하고, 필요할 때만 optional transition으로 확장
- optional transition 예시: `bottom-up` (기존 화면을 아래에서부터 덮으며 올라오는 Full Screen)
- `bottom-up`은 **새 스크린 타입이 아니라 Full Screen의 선택 가능한 진입 효과**로 취급

---

### 2. Main Screen (메인 화면)

**정의**: GNB(Global Navigation Bar)를 가지고 있는 메인 화면

**특징**:
- **하단 네비게이션 바 (GNB) 필수 포함**
- GNB 위치: 안드로이드 시스템 네비게이션 바 바로 위
- GNB 색상: 안드로이드 시스템 네비게이션 바와 색상 통일 (이질감 없도록)
- 로그인 직후 또는 GNB 클릭을 통해 접근 가능
- 시스템 뒤로가기 버튼 클릭 시: Home 탭에서는 앱 종료, Alarm/Profile 탭에서는 Home 탭으로 이동

**GNB 구성**:
- Alarm / Home / Profile. Profile은 `profileImgUrl` 원형(없으면 default)

**사용 예시**:
- NotificationBoxScreen (알림함 화면) - Main Screen
- HomeScreen (홈 화면) - Main Screen
- ProfileScreen (프로필 화면) - Main Screen 속성

**구현 규칙**:
- `Scaffold` 사용
- 하단에 `BottomNavigationBar` 또는 커스텀 GNB 위젯 필수
- GNB 색상은 시스템 네비게이션 바와 통일
- GNB를 통해 다른 Main Screen으로 전환 가능

---

### 3. Sub Screen (서브 화면)

**정의**: GNB 없이, 기존 화면을 우측에서부터 덮어서 노출되는 전체화면 스크린

**특징**:
- GNB 없음
- **iOS 스타일 슬라이드 애니메이션**: 우측에서 좌측으로 슬라이드되어 표시
- **우측 상단 X 버튼 필수**: 닫기 버튼 (`Icons.close` 또는 `Icons.clear`)
- X 버튼 클릭 시: 오른쪽으로 밀려나가며 이전 화면(Main/Sub/Full Screen) 노출
- 시스템 뒤로가기 버튼 클릭 시: X 버튼과 동일한 동작 (오른쪽으로 슬라이드 아웃)
- Main Screen, Sub Screen, Full Screen 모두에서 진입 가능

**사용 예시**:
- 상세 화면
- 설정 화면
- Series Overview, Setting, History 등

**구현 규칙**:
- `Scaffold` 사용 (GNB 없음)
- 네비게이션: `Navigator.push()` 사용 (iOS 스타일 슬라이드 애니메이션)
- 우측 상단에 X 버튼 필수 (`AppBar`의 `leading` 또는 `actions`에 배치)
- X 버튼 클릭 시: `Navigator.pop()` 호출
- 애니메이션: iOS 스타일 슬라이드 (기본 `MaterialPageRoute` 또는 커스텀 `PageRouteBuilder`)
- **배경색**: 기본 배경색과 동일 (`Color(0xFF121212)`)

---

### 스크린 타입별 비교표

| 구분 | Full Screen | Main Screen | Sub Screen |
|------|-------------|-------------|------------|
| GNB | ❌ 없음 | ✅ 있음 (하단) | ❌ 없음 |
| 독립적 표시 | ✅ 예 | ✅ 예 | ❌ 아니오 (덮어서 표시) |
| 진입 애니메이션 | 일반 전환 (optional bottom-up 가능) | 일반 전환 | 우측→좌측 슬라이드 |
| 뒤로가기 버튼 | ❌ 없음 | ❌ 없음 | ✅ 있음 (우측 상단 X) |
| 시스템 뒤로가기 | 앱 종료 | Home: 앱 종료 / Alarm·Profile: Home으로 | 슬라이드 아웃 |
| 사용 예시 | LoginScreen | NotificationBoxScreen, HomeScreen, ProfileScreen | 상세 화면, 설정 화면 |

---

## 네이티브 스플래시 화면

### 스플래시 관련 정의 파일
- **패키지**: `flutter_native_splash` (버전 2.3.10 이상)
- **설정 파일**: `pubspec.yaml`의 `flutter_native_splash` 섹션
- **Android**: `android/app/src/main/res/drawable/launch_background.xml`, `android/app/src/main/res/drawable-v21/launch_background.xml`
- **iOS**: `ios/Runner/Base.lproj/LaunchScreen.storyboard` (자동 생성)

### 스플래시 용도
- 앱 실행 직후 Flutter 엔진 초기화 및 JWT 인증 상태 확인 중 표시
- 어두운 단색 배경(`#121212`) 위에 `splash_still.png`를 가로·세로 정중앙 노출
- JWT 토큰 확인 및 서버 검증 완료 후 자동 제거

### 표시 조건
- 앱 실행 시 자동 표시
- `FlutterNativeSplash.preserve()`로 Flutter 엔진 초기화 후에도 유지
- `FlutterNativeSplash.remove()` 호출 시 제거

### 제거 시점 및 이후 화면
- JWT 토큰이 없을 때: `_checkAuthStatus()`에서 제거 → LoginScreen
- JWT 토큰이 유효할 때: 서버 검증 완료 후 제거 → HomeScreen(또는 서비스 동의 레이어)
- JWT 토큰이 유효하지 않을 때: 에러 처리 후 제거 → LoginScreen

### 스플래시 내부 구현 특이사항
- **배경색**: `#121212`
- **중앙 이미지**: `assets/images/splash_still_260513.png` 기반 밀도별 `splash_still.png`(mdpi 165×36 ~ xxxhdpi 660×144 픽셀, 논리 165×36dp 유지)
- **Android 구현**: `launch_background.xml`의 `layer-list`에서 배경 shape + `android:gravity="center"` bitmap
- **생성 방법**: `dart run flutter_native_splash:create`로 기본 리소스 생성 가능. Android 중앙 스틸은 `launch_background.xml`과 밀도별 `splash_still.png`로 유지.
- **Android 12+(API 31) 지원**: `windowSplashScreenAnimatedIcon` → `drawable-v31/splash_still_square_v3.png`(원본 `assets/images/splash_still_square_v3.png`와 동기화). API 30 이하는 기존 `launch_background` + 가로형 `splash_still` 유지. `LaunchTheme`은 `values-v31` / `values-night-v31`
- **제어 방법**: `lib/main.dart`에서 `FlutterNativeSplash.preserve()` 및 `FlutterNativeSplash.remove()` 사용

---

## 1. LoginScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/login.dart`
- **클래스명**: `LoginScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (인증 플로우)
- **진입 연출**: `#121212` 배경 위 중앙 스틸에서 시작한다. **1000ms 대기** 후 스틸 500ms fade-out, 로고 파트 1000ms 중앙 이동, 포스터·하단 영역은 fade-in 없이 각각 등장 연출한다. 포스터 1~3행은 행별로 화면 밖→노출 위치 1000ms(`easeOutCubic`) 슬라인 후 마키(1행 좌에서 등장·우로·60s, 2행 우에서 등장·좌로·70s, 3행 좌에서 등장·우로·66s). 하단 노출 영역은 화면 아래 밖에서 1000ms 상승(`easeOutCubic`).
- **서비스 이용 동의(레이어)**: 로그인 후 사용자 metaInfo의 `SUDA_AGREEMENT != 'Y'`인 경우, LoginScreen 위에 **bottom-up 레이어**(배경 blur+dim)로 동의 UI를 노출한다. 레이어 바깥 탭 시 닫힌다. 동의 완료 시 `POST /v1/users/agreement` + AppsFlyer `af_complete_registration` 이벤트를 호출한 뒤 **FirstCefrLevelScreen**(§1.2)으로 전환한다.

---

## 1.2 FirstCefrLevelScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/first_cefr_level.dart`
- **클래스명**: `FirstCefrLevelScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (온보딩 플로우)

### 스크린 용도
- 서비스 이용 동의를 **방금 완료한 세션**에서 1회만 노출되는 CEFR 레벨 선택 화면
- Setting `CefrLevelScreen`과 동일 API(`PUT /v1/users/language-level`) 사용

### 이전 스크린 정보 (진입점)
- **LoginScreen 동의 레이어**: `_onAgreementComplete` → `main.dart` `_needsFirstCefrLevel = true`

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HomeScreen(Main)**: Confirm 탭 시 API 호출 후 `_onFirstCefrLevelComplete`(실패해도 Home)

### 스크린 내부 구현 특이사항
- **배경**: `#121212`. **PopScope** `canPop: false`(시스템·스와이프 백 차단)
- **레이아웃**: 상·중·하 3등분(`Expanded`×3). 상단·하단은 각각 2등분 가상선 기준 배치
- **중앙**: `PageView` 캐러셀(Pre-A1~B1, 기본 포커스 **A1**, 무한루프 없음). 포커스 원 40% width·`#0CABA8`, 대기 원 90%·반원 peek. 좌우 `#121212` 60%→0% 그라데이션. 스냅 후 `Vibration` 80ms
- **Confirm**: width 70%·흰 배경·Stadium·검정 텍스트. l10n `firstCefrLevel*`
- **Lab(dev)**: Setting > Lab > **Open First CEFR Level**

---

### 스크린 용도
- Google 로그인을 위한 인증 화면
- 로그인되지 않은 사용자에게 표시
- Google Sign-In을 통해 idToken 획득 후 SUDA 서버에 JWT 발급 요청

### 이전 스크린 정보 (진입점)
- **네이티브 스플래시**: 앱 실행 후 토큰이 없거나 유효하지 않을 때 (`FlutterNativeSplash.remove()` 직후)
- **HomeScreen**: 로그아웃 시 (`onSignOut` 콜백 호출) → 곧바로 LoginScreen 표시
- **조건**: `_MyAppState`의 `_accessToken == null`일 때 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HomeScreen**: Google 로그인 성공 및 JWT 토큰 발급 성공 시 (`SUDA_AGREEMENT == 'Y'`)
  - `onSignIn` 콜백 호출 → `_MyAppState._onSignIn()` 실행 → 상태 업데이트로 자동 전환
- **FirstCefrLevelScreen**: 로그인 성공 후 동의 레이어에서 동의 완료 시(§1.2)

### 스크린 내부 구현 특이사항
- **스크린 타입 특성**: Full Screen, GNB 없음
- **진입 애니메이션**: 초기 **1000ms** 무대 세팅 후, 스틸(`splash_still_260513.png`, 165×36) **500ms** fade-out, 로고 파트(`splash_still_logo_part.png`, 40×36) **1000ms** 이동, 하단 노출 요소는 **fade-in 없이** 화면 아래 밖→최종 위치 **1000ms** 슬라이드(`easeOutCubic`). 로고 파트 opacity는 유지한다.
- **포스터 배경**: 스크린 상단 50%를 포스터 노출 영역으로 사용한다. 영역을 세로 3행으로 나눈다. 각 행은 **1000ms** 슬라인 등장(`easeOutCubic`: 화면 밖→노출, 1·3행은 왼쪽 밖, 2행은 오른쪽 밖) 후 무한 마키: **1행** 우측 흐름 **60s** 주기, **2행** 좌측 **70s**, **3행** 우측 **66s**. `assets/images/small_posters/*.png`를 3개 그룹으로 쓰며 `pubspec.yaml` assets 등록. 포스터당 4px 패딩, 썸네일은 Home `RoleplayThumbnail`과 동일하게 **`ClipRRect` radius 10**. 상·하 1/6 높이 검정 그라데이션 오버레이.
- **노출 영역**: 최종 고정 로고 아래부터 화면 끝까지를 사용한다. 상단에는 12px 갭 뒤 환영 문구 첫줄(`headlineLarge`, `#0CABA8`)과 둘째줄(`bodyMedium`, 흰색). 중간 가상선(`dividerY = contentTop + contentHeight/2`) 기준 로그인 버튼 블록 `top`은 `dividerY - (블록높이 − 단버튼높이)/2 - _loginButtonsExtraLift(36)`로 올려 로고·환영과의 간격을 줄인다. 약관은 `loginButtonsTop + 블록높이`부터 높이 **`contentHeight/3`** 영역 중앙. 등장 연출 시 `Transform.translate` Y가 **노출 최상단(`contentTop+12`)이 뷰포트 하단 밖**으로 나가도록 거리를 `height`·`contentTop`에서 역산한다(여유 ~40px).
- **Google 로그인 버튼**: Apple과 동일 슬롯(높이 48·폭 디스플레이 80%·radius 8·흰 배경)을 **전체 클릭 영역**으로 두고, 그 중앙에 `sign_in_with_google.png`를 슬롯 높이의 **90%**·`BoxFit.contain`으로 배치. 로딩 중에는 같은 영역에 `CircularProgressIndicator`를 표시한다.
- **약관 문구**: 하단 영역 좌우 15% 패딩 안에서 `labelSmall` 기반으로 표시한다. 링크 색상/밑줄은 기존 `#80D7CF` 규칙 유지. 이용약관·개인정보처리방침 탭 시 각각 WebView로 이동한다.
- **로그인 플로우**: Google — `AuthService.signInWithGoogle()` → `SudaApiClient.loginWithGoogle()` → `TokenStorage.saveTokens()` → `onSignIn`. Apple — `AuthService.signInWithApple()` → `SudaApiClient.loginWithApple()` → 동일. **Custom(iOS 심사)** — 중앙 로고 5연타(600ms 이내 간격) → `ReviewLoginDialog` → `SudaApiClient.loginWithCustom()` → 동일. 에러는 `DefaultToast`.
- **로그인 버튼**: Google·Apple 공통 슬롯 높이 **48**·폭 **디스플레이 80%**. Apple은 `SignInWithAppleButton`(`style: white`·`borderRadius` 8). **iOS: Apple↑ Google↓**, **Android: Google↑ Apple↓**. Apple 버튼은 `AppConfig.isAppleSignInSupported`일 때만(Android local/stg 제외).
- **심사용 hidden login (iOS only)**: 진입 애니 완료 후 화면 정중앙 로고(`splash_still_logo_part.png`) **56×56 hit area**를 **5연타**(탭 간격 ≤600ms)하면 glassy dialog(`lib/widgets/review_login_dialog.dart`) 노출. Email/Password + Log in. 우상단 X·배경 탭으로 닫기. `POST /v1/auth/custom`. UI 라벨은 영문(은은한 일반 폼). **ENV 제한 없음**(local/dev/stg/prd).

---

## 2. HomeScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/home.dart`
- **클래스명**: `HomeScreen` (StatefulWidget)
- **스크린 타입**: **Main Screen**
- **appPath**: `/home`

### 스크린 용도
- 로그인 후 메인. 배너 + 시리즈 카테고리 가로 썸네일.

### 이전 스크린 정보 (진입점)
- **네이티브 스플래시**: 저장된 JWT 토큰이 유효하고 사용자 정보 조회 성공 시 (스플래시 제거 후 표시)
- **LoginScreen**: Google 로그인 성공 및 JWT 토큰 발급 성공 시
- **NotificationBoxScreen**: GNB의 Home 버튼 클릭 시
- **ProfileScreen**: GNB의 Home 버튼 클릭 시
- **조건**: `_MyAppState`의 `_accessToken != null`이고 `_currentMainScreen == 'home'`일 때 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **NotificationBoxScreen**: GNB의 Alarm 버튼 클릭 시
  - `onNavigateToAlarm` 콜백 호출 → `_MyAppState._navigateToAlarm()` 실행 → 상태 업데이트로 전환
- **ProfileScreen**: GNB의 Profile 버튼 클릭 시
  - `onNavigateToProfile` 콜백 호출 → `_MyAppState._navigateToProfile()` 실행 → 상태 업데이트로 전환
- **SeriesOverviewScreen** (Sub): Home 시리즈 썸네일 탭 시 `SeriesRouter.pushOverview`. `lib/screens/series/overview.dart`.
  - 진입 시 `GET /rps2/series/{seriesId}/overview` (`SudaApiClient.getSeriesOverview`) → `RpS2SeriesOverviewDto` 파싱.
  - **레이아웃**(rp overview와 동일 골격): `Scaffold`+`Stack` — 상단 배경 `thumbnailImgPath`(CDN, 너비×**60%** 높이)·히어로 그라데이션·스크롤 본문(`information.png` 24×24(타이틀 **상단** 좌측·탭 → `SeriesInformationScreen`) → 타이틀 `headlineSmall` → gap 4 → `synopsisComplexityLevel` 태그 → 진행률 바 → gap 8 → `synopsis`)·**플로팅 헤더**(좌 뒤로가기 / 우 언어레벨 pill: liquid glass 24h — `ClipRRect` pill, `BackdropFilter` blur 12, white α0.14~0.22 gradient(좌상 밝음/우하 어두움), border white α0.36, shadow blur 10 offset (0,2), `ENGLISH_LEVEL` l10n 라벨, 탭 → `CefrLevelScreen`) 스크롤 시 타이틀 상단 도달하면 fade-out. §5 이후(에피소드 등) 추후.
- **SeriesInformationScreen** (Sub Screen, **S2**): Overview information 탭 → `SubScreenRoute` (`lib/screens/series/series_information.dart`). 부모가 로드한 `RpS2SeriesOverviewDto`·`UserDto` 전달(API 재호출 없음). 헤더: Setting 계열 `AppScaffold`(좌 뒤로가기·우측 없음)+커스텀 중앙 title(`headlineSmall`·좌우 inset 40·max 2줄·`bodyTopPadding` 타이틀 높이 연동). 배경: `RoleplayOverviewBackdrop`(thumbnail CDN·Opening과 동일 blur/dim). 본문: synopsis(bodySmall·justify) → gap10 → blockquote(좌 #353535 3px)·언어레벨·주제난이도(scl) → gap20 → 학습목표(headlineSmall) → gap10 → 에피소드별 learningFunction+#N title(gap10)·핵심 표현 불릿(`missions[].keyExpression` **en** 고정, 사용자 언어 미사용).

### 스크린 내부 구현 특이사항
- **스크린 타입 특성**: Main Screen
  - **GNB 포함**: 하단 네비게이션 바 필수 포함 (AppScaffold의 `bottomNavigationBar` 사용)
  - GNB 구성: 왼쪽 "Alarm" (회색), 중앙 "Home" (현재 화면, 흰색), 오른쪽 "Profile" (회색)
  - GNB 색상: 검정 (`Colors.black`) - 시스템 네비게이션 바와 색상 통일
- **UI 구성**: `AppScaffold`를 사용하여 표준 레이아웃 적용
  - **상단 여백**: 70 (표준)
  - **헤더**:
    - 좌측: "Hi, {userName}!" 인사말 (`AppScaffold.title` 사용)
  - **메인 콘텐츠**:
    - **홈 배너**: 
      - 위치: 상단 여백 70 바로 아래
      - 형태: Width 100% 정사각형 (`AspectRatio(1.0)`), `BorderRadius: 20`
      - 구현: `AppScaffold(usePadding: false)`를 적용하여 배너가 화면 끝까지 닿도록 함
      - 기능: 무한 루프 스와이프, 자동 슬라이드(4초), 인디케이터, 다국어 오버레이
      - `MainHomeBannerDto.appPath`가 있으면 배너 탭 시 기존 appPath 규칙으로 화면 이동
    - **시리즈 카테고리** (S2):
      - 구성: 카테고리명(h3, `HomeCategoryDto.name` Map) + 가로 스크롤 썸네일 리스트
      - 썸네일: 30% 너비, radius 10, 음영 박스 오버레이 타이틀 (`HomeSeriesDto.title` Map)  
        (텍스트가 영역을 초과할 때만 Marquee 적용)
      - 기능: 레이지 로딩(페이징) 지원, 로딩 중 Shimmer 스켈레톤 노출
      - 탭: `SeriesOverviewScreen` (Sub)
- **API 연동**:
  - **홈 콘텐츠 통합 조회**: `GET /v2/home/contents` (`SudaApiClient.getHomeContents()`)
    - 응답: HomeDto (banners, seriesList, restYn, restStartsAt, restEndsAt, notiboxUnreadYn)
    - banners: `MainHomeBannerDto(imgPath, overlayText, appPath?)`
  - **시리즈 페이징 조회**: `GET /v2/home/series?category={enumValue}&pageNum=…` (`SudaApiClient.getSeriesByCategory()`)
  - **푸시 토큰 등록**: `_registerPushToken()` 메서드로 처리
    - Firebase Messaging 토큰 획득 후 서버에 전송 (`POST /users/push-token`)
- **초기화 작업**: `initState()`에서 `_performInitialization()` 호출 (한 번만 실행)
  - `_isInitialized` 플래그로 중복 실행 방지
- **Props**:
  - `onNavigateToAlarm`: Alarm 화면으로 이동 시 호출되는 콜백
  - `onNavigateToProfile`: Profile 화면으로 이동 시 호출되는 콜백
  - `onOpenAppPath`: Home 배너 appPath 탭 시 Main의 appPath 라우터로 전달하는 콜백
  - `user`: 앱 메모리에 저장된 사용자 정보 (UserDto)

---

## 3. ProfileScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/profile.dart`
- **클래스명**: `ProfileScreen` (StatefulWidget)
- **스크린 타입**: **Main Screen**
- **appPath**: `/profile`

### 스크린 용도
- 사용자 프로필 화면
- 로그아웃 기능 제공
- 사용자 프로필 이미지/이름 및 서비스 사용 지표(Roleplay/Words/Like) 요약을 표시
- Profile 화면 노출 시점마다(`/v1/users/profile`)를 호출하여 최신 userDto를 받아 화면을 자연스럽게 갱신하고 앱 메모리의 userInfo도 업데이트

### 이전 스크린 정보 (진입점)
- **HomeScreen**: GNB의 Profile 버튼 클릭 시
  - `onNavigateToProfile` 콜백 호출 → `_MyAppState._navigateToProfile()` 실행 → 상태 업데이트로 전환
- **NotificationBoxScreen**: GNB의 Profile 버튼 클릭 시
  - `onNavigateToProfile` 콜백 호출 → 상태 업데이트로 전환
- **조건**: `_MyAppState`의 `_accessToken != null`이고 `_currentMainScreen == 'profile'`일 때 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **NotificationBoxScreen**: GNB의 Alarm 버튼 클릭 시
  - `onNavigateToAlarm` 콜백 호출 → 상태 업데이트로 전환
- **HomeScreen**: GNB의 Home 버튼 클릭 시
  - `onNavigateToHome` 콜백 호출 → `_MyAppState._navigateToHome()` 실행 → 상태 업데이트로 전환
- **SettingScreen** (Sub Screen): 우측 상단 원형 버튼 클릭 시
  - `Navigator.push()`로 iOS 스타일 슬라이드 애니메이션으로 표시
- **HistoryScreen** (Sub Screen): 롤플레이 히스토리 썸네일 탭 시 진입 (`rpUserHistoryId` 전달)
  - `Navigator.push(SubScreenRoute(page: HistoryScreen(rpUserHistoryId: …)))` 로 진입

### 스크린 내부 구현 특이사항
- **스크린 타입 특성**: Main Screen
  - **GNB 포함**: 하단 네비게이션 바 필수 포함 (AppScaffold의 `bottomNavigationBar` 사용)
  - GNB 구성: 왼쪽 "Alarm" (회색), 중앙 "Home" (회색), 오른쪽 "Profile" (현재 화면, 흰색)
  - GNB 색상: 검정 (`Colors.black`) - 시스템 네비게이션 바와 색상 통일
- **UI 구성**: `AppScaffold`를 사용하여 표준 레이아웃 적용
  - **상단 여백**: 70 (표준)
  - **헤더**: 우측 설정 아이콘만 노출 (`AppScaffold.actions` 사용)
  - **Profile Box**: 
    - 위치: 상단 여백 80 바로 아래
    - 배경: 박스가 위치한 세로 구간에 화면 좌우 끝까지 닿는 full-bleed 그라데이션 적용
    - 구현: `AppScaffold(usePadding: false)`를 적용하여 그라데이션이 화면 끝까지 닿도록 함
  - Progress Box: Profile Box 아래 gap 50 이후, 가로 중앙 정렬, 너비는 디바이스의 70%
    - 텍스트: `body-tiny` (`textTheme.labelSmall`), 흰색, `Lv. {currentLevel}`
    - 프로그레스 바: height 4, radius 2
      - 바탕: `#635F5F`
      - 진행: `#80D7CF` (progressPercentage / 100)
  - **무료 사용자 Premium CTA** (`SubscriptionStatusCache.isSubscribedActive == false`):
    - 위치: Progress Box 아래 gap 24, 좌우 margin 20 (`_profileHorizontalMargin`)
    - 위젯: `ProfileGoPremiumButton` (`lib/widgets/profile_go_premium_button.dart`)
    - l10n: `profileGoPremiumTitle` / `profileGoPremiumExplore` (en Get SUDA Premium·Explore / pt Assine o SUDA Premium·Explorar / ko SUDA Premium 구독·혜택보기)
    - 레이아웃: height 52 pill, 내부 padding 좌 20·우 28, Row(아이콘 28×28 + gap 12 + Expanded 제목 + `SizedBox` gap 20 + Explorar 66×24). 혜택보기는 우측 28px 고정, 제목↔혜택보기 간격은 `SizedBox(width: 20)`로 고정(디바이스 무관)
    - 제목: `textTheme.headlineSmall`(H3)·불투명 흰색(softLight 미사용 — 글로우와 합성 시 글자 아래 세로 아티팩트 방지). 공간 부족 시 min 10px까지 축소·말줄임·클립 없음, min에서도 넘치면 `FittedBox.scaleDown`
    - 메인 pill fill `#8A38F5→#280752`·stroke `#80D7CF→#8A38F5` (좌→우, 1px padding border), radius height/2
    - Explorar: fill white 3.8%·12px 흰색·conic stroke·padding 4·radius 12(24h pill)
    - **글로우 애니메이션**: progress 기반 좌우 왕복(easeInOut 2.4~3.8s/leg). Glow1 별(왼)→오른끝→홈, Glow2 혜택보기(오른)→왼끝→홈. 횡단 중 Y 튕김 0~3회 랜덤 + bob. 소스: `paywall_star_badge.png` blur σ10, opacity ~0.55
    - 탭: pill 전체 → `PaywallScreen.push` → 성공 시 `getUserEnergySimple` 재조회 후 CTA 숨김
    - Profile 탭 활성·복귀 시 `getUserEnergySimple`로 구독 상태 갱신
- **Profile 히스토리 (S2)**: `GET /rps2/user-histories?pageNum=` (0-based 페이징). 썸네일 3열 그리드 — `imgPath`·`starResult`·`createdAt`(dd/mm) 기존과 동일. 상단 좌측 **CEFR 알약** + 우측 별 3개. 탭 시 `HistoryScreen(rpUserHistoryId)` → `GET /rps2/user-histories/{id}` 후 Result 본문(애니메이션 없음).
- **Saved 표현 (Expression 탭)**: 목록 `GET /v1/users/expressions?pageNum=` · 카드 탭 TTS `GET /rps2/user-histories/{rpUserHistoryId}/expressions/{expressionIndex}/sound` (`roleplayResultId` → `rpUserHistoryId`, `TtsResultDto`) · 삭제 `DELETE /v1/users/expressions?rpResultId=…&expressionIndex=…`. 카드 배경 기본·재생 모두 `#FFFFFF`. 오디오 fetch 중 16×16 `CircularProgressIndicator`(strokeWidth 2, `#0CABA8` 70%), 재생 중 `megaphone_fill.png` `#0CABA8`, 기본 `megaphone.png` `#0CABA8`(Result Key Expression 카드와 동일).
- **Saved 표현 삭제 확인 팝업**: Saved 탭의 expression 카드에서 `bookmark_on` 탭 시 `DefaultPopup`으로 삭제 confirm 팝업을 띄운다. 상단 버튼(삭제/Remove) 탭 시 팝업을 닫고 `DELETE /v1/users/expressions`를 호출해 목록에서 제거, 하단 버튼(Practice more/더 연습할래요) 탭 시 팝업만 닫는다.
- **Props**:
  - `onNavigateToHome`: Home 화면으로 이동 시 호출되는 콜백 (VoidCallback?)
  - `onNavigateToAlarm`: Alarm 화면으로 이동 시 호출되는 콜백 (VoidCallback?)
  - `onSignOut`: 로그아웃 시 호출되는 콜백 (VoidCallback?)
  - `user`: 앱 메모리에 저장된 사용자 정보 (UserDto?)

---

## 4. SettingScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/setting.dart`
- **클래스명**: `SettingScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: `/profile/setting`

### 스크린 용도
- 설정 메뉴 화면
- ProfileScreen에서 진입
- 다양한 설정 항목 및 정보 화면으로의 진입점 제공

### 이전 스크린 정보 (진입점)
- **ProfileScreen**: 우측 상단 원형 버튼 클릭 시
  - `Navigator.push()`로 iOS 스타일 슬라이드 애니메이션으로 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **AccountScreen** (Sub Screen): "Account" 클릭 시
- **PushAgreementScreen** (Sub Screen): "Notification" 클릭 시
- **CefrLevelScreen** (Sub Screen): "Language Level" 클릭 시
- **FeedbackScreen** (Sub Screen): "Feedback" 클릭 시
- **AnnouncementsScreen** (Sub Screen): "Announcements" 클릭 시
- **WebViewScreen** (Sub Screen): "Privacy policy" 또는 "Terms of Service" 클릭 시
  - "Privacy policy": `https://sudatalk.kr/public/app/privacy` 웹뷰 표시
  - "Terms of Service": `https://sudatalk.kr/public/app/terms` 웹뷰 표시
  - 언어별 제목 표시 (한국어/영어/포르투갈어)
- **OpenSourceLicenseScreen** (Sub Screen): "Open source license" 클릭 시
- **LoginScreen**: "Log out" 클릭 시
  - JWT 토큰 삭제 후 모든 스크린을 pop하고 LoginScreen으로 이동

### 스크린 내부 구현 특이사항
- **스크린 타입 특성**: Sub Screen
  - 배경색: RGB(26, 26, 26) - Main Screen(검정) 대비 10% 밝기 증가
  - 우측 상단 X 버튼 필수
  - iOS 스타일 슬라이드 애니메이션
- **메뉴 항목**: 세로로 나열된 텍스트 항목들
  - Account
  - **Restore Purchases** (`settingsRestorePurchases`) — **iOS만**, Account 다음. 탭 → StoreKit restore + 트랜잭션당 verify(소모품 제외, 세션 ID 없음) → `finishYn`. 없음 토스트 `restorePurchasesNothing`. 성공 시 `restorePurchasesCompleted` + `GET energy/simple`
  - Notification (l10n: Notification / 알림 / Notificações)
  - Language Level
  - Feedback
  - Announcements (l10n: Announcements / 공지사항 / Avisos)
  - Tutorial (클릭 시 반응 없음, 추후 구현)
  - Log out
  - Privacy policy
  - Terms of Service
  - Open source license
- **Props**:
  - `onSignOut`: 로그아웃 시 호출되는 콜백 (VoidCallback?)

---

## 5. AccountScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/account.dart`
- **클래스명**: `AccountScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Account" 클릭 시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **PaywallScreen**: 무료 사용자 Free Plan 카드 탭 시
- **ChangePlanScreen** (Sub Screen): 월간 구독 활성 시 Subscription 헤더 우측 `Change Plan >` 탭 시

### 스크린 내부 구현 특이사항
- 키보드 활성화 시 `resizeToAvoidBottomInset: false` (하단 "계정 삭제"가 키보드와 함께 올라오지 않도록)
- 진입 시 `GET /v1/users/energy/simple`로 구독 상태 갱신 (`SubscriptionStatusCache`)
- **Subscription 섹션**
  - 무료 (`isSubscribedActive == false`): Free Plan 카드(`check_green.svg`) → Paywall. l10n `accountFreePlanTitle` / `accountFreePlanSubtitle`
  - 구독 활성: Subscription 헤더 좌측. 구독↔카드 간격 **24**(이름/계정 섹션과 동일). **`Change Plan >`는 월간 구독자만** 노출(`subscriptionBasePlanId==bp-premium-monthly`; 연간·미구독은 미표시). (l10n `accountChangePlan` + chevron, 텍스트 `bodySmall` 14·**w700**/`wght` 700·흰색)는 그 간격 안 하단 우측(`right: 8`, 카드와 `bottom: 12`) → `ChangePlanScreen`. Premium 카드(`premium_verified_badge.png`) — 제목 `accountPremiumTitle`, 부제 `accountPremiumSubtitle`, 갱신일 `accountPremiumRenewsOn`(`subscriptionExpiredAt`, en/ko `yyyy/MM/dd` · pt `dd/MM/yyyy`)

---

## 5.0 ChangePlanScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/change_plan.dart`
- **클래스명**: `ChangePlanScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Account 하위)

### 이전 스크린 정보 (진입점)
- **AccountScreen**: 월간 Premium 구독 활성 시 `Change Plan >` 탭 (연간은 미노출)

### 스크린 내부 구현 특이사항
- 헤더: l10n `changePlanTitle` (en Change Plan / pt Alterar plano / ko **요금제 변경**). Account 버튼 `accountChangePlan`(ko 플랜 변경)과 분리.
- 진입 시 `GET /v1/users/energy/simple` + `loadPremiumSubscriptionPrices()`.
- **`subscriptionBasePlanId` null/미지 값·로드 실패**: 추측 폴백 없음. l10n `changePlanLoadFailed` + `changePlanRetry`로 재시도.
- **Current Plan**: 섹션 라벨 H2(`headlineMedium`)·`#0CABA8`. 카드 높이 **103**·좌우 패딩 **16**. 좌측 플랜명 20·갱신일 14(`changePlanRenewsOn`), 우측 가격 **H3** 수직 중앙.
- **Available Plans**: 동일 섹션 라벨. **월→연만** (연간 카드). 카드 동일 폭·**minHeight 103**(설명 줄바꿈 시 확장)·좌우 16. 라디오 **24×24**·플랜명 20·설명 14·주 가격 H3·연간 부제 **`#80D7CF` 14**. ko 연간 설명 `paywallAnnualPlanSubtitle`는 `월간 플랜 대비`/`33% 이상 절약` 2줄(`\n`); 폭 부족 시 부제 `FittedBox`로 축소해 2줄 유지. 탭 토글 선택.
- **CTA**: l10n `accountChangePlan`. 기본 비활성. Available 선택 시에만 활성. 탭 시 `DefaultPopup` 확인 팝업(`changePlanConfirmBody`: **다음 결제일부터 적용**) → Confirm 시 `IapPurchaseService.changeSubscription`. AOS **`ReplacementMode.withoutProration`**. iOS 같은 그룹 `premium_yearly`(verify `productId=premium_yearly`, `basePlanId=bp-premium-yearly`, paywall 세션 없음). old purchase 없으면 토스트 `changePlanOldPurchaseMissing`(크래시 없음, AOS). 성공 시 Account `pop(true)` + `changePlanChangeRequested`. verify 직후 simple은 계속 monthly. 실패 시 Billing/Purchase error code·message를 debugPrint.
- **ReplacementMode 실측 메모:** `DEFERRED`=에러·변경 불가. `WITHOUT_PRORATION`=앱 채택(월↔년 가능했으나 제품은 월→연만 노출). `CHARGE_FULL_PRICE`는 미사용.

---

## 5.1 PushAgreementScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/push_agreement.dart`
- **클래스명**: `PushAgreementScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 스크린 용도
- 푸시 알림 수신 동의 ON/OFF 설정

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Notification" 클릭 시
- **에너지 팝업** Enable Notifications 슬롯: `SubScreenRoute`로 덮음. 팝업은 유지. 열기 전 `GET /v1/users`로 토글 초기값.

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **SettingScreen** / 에너지 팝업: 좌상단 뒤로가기 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀(에너지 팝업은 그대로)

### 스크린 내부 구현 특이사항
- 좌상단 뒤로가기: 같은 레벨(Account, Feedback 등)과 동일
- 헤더 타이틀: 메뉴명 그대로(l10n.settingsNotification)
- 본문: width 100%, 배경 #353535, 모서리 둥근 박스. 좌측 설명(pushNotifications 흰색, pushNotificationsDesc caption·#80D7CF), 우측 토글(56×24 트랙, 20×20 흰 원). OFF: 원 좌측, 트랙 #8C8C8C. ON: 원 우측, 트랙 #80D7CF. 200 응답 후 전환 애니메이션.
- API: ON 시 `PUT /v1/users/push-agreement?agreementYn=Y`, OFF 시 `PUT /v1/users/push-agreement?agreementYn=N`
- 응답: `QuestResultDto { completeYn }`
  - `completeYn == 'Y'`: `Navigator.pop(true)`로 자동 복귀. 에너지 팝업 진입이면 토스트(`energyEnablePushCompleted`) + 슬롯 제거 애니 + detail 재조회. Setting 경로는 토스트 없음
  - `completeYn != 'Y'`(N 포함): 추가 토스트 없이 기존처럼 토글 상태만 반영

---

## 6. CefrLevelScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/cefr_level.dart`
- **클래스명**: `CefrLevelScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Language Level" 클릭 시

### 스크린 내부 구현 특이사항
- **AppScaffold** 헤더(뒤로가기 + 중앙 `settingsCefrLevel`) 유지. 본문 `usePadding: false`.
- **UI**: `FirstCefrLevelScreen`(§1.2)과 동일 캐러셀·설명·Confirm 패턴(포커스 80%W·대기 40%). 본문 **h1 타이틀 없음**(헤더 `settingsCefrLevel`만). **`firstCefrLevelSettingsHint` 미노출**. 본문 세로 **1:1:1**(상·중·하): 설명=상단 2등분 **아래** 블록 중앙, 캐러셀=중앙 영역 중앙, Confirm=하단 2등분 **위** 블록 중앙. Sub Screen 슬라이드(300ms) 완료 후 좌·우 대기 원 **280ms fade-in**. 닫힘 시 좌·우 대기 원 **160ms fade-out** 후 pop.
- 초기 포커스: 사용자 `ENGLISH_LEVEL` meta. Confirm 시 `PUT /v1/users/language-level` 후 pop(실패 시 토스트·유지).
- 레벨 단일 표현: CEFR 라벨 `Pre-A1`/`A1`/`A2`/`B1` (`EnglishLevelUtil`). `C1` UI 미노출.

---

## 7. FeedbackScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/feedback.dart`
- **클래스명**: `FeedbackScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Feedback" 클릭 시

### 스크린 내부 구현 특이사항
- 배경색: `AppScaffold` 기본 `#121212`
- 헤더: 중앙 `settingsFeedback`(h2), 좌상 뒤로가기
- 본문: Report 스크린과 동일 글래스 입력창(`RoleplayConfigurationPanel.panelBorderRadius`·blur·반투명 그라데이션) + 중앙 Stadium Send 버튼

---

## 7-1. AnnouncementsScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/announcements.dart`
- **클래스명**: `AnnouncementsScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Announcements" 클릭 시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **AnnouncementDetailScreen** (Sub Screen): 카드 탭 시 `GET /v1/notice/{id}` 선조회, 정상 응답이면 상세 진입
- **팝업 (DefaultPopup)**: showYn='n' 또는 404 시 상세 진입 대신 팝업. 본문 l10n.postNoLongerAvailable, 버튼 l10n.backToHome

### 스크린 내부 구현 특이사항
- 배경색: `#353535`
- 세로 스크롤 목록, 최신순 정렬 (`GET /v1/notice` page/size 페이징)
- 카드: 제목·본문 각 1줄 말줄임, 공지 게시일 YYYY-MM-DD 우하단
- 빈 상태: l10n `noticesEmpty` (en: No posts yet, ko: 아직 게시글이 없습니다, pt: Ainda não há publicações.)

---

## 7-2. AnnouncementDetailScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/announcement_detail.dart`
- **클래스명**: `AnnouncementDetailScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: `/notice/{noticeId}` (예: `/notice/123`)

### 이전 스크린 정보 (진입점)
- **AnnouncementsScreen**: 공지 카드 탭 시 (`noticeId` 전달)
- **appPath**: `/notice/{noticeId}` 푸시 딥링크 진입 시 (`noticeId` 전달)

### 스크린 내부 구현 특이사항
- `GET /v1/notice/{noticeId}` 조회. (404는 목록에서 선조회로 대부분 차단되어 진입 전 팝업 처리, 진입 후 404 시 l10n `deletedPost` 표시)

---

## 8. OpenSourceLicenseScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/open_source_license.dart`
- **클래스명**: `OpenSourceLicenseScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Open source license" 클릭 시

### 스크린 내부 구현 특이사항
- 배경색: RGB(51, 51, 51) - SettingScreen 대비 10% 밝기 증가
- 우측 상단 X 버튼 필수

---

## 11. RoleplayOverviewScreen (딥링크 잔존)

- **파일**: `lib/screens/roleplay/overview.dart` · appPath `/roleplay/overview/{roleplayId}`
- S1 단일 RP Overview. 홈 진입 없음. Play→Opening 연결 없음. 현행 플로우는 `SeriesOverviewScreen`.

---

## 11.2 RoleplayTutorialScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/tutorial.dart`
- **클래스명**: `RoleplayTutorialScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음

### 스크린 용도
- 앱 튜토리얼 슬라이드 화면 (6페이지 스와이프)
- `userDto.metaInfo`의 `TUTORIAL` 값이 없거나 `'Y'`가 아닌 경우에만 노출
- 완료 조건 충족 시 `POST /v1/users/tutorial` 호출 후 Opening으로 진입

### 이전 스크린 정보 (진입점)
- **SeriesOverviewScreen**: 에피소드 Play (`RoleplayRouter.pushTutorial`)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayOpeningScreen**: 튜토리얼 완료(마지막 이미지에서 탭) 또는 이미 완료된 경우 즉시 replace
  - `Navigator.pushReplacement()`로 Tutorial 스크린을 스택에서 제거하며 전환

### 스크린 내부 구현 특이사항
- **진입 시 조건 체크**: `RoleplayStateService.instance.user` 없으면 `GET /v1/users` 호출. `TUTORIAL == 'Y'`이면 첫 프레임 이후 `replaceWithOpeningFromTutorial()`로 스킵(`addPostFrameCallback` — build 중 `pushReplacement` 금지)
- **이미지**: `assets/images/tutorials2/{lang}/tutorial-{1~6}.png` (lang: ko/pt/en, 기본 en)
- **인디케이터**: 상단 6개 dot (활성: 흰색 / 비활성: 흰색 40% 불투명도)
- **완료 처리**: 마지막(6번째) 페이지에서 화면 탭 시 `SudaApiClient.completeTutorial()` 호출 → 첫 프레임 이후 `replaceWithOpeningFromTutorial()`
- **뒤로가기**: `PopScope(canPop: true)` — Overview로 복귀 가능
- **API**: `POST /v1/users/tutorial` (request body 없음, 200 응답 시 성공)
- Route name: `/roleplay/tutorial`

---

## 11.1 NotificationBoxScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/notification_box.dart`
- **클래스명**: `NotificationBoxScreen` (StatefulWidget)
- **스크린 타입**: **Main Screen**
- **appPath**: `/box` (GNB만 진입 시). 앱 공지 푸시(Add Notibox=Y·`appPath` 미지정)는 `/app/notification/{notificationId}`로 Alarm 탭 진입 후 해당 id 카드 펼침·상단 앵커.

### 스크린 용도
- 사용자 알림함(알림 메시지) 목록을 표시하는 화면
- GNB를 통한 진입/전환 (Alarm / Home / Profile 3탭)

### 이전 스크린 정보 (진입점)
- **HomeScreen**: GNB의 Alarm 버튼 클릭 시
  - `onNavigateToAlarm` 콜백 호출 → `_MyAppState._navigateToAlarm()` 실행 → 상태 업데이트로 전환
- **ProfileScreen**: GNB의 Alarm 버튼 클릭 시
  - `onNavigateToAlarm` 콜백 호출 → 상태 업데이트로 전환
- **조건**: `_MyAppState`의 `_currentMainScreen == 'alarm'`일 때 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HomeScreen**: GNB의 Home 버튼 클릭 시
  - `onNavigateToHome` 콜백 호출 → 상태 업데이트로 전환
- **ProfileScreen**: GNB의 Profile 버튼 클릭 시
  - `onNavigateToProfile` 콜백 호출 → 상태 업데이트로 전환

### 스크린 내부 구현 특이사항
- **스크린 타입 특성**: Main Screen
  - **GNB 포함**: 하단 네비게이션 바 필수 포함 (Alarm 현재 화면, 흰색 / Home·Profile 회색)
  - GNB 색상: 검정 - 시스템 네비게이션 바와 색상 통일
- 헤더 중앙 타이틀은 l10n `notificationsTitle` 사용  
  - en: "Notifications", ko: "알림", pt: "Notificações"
- 알림 목록은 서버에서 페이징 조회
  - API: `GET /v1/users/notification?pageNum={pageNum}` (`SudaApiClient.getNotifications()`, `pageNum` 인자 0-based)
  - 응답: `List<NotificationDto>` (id, title(List<SudaJson>), content(List<SudaJson>), imgPath, appPath, sendFinishedAt)
  - 첫 조회 `pageNum=0`, 스크롤 append 시 `pageNum=1`, `2`, `3`… 순차 호출
  - 호출 결과가 빈 리스트이면 더 이상 호출하지 않음
  - GNB가 본문 위 오버레이이므로 목록 `ListView` 하단 패딩: `MediaQuery.padding.bottom + GnbBar.contentHeight`
- 화면 진입 또는 Alarm 탭이 다시 활성화될 때(page 0) 목록을 새로 조회
- **빈 상태**: 조회 결과가 없을 때는 본문 영역 정중앙에  
  - `No notification yet` 문구를 body-default 스타일·흰색으로 가로/세로 중앙 정렬하여 노출 (l10n `notificationsEmpty`)
- **목록 상태**: 조회 결과가 있을 때는 각 요소를 아래로 append
  - 요소별 레이아웃: width 100% 짜리 #353535 둥근 테두리(1px)를 가진 투명 박스 안에, 요소 간 세로 간격 24  
    - **접힌 상태(기본)**: 카드 탭으로 **펼침** 전환. title·content는 각각 접힌 한 줄 규칙(`_singleLineForNotification` + 가로 `ellipsis`).  
    - **펼침 상태**: 동일 카드 재탭 시 **접힘**으로 복귀. title·content는 원문 전체(줄바꿈 포함) 노출. 상단 title → 하단 `sendFinishedAt` 순서 유지.  
    - title 행(아이콘 포함): 위·아래 `Padding` 14, 텍스트는 좌측(`TextAlign.start` + `AnimatedSwitcher` Stack `topLeft`).  
    - title 행 우측 상단(또는 title 없이 content만 있을 때 첫 줄 우측): 24×24 `click_to_expand.png` / `click_to_fold.png` 시각 힌트(탭은 카드 전체에만 적용, `ExcludeSemantics`).  
    - 전환: 높이는 `AnimatedSize`(300ms·`easeInOutCubic`), title/content 텍스트는 `AnimatedSwitcher` + `FadeTransition`(150ms)로 교차.  
    - 펼침 여부는 `NotificationDto.id` 기준 `Set`으로 보관, 목록 첫 페이지 재조회 시 초기화.  
    - 접힌 때 첫 줄: title (`textTheme.headlineSmall`·흰색)  
    - 접힌 때 둘째 줄: content (`textTheme.bodyMedium`·흰색)  
    - 그 아래(텍스트가 있으면 상단 8 gap): `sendFinishedAt`(UTC+0; 타임존 없는 ISO는 UTC로 간주) → 로컬 날짜 기준 달력 일 수 차이 → l10n `notificationSendToday` / `notificationSendOneDayAgo` / `notificationSendDaysAgo` (`textTheme.bodySmall`·#635F5F·우측 정렬)
- ScrollController를 사용하여 `maxScrollExtent - 200` 지점에서 다음 페이지 로딩 트리거
- 뒤로가기 버튼 없음 (`showBackButton: false`)
- Route name: `/notification_box` (참조용)

---

## 12. RoleplayOpeningScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/opening.dart`
- **클래스명**: `RoleplayOpeningScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (에피소드 선택 후)

### 스크린 용도
- 에피소드 시작 전 브리핑. 데이터 `SeriesStateService.selectedEpisode`.

### 이전 스크린 정보 (진입점)
- **RoleplayTutorialScreen** 완료/스킵, 또는 Tutorial 이미 완료면 Series Overview Play에서 바로

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayPlayingScreen**: Start 성공 시 `replaceWithPlaying`

### 스크린 내부 구현 특이사항
- 배경: episode `thumbnailImgPath` → `RoleplayOverviewBackdrop`. 본문: `aiCharacter.name` + briefing(`DefaultMarkdown`). duration 없음.
- 시스템 뒤로가기: Opening 제거, Series Overview 노출
- 우상단 `EnergyHeaderBadge` — Home과 동일(충전·무제한 타이머 포함)
- **Briefing TTS**: episode `briefingAudio`(언어→CDN path). 진입 첫 프레임 후 현재 언어→`en` 순으로 path 선택·`cdnBaseUrl` prepend·`just_audio` 자동재생. 둘 다 없거나 실패 시 스킵. 이탈/Playing 전환 시 즉시 stop. 재진입 시 다시 재생.
- footer Start 버튼 아래 AI 안내(`l10n.roleplayOpeningAiDisclaimer`): `labelSmall`·`#8C8C8C`·중앙 정렬·두 문장 줄바꿈(`\n`). 버튼↔문구 12dp, 문구 아래 50dp.
- **Start 마이크 권한**: status→request→영구거부 시 설정 안내만. 복귀 후 사용자가 다시 Start. iOS `PERMISSION_MICROPHONE=1` + `NSMicrophoneUsageDescription`. 상세 `CONTEXT_ROLEPLAY_S2.md` Opening Start.
- 세션 초기화 응답 분기 (`POST /rps2/sessions`):
  - `sessionId == '0'`: `showEnergyInsufficientPopup`(l10n `energyInsufficient`) → Opening 유지, 재시도 가능
  - 정상 sessionId: Playing 진입(에너지 소비는 Playing 발화 처리 시)

---

## 13. RoleplayPlayingScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/playing.dart`
- **클래스명**: `RoleplayPlayingScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- S2 Roleplay 진행 중 화면. AI 선시작 후 힌트 조건 처리, 사용자 발화, 나레이션, 후속 AI 말풍선, 턴바/미션 효과를 반복한다.

### 이전 스크린 정보 (진입점)
- **RoleplayOpeningScreen**: 정상 `POST /rps2/sessions` 후 `SeriesStateService.session` 저장 → `replaceWithPlaying`
  - `RoleplayRouter.replaceWithPlaying()`로 전환 (opening screen 삭제)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **SeriesOverviewScreen** (Sub Screen): X/시스템 뒤로가기 확인 후 나가기 시 `RoleplayRouter.popToOverview()`로 복귀
- **Ending/Try Again/Result 계열**: S2 result 호출·이동은 아직 미구현. 현재 `requiredSpeechCount` 도달 후 응답 `narration`·`aiText`가 모두 비어 있을 때 `roleplayAnalyzing` 서비스 메시지 blink까지만 수행한다. 응답 본문이 있으면 정상 대화 루프를 계속 처리한다.

### 스크린 내부 구현 특이사항
- `SeriesStateService.selectedEpisode` 기반. 배경은 episode `thumbnailImgPath`, 헤더 타이틀은 episode `title`(`bodySmall` w700·1줄 말줄임), 본문은 `briefing`·`aiCharacter.name`. 헤더 슬롯 높이 **60**, duration 없음. 타이틀은 X·kebab과 동일 밴드(top 16·height 40) 세로 중앙(`centerTitleInHeaderActionRow`).
- 헤더 좌측 X/시스템 뒤로가기: 나가기 확인 레이어 노출, 확인 시 `/series/overview`까지 pop. 우측 `kebab.png`는 설정패널 토글(오토힌트, 음성 속도).
- `RoleplayScaffold.belowHeader`에 S2 턴바 영역 표시. `requiredSpeechCount`개 턴박스를 렌더링하고, 사용자 발화 응답 `userGrade` A/B/C/D에 따라 색상·라벨 효과 후 40% opacity 상태로 남긴다.
- 본문은 상단 고정 미션 패널 + 스크롤 대화 영역. 대화 entry는 AI/User/Narration 타입이며 힌트는 별도 bubble로 append된다. 힌트 텍스트 조회 `GET /rps2/sessions/{id}/hint/{rpMsgId}`는 202 not-ready 시 최대 15회 재시도. AI 말풍선은 번역 아이콘과 `GET /rps2/sessions/{id}/translation?index=`를 사용한다.
- 미션 패널은 접힘/펼침을 지원한다. 접힘 상태 우측 숫자는 달성 수가 아니라 현재 노출 미션 순서(`activeMissionIndex + 1`) 기준이다. `missionCompletedIndex` 수신 시 해당 미션 row 또는 접힘 좌측 아이콘 위치에서 `mission_complete_effect.png` fade/회전 효과를 재생하고, 아이콘을 즉시 `rps2_mission_on.png`로 전환한다. 이미 완료 처리한 index가 재수신되면 무시한다. 접힘 상태 배경은 `#9E0067`로 300ms 전환되며, 다음 사용자 턴에 잔여 미션을 노출하기 전까지 유지된다. 잔여 미션으로의 표시 전환은 다음 사용자 턴 활성화 시점에 수행한다.
- 푸터는 서비스 메시지 24px, 녹음/타이핑 입력, 하단 mic/keyboard·에너지·hint 아이콘 3층 구조. 녹음 영역 높이 140(`roleplayMicFooterStackHeight`). 중앙 `PlayingEnergyIndicator`(일반: energy+숫자, 무제한: unlimited 아이콘만). 30분 충전 00:00 시 서버 재조회. 발화 성공 시 로컬 -1. 에너지 0에서 **녹음 또는 타이핑 send** 또는 user-message `402` 시 `showPlayingEnergyInsufficientPopup`(버튼 `endRoleplay`) → Wait 레이어 후 Overview 이탈. **세션당 첫 사용자 발화 턴**에만 `holdMicrophoneToSpeak` fade-in/out, 마지막 턴 나레이션·후속 AI 종료 후 서버 `serviceMessage`(없으면 `roleplayAnalyzing`) blink. 오토힌트 ON으로 힌트박스가 자동 노출된 턴은 사용자 턴 활성 후에도 힌트 버튼 disabled를 유지한다. 녹음 시작 완료 전 release/cancel이 들어오면 pending action으로 보관해 start 완료 직후 finish/cancel을 이어서 처리한다. **녹음 가드**(`playing_input_mixin`): begin/cancel/finish/stop 직렬화·stop/cancel try-catch·이탈(`_confirmExit`)/dispose/`lockPlayingInputForSessionEnd` 전 `teardownPlayingRecording()`(cancel 완료 대기) — `record` MediaMuxer race 크래시 완화.
- API: 사용자 음성 `POST /rps2/sessions/{id}/user-message/audio`(octet-stream), 텍스트 `POST /rps2/sessions/{id}/user-message/text`(raw string), 후속 AI 음성 `GET /rps2/sessions/{id}/ai-message/audio`.
- 사용자 발화 응답 후 타이밍: 사용자 말풍선 노출 직후 후속 AI 음성을 미리 준비하고, 500ms 후 나레이션을 한 줄씩 fade-in(최소 1초 단계 보장)한 뒤 500ms 대기한다. 이 시점과 AI 음성 준비 완료 중 늦은 시점에 AI 말풍선을 노출하고 준비된 음성을 재생한다.

---

## 14. RoleplayEndingScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/ending.dart`
- **클래스명**: `RoleplayEndingScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- Roleplay 성공 종료 화면 (미션 전부 완수 후 진입)

### 이전 스크린 정보 (진입점)
- **RoleplayPlayingScreen**: resultId 기반 종료 시 미션 전부 완수 분기에서 `roleplayEndedEnding` 3초 노출 후 `Navigator.pushReplacement()`로 전환 (playing screen 삭제)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultScreen** (Full Screen): 하단 "Next" 버튼 클릭 시
  - 별점 `PUT /v1/roleplays/results/{rpResultId}?star={star}` 호출(응답 무시·fire-and-forget) 직후 `RoleplayRouter.replaceWithResult()`로 즉시 전환 (ending screen 삭제, 돌아올 일 없음)

### 스크린 내부 구현 특이사항
- 닫기(X) 버튼 없음. 시스템 뒤로가기 시 "Exit from ending screen" 얼럿, 확인 시 ending screen 삭제 후 Overview 노출.
- 엔딩 데이터: 사용자 role(`RoleplayStateService.overview`·`roleId`)의 `endingList` 첫 번째 요소(`RoleplayEndingDto`) 사용. 이미지 없을 경우 바로 80% 검정 레이어·콘텐츠 노출.
- 이미지 있을 경우: 디바이스 높이 100% 비율 유지 표시(기본). 중앙 기준 1.5배→1배 약 2초 축소 애니메이션 후, 80% 투명도 검정 레이어 fade-in, 이어서 콘텐츠 fade-in.
- 레이아웃: 상단 `Expanded` + `SingleChildScrollView`(gap 50 / 타이틀 / gap 50 / 콘텐츠 / gap 50). 하단 고정 영역 = **전체 디스플레이 높이 35%**, 내부를 세로 2등분 — **상단** 중앙 별점 영역(`endingHowWas` + gap 15 + 별 5개), **하단** 중앙 Next 버튼(shrink-wrap). 별점은 선택 시 해당 별 및 좌측 star_filled, 우측 star_empty. star=0 허용.
- Playing에서 ending 전환 확정 시점에 role.endingList 첫 요소의 `imgPath`에 CDN host prepend하여 이미지 preload.

---

## 15. RoleplayTryAgainScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/try_again.dart`
- **클래스명**: `RoleplayTryAgainScreen` (StatefulWidget)
- **Route name**: `RoleplayTryAgainScreen.routeName` (`/roleplay/try_again`)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- Roleplay 실패 종료 화면

### 이전 스크린 정보 (진입점)
- **RoleplayPlayingScreen**: finish `0` 또는 세션 404 후 finish 실패 시
  - `RoleplayRouter.replaceWithTryAgain()`으로 전환 (playing screen 삭제)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayTryAgainReportScreen** (Sub Screen): "Report" 텍스트 클릭 시
  - `RoleplayRouter.pushTryAgainReport()` → SubScreenRoute로 진입 (Try Again 위에 쌓임)
- **Overview**: X·뒤로가기 → `popToOverview`
- **Retry**: `replaceWithOpeningForRetry` (세션 clear 후 동일 에피소드 Opening)

### 스크린 내부 구현 특이사항
- 닫기(X)/시스템 뒤로가기: 확인 다이얼로그 없이 Overview로 복귀 (Opening과 동일).
- 푸터 없음. 본문 5요소: Try Again 타이틀, 하트 애니메이션, `roleplayTryAgainMessage` 문구, Retry 버튼, Report 텍스트(탭 시 Try Again Report Sub Screen 진입).

---

## 16. RoleplayTryAgainReportScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/try_again_report.dart`
- **클래스명**: `RoleplayTryAgainReportScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Try Again 전용)

### 스크린 용도
- Try Again 화면에서만 진입. 사용자가 느낀 불편함을 수집하는 용도.

### 이전 스크린 정보 (진입점)
- **RoleplayTryAgainScreen**: "Report" 텍스트 클릭 시
  - `RoleplayRouter.pushTryAgainReport()` → SubScreenRoute로 우측에서 슬라이드 인

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayTryAgainScreen**: X 버튼 또는 Android 백버튼 시 `Navigator.pop()`으로 Try Again으로 복귀

### 스크린 내부 구현 특이사항
- 롤플레이 스캐폴드(RoleplayScaffold) 적용.
- Route name: `RoleplayTryAgainReportScreen.routeName` (`/roleplay/try_again_report`).
- Android 디바이스 백버튼: Try Again으로 복귀 (pop).
- 본문: 입력창 + 제출 버튼(sendFeedback API). 성공 시 `feedbackSuccess` 토스트 후 pop(true).

---

## 17. RoleplayResultScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/result.dart`
- **클래스명**: `RoleplayResultScreen` (StatefulWidget)
- **Route name**: `RoleplayResultScreen.routeName` (`/roleplay/result`)
- **스크린 타입**: **Full Screen**
- **전환 방식**: **bottom-up Full Screen** (`FullScreenRoute` + `FullScreenTransition.bottomUp`)
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- Playing finish / Ending Next 후 결과. `SeriesStateService.cachedUserHistory` 기준. 상세 `CONTEXT_ROLEPLAY_S2.md` Result.

### 이전 스크린 정보 (진입점)
- **RoleplayEndingScreen**: Next → `replaceWithResult()`
- **RoleplayPlayingScreen**: finish 성공·마지막 에피소드 아님 → `replaceWithResult()`

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultReportScreen** (Sub): Report 문구
- **ViewChatScreen** (Sub): Speech Feedback 헤더 View Chat
- Got it! → `popToOverview` (Series Overview)

### 스크린 내부 구현 특이사항
- 박스레이어: 별 + titles + Mission/Words/Like (`rps2_mission_on/off.png`). 1초 후 상단 이동 + `LikeProgressEffect`.
- 본문: Key Expression + Speech Feedback + Got it!/Report. History는 동일 본문·Report 없음(`showReportLink: false`).
- Speech Feedback 펼침: `feedbackLockedYn`. `'Y'` Paywall, `'N'` feedback TTS 후 펼침+재생.
- Key Expression 카드 탭: `GET …/expressions/{i}/sound`. 북마크 POST/DELETE 동일 경로.
- 시스템 뒤로가기 = Got it! (`PopScope`).

---

## 18. RoleplayResultReportScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/result_report.dart`
- **클래스명**: `RoleplayResultReportScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Result 전용)

### 스크린 용도
- Result 화면에서 진입. 사용자가 느낀 불편함을 수집하는 용도.
- Send: `POST /rps2/user-histories/{rpUserHistoryId}/report`. `SeriesStateService.cachedUserHistory.id`.

### 이전 스크린 정보 (진입점)
- **RoleplayResultScreen**: 본문 "Report" 문구 탭 시
  - `RoleplayRouter.pushResultReport()` → SubScreenRoute로 우측에서 슬라이드 인

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultScreen**: X 버튼 또는 Android 백버튼 시 `Navigator.pop()`으로 Result로 복귀. 전송 성공(200) 시 `feedbackSuccess` 토스트 후 `pop(context, true)`로 Result에서 Report 문구 숨김.

### 스크린 내부 구현 특이사항
- Try Again Report와 동일 UI. Send API만 위 경로.
- Route name: `RoleplayResultReportScreen.routeName` (`/roleplay/result_report`).
- 다국어: try_again_report 참고 (l10n.reportTitle, endingReport, feedbackPlaceholder, feedbackSend).

---

## 19. HistoryScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/history.dart`
- **클래스명**: `HistoryScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: `/profile/history/{rpUserHistoryId}` (예: `/profile/history/456`)

### 스크린 용도
- Profile에서 진입. S2 롤플레이 결과 요약. Result와 **동일 API·동일 본문 UI**, **초기 애니메이션 없음**.

### 이전 스크린 정보 (진입점)
- **ProfileScreen**: 롤플레이 히스토리 썸네일 탭 시 (`rpUserHistoryId` 전달)
- **appPath**: `/profile/history/{rpUserHistoryId}`

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **ViewChatScreen** (Sub Screen): Speech Feedback 헤더 View Chat pill 탭 시 (`RpS2UserHistoryDto` 전달)
- **ProfileScreen**: Got it! / 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- **로드**: `GET /rps2/user-histories/{rpUserHistoryId}` → `SeriesStateService.setCachedUserHistory`
- **표시**: `RoleplayResultScreen(skipEntranceAnimation: true, exitViaPop: true, showReportLink: false)` — LikeProgressEffect·패널 이동·별 순차 애니 생략, effect 완료 상태 본문 즉시 노출. **Report 링크 미노출**. Speech Feedback 구독 가드는 Result와 동일.
- **종료**: dispose 시 `SeriesStateService.cachedUserHistory` clear

---

## 20. ViewChatScreen

- **파일**: `lib/screens/roleplay/view_chat.dart` · Sub. Result/History Speech Feedback 헤더 View Chat.
- `RpS2UserHistoryDto` 전달. USER 카드 펼침/TTS는 Result와 동일 (`feedbackLockedYn`). 상세 `CONTEXT_ROLEPLAY_S2.md` Speech Feedback.
- S1 ReviewChat/ReviewEnding은 삭제됨.

---

## 22. PaywallScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/paywall/paywall.dart`
- **클래스명**: `PaywallScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen** (optional bottom-up)
- **전환 방식**: `FullScreenRoute` + `FullScreenTransition.bottomUp` (450ms / reverse 280ms). `PaywallScreen.push(context)`
- **appPath**: 해당 없음 (구독 플로우. 진입: 에너지 팝업 Go Premium, Result/History/View Chat Speech Feedback, Lab)

### 스크린 용도
- Premium 구독 Paywall. 월/연 선택 후 AOS Play / iOS StoreKit SUBS → verify.

### 이전 스크린 정보 (진입점)
- **에너지 팝업** Go Premium (`EnergyPurchaseSection`)
- **LabScreen** (dev): Setting > Lab > **Open Paywall**

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **PaywallCompletedScreen**: 신규 구독 verify 성공(비 pending)
- **이전 스크린**: X/`pop()`, 또는 성공·승인대기·Restore 성공 후 `pop(true)`

### 스크린 내부 구현 특이사항
- **결제**: `IapPurchaseService.purchaseSubscription`. AOS `subscription_premium`+`bp-premium-*`. iOS `premium_monthly`/`premium_yearly` + 매핑 `basePlanId`. CTA `_purchasing` lock. dispose 시 `abandonPendingPurchase`.
- **가격**: 스토어. 월간 `price/mês`. 연간 메인 `rawPrice/12` 포맷+`/mês`, 서브 yearly+`/ano`. 미조회 시 하드코딩 폴백.
- **verify N**: 실패 토스트·유지. **pending Y**: 승인대기 토스트+`pop(true)`. **성공**: Completed push 후 Paywall `pop(true)`.
- **Restore**: **iOS만** Terms•Privacy 옆 링크. 세션 ID 없이 restore+verify. Completed 화면 없음. 성공/`pending` → `pop(true)`. 에너지 팝업에는 Restore 없음.
- **CTA**: Assinar agora → 결제. Terms/Privacy → WebView. X = pop
- **UI**: 배경 그라데이션·glow·PREMIUM 카드·플랜 카드·MELHOR 등 기존 레이아웃 유지.

---

## 23. PaywallCompletedScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/paywall/paywall_completed.dart`
- **클래스명**: `PaywallCompletedScreen` (StatelessWidget)
- **스크린 타입**: **Full Screen** (optional bottom-up)
- **전환 방식**: `FullScreenRoute` + `FullScreenTransition.bottomUp`. `PaywallCompletedScreen.push(context)`
- **appPath**: 해당 없음 (Lab 확인용)

### 스크린 용도
- Premium 구독 결제 성공 화면. Lab Preview + Paywall 실결제 성공 후 진입.

### 이전 스크린 정보 (진입점)
- **PaywallScreen**: verify `successYn=Y` (비 pending)
- **LabScreen**: Open Paywall Completed (preview)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- Continuar/X → `pop(true)` → Paywall이 `pop(true)` → 에너지 팝업 Go Premium 제거 애니 + detail 재조회

### 스크린 내부 구현 특이사항
- **배경 그라디언트**: Paywall과 동일. glow `#AB6AFF` 등 기존 스펙 유지.
- **아이콘**: `premium_unlocked_check.png` / 혜택 `white_check_icon.png`
- **문구/버튼**: l10n Continue/X → `pop(true)`

---

## 스크린 네비게이션 흐름도

```
앱 실행
  ↓
[네이티브 스플래시] (#121212 배경 + 중앙 스틸 이미지)
  ↓ (Flutter 엔진 초기화 + JWT 처리)
  ├─ 토큰 없음/유효하지 않음 → [LoginScreen]
  └─ 토큰 유효 → [HomeScreen] (동의 미완료 시 LoginScreen 동의 레이어)

[LoginScreen]
  ├─ 로그인 성공 → [HomeScreen] (이미 동의) / [FirstCefrLevelScreen] (동의 직후)
  └─ 로그인 취소/실패 → [LoginScreen] (유지)

[NotificationBoxScreen] ←→ [HomeScreen] ←→ [ProfileScreen] (GNB Alarm/Home/Profile)
  ├─ [HomeScreen] → [SeriesOverviewScreen] (시리즈 썸네일)
  │     → Tutorial(미완료 시) → Opening → Playing
  │           ├─ Ending → Result → ResultReport
  │           │              └─ ViewChatScreen
  │           └─ Try Again → TryAgainReport
  └─ [ProfileScreen] → Setting / Account / ChangePlan / History
          History → Result 본문(애니 없음) → ViewChatScreen
```

### 네비게이션 흐름 상세 설명

1. **앱 실행 → 네이티브 스플래시**
   - 네이티브 스플래시가 자동으로 표시됨 (`#121212` 배경 + 중앙 스틸 이미지)
   - `FlutterNativeSplash.preserve()`로 Flutter 엔진 초기화 후에도 유지

2. **네이티브 스플래시 → LoginScreen 또는 HomeScreen**
   - Flutter 엔진 초기화 완료 후 `_checkAuthStatus()` 실행
   - JWT 토큰 확인 및 서버 검증 (네이티브 스플래시 유지 중)
   - 처리 완료 후 `FlutterNativeSplash.remove()` 호출
   - 토큰 없음/유효하지 않음 → LoginScreen 표시
   - 토큰 유효 → HomeScreen 표시 (동의 미완료 시 LoginScreen 동의 레이어 → 동의 직후 FirstCefrLevelScreen → Home)

3. **로그아웃 시**
   - `_onSignOut()`에서 곧바로 LoginScreen 표시

4. **LoginScreen ↔ HomeScreen/ProfileScreen**
   - 로그인 성공 시 HomeScreen으로 전환
   - 로그아웃 시 (ProfileScreen에서) LoginScreen으로 전환

5. **NotificationBoxScreen ↔ HomeScreen ↔ ProfileScreen**
  - GNB의 Alarm/Home/Profile 3탭 클릭으로 전환
   - `_MyAppState`의 `_currentMainScreen` ('alarm'|'home'|'profile') 상태로 관리
   - 화면 전환 시 애니메이션 없이 즉시 전환

---

## appPath (푸시 딥링크 경로)

푸시 알림의 data payload에 `appPath`를 넣어, 알림 클릭 시 특정 스크린으로 이동할 수 있다.  
**앱 실행 직후 바로 보여줄 수 있는 스크린**만 appPath로 노출한다. (선행 단계가 필수인 스크린은 제외.)

### appPath 규칙
- **형식**: `/{영역}/{스크린}/{id?}` — 소문자, 세그먼트 구분, id는 필요 시 마지막에만.
- **인터넷 URL과 구분**: appPath는 앱 내부 경로만 의미하며, 웹 주소가 아님.

### 승인된 appPath

| appPath | 스크린 | 비고 |
|---------|--------|------|
| `/home` | HomeScreen (Main, Home 탭) | GNB Home |
| `/box` | NotificationBoxScreen (Main, Alarm 탭) | GNB Alarm |
| `/app/notification/{id}` | NotificationBoxScreen (Main, Alarm 탭) | 푸시: 해당 알림 id 카드 펼침·목록 상단 정렬 |
| `/profile` | ProfileScreen (Main, Profile 탭) | GNB Profile |
| `/notice/{noticeId}` | AnnouncementDetailScreen (Sub) | 예: `/notice/123` |
| `/roleplay/overview/{roleplayId}` | RoleplayOverviewScreen (Sub, 딥링크 잔존) | 홈 플로우 아님 |
| `/profile/history/{rpUserHistoryId}` | HistoryScreen (Sub) | 예: `/profile/history/456`, S2 user-history id |
| `/profile/setting` | SettingScreen (Sub) | Profile에서 진입 |

- **제외**: Login, Agreement(인증 플로우), RoleplayOpening(role 선택 필수), Playing/Ending/Result/Try Again(세션·플로우 의존).

### 신규 스크린 생성 시 appPath 확인 절차
- **모든 스크린** 추가 시 이 문서에서 다음을 확인·정의한다.
  1. 해당 스크린이 **앱 실행 후 바로 보여줄 수 있는지** 판단.
  2. 가능하면 위 표와 동일 형식으로 **appPath 필요 여부 및 값**을 정하고, 이 섹션 표에 반영.
  3. 불가(선행 단계 필수)면 표에 넣지 않고, 필요 시 "제외 사유"만 주의사항 등에 언급.
  4. 해당 스크린의 **스크린 관련 정의 파일** 블록에 **appPath** 항목을 반드시 추가한다 (승인 경로 또는 "해당 없음" 및 사유).

---

## 주의사항

- **스크린 추가/수정 시**: 이 문서를 반드시 업데이트해야 합니다.
- **스크린 타입 지정**: 새 스크린 추가 시 반드시 3가지 타입(Full Screen, Main Screen, Sub Screen) 중 하나로 분류하고, 해당 타입의 규칙을 준수해야 합니다.
- **네비게이션 변경 시**: "이전 스크린 정보" 및 "이후 스크린 정보" 섹션을 업데이트해야 합니다.
- **구현 특이사항 변경 시**: 해당 스크린의 "스크린 내부 구현 특이사항" 섹션을 업데이트해야 합니다.
- **appPath**: 새 스크린 생성 시 "appPath (푸시 딥링크 경로)" 섹션에서 appPath 필요 여부 확인 및 정의를 거친다.
- **Main Screen GNB 규칙**: Main Screen은 반드시 하단 네비게이션 바를 포함해야 하며, 안드로이드 시스템 네비게이션 바와 색상을 통일해야 합니다.
- **Sub Screen X 버튼**: Sub Screen은 반드시 우측 상단에 X 버튼을 포함해야 하며, iOS 스타일 슬라이드 애니메이션을 사용해야 합니다.
- **Full Screen 뒤로가기**: Full Screen에서 시스템 뒤로가기 버튼 클릭 시 앱이 종료되도록 처리해야 합니다.
