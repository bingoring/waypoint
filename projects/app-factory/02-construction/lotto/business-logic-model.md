---
artifact: business-logic-model
build-spec: lotto
status: DRAFT
updated: 2026-10-14
---

# Business Logic Model — 로또

## 1. 워크플로

### 1.1 생성
옵션(게임 수·고정·제외) → 게임마다 `fixed ∪ sample(candidates − fixed − excluded, 6 − |fixed|)` → 정렬 → 묶음 내 중복이면 다시 → 결과 표시 →
`key_action{action: generate_numbers, games, source}`. 두 번째 생성부터 `onTransition('interstitial_generate')`를 먼저 호출하고 광고가 닫힌 뒤 새 결과를 보인다(L-ADS-1).

### 1.2 저장
결과 묶음 → `SavedTicket(targetRound = currentSalesRound(now))` → 이력 맨 앞에 추가(200개 제한) → `save_numbers` 이벤트 → `positiveMoment()`.

### 1.3 당첨 확인
이력 화면 진입 시 각 티켓의 `targetRound` 당첨 데이터를 찾아 게임별 등수 계산(L-WIN). 1~5등이 있으면 `check_result{prize}` 이벤트(티켓당 1회).

### 1.4 통계
진입 → 잠금 확인(L-STAT-4) → 잠김이면 보상형 버튼 → `showRewarded('rewarded_analysis')` → `grants`면 오늘 날짜 저장 → 열림:
최근 N회 번호별 출현 횟수 막대(1~45), 많이 나온 6개·적게 나온 6개, "통계로 생성" 버튼(L-STAT-2). `open_stats` 이벤트.

### 1.5 당첨 데이터 갱신 (자동, 매주 — 실패 시 오너 수동)
자동: `lotto-draws.yml`(일 00:30 KST = 토 15:30 UTC, 실패 시 일 09:00 KST 재시도) → `tool/fetch_draws.dart --latest`(`GET /lt645/selectPstLt645InfoNew.do?srchDir=center&srchLtEpsd=<다음 회차>`) →
L-DATA-2·회차 연속성·추첨일이 토요일인지 검증 → Remote Config REST API(서비스 계정)로 `app_lotto_draws_v1` 갱신. 이미 있으면 아무것도 하지 않는다(멱등).
수동(비상):
`dart run tool/add_draw.dart <회차> n1 … n6 <보너스> [날짜]` →
`firebase remoteconfig:get` → `app_lotto_draws_v1` JSON에 회차 추가(검증 L-DATA-2, 회차 연속성) → `firebase deploy --only remoteconfig`.
앱은 다음 실행에서 활성화한다(1-2 §5). 새 버전 출시 때는 원격 회차를 에셋에 합치고 원격 값을 비운다.

## 2. 알고리즘

```
salesRound(nowUtc):
  kst = nowUtc + 9h
  sat = 이번 주 토요일(kst 날짜 기준, 토요일이면 오늘)
  if kst ≥ sat 20:00: sat += 7일
  return (sat − 2002-12-07) / 7일 + 1

weightedPick(weights[1..45], k, rng):   // 비복원
  repeat k: r = rng.nextDouble() * Σw; 누적합으로 번호 선택; 그 번호 가중치 0
```
