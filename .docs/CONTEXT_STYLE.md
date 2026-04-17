# Suda Application 스타일 / 디자인 가이드

이 문서는 **텍스트 스타일, 폰트, 기본 배치 규칙**에 대한 사실 기준입니다.  
화면을 새로 만들거나 UI를 수정할 때 이 문서를 우선 참조합니다.

---

## 1. 폰트 정의

- **기본 폰트 (default font)**
  - 파일(등록 기준): `assets/fonts/ChironHeiHK-subset-w400.ttf` / `-w600.ttf` / `-w700.ttf`
  - 원본(작업/교체용): `assets/fonts/ChironHeiHK-subset.woff2`
  - `pubspec.yaml` 상의 패밀리명: `ChironHeiHK`
  - 용도: 앱 내 대부분 텍스트 (heading, body, caption)

- **버튼 폰트 (button font)**
  - 파일(등록 기준): `assets/fonts/ChironGoRoundTC-subset-w400.ttf` / `-w600.ttf` / `-w700.ttf`
  - 원본(작업/교체용): `assets/fonts/ChironGoRoundTC-subset.woff2`
  - `pubspec.yaml` 상의 패밀리명: `ChironGoRoundTC`
  - 용도: 버튼 계열 위젯(TextButton, ElevatedButton 등)의 텍스트

- **가변폰트(weight) 적용 규칙**
  - 두 폰트 모두 `fvar`의 `wght` 축(200~900)을 가진 **가변폰트**이므로, `fontWeight`만으로는 체감 굵기가 부족할 수 있다.
  - 전역 `TextTheme`/버튼 `textStyle`에서는 `fontWeight`와 함께 `fontVariations: [FontVariation('wght', <동일값>)]`를 명시한다. (구현: `lib/theme/app_theme.dart`)

폰트 로딩은 `pubspec.yaml`의 `flutter/fonts` 섹션과  
`lib/theme/app_theme.dart`의 `ThemeData`에서 설정합니다.

---

## 2. 텍스트 스타일 체계 (CSS h1/h2/body 대응)

Flutter의 `TextTheme`와 매핑하여 전역으로 사용합니다.  
구체적인 설정은 `lib/theme/app_theme.dart`의 `ThemeData.textTheme`를 참조하세요.

### 2.1 Heading 계열

- **heading1**
  - 매핑: `textTheme.headlineLarge`
  - 폰트: 기본 폰트 (`ChironHeiHK`)
  - 크기 / 굵기: `fontSize: 32`, `fontWeight: w700`
  - 용도: 최상위 타이틀, 메인 스크린의 대표 제목

- **heading2**
  - 매핑: `textTheme.headlineMedium`
  - 폰트: 기본 폰트
  - 크기 / 굵기: `fontSize: 24`, `fontWeight: w600`
  - 용도: 섹션 타이틀, 두 번째 레벨 제목

- **heading3**
  - 매핑: `textTheme.headlineSmall`
  - 폰트: 기본 폰트
  - 크기 / 굵기: `fontSize: 20`, `fontWeight: w700`
  - 용도: 카드/모듈 내 소제목, 다이얼로그 타이틀 등

### 2.2 Body 계열

- **body-default**
  - 매핑: `textTheme.bodyLarge`
  - 폰트: 기본 폰트
  - 크기 / 굵기: `fontSize: 18`, `fontWeight: w400`
  - 용도: 기본 본문 텍스트 (설명, 문단 등)

- **body-secondary**
  - 매핑: `textTheme.bodyMedium`
  - 폰트: 기본 폰트
  - 크기 / 굵기: `fontSize: 16`, `fontWeight: w400`
  - 용도: 보조 설명, 서브 정보, 리스트 아이템 텍스트 등

- **body-caption**
  - 매핑: `textTheme.bodySmall`
  - 폰트: 기본 폰트
  - 크기 / 굵기: `fontSize: 14`, `fontWeight: w400`
  - 용도: 캡션, 라벨, 부가 정보(날짜, 태그 등)

- **body-tiny**
  - 매핑: `textTheme.labelSmall`
  - 폰트: 기본 폰트
  - 크기 / 굵기: `fontSize: 12`, `fontWeight: w600`
  - 용도: 매우 작은 라벨/배지/보조 설명(공간이 극도로 제한된 경우)

### 2.3 사용 예시 (위젯 코드 관점)

Material 표준 `TextTheme` 이름을 그대로 사용합니다.

```dart
final theme = Theme.of(context).textTheme;

Text('타이틀', style: theme.headlineLarge);    // heading1
Text('섹션 제목', style: theme.headlineMedium); // heading2
Text('소제목', style: theme.headlineSmall);    // heading3

Text('본문', style: theme.bodyLarge);         // body-default
Text('보조 본문', style: theme.bodyMedium);     // body-secondary
Text('캡션', style: theme.bodySmall);         // body-caption
Text('아주 작은 라벨', style: theme.labelSmall); // body-tiny
```

---

## 3. 버튼 텍스트 스타일

- 전역 설정 위치: `lib/main.dart`의
  - `elevatedButtonTheme` (w600, 18px)
  - `outlinedButtonTheme` (w400)
  - `textButtonTheme` (w400)
- 공통 규칙:
  - 폰트 패밀리: `ChironGoRoundTC`
  - 굵기: 각 테마 설정 참조
  - 크기: 기본적으로 Theme 값을 사용하며, 특수 케이스만 override

버튼을 새로 만들 때는 **가능한 한 직접 `TextStyle`을 박지 말고**,  
`TextButton`, `ElevatedButton` 등의 Theme 설정을 우선 사용합니다.

---

## 4. 배치 / 레이아웃 기본 규칙

### 4.1 기본 마진 및 여백 (Screen Layout)
- **기본 좌우 여백**: `24` (콘텐츠 영역 기준)
- **본문 영역 상단 여백**: `70` (상단 헤더 아이콘 및 제목과의 간격을 고려한 시작점)
- **하단 여백**: 별도 고정값 없음 (콘텐츠 길이에 따라 유동적)
- **GNB 하단 여백**: `SafeArea(bottom: true, top: false)`로 처리하며  
  `MediaQuery.padding.bottom`과 중복 적용하지 않음
- **헤더 구성 규칙**:
  - **좌측 상단 아이콘**: 뒤로가기(`assets/images/header_arrow_back.svg`) 아이콘 배치. `Positioned(top: 16, left: 16)`
  - **중앙 제목**: 페이지 제목 표시 시 `h2` 스타일 사용 및 중앙 정렬.
  - **아이콘 표준 크기**: 모든 헤더 아이콘은 **24x24** 크기를 표준으로 사용함

### 4.2 공통 요소 규칙
- **베이스 스크린 위젯 (`AppScaffold`)**
  - 새로운 스크린 생성 시, 반드시 `lib/widgets/app_scaffold.dart`의 `AppScaffold` 사용 여부를 먼저 검토합니다.
  - `AppScaffold`는 표준 마진(좌우 24, 상단 80)과 헤더 위치(16)를 자동으로 적용합니다.
  - 특수한 레이아웃(로그인, 웹뷰 등)이 아닌 경우 `AppScaffold` 사용을 원칙으로 합니다.

- **기본 배경색**
  - 앱 전역 배경: `#121212` (`Color(0xFF121212)`)
  - Sub Screen: 기본 배경색과 동일 (`Color(0xFF121212)`)

- **텍스트 정렬**
  - 기본: 좌측 정렬
  - 중앙 정렬은 Hero 영역, Demo 화면(예: OpenSourceLicenseScreen) 등 특수한 경우에만 사용

- **색상**
  - 타이포 그래피 규칙은 이 문서에서 관리
  - 색상 팔레트/상세 컬러 규칙이 추가될 경우 이 문서에 섹션을 확장해서 기록

### 4.3 DefaultPopup (공통 팝업 프레임)

- **구현 파일**: `lib/widgets/default_popup.dart`
- **타이틀 타이포**: `textTheme.headlineMedium` + 흰색 (`heading2` 계열)
- **본문 슬롯(`bodyWidget`)**: 내부 타이포/정렬/추가 위젯 구성은 호출부 책임(자유도 높음)
- **슬롯 간격 규칙**: `DefaultPopup`은 **topWidget ↔ title ↔ body ↔ buttons** 사이에만 세로 `20`을 보장한다(`bodyWidget` 내부 간격은 강제하지 않음)
- **본문 영역 패딩**: 상 `20`, 좌·우·하 `16`
- **스크롤/최대 높이**: 카드 높이는 내용에 따라 결정되되, **최대 높이는 화면 높이의 `80%`로 캡**되며 초과 시 **`topWidget + title + body + buttons` 영역만 스크롤**(좌상단 닫기 아이콘은 고정)

---

## 5. 유지보수 규칙

- 새로운 텍스트 스타일을 추가할 때:
  1. `lib/theme/app_theme.dart`의 `ThemeData.textTheme`에 먼저 정의
  2. 이 문서(`CONTEXT_STYLE.md`)에 **이름, 용도, 매핑, 예시**를 함께 추가
- 기존 스타일 변경 시:
  - 실제 코드 변경과 이 문서의 정의를 항상 함께 업데이트
- 스크린 레벨의 레이아웃/배치 특이사항:
  - 구체적인 스크린별 내용은 `.docs/CONTEXT_SCREEN.md`에 기록  
  - 공통 스타일/규칙은 이 문서에 기록

