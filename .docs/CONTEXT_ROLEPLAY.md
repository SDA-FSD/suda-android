# Roleplay 컨텍스트

## 1. 목적
- Roleplay 관련 스크린, 네비게이션 흐름, 데이터 정책을 정리한다.
- Roleplay 관련 구현 시 이 문서를 기준으로 변경 사항을 기록한다.

## 2. 스크린 목록 (파일/클래스)
- Overview (Sub Screen)
  - 파일: `lib/screens/roleplay/overview.dart`
  - 클래스: `RoleplayOverviewScreen`
- Opening (Full Screen)
  - 파일: `lib/screens/roleplay/opening.dart`
  - 클래스: `RoleplayOpeningScreen`
- Playing (Full Screen)
  - 파일: `lib/screens/roleplay/playing.dart`
  - 클래스: `RoleplayPlayingScreen`
- Ending (Full Screen)
  - 파일: `lib/screens/roleplay/ending.dart`
  - 클래스: `RoleplayEndingScreen`
- Failed (Full Screen)
  - 파일: `lib/screens/roleplay/failed.dart`
  - 클래스: `RoleplayFailedScreen`
- Result (Full Screen)
  - 파일: `lib/screens/roleplay/result.dart`
  - 클래스: `RoleplayResultScreen`

## 3. 기본 네비게이션 흐름 (현행 코드 기준)
- Home -> Overview -> Opening -> Playing -> Ending/Failed -> Result -> Overview
- Playing/Ending/Failed에서 뒤로가기는 확인 다이얼로그 후 Overview로 복귀

## 4. 라우팅 중앙화 규칙
- Roleplay 화면 전환 규칙은 `lib/routes/roleplay_router.dart`에서 관리한다.
- Overview 진입은 Sub Screen 정책에 맞춰 `SubScreenRoute`를 사용한다.
- Opening/Playing/Ending/Failed/Result 전환은 기존과 동일하게 `MaterialPageRoute` 기반이다.

## 5. Roleplay 데이터 정책 (요구 사항)
- Home에서 특정 Roleplay 클릭 시 Overview로 이동하며 `roleplayId`를 확보해야 한다.
- Overview 진입 시 `roleplayId`로 서버 호출하여 상세 데이터를 가져온다.
- 앱 이용 중 **단 하나의 Roleplay 정보만 유지**해야 한다.
- Overview에서 획득한 Roleplay 정보는 이후 Roleplay 관련 스크린에서 **항상 접근 가능**해야 한다.

## 6. Roleplay 상세 조회 API
- 홈 화면 카테고리별 롤플레이 목록 전체 조회: `GET /v1/home/roleplays/all`
  - 응답: `List<AppHomeRoleplayGroupDto>` (roleplayCategoryDto, list)
- 카테고리별 롤플레이 목록 페이징 조회: `GET /v1/home/roleplays`
  - 파라미터: `roleplayCategoryId`, `pageNum`
  - 응답: `SudaAppPage<AppHomeRoleplayDto>` (content, number, size, last, first)
- 엔드포인트: `GET /v1/roleplays/{roleplayId}/overview`
- 인증: Authorization Bearer JWT 필요
- 응답: `RoleplayOverviewDto`
  - `roleplay`: `RoleplayDto`
  - `availableRoleIds`: `List<Long>`
  - `starResultMap`: `Map<Long, Integer>`
  - `similarRoleplayList`: `List<RoleplayDto>`
- `RoleplayDto.duration`은 서버에서 Java `LocalTime` 형식으로 응답됨 (문자열로 처리)
- Long 타입 외 모든 필드는 nullable로 취급

## 7. 단일 Roleplay 컨텍스트 보관
- 인메모리 서비스로 단일 Roleplay Overview를 보관한다.
- 서비스 파일: `lib/services/roleplay_state_service.dart`
- 흐름/수명은 향후 지침에 따라 보완 예정

## 8. Overview UI 구성 (요약)
- 상단 배경 이미지: `RoleplayDto.overviewImgPath`를 너비 100%로 고정 배치
- 스크롤 콘텐츠가 배경 위를 덮는 구조로 구성
- 역할 선택 버튼: 활성/비활성 스타일 분기 및 잠김 토스트 안내
- 역할 선택 버튼 우측 별 표시 규칙:
  - 별은 항상 3개를 표시
  - 별 기록이 있으면 왼쪽부터 켜짐 처리, 없으면 모두 꺼짐 표시
- 별 아이콘은 PNG로 관리 (광택 효과 유지 목적)
- 별 아이콘 크기: 16x16, 별 사이 간격 2
- 역할 선택 버튼 세로 패딩: 18, 좌우 패딩: 30
- 비활성 안내 토스트는 공통 토스트 헬퍼(`lib/utils/app_toast.dart`) 사용
- 유사 롤플레이 그리드(3열) 표시 및 제목 오버레이 텍스트 포함

## 9. 공통 레이아웃 (RoleplayScaffold)
- **목적**: 롤플레이 단계별 스크린(Opening, Playing, Ending, Failed, Result)의 일관된 UI 구조 제공.
- **파일**: `lib/widgets/roleplay_scaffold.dart`
- **주요 특징**:
  - **전용 헤더**: 일반적인 화살표 뒤로가기 대신 닫기(X) 아이콘(`close.svg`, 24x24)을 좌상단(16, 16)에 고정 배치.
  - **스크롤 본문**: 중앙 영역은 `Expanded`와 `SingleChildScrollView`를 사용하여 헤더와 푸터 사이에서 독립적으로 스크롤됨.
  - **본문 중앙 정렬**: 내용이 적을 경우 세로 중앙에 배치되도록 `LayoutBuilder`와 `ConstrainedBox`를 이용한 최소 높이 강제 방식이 적용되어 있음. 내용이 길어질 경우 자동으로 상단부터 스크롤됨.
  - **가변 고정 푸터**: 하단에 버튼 등 액션 영역을 배치하며, 콘텐츠 양에 따라 높이가 자동 조절되면서 항상 화면 하단에 고정됨.
  - **유연성**: `showCloseButton` 옵션을 통해 X 아이콘 노출 여부를 제어할 수 있음.

## 10. 최근 Roleplay 작업 메모
- **홈 화면 카테고리별 롤플레이 목록 추가**:
  - `marquee` 패키지 도입으로 흐르는 타이틀 텍스트 구현
  - `GET /v1/home/roleplays/all` 및 `GET /v1/home/roleplays` API 연동
  - 카테고리별 가로 스크롤 리스트 및 레이지 로딩(Lazy Loading) 페이징 구현
  - 30% 너비 썸네일, radius 10, 음영 박스 오버레이 타이틀 적용
  - 카테고리명(100px) 및 썸네일 리스트에 Shimmer 로딩 스켈레톤 적용
