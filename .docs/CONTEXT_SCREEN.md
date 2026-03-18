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
| 진입 애니메이션 | 일반 전환 | 일반 전환 | 우측→좌측 슬라이드 |
| 뒤로가기 버튼 | ❌ 없음 | ❌ 없음 | ✅ 있음 (우측 상단 X) |
| 시스템 뒤로가기 | 앱 종료 | Home: 앱 종료 / Alarm·Profile: Home으로 | 슬라이드 아웃 |
| 사용 예시 | LoginScreen | NotificationBoxScreen, HomeScreen, ProfileScreen | 상세 화면, 설정 화면 |

---

## 네이티브 스플래시 화면

### 스플래시 관련 정의 파일
- **패키지**: `flutter_native_splash` (버전 2.3.10 이상)
- **설정 파일**: `pubspec.yaml`의 `flutter_native_splash` 섹션
- **Android**: `android/app/src/main/res/drawable/launch_background.xml` (자동 생성)
- **iOS**: `ios/Runner/Base.lproj/LaunchScreen.storyboard` (자동 생성)

### 스플래시 용도
- 앱 실행 직후 Flutter 엔진 초기화 및 JWT 인증 상태 확인 중 표시
- **이미지 없음**, 어두운 단색 배경(`#121212`)만 노출
- JWT 토큰 확인 및 서버 검증 완료 후 자동 제거

### 표시 조건
- 앱 실행 시 자동 표시
- `FlutterNativeSplash.preserve()`로 Flutter 엔진 초기화 후에도 유지
- `FlutterNativeSplash.remove()` 호출 시 제거

### 제거 시점 및 이후 화면
- JWT 토큰이 없을 때: `_checkAuthStatus()`에서 제거 → **CustomSplashScreen** → LoginScreen
- JWT 토큰이 유효할 때: 서버 검증 완료 후 제거 → HomeScreen(또는 AgreementScreen)
- JWT 토큰이 유효하지 않을 때: 에러 처리 후 제거 → CustomSplashScreen → LoginScreen

### 스플래시 내부 구현 특이사항
- **배경색**: `#121212` (이미지 없음)
- **생성 방법**: `dart run flutter_native_splash:create` 명령으로 자동 생성
- **Android 12+ 지원**: `android_12.color` 설정
- **제어 방법**: `lib/main.dart`에서 `FlutterNativeSplash.preserve()` 및 `FlutterNativeSplash.remove()` 사용

---

## 0. CustomSplashScreen (커스텀 스플래시)

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/custom_splash.dart`
- **클래스명**: `CustomSplashScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen** (GNB 없음, 인증 플로우 전 단계)
- **appPath**: 해당 없음

### 스크린 용도
- 앱 실행 시 네이티브 스플래시 제거 후, LoginScreen 전에만 표시되는 Flutter 스플래시
- 네이티브 스플래시(배경색만)와 LoginScreen 사이의 전환·애니메이션을 담당 (애니메이션 상세는 추후 정의)
- **로그아웃 시에는 표시하지 않음** → 곧바로 LoginScreen으로 이동

### 이전 스크린 정보 (진입점)
- **네이티브 스플래시**: 앱 실행 후 JWT 토큰이 없거나 유효하지 않을 때 (`FlutterNativeSplash.remove()` 직후)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **LoginScreen**: `onComplete` 콜백 호출 시 `_MyAppState`에서 `_showCustomSplash = false`로 전환하여 표시

### 표시 조건
- `_MyAppState._accessToken == null` 이면서 `_showCustomSplash == true`일 때만 표시
- 로그아웃 시에는 `_onSignOut()`에서 `_showCustomSplash = false`로 설정하므로 CustomSplashScreen을 거치지 않고 LoginScreen으로 전환

### 스크린 내부 구현 특이사항
- **배경색**: `#121212` (네이티브 스플래시와 동일)
- **완료 시점**: 현재는 `initState`에서 1.5초 후 `onComplete()` 호출. 추후 커스텀 스플래시 → Login 연계 애니메이션 정의 시 해당 시점으로 변경 가능

---

## 1. LoginScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/login.dart`
- **클래스명**: `LoginScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (인증 플로우)

---

## 1.1 AgreementScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/agreement.dart`
- **클래스명**: `AgreementScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (동의 플로우)

### 스크린 용도
- 서비스 이용을 위한 필수 약관 동의 화면
- 로그인 후 사용자 정보(`SudaUser`)의 `metaInfo` 중 `SUDA_AGREEMENT` 값이 'Y'가 아닌 경우 표시

### 이전 스크린 정보 (진입점)
- **LoginScreen**: 로그인 성공 후 동의 정보가 없을 때
- **네이티브 스플래시**: 자동 로그인 후 동의 정보가 없을 때

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HomeScreen**: 동의 완료(`POST /v1/users/agreement`) 성공 시
- **WebViewScreen**: 이용약관 및 개인정보 처리방침 "자세히 보기" 클릭 시

### 스크린 내부 구현 특이사항
- **다국어 지원**: 한국어(ko), 영어(en), 포르투갈어(pt) 지원 (기본값 en)
- **동의 항목**: 이용약관, 개인정보 처리방침 (모두 체크 시에만 버튼 활성화)
- **API 호출**: `SudaApiClient.updateAgreement()` 호출
- **디자인**: 어두운 배경색, 중앙 정렬 레이아웃

---

### 스크린 용도
- Google 로그인을 위한 인증 화면
- 로그인되지 않은 사용자에게 표시
- Google Sign-In을 통해 idToken 획득 후 SUDA 서버에 JWT 발급 요청

### 이전 스크린 정보 (진입점)
- **CustomSplashScreen**: 앱 실행 후 토큰이 없거나 유효하지 않을 때 (커스텀 스플래시 `onComplete` 후 표시)
- **HomeScreen**: 로그아웃 시 (`onSignOut` 콜백 호출) → CustomSplashScreen 없이 곧바로 LoginScreen 표시
- **조건**: `_MyAppState`의 `_accessToken == null`이고 `_showCustomSplash == false`일 때 표시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HomeScreen**: Google 로그인 성공 및 JWT 토큰 발급 성공 시
  - `onSignIn` 콜백 호출 → `_MyAppState._onSignIn()` 실행 → 상태 업데이트로 자동 전환

### 스크린 내부 구현 특이사항
- **스크린 타입 특성**: Full Screen
  - GNB 없음
  - 시스템 뒤로가기 시 앱 종료 처리 필요 (`WillPopScope` 또는 `PopScope` 사용)
- **Google 로그인 버튼**: `ElevatedButton.icon` 사용
  - 로딩 중일 때 `CircularProgressIndicator` 표시
  - Google 로고 이미지: `assets/images/google_logo.png` (없으면 `Icons.login` 아이콘 사용)
- **로그인 플로우**:
  1. `AuthService.signInWithGoogle()` 호출하여 Google 로그인 및 idToken 획득
  2. idToken이 없으면 에러 메시지 표시 (SnackBar)
  3. `SudaApiClient.loginWithGoogle()` 호출하여 SUDA 서버에 idToken 전달 및 JWT 발급
  4. `TokenStorage.saveTokens()`로 JWT 토큰 저장
  5. `onSignIn` 콜백 호출하여 상위로 결과 전달
  6. 성공 시 환영 메시지 표시 (SnackBar)
- **환경 표시**: 개발/스테이징 환경일 때 상단에 환경명 표시 (`AppConfig.isPrd == false`)
- **에러 처리**: 모든 에러는 SnackBar로 표시, 터미널에도 로그 출력
- **UI 구성**:
  - 중앙 정렬된 Column 레이아웃
  - 앱 로고 아이콘 (`Icons.chat_bubble_outline`, 80px)
  - 앱 이름 "Suda" (32px, bold, deepPurple)
  - 부제목 "AI와 함께하는 영어 대화" (16px, grey)
  - 환경 표시 배지 (개발/스테이징 환경만)
  - Google 로그인 버튼 (전체 너비, 50px 높이)

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
- **RoleplayOverviewScreen** (Sub Screen): (현재는 명시적 버튼 없음, 향후 추가 예정)
  - 향후 n개의 롤플레이가 Home Screen에 게시될 예정

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
    - **롤플레이 카테고리**:
      - 구성: 카테고리명(h3) + 가로 스크롤 썸네일 리스트
      - 썸네일: 30% 너비, radius 10, 음영 박스 오버레이 타이틀  
        (텍스트가 영역을 초과할 때만 Marquee 적용)
      - 기능: 레이지 로딩(페이징) 지원, 로딩 중 Shimmer 스켈레톤 노출
- **API 연동**:
  - **홈 콘텐츠 통합 조회**: `GET /v1/home/contents` (`SudaApiClient.getHomeContents()`)
    - 응답: HomeDto (banners, roleplays, restYn, restStartsAt, restEndsAt)
  - **롤플레이 페이징 조회**: `GET /v1/home/roleplays` (`SudaApiClient.getRoleplaysByCategory()`)
  - **푸시 토큰 등록**: `_registerPushToken()` 메서드로 처리
    - Firebase Messaging 토큰 획득 후 서버에 전송 (`POST /users/push-token`)
- **초기화 작업**: `initState()`에서 `_performInitialization()` 호출 (한 번만 실행)
  - `_isInitialized` 플래그로 중복 실행 방지
- **Props**:
  - `onNavigateToAlarm`: Alarm 화면으로 이동 시 호출되는 콜백
  - `onNavigateToProfile`: Profile 화면으로 이동 시 호출되는 콜백
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
- **HistoryScreen** (Sub Screen): 롤플레이 히스토리 썸네일 탭 시 (resultId 전달)
  - `Navigator.push(SubScreenRoute(page: HistoryScreen(resultId: ...)))` 로 진입

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
    - Progress Box 아래 gap 50 이후, 남은 하단 영역은 추후 히스토리 영역 예정 (현재는 빈 상태)
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
- **LanguageLevelScreen** (Sub Screen): "Language Level" 클릭 시
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

### 스크린 내부 구현 특이사항
- 배경색: RGB(51, 51, 51) - SettingScreen 대비 10% 밝기 증가
- 우측 상단 X 버튼 필수
- 콘텐츠 구성: 서버 공시 페이지와 유사한 섹션형 레이아웃
  - 상단 안내문: "This page provides information on some of the open-source libraries and their licenses used in the SUDA app."
  - 라이선스별 섹션 + 라이선스 URL + 패키지/버전 목록 표시
  - 현재 공시 범위는 앱 코드(Flutter 앱 직접 의존성) 기준
- 키보드 활성화 시 `AccountScreen`은 `resizeToAvoidBottomInset: false`로 유지  
  (하단 "계정 삭제" 텍스트 버튼이 키보드와 함께 따라 올라오는 현상 방지)

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
  - `completeYn == 'Y'`: 티켓 보상 지급으로 간주, `surveySuccessToast` 노출 후 `Navigator.pop()`으로 자동 복귀
  - `completeYn != 'Y'`(N 포함): 추가 토스트 없이 기존처럼 토글 상태만 반영

---

## 6. LanguageLevelScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/setting/language_level.dart`
- **클래스명**: `LanguageLevelScreen` (StatelessWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Setting 하위)

### 이전 스크린 정보 (진입점)
- **SettingScreen**: "Language Level" 클릭 시

### 스크린 내부 구현 특이사항
- 배경색: RGB(51, 51, 51) - SettingScreen 대비 10% 밝기 증가
- 우측 상단 X 버튼 필수

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
- 배경색: RGB(51, 51, 51) - SettingScreen 대비 10% 밝기 증가
- 우측 상단 X 버튼 필수

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
- **팝업 (AppContentDialog)**: showYn='n' 또는 404 시 상세 진입 대신 팝업. 본문 l10n.postNoLongerAvailable, 버튼 l10n.backToHome

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

### 이전 스크린 정보 (진입점)
- **AnnouncementsScreen**: 공지 카드 탭 시 (`noticeId` 전달)

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
- **RoleplayOpeningScreen** (Full Screen): 중앙 "Play" 텍스트 클릭 시
  - `Navigator.push()`로 Full Screen 형태로 전환

### 스크린 내부 구현 특이사항
- 우측 상단 X 버튼 필수
- 중앙에 "Play" 텍스트 (임시, 향후 롤플레이 목록으로 대체 예정)
- Route name: `/roleplay/overview` (뒤로가기 시 overview로 돌아가기 위해 사용)

---

## 11.1 NotificationBoxScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/notification_box.dart`
- **클래스명**: `NotificationBoxScreen` (StatefulWidget)
- **스크린 타입**: **Main Screen**
- **appPath**: `/box`

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
  - API: `GET /v1/users/notification?page={page}` (`SudaApiClient.getNotifications()`)
  - 응답: `List<NotificationDto>` (id, title(List<SudaJson>), content(List<SudaJson>), imgPath, appPath, sendFinishedAt)
  - `page=0`부터 시작, 스크롤을 아래로 내릴 때 1, 2, 3... 순차 호출
  - 호출 결과가 빈 리스트이면 더 이상 호출하지 않음
- 화면 진입 또는 Alarm 탭이 다시 활성화될 때(page 0) 목록을 새로 조회
- **빈 상태**: 조회 결과가 없을 때는 본문 영역 정중앙에  
  - `No notification yet` 문구를 body-default 스타일·흰색으로 가로/세로 중앙 정렬하여 노출 (l10n `notificationsEmpty`)
- **목록 상태**: 조회 결과가 있을 때는 각 요소를 아래로 append
  - 요소별 레이아웃: width 100% 짜리 흰색 둥근 테두리를 가진 투명 박스 안에  
    - 첫 줄: title 한 줄 (SudaJsonUtil.localizedText, maxLines:1, ellipsis)  
    - 둘째 줄: content 한 줄 (동일 규칙)
- ScrollController를 사용하여 `maxScrollExtent - 200` 지점에서 다음 페이지 로딩 트리거
- 뒤로가기 버튼 없음 (`showBackButton: false`)
- Route name: `/notification_box` (참조용)

---

## 12. RoleplayOpeningScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/opening.dart`
- **클래스명**: `RoleplayOpeningScreen` (StatelessWidget)
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
- **RoleplaySurveyScreen** (Sub Screen): `sessionId == '-10'` 분기 팝업의 "Answer now ✅" 버튼 클릭 시
  - `RoleplayRouter.pushSurvey()` → SubScreenRoute로 우측에서 슬라이드 인
- **PushAgreementScreen** (Sub Screen): `sessionId == '-20'` 분기 팝업의 "Turn on 🔔" 버튼 클릭 시
  - 팝업 닫힘 후 SubScreenRoute로 우측에서 슬라이드 인

### 스크린 내부 구현 특이사항
- 시스템 뒤로가기 버튼 클릭 시: opening screen 삭제, 이전 overview 노출
- 별도 X 버튼 제공 안 함
- 중앙에 "Start" 텍스트 (임시, 향후 오프닝 콘텐츠로 대체 예정)
- 세션 초기화 응답 분기:
  - `sessionId == '-20'`: 3단 팝업(타이틀 + `surveyPromptLine1` + `pushTicketPromptLine2` + `pushTicketTurnOnButton`)
  - `sessionId == '-30'`: 3단 팝업(타이틀 + `surveyPromptLine1` + `shareTicketPromptLine2` + `shareTicketButton`)
    - "Share link 💬" 탭 시 팝업 닫고 OS 공유시트 노출(Play Store 링크 공유)
    - 공유시트 닫힘 감지 후 `POST /v1/users/quests/{questId}` 호출 (`questId = sessionId`)
    - 응답 `QuestResultDto.completeYn == 'Y'`일 때만 `surveySuccessToast` 토스트 노출
  - `sessionId == '-40'`: 3단 팝업(타이틀 + `surveyPromptLine1` + `reviewTicketPromptLine2` + `reviewTicketButton`)
    - "Leave Stars ⭐" 탭 시 팝업 닫고 OS 인앱리뷰 API 호출
    - 인앱리뷰 호출 성공 반환 시 `POST /v1/users/quests/{questId}` 호출 (`questId = sessionId`)
    - 응답 `QuestResultDto.completeYn == 'Y'`일 때만 `surveySuccessToast` 토스트 노출

---

## 12.1 RoleplaySurveyScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/survey.dart`
- **클래스명**: `RoleplaySurveyScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Opening -10 분기 전용)

### 스크린 용도
- Opening에서 세션 초기화 응답 `sessionId == '-10'`인 경우 진입하는 3단계 선택형 설문 화면.

### 이전 스크린 정보 (진입점)
- **RoleplayOpeningScreen**: `sessionId == '-10'` 팝업의 "Answer now ✅" 버튼 클릭 시

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayOpeningScreen**: X 버튼 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- 헤더: 타이틀 없이 닫기(X) 버튼만 노출.
- 상단 진행바: width 100% 기준 3분할(각 32%, height 8, radius 4). 단계 활성 바는 좌→우 그라데이션(`#076766`→`#0CABA8`), 비활성은 `#353535`.
- 단계 진행:
  - 1단계(연령): `Under 18`, `18-24`, `25-34`, `35-44`, `45+` (값 1~5)
  - 2단계(성별): `Female`, `Male`, `Prefer not to say` (l10n, 값 1~3)
  - 3단계(유입경로): `Facebook`, `Instagram`, `TikTok`, `Friends`, `Others` (값 1~5)
- 레이아웃: 진행바 아래 `gap 50` → title(h2, 흰색, 중앙) → `gap 50` → 선택지 세로 나열(gap 10).
- 선택지 버튼: `width=디스플레이 40%`, `height=60`, `radius=30`, 배경 투명, 테두리 `#635F5F`(1), 텍스트는 ElevatedButton 스타일(흰색).
- 3단계 선택 시 `POST /v1/users/survey` 호출:
  - body: `{ "age": "<1~5>", "gender": "<1~3>", "source": "<1~5>" }` (문자열 숫자)
  - 응답 `200 + body == 'Y'`: 성공 토스트(`surveySuccessToast`) 후 `pop`
  - 그 외 응답/예외(4xx/5xx/timeout 포함): 경고 토스트 `"Survey Failed"` 후 `pop`
- 제출 중에는 모든 선택지 버튼 비활성화.

---

## 13. RoleplayPlayingScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/playing.dart`
- **클래스명**: `RoleplayPlayingScreen` (StatelessWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- Roleplay 진행 중 화면

### 이전 스크린 정보 (진입점)
- **RoleplayOpeningScreen**: 중앙 "Start" 텍스트 클릭 시
  - `Navigator.pushReplacement()`로 전환 (opening screen 삭제)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayEndingScreen** (Full Screen): 중앙 "Ending" 텍스트 클릭 시
  - `Navigator.pushReplacement()`로 전환 (playing screen 삭제, 돌아올 일 없음)
- **RoleplayFailedScreen** (Full Screen): 중앙 "Failed" 텍스트 클릭 시
  - `Navigator.pushReplacement()`로 전환 (playing screen 삭제, 돌아올 일 없음)

### 스크린 내부 구현 특이사항
- 시스템 뒤로가기 버튼 클릭 시: "페이지를 나갑니다" 얼럿 노출, 확인 시 playing screen 삭제, 이전 overview 노출
- 별도 X 버튼 제공 안 함
- 중앙에 "Ending", "Failed" 텍스트 (임시, 향후 게임 진행 UI로 대체 예정)

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
  - Next 버튼 텍스트 fade-out과 동시에 버튼에서 #0CABA8 풍선이 부푸는 모양으로 전체 화면 덮는 애니메이션(2s) 후 `RoleplayRouter.replaceWithResult()`로 전환 (ending screen 삭제, 돌아올 일 없음)
  - `PUT /v1/roleplays/results/{rpResultId}?star={star}` 호출(응답 무시)은 전환 전에 수행

### 스크린 내부 구현 특이사항
- 닫기(X) 버튼 없음. 시스템 뒤로가기 시 "Exit from ending screen" 얼럿, 확인 시 ending screen 삭제 후 Overview 노출.
- 엔딩 데이터: 사용자 role(`RoleplayStateService.overview`·`roleId`)의 `endingList` 첫 번째 요소(`RoleplayEndingDto`) 사용. 이미지 없을 경우 바로 80% 검정 레이어·콘텐츠 노출.
- 이미지 있을 경우: 디바이스 높이 100% 비율 유지 표시(기본). 중앙 기준 1.5배→1배 약 2초 축소 애니메이션 후, 80% 투명도 검정 레이어 fade-in, 이어서 콘텐츠 fade-in.
- 레이아웃: 상단 75% = SingleChildScrollView(gap 50 / 타이틀 / gap 50 / 콘텐츠 / gap 50 / 평가문구 / gap 15 / 별 5개 40×40 gap 5). 콘텐츠 양이 많으면 이 영역 내 스크롤. 하단 25% = Next 버튼(Opening Let's start 스타일, l10n `endingNext`). 별점은 선택 시 해당 별 및 좌측 star_filled, 우측 star_empty. star=0 허용.
- Playing에서 ending 전환 확정 시점에 role.endingList 첫 요소의 `imgPath`에 CDN host prepend하여 이미지 preload.

---

## 15. RoleplayFailedScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/failed.dart`
- **클래스명**: `RoleplayFailedScreen` (StatelessWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- Roleplay 실패 종료 화면

### 이전 스크린 정보 (진입점)
- **RoleplayPlayingScreen**: 중앙 "Failed" 텍스트 클릭 시
  - `Navigator.pushReplacement()`로 전환 (playing screen 삭제)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayFailedReportScreen** (Sub Screen): "Report" 텍스트 클릭 시
  - `RoleplayRouter.pushFailedReport()` → SubScreenRoute로 진입 (Failed 위에 쌓임)
- **RoleplayResultScreen** (Full Screen): "Retry" 버튼 클릭 시 Overview로 복귀. Result로의 전환은 Playing에서 resultId 분기로 진행.

### 스크린 내부 구현 특이사항
- 닫기(X)/시스템 뒤로가기: 확인 다이얼로그 없이 Overview로 복귀 (Opening과 동일).
- 푸터 없음. 본문 5요소: Failed 타이틀, 하트 애니메이션, ending.fail 문구, Retry 버튼, Report 텍스트(탭 시 Failed Report Sub Screen 진입).

---

## 16. RoleplayFailedReportScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/failed_report.dart`
- **클래스명**: `RoleplayFailedReportScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Failed 전용)

### 스크린 용도
- Failed 화면에서만 진입. 사용자가 느낀 불편함을 수집하는 용도.

### 이전 스크린 정보 (진입점)
- **RoleplayFailedScreen**: "Report" 텍스트 클릭 시
  - `RoleplayRouter.pushFailedReport()` → SubScreenRoute로 우측에서 슬라이드 인

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayFailedScreen**: X 버튼 또는 Android 백버튼 시 `Navigator.pop()`으로 Failed로 복귀

### 스크린 내부 구현 특이사항
- 롤플레이 스캐폴드(RoleplayScaffold) 적용.
- Route name: `RoleplayFailedReportScreen.routeName` (`/roleplay/failed_report`).
- Android 디바이스 백버튼: Failed로 복귀 (pop).
- 본문: 입력창 + 제출 버튼(sendFeedback API). 성공 시 pop(true).

---

## 17. RoleplayResultScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/result.dart`
- **클래스명**: `RoleplayResultScreen` (StatefulWidget)
- **스크린 타입**: **Full Screen**
- **appPath**: 해당 없음 (세션·플로우 의존)

### 스크린 용도
- Roleplay 결과 화면

### 이전 스크린 정보 (진입점)
- **RoleplayEndingScreen**: 하단 "Next" 버튼 클릭 후 풍선 확장 애니메이션(2s) 완료 시 `RoleplayRouter.replaceWithResult()`로 전환 (ending screen 삭제)
- **RoleplayPlayingScreen**: resultId 기반 종료 시 (미션 전부 완수 아님) 분기에서 `roleplayEndedTimesup` 또는 `roleplayEndedComplete` 3초 노출 후 `Navigator.pushReplacement()`로 전환 (playing screen 삭제)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultReportScreen** (Sub Screen): 본문 "Report" 문구 탭 시
  - `RoleplayRouter.pushResultReport()` → SubScreenRoute로 진입 (Result 위에 쌓임)
- 그 외: 최종 결과 화면(Overview 이동은 Got it! 버튼)

### 스크린 내부 구현 특이사항
- **박스레이어/본문레이어**: 줄어드는 영역을 박스레이어, 그 뒤쪽을 본문레이어로 칭함.
- **진입(박스레이어)**: 전체 화면 #0CABA8 박스 → 로딩 300ms 후 별점 3개(70×70 -10°/80×80/70×70 +10°, starResult 1~3이면 star_gold else star_silver) 노출·진동 → 300ms 후 mainTitle(h1 흰색)·진동 → 300ms 후 subTitle(h3 검정)·진동 → 300ms 후 박스 축소 트리거. 박스 축소 시 내부 요소는 가로세로 중앙에 쫀쫀하게 유지. 박스 최종 높이 210, easeOutQuint 1.5s.
- **본문레이어**: gap 35 → like_at_result 75×75 + likePoint(h1, 그라데이션 #80D7CF→#CFFFFB, 없으면 00) → gap 35 → 좌 50% Mission(body-default w600 Chiron GoRound TC #80D7CF) + missionResult별 아이콘(mission_succeeded/mission_failed, 높이 20, gap 없음) / 우 50% Words + words(없으면 00) → gap 25 → Lv.x 프로그레스바(Profile 동일, getUserProfile로 currentLevel·progressPercentage) → gap 25 → Good Points(h3 Chiron GoRound TC #80D7CF) → gap 20 → goodFeedback(body-caption 흰색) → gap 25 → To Improve(h3 동일) → gap 20 → improvementFeedback(body-caption 흰색) → gap 25 → Got it! 버튼(Opening Let's Start 스타일, 탭 시 Overview) → gap 35 → Report 문구(다국어 l10n.endingReport, 중앙 정렬, 탭 시 Result Report 스크린 진입, 전송 성공 후 돌아오면 숨김). SingleChildScrollView로 스크롤.
- 시스템 뒤로가기 동작: 향후 구현 예정

---

## 18. RoleplayResultReportScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/result_report.dart`
- **클래스명**: `RoleplayResultReportScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: 해당 없음 (Result 전용)

### 스크린 용도
- Result 화면에서만 진입. 사용자가 느낀 불편함을 수집하는 용도. Send 시 `POST /v1/roleplays/results/{roleplayResultId}/report` (body: `{"content": "<string>"}`).

### 이전 스크린 정보 (진입점)
- **RoleplayResultScreen**: 본문 "Report" 문구 탭 시
  - `RoleplayRouter.pushResultReport()` → SubScreenRoute로 우측에서 슬라이드 인

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **RoleplayResultScreen**: X 버튼 또는 Android 백버튼 시 `Navigator.pop()`으로 Result로 복귀. 전송 성공(200) 시 `pop(context, true)`로 Result에서 Report 문구 숨김.

### 스크린 내부 구현 특이사항
- 내부 표현·구성은 Failed Report와 동일 (RoleplayScaffold, reportTitle, 입력창, feedbackSend 버튼). Send 시 신규 엔드포인트만 사용.
- Route name: `RoleplayResultReportScreen.routeName` (`/roleplay/result_report`).
- 다국어: failed_report 참고 (l10n.reportTitle, endingReport, feedbackPlaceholder, feedbackSend).

---

## 19. HistoryScreen

### 스크린 관련 정의 파일
- **파일 경로**: `lib/screens/roleplay/history.dart`
- **클래스명**: `HistoryScreen` (StatefulWidget)
- **스크린 타입**: **Sub Screen**
- **appPath**: `/profile/history/{resultId}` (예: `/profile/history/456`)

### 스크린 용도
- Profile에서 진입. 롤플레이 결과 요약. Result Screen과 동일 구조(초기 애니메이션 없음).
- History ↔ ReviewChat/ReviewEnding 왔다 갔다 하는 동안 하나의 roleplay result 정보를 스크린 상태로 보존. 나갈 때·새로 진입할 때 갱신.

### 이전 스크린 정보 (진입점)
- **ProfileScreen**: 롤플레이 히스토리 영역의 썸네일 탭 시 (resultId 전달)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **ReviewChatScreen** (Sub Screen): 롤플레이 채팅 내용 열람 진입 (추후 지침)
- **ReviewEndingScreen** (Sub Screen): 롤플레이 엔딩 내용 열람 진입 (추후 지침)
- **ProfileScreen**: X 버튼 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- **상태**: resultId로 `SudaApiClient.getRoleplayResult()` 조회 후 `RoleplayResultDto` 및 `getUserProfile()`(Lv·progress)를 스크린 상태로 보관. **롤플레이 진행용(RoleplayStateService)과 혼용하지 않음.**
- **레이아웃**: Result와 동일(박스 210 + 본문). 초기 애니메이션 없이 애니 완료 시점 형태로 노출(별·mainTitle·subTitle·likePoint·Mission·Words·Lv·Good Points·To Improve·Got it 버튼).
- **Got it 버튼**: 노출만, 동작 없음(추후 지침). Report 문구 없음.
- 우측 상단 X 버튼 필수.

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
- **HistoryScreen**: "View Chat" 버튼 탭 시 (RoleplayResultDto 전달)

### 이후 스크린 정보 (이동 가능한 다른 스크린)
- **HistoryScreen**: 좌상단 뒤로가기 또는 시스템 뒤로가기 시 `Navigator.pop()`으로 복귀

### 스크린 내부 구현 특이사항
- **헤더**: 중앙 "Chat History" (headlineMedium·흰색), Setting 계열 스타일. 좌상단 뒤로가기(header_arrow_back.svg).
- **배경색**: `#121212`. AppScaffold 사용, showBackButton: true.
- **본문**: RoleplayResultDto.chatHistory(List\<SudaJson\>)를 순서대로 표시. key로 발화자 구분: USER(사용자 말풍선·우측·흰색), AI_CHARACTER(AI 말풍선·좌측·#0CABA8·avatarImgPath 아바타 40×40), AI_NARRATOR(나레이션·중앙·이탤릭 흰색), SYSTEM_MISSION(미션·중앙·Mission 뱃지+핑크 텍스트). value를 그대로 문구로 표시. Playing 스크린과 동일 말풍선/나레이션/미션 배치·스타일.

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

## 스크린 네비게이션 흐름도

```
앱 실행
  ↓
[네이티브 스플래시] (어두운 단색 배경 #121212, 이미지 없음)
  ↓ (Flutter 엔진 초기화 + JWT 처리)
  ├─ 토큰 없음/유효하지 않음 → [CustomSplashScreen] → [LoginScreen]
  └─ 토큰 유효 → [HomeScreen] (또는 AgreementScreen)

[CustomSplashScreen] (앱 실행 후 로그인 플로우에서만 표시)
  └─ onComplete → [LoginScreen]

[LoginScreen]
  ├─ 로그인 성공 → [HomeScreen]
  └─ 로그인 취소/실패 → [LoginScreen] (유지)

[NotificationBoxScreen] ←→ [HomeScreen] ←→ [ProfileScreen] (GNB Alarm/Home/Profile 3탭 전환)
  ├─ [HomeScreen] → [RoleplayOverviewScreen] (중앙 "Roleplay" 텍스트)
  │   └─ [RoleplayOpeningScreen] (중앙 "Play" 텍스트)
  │       ├─ [RoleplaySurveyScreen] (sessionId == '-10' 팝업의 "Answer now ✅")
  │       └─ [RoleplayPlayingScreen] (중앙 "Start" 텍스트)
  │           ├─ [RoleplayEndingScreen] (중앙 "Ending" 텍스트)
  │           │   └─ [RoleplayResultScreen]
  │           │       └─ [RoleplayResultReportScreen] (Report 문구 탭 시, 백버튼/X → Result 복귀)
  │           └─ [RoleplayFailedScreen]
  │               └─ [RoleplayFailedReportScreen] (Report 텍스트 탭 시, 백버튼/X → Failed 복귀)
  └─ [ProfileScreen] → [SettingScreen] (우측 상단 원형 버튼)
  │       ├─ [AccountScreen]
  │       ├─ [LanguageLevelScreen]
  │       ├─ [FeedbackScreen]
  │       ├─ [WebViewScreen] (Privacy policy / Terms of Service)
  │       ├─ [OpenSourceLicenseScreen]
  │       └─ Log out → [LoginScreen] (커스텀 스플래시 없이 곧바로 이동)
  └─ [ProfileScreen] → [HistoryScreen] (롤플레이 히스토리 썸네일 탭)
          ├─ [ReviewChatScreen] (채팅 열람)
          └─ [ReviewEndingScreen] (엔딩 열람)
```

### 네비게이션 흐름 상세 설명

1. **앱 실행 → 네이티브 스플래시**
   - 네이티브 스플래시가 자동으로 표시됨 (어두운 단색 배경 #121212, 이미지 없음)
   - `FlutterNativeSplash.preserve()`로 Flutter 엔진 초기화 후에도 유지

2. **네이티브 스플래시 → CustomSplashScreen 또는 HomeScreen**
   - Flutter 엔진 초기화 완료 후 `_checkAuthStatus()` 실행
   - JWT 토큰 확인 및 서버 검증 (네이티브 스플래시 유지 중)
   - 처리 완료 후 `FlutterNativeSplash.remove()` 호출
   - 토큰 없음/유효하지 않음 → CustomSplashScreen 표시 → onComplete 후 LoginScreen
   - 토큰 유효 → HomeScreen(또는 AgreementScreen) 표시

3. **로그아웃 시**
   - `_onSignOut()`에서 `_showCustomSplash = false` 설정 → CustomSplashScreen 없이 곧바로 LoginScreen 표시

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
| `/profile` | ProfileScreen (Main, Profile 탭) | GNB Profile |
| `/roleplay/overview/{roleplayId}` | RoleplayOverviewScreen (Sub) | 예: `/roleplay/overview/12` |
| `/profile/history/{resultId}` | HistoryScreen (Sub) | 예: `/profile/history/456` |
| `/profile/setting` | SettingScreen (Sub) | Profile에서 진입 |

- **제외**: Login, Agreement(인증 플로우), RoleplayOpening(role 선택 필수), Playing/Ending/Result/Failed(세션·플로우 의존).

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
