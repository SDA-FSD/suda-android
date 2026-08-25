# Roleplay 컨텍스트 (S2)

> 롤플레이 플로우·state·`/rps2` API의 사실 기준. UI 픽셀은 `CONTEXT_SCREEN.md`.
>
> **S1**은 단일 RP 단위였다. 플레이 경로·`playing_backup`은 제거됨. `RoleplayOverviewScreen`은 딥링크 잔존.

---

## 1. 한 줄

홈 **시리즈** → `SeriesOverviewScreen` → 에피소드. state는 `SeriesStateService`. 세션 `POST /rps2/sessions` `{seriesId, episodeId}`. Playing은 `playing.dart`.

---

## 2. S2 네비게이션 흐름 (현행 코드)

```
Home (시리즈 썸네일)
  → SeriesOverviewScreen          [Sub, GET /rps2/series/{id}/overview]
  → (에피소드 Play)
  → RoleplayTutorialScreen        [Tutorial 미완료 시만 노출]
  → RoleplayOpeningScreen         [Full]
  → RoleplayPlayingScreen         [Full]
  → Ending / Result / Try Again
```

- **복귀**: `RoleplayRouter.popToOverview()` → **`/series/overview`**.

---

## 3. SeriesStateService (S2 플레이 컨텍스트)

**파일**: `lib/services/series_state_service.dart`  
**싱글톤**: `SeriesStateService.instance`

| 필드 | 타입 | 설정 시점 | 용도 |
|------|------|-----------|------|
| `seriesId` | `int?` | Series Overview 로드 | 세션 API `seriesId` |
| `overview` | `RpS2SeriesOverviewDto?` | Series Overview 로드 | 시리즈 메타·`episodes`·`bestScoreMap`·ending 필드 |
| `selectedEpisodeId` | `int?` | 에피소드 Play 탭 | 현재 플레이 대상 에피소드 id |
| `user` | `UserDto?` | Overview / Episode Play / Tutorial | 사용자·metaInfo (속도 등) |
| `session` | `RpS2SessionDto?` | Opening Start 성공 | `sessionId`, 초기 `aiSound` |

**편의 getter**: `selectedEpisode`, `sessionId`

**refresh / clear 규칙**
- **다른 `seriesId`로 Series Overview 진입** → `setSeriesOverview` 시 `selectedEpisodeId`·`session` 초기화.
- **다른 에피소드 Play** → `setSelectedEpisodeId` 시 `session` 초기화.
- `clear()` → 전 필드 null.

`RoleplayStateService`는 딥링크 Overview·일부 user 동기화 잔존. 플레이는 **`SeriesStateService`만**.

---

## 3-1. S2 Playing 턴 엔진 (목표 구조) — **agent 필독**

**항상 AI 선시작** (`isUserTurnYn` 없음). 첫 턴은 Opening 세션 `aiSound` + episode `startLine`.

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
| **① AI 시작** | 진입 직후 첫 AI 말풍선·TTS·번역 아이콘 | 텍스트: `cefrMap[ENGLISH_LEVEL].startLine` · 음성: `session.aiSound` · 아바타: `aiCharacter.rpImgPath` · 번역: `GET /rps2/sessions/{id}/translation?rpMsgId=` | ✅ `playing_conversation_mixin.dart` **`startAiOpeningFlow`만**. iOS: Opening AVPlayer teardown를 `IosAudioTeardown` 큐(job timeout 2s)로 직렬화, CDN을 파일로 받아 `setFilePath`, duration=0을 로드 실패로 보지 않음. Playing iOS 오디오 세션은 TTS부터 `playAndRecord`+`defaultToSpeaker`(Bluetooth 미사용 전제, 탭 시 category 전환 없음). |
| **② 힌트 자동** | AI 발화 후 조건부 | `_autoHintEnabled` + `GET /rps2/sessions/{id}/hint/{rpMsgId}` (`rpMsgId` = 마지막 AI `conversationIndex`) | ✅ `playing_hint_mixin.dart` — 오토힌트 ON 자동 노출 후 사용자 턴·OFF 아이콘 탭+사용자 턴·AI 음성 종료 트리거·3s blink. 힌트 텍스트 202 not-ready 시 최대 15회 재시도 |
| **③ 사용자 발화** | 마이크/타이핑 전송 | `POST /rps2/sessions/{id}/user-message/audio`, `POST /rps2/sessions/{id}/user-message/text` | ✅ `playing_input_mixin.dart`. iOS: 탭 시 세션 재설정 없이 `recorder.start`(플러그인 `manageAudioSession=false`). 말풍선은 start 전에 노출. AOS 녹음 경로는 세션 전환 없음(기존과 동일). |
| **④ 나레이션+후속 AI+턴바** | 사용자 1회 발화 후 서버 처리 | `RpS2UserMessageResponseDto(userText,userGrade,narration,aiText,missionCompletedIndex,serviceMessage?)` + `GET /rps2/sessions/{id}/ai-message/audio` | ✅ 사용자 말풍선·턴바 등급 효과·미션 완료 효과·나레이션·후속 AI 말풍선/음성 |
| **⑤ 반복·종료** | 턴 소진·finish | `requiredSpeechCount` | ✅ 마지막 턴 나레이션·후속 AI·분석중 blink 후 `PUT /rps2/sessions/{id}/finish` 분기. 상세 §3-2 |

### 입력(마이크·타이핑) 활성 규칙

- `activateUserTurn()` / `deactivateUserTurn()` (`playing_input_mixin.dart`)로만 제어.
- **현재**: Playing 진입 시 `deactivateUserTurn()` → AI 음성 종료 후 오토힌트 ON이면 `showPlayingHint()` 완료 뒤 `activateUserTurn(enableHintButton:false)`, OFF이면 `onHintAvailableAfterAi()` 직후 `activateUserTurn()`.
- 사용자 발화 준비 시점에만 `activateUserTurn()` 호출. 발화 전송 시작 시 사용자 턴·힌트 비활성, 응답 실패 시 사용자 턴 복구. 녹음 시작 중 release/cancel이 들어오는 경우 시작 완료 후 pending finish/cancel을 처리해 요청 누락을 방지한다.
- **② 힌트**: AI 음성 종료 후 트리거. 오토힌트 ON → 자동 노출 후 사용자 턴, 이 턴의 힌트 버튼은 disabled 유지. OFF → 아이콘 enabled·3s blink·탭 시 노출. 발화 완료(녹음 종료·텍스트 전송) 시 힌트 제거(녹음 시작 시 유지).

### agent 주의 (범위 침범 방지)

- Playing은 본 문서 ③~⑤ 루프. `/v1/roleplay-sessions`를 쓰지 않는다.

### 3-2. Playing 마무리 — `PUT finish` 및 분기 (agent 필독)

**오케스트레이션**: `lib/screens/roleplay/playing_finish_mixin.dart`  
**state 저장**: `SeriesStateService.cachedUserHistory` (`RpS2UserHistoryDto`)

#### 트리거

| # | 조건 | 시점 |
|---|------|------|
| ① 세션 만료 | 사용자 유발 API(번역·힌트 조회/sound·발화 audio/text) **HTTP 404** | 즉시 `PUT finish` 1회 → 분기 |
| ② 정상 마무리 | 마지막 AI `GET ai-message/audio` **수신 이후** (`aiText` 없으면 나레이션 후) | `PUT finish` 백그라운드 시작 · 전환은 AI 종료+finish 완료 후 |

404 **제외**: `GET ai-message/audio`(자동), Opening TTS, `PUT speed-rate`

#### `PUT /rps2/sessions/{rpSessionId}/finish`

- 응답: JSON 숫자 (`0` = 실패, 자연수 = `rpUserHistoryId`)
- 404: `RpS2SessionNotFoundException`

#### 분기

| finish 결과 | 전환 메시지 (l10n, 3초, blink 없음·흰색) | 이동 |
|-------------|------------------------------------------|------|
| **A) `0`** | `roleplayFinishNotEnoughProgress` | Try Again (`replaceWithTryAgain`) |
| **① 404 → finish 실패** | 없음 | Try Again **즉시** |
| **B) 자연수** + 마지막 에피소드 아님 | `roleplayFinishCompleted` | Result (`replaceWithResult`) |
| **C) 자연수** + 마지막 에피소드 | `roleplayFinishMovingToEnding` | Ending (`replaceWithEnding`) |

- **마지막 에피소드**: `overview.episodes.last.id == selectedEpisodeId`
- B/C: `GET /rps2/user-histories/{rpUserHistoryId}` — 3초 전환과 **병렬** 조회, 500ms 후 1회 재시도, 실패 시 Playing persistent `Network Error`
- C: 이동 전 `overview.endingImgPath` precache
- B/C 이동 전 `SeriesStateService.setCachedUserHistory`

#### 마지막 턴 타이밍

```
마지막 user-message 응답 → (턴바·미션) **분석중 blink 즉시**
  → user 말풍선·나레이션 → (aiText 있으면) GET ai-message/audio 수신
  → requestFinishAfterLastUserResponse()
  → user 말풍선·턴바·미션 → 나레이션 → 후속 AI
  → startPlayingAnalyzingBlink → onLastTurnPresentationComplete()
  → finish 완료 대기 → stopAnalyzingBlink
  → A/B/C 전환 메시지 3초 (+ B/C user-histories 병렬) → navigate
```

(`분석중 blink`는 마지막 `POST user-message` 응답 직후. `PUT finish`는 ai-audio 수신 후(또는 aiText 없으면 나레이션 후). `onLastTurnPresentationComplete`는 후속 AI 음성 종료 시 — aiText 없으면 finish 직후.)

---

## 4. 스크린별 마이그레이션 상태

### 4-1. SeriesOverviewScreen ✅ (S2 본流)

- **파일**: `lib/screens/series/overview.dart`
- **API**: `GET /rps2/series/{seriesId}/overview`(`category` 포함), `GET /rps2/series/{seriesId}/best-score`
- **복귀 시 bestScore 갱신**: `RoleplayRouter.popToOverview` 직전 `markBestScoreRefreshPending` → Overview `RouteAware.didPopNext`에서 `GET .../best-score` 재조회(현재 CEFR 기준). CEFR 변경 후와 동일 API.
- **로드 시**: `SeriesStateService.setSeriesOverview`, **`FIRST_OVERVIEW`** 통계 (`POST /v1/users/first-overview`, metaInfo `FIRST_OVERVIEW=Y` 가드)
- **에피소드 Play**: `setSelectedEpisodeId(episode.id)` → `RoleplayRouter.pushTutorial`
- **Similar Topic 탭**: `SeriesSimilarTopicTabContent` — `GET /v2/home/series?category=` 초기 0–2페이지 로드·스크롤 추가 페이징, 현재 series 제외, 3열 썸네일 탭 시 Overview push

### 4-2. RoleplayTutorialScreen ✅ (S2 경로 연동)

- **파일**: `lib/screens/roleplay/tutorial.dart`
- **user** 조회·갱신: `SeriesStateService` (Tutorial 완료 시 `RoleplayStateService.setUser`도 맞춤)
- 완료/스킵 → `replaceWithOpeningFromTutorial`

### 4-3. RoleplayOpeningScreen ✅ (S2 UI·세션)

- **파일**: `lib/screens/roleplay/opening.dart`
- **데이터**: `SeriesStateService.selectedEpisode` (`title`/`briefing`/`thumbnailImgPath`/`aiCharacter`)
- **렌더**
  - 배경: episode `thumbnailImgPath` → `RoleplayOverviewBackdrop`
  - 헤더 타이틀: episode `title` (`SudaJsonUtil.localizedMapText`) · `bodySmall` **w700** · **1줄** 말줄임 — X 밴드(top 16·height 40) 세로 중앙(`centerTitleInHeaderActionRow`, `RoleplayScaffold.episodeTitleStyle`)
  - **우상단 에너지 배지**: `EnergyHeaderBadge` (`SafeArea top + 16`, `right: 16`) — Home과 동일 스펙·탭 시 `showEnergyInfoPopup`
  - **duration 없음** (S2)
  - AI 캐릭터: l10n `roleplayOpeningAiCharacter`(en AI Character / ko AI 캐릭터 / pt Personagem IA) + `selectedEpisode.aiCharacter.name` (`headlineLarge` `#0CABA8`)
  - 시나리오: l10n `roleplayOpeningScenario`(en Scenario / ko 시나리오 / pt Cenário) + episode `briefing` (`DefaultMarkdown`)
- **Start (`Let's Start`)**
  1. **마이크 권한** (`Permission.microphone`, `permission_handler`, `opening.dart`)
     - `status` 확인 → 허용/`limited`이면 진행
     - `denied`이면 `request()` → 허용 시 진행
     - 거부(일시): l10n `microphonePermissionDenied` 토스트, Opening 유지
     - **영구 거부/`restricted`**: 다이얼로그(이전으로 / 설정 열기) → 설정 열기 시 `openAppSettings()`만. pending·autoStart·`main` 복구 없음
     - **설정 복귀 후**: Opening(또는 iOS 스택 리셋 시 홈)에 그대로 두고, 사용자가 **다시 Start**
     - **iOS 필수:** `ios/Podfile` `PERMISSION_MICROPHONE=1` + `Info.plist` `NSMicrophoneUsageDescription` (없으면 `request()`가 no-op처럼 동작할 수 있음). 요약: `.docs/CONTEXT.md` §2·`CONTEXT_IOS.md`
  2. `POST /rps2/sessions` `{seriesId, episodeId}`
  3. `sessionId == '0'`: `showEnergyInsufficientPopup`(에너지 바 + l10n `energyInsufficient`) → Opening 유지, 재시도 가능
  4. `sessionId`가 `-`로 시작: "Cannot start roleplay" 토스트 → Opening 유지
  5. 정상 sessionId → `SeriesStateService.setSession(session)` → `replaceWithPlaying` (에너지 소비는 Playing 발화 처리 시, Start 시점 소비 없음)
  6. **우상단 `EnergyHeaderBadge`**: Home과 동일 충전·무제한 타이머 — 화면 체류 중 30분 충전·무제한 만료 시 서버 재조회

### 4-4. RoleplayPlayingScreen

#### 파일 구조

| 파일 | 역할 |
|------|------|
| `lib/screens/roleplay/playing.dart` + mixins | 라우터가 사용 |

#### ✅ 이미 구현됨 (`playing.dart`)

- `RoleplayScaffold` + episode `thumbnailImgPath` 배경
- **헤더**
  - 좌상 **X** → 나가기 확인 레이어
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
  - **등급 효과**: A `#0CABA8` 라벨 l10n `roleplayTurnGradeA`, B `#62FF00` `roleplayTurnGradeB`, C `#FFB700` `roleplayTurnGradeC`, D `#FF0000` `roleplayTurnGradeD`. bar 색·라벨 즉시 100% pop(1.0→1.42→1.0, 320ms). **2초 후** 라벨 150ms fade-out + bar 등급색 **20%**(`pastTurnBarOpacity`)로 dim(다음 사용자 턴 시작과 무관).
- **시스템 뒤로가기**: `PopScope` → X와 동일하게 확인 레이어
- **나가기 확정**: `RoleplayRouter.popToOverview` → Series Overview
- **설정패널 (configuration panel)** — `lib/widgets/roleplay_configuration_panel.dart`
  - **노출**: 케밥 탭 토글 · `top = safeArea + 56` · `right = 24` · 미션패널 포함 최상단
  - **닫기**: 케밥 재탭 · 패널 외부 탭 (`Listener` dismiss)
  - **프레임**: Series Overview 언어레벨 버튼과 동일 글래스(BackdropFilter σ12 + gradient border, radius 16)
  - **오토힌트**: l10n `roleplayAutoHint` · push agreement 동일 토글 · Pre-A1/A1/A2 기본 on, B1 이상 off · `_autoHintEnabled` (Playing 생명주기)
  - **속도**: l10n `roleplayVoiceSpeed` · 가로 레일 200×4 · thumb 9 흰 원 · 좌측~thumb `#80D7CF` · 0.7/1.0/1.2/1.5 · 탭 시 1단 이동 + `PUT` speed-rate
  - **구분선**: `SizedBox` 200×1 직접 그림, `#FFFFFF` 40% (`panelLineColor`), 상·하 여백 **16**
  - **슬라이더**: 레일 기본색 `panelLineColor` · 터치 영역 = 레일+라벨 전체 · 탭 1단 이동 · 드래그 후 가장 가까운 4단계 스냅

#### 레이아웃 구역 (턴바영역 아래)

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
- **오버레이**: `buildPlayingBody`의 `SingleChildScrollView` 위에 `Positioned` — 메시지 append 시 위로 스크롤되며 패널에 가려짐. 스크롤과 미션 패널 **사이**에 **상단 페이드** 레이어: SafeArea 상단~미션 패널 하단, `#121212` 100%→0% 세로 gradient(헤더·턴바·미션 패널은 페이드 위에 노출, 말풍선만 페이드에 가려짐). 하단 그라데이션 없음. 상단 페이드는 `scaffoldBodyHorizontalInset`(24) 상쇄로 **디스플레이 좌우 전폭**. `playing.dart` 최외곽 Stack에 상태표시줄·하단 시스템 영역 `#121212` 솔리드 보강.
- **스크롤 정책**: 본문 `SingleChildScrollView`는 `ScrollController`를 사용한다. AI/User/Narration entry 또는 힌트 bubble이 새로 추가될 때만 최하단으로 250ms 애니메이션 이동한다. 사용자가 상하 드래그로 과거 메시지를 보는 중에는 새 요소 추가가 없는 한 강제로 하단 고정하지 않는다.
- AI 말풍선 (`playing_conversation_mixin` `_buildAiMessage`): 배경 `#353535`·padding **10**·radius 12. 본문 `bodyMedium` 흰색. 번역 `labelSmall` `#777373`. 아바타 40×40은 말풍선 컨테이너 **상단** 정렬(`CrossAxisAlignment.start`). 번역 펼침 시 가려지면 `scrollToRevealBubbleIfNeeded` — `getOffsetToReveal`+하단 inset **8**, 필요 시에만 아래로 최소 스크롤, `maxScrollExtent` 강제 없음.
- 사용자 말풍선 (`_buildUserMessage`): 우측 정렬·max 너비 `bodyWidth×0.7`. 배경 흰색 **30%**·padding 좌우 12 상하 10·radius 12. 본문 `bodyMedium` 흰색.
- 녹음 중 말풍선 (`_buildRecordingBubble`): S1과 동일 — 녹음 시작 시 entry append·150ms fade-in·우측 말풍선·3점 wave(900ms sin, opacity 0.3~1.0). 배경·점 색은 사용자 말풍선과 동일(흰 30%·흰 점). **힌트박스가 노출된 턴**에는 힌트박스 **아래**에 배치(`_buildConversationWithHint`에서 recording을 hint 뒤로 렌더). 녹음 종료/취소 시 제거 후 STT 결과 말풍선 노출.
- **첫 AI 말풍선 Y**: 본문 스크롤 영역 상단에 **고정 `SizedBox(height: 68)`** (`PlayingConversationLayout.firstBubbleTopOffset`) — 패널에 가리지 않음. 추가 말풍선은 아래로 쌓이며 스크롤 시 패널 뒤로 이동
- **AI 아바타**: `selectedEpisode.aiCharacter.rpImgPath` — Opening `initState`·Playing 전환 직전 `precacheImage`
- **미션 완료 효과**: `missionCompletedIndex` 수신 시 **`MissionCompleteEffect`**(`EffectOverlayService` root overlay)로 `mission_complete_effect.png`를 **디스플레이 width × 2/3** 크기(에셋 전체 기준)로 재생 — **미션 패널 active row 좌측 on/off 아이콘 중심**과 이미지 중심(핑크 원) 정렬, 좌·상단은 화면 밖으로 클리핑 가능(`Stack clipBehavior: none`). 중앙 원은 에셋 폭의 ~19%라 실제 눈에 띄는 크기는 화면의 ~12% 수준. 500ms fade-in → 1000ms fade-out(1.5s, 미세 회전). shine 시작과 동시에 `VibrationPreset.quickSuccessAlert` 축하 진동. 아이콘 즉시 `rps2_mission_on.png` 전환. 패널 배경은 동시에 `#9E0067` **1.5초** 노출 후 300ms 전환으로 글래스 프레임 복귀·**이 시점에** `activeMissionIndex`를 다음 미완료 미션으로 전환. **전 미션 달성 시** 글래스 복귀와 동시에 패널 전체 300ms fade-out.
| **푸터** | `RoleplayScaffold.footer` | `SafeArea(top:false)` + 3층 | 입력·아이콘·서비스메시지 |

**사용자 발화 후 응답 타이밍**

- `conversationIndex`는 **1부터 시작**하며 AI/User/Narration entry를 포함한 전체 대화 순번이다. **recording preview 말풍선은 index를 소비하지 않는다** (`consumesConversationIndex`). 힌트 조회의 `rpMsgId`는 마지막 AI entry의 `conversationIndex`를 그대로 사용한다.
- 사용자 말풍선 노출 직후 후속 AI 음성(`GET /rps2/sessions/{id}/ai-message/audio`)을 미리 준비한다.
- 사용자 말풍선 후 **500ms 대기** → 나레이션 노출(`playing_conversation_mixin`, 한 줄씩 fade-in) → 나레이션 단계는 **최소 1초** 보장 → **500ms 대기**.
- 위 시점과 AI 음성 준비 완료 중 늦은 시점에 AI 말풍선을 노출하고, 준비된 음성이 있으면 말풍선 노출과 동시에 재생한다.

**푸터 3층 상세** (`lib/screens/roleplay/playing_input_mixin.dart` — `buildPlayingFooter`)

1. **서비스메시지 영역**: height **24**, `bodyMedium` 중앙. **세션당 첫 사용자 발화 턴**에만 `holdMicrophoneToSpeak` fade-in/out. **마지막 턴** `POST user-message` 응답 **직후** 서버 `serviceMessage`(없으면 `roleplayAnalyzing`) blink(이후 나레이션·후속 AI 계속 노출).
2. **입력 영역**:
   - **녹음**: gap **10** + height **140** (`roleplayMicFooterStackHeight` = mic 100px + 에너지/아이콘 행 40px). 마이크 **이미지 하단**이 에너지·아이콘 행 **상단**에 정렬. 하단 행 중앙 `PlayingEnergyIndicator`(일반: energy+숫자, 무제한: unlimited 아이콘만). 좌 mic/keyboard·우 hint 아이콘과 동일 세로 높이.
   - **타이핑**: gap 10 + 입력 height **44** (`#353535` stadium) + Send 44×44 + gap 10
3. **하단 아이콘**: height **40**, 좌 mic↔keyboard(30×30)·우 hint lightball(24×24) — 토글·힌트 idle 3s 후 blink

**입력 활성 조건**: `_isUserTurn == true`일 때만 마이크·타이핑·Send 활성. 턴 엔진 전체는 **§3-1** 참조.

- **현재**: AI 음성 종료 후 오토힌트 조건 처리 뒤 사용자 턴 활성. 발화 전송 중 입력 잠금, 응답 실패 시 사용자 턴 복구.
- 턴바 색·라벨 갱신: 사용자 발화 응답 `userGrade` 기준.

힌트 202 not-ready: 150/250/400/700/1500ms ×3, 최대 15회. 녹음 시작 시 우측 `...` wave 말풍선(150ms fade-in). **duration/타임아웃 없음.**

### 4-5. Ending / Try Again / Result

- **파일**: `ending.dart`, `try_again.dart`, `result.dart` 등

#### RoleplayEndingScreen

- **S2 진입 판별**: `SeriesStateService.cachedUserHistory != null`
- **노출 요소 ↔ 데이터**

| UI | S2 소스 |
|----|---------|
| 배경 이미지 | `overview.endingImgPath` (+ Playing finish 시 precache) |
| 타이틀 | `overview.endingTitle` (`SudaJsonUtil.localizedMapText`) |
| 본문 | `overview.endingContent` (`localizedMapText`, 마크다운 없음) |
| 별점 | `cachedUserHistory.userStarRating` 초기값 · 탭마다 `PUT /rps2/user-histories/{id}/user-star-rating` |
| Next → Result | `replaceWithResult` (`cachedUserHistory` 유지) |


#### RoleplayTryAgainScreen ✅ (S2 분기·UI 갱신)

- **S2 진입 판별**: `SeriesStateService.overview != null`
- **노출 요소**

| UI | 소스 |
|----|------|
| 전체 배경 그라데이션 | 디스플레이 전폭 · 하단→중앙 `#5F0C0C` 100%→0% (스캐폴드 바깥 `Stack`) |
| "Try Again" 타이틀 | 하드코딩 |
| 하트 애니메이션 | 로컬 asset (유지) |
| 안내 문구 | `l10n.roleplayTryAgainMessage` (en/ko/pt) — 서브타이틀 **삭제** |
| Retry 버튼 | 하드코딩 `'Retry'` |
| Report | `l10n.endingReport` → Try Again Report (유지) |
| X / 뒤로가기 | `RoleplayRouter.popToOverview` |
| Retry | `RoleplayRouter.replaceWithOpeningForRetry` (세션 clear 후 Opening) |

#### RoleplayResultScreen

- **S2 진입 판별**: `SeriesStateService.cachedUserHistory != null`
- **로딩 애니메이션**(별점·패널·LikeProgressEffect): `RpS2UserHistoryDto` — `mainTitle`, `subTitle`, `starScore`, `missions`, `words`, `likePoint`, `before/afterLikePoint·Level·ProgressPercentage`
  - Mission 아이콘: `missions(bool[])` → `rps2_mission_on/off.png` 20×20, gap 2
- **애니메이션 이후 본문** (`result.dart` S2 전용):
  - **Feedback 영역**: 삭제(S2)
  - **Key Expression**: `keyExpressions` — 카드 체크+`keyExpression(en)` / `keyExpression(사용자언어)` / `sampleAnswer(en)` / `sampleAnswer(사용자언어)`. 카드 전체 탭(북마크 제외) → `GET /rps2/user-histories/{rpUserHistoryId}/expressions/{expressionIndex}/sound`(`TtsResultDto`, index 0-based). fetch 중 16×16 `CircularProgressIndicator`(strokeWidth 2, `#0CABA8` 70%), 재생 중 `megaphone_fill.png` `#0CABA8`, 타 카드 탭 시 이전 재생 중단. 북마크 OFF→ON: `POST /rps2/user-histories/{id}/expressions/{index}` → `bookmark_on.png` + l10n `expressionSavedToProfile`. ON→OFF: `DELETE` 동일 경로 → `bookmark_off.png`(토스트 없음). 실패 시 HTTP 코드·간단 문구 토스트. 진입 시 북마크 UI 전부 off.
  - **Speech Feedback**(신규): 섹션 헤더 + **View Chat** pill → `ViewChatScreen`(`RpS2UserHistoryDto` 전달, `lib/screens/roleplay/view_chat.dart`). Review Chat과 동일 그라데이션 배경. `messages[]` role별 USER/AI_CHARACTER/AI_NARRATOR/SYSTEM_MISSION 렌더. **헤더 우측 메가폰**(기본색, fill은 자동재생 중만): `msgId` 오름차순 재생 가능 메시지 순차 자동재생, 말풍선 간 300ms 휴식, 재생 중 타겟 말풍선 하이라이트(`#80D7CF`). USER 말풍선은 Speech Feedback 카드 형태(grade·score·feedback 펼침/접힘 — **펼침 score·구분선 레이아웃은 Result Speech Feedback 카드와 동일**). USER 카드·AI 말풍선 오디오 fetch 중 메가폰 대신 16×16 `CircularProgressIndicator`(strokeWidth 2; USER·AI 하이라이트 시 `#054544` 70%, Result 카드와 동일 위치는 `#0CABA8` 70%). AI 말풍선은 아바타 없이 전폭. USER(`audioInputYn=='Y'`) 좌하단 메가폰 탭·AI_CHARACTER(`audioPath` 있음) 말풍선 탭 재생 — USER는 `GET …/messages/{rpMsgId}/audio`, AI는 CDN `audioPath`. 안내 문구 영역 없음.
    - **접힘**: 1줄 grade `bodySmall` **w700**(grade색) · 2줄 사용자 발화 `bodyLarge` · 3줄 메가폰 + **Feedback** pill.
    - **펼침**: score 4항목 — 카드 전폭 **50:50** 2열(좌: Meaning·Vocabulary, 우: Relevance·Grammar). score 패널 좌·우 **24** · 열 간격 **24** · 각 행 `labelSmall` label + bar, 4 label 공통 너비로 bar 좌우 길이 균등. score 영역과 사용자 발화 사이 `#D9D9D9` 1px 구분선 · 2·3줄 사이 `feedback` `bodySmall` `#635F5F`.
    - **펼침/접힘(Result·History)**: Speech Feedback 카드 영역 탭 또는 Feedback pill 탭. `feedbackLockedYn=='Y'`면 Paywall(USER placeholder 카드 유지·grade/score 없음). `'N'`이면 `GET /rps2/user-histories/{rpUserHistoryId}/feedbacks/{rpMsgId}/audio` 준비 후 펼침+TTS 재생 동시(실패 시 펼침만). 로딩 중 pill 화살표 자리 16×16 스피너·재탭 무시. 접기 시 해당 행 TTS 정지. `audioInputYn == 'N'`이면 메가폰 미노출·카드·Feedback pill 탭으로 펼침/접힘(+TTS).
    - **펼침/접힘(View Chat USER)**: USER 말풍선 카드 영역 탭 또는 Feedback pill 탭. feedback null이면 Feedback 버튼 미노출. 펼침 TTS는 Result와 동일 API·스피너.
    - **재생**: `messages[].audioInputYn == 'Y'`인 행만 좌하단 메가폰 탭 시 재생. API `GET /rps2/user-histories/{rpUserHistoryId}/messages/{rpMsgId}/audio`(`TtsResultDto`, `rpMsgId` = `speechFeedback` 키 = `messages[].id`). fetch 중 16×16 `CircularProgressIndicator`(strokeWidth 2, `#0CABA8` 70%), 재생 중 `megaphone_fill.png` `#0CABA8`. Key Expression·Feedback TTS 등 다른 재생 중이면 중단 후 우선 적용.
    - **iOS TTS**: Result Key Expression·Speech Feedback·View Chat·**Profile Saved**는 `SudaTtsAudioPlayer` (`suda_tts_audio_player.dart`). Playing과 같이 byte[]·CDN을 임시 파일로 `setFilePath` + `audio_session` speech. `Uri.dataFromBytes` 미사용(첫 생성 byte[] 무음 방지). AOS는 HTTP/`data:` URI.
  - Footer: Got it! / Report(S1과 동일 UX) — S2는 `POST /rps2/user-histories/{rpUserHistoryId}/report`. **Profile History 진입**(`showReportLink: false`) 시 Report 링크 미노출.
### 4-6. RoleplayOverviewScreen (딥링크 잔존)

- `lib/screens/roleplay/overview.dart` — S1 단일 RP Overview. Play→Opening 연결 없음. appPath `/roleplay/overview/{id}` 용.

---

## 5. S2 API (클라이언트 구현 현황)

| Method | Path | DTO | 사용처 | 상태 |
|--------|------|-----|--------|------|
| GET | `/rps2/series/{seriesId}/overview` | `RpS2SeriesOverviewDto` | SeriesOverview | ✅ |
| GET | `/rps2/series/{seriesId}/best-score` | `Map<int,int>` | SeriesOverview (CEFR 변경) | ✅ |
| POST | `/rps2/sessions` | req: `{seriesId, episodeId}` / res: `RpS2SessionDto` | Opening Start | ✅ |
| GET | `/rps2/sessions/{id}/translation?rpMsgId=` | **plain String** (JSON 아님) · `rpMsgId` = AI entry `conversationIndex` | Playing AI 말풍선 번역 | ✅ `SeriesApi._parseStringResponse` |
| GET | `/rps2/sessions/{id}/hint/{rpMsgId}` | `RpS2HintDto` (`hint`, `translatedHint`) · `rpMsgId` = 마지막 AI `conversationIndex` · 202 not-ready는 최대 15회 재시도 | Playing 힌트 | ✅ |
| PUT | `/rps2/sessions/{id}/hint/{rpMsgId}` | void (200) | 영문 힌트 노출 시 — en 사용자·번역 없음 즉시 노출, 그 외 **답변보기** 탭 시. 실패 무시(플레이 영향 없음) | ✅ |
| GET | `/rps2/sessions/{id}/hint/sound` | `TtsResultDto` (`cdnYn`, `cdnPath`, `sound`) | 힌트 전체 재생 | ✅ |
| GET | `/rps2/sessions/{id}/hint/sound/{wordIndex}` | 동일 | 힌트 단어 재생 | ✅ |
| POST | `/rps2/sessions/{id}/user-message/audio` | req: `byte[]` octet-stream / res: `RpS2UserMessageResponseDto` | 사용자 음성 발화 | ✅ |
| POST | `/rps2/sessions/{id}/user-message/text` | req: raw `String` / res: `RpS2UserMessageResponseDto` | 사용자 텍스트 발화 | ✅ |
| GET | `/rps2/sessions/{id}/ai-message/audio` | `RpS2SoundResDto` (`cdnYn`, `cdnPath`, `file`/`sound`) | 후속 AI 음성 | ✅ |
| PUT | `/rps2/sessions/{id}/finish` | res: JSON `Long` (`0` 또는 `rpUserHistoryId`) | Playing 마무리 | ✅ |
| GET | `/rps2/user-histories?pageNum=` | `SudaAppPage<RpS2SimpleHistoryDto>` | Profile History 목록 | ✅ |
| GET | `/rps2/user-histories/{rpUserHistoryId}` | `RpS2UserHistoryDto` | finish 성공 후 result/ending 이동 전 · **Profile History 상세** | ✅ |
| GET | `/rps2/user-histories/{rpUserHistoryId}/expressions/{expressionIndex}/sound` | `TtsResultDto` (`cdnYn`, `cdnPath`, `sound`) | Result Key Expression · **Profile Saved expression** 카드 탭 | ✅ |
| POST | `/rps2/user-histories/{rpUserHistoryId}/expressions/{expressionIndex}` | void (200) | Result Key Expression 북마크 저장 | ✅ |
| DELETE | `/rps2/user-histories/{rpUserHistoryId}/expressions/{expressionIndex}` | void (200) | Result Key Expression 북마크 삭제 | ✅ |
| GET | `/rps2/user-histories/{rpUserHistoryId}/messages/{rpMsgId}/audio` | `TtsResultDto` (`cdnYn`, `cdnPath`, `sound`) | Result Speech Feedback 카드·메가폰 탭 | ✅ |
| GET | `/rps2/user-histories/{rpUserHistoryId}/feedbacks/{rpMsgId}/audio` | `TtsResultDto` (`cdnYn`, `cdnPath`, `sound`) | Speech Feedback 펼침 시 TTS (Result·History·View Chat) | ✅ |
| PUT | `/rps2/user-histories/{rpUserHistoryId}/user-star-rating` | req: `{userStarRating: 0~5}` | Ending 별 탭마다 | ✅ |
| POST | `/rps2/user-histories/{rpUserHistoryId}/report` | req: `{content: string}` | Result Report Send | ✅ |

**모델 파일**: `lib/models/series_models.dart`  
(`RpS2SessionRequestDto`, `RpS2SessionDto`, `RpS2SoundResDto`, `RpS2UserMessageResponseDto`, `RpS2SeriesOverviewDto`, `RpS2SeriesEpisodeDto`, …)

**`RpS2UserHistoryDto` 응답 필드(클라이언트 사용분만)**: `id`, `messages[]`(`id`, `role`, `content`, `audioInputYn`, `audioPath`), `missions`, `starScore`, `words`, `likePoint`, `keyExpressions`, `speechFeedback`(nullable — `feedbackLockedYn=='Y'`이면 null), `feedbackLockedYn`(`Y`/`N`, 미수신 시 `N`), `userStarRating`, `mainTitle`, `subTitle`, `before/afterLikePoint·Level·ProgressPercentage`. 메타(`userId`·`seriesId`·`hints`·`translations` 등) 및 `messages` 타임스탬프 필드는 서버·클라이언트 모두 제외.

**API 파일**: `lib/api/endpoints/series_api.dart` → `SudaApiClient.createRpS2Session`

`RoleplayApi` 잔존: `getRoleplayOverview`(딥링크)·`updateSpeedRate`(Playing 속도). 세션 생성은 `/rps2/sessions`만.

---

## 6. S1에서 바뀐 점 (요약)

시리즈+에피소드, duration/역할선택/`isUserTurnYn` 없음, Briefing+`aiCharacter`, 복귀는 Series Overview, `FIRST_OVERVIEW`는 Series Overview 로드 시.

---

## 7. 관련 파일 빠른 맵

```
lib/services/series_state_service.dart     # S2 in-memory state
lib/models/series_models.dart              # RpS2 DTO (RpS2CefrDto.requiredSpeechCount)
lib/api/endpoints/series_api.dart          # /rps2/* HTTP
lib/screens/series/overview.dart           # Series Overview
lib/screens/roleplay/opening.dart          # S2 Opening
lib/screens/roleplay/playing.dart          # Playing
lib/screens/roleplay/playing_finish_mixin.dart  # S2 Playing finish API·분기·navigate
lib/screens/roleplay/playing_input_mixin.dart  # 푸터·입력
lib/screens/roleplay/playing_conversation_mixin.dart  # S2 ① AI 시작 말풍선·음성·번역·힌트 트리거 훅
lib/screens/roleplay/playing_hint_mixin.dart       # S2 ② 힌트 영역·API·sound
lib/widgets/roleplay_mic_button_area.dart  # 녹음 버튼 UI
lib/screens/roleplay/tutorial.dart         # Tutorial
lib/widgets/roleplay_scaffold.dart         # belowHeader 슬롯 (턴바영역 등)
lib/widgets/roleplay_turn_bar_area.dart    # S2 Playing 턴바영역 위젯
lib/widgets/roleplay_mission_panel.dart    # S2 Playing 미션 패널
lib/effects/mission_complete_effect.dart   # 미션 완료 shine (EffectOverlayService)
lib/widgets/effects/mission_complete_overlay.dart  # 미션 완료 전체화면 오버레이
lib/widgets/roleplay_configuration_panel.dart  # S2 Playing 설정패널 (오토힌트·속도)
lib/routes/roleplay_router.dart            # replaceWithPlaying, popToOverview
lib/services/roleplay_state_service.dart   # 딥링크 Overview 잔존
lib/utils/english_level_util.dart        # cefrMap 키 (ENGLISH_LEVEL)
```

---

## 8. 문서 갱신

롤플레이 스크린·API·state 변경 시 본 문서와 `CONTEXT_SCREEN.md` Playing/Opening/Result를 맞춘다. 이력은 `CONTEXT_HISTORY.md`.
