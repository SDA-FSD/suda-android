# Locale

앱 언어 계약. suda-api·suda-back `.docs/CONTEXT_LOCALE.md`와 같다.

사용자 언어는 meta `LANGUAGE_TAG` 하나. 빈 태그는 없다.

## 누가 쓰나

- **태그 없음**: 기기 로케일. 로그인·약관·`FirstAppLanguageScreen`의 제목, 그리고 선택 언어에 기기 지역을 붙일 때만.
- **태그 있음**: 화면 문구, 동적 콘텐츠 조회, 폰트 팩, 힌트 영어 사용자 판별, 점검 배너, 구독 날짜 표기, 에너지 구매의 포르투갈어 분기. `GET /v1/users`로 받은 `UserDto`의 `LANGUAGE_TAG`를 `LanguageUtil.bind`. 언어 저장 성공 직후에도 같은 GET으로 `_user`를 바꾼다.
- **스토어 가격·통화**는 기기/스토어 로케일. 태그와 무관.

Flutter 화면 로케일: `zh-Hans`·`zh-CN` → `zh_Hans`. `zh-Hant`·`zh-TW`/`HK`/`MO` → `zh_Hant`. `es-419` → `es_419`. 그 외는 primary(`ko-KR` → `ko`).

## 저장

`PUT /v1/users/language-tag?languageTag=`. trim 후 12자 초과, 또는 영문·숫자·하이픈 외면 `400`. Back `POST /api/users/meta`가 Redis `suda:user:{id}`를 갱신한다.

선택지에 지역·스크립트가 있으면 그 코드를 고정 저장한다.

| 선택 | 저장 |
|---|---|
| Português (Brasil) | `pt-BR` |
| Español (Latinoamérica) | `es-419` |
| 简体中文 | `zh-Hans` |
| 繁體中文 | `zh-Hant` |

지역이 없는 선택(`en`,`ko`,`ja`,`fr` …)은 기기 언어가 같을 때만 기기 태그(`ko-KR`). 다르면 언어 코드만(`nl`). 기기 태그가 12자·문자 규칙을 넘으면 언어 코드만.

기기와 같은 항목은 목록 맨 위·선택 상태. `pt`는 Brasil, `es`는 `es-419`, `zh`+Hant/`TW`/`HK`/`MO`는 번체, 그 외 `zh`는 간체. 맞는 항목이 없으면 Continue 비활성.

실패 시 `requestFailed` 토스트 후 그 화면. 성공 후 `ENGLISH_LEVEL`이 없으면 CEFR.

현행 앱의 `POST /v1/users/push-token`은 `pushToken`만 보낸다. 구버전은 `languageTag`가 있으면 같은 메타를 덮어쓴다.

## 서버가 이미 가진 키

- 조회: 태그 원문 → primary → `en`. `ko`/`ko-KR`, `pt`/`pt-BR`은 원문 복사.
- 브리핑 음성·Redis·피드백 TTS의 중국어 키는 `zh-Hans`만. `zh-Hant` 문구는 요청 시 생성되고, 음성은 `en`.
- 푸시 문구는 태그의 언어 코드(`ko-KR` → `ko`). 시간대는 태그 국가 → 언어 → `America/Sao_Paulo`.
