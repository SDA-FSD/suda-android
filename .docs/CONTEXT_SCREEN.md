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
- 현재: Alarm 버튼, Home 버튼, Profile 버튼 (3개)
- 향후: Profile 버튼 영역을 사용자 이미지 아이콘으로 대체 예정

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
- AI 대화 화면 (향후 추가 예정)

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
- **현재 임시 상태**: 로그인 화면 개편 중이며 `#121212` 배경 위 중앙 스틸 이미지에서 시작한다. **1000ms 대기** 후 스틸 500ms fade-out, 로고 파트 1000ms 중앙 이동, 포스터·하단 영역은 fade-in 없이 각각 등장 연출한다. 포스터 1~3행은 행별로 화면 밖→노출 위치 1000ms(`easeOutCubic`) 슬라인 후 마키(1행 좌에서 등장·우로·60s, 2행 우에서 등장·좌로·70s, 3행 좌에서 등장·우로·66s). 하단 노출 영역은 화면 아래 밖에서 1000ms 상승(`easeOutCubic`).
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
- **노출 영역**: 최종 고정 로고 아래부터 화면 끝까지를 사용한다. 상단에는 12px 갭 뒤 환영 문구 첫줄(`headlineLarge`, `#0CABA8`)과 둘째줄(`bodyMedium`, 흰색), 중간 가상선(`dividerY`)에는 Google 로그인 버튼 **상단**이 맞도록 배치, 그 아래(`dividerY + 버튼 높이`)부터 높이 **`contentHeight/3`** 인 영역 중앙에 약관 문구를 둔다. 등장 연출 시 `Transform.translate` Y가 **노출 최상단(`contentTop+12`)이 뷰포트 하단 밖**으로 나가도록 거리를 `height`·`contentTop`에서 역산한다(여유 ~40px).
- **Google 로그인 버튼**: 기존 `assets/images/android_dark_rd_SI.png` 버튼 이미지를 사용하고, 로딩 중에는 같은 영역에 `CircularProgressIndicator`를 표시한다.
- **약관 문구**: 하단 영역 좌우 15% 패딩 안에서 `labelSmall` 기반으로 표시한다. 링크 색상/밑줄은 기존 `#80D7CF` 규칙 유지. 이용약관·개인정보처리방침 탭 시 각각 WebView로 이동한다.
- **로그인 플로우**: `AuthService.signInWithGoogle()` → idToken 검증 → `SudaApiClient.loginWithGoogle()` → `TokenStorage.saveTokens()` → `onSignIn` 콜백 순서. 에러는 `DefaultToast`로 표시한다.

---

## 2. HomeScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/home.dart`
- **클래스명**: `HomeScreen` (StatefulWidget)
- **스크린 타입**: **Main Screen**
- **appPath**: `/home`

### 스크린 용도
- 로그인 후 메인 화면
- 앱의 주요 기능 진입점
- **홈 배너**: 상단에 100% 너비의 정사각형 배너 노출 (스와이프 가능, 무한 루프)
- 향후 AI 영어 대화 기능이 추가될 예정

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
- **RoleplayOverviewScreen** (Sub Screen, **S1**): (현재는 명시적 버튼 없음, 향후 추가 예정)
  - S1 단일 롤플레이 Overview. 홈 v2 이후 홈 썸네일 탭은 S2 `SeriesOverviewScreen`으로 진입.
- **SeriesOverviewScreen** (Sub Screen, **S2**): Home 시리즈 썸네일 탭 시 `SeriesRouter.pushOverview`로 진입. `lib/screens/series/overview.dart`.
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
      - 탭: `SeriesOverviewScreen` (Sub, placeholder)
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
    - 제목: `textTheme.headlineSmall`(H3)·흰색 `foreground` + `BlendMode.softLight`(버튼 fill `#8A38F5→#280752`와 합성). 공간 부족 시 min 10px까지 축소·말줄임·클립 없음, min에서도 넘치면 `FittedBox.scaleDown`
    - 메인 pill fill `#8A38F5→#280752`·stroke `#80D7CF→#8A38F5` (좌→우, 1px padding border), radius height/2
    - Explorar: fill white 3.8%·12px 흰색·conic stroke·padding 4·radius 12(24h pill)
    - **글로우 애니메이션**: progress 기반 좌우 왕복(easeInOut 2.4~3.8s/leg). Glow1 별(왼)→오른끝→홈, Glow2 혜택보기(오른)→왼끝→홈. 횡단 중 Y 튕김 0~3회 랜덤 + bob. 소스: `paywall_star_badge.png` blur σ10, opacity ~0.55
    - 탭: pill 전체 → `PaywallScreen.push` → 성공 시 `getUserEnergy` 재조회 후 CTA 숨김
    - Profile 탭 활성·복귀 시 `getUserEnergy`로 구독 상태 갱신
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
- **ChangePlanScreen** (Sub Screen, stub): 구독 활성 시 Subscription 헤더 우측 `Change Plan >` 탭 시

### 스크린 내부 구현 특이사항
- 키보드 활성화 시 `resizeToAvoidBottomInset: false` (하단 "계정 삭제"가 키보드와 함께 올라오지 않도록)
- 진입 시 `GET /v1/users/energy/detail`로 구독 상태 갱신 (`SubscriptionStatusCache`)
- **Subscription 섹션**
  - 무료 (`isSubscribedActive == false`): Free Plan 카드(`check_green.svg`) → Paywall. l10n `accountFreePlanTitle` / `accountFreePlanSubtitle`
  - 구독 활성: Subscription 헤더 좌측. 구독↔카드 간격 **24**(이름/계정 섹션과 동일). `Change Plan >`(l10n `accountChangePlan` + chevron, 텍스트 `bodySmall` 14·**w700**/`wght` 700·흰색)는 그 간격 안 하단 우측(`right: 8`, 카드와 `bottom: 12`) → `ChangePlanScreen`. Premium 카드(`premium_verified_badge.png`) — 제목 `accountPremiumTitle`, 부제 `accountPremiumSubtitle`, 갱신일 `accountPremiumRenewsOn`(`subscriptionExpiredAt`, en/ko `yyyy/MM/dd` · pt `dd/MM/yyyy`)

---

## 5.0 ChangePlanScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/change_plan.dart`
- **클래스명**: `ChangePlanScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Account 하위)

### 이전 스크린 정보 (진입점)
- **AccountScreen**: 구독 활성 시 `Change Plan >` 탭

### 스크린 내부 구현 특이사항
- Phase 4 본문 UI 전 stub: `AppScaffold` + 헤더 `accountChangePlan`만. 플랜 목록·결제 변경은 후속.

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

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **SettingScreen**: 좌상단 뒤로가기 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- 좌상단 뒤로가기: 같은 레벨(Account, Feedback 등)과 동일
- 헤더 타이틀: 메뉴명 그대로(l10n.settingsNotification)
- 본문: width 100%, 배경 #353535, 모서리 둥근 박스. 좌측 설명(pushNotifications 흰색, pushNotificationsDesc caption·#80D7CF), 우측 토글(56×24 트랙, 20×20 흰 원). OFF: 원 좌측, 트랙 #8C8C8C. ON: 원 우측, 트랙 #80D7CF. 200 응답 후 전환 애니메이션.
- API: ON 시 `PUT /v1/users/push-agreement?agreementYn=Y`, OFF 시 `PUT /v1/users/push-agreement?agreementYn=N`
- 응답: `QuestResultDto { completeYn }`
  - `completeYn == 'Y'`: `Navigator.pop()`으로 자동 복귀
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

## 11. RoleplayOverviewScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/overview.dart`
- **클래스명**: `RoleplayOverviewScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: `/roleplay/overview/{roleplayId}` (예: `/roleplay/overview/12`)

### 스크린 용도
- Roleplay 목록 및 개요를 표시하는 화면
- 향후 n개의 롤플레이가 표시될 예정

### 이전 스크린 정보 (진입점)
- **HomeScreen**: 중앙 "Roleplay" 텍스트 클릭 시
  - `Navigator.push()`로 iOS 스타일 슬라이드 애니메이션으로 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayTutorialScreen** (Full Screen): 역할 버튼 탭 시 항상 먼저 진입 (Tutorial 완료 여부에 따라 자동 분기)
  - `Navigator.push()`로 Full Screen 형태로 전환

### 스크린 내부 구현 특이사항
- 우측 상단 X 버튼 필수
- 중앙에 "Play" 텍스트 (임시, 향후 롤플레이 목록으로 대체 예정)
- Route name: `/roleplay/overview` (뒤로가기 시 overview로 돌아가기 위해 사용)
- 역할 버튼 탭 시 `RoleplayRouter.pushTutorial()`로 Tutorial 스크린 경유 후 Opening 진입

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
- **RoleplayOverviewScreen**: 역할 버튼 탭 시 항상 거치며, 내부에서 조건 판단

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
- **appPath**: 해당 없음 (role 선택 필수)

### 스크린 용도
- Roleplay 시작 전 오프닝 화면

### 이전 스크린 정보 (진입점)
- **RoleplayOverviewScreen**: 중앙 "Play" 텍스트 클릭 시
  - `Navigator.push()`로 Full Screen 형태로 전환

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayPlayingScreen** (Full Screen): 중앙 "Start" 텍스트 클릭 시
  - `Navigator.pushReplacement()`로 전환 (opening screen 삭제, 돌아올 일 없음)

### 스크린 내부 구현 특이사항
- `RoleplayDto.overviewImgPath`가 있으면 전면 배경: `lib/widgets/roleplay_overview_backdrop.dart`의 `RoleplayOverviewBackdrop`(URL·연출은 Overview 상단과 동일·디스크 캐시 공유). 없으면 `RoleplayScaffold` 기본 배경 `#121212`.
- 본문: 선택 역할명은 `headlineLarge`·색 `#0CABA8`만(별도 `fontWeight` 없음). 시나리오 문구는 `localizedText`를 `DefaultMarkdown` 없이 단일 `Text`로, `bodyLarge`·흰색·중앙 정렬.
- 시스템 뒤로가기 버튼 클릭 시: opening screen 삭제, 이전 overview 노출
- 별도 X 버튼 제공 안 함
- 중앙에 "Start" 텍스트 (임시, 향후 오프닝 콘텐츠로 대체 예정)
- 우상단 `EnergyHeaderBadge` — Home과 동일(충전·무제한 타이머 포함)
- footer Start 버튼 아래 AI 안내(`l10n.roleplayOpeningAiDisclaimer`): `labelSmall`·`#8C8C8C`·중앙 정렬·두 문장 줄바꿈(`\n`). 버튼↔문구 12dp, 문구 아래 50dp.
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
- 본문은 상단 고정 미션 패널 + 스크롤 대화 영역. 대화 entry는 AI/User/Narration 타입이며 힌트는 별도 bubble로 append된다. 힌트 텍스트 조회 `GET /rps2/sessions/{id}/hint/{rpMsgId}`는 202 not-ready 시 S1 delay 패턴으로 최대 15회 재시도한다. AI 말풍선은 번역 아이콘과 `GET /rps2/sessions/{id}/translation?index=`를 사용한다.
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
- **Overview**: X·뒤로가기 시 Overview 복귀 (S2: `popToOverview`, S1: `Navigator.pop`)
- **Retry**: S2 `replaceWithOpeningForRetry` (세션 clear 후 동일 에피소드 Opening) · S1 `Navigator.pop`

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
- Roleplay 종료 후 결과·피드백·보상을 노출하는 기본 Result 화면 (구 레거시 `result.dart` 삭제, 구 `result_v2` 구현을 본 파일로 통합)

### 이전 스크린 정보 (진입점)
- **RoleplayEndingScreen**: 하단 "Next" 버튼 클릭 시 `RoleplayRouter.replaceWithResult()`로 즉시 전환 (ending screen 삭제)
- **RoleplayPlayingScreen** (S1): resultId 기반 종료 시 (미션 전부 완수 아님) 분기에서 `roleplayEndedComplete` 3초 노출 후 `replaceWithResult()`로 전환
- **RoleplayPlayingScreen** (S2): `PUT /rps2/sessions/{id}/finish` 성공·마지막 에피소드 아님 분기에서 `replaceWithResult()`로 전환 (`SeriesStateService.cachedUserHistory` 선저장)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultReportScreen** (Sub Screen): 본문 "Report" 문구 탭 시
  - `RoleplayRouter.pushResultReport()` → SubScreenRoute로 진입 (Result 위에 쌓임)
- **ReviewChatScreen** (Sub Screen): S1 Key Expression 헤더 우측 "View Chat" pill 탭 시 (`RoleplayResultDto` 전달). S2 Speech Feedback 헤더 View Chat은 API 연동 추후.
- 그 외: Got it! → Overview (`RoleplayRouter.popToOverview`)

### 스크린 내부 구현 특이사항
- **진입 판별**: `SeriesStateService.cachedUserHistory != null`이면 **S2**, 아니면 **S1** (`RoleplayStateService.cachedResult`).
- **배경**: 상단 `#054544` → 하단 `#0CABA8` 세로 그라데이션 전체 유지.
- **초기 박스레이어**: 별 3개 + mainTitle + subTitle(`#80D7CF`) + Mission/Words/Like 3카드. S2 Mission은 `rps2_mission_on/off.png` 20×20(gap 2), S1은 `mission_succeeded`/`mission_failed`.
- **별 애니메이션**: silver → `starResult`/`starScore` 개수만큼 gold 전환 + 진동.
- **후속 타이밍**: fully shown 1초 후 박스레이어 상단 이동 + `LikeProgressEffect.play()` (before/after like·level·progress).
- **effect 이후 본문 (S1)**: Feedback + Key Expression + Got it!/Report. Feedback 즉시, Key Expression 500ms 후, footer 1s 후 fade-in.
- **effect 이후 본문 (S2)**: Feedback **없음**. Key Expression + Speech Feedback + Got it!/Report. Key Expression·Speech Feedback 동시 슬라이드, footer 1s 후 fade-in.
- **Speech Feedback 펼침**: 구독자만. 비구독 Feedback 탭 → `PaywallScreen`. 결제 후 복귀 시 자동 펼침 없음·재탭 시 펼침 (`ensureSubscribedForSpeechFeedback`). History도 동일 본문.
- **Expression/Key Expression 카드**: 가로 70% 캐러셀, 카드 탭 시 TTS(S1 API 연동 완료, S2 메가폰·북마크 UI만·API 추후), 북마크(S1 API 연동 완료).
- **Got it! (S1)**: `GET /v1/users` + `GET /v1/roleplays/{roleplayId}/overview` best-effort 후 Overview pop.
- **Got it! (S2)**: 동일 경로로 Overview pop (Series Overview).
- **Report**: `l10n.endingReport`, 전송 성공 시 숨김, 텍스트 `#054544`.
- **시스템 뒤로가기**: Got it!과 동일하게 Overview 복귀 (`PopScope`).

---

## 18. RoleplayResultReportScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/result_report.dart`
- **클래스명**: `RoleplayResultReportScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Result 전용)

### 스크린 용도
- Result 화면에서 진입. 사용자가 느낀 불편함을 수집하는 용도.
- **S1** Send: `POST /v1/roleplays/results/{roleplayResultId}/report` (body: `{"content": "<string>"}`).
- **S2** Send: `POST /rps2/user-histories/{rpUserHistoryId}/report` (body 동일). `SeriesStateService.cachedUserHistory.id` 사용.

### 이전 스크린 정보 (진입점)
- **RoleplayResultScreen**: 본문 "Report" 문구 탭 시
  - `RoleplayRouter.pushResultReport()` → SubScreenRoute로 우측에서 슬라이드 인

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultScreen**: X 버튼 또는 Android 백버튼 시 `Navigator.pop()`으로 Result로 복귀. 전송 성공(200) 시 `feedbackSuccess` 토스트 후 `pop(context, true)`로 Result에서 Report 문구 숨김.

### 스크린 내부 구현 특이사항
- 내부 표현·구성은 Try Again Report와 동일 (그라데이션 배경 + 글래스 입력창 + Stadium Send 버튼). S1/S2 분기는 Send API·ID 소스만 다름.
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
- S1 `GET /v1/roleplays/results`·`history_v2.dart`·version 분기 **삭제**

---

## 20. ReviewChatScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/review_chat.dart`
- **클래스명**: `ReviewChatScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (History 전용)

### 스크린 용도
- History Screen에서 진입. 롤플레이 채팅 내용 열람.

### 이전 스크린 정보 (진입점)
- **RoleplayResultScreen** (S1 Key Expression View Chat): Key Expression 헤더 우측 "View Chat" pill 탭 시 (RoleplayResultDto 전달)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **이전 스크린**: 좌상단 뒤로가기 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- **헤더**: 중앙 "Chat History" (headlineMedium·흰색), Setting 계열 스타일. 좌상단 뒤로가기(header_arrow_back.svg).
- **배경**: 상→하 선형 그라데이션 `#054544`→`#0CABA8` + 검정 40% 오버레이(`0x66000000`). AppScaffold `backgroundColor: transparent`, showBackButton: true.
- **안내 문구**: 헤더 아래 `reviewChatTapHint`(l10n·디바이스 언어) + 좌측 `assets/images/icons/speaker.png`(16×16), bodySmall·`#80D7CF`.
- **본문**: RoleplayResultDto.chatHistory(List\<SudaJson\>)를 순서대로 표시. key로 발화자 구분: USER(사용자 말풍선·우측·흰색), AI_CHARACTER(AI 말풍선·좌측·#0CABA8·avatarImgPath 아바타 40×40), AI_NARRATOR(나레이션·중앙·이탤릭 흰색), SYSTEM_MISSION(미션·중앙·Mission 뱃지+핑크 텍스트). value를 그대로 문구로 표시. USER/AI 말풍선은 네 꼭짓점 동일 반지름(20)·둥근 직사각형 형태.
- **오디오 재생 UX**: 진입 시 `GET …/review-chat/audio-meta`. USER(음성 입력)·AI_CHARACTER 말풍선 탭으로 재생(별도 스피커 버튼 없음). 재생·로딩 중 말풍선 배경 `#80D7CF`·텍스트 `#054544`(AnimatedContainer 180ms). 동일 라인 재탭 시 stop, 다른 라인 탭 시 전환. 완료 시 기본 색 복귀. 재생 불가·실패·텍스트 입력 라인 탭 시 `reviewChatNoAudioToPlay` 토스트(l10n). USER는 `GET …/lines/{lineIndex}/user-sound` bytes, AI는 meta `aiCdnPath`+CDN.

---

## 21. ReviewEndingScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/review_ending.dart`
- **클래스명**: `ReviewEndingScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (History 전용)

### 스크린 용도
- History Screen에서 진입. 롤플레이 엔딩 내용 열람(단순 조회, 버튼 없음).

### 이전 스크린 정보 (진입점)
- **HistoryScreen**: "View Ending" 버튼 탭 시. API·이미지 프리로드 완료 후 진입.

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HistoryScreen**: 좌상단 뒤로가기 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- **헤더**: 중앙 "View Ending", 좌상단 뒤로가기(View Chat과 동일). 배경색 `#121212`.
- **본문**: 헤더 아래 전체 영역에 엔딩 이미지(비율 유지·높이 100% 채움, BoxFit.cover·좌우 잘림 가능). **2초 후** 검정 레이어(0xCC000000)·타이틀·콘텐츠 페이드인(300ms). 타이틀 위쪽 25%/콘텐츠 아래 75% 비율. title/content는 SudaJsonUtil.localizedText로 사용자 언어에 맞게 표시. 별점·Next 등 버튼 없음.
- **진입**: History에서 `GET /v1/roleplays/{rpId}/roles/{rpRoleId}/endings/{endingId}` 호출 후 이미지 프리로드 완료 시 SubScreenRoute로 진입. View Ending 버튼은 Opening과 동일한 24×24 뱅글 로딩 표시.

---

## 22. PaywallScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/paywall/paywall.dart`
- **클래스명**: `PaywallScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen** (optional bottom-up)
- **전환 방식**: `FullScreenRoute` + `FullScreenTransition.bottomUp` (450ms / reverse 280ms). `PaywallScreen.push(context)`
- **appPath**: 해당 없음 (구독 플로우. 진입: 에너지 팝업 Go Premium, Result/History/View Chat Speech Feedback, Lab)

### 스크린 용도
- Premium 구독 Paywall. 월/연 선택 후 Play Billing SUBS → verify.

### 이전 스크린 정보 (진입점)
- **에너지 팝업** Go Premium (`EnergyPurchaseSection`)
- **LabScreen** (dev): Setting > Lab > **Open Paywall**

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **PaywallCompletedScreen**: verify 성공(비 pending)
- **이전 스크린**: X/`pop()`, 또는 성공·승인대기 후 `pop(true)`

### 스크린 내부 구현 특이사항
- **결제**: `IapPurchaseService.purchaseSubscription` (`bp-premium-monthly`/`bp-premium-yearly`). CTA `_purchasing` lock. dispose 시 `abandonPendingPurchase`.
- **가격**: 스토어. 월간 `price/mês`. 연간 메인 `rawPrice/12` 포맷+`/mês`, 서브 yearly+`/ano`. 미조회 시 하드코딩 폴백.
- **verify N**: 실패 토스트·유지. **pending Y**: 승인대기 토스트+`pop(true)`. **성공**: Completed push 후 Paywall `pop(true)`.
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
- **문구/버튼**: PT 하드코딩(l10n 추후). CTA `Continuar`

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

[NotificationBoxScreen] ←→ [HomeScreen] ←→ [ProfileScreen] (GNB Alarm/Home/Profile 3탭 전환)
  ├─ [HomeScreen] → [RoleplayOverviewScreen] (중앙 "Roleplay" 텍스트)
  │   └─ [RoleplayOpeningScreen] (중앙 "Play" 텍스트)
  │       └─ [RoleplayPlayingScreen] (중앙 "Start" 텍스트)
  │           ├─ [RoleplayEndingScreen] (중앙 "Ending" 텍스트)
  │           │   └─ [RoleplayResultScreen]
  │           │       └─ [RoleplayResultReportScreen] (Report 문구 탭 시, 백버튼/X → Result 복귀)
  │           └─ [RoleplayTryAgainScreen]
  │               └─ [RoleplayTryAgainReportScreen] (Report 텍스트 탭 시, 백버튼/X → Try Again 복귀)
  └─ [ProfileScreen] → [SettingScreen] (우측 상단 원형 버튼)
  │       ├─ [AccountScreen]
  │       │   └─ [ChangePlanScreen] (구독 활성 시 Change Plan, stub)
  │       ├─ [CefrLevelScreen]
  │       ├─ [FeedbackScreen]
  │       ├─ [WebViewScreen] (Privacy policy / Terms of Service)
  │       ├─ [OpenSourceLicenseScreen]
  │       └─ Log out → [LoginScreen] (곧바로 이동)
  └─ [ProfileScreen] → [HistoryScreen] (롤플레이 히스토리 썸네일 탭)
          ├─ [ReviewChatScreen] (채팅 열람)
          └─ [ReviewEndingScreen] (엔딩 열람)
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
| `/roleplay/overview/{roleplayId}` | RoleplayOverviewScreen (Sub) | 예: `/roleplay/overview/12` |
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
