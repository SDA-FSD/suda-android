# Roleplay S2 (Season 2) 컨텍스트

> **용도**: S1 → S2 마이그레이션 **진행상황**과 S2 전용 정책을 정리한다.  
> **S1 사실 기준**은 `.docs/CONTEXT_ROLEPLAY.md`를 따른다. S2 작업 시 **이 문서를 먼저** 읽는다.

---

## 1. S1 / S2 한 줄 요약

| | S1 (fade-out) | S2 (신규) |
|---|---------------|-----------|
| 홈 노출 단위 | 단일 roleplay (v1, 제거 중) | **시리즈** → 에피소드 |
| Overview | `RoleplayOverviewScreen` | `SeriesOverviewScreen` |
| 플레이 state | `RoleplayStateService` | **`SeriesStateService`** |
| Opening 데이터 | `RoleplayOverviewDto` / role 선택 | **`RpS2SeriesEpisodeDto`** + `userCharacter` |
| 세션 생성 | `POST /v1/roleplay-sessions` `{roleplayId, roleId}` | **`POST /rps2/sessions` `{seriesId, episodeId}`** |
| Playing 구현 | `playing_backup.dart` (보존) | **`playing.dart` (신규, 진행 중)** |

---

## 2. S2 네비게이션 흐름 (현행 코드)

```
Home (시리즈 썸네일)
  → SeriesOverviewScreen          [Sub, GET /rps2/series/{id}/overview]
  → (에피소드 Play)
  → RoleplayTutorialScreen        [Tutorial 미완료 시만 노출]
  → RoleplayOpeningScreen         [Full]
  → RoleplayPlayingScreen         [Full, S2 재구현 중]
  → (Ending / Failed / Result …)  [아직 S1 스크린·S1 state — 미마이그레이션]
```

- **S1 경로 단절**: `RoleplayOverviewScreen` 역할 Play → Opening/Tutorial **연결 끊김** (fade-out). Overview 스크린·`RoleplayStateService` overview 정리는 **스크린 삭제 단계**에서 처리 예정.
- **복귀**: Playing/이후 스크린에서 나가기 확정 시 `RoleplayRouter.popToOverview()` → **`/series/overview`**까지 pop (S1 `/roleplay/overview` 아님).

---

## 3. SeriesStateService (S2 플레이 컨텍스트)

**파일**: `lib/services/series_state_service.dart`  
**싱글톤**: `SeriesStateService.instance`

| 필드 | 타입 | 설정 시점 | 용도 |
|------|------|-----------|------|
| `seriesId` | `int?` | Series Overview 로드 | 세션 API `seriesId` |
| `overview` | `RpS2SeriesOverviewDto?` | Series Overview 로드 | 시리즈 메타·`userCharacter`·`episodes`·`bestScoreMap` |
| `selectedEpisodeId` | `int?` | 에피소드 Play 탭 | 현재 플레이 대상 에피소드 id |
| `user` | `UserDto?` | Overview / Episode Play / Tutorial | 사용자·metaInfo (속도 등) |
| `session` | `RpS2SessionDto?` | Opening Start 성공 | `sessionId`, 초기 `aiSound` |

**편의 getter**: `selectedEpisode`, `sessionId`

**refresh / clear 규칙**
- **다른 `seriesId`로 Series Overview 진입** → `setSeriesOverview` 시 `selectedEpisodeId`·`session` 초기화.
- **다른 에피소드 Play** → `setSelectedEpisodeId` 시 `session` 초기화.
- `clear()` → 전 필드 null.

**RoleplayStateService와의 관계**
- S2 Opening/Playing/Tutorial은 **`SeriesStateService` 우선**.
- `RoleplayStateService`는 S1 `playing_backup.dart`, Ending/Result/Failed 등 **아직 S1에 묶인 스크린**에서 계속 사용 중. Playing 이후 S2 전환 시 점진 제거 예정.

---

## 3-1. S2 Playing 턴 엔진 (목표 구조) — **agent 필독**

S1 턴 정책은 `.docs/CONTEXT_ROLEPLAY.md`만 본다. **S2는 아래가 단일 기준**이다.

### S1과 결정적 차이 (비교만, S1 구현 참조 금지)

| | S1 | S2 |
|---|----|----|
| 시작 주체 | `isUserTurnYn`에 따라 AI 또는 사용자 | **항상 AI** (`isUserTurnYn` **없음**) |
| AI 시작 분기 | `_handleInitialTurn`에서 사용자 시작 가능 | **분기 없음** — Opening 세션의 `aiSound` + episode `startLine`만 |
| 초기 입력 | AI 시작이면 나레이션 후 `activateUserTurn` | **단계별 지침**에 따름 (아래 표) |

### 턴 사이클 (고정 순서)

```
[Opening] POST /rps2/sessions → sessionId + aiSound 저장
    ↓
① AI 시작 (첫 턴만 자동) — 말풍선·음성·번역 아이콘
    ↓
② (조건부) 힌트 자동 노출 — `_autoHintEnabled` ON이면 힌트 로드 후 사용자 턴, OFF이면 힌트 아이콘 활성+사용자 턴
    ↓
③ 사용자 발화 — 녹음/타이핑 API
    ↓
④ 서버 응답 처리 — 사용자 말풍선 + 턴바 등급 효과 + 미션 완료 효과 + 나레이션 + 후속 AI 말풍선·음성
    ↓
⑤ ③~④ 반복 — `requiredSpeechCount`회 사용자 발화 완료 시 분석중 blink(결과 호출·이동은 추후)
```

### 단계별 구현 현황 (코드 기준)

| 단계 | 내용 | 데이터/API | 코드 상태 |
|------|------|------------|-----------|
| **Opening** | 세션 생성 | `POST /rps2/sessions` → `RpS2SessionDto` | ✅ `opening.dart` |
| **① AI 시작** | 진입 직후 첫 AI 말풍선·TTS·번역 아이콘 | 텍스트: `cefrMap[ENGLISH_LEVEL].startLine` · 음성: `session.aiSound` · 아바타: `aiCharacter.rpImgPath` · 번역: `GET /rps2/sessions/{id}/translation?rpMsgId=` | ✅ `playing_conversation_mixin.dart` **`startAiOpeningFlow`만** |
| **② 힌트 자동** | AI 발화 후 조건부 | `_autoHintEnabled` + `GET /rps2/sessions/{id}/hint/{rpMsgId}` (`rpMsgId` = 마지막 AI `conversationIndex`) | ✅ `playing_hint_mixin.dart` — 오토힌트 ON 자동 노출 후 사용자 턴·OFF 아이콘 탭+사용자 턴·AI 음성 종료 트리거·3s blink. 힌트 텍스트 조회만 202 not-ready 시 S1 delay 패턴으로 최대 15회 재시도 |
| **③ 사용자 발화** | 마이크/타이핑 전송 | `POST /rps2/sessions/{id}/user-message/audio`, `POST /rps2/sessions/{id}/user-message/text` | ✅ `playing_input_mixin.dart` |
| **④ 나레이션+후속 AI+턴바** | 사용자 1회 발화 후 서버 처리 | `RpS2UserMessageResponseDto(userText,userGrade,narration,aiText,missionCompletedIndex,serviceMessage?)` + `GET /rps2/sessions/{id}/ai-message/audio` | ✅ 사용자 말풍선·턴바 등급 효과·미션 완료 효과·나레이션·후속 AI 말풍선/음성 |
| **⑤ 반복·종료** | 턴 소진·Ending | `requiredSpeechCount` | 🚧 마지막 턴도 나레이션·후속 AI 말풍선/음성 노출 후 `serviceMessage`(없으면 `roleplayAnalyzing`) blink. result 호출·이동은 추후 |

### 입력(마이크·타이핑) 활성 규칙

- `activateUserTurn()` / `deactivateUserTurn()` (`playing_input_mixin.dart`)로만 제어.
- **현재**: Playing 진입 시 `deactivateUserTurn()` → AI 음성 종료 후 오토힌트 ON이면 `showPlayingHint()` 완료 뒤 `activateUserTurn(enableHintButton:false)`, OFF이면 `onHintAvailableAfterAi()` 직후 `activateUserTurn()`.
- 사용자 발화 준비 시점에만 `activateUserTurn()` 호출. 발화 전송 시작 시 사용자 턴·힌트 비활성, 응답 실패 시 사용자 턴 복구. 녹음 시작 중 release/cancel이 들어오는 경우 시작 완료 후 pending finish/cancel을 처리해 요청 누락을 방지한다.
- **② 힌트**: AI 음성 종료 후 트리거. 오토힌트 ON → 자동 노출 후 사용자 턴, 이 턴의 힌트 버튼은 disabled 유지. OFF → 아이콘 enabled·3s blink·탭 시 노출. 발화 완료(녹음 종료·텍스트 전송) 시 힌트 제거(녹음 시작 시 유지).

### agent 주의 (범위 침범 방지)

- S2 Playing의 구현 기준은 본 문서의 ③~⑤ 루프를 따른다. S1 `playing_backup.dart`는 UI/UX 참조용이며 `/v1/roleplay-sessions` API를 S2 경로에 재사용하지 않는다.

---

## 4. 스크린별 마이그레이션 상태

### 4-1. SeriesOverviewScreen ✅ (S2 본流)

- **파일**: `lib/screens/series/overview.dart`
- **API**: `GET /rps2/series/{seriesId}/overview`, `GET /rps2/series/{seriesId}/best-score`
- **로드 시**: `SeriesStateService.setSeriesOverview`, **`FIRST_OVERVIEW`** 통계 (`POST /v1/users/first-overview`, metaInfo `FIRST_OVERVIEW=Y` 가드)
- **에피소드 Play**: `setSelectedEpisodeId(episode.id)` → `RoleplayRouter.pushTutorial` (S1 `getRoleplayOverview` **호출 안 함**)

### 4-2. RoleplayTutorialScreen ✅ (S2 경로 연동)

- **파일**: `lib/screens/roleplay/tutorial.dart`
- **user** 조회·갱신: `SeriesStateService` (+ Tutorial 완료 시 `RoleplayStateService.setUser` 동기화 — Playing S1 잔재 대비)
- 완료/스킵 → `replaceWithOpeningFromTutorial`

### 4-3. RoleplayOpeningScreen ✅ (S2 UI·세션)

- **파일**: `lib/screens/roleplay/opening.dart`
- **데이터**: `SeriesStateService.selectedEpisode`, `overview.userCharacter`
- **렌더**
  - 배경: episode `thumbnailImgPath` → `RoleplayOverviewBackdrop`
  - 헤더 타이틀: episode `title` (`SudaJsonUtil.localizedMapText`) — X·kebab 밴드(top 16·height 40) 세로 중앙
  - **duration 없음** (S2)
  - Your Role: `userCharacter.name`
  - Briefing: episode `briefing` (`DefaultMarkdown`)
- **Start (`Let's Start`)**
  1. 마이크 권한
  2. `POST /rps2/sessions` `{seriesId, episodeId}`
  3. `sessionId` 분기 (S1과 **동일 의미**): `-99` 데일리 티켓, `0` 티켓 없음, `-10` 설문, `-20` 푸시, `-30` 공유, `-40` 리뷰 → 각 DefaultPopup / Survey
  4. 정상 sessionId → 티켓 consume 이펙트 → `SeriesStateService.setSession(session)` → `replaceWithPlaying`

### 4-4. RoleplayPlayingScreen 🚧 (S2 재구현 중 — **핵심**)

#### 파일 구조

| 파일 | 역할 |
|------|------|
| `lib/screens/roleplay/playing.dart` | **S2 신규** — 라우터가 이 파일을 사용 |
| `lib/screens/roleplay/playing_backup.dart` | **S1 전체 보존** — 기능 이식·참조용 (수정하지 않음) |

#### ✅ 이미 구현됨 (`playing.dart`)

- `RoleplayScaffold` + episode `thumbnailImgPath` 배경
- **헤더**
  - 좌상 **X** → 나가기 확인 레이어 (S1 `playing_backup._buildExitLayer`와 동일 UX·l10n)
  - 중앙 **타이틀**: episode `title` (사용자 언어, fallback en) · `bodySmall` **w700** · **1줄** 말줄임
  - **duration 없음**
  - 우상 **`kebab.png`** (40×40 탭 영역) — 탭 시 **설정패널(configuration panel)** 토글
- **턴바영역 (turn bar area)** — `RoleplayScaffold.belowHeader` + `lib/widgets/roleplay_turn_bar_area.dart`
  - **위치**: 헤더 타이틀 영역(`effectiveHeaderTopSpacing` **60**, `headerTopSpacingDelta -10`) **바로 아래**, 간격 0
  - **크기**: height **20**, 좌우 **마진 24** (`RoleplayTurnBarArea.horizontalMargin`) — 턴박스 Row는 마진 안쪽에서 전폭 채움
  - **턴박스 개수**: `selectedEpisode.cefrMap[EnglishLevelUtil.readLevelFromUser(user)].requiredSpeechCount` (`RpS2CefrDto`). `null` 또는 `<1`이면 영역 **미노출**
  - **가로 배치**: `requiredSpeechCount`개 `Expanded` 턴박스 + 턴박스 사이 **gap 6**만 → 개수가 적을수록 턴박스 하나의 width가 커짐
  - **턴박스 내부**(세로, height 20 안):
    - **하단**: turn bar — height **4**, **좌우 둥근 캡슐**(borderRadius = height/2 = **2**) — 턴 상태 색
    - **상단 나머지**: turn bar 색 변경 시 그 바 **바로 위**에 노출할 라벨 텍스트 예비 영역 (`labelTexts`, 초기 `null`)
  - **초기 turn bar 색**: 전 턴 `#635F5F` **40%** (`Color(0x66635F5F)`, `RoleplayTurnBarArea.defaultBarColor`)
  - **상태 보관** (`playing.dart`): `_turnBarColors`, `_turnLabelTexts`, `_turnLabelColors` (길이 = `_turnCount`)
  - **진행 정책**: 사용자 발화 **1회 완료**마다 해당 턴 turn bar 색 1개 갱신 → `requiredSpeechCount`회 발화 완료(마지막 턴) 시에도 나레이션·후속 AI 말풍선/음성을 노출한 뒤 서버 `serviceMessage`(없으면 `roleplayAnalyzing`) blink(결과 호출·이동은 추후).
  - **등급 효과**: A `#0CABA8` 라벨 en `wow!`/pt `bah!`, B `#62FF00` `ok!`, C `#FFB700` en `hmm…`/pt `nhé…`, D `#FF0000` en `oh…`/pt `oxi?`. bar 색·라벨 즉시 100% pop(1.0→1.42→1.0, 320ms). **2초 후** 라벨 150ms fade-out + bar 등급색 **20%**(`pastTurnBarOpacity`)로 dim(다음 사용자 턴 시작과 무관).
- **시스템 뒤로가기**: `PopScope` → X와 동일하게 확인 레이어
- **나가기 확정**: `RoleplayRouter.popToOverview` → Series Overview
- **설정패널 (configuration panel)** — `lib/widgets/roleplay_configuration_panel.dart`
  - **노출**: 케밥 탭 토글 · `top = safeArea + 56` · `right = 24` · 미션패널 포함 최상단
  - **닫기**: 케밥 재탭 · 패널 외부 탭 (`Listener` dismiss)
  - **프레임**: Series Overview 언어레벨 버튼과 동일 글래스(BackdropFilter σ12 + gradient border, radius 16)
  - **오토힌트**: l10n `roleplayAutoHint` · push agreement 동일 토글 · Pre-A1/A1/A2 기본 on, B1 이상 off · `_autoHintEnabled` (Playing 생명주기)
  - **속도**: l10n `roleplayVoiceSpeed` · 가로 레일 200×4 · thumb 9 흰 원 · 좌측~thumb `#80D7CF` · 0.7/1.0/1.2/1.5 · 탭 시 1단 이동 + `PUT` speed-rate (S1 `RP_SPEED_RATE` 70/100/120/150)
  - **구분선**: `SizedBox` 200×1 직접 그림, `#FFFFFF` 40% (`panelLineColor`), 상·하 여백 **16**
  - **슬라이더**: 레일 기본색 `panelLineColor` · 터치 영역 = 레일+라벨 전체 · 탭 1단 이동 · 드래그 후 가장 가까운 4단계 스냅

#### 레이아웃 구역 (턴바영역 아래 — S1 `RoleplayScaffold` body/footer 분할과 동일)

| 구역 | 슬롯 | 스펙 | 현재 상태 |
|------|------|------|-----------|
| **본문** | `RoleplayScaffold.body` | 상단 gap **8** → `Expanded`(Stack) → 하단 gap **8**, 좌우 마진 **24**(스캐폴드) | **미션 패널 오버레이** + AI/User/나레이션/힌트 대화 스크롤 |

**미션 패널 (mission panel)** — `lib/widgets/roleplay_mission_panel.dart`, 본문 `Stack` 상단 고정 오버레이

- **데이터**: `selectedEpisode.cefrMap[ENGLISH_LEVEL].missions` (`List<RpS2CefrMissionDto>`, 보통 3개). `instruction`은 `SudaJsonUtil.localizedMapText`
- **위치**: 본문 `Stack` 상단에서 **top 2** (`PlayingConversationLayout.missionPanelTop`, gap 8 아래 추가 여백)
- **레이아웃(접힘)**: 전폭(본문 inset 24 안) · height **54** · **글래스 프레임**(설정패널과 동일: `BackdropFilter` blur 12 · white gradient border α0.36 · gradient α0.22→0.14 · shadow blur 10) · borderRadius **27**(알약형, height/2)
  - 좌 **15**: `rps2_mission_off.png`/완료 시 `rps2_mission_on.png` 24×24 세로 중앙
  - 우 **20**: `{activeMissionIndex + 1}/{total}` `labelSmall` 흰색(달성 수가 아니라 현재 노출 미션 순서 기준)
  - 중앙: 텍스트 컬럼 width = (패널 − 좌·우 슬롯) × **90%**, 나머지 10%는 좌·우 **균등 여백**(아이콘↔텍스트 간격 확보). 접힘/펼침 동일 · `instruction` `bodyMedium` 흰색·**좌측 정렬** (`_activeMissionIndex`, 초기 0). 펼침 시 우 슬롯은 빈 공간으로 동일 width 유지
- **탭 → 펼침**: **아래로만** `AnimatedSize`+`AnimatedSwitcher`(300ms, `easeInOutCubic`, fade+`SizeTransition`). 모서리 radius **27** 유지. 전체 미션 `instruction`+좌측 아이콘 세로 나열 · `0/3` **hide**. 재탭 → 접힘
- **오버레이**: `buildPlayingBody`의 `SingleChildScrollView` 위에 `Positioned` — 메시지 append 시 위로 스크롤되며 패널에 가려짐. 스크롤과 미션 패널 **사이**에 상단 페이드 레이어: SafeArea 상단~미션 패널 하단, `#121212` 100%→0% 세로 gradient(헤더·턴바·미션 패널은 페이드 위에 노출, 말풍선만 페이드에 가려짐). **하단 페이드**: 디스플레이 하단~서비스메시지 상단, `#121212` 100%→0%(본문 48px 침범 + 푸터 하단·safe·scaffold gap 24). 상·하단 페이드는 `scaffoldBodyHorizontalInset`(24) 상쇄로 **디스플레이 좌우 전폭**. `playing.dart` 최외곽 Stack에 상태표시줄·하단 시스템 영역 `#121212` 솔리드 보강(기존 페이드와 이어짐). 푸터 UI(서비스메시지·입력·아이콘)는 페인트 순서상 페이드 위에 노출, 배경·말풍선만 가림.
- **스크롤 정책**: 본문 `SingleChildScrollView`는 `ScrollController`를 사용한다. AI/User/Narration entry 또는 힌트 bubble이 새로 추가될 때만 최하단으로 250ms 애니메이션 이동한다. 사용자가 상하 드래그로 과거 메시지를 보는 중에는 새 요소 추가가 없는 한 강제로 하단 고정하지 않는다.
- AI 말풍선 (`playing_conversation_mixin` `_buildAiMessage`): 배경 `#353535`·padding **10**·radius 12. 본문 `bodyMedium` 흰색. 번역 `labelSmall` `#777373`. 아바타 40×40은 말풍선 컨테이너 **상단** 정렬(`CrossAxisAlignment.start`).
- 사용자 말풍선 (`_buildUserMessage`): 우측 정렬·max 너비 `bodyWidth×0.7`. 배경 흰색 **30%**·padding 좌우 12 상하 10·radius 12. 본문 `bodyMedium` 흰색.
- 녹음 중 말풍선 (`_buildRecordingBubble`): S1과 동일 — 녹음 시작 시 entry append·150ms fade-in·우측 말풍선·3점 wave(900ms sin, opacity 0.3~1.0). 배경·점 색은 사용자 말풍선과 동일(흰 30%·흰 점). 녹음 종료/취소 시 제거 후 STT 결과 말풍선 노출.
- **첫 AI 말풍선 Y**: 본문 스크롤 영역 상단에 **고정 `SizedBox(height: 68)`** (`PlayingConversationLayout.firstBubbleTopOffset`) — 패널에 가리지 않음. 추가 말풍선은 아래로 쌓이며 스크롤 시 패널 뒤로 이동
- **AI 아바타**: `selectedEpisode.aiCharacter.rpImgPath` — Opening `initState`·Playing 전환 직전 `precacheImage`
- **미션 완료 효과**: `missionCompletedIndex` 수신 시 **`MissionCompleteEffect`**(`EffectOverlayService` root overlay)로 `mission_complete_effect.png`를 **디스플레이 width × 2/3** 크기(에셋 전체 기준)로 재생 — **미션 패널 active row 좌측 on/off 아이콘 중심**과 이미지 중심(핑크 원) 정렬, 좌·상단은 화면 밖으로 클리핑 가능(`Stack clipBehavior: none`). 중앙 원은 에셋 폭의 ~19%라 실제 눈에 띄는 크기는 화면의 ~12% 수준. 500ms fade-in → 1000ms fade-out(1.5s, 미세 회전). shine 시작과 동시에 `VibrationPreset.quickSuccessAlert` 축하 진동. 아이콘 즉시 `rps2_mission_on.png` 전환. 패널 배경은 동시에 `#9E0067` **1.5초** 노출 후 300ms 전환으로 글래스 프레임 복귀·**이 시점에** `activeMissionIndex`를 다음 미완료 미션으로 전환. **전 미션 달성 시** 글래스 복귀와 동시에 패널 전체 300ms fade-out.
| **푸터** | `RoleplayScaffold.footer` | `SafeArea(top:false)` + 3층 (S1 §6-7) | **입력·아이콘 이식 완료**, 서비스메시지 **영역만** |

**사용자 발화 후 응답 타이밍**

- `conversationIndex`는 **1부터 시작**하며 AI/User/Narration entry를 포함한 전체 대화 순번이다. **recording preview 말풍선은 index를 소비하지 않는다** (`consumesConversationIndex`). 힌트 조회의 `rpMsgId`는 마지막 AI entry의 `conversationIndex`를 그대로 사용한다.
- 사용자 말풍선 노출 직후 후속 AI 음성(`GET /rps2/sessions/{id}/ai-message/audio`)을 미리 준비한다.
- 사용자 말풍선 후 **500ms 대기** → 나레이션 노출(`playing_conversation_mixin`, 한 줄씩 fade-in) → 나레이션 단계는 **최소 1초** 보장 → **500ms 대기**.
- 위 시점과 AI 음성 준비 완료 중 늦은 시점에 AI 말풍선을 노출하고, 준비된 음성이 있으면 말풍선 노출과 동시에 재생한다.

**푸터 3층 상세** (`lib/screens/roleplay/playing_input_mixin.dart` — `buildPlayingFooter`)

1. **서비스메시지 영역**: height **24**, `bodyMedium` 중앙. 사용자 턴 활성 시 `holdMicrophoneToSpeak` fade-in/out, 마지막 턴 나레이션·후속 AI 종료 후 서버 `serviceMessage`(없으면 `roleplayAnalyzing`) blink.
2. **입력 영역**: S1과 동일 UX
   - **녹음**: height **120** (`roleplayMicFooterStackHeight` = mic 100px + 아이콘 행 중앙 20px), `RoleplayMicButtonArea` — 마이크 **이미지 하단**이 하단 아이콘 행(40px) 세로 중앙에 정렬·Cancel 드래그 영역 포함. hold·Cancel 드래그·500ms 미만 거절·loading 회전. `AudioRecorder.start` 완료 전 손을 떼거나 cancel되면 pending action으로 저장 후 start 완료 시 finish/cancel을 이어서 처리한다.
   - **타이핑**: gap 10 + 입력 height **44** (`#353535` stadium) + Send 44×44 + gap 10
3. **하단 아이콘**: height **40**, 좌 mic↔keyboard(30×30)·우 hint lightball(24×24) — S1과 동일 토글·힌트 idle 3s 후 blink

**입력 활성 조건**: `_isUserTurn == true`일 때만 마이크·타이핑·Send 활성. 턴 엔진 전체는 **§3-1** 참조.

- **현재**: AI 음성 종료 후 오토힌트 조건 처리 뒤 사용자 턴 활성. 발화 전송 중 입력 잠금, 응답 실패 시 사용자 턴 복구.
- 턴바 색·라벨 갱신: 사용자 발화 응답 `userGrade` 기준.

**API·연동 미완 (TODO)**

| 기능 | S1 | S2 |
|------|----|----|
| 녹음/타이핑 전송 | `POST /v1/roleplay-sessions/{id}/user-message/...` | `POST /rps2/sessions/{id}/user-message/audio`(octet-stream), `POST /rps2/sessions/{id}/user-message/text`(raw string) ✅ |
| 힌트 탭 | `GET .../hint` + 본문 hint 말풍선 | **`GET /rps2/sessions/{id}/hint/{rpMsgId}`** + `playing_hint_mixin` — 2단계(번역→답변보기)·en은 본문 즉시·sound API. 202 not-ready는 150/250/400/700/1500ms ×3 패턴으로 최대 15회 재시도 | ✅ |
| 녹음 중 본문 preview | recording 말풍선 | S1 동일 — 녹음 시작 시 우측 `...` wave 말풍선(150ms fade-in), S2 사용자 말풍선 색(흰 30%·흰 점) | ✅ |

#### ❌ 아직 미구현 (S1 `playing_backup.dart`에서 이식·S2 API로 재설계 필요)

아래는 **백업 파일에만** 존재. S2에서는 `/rps2/` API 명세 확인 후 이식할 것.

| 영역 | S1 백업 참고 | S2 메모 |
|------|--------------|---------|
| AI 선시작 (①만) | `_handleAiStart`, session aiSound | ✅ `playing_conversation_mixin` — 말풍선·TTS·번역 아이콘 (**나레이션·activateUserTurn 없음**) |
| 대화 UI (User/나레이션/힌트/후속 AI) | `_conversationEntries` | ✅ `playing_conversation_mixin` — AI/User/Narration entry, 힌트는 별도 entry로 append |
| 프로그레스바 | `_buildProgressHeader`, `scenarioFlow` | ✅ S2 턴바 — `userGrade` 기준 색·라벨 효과, 마지막 턴 분석중 blink |
| 마이크·타이핑 입력 | `_MicButtonState`, 녹음/전송 | ✅ `playing_input_mixin` — RpS2 user-message API 연동 |
| Playing API 호출 | `/v1/roleplay-sessions/{id}/…` 전부 | ✅ `/rps2/sessions/{id}/user-message/audio|text`, `GET /ai-message/audio`, hint/translation/sound |
| 설정패널 (kebab) | `_buildSpeedPanel`, `PUT /v1/users/speed-rate` | ✅ **설정패널** (`roleplay_configuration_panel.dart`) — 오토힌트 토글 + 가로 속도 슬라이더 |
| 타임아웃 countdown | `roleplay.duration` 기반 | S2 **duration 개념 없음** — 정책 재정의 필요 |
| 종료 → Ending/Failed/Result | `_handleResultIdEnding`, `RoleplayRouter.replaceWith*` | Ending/Result도 S2 state/API 마이그레이션 필요 |
| `isUserTurnYn` | S1 state | **삭제됨**. S2는 **AI 선시작 고정** (`playing_backup`도 `_handleInitialTurn` → `_handleAiStart` only) |

#### Playing 작업 시 참조 순서 (권장)

1. `.docs/CONTEXT_ROLEPLAY_S2.md` (본 문서) — 범위·state 확인  
2. `lib/screens/roleplay/playing.dart` — S2에 추가할 위치  
3. `lib/screens/roleplay/playing_backup.dart` — UI/UX·로직 **복사 원본** (필요 부분만)  
4. `lib/services/series_state_service.dart` — session·episode·user  
5. RpS2 Playing API 지침 (미수령 시 사용자에게 확인)

### 4-5. Ending / Failed / Result / Survey ⏳ (S1 유지)

- **파일**: `ending.dart`, `failed.dart`, `result.dart`, `result_v2.dart`, `survey.dart` 등
- **`RoleplayStateService` 의존** (overview, roleId, cachedResult, sessionId)
- S2 Playing 완료 후 **SeriesStateService 기반**으로 순차 마이그레이션 예정

### 4-6. RoleplayOverviewScreen ⏸ (S1 fade-out)

- **파일**: `lib/screens/roleplay/overview.dart`
- Opening 연결 **제거됨**. 스크린·state 정리는 **삭제 단계**에서 처리.

---

## 5. S2 API (클라이언트 구현 현황)

| Method | Path | DTO | 사용처 | 상태 |
|--------|------|-----|--------|------|
| GET | `/rps2/series/{seriesId}/overview` | `RpS2SeriesOverviewDto` | SeriesOverview | ✅ |
| GET | `/rps2/series/{seriesId}/best-score` | `Map<int,int>` | SeriesOverview (CEFR 변경) | ✅ |
| POST | `/rps2/sessions` | req: `{seriesId, episodeId}` / res: `RpS2SessionDto` | Opening Start | ✅ |
| GET | `/rps2/sessions/{id}/translation?rpMsgId=` | **plain String** (JSON 아님) · `rpMsgId` = AI entry `conversationIndex` | Playing AI 말풍선 번역 | ✅ `SeriesApi._parseStringResponse` |
| GET | `/rps2/sessions/{id}/hint/{rpMsgId}` | `RpS2HintDto` (`hint`, `translatedHint`) · `rpMsgId` = 마지막 AI `conversationIndex` · 202 not-ready는 최대 15회 재시도 | Playing 힌트 | ✅ |
| GET | `/rps2/sessions/{id}/hint/sound` | `TtsResultDto` (`cdnYn`, `cdnPath`, `sound`) | 힌트 전체 재생 | ✅ |
| GET | `/rps2/sessions/{id}/hint/sound/{wordIndex}` | 동일 | 힌트 단어 재생 | ✅ |
| POST | `/rps2/sessions/{id}/user-message/audio` | req: `byte[]` octet-stream / res: `RpS2UserMessageResponseDto` | 사용자 음성 발화 | ✅ |
| POST | `/rps2/sessions/{id}/user-message/text` | req: raw `String` / res: `RpS2UserMessageResponseDto` | 사용자 텍스트 발화 | ✅ |
| GET | `/rps2/sessions/{id}/ai-message/audio` | `RpS2SoundResDto` (`cdnYn`, `cdnPath`, `file`/`sound`) | 후속 AI 음성 | ✅ |

**모델 파일**: `lib/models/series_models.dart`  
(`RpS2SessionRequestDto`, `RpS2SessionDto`, `RpS2SoundResDto`, `RpS2UserMessageResponseDto`, `RpS2SeriesOverviewDto`, `RpS2SeriesEpisodeDto`, …)

**API 파일**: `lib/api/endpoints/series_api.dart` → `SudaApiClient.createRpS2Session`

**S1 세션 API** (`POST /v1/roleplay-sessions`): `RoleplayApi.createRoleplaySession` — **`playing_backup` / Lab 등 S1 전용**. S2 Opening에서는 **사용하지 않음**.

**미구현 (Playing용)**: result/session status 및 Ending/Failed/Result 화면 전환 — **`requiredSpeechCount` 도달 후 `roleplayAnalyzing` blink 진입한 이후는 추후 지침 대기**.

---

## 6. S2에서 제거·변경된 S1 개념

| S1 | S2 |
|----|-----|
| `roleplayId` + `roleId` 세션 요청 | `seriesId` + `episodeId` |
| Opening 헤더 duration | **없음** |
| Opening Scenario (`role.scenario`) | **Briefing** (`episode.briefing`) |
| 역할명 (`roleList` / role 선택) | **`userCharacter.name`** (고정) |
| `isUserTurnYn` state | **삭제** — AI 선시작 |
| `popToOverview` → RoleplayOverview | → **SeriesOverview** |
| `FIRST_OVERVIEW` on Roleplay Overview | → **Series Overview** 로드 시 |

---

## 7. 관련 파일 빠른 맵

```
lib/services/series_state_service.dart     # S2 in-memory state
lib/models/series_models.dart              # RpS2 DTO (RpS2CefrDto.requiredSpeechCount)
lib/api/endpoints/series_api.dart          # /rps2/* HTTP
lib/screens/series/overview.dart           # Series Overview
lib/screens/roleplay/opening.dart          # S2 Opening
lib/screens/roleplay/playing.dart          # S2 Playing (진행 중)
lib/screens/roleplay/playing_input_mixin.dart  # 푸터·입력 비즈니스 (S1 이식)
lib/screens/roleplay/playing_conversation_mixin.dart  # S2 ① AI 시작 말풍선·음성·번역·힌트 트리거 훅
lib/screens/roleplay/playing_hint_mixin.dart       # S2 ② 힌트 영역·API·sound
lib/widgets/roleplay_mic_button_area.dart  # 녹음 버튼 UI (S1 이식)
lib/screens/roleplay/playing_backup.dart   # S1 Playing (참조 전용)
lib/screens/roleplay/tutorial.dart         # Tutorial (S2 user 연동)
lib/widgets/roleplay_scaffold.dart         # belowHeader 슬롯 (턴바영역 등)
lib/widgets/roleplay_turn_bar_area.dart    # S2 Playing 턴바영역 위젯
lib/widgets/roleplay_mission_panel.dart    # S2 Playing 미션 패널
lib/effects/mission_complete_effect.dart   # 미션 완료 shine (EffectOverlayService)
lib/widgets/effects/mission_complete_overlay.dart  # 미션 완료 전체화면 오버레이
lib/widgets/roleplay_configuration_panel.dart  # S2 Playing 설정패널 (오토힌트·속도)
lib/routes/roleplay_router.dart            # replaceWithPlaying, popToOverview
lib/services/roleplay_state_service.dart   # S1 잔재 (Ending/Result/backup)
lib/utils/english_level_util.dart        # cefrMap 키 (ENGLISH_LEVEL)
```

---

## 8. 다음 작업 후보 (우선순위 참고)

1. ~~**Playing**: 턴바영역 — 사용자 발화 완료 시 `_turnBarColors`·`_turnLabelTexts` 갱신 + 전 턴 완료 시 종료 분기~~ ✅ 마지막 턴 나레이션·후속 AI 후 `serviceMessage` blink
2. ~~**Playing**: 햄버거 메뉴 UX + 패널 (S1 speed panel 대체)~~ ✅ 설정패널 UI
3. ~~**Playing**: ① AI 선시작 말풍선·음성·번역~~ ✅ (나레이션·입력 활성 **미포함**)
4. ~~**Playing**: RpS2 turn/message API 연동 (지침 수령 후)~~ ✅ user-message + GET ai-message/audio
5. ~~**Playing**: 대화·미션 UI (backup 참조 + S2 episode/cefr 데이터)~~ ✅ 사용자/나레이션/후속 AI/미션 완료 효과
6. **Playing**: 마지막 턴 이후 result 호출·이동
7. **Ending/Failed/Result**: `SeriesStateService` + RpS2 API 마이그레이션
8. **RoleplayStateService** S2 경로에서 완전 분리 및 S1 코드 정리

---

## 9. 문서 갱신 규칙

- S2 Roleplay 스크린·API·state 변경 시 **본 문서를 먼저** 갱신한다.
- S1-only 정책은 `.docs/CONTEXT_ROLEPLAY.md`에만 둔다.
- 스크린 UI 상세는 `.docs/CONTEXT_SCREEN.md` §12·§13과 동기화한다.
- 작업 이력 한 줄 요약은 `.docs/CONTEXT_HISTORY.md` 상단에 추가 가능.
