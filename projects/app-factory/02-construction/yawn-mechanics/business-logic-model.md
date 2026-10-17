---
artifact: business-logic-model
build-spec: yawn-mechanics
status: IMPLEMENTED
updated: 2026-10-17
---

# Business Logic Model — Yawn! 기믹 확장

> 규칙은 [`business-rules.md`](business-rules.md), 데이터는 [`domain-entities.md`](domain-entities.md). 기존 흐름은 2-9 BLM 그대로.

## 1. 엔진 박자 (`Engine.step`)

프로토타입 `step` 순서를 그대로 옮긴다(BR §3). 의사 코드:

```
step(yawnSet):
  events = []; next = {}
  if !isDark(k):                                   # ① Y-TUNNEL-1
    for q in people where canSee(q):              #   canSee: 깨어 있음 && 커피·휴대폰·고양이 아님
      for t in sightTargets(q):                   #   근시 range 1, 까치발 skip 1, 기둥 갈림, 창문 꺾임 — 상태 격자 기준
        if t in yawnSet && kind(t) != mask: next += q; break
  for id in yawnSet where kind(id) == cat:         # ② Y-CAT-2
    next += {nb in neighbors(id) | awake && !coffee}; event meow
  for id in yawnSet: count++; if count >= need && !asleep: asleep, sleptAt = k     # ③
  for p in couples where sleptAt == k && partner awake:                           # ④ Y-COUPLE-1
    partner: asleep, count = need, sleptAt = k; next -= partner; event lean
  for q in rot where awake: dir = cw(dir)          # ⑤
  for q in walkers where awake: move or turn (Y-WALK-1); event walk/turn          # ⑥
  scheduled = next − asleep                        # ⑦
  talker (Y-TALK-1) → scheduled += ...            # ⑧ 상태 격자 기준
  snore/cry → wake neighbors except earphone       # ⑨
  if alarm && k == alarmAt: wake 8-neighbors except earphone; event alarm       # ⑩
  doors (Y-DOOR-1) — 문 칸의 승객 id는 상태 격자에서                              # ⑪
  k++
```

**구현 메모**
- `Board.targets(id, dir)` 캐시는 **걷는 판이 아닐 때만** 쓴다(`Board.walks`). 걷는 판은 `sights(r, c, dir, grid: engine.grid)`로 매번 계산한다.
- 근시·까치발의 시선은 종류에 따라 정해지므로 캐시 키에 종류가 따라온다(같은 승객은 종류가 바뀌지 않음 — 문 새 승객도 같은 종류).
- 이웃(`neighbors`)도 상태 격자 기준.

## 2. 풀이기

- 분기 탐색(2-9 최적화)은 그대로. `Engine.copy()`가 `grid`·위치를 복사한다.
- 대조 테스트(`solver_equivalence_test.dart`)의 무작위 판 생성에 새 기믹(노선 7~20)을 포함한다. 판이 작아야 전수 시험이 빨라서 크기는 16칸·승객 7명 이하로 둔다.
- 골든(`engine_golden_test.dart`): 역 1~36 × (시작점, 묶음, 니어미스). 역 21~36 수치는 DE §4.

## 3. 생성기 (`YawnGame.generate`)

1. 시선 나무로 승객을 놓는다(기존).
2. **기믹 고르기 (Y-GEN-1):** `focus`(노선 기믹)는 반드시, 나머지 열린 기믹에서 무작위 순서로 최대 2개. 기존의 「기믹마다 25%」를 「섞은 순서에서 앞 2개를 각각 50%」로 바꾼다(평균 1개 안팎).
3. **기믹 넣기(`put`) 추가:**
   - `cat`: 이웃이 2명 이상인 기본 승객 하나를 `k`로 (Y-GEN-3).
   - `walker`: 기본 승객 하나를 `w`로. 방향은 그대로(걷는 방향 = 시선).
   - `couple`: 상하좌우로 붙은 기본 승객 두 명을 `h`로.
   - `myopic` / `tiptoe`: 기본 승객 하나를 `g` / `x`로.
   - `earphone`: 판에 코골이·아기·알람 중 하나가 있으면 그 이웃 기본 승객 하나를 `i`로. 없으면 코골이 하나를 같이 넣고 그 이웃을 `i`로.
   - `tunnel`: 역 설정 `tunnelEvery` = 3 또는 4.
   - `alarm`: 사람 이웃이 있는 빈칸 하나를 `A.`로, `alarmAt` = 2~5.
4. **자르기(Y-GEN-2):** 사람·창문·기둥·알람을 모두 담는 범위. 걷는 승객이 있으면 그 줄(가로로 걸으면 행, 세로면 열)은 자르지 않는다. 알람이 있으면 알람 주변 8칸을 담는다.
5. 측정(`measure`)·결정성·5×8 상한은 그대로.

## 4. 노선 늘리기와 저장 이전

- `lineMechanics`가 20개가 되면 `factory_adaptive` 커리큘럼이 노선을 차례로 연다(간격 `spacing`, Q4).
- `MapProgress.load(store, lines.length)`: 저장된 노선이 6개면 7~20을 「깬 역 0」으로 붙인다(기존 6개 진행 유지). 테스트로 증명한다.
- 노선 20개를 모두 켜고 출시한다(원격 노선 스위치 없음, DECISIONS 2026-10-17).

## 5. 화면 연출 (요약 — 자세히는 FC)

엔진 사건(`events`) → 연출: `meow` 분홍 물결 520ms · `walk` 260ms 미끄러짐 · `turn` 150ms · `lean` 300ms 기대기(말풍선 없음) · `alarm` 벨 흔들림 + 3×3 파동 400ms · `snore`/`cry` 파동(기존) · 이어폰에 파동이 닿으면 튕김 250ms(이어폰 이웃에 `snore`/`cry`/`alarm` 사건이 있고 이어폰이 잠들어 있을 때).
터널 박자는 엔진 판정과 별도로 화면이 `isDark(k)`를 보고 어둡게 한다(한 박자 전 깜빡임).
