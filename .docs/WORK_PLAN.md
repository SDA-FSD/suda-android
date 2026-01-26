# 작업 계획서: JWT 갱신/로그아웃 및 deviceId 도입

## 배경/요구사항 요약
- JWT: Access 30분, Refresh 14일, Refresh는 Redis 저장 + rotate
- 앱은 인증/갱신/로그아웃 요청에 `deviceId` 포함
- API
  - `POST /v1/auth/google`
    - Request: `{ "idToken": "google-id-token", "deviceId": "device-unique-id" }`
    - Response: `{ "accessToken": "jwt-access", "refreshToken": "jwt-refresh" }`
  - `POST /v1/auth/refresh`
    - Request: `{ "refreshToken": "jwt-refresh", "deviceId": "device-unique-id" }`
    - Response: `{ "accessToken": "jwt-access", "refreshToken": "jwt-refresh-rotated" }`
    - Error: 400(파라미터 누락), 401(만료/위조/불일치)
  - `POST /v1/auth/logout`
    - Request: `{ "refreshToken": "jwt-refresh", "deviceId": "device-unique-id" }`
    - Response: 200 OK
    - Error: 400(파라미터 누락), 401(만료/위조)

## 범위
- deviceId 생성/보관, 토큰 저장/갱신/로그아웃 플로우 보완
- 갱신 전략(만료 1~3분 전 백그라운드 타이머), 401 처리 1회 시도 후 재시도
- 동시 요청에서 refresh 중복 방지(큐잉/단일화)
- 기존 로직을 면밀히 분석하고, 중복 코드 없이 일원화 유지

## 소규모 작업 단위(단계별)
1. 현행 로직 분석: 로그인/토큰 저장/요청 인터셉트/로그아웃 위치 파악
2. deviceId 생성 및 안전 저장(최초 설치 1회)
3. 토큰 저장 구조 점검 및 refresh 토큰 보관/회전 반영
4. refresh/logout API 추가 및 `deviceId` 포함
5. 갱신 전략 구현: 타이머 기반 백그라운드 refresh
6. 401 처리: refresh 1회 시도 후 원 요청 1회 재시도
7. 동시 요청 큐잉: refresh 중복 방지 및 대기 처리
8. 롤플레이 시작/포그라운드 진입 시 refresh 체크
9. 로그아웃 시 서버 `/v1/auth/logout` 호출 + 로컬 토큰 폐기
10. `.docs/CONTEXT.md` 업데이트(변경된 사실 기준 반영)

## 예상 수정 파일(후보)
- `lib/services/suda_api_client.dart`
- `lib/services/token_storage.dart`
- (현행 분석 후 추가/변경 가능)

## 테스트/검증(예정)
- 토큰 만료 임박 시 자동 refresh 동작 확인
- 401 발생 시 refresh 후 원 요청 재시도 확인
- refresh 동시 요청 시 단일 갱신으로 수렴 확인
- 로그아웃 시 서버 호출 및 로컬 토큰 삭제 확인
