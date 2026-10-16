---
artifact: business-logic-model
build-spec: adaptive
status: DRAFT
updated: 2026-10-16
---

# Business Logic Model — 공통 적응형 난이도 `factory_adaptive`

## 1. 판 하나의 흐름

```
게임: 다음 판 요청(노선 L)
  → Director.next(L)
      ├ 소개할 기믹이 있는가? (A-CUR-4) → 소개 판 반환
      ├ 처음 3판? (A-TGT-5) → target_min
      ├ T = 목표(A-TGT-1~4), 크기 = 상황 신호(A-CTX)
      ├ 미리 만든 판(isolate 결과)이 조건에 맞으면 그것, 아니면 즉시 생성(A-GEN)
      └ 다음 판 미리 만들기를 isolate에 맡김
  → 게임이 판을 플레이
  → Director.report(Outcome)
      ├ MechanicProgress 갱신 → 익힘 판정 (A-CUR-2)
      ├ (켬) Glicko-2 갱신 (A-RATE)
      ├ recent·played·sessionPlayed 갱신, 저장
      └ 분석 이벤트 adaptive_result (A-PRIV-1 범위)
```

`Director`가 패키지의 유일한 진입점이다. 게임은 `next`와 `report`만 부른다.

## 2. 생성 루프 (isolate)

```
for i in 0..gen_candidates:
  if 경과 > gen_budget_ms: break
  req = GenRequest(allowed, fresh ≤ 1, size, seed = base ^ i)
  b = game.generate(rng(seed), req); if b == null: continue
  f = game.measure(b); if !f.solvable: continue        ← A-SOLV-1
  p = predict(f, rating)                               ← A-PRED
  score = |p − T| + 다양성 벌점
best 반환, 없으면 pool.json (A-GEN-3)
```

하품 릴레이의 측정(풀이기)은 툭 2개·승객 10명에서 수천 묶음 × 수십 박자다. 프로토타입 생성기로 판 하나 측정에 수 ms~수십 ms가 걸렸으므로 [추정] 300ms에 수~수십 후보가 가능하다. 실측은 구현 때 하고 예산을 원격 설정으로 맞춘다.

## 3. Glicko-2 갱신 (A-RATE)
표준 Glicko-2(Glickman 2012) 한 경기 갱신. 상대 = 판(`R_L`, RD 50). 결과 점수 = A-RATE-1·2. 갱신 뒤 `|Δrating| ≤ cap`으로 자르고 `rd ≥ 60`.

## 4. 기본 곡선과 스위치 끔
스위치 끔 → `rating`을 1500으로 고정한 것처럼 계산(갱신은 멈추지 않고 저장만, 다시 켜면 이어 씀). 상황 신호 무시. 그 외 흐름은 같다.

## 5. 가상 플레이어 시뮬레이션 (`tool/simulate.dart`, 게임마다)
- **모델:** Rovio CHI PLAY 2020의 가상 플레이어(조사 ⑥) — 실력, 끈기(연패를 견디는 횟수), 지루함(쉬운 판 누적), 실패할 때마다 실력이 조금 오름. 2,000명, 실력 분포는 정규분포.
- **판 결과 모의:** 가상 플레이어의 실력과 판의 「참 난이도」로 승패를 뽑는다. 참 난이도는 예측식과 일부러 다르게 둔다(예측 오차 ±7%p, King 오차 범위) — 보정이 없을 때의 어긋남도 본다.
- **출시 전 확인할 지표:**
  - 판별 실제 승률이 목표 ±5%p 안
  - 기믹 소개 간격, 모든 기믹 해금까지 판 수 분포(중앙값 150판 이상, DECISIONS 기믹 간격)
  - 최대 연패 길이 분포(3연패 이상 비율)
  - 이탈 대리 지표(끈기·지루함 소진)
  - 스위치 끔(고정 곡선)과 켬 비교
- **결과:** `adaptive/sim-<game>-<날짜>.md`에 표로 남기고, 기본 설정값(§3 표)을 그 결과로 정한다.

## 6. 출시 뒤 보정 (`tool/fit_difficulty.dart`)
- 입력: `adaptive_result` 이벤트 내보내기(CSV). Firebase Analytics → BigQuery 연결이 필요하다(미해결 질문 Q1).
- 처리: 판 지표 `f_*` → 이김 여부 로지스틱 회귀(정규화), 기믹별 잔차 확인. 기간은 최근 14일, 판 표본 1,000개 이상일 때만 갱신.
- 출력: 새 `model` JSON → 원격 설정에 올린다(사람이 확인 후). 갱신 기록은 Waypoint에 남긴다.

## 7. 테스트
| 테스트 | 기대 |
|---|---|
| A-CUR-1: 못 익힌 기믹 2개 이상 요청 불가 | `GenRequest.fresh`는 최대 1, 위반 시 예외 |
| A-CUR-4: 1판 만에 다 이겨도 간격 전엔 소개 안 함 | 6판 전 소개 없음 |
| A-TGT-3·4: 진 직후 목표 상승 없음, 2연패 하강 | 표 기반 단위 테스트 |
| A-SOLV-1: 측정이 풀림 아님이면 절대 반환 안 함 | 가짜 게임으로 확인 |
| A-GEN-3: 예산 초과 시 pool | 가짜 게임(항상 느림) |
| Glicko-2 | Glickman 2012 예제 수치 일치(골든) |
| A-OFF-1 | 끔 상태에서 실력이 달라도 같은 목표 |
| 결정성 | 같은 상태·시드 → 같은 판 |
| 시뮬레이터 | 기본 설정에서 판별 승률이 목표 ±5%p (하품 릴레이) |
