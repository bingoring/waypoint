---
artifact: domain-entities
build-spec: lotto
status: DRAFT
updated: 2026-10-14
---

# Domain & Entities — 로또

## 1. 엔티티

| 엔티티 | 필드 | 영속성 |
|---|---|---|
| `Game` | `List<int> numbers` (6개, 오름차순, 1~45, 중복 없음) | — |
| `GenerateOptions` | `int games`(1~5), `Set<int> fixed`(≤5), `Set<int> excluded` | 마지막 값 `app.lotto.options` |
| `Draw` | `int round`, `List<int> numbers`(6), `int bonus`, `DateTime date` | 에셋·원격 |
| `SavedTicket` | `String id`, `int targetRound`, `List<Game> games`, `DateTime savedAt`, `TicketSource source`(`random`·`custom`·`stats`) | `app.lotto.tickets` (JSON 배열, 최근 200개) |
| `TicketResult` | 게임별 `Prize?` + 일치 번호 | 계산값 |
| `StatsUnlock` | `String date`(KST `yyyy-MM-dd`) | `app.lotto.statsUnlockedOn` |

## 2. 열거형

| 이름 | 값 |
|---|---|
| `Prize` | `first`(6) · `second`(5+보너스) · `third`(5) · `fourth`(4) · `fifth`(3) |
| `TicketSource` | `random` · `custom`(고정·제외 사용) · `stats` |

## 3. 데이터 형식

- `assets/draws.json`: `[[round, n1, n2, n3, n4, n5, n6, bonus, "yyyy-MM-dd"], ...]` (회차 오름차순).
- Remote Config `app_lotto_draws_v1`: 같은 형식의 JSON 문자열, 에셋 이후 회차만. 기본값 `"[]"`.

## 4. 공 색 (화면 표시)

1~10 노랑 · 11~20 파랑 · 21~30 빨강 · 31~40 회색 · 41~45 초록 (동행복권 용지 색 구간, `2차 자료`). 색값은 앱 테마 토큰과 별개 상수.
