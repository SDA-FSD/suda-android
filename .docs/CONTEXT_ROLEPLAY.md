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
- Failed Report (Sub Screen)
  - 파일: `lib/screens/roleplay/failed_report.dart`
  - 클래스: `RoleplayFailedReportScreen`
  - 용도: 사용자가 느낀 불편함 수집. Failed에서 진입, 백버튼/X 시 Failed로 복귀.
- Result (Full Screen)
  - 파일: `lib/screens/roleplay/result.dart`
  - 클래스: `RoleplayResultScreen`
- Result Report (Sub Screen)
  - 파일: `lib/screens/roleplay/result_report.dart`
  - 클래스: `RoleplayResultReportScreen`
  - 용도: Result에서만 진입, 불편함 수집. Send 시 POST /v1/roleplays/results/{roleplayResultId}/report.

## 3. 기본 네비게이션 흐름 (현행 코드 기준)
- Home -> Overview -> Opening -> Playing -> Ending/Failed -> Result -> Overview
- Failed -> Failed Report (Sub Screen, push). Failed Report에서 백버튼/X -> Failed 복귀.
- Result -> Result Report (Sub Screen, push). Result Report에서 백버튼/X -> Result 복귀. 전송 성공 시 pop(true)로 Result에서 Report 문구 숨김.
- Playing/Ending/Failed에서 뒤로가기는 확인 다이얼로그 후 Overview로 복귀 (Failed는 확인 없이 Overview 복귀).

## 4. 라우팅 중앙화 규칙
- Roleplay 화면 전환 규칙은 `lib/routes/roleplay_router.dart`에서 관리한다.
- Overview 진입은 Sub Screen 정책에 맞춰 `SubScreenRoute`를 사용한다.
- Failed Report 진입: Failed에서 `RoleplayRouter.pushFailedReport()` → `SubScreenRoute` 사용 (백버튼 시 Failed 복귀).
- Result Report 진입: Result에서 `RoleplayRouter.pushResultReport()` → `SubScreenRoute` 사용 (백버튼 시 Result 복귀).
- Opening/Playing/Ending/Failed/Result 전환은 기존과 동일하게 `MaterialPageRoute` 기반이다.

## 5. Roleplay 데이터 정책 (요구 사항)
- Home에서 특정 Roleplay 클릭 시 Overview로 이동하며 `roleplayId`를 확보해야 한다.
- Overview 진입 시 `roleplayId`로 서버 호출하여 상세 데이터를 가져온다.
- 앱 이용 중 **단 하나의 Roleplay 정보만 유지**해야 한다.
- Overview에서 획득한 Roleplay 정보는 이후 Roleplay 관련 스크린에서 **항상 접근 가능**해야 한다.
- 사용자의 음성 전송은 **byte[](바이너리)** 방식으로 처리한다. (base64 미사용)

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

## 6-1. Roleplay Playing API 명세
- **세션 초기화**: `POST /v1/roleplay-sessions`
  - req: `{ roleplayId, roleId }`
  - res: `{ sessionId, aiSoundCdnYn, aiSoundCdnPath, aiSoundFile(byte[]) }`
  - 설명: Opening -> Playing 전환 시 세션 생성. `sessionId`는 이후 모든 Roleplay API의 path param으로 사용.
  - 비고: 시작 역할이 AI인 경우 TTS 데이터를 반환. `aiSoundCdnYn == "Y"`이면 CDN 호스트를 prepend하여 `aiSoundCdnPath`의 mp3 재생. 아니면 `aiSoundFile`(byte[]) 재생.
- **사용자 텍스트 입력**: `POST /{rpSessionId}/user-message/text`
  - req: `{ text }`
  - res: `{ text, missionCompleteYn }`
  - 설명: 타이핑 모드 입력 전달. 응답 `text`는 요청과 동일하지만 오디오 API와 동일 포맷 유지 목적.
  - 비고: 미션 정답 여부는 `missionCompleteYn`으로 판단.
- **사용자 음성 입력**: `POST /{rpSessionId}/user-message/audio`
  - req: `byte[] audioData` (`Content-Type: application/octet-stream`)
  - res: `{ text, missionCompleteYn }`
  - 설명: 녹음 모드 발화 전달. 응답 `text`는 STT 결과로 사용자 말풍선 표시.
  - 비고: `missionCompleteYn` 동작은 텍스트 API와 동일.
- **AI 응답 조회**: `GET /{rpSessionId}/ai-message`
  - req: path param만 사용
  - res: `{ text, cdnYn, cdnPath, sound(byte[]) }`
  - 설명: 서버가 비동기 준비한 AI 응답 조회. `text`는 AI 말풍선, 음성은 TTS 재생에 사용.
- **나레이션 조회**: `GET /{rpSessionId}/narration`
  - req: path param만 사용
  - res: `{ text, missionActiveYn, currentStep, resultId }`
  - 설명: AI 말풍선 이후 노출되는 나레이션. 미션 활성 시 안내 텍스트 포함 가능.
  - 비고: `resultId`는 종료 판정 시 생성되는 결과 식별자.
- **힌트 조회**: `GET /{rpSessionId}/hint`
  - req: path param만 사용
  - res: `String`
  - 설명: 사용자 차례에 힌트 버튼 클릭 시 호출.
- **번역 조회**: `GET /{rpSessionId}/translation?index=3`
  - req: path param + query param(`index`)
  - res: `String`
  - 설명: 채팅/나레이션 노출 순서(0-based) 기준 인덱스를 전달해 번역 결과 조회.
  - 비고: 동일 세션 내 번역 결과는 캐시하여 재사용.

## 6-2. Playing API 준비 상태(클라이언트)
- 호출 로직/모델 준비 파일:
  - API: `lib/api/endpoints/roleplay_api.dart`
  - Facade: `lib/api/suda_api_client.dart`
  - DTO: `lib/models/roleplay_models.dart`
- DTO (최소 필드, 추후 확장 가능):
  - `RoleplaySessionRequestDto`, `RoleplaySessionDto`
  - `RoleplayUserMessageRequestDto`, `RoleplayUserMessageResponseDto`
  - `RoleplayAiMessageDto`, `RoleplayNarrationDto`
  - `RoleplayResultDto` (6-9 Result 조회 응답)
- 응답 모델은 **최소 필드 기준**으로 구성되어 있으며, 기능 진행 중 확장 가능.

## 6-3. Playing API 예외 처리 지침
- **세션 초기화** (`POST /v1/roleplay-sessions`)
  - 500: Opening -> Playing 전환 금지. 마이크 권한 체크 이후 처리.
  - 현행 UX: "Cannot start roleplay" 토스트 노출 후 Opening에 머무름.
- **사용자 텍스트/음성 입력, AI 응답, 나레이션, 힌트, 번역**
  - 404: 서버에서 세션 유실로 판단. "Roleplay Session Not Found" 얼럿 후 Overview 복귀.
- **사용자 텍스트/음성 입력**
  - 400: 유의미한 입력 없음. AI 말풍선 단계로 진행하지 않고 사용자 입력 재대기.
- **AI 응답, 나레이션**
  - 202: 50ms → 150ms → 300ms 대기 후 재호출. 최대 3회까지. 최종 실패 시 디버그 로그 + "Cannot Process Roleplay" 얼럿 후 Overview 복귀.
  - 500: 50ms → 150ms → 300ms 대기 후 재호출. 최대 3회까지. 최종 실패 시 디버그 로그 + "Server Error" 얼럿 후 Overview 복귀.
- **힌트, 번역**
  - 500: 해당 프로세스 취소(버튼 비활성화 해제 등). 추가 유저 인터렉션 없음.

## 6-4. Playing UX 흐름/턴 전환 규칙
- **말풍선/나레이션 영역**
  - AI 말풍선: 좌측, AI 아바타 아이콘과 함께 노출.
  - 나레이션: 중앙 영역 노출. 미션 여부에 따라 디자인 변경(구현 완료: 미션 시 Mission 배지·강조 색상).
  - 사용자 말풍선: 우측, 텍스트 박스만 노출(이미지 없음).
  - 사용자 말풍선은 서버 응답 수신 즉시 노출(타이핑 효과 없음).
  - 신규 요소가 푸터에 가려질 수 있는 경우, 노출 직전에 해당 요소만큼 부드럽게 스크롤 이동 후 표시.
- **턴 전환 기준**
  - 사용자 말풍선: user-message API 호출 직후 노출(텍스트/오디오 공통).
  - AI 말풍선: user-message 응답 직후 즉시 AI 응답 조회 호출.
  - AI 말풍선 노출은 TTS 준비 후 시작하며, 타이핑 속도는 음성 재생 속도와 동기화.
  - 나레이션 API는 AI 말풍선 노출 시작 시점에 즉시 호출.
  - AI 말풍선 타이핑 종료 시 나레이션을 500ms fade-in으로 노출한다.
  - 나레이션 fade-in 시작 시점에 사용자 턴 활성화(마이크 default, 힌트 활성화, 타이핑 모드면 입력 포커스).
  - 나레이션 응답의 `currentStep`이 존재하면 진행바 단계 업데이트에 반영한다.
- **starter 처리**
  - `RoleplayDto.starter`는 `SudaJson`이며, `key = roleplayRoleId`, `value = 시작 대사`.
  - 사용자 시작: 선택한 role의 id가 `starter.key`와 같으면 사용자 시작으로 판단. 첫 대사를 말하라는 1회성 안내 레이어 노출(본문 중앙 rgb(53,53,53) 배경, h2/body-secondary/흰박스+starter.value, l10n yourTurnFirst/sayLineBelowToStart, 사용자 말풍선 노출 시 해제).
  - AI 시작: 세션 초기화 응답으로 받은 AI 시작 보이스를 사용. Playing 진입 후 500ms 대기 → AI 말풍선 노출 시작 → 즉시 나레이션 호출.
  - AI 시작 메시지 노출: Playing 본문에 AI 말풍선 표시(본문 width 70%). 아바타는 `userRoleDto.avatarImgPath`에 CDN host를 prepend, 텍스트는 `starter.value` 사용. 음성 길이에 맞춰 타이핑 속도 조절.
  - AI 시작 보이스 처리: `aiSoundCdnYn == "Y"`이면 CDN host를 prepend해 재생, 아니면 `aiSoundFile`(byte[]) 재생.
- **나레이션/미션 표기**
  - 나레이션 텍스트가 미션 안내인 경우 `missionActiveYn == "Y"`로 판단.
  - 미션 활성 시 강조 색상/태그(구현 완료: Mission 배지·핑크 강조).
- **번역 index 규칙**
  - AI/사용자/나레이션 모두 “요소(element)”로 보고 0부터 순서대로 index 부여.
  - 녹음 중 mock 말풍선은 index 부여 대상이 아님.
- **번역 캐시 범위**
  - 하나의 롤플레이 상태값 생명주기와 동일한 범위로 캐시 유지.
- **힌트 버튼 활성 조건**
  - 사용자 턴이기만 하면 활성화.
  - user-message 관련 API 호출 시작 시점부터 그 외 모든 상태는 비활성화.
- **힌트 버튼 동작**
  - 탭 시 `GET /v1/roleplay-sessions/{sessionId}/hint` 호출 후 응답 텍스트를 힌트 말풍선으로 표시(우측 정렬, 흰색 점선 테두리·투명 배경·흰색 글씨).
  - 한 사용자 턴에서 한 번만 사용 가능(탭 즉시 비활성화, 해당 턴 종료까지 유지).
  - 힌트 말풍선은 실제 user-message(텍스트/음성) 전송 후 사용자 말풍선이 추가되는 시점에 제거.
  - 사용자 턴 활성화 후 녹음 모드에서 3초 동안 녹음 버튼을 누르지 않으면 힌트 아이콘에 500ms fade-in/out 깜빡임 효과 표시. 녹음 시작·입력 전송·타이핑 모드 전환 시 깜빡임 해제.
- **입력 모드 전환**
  - 녹음 모드 기본. 좌측 하단 아이콘으로 전환.
  - 녹음 모드: 키보드 아이콘 표시.
  - 타이핑 모드: 마이크 아이콘 표시.
- **입력 UI 활성화**
  - 비활성화된 힌트 버튼, 마이크 버튼, 텍스트 입력창은 나레이션 노출 후 다시 활성화.
  - 사용자 안내 메시지(구현 완료: holdMicrophoneToSpeak, 500ms 미만 녹음 안내 등).
  - 사용자 턴에서 500ms 미만 녹음 시 처리하지 않고 안내 문구를 2초 노출 후 500ms fade-out 처리.
  - 미션 성공/실패 처리: 직전 나레이션이 미션 활성(`missionActiveYn == "Y"`)인 경우에만 user-message 응답의 `missionCompleteYn`으로 success/fail 판정.
- **타이머/백그라운드 처리**
  - 사용자의 첫 말풍선 노출 시점부터 duration 타이머 시작(1초 단위 감소, 클라이언트 구현 완료).
  - 앱이 백그라운드로 이동했다가 복귀 시, 시작 시각과 복귀 시각 차이가 너무 크면 롤플레이 중단.
  - 실제 시작시간 대비 현재 시간이 1시간을 넘으면 무효 처리(백그라운드 체크 로직).
  - 중단 시 서버 종료 처리 API 미구현(서버 타이머에 의존). 사용자 안내 후 Overview 복귀.
- **오디오 재생 실패**
  - 기존 웹서비스에서 실패 사례가 없어 별도 대응 없음.

## 6-6. Playing 헤더 진행 표시
- 헤더에 duration 아래로 progress 영역을 추가한다. (gap 10 → progress(height 18) → gap 10)
- 진행 바: height 3, 배경 `#635F5F`, 진행 `#FFAAE1`, 양끝 radius 처리.
- 진행 단계는 `scenarioFlow.size()` 기준이며, `n = size - 1`.
- 미션 아이콘은 `RoleplayMissionDto.scenarioFlowIndex` 위치에 배치한다.
- 아이콘: `mission_ready.png`, `mission_succeeded.png`, `mission_failed.png` (height 18, 비율 유지, 바 중앙 관통 배치).
- **UI 업데이트 함수(PlayingScreen 내부)**:
  - 단계 진행: `_setProgressToStep(int stepIndex)` 호출
  - 미션 성공: `_setMissionSuccess(int stepIndex)` 호출
  - 미션 실패: `_setMissionFailed(int stepIndex)` 호출

## 6-7. Playing 하단 푸터 영역
- footer 구조: **서비스메시지 영역(높이 24)** + **입력 영역(녹음/타이핑 전환)** + **하단 아이콘 영역(높이 40)**.
- 서비스메시지 영역은 `body-secondary`(bodyMedium) 텍스트를 공통으로 노출한다.
- 하단 아이콘 영역:
  - 좌측 토글(키보드/마이크)과 우측 전구 아이콘을 배치한다.
  - 각 아이콘의 터치 영역은 40x40, 토글 아이콘 크기는 30x30으로 확장한다.
- **녹음 영역(Recording)**:
  - 높이 120.
  - 중앙에 녹음 버튼을 표시하고 pressed 상태에서 좌측 "Cancel" 텍스트를 노출한다.
  - 녹음 버튼 상태: default/hover/pressed/loading/disabled.
  - pressed 상태에서 좌측으로만 드래그 가능하며, Cancel 중앙 지점 통과 시 취소 힌트를 제공한다.
  - 드래그 경로 안내 화살표는 16x16 아이콘 3개를 gap 5로 고정 배치하고, 우→좌로 흐르는 그라데이션 애니메이션을 적용한다.
- **타이핑 영역(Typing)**:
  - 서비스메시지 영역 아래에 gap 10, 입력 영역(높이 44), 하단 gap 10 구성.
  - 입력 영역: 배경 `#353535`, 좌우 반원형 radius, placeholder `"Type your message ..."` 또는 비활성 시 `"Wait for your turn ..."`.
  - Send 버튼: 44x44 원형 배경(`#353535`)에 `icons/send.png` 24x24 중앙 배치.
- **제어 함수(PlayingScreen 내부)**:
  - 녹음 상태 전환: `_setMicState(_MicButtonState next)` 및 `onPressStart/onPressEnd/onPressCancel`.
  - 타이핑 전송: `_handleSend()` (전송 시 입력 초기화 후 2초 비활성 → 활성).

## 6-8. Playing 헤더 우측 속도 슬라이더
- 닫기(X) 버튼이 있는 경우 우측 상단에 kebab 아이콘(`icons/kebab.png`)을 배치한다.
  - 아이콘 24x24, 터치 영역 40x40, top/right 16.
- kebab 토글 시 우측에서 슬라이더 패널이 슬라이드 인/아웃 된다.
  - 패널 크기: 56x230, 배경 `#8C8C8C` 50% 투명, 상/하단 반원형 radius.
  - 패널 상단은 헤더 바로 아래(본문 상단 마진 기준)에 맞춘다.
- 슬라이더 구성:
  - 레일: 흰색 width 4, 상단 `1.5x`, 하단 `0.7x` (body-caption, 흰색).
  - 핸들: 흰색 원 24x24.
  - 4단 스텝 고정(상단→하단): 150 / 120 / 100 / 70.
  - 사용자가 손을 떼면 가장 가까운 스텝으로 스냅.
- 초기값: `userDto.metaInfo` 중 `RP_SPEED_RATE` 값을 사용하며, 실패 시 100.
- 변경 즉시 API 호출: `PUT /v1/users/speed-rate?speedRate=...` (에러 무시).

## 6-5. 나레이션 resultId 기반 종료/분기 규칙
- narration 응답에 `resultId`가 포함되면 **roleplay 중단**으로 처리한다.
- `resultId == 0`: roleplay 진행 실패(결과지 없음). 안내 메시지 후 Failed 스크린으로 이동.
- `resultId > 0`:
  - 미션 성공률 100%: Ending 스크린 → Result 스크린
  - 그 외(사이값): Ending 없이 Result 스크린
  - Result 스크린 연결 시 `resultId` 값을 유지해야 한다.
- `resultId == null`: roleplay 진행 계속. 사용자 입력 대기 상태로 복귀.

**Playing 화면 구현(UX)**
- 종료 안내 메시지는 서비스메시지 영역에 **색상 `#0CABA8`**, **fade-in**으로 노출하며 **3초** 노출 후 해당 스크린으로 전환.
- **1/3) resultId == 0**: l10n `roleplayEndedFailed` 노출 → 3초 후 Failed 스크린으로 전환.
- **2/3) resultId > 0 이고 n개 미션 전부 완수 아님**: duration이 00:00이면 `roleplayEndedTimesup`, 아니면 `roleplayEndedComplete` 노출. result 선조회·캐시 후(3초와 병렬, 캐시 완료까지 대기) Result 스크린으로 전환.
- **3/3) resultId > 0 이고 n개 미션 전부 완수**: `roleplayEndedEnding` 노출. result 선조회·캐시 후(동일) Ending 스크린으로 전환.
- **미션 달성 여부**: Overview 선택 role의 `missionList`로 총 개수, user-message 응답 `missionCompleteYn`으로 단계별 성공/실패 반영. Playing 내부 `_missionStatuses`(success 개수)로 전체 완수 여부 판단.

**l10n 키 (en/ko/pt)**
- `roleplayEndedFailed`: Mission Failed... / 미션을 실패했습니다... / Missão falhou...
- `roleplayEndedTimesup`: Time has run out... / 시간이 소진되었습니다... / O tempo acabou...
- `roleplayEndedComplete`: Roleplay Completed / 롤플레이를 완료했습니다 / Roleplay concluído
- `roleplayEndedEnding`: Moving to ending... / 엔딩으로 이동합니다... / Indo para o final em breve...

## 6-9. Result 조회 API 및 캐시
- **엔드포인트**: `GET /v1/roleplays/results/{resultId}` (path param만 사용)
- **클라이언트**: `SudaApiClient.getRoleplayResult(accessToken, resultId)` → `RoleplayApi.getRoleplayResult`
- **응답**: `RoleplayResultDto` (id, userId, roleplayId, roleplayRoleId, endingId, chatHistory, completeYn, completedMissionIds, missionResult, starResult, words, goodFeedback, improvementFeedback, likePoint, likePointReceivedYn, star, createdAt, mainTitle, subTitle 등)
- **캐시**: Result/Ending 스크린에서 즉시 노출하기 위해, resultId를 인지한 직후 Playing에서 선조회하여 `RoleplayStateService.setCachedResult(dto)`로 저장. 이후 스크린 전환 시 `RoleplayStateService.instance.cachedResult`로 조회. 캐시가 늦으면 3초가 지나도 캐시 완료까지 대기한 뒤 전환.
- DTO: `lib/models/roleplay_models.dart`의 `RoleplayResultDto`

## 7. 단일 Roleplay 컨텍스트 보관
- 인메모리 서비스로 단일 Roleplay Overview를 보관한다.
- 서비스 파일: `lib/services/roleplay_state_service.dart`
- `sessionId`는 Roleplay 생명주기 동안 공통 상태로 보관하고 종료 시 삭제한다.
- `isUserTurnYn`는 Playing 상태에서 사용자의 입력 가능 여부를 나타내며(`Y`/`N`),
  Roleplay 생명주기 동안 공통 상태로 보관한다.
- **`cachedResult`**: resultId 기반 종료 시 Playing에서 `GET /v1/roleplays/results/{resultId}`로 조회한 `RoleplayResultDto`를 `setCachedResult(dto)`로 저장. Ending/Result 스크린에서 `cachedResult`로 즉시 표시. `clear()` 시 함께 제거.
- 흐름/수명 현행 구현 완료(필요 시 보완)

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
- **Failed Report 스크린**:
  - `lib/screens/roleplay/failed_report.dart` (RoleplayFailedReportScreen, Sub Screen). 롤플레이 스캐폴드 적용.
  - 용도: Failed 화면에서만 진입, 사용자가 느낀 불편함 수집. Failed 화면 "Report" 텍스트 탭 시 `RoleplayRouter.pushFailedReport()`로 진입 (SubScreenRoute).
  - Android 백버튼 또는 X 버튼 시 Failed로 복귀 (pop). 본문/푸터는 초기화 상태(플레이스홀더).
- **resultId 기반 종료 분기 및 Result API·캐시**:
  - Playing에서 narration `resultId` 수신 시 3분기 처리: resultId==0 → Failed, resultId>0·미션 일부 완수 → Result, resultId>0·미션 전부 완수 → Ending.
  - 서비스메시지 영역에 종료 안내 메시지 색상 `#0CABA8`, fade-in, 3초 노출 후 해당 스크린 전환.
  - `GET /v1/roleplays/results/{resultId}` API 추가, `RoleplayResultDto` 및 `RoleplayStateService.setCachedResult/cachedResult`로 Result/Ending 진입 전 캐시. 3초와 캐시 완료를 함께 대기 후 전환.
  - Ending 전환 확정 시(미션 전부 완수) Playing에서 role.endingList 첫 요소의 `imgPath`에 CDN host prepend하여 이미지 preload.
  - l10n: `roleplayEndedFailed`, `roleplayEndedTimesup`, `roleplayEndedComplete`, `roleplayEndedEnding` (en/ko/pt) 추가.
- **Ending 스크린 및 Result 별점 API**:
  - Ending 스크린: 닫기 버튼 없음. RoleplayEndingDto(role.endingList 첫 요소) 기반 title/content/이미지. 이미지 있으면 1.5x→1x 2초 축소 후 80% 검정 레이어·콘텐츠 fade-in; 없으면 바로 레이어·콘텐츠. 상단 50% title+content, 하단 50% endingHowWas+별 5개(40×40 gap 5)+Next 버튼. Next 탭 시 Next 버튼 텍스트 fade-out과 동시에 버튼에서 #0CABA8 풍선이 부푸는 모양으로 전체 화면 덮는 애니메이션(2s) 후 Result 스크린 전환. `PUT /v1/roleplays/results/{rpResultId}?star={star}` 호출(응답 무시), star=선택 별 개수(0~5).
- Result 스크린: 박스레이어에 별점·mainTitle·subTitle 순차 노출 후 박스 축소. 본문레이어: like_at_result·likePoint·Mission(missionResult 아이콘)·Words·Lv 프로그레스바(getUserProfile)·Good Points·To Improve·Got it! 버튼(Overview 이동). `.docs/CONTEXT_SCREEN.md` §17 참조.
  - `PUT /v1/roleplays/results/{resultId}?star={star}`: RoleplayApi.updateRoleplayResultStar, SudaApiClient.updateRoleplayResultStar. 응답 무시.
  - l10n: `endingHowWas`, `endingNext` (en/ko/pt) 추가.
- **홈 화면 카테고리별 롤플레이 목록 추가**:
  - `marquee` 패키지 도입으로 흐르는 타이틀 텍스트 구현
  - `GET /v1/home/roleplays/all` 및 `GET /v1/home/roleplays` API 연동
  - 카테고리별 가로 스크롤 리스트 및 레이지 로딩(Lazy Loading) 페이징 구현
  - 30% 너비 썸네일, radius 10, 음영 박스 오버레이 타이틀 적용
  - 카테고리명(100px) 및 썸네일 리스트에 Shimmer 로딩 스켈레톤 적용
