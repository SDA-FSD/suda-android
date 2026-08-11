# FPM 커스텀 URL 패턴

일상 작업은 `.docs/CONTEXT.md` §10-1만 보면 된다. **신규 `SudaHttpClient` 엔드포인트를 추가할 때** 이 문서를 연다.

- **기준점 2026-08-11**: 아래 path를 Firebase Console(dev `api.dev-sudatalk.kr` · prd `api.sudatalk.kr`)에 전부 등록함.
- 이후 추가 시: **이 목록에 없는 path만** 콘솔에 넣고 여기도 갱신.
- `*` = 한 세그먼트. 구체적 패턴을 와일드카드보다 위에. 호스트는 콘솔에서 prefix.
- 앱은 query를 빼고 path 그대로 `HttpMetric`에 올린다.

```
/v1/auth/google
/v1/auth/apple
/v1/auth/refresh
/v1/auth/logout
/v1/latest-version
/v1/purchases/verify
/v2/home/contents
/v2/home/series
/v1/users
/v1/users/profile
/v1/users/profile-img
/v1/users/tutorial
/v1/users/tutorial-shown
/v1/users/first-overview
/v1/users/grant-welcome-gift
/v1/users/agreement
/v1/users/language-level
/v1/users/energy/detail
/v1/users/energy/simple
/v1/users/push-token
/v1/users/push-agreement
/v1/users/speed-rate
/v1/users/feedback
/v1/users/expressions
/v1/users/notification
/v1/users/notification/*/read
/v1/impressions/products
/v1/impressions/subscriptions
/v1/notice
/v1/notice/*
/v1/roleplays/*/overview
/rps2/series/*/overview
/rps2/series/*/best-score
/rps2/sessions
/rps2/sessions/*/translation
/rps2/sessions/*/hint/sound/*
/rps2/sessions/*/hint/sound
/rps2/sessions/*/hint/*
/rps2/sessions/*/user-message/audio
/rps2/sessions/*/user-message/text
/rps2/sessions/*/ai-message/audio
/rps2/sessions/*/finish
/rps2/user-histories
/rps2/user-histories/*/expressions/*/sound
/rps2/user-histories/*/expressions/*
/rps2/user-histories/*/messages/*/audio
/rps2/user-histories/*/feedbacks/*/audio
/rps2/user-histories/*/user-star-rating
/rps2/user-histories/*/report
/rps2/user-histories/*
```
