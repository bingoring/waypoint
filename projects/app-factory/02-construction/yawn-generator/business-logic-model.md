---
artifact: business-logic-model
build-spec: yawn-generator
status: DRAFT
updated: 2026-10-18
---

# Business Logic Model — Yawn! 엮기 생성기 이식 · 짐수레 · 빌런 노선 · 노선 길이 적응

> 규칙(BR)은 [`business-rules.md`](business-rules.md), 타입은 [`domain-entities.md`](domain-entities.md). 여기서는 흐름·알고리즘·통합만.

## 1. 주요 워크플로

### W1. 다음 역 고르기 (노선 L, 플레이어 상태)
1. `LineMastery[L]`에서 계단 높이 `n` (= 역 규모), 복습 기믹 `review = ReviewPlanner.pick(…)`.
2. 미리 만든 판(W4)이 (L, n, review, 시드)와 맞으면 그것을 쓴다. 아니면 지금 만든다.
3. 생성: `weaveGenerate(L, n, seed, review)` (§2.1). 시드 = (플레이어 고정 소금, L, 그 노선에서 끝낸 판 수)에서 정한다 — 「같은 역 다시 하기」는 같은 판.
4. 실패(null) → 기존 대체 흐름(풀 판·소개 판).
5. Director의 Glicko 실력·목표 패배 확률은 **같은 n 안에서** 시드 후보 여럿(기본 3) 중 예측 패배 확률이 목표에 가장 가까운 판을 고르는 데만 쓴다(크기는 계단이 정한다 — Director의 크기 단계 `sizes`·`sizeUnlockAt`은 이 게임에서 쓰지 않음).

### W2. 판이 끝났을 때
1. 진 시도마다 실패 종류(Y2-MAS-4)를 백그라운드에서 계산해 모아 둔다.
2. 이김·짐·나감에서 `PlayRecord`를 만들고 `LineMastery[L].update(record, pace, config)`.
3. 이 판이 복습 판이면 그 기믹의 `LineMastery.reviewed(record, …)`도.
4. 기존 `Director.report(outcome)`(Glicko·기믹 보정)도 그대로.
5. `step.graduated`면 다음 노선을 연다(노선도에 「새 노선」 연출). `forced`면 복습 빚이 생긴다.
6. 저장(W5).

### W3. 툭
- 호통 승객·커피·잠든 사람·하품 중인 사람은 거절. 호통은 「갑옷」 효과(`FX ting`), 커피는 기존 거절.
- 그 밖은 기존과 같다.

### W4. 다음 판 미리 만들기
- 판이 시작되면 백그라운드 isolate에서 「이기면 갈 다음 역」 판을 만든다(이길 때 계단이 오르는 가장 흔한 경우: n+1 — 실제 n이 다르면 W1에서 다시 만든다).
- 판이 끝나기 전에 못 끝나면 W1이 기다린다(로딩 표시 없음 — 카드 연출 시간 안에 대개 끝남, NFR §6).

### W5. 저장
- 기믹 id → `{m: LineMastery.toJson(), cleared, recent}`, `pace` — 키 `yawn.map.v2`. `adaptive.yawn.v1`(Glicko·기믹 노출)은 그대로.
- 이전 `yawn.map.v1`은 읽지 않는다(출시 전 새로 시작, Q4).
- 새 노선 소개 판 = 생성기의 첫 역(n=0)(Q3). 손으로 만든 역 36개는 대체 판(생성 실패 시)과 1호선 첫 역 손가락 안내 판으로만 남긴다.

## 2. 알고리즘

### 2.1 엮기 생성기 — `weave.js`를 그대로
줄 단위로 옮긴다(함수 이름도 맞춘다). 구조:

```
weaveGenerate(line, n, seed, review):
  base = weavePlan(line, n, review)
  for scale in [1, 0.9, 0.8]:
    plan = scale==1 ? base : base with P = max(5, round(base.P·scale)), K 다시
    w0 = work.beats
    for t in 0..39 while work.beats - w0 < 180000:
      res = weaveBuild(plan, seed·7919 + t·104729 + round(scale·10)·31 + 1)
      검증(focus 포함·review 포함·weaveCheck) 통과 → (호통 노선이면 셋 중 가장 까다로운 것) 반환
  review가 있으면 review 없이 다시
weaveBuild(plan, seed):
  rnd = mulberry32(seed)
  1) 판당 기믹 고르기(Y2-GEN-2)
  2) 터널이면 tunnelEvery 먼저
  3) 시작점 K개: 서로 거리 ≥ max(2, ⌊(rows+cols)/(K+1)⌋), 종류별 시작점 패턴(고양이·커피·근시·짐수레·보통)
  4) 사슬 기르기(Y2-GEN-4) — 후보: 곧은 연결, 까치발, 창문(꺾임), 기둥(갈림), 대머리(갈림), 고양이 둘레, 잠꼬대 앞 칸, 짐수레 너머
     사람 하나 붙일 때마다 계획 풀이 확인(Y2-GEN-5)
  5) 개수·사슬 크기 검사
  6) 장식 걷어내기: 쓰이지 않는 연결 기믹(+근시 시작점)을 보통으로
  7) 뒤에 바꿔 넣는 기믹: 마스크·근시·코골이·아기·서서 가는·스피커·치킨·통화·순찰·쩍벌·호통·출입문·커플·이어폰·알람 (각각 계획 풀이·쓰임 검사)
  8) 휴대폰 시작점
```
세부 상수·순서는 `weave.js`가 SoT(BR Y2-GEN-*). 테스트는 JS 고정 자료(Y2-PORT-2)로 줄 단위 이식을 강제한다.

### 2.2 빠른 박자 계산 (생성기 전용)
`engine-fast.js` 그대로: 시선 대상 목록 기억(열쇠 = 위치·실제 방향·까치발/근시·짐수레 주인/대머리 잠 비트), 서서 가는·순찰이 걸으면 그 판 기억 새로, 종류별 사람 목록, 하품 없는 박자는 시선 단계 건너뜀, 사람마다 지난 박자 목록 재사용. 판 해석은 같은 판을 여러 번 돌릴 때 한 번만(최대 256개 기억).

### 2.3 실패 종류 분류 (Y2-MAS-4)
```
classify(board, tappedSet):
  K = |tappedSet|, S = K≤2 ? 6 : K==3 ? 5 : 4
  for beats in S^K (사전순):
    if run(board, tappedSet, beats).win: return execution
    if work > 20000 beats: return other
  return plan
```

### 2.4 노선 길이 (mastery)
`factory_adaptive` `LineMastery.update` 그대로(알고리즘 설명서 `adaptive/line-mastery.md`). 게임 쪽 일은 `PlayRecord` 채우기뿐.

## 3. 상태 전이 — 노선

| 현재 | 이벤트 | 다음 | 액션 | 가드 |
|---|---|---|---|---|
| 잠김 | 앞 노선 졸업 | 열림(소개 전) | 노선도 연출 | Y2-MAS-3 |
| 열림(소개 전) | 첫 판 시작 | 진행 중 | 소개 판(작은 판, n=0) | — |
| 진행 중 | 판 끝 | 진행 중 | 계단 갱신 | Y2-MAS-1 |
| 진행 중 | 졸업 | 졸업 | 다음 노선 열기 | min ≤ 판 수, 꼭대기, 평균 ≥ 0.6, 이김 / 또는 40판 |
| 졸업 | 판 끝 | 졸업 | 계단 갱신(꼭대기 유지) | — |

## 4. 시퀀스 — 판 하나

```
CarPage → RunController.start(board) ─ isolate: 다음 판 미리 만들기
  사용자 툭 ─→ 시도 시작 시각·첫 툭 시각(고민 시간)
  박자 … 짐/이김
  짐 → 패배 카드 표시 ∥ isolate: classify(board, 툭 묶음) → 실패 종류 누적
  이김/나감 → PlayRecord → LineMastery.update(+reviewed) → Director.report → 저장 → (졸업이면 노선도 연출)
```

## 5. 통합 지점

| 대상 | 호출 시점 | 요지 | 실패 처리 |
|---|---|---|---|
| `factory_adaptive` mastery | 판 끝 | `update`·`reviewed`·`ReviewPlanner.pick` | 저장 실패는 다음 판에 다시 |
| `factory_adaptive` Director | 판 고르기·판 끝 | 같은 n 안 시드 후보 고르기 · `report` | 기존 |
| 분석(익명) | 판 끝 | 기존 이벤트에 `level`(계단 높이)·`evidence`(0~1, 소수 2자리)·`graduated` 추가. 고민 시간·실력은 보내지 않음 | 기존 |
| isolate | 판 시작·패배 | 생성·분류 | 실패 시 주 스레드에서 다시(느려도 결과 같음) |
