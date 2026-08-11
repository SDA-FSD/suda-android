# CONTEXT_HISTORY — 최근 작업 메모

사실 기준이 아님. 현행은 `CONTEXT.md`. 오래된 이력: `CONTEXT_HISTORY_ARCHIVE.md`. 신규 메모는 이 파일 상단에.

---

- **docs 경량화(2026-08-11):** FPM URL → `CONTEXT_FPM_CUSTOM_URL.md`. `CONTEXT_APPLE.md` 삭제(시뮬·실패표는 `CONTEXT.md` §2). `CONTEXT_IOS.md`는 남은 이슈만. S1은 한 줄 요약. HISTORY 아카이브 분리.
- **Speech Feedback 펼침 TTS(2026-08-11):** `GET …/feedbacks/{rpMsgId}/audio`. 펼침 허용 시 로딩 스피너 후 펼침+재생, 실패 시 펼침만.
- **Change Plan 월→연 ONLY + WITHOUT_PRORATION(2026-08):** 월간 구독자만. `ReplacementMode.withoutProration`.
- **Opening 마이크(2026-08):** 자동 재개 없음. Start→status/request→영구거부 시 설정 안내. `PERMISSION_MICROPHONE=1`.
- **Sign in with Apple(2026-07):** `POST /v1/auth/apple`. iOS local/dev/prd, AOS dev/prd. local·stg AOS 미지원.
- **iOS Google Sign-In 이원화:** non-prod 558349 / prd 841694. plist 빌드 복사. `getInitialMessage` 2초 timeout 유지.
- **Speech Feedback 잠금:** `feedbackLockedYn`. Y→Paywall, N→펼침. View Chat은 feedback null이면 버튼 없음.
- **에너지 simple/detail 분기·Playing 소비:** simple은 배지/상태, detail은 팝업. 발화 처리마다 -1.
- **Home v2 / Series Overview:** `GET /v2/home/contents`, 썸네일 → Series Overview.
