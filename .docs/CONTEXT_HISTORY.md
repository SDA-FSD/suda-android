# CONTEXT_HISTORY — 최근 작업 메모

사실 기준이 아님. 현행은 `CONTEXT.md`. 오래된 이력: `CONTEXT_HISTORY_ARCHIVE.md`. 신규 메모는 이 파일 상단에.

---

- **Other User Profile(2026-09-22):** Ranking 포디움·4위+ 리스트의 남 이미지/이름 탭 → SubScreen `OtherUserProfileScreen` (`/profile/{userId}`). `GET /v1/users/{userId}/profile`. 친구 알약 Friends/Requested/Add Friend. INCOMING_PENDING도 Add Friend POST(역방향=수락). REJECTED·409 `FRIEND_REQUEST_COOLDOWN`는 스토킹 팝업. 레벨바·Saved/History 없음. Neighbors/Achievements는 타이틀 유지, 0개면 안내 문구.

- **Profile GNB inset(2026-09-22):** 본문 스크롤 `bottom: GnbBar.contentHeight`. Saved 마지막 페이지 50 스페이서 제거.

- **Achievements(2026-09-22):** Progress 탭 Neighbors 아래 주간 1·2·3위 메달 1행. `GET /v1/users/progress` `achievements`. n은 RANKED distinct periodId. 달성 최근순, Claim 없음, 미해금 place 순. 칸·팝업 모두 탭. 미해금 흑백(팝업 포함). 그리드 `x n`은 0 숨김, 팝업은 `x n`(0 포함).

- **Lv Progress(2026-09-22):** Progress 탭 streak/words와 Neighbors 사이 레벨업 바. `GET /v1/users/progress`에 streak/words/`progressPercentage`/R/`claimableCharacterRewardId`/Neighbors. my-profile은 헤더만. 선물 탭 → `POST /v1/users/character-rewards/claim`(LEVEL_UP, like 없음). RANKED URI 유지.

- **SUDA Neighbors(2026-09-22):** Progress 탭 streak/words 아래 수령 초상화. 지금은 `GET /v1/users/progress` `claimedCharacters`. Epic→Rare→Normal, 같은 rarity는 최근 수령. `duplicatedYn!=Y`. 빈 목록은 70 높이 안내 문구.

- **DEFAULT 프로필 색(2026-09-22):** 피커에서 초록 `#03ABA8` 제거. `1`…`4` = `#FFB700`/`#FFAAE1`/`#B286EB`/`#054544`. 빈 imgPath·무효 value 기본은 노랑. 이미 저장된 `DEFAULT:03ABA8`은 hex 그대로 표시.

- **profileImgUrl 제거(2026-09-22):** 필드·Google picture upsert·`DELETE /v1/users/profile-img`/`PUT .../profile-img/default` 삭제. Account 리셋은 `PUT` `DEFAULT`/`1`. 빈 `imgPath`는 클라 1번 노랑 `#FFB700`. 배포 후 `ALTER TABLE user DROP COLUMN profile_img_url`.

- **프로필 imgPath type(2026-09-22):** `DEFAULT|NORMAL|RARE|EPIC`. 저장 `{TYPE}:{path}`. Unboxing Set as Profile rarity type + GET users. GNB/랭킹 `_150`. 구독 테두리 안 rarity border 5.

- **Reward Unboxing 3단계 연출(2026-09-22):** 테스트 UI 제거. 선정→확정→해금. `characterName` DTO. `CharacterRarityFrame`. 마지막 Set as Profile(NORMAL|RARE|EPIC)/View Character/X.


- **에너지 팝업 Enable Notifications(2026-08-11):** detail `showEnablePushFreeChargeYn` + screen home/opening/opening_insufficient. impression `enable_push_free_charge`. 완료 시 팝업 경로만 토스트 + 제거 애니.
- **docs 경량화(2026-08-11):** FPM URL → `CONTEXT_FPM_CUSTOM_URL.md`. `CONTEXT_APPLE.md` 삭제(시뮬·실패표는 `CONTEXT.md` §2). `CONTEXT_IOS.md`는 남은 이슈만. S1은 한 줄 요약. HISTORY 아카이브 분리.
- **Speech Feedback 펼침 TTS(2026-08-11):** `GET …/feedbacks/{rpMsgId}/audio`. 펼침 허용 시 로딩 스피너 후 펼침+재생, 실패 시 펼침만.
- **Change Plan 월→연 ONLY + WITHOUT_PRORATION(2026-08):** 월간 구독자만. `ReplacementMode.withoutProration`.
- **Opening 마이크(2026-08):** 자동 재개 없음. Start→status/request→영구거부 시 설정 안내. `PERMISSION_MICROPHONE=1`.
- **Sign in with Apple(2026-07):** `POST /v1/auth/apple`. iOS local/dev/prd, AOS dev/prd. local·stg AOS 미지원.
- **iOS Google Sign-In 이원화:** non-prod 558349 / prd 841694. plist 빌드 복사. `getInitialMessage` 2초 timeout 유지.
- **Speech Feedback 잠금:** `feedbackLockedYn`. Y→Paywall, N→펼침. View Chat은 feedback null이면 버튼 없음.
- **에너지 simple/detail 분기·Playing 소비:** simple은 배지/상태, detail은 팝업. 발화 처리마다 -1.
- **Home v2 / Series Overview:** `GET /v2/home/contents`, 썸네일 → Series Overview.
