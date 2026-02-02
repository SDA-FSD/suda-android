# RP_SPEED_RATE 슬라이더 초기값 미적용 원인 분석

## 단계별 분석

### 1단계: RoleplayStateService.user 세팅 시점
- **위치**: `lib/screens/home.dart` 210–213라인 `_navigateToRoleplayOverview()`
- **동작**: 홈에서 롤플레이 탭 시 **한 번만** `RoleplayStateService.instance.setUser(widget.user)` 호출 후 `pushOverview`
- **결과**: 이 시점에 `user`(Main의 `_user`, getCurrentUser 응답)가 서비스에 들어감. `metaInfo`에 `RP_SPEED_RATE`가 있으면 그대로 들어가 있음.

### 2단계: Main의 _user 출처
- **위치**: `lib/main.dart` – 스플래시 후 `getCurrentUser`(129라인), 로그인 후 `getCurrentUser`(205라인), `onUserUpdated`(330라인)
- **동작**: `GET /v1/users` 응답을 `UserDto.fromJson`으로 파싱. `metaInfo`는 `List<SudaJson>`(key/value)로 파싱됨.
- **결과**: 서버가 `metaInfo`에 `RP_SPEED_RATE`를 넣어 주면 `_user.metaInfo`에 존재. Main → Home에 `user: _user`로 전달.

### 3단계: Overview 진입 후 _loadOverview
- **위치**: `lib/screens/roleplay/overview.dart` – `initState()`(46라인)에서 `_loadOverview(_currentRoleplayId)` 호출
- **동작**: `_loadOverview` 내부 77라인에서 **`RoleplayStateService.instance.clear()`** 호출 후 `getRoleplayOverview` → `setOverview`만 수행
- **결과**: `clear()`가 **`_user = null`** 포함 전체 상태를 초기화함. `setUser`는 Overview에서 다시 호출되지 않음.

### 4단계: Playing 진입 시 _initializeSpeedRate
- **위치**: `lib/screens/roleplay/playing.dart` – `initState()`(85라인)에서 `_initializeSpeedRate()` 호출
- **동작**: `RoleplayStateService.instance.user?.metaInfo`에서 `RP_SPEED_RATE` 검색 → `user`가 이미 **null**이므로 `metaInfo`도 null, `initialRate`는 100 유지
- **결과**: `_speedIndex`는 항상 100에 해당하는 인덱스(2)로만 설정됨.

### 5단계: 결론
- **원인**: Home에서 `setUser(widget.user)`로 user를 세팅한 **직후**, Overview가 push되고 `_loadOverview`가 실행되면서 **`clear()`가 user까지 지움**. 이후 Overview/Opening/Playing 구간에서 user를 다시 세팅하지 않으므로, Playing의 `_initializeSpeedRate()` 시점에는 **user가 null**이라 `RP_SPEED_RATE`를 읽지 못함.
- **수정 방향**: Overview의 `_loadOverview()`에서 `clear()` 호출을 제거하거나, `clear()`에서 `_user`는 제외하거나, `clear()` 후 곧바로 `setUser(현재 user)`를 다시 호출하도록 해야 함. (user 출처는 Home과 동일한 Main의 _user를 유지하려면, clear 전에 user만 별도 보관했다가 clear 후 setUser(보관한 user) 호출 등)
