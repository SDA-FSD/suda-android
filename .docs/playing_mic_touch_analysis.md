# 녹음 버튼 터치 동작 분석 보고

현재 `lib/screens/roleplay/playing.dart` 기준으로, 터치 액션이 매끄럽지 못한 원인을 단계별로 정리한 내용입니다.

---

## 1. 터치 후 녹음 시작까지의 딜레이 (문제 1)

### 원인

- **TapDown** → `_handleMicTapDown()` → `_setMicState(pressed)` → **동기적으로** `setState`로 `_micState = pressed` 반영 후, **비동기** `_beginRecording()` 호출(await 없음).
- `_beginRecording()` 내부:
  1. `await _recorder.hasPermission()` (플랫폼 호출, 수십 ms~수백 ms 가능)
  2. `await _recorder.start(...)` (실제 녹음 시작)
  3. **그 다음** `_isRecording = true`, `_showRecordingEntry()` (mock 말풍선)

즉, “녹음 시작”으로 사용자가 인지하는 시점(mock 말풍선·녹음 중 UI)은 **권한 체크 + recorder.start()** 가 끝난 뒤에야 오므로, 기기/상태에 따라 100~300ms 이상 느껴질 수 있음.

### 요약

| 구분 | 내용 |
|------|------|
| 원인 | `_beginRecording()` 전체가 async이고, `_isRecording`/mock 말풍선은 그 **끝**에서만 설정됨 |
| 영향 | 권한·start 지연이 그대로 “녹음 시작 딜레이”로 체감됨 |
| 관련 코드 | `_setMicState()` → `_beginRecording()` (623~636행) |

---

## 2. 터치 직후 이미지(pressed) 변화의 시간차 (문제 2)

### 원인

- `_buildMicButton()`(1211행~)에서 **AnimatedContainer** 사용:
  - `duration: const Duration(milliseconds: 80)`
  - `size`·`asset`(default ↔ pressed) 변경 시 **80ms 애니메이션**으로 전환.

그래서 TapDown 직후 `_micState`는 바로 `pressed`로 바뀌어도, **화면에 보이는 버튼 크기/이미지**는 80ms 동안 서서히 변함. “눌렀다”는 느낌이 즉각적이지 않음.

### 요약

| 구분 | 내용 |
|------|------|
| 원인 | default → pressed 전환에 **AnimatedContainer 80ms** 적용 |
| 영향 | 터치 직후 pressed 이미지/크기 변화가 80ms 뒤에 완료되는 것처럼 보임 |
| 관련 코드 | `_buildMicButton()` 내 `AnimatedContainer(duration: 80)` (1226행) |

---

## 3. 터치하고 있는 도중 터치가 끊기는 경우 (문제 3)

### 원인

- **TapDown** 시 `setState(pressed)` 한 번으로도 **위젯 트리 전체**가 다시 빌드됨.
- 녹음 버튼 구조:  
  `Column` → `SizedBox` → `LayoutBuilder` → `Stack` → … → `GestureDetector` → `_buildMicButton()`
- `RoleplayPlayingScreenState`에서 `setState`가 호출되면 이 **build 전체**가 다시 실행되고, 그 안의 **GestureDetector 인스턴스가 새로 생성**됨.
- Flutter 제스처 인식은 “같은 recognizer 인스턴스” 기준으로 터치를 추적하므로, **빌드로 인해 GestureDetector가 바뀌면** 진행 중이던 제스처가 끊길 수 있음 → **TapCancel** 또는 Pan 중단 발생.
- 특히 **PanUpdate**에서 조건부 setState를 쓰고 있지만, **TapDown·TapUp·TapCancel·PanEnd** 등 다른 이벤트에서의 setState도 동일한 “전체 rebuild”를 유발함.
- 기기/터치 패턴에 따라 **Tap vs Pan** 경합(gesture arena) 결과가 달라지면, “살짝만 움직여도” Pan이 이기고, 그 과정에서 한 번 더 setState가 나가면 터치가 끊기는 현상이 더 자주 나올 수 있음.

### 요약

| 구분 | 내용 |
|------|------|
| 원인 | 터치 관련 모든 setState가 **스크린 전체 rebuild** → GestureDetector 재생성 → 진행 중 제스처 취소 가능 |
| 영향 | 누르고 있는 도중에 터치가 끊기고, TapCancel/중단이 발생해 “가끔만 끊김”처럼 보임 |
| 관련 코드 | `_handleMicTapDown` / `_handleMicPanStart` / `_handleMicTapCancel` / `_handleMicTapUp` / PanEnd → setState, 그리고 그에 따른 build 전체 |

---

## 4. 빠르게 터치하면 pressed 상태가 default로 안 바뀌고 유지됨 (문제 4)

### 원인

- **TapDown** → `_setMicState(pressed)` → `_beginRecording()` **비동기 호출만** 하고 기다리지 않음.
- **TapUp**이 **빠르게** 발생(예: 50~200ms 안에 손을 뗌)하면, 아직 `_beginRecording()`이 끝나지 않아 **`_isRecording`이 여전히 false**인 상태에서 `_finishRecording()`이 호출됨.
- `_finishRecording()`(638행~) 맨 앞:
  - `if (!_isRecording) return;`  
  → 이때 **아무 것도 하지 않고 return** (default 복귀·mock 제거·타이머 정리 등 전혀 없음).
- 그 결과 **`_micState`는 pressed로 그대로** 두고 끝나며, UI도 pressed로 남음.

### 요약

| 구분 | 내용 |
|------|------|
| 원인 | TapUp 시점에 `_isRecording`이 아직 false(녹음 시작 전)인데, `_finishRecording()`이 “녹음 중이 아니면 그냥 return”만 함 |
| 영향 | 짧게 탭한 경우 pressed → default 전환이 일어나지 않고, 버튼이 눌린 채로 고정됨 |
| 관련 코드 | `_finishRecording()` 638–639행 `if (!_isRecording) return;` / `_beginRecording()` 623–636행(비동기 완료 시점에만 `_isRecording = true`) |

---

## 5. UI/구조 측면의 공통 요인

| 항목 | 내용 |
|------|------|
| **setState 범위** | 녹음 버튼만 바꿀 때도 **RoleplayPlayingScreen 전체**가 rebuild됨. 대화 목록 등이 길수록 빌드 비용이 커지고, 그만큼 프레임 지연·제스처 끊김이 나기 쉬움. |
| **GestureDetector 생명주기** | 매 build마다 새 인스턴스가 만들어져, “같은 터치”가 중간에 다른 recognizer로 이어지지 못하고 취소될 수 있음. |
| **Tap vs Pan 경합** | Tap과 Pan이 같은 영역을 쓰므로, 기기·터치 특성에 따라 “살짝만 움직여도” Pan으로 넘어가거나, 그 반대로 Tap만 인식되는 등 결과가 달라질 수 있음. |
| **비동기와 상태 불일치** | “눌렀다”는 시각/녹음 상태(`_micState` / `_isRecording`)가 서로 다른 시점에 바뀌어, 빠른 탭·느린 기기에서 4번 같은 논리 오류가 두드러짐. |

---

## 6. 수정 시 권장 우선순위

1. **문제 4 (빠른 터치 시 pressed 유지)**  
   - `_finishRecording()`에서 `!_isRecording`일 때도 **default로 복귀**하도록 처리 (최소한 `_setMicState(default)`, 필요 시 mock/타이머 정리).  
   - 즉, “녹음이 시작되기 전에 손을 뗀 경우”를 명시적으로 처리.

2. **문제 2 (pressed 이미지 지연)**  
   - default ↔ pressed 전환 구간만 **AnimatedContainer duration을 0 또는 매우 짧게**(예: 0~30ms) 주거나, 이 구간만 즉시 전환하도록 분기.

3. **문제 1 (녹음 시작 딜레이)**  
   - `_beginRecording()`에서 “녹음 시작” 체감 시점을 앞당기기:  
     예) `_isRecording = true`·`_showRecordingEntry()`를 **먼저** 호출하고, `hasPermission()`/`start()`는 그 뒤에 실행하고, 실패 시만 롤백.  
   - 또는 최소한 권한은 미리 받아 두는 등, 체감 지연을 줄일 수 있는 구조 검토.

4. **문제 3 (터치 끊김)**  
   - 녹음 버튼을 **별도 StatefulWidget**으로 분리해, 버튼 상태만 그 위젯의 setState로 갱신하면 상위 스크린 전체 rebuild를 줄일 수 있음.  
   - 또는 **Listener** + 수동 드래그/탭 판별로 제스처를 처리해, GestureDetector 재생성 영향을 줄이는 방안 검토.

이 순서로 적용하면, “빠르게 눌렀을 때 pressed로 남는 현상”과 “눌렀다 отпу았을 때의 시각/녹음 피드백”이 먼저 개선되고, 그 다음 터치 끊김·녹음 시작 딜레이까지 단계적으로 다듬을 수 있습니다.

---

## 7. 다른 AI 제안 해결책 분석 (드래그/누르고 있을 때 끊김)

제안 요약:
1. **GestureDetector/Listener는 “버튼 전용 위젯”에 고정**
2. **제스처는 LongPressStart / MoveUpdate / End로 통일**
3. **pressed / cancelling UI는 ValueNotifier + ValueListenableBuilder로만 갱신**
4. **상위 RoleplayPlayingScreen setState는 녹음 제스처 진행 중엔 안 치거나, 버튼을 rebuild에서 분리**

### 우리 코드와의 맞춤 분석

| 제안 | 우리 코드에 맞는지 | 비고 |
|------|-------------------|------|
| **(1) 버튼 전용 위젯으로 분리** | ✅ **맞음** | 지금은 `RoleplayPlayingScreenState.build()` 안에 버튼·GestureDetector가 있어서, `_micState`/`_dragOffsetX` 등만 바꿔도 **전체 화면**이 rebuild되고 **GestureDetector가 매번 새 인스턴스**로 만들어짐. 버튼+제스처를 **별도 StatefulWidget**(예: `_MicButtonArea`)으로 빼면, 그 위젯의 setState만으로 버튼 영역만 다시 그려지고 **상위 스크린은 rebuild되지 않음** → GestureDetector가 제스처 진행 중에 바뀌지 않아 끊김 완화. |
| **(2) LongPressStart / MoveUpdate / End로 통일** | ⚠️ **의도만 맞고, LongPress는 우리 요구와 충돌** | “Tap vs Pan 경합 제거, 하나의 연속 제스처로 통일”이라는 **의도**는 우리 문제(3번)와 일치함. 다만 Flutter의 **LongPress**는 **일정 시간(기본 500ms) 누른 뒤**에야 Start가 발생함. 우리는 **누르는 즉시** pressed 표시·녹음 시작이 필요하므로, **LongPressStart 타이밍이 맞지 않음**. 대안: **Listener**(`onPointerDown` → Start, `onPointerMove` → MoveUpdate, `onPointerUp` → End)로 “누르자마자 시작 + Tap/Pan 경합 없음”을 만드는 쪽이 우리 요구에 더 맞음. |
| **(3) ValueNotifier + ValueListenableBuilder로만 갱신** | ✅ **맞음** | `_micState`(pressed 여부), `_dragOffsetX`, `_isCancelHovered`처럼 **제스처 진행 중에만** 바뀌는 값들을 **ValueNotifier**로 두고, 버튼/취소 UI를 **ValueListenableBuilder**로 감싸면, 이 값 갱신 시 **해당 빌더만** 다시 그려짐. **RoleplayPlayingScreen의 setState는 호출하지 않음** → 상위가 rebuild되지 않아 GestureDetector가 유지되고, 끊김 원인이 제거됨. (녹음 완료·에러 등 “제스처 밖” 상태는 기존처럼 콜백으로 상위에 알리고 상위 setState 유지 가능.) |
| **(4) 상위 setState 안 치거나 버튼을 rebuild에서 분리** | ✅ **(1)·(3)과 동일 내용** | “녹음 제스처 진행 중엔 상위 setState를 안 친다”는 것은 (3)으로 구현 가능. “버튼을 rebuild에서 분리”는 (1) 버튼 전용 위젯 분리로 구현. 둘 다 우리 분석(문제 3, 5)과 같은 해결 방향임. |

### 종합

- **방향성**: “제스처 중에는 상위를 건드리지 말고, 버튼 영역만 갱신한다”는 점이 우리 코드가 갖는 **setState 범위 과다** 문제와 정확히 맞는 해결책임.
- **구현 시 유의**:
  - **(1)+(4)**: 녹음 버튼 + 제스처를 **별도 위젯**으로 분리하고, 그 위젯이 “pressed / 드래그 / 취소 영역” 상태를 가짐.
  - **(3)**: 위 버튼 위젯 **내부**에서만 `ValueNotifier`(예: `offset`, `isCancelZone`) + `ValueListenableBuilder`로 UI 갱신. “녹음 시작/종료/에러”는 콜백으로 `RoleplayPlayingScreen`에 전달해, **필요할 때만** 상위 setState(대화 목록·로딩·서비스 메시지 등).
  - **(2)**: **LongPress 대신 Listener** 사용 권장. `onPointerDown` → pressed + 녹음 시작, `onPointerMove` → offset/취소 영역 갱신(ValueNotifier만 변경), `onPointerUp`/`onPointerCancel` → 녹음 종료/취소 처리. Tap/Pan 경합이 없어서 “살짝 움직였을 때 끊김”을 줄이기 좋음.

---

## 8. 위젯화 이후 드래그 끊김 원인

### 원인 1: Transform.translate offset 미갱신
- `ValueListenableBuilder`가 `_isPressed`만 구독
- `effectiveOffset = isPressed ? _dragOffset.value : 0.0`인데, `_dragOffset` 변경 시 rebuild 없음
- 드래그 중 버튼 위치가 갱신되지 않을 수 있음

### 원인 2: _dragOffset 구독 시 과도한 rebuild
- `Listenable.merge([_isPressed, _dragOffset])`로 두 값 모두 구독하면, pointer move마다 **전체 Stack rebuild**
- `_buildDragArrows`(AnimatedBuilder, ShaderMask, SvgPicture)가 매번 다시 빌드됨 → 무거움
- `_buildButton` 3단계 nested builder도 매번 함께 rebuild

### 해결: Transform.translate만 _dragOffset으로 구독
- `_isPressed` builder: Cancel 텍스트, 화살표 등 구조만
- `_dragOffset` builder: **Transform.translate와 그 자식만** 감싸서 offset만 갱신
- 드래그 중 Cancel·화살표는 rebuild하지 않음
