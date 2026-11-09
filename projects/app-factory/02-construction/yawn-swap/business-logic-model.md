---
artifact: business-logic-model
build-spec: yawn-swap
status: READY
updated: 2026-11-09
---

# Business Logic Model — Yawn! 자리 교환 방식

## 1. 주요 워크플로

### `PlayStation` (역 하나)

1. `Kit`가 다음 역의 (노선 L, 계단 n, 씨앗)을 정한다 → `swapSpec(n, L)` → isolate에서 `generateSwap(spec, seed)` (지난 역을 하는 동안 미리 만들어 둔다).
2. 판 화면이 `SwapSession(puzzle, now = scrambled)`로 시작한다. 시간을 재기 시작한다.
3. 플레이어가 승객을 끈다 → 손가락 아래 칸이 바뀔 때마다 `preview = now.swap(id, cell)` → `chain(preview)` → 실시간 경로를 그린다.
4. 손을 뗀다 → 놓을 수 있으면 `history.push(now)`, `now = preview`, `moves++` → `chain(now)`.
5. `chain(now).ok`면 끌기를 막고 하품 연쇄를 박자대로 재생한다 → 도착 안내(옮김 수·시간) → `PlayRecord` 기록 → 노선 길이 적응 → 다음 역.
6. 힌트·되돌리기·처음 배치는 3~4와 같은 흐름으로 `now`를 바꾼다.

### `ResumeStation` (진행 중 저장)

- 화면이 백그라운드로 가거나 노선도로 나갈 때 `SwapSession` 요약(노선, n, 씨앗, 설계 값, `now.cells`, `moves`, `elapsedMs`, `hints`, `hintLocked`)을 저장한다.
- 다시 들어오면 (씨앗, 설계 값)으로 판을 다시 만들고(I-4), 저장된 배치를 검증(business-rules §2)한 뒤 이어서 한다. 되돌리기 기록은 저장하지 않는다.
- 노선도에서 다른 역을 고를 수 없으므로(다음 역 = `Kit.selected`), 진행 중 역은 하나뿐이다.

## 2. 알고리즘

### 2.1 `Arrangement.toBoard(puzzle) → (Board, List<int> engineToRider)`

1. `rows × cols` 칸을 `..`으로 채운다.
2. 고정 칸: 짐 상자 `X.`, 창문 `/.`·`\.`, 기둥 `O.`, 짐수레 `C.`.
3. 승객: `cells[id]` 칸에 `kind.letter + dir.letter` (예: `nR`).
4. 판 문자열을 `Board.parse(map, taps: 1, cartOwners: {수레 칸: 주인 칸})`로 읽는다. 주인 칸 = `cells[fixture.owner]`.
5. 엔진 번호는 행 우선 순서로 매겨지므로, 행 우선으로 승객 칸을 훑어 `engineToRider[엔진 번호] = Rider.id`를 만든다.

`Board.parse` 변경: `cartOwners: Map<(int, int), (int, int)>`을 받아, 칸을 다 읽은 뒤 `carts[수레 칸] = grid[주인 칸]`(엔진 번호)으로 채운다. 이 입력이 있으면 짐꾼(`q`) 규칙(`engine.dart` 305~309)으로 주인을 찾지 않는다. `X.`는 `grid`에 고정 막힘으로 기록하고, 시선 추적(`_targets`)에서 판 밖과 같게 끝낸다.

### 2.2 `chain(arrangement) → ChainResult`

1. `toBoard`로 엔진 판을 만든다.
2. `Engine(board)`에 0박자 시작 = 시작 자리 승객(`Station.plan = [start]`)을 넣고, `step`을 예약이 빌 때까지 반복한다(엔진 대조 조사: `step({s})` 후 `step(scheduled)`).
3. 박자마다 잠든 엔진 번호를 `engineToRider`로 바꿔 `beats`·`beatOf`를 채운다.
4. `litRays`: 각 잠든 승객 i의 시선 갈래 중 처음 만난 사람 j가 `beatOf[j] == beatOf[i] − 1`이면 (i, j)를 넣는다.
5. 결과를 `Arrangement`를 키로 최근 64개 캐시한다(끄는 중 같은 칸을 오가도 다시 계산하지 않는다).

시작 자리가 비었으면 엔진을 돌리지 않고 `ChainResult(linked: 0, ok: false)`.

### 2.3 `generateSwap(spec, seed) → SwapPuzzle?` — 실험판 `makePuzzle` 줄 단위 이식

```
rnd = lcg(seed); pick(a) = a[floor(rnd() * a.length)]
repeat t in 0..199:
  고정 칸 놓기: 짐 상자 → 창문(기울기 rnd < 0.5 ? '/' : '\') → 기둥 → 짐수레 (겹치면 다시 뽑기, 순서 고정)
  seats = 고정 칸이 아닌 칸
  root = pick(seats); parent, face, via, depth = {root: 0}; order = [root]; frontier = [root]
  while frontier:
    i = rnd() < 0.7 ? frontier.last : floor(rnd() * frontier.length)
    (r, c) = frontier[i]; adj = []; viaM = []
    for d in [U, R, D, L]:
      n = (r, c) + d
      n이 빈 좌석이면 adj += {cell: n, dir: REV[d]}
      n이 짐수레이고 depth[(r, c)] >= 1: 수레 건너편 좌석이 비었으면 viaM += {cell, dir: REV[d], via: n}; continue
      n이 기둥: e = REV[d]; SIDES[d0]에 e가 든 d0마다 n − d0 좌석이 비었으면 viaM += {cell, dir: d0, via: n}; continue
      n이 창문(m): MIR[m][d0] == REV[d]인 d0마다 n − d0 좌석이 비었으면 viaM += {cell, dir: d0, via: n}
    둘 다 비면 frontier에서 i를 빼고 계속
    nx = viaM이 있고 (adj가 없거나 rnd() < 0.6) ? pick(viaM) : pick(adj)
    parent[nx] = (r, c); face[nx] = nx.dir; via[nx] = nx.via; depth[nx] = depth[(r, c)] + 1
    order += nx; frontier += nx
  order 길이 != seats 길이면 다시 (SW-GEN-2)
  끝 가지 빼기 (seats − people명): 매번 kids == 0이고 부모가 있는 칸 중 pick (SW-GEN-3)
  남은 칸마다 Rider(id 순서 = order 순서, dir = 부모가 있으면 face, 없으면 pick(DIRS))
  승객 수가 다르면 다시
  쓰인 고정물 = via 값들; 안 쓰인 창문·기둥·짐수레가 있으면 다시 (SW-GEN-4)
  짐수레마다: minD = 이 수레를 건너는 자식들의 부모 depth 최소; 후보 = depth < minD인 승객; 없으면 다시; owner = pick(후보)
  run(solved).ok 아니면 다시
  고정: nLock = round(승객 × lockRatio); 후보 = 시작 자리가 아닌 승객; 무작위로 nLock명
  섞기: free = 고정 승객이 없는 좌석; movers = 고정 아닌 승객; want = max(2, round(movers × 0.9))
        400번까지: i = pick(movers), cell = pick(free); 같은 칸이면 건너뜀; swap 성공이면 k++ (k == want면 끝)
  run(scrambled).ok면 다시 (SW-GEN-9)
  return SwapPuzzle(scrambled, solved, par = k)
return null
```

**결정성 주의(이식 규칙):** 난수 호출 순서가 실험판과 글자 단위로 같아야 한다. `pick`의 바닥 함수, `Set`·`Map` 순회 순서(JS는 삽입 순서 → Dart `LinkedHashMap`/`LinkedHashSet` 기본값과 같음), `filter` 순서를 그대로 지킨다. 대조 도구로 확인한다(§2.6).

**갈래 B 확장점:** 승객 기믹은 ① 나무를 키울 때 쓰는 **연결 후보 함수**(기믹 승객을 자식으로 붙일 수 있는 칸·방향 목록)와 ② 생성 뒤 **장식 검사**(SW-GEN-10) 두 곳에 꽂는다. 기믹마다 `SwapGimmick { String id; List<Link> links(ctx); bool essential(puzzle) }`을 구현하고, 생성기는 노선이 허용한 기믹 목록만 쓴다.

### 2.4 `swapSpec(n, L, {restStation}) → SwapSpec` — 실험판 `lineSpec`

```
N = min(cap(L), 3 + floor((n − 1) * rate(L))); restStation이면 N = max(3, N − 1)
intro = n <= 2
boxes = intro ? 0 : 1 + floor(N / 8)
노선 기믹이 창문 / 기둥이면 1 개(intro) 또는 1 + floor(N / 12); 짐수레면 1 또는 1 + floor(N / 14)
need = ceil(N / (1 − emptyRatio)) + boxes + 고정물 수
(R, C) = GRIDS에서 R × C >= need인 첫 판 (없으면 11×7)
lockRatio = intro ? 0 : swap_lock_ratio
```

`restStation` = 이 노선에서 깬 역 수 + 1이 5의 배수(노선도 한 줄 끝 역과 같은 자리 — Y2-ROW 「5역 줄」).

### 2.5 실력 판정 입력 — `PlayRecord` 매핑 (AI 결정, `factory_adaptive` 변경 없음)

| `PlayRecord` | 교환 방식 값 | 이유 |
|---|---|---|
| `won` | 클리어 = `true` | 실패가 없다 |
| `abandoned` | 클리어 전에 역을 나감 | 기존 그대로 |
| `helped` | `hints > 0` | 기존 그대로 (근거 × 0.5) |
| `planFails` | 0 | 「출발해서 진 시도」가 없다 |
| `executionFails` | 0 | 손이 어긋나는 실패가 없다 |
| `otherFails` | ⌊max(0, moves − par) / max(2, ⌈movers / 2⌉)⌋ | 섞은 수(par)를 넘는 옮김을 「헤맨 정도」로 본다. 움직일 승객 절반만큼 더 옮길 때마다 실패 1번(원격 설정 `swap_move_fail_unit`으로 나눗수 배율 조정) |
| `thinkMs` | `elapsedMs` | 판 전체를 푸는 시간 |
| `complexity` | movers (고정 아닌 승객 수) | 시간 정규화(`complexityExponent` 0.7)에 그대로 쓴다 |

par는 정답까지의 최소 옮김 수가 아니라 **상한**이라 잡음이 있다. 그래서 옮김은 `otherFails` 한 곳으로만 들어가고(근거 식 계수 0.3), 출시 뒤 분석 이벤트로 다시 맞춘다. 원본 값은 모두 분석 이벤트 `swap_clear`에 남긴다(§5).

### 2.6 대조 도구

- 실험판의 규칙·생성 코드를 `prototypes/yawn-relay/swap-core.js`(DOM 없는 모듈)로 떼어 `arrange.html`과 Node가 함께 쓴다.
- `tool/fixtures/swap_trace.js`: 노선 1·7·14·21·28 × n = 1~20 × 씨앗 3 × 고정물(없음·창문·기둥·짐수레·전부) → `{spec, seed, puzzle, chain(scrambled), chain(solved)}` JSON.
- Dart 테스트 `swap_generator_test.dart`가 같은 입력으로 만든 판과 연쇄 결과를 글자 단위로 비교한다.
- 연쇄 대조: 무작위 배치 1만 개에 대해 `swap-core.js run`과 Dart `chain`(엔진 경유)의 `beatOf`가 같은지 본다(엔진 재사용이 실험판 규칙과 같다는 증명).

## 3. 상태 전이

### `SwapSession`

```
loading ──판 준비──▶ arranging ──끌기 시작──▶ dragging ──놓기(가능)──▶ arranging
                        │  ▲                    │
                        │  └──놓기(불가)/취소────┘
                        │
                        ├──힌트(광고 성공)──▶ arranging (한 명 고정)
                        ├──되돌리기/처음 배치──▶ arranging
                        └──chain.ok──▶ playing(연쇄 재생) ──끝──▶ cleared ──다음 역──▶ loading
arranging/dragging ──백그라운드──▶ paused(저장) ──복귀──▶ arranging
```

- `playing`과 `cleared`에서는 끌기·되돌리기·힌트가 막힌다.
- 시간은 `arranging`·`dragging`에서만 흐른다.

## 4. 시퀀스

```
사용자          판 화면(ArrangeController)       chain(캐시)          Engine
  │─끌기 시작──▶│ dragging(id)                       │                    │
  │─칸 이동────▶│ preview = now.swap(id, cell) ─────▶│ toBoard → parse ──▶│ step*
  │             │◀────────── ChainResult ────────────│◀───────────────────│
  │             │ 실시간 경로·연결 수 다시 그림          │                    │
  │─놓기───────▶│ now = preview, moves++ ───────────▶│ (캐시 적중)          │
  │             │ ok? → 연쇄 재생 → 도착 안내 → Kit.won(PlayRecord)
```

## 5. 통합 지점

| 대상 | 내용 |
|---|---|
| `Kit`(`ui/providers.dart`) | `ready()`·`selected`·`hardNext` 그대로. 판 만들기만 `generateSwap`으로 바꾸고, `won(PlayRecord)`에 §2.5 매핑을 넣는다 |
| `factory_adaptive` | 변경 없음. `LineMastery`·`Director`·섞기 장·`catchUp`·`hardTarget` 그대로 |
| 원격 설정 `app_adaptive` | 새 키: `swap_lock_ratio`(0.18), `swap_empty_ratio`(0), `swap_hint_after_ms`(30000), `swap_hint_after_moves`(10), `swap_move_fail_unit`(1.0) |
| 분석 | 새 이벤트 `swap_clear` {line, n, people, movers, locked, par, moves, undos, resets, ms, hints}, `swap_abandon` {line, n, moves, ms}. 기존 `adaptive_result`는 그대로 |
| 광고 | 보상형 단위 `rewarded_hint`만 남기고 `rewarded_extra_tap` 제거. 전면 광고 그대로 |
| 저장 `data/progress.dart` | 저장 형식 v3: `ClearedStation` 필드 변경, 진행 중 역(`SwapSession` 요약). 출시 전이므로 v2를 읽지 않고 새로 시작 |
| 없애는 것 | `round.dart`의 툭 흐름, `solver.dart`(판 측정·힌트), `difficulty.dart`(후보 고르기 C), `weave.dart`(탭 방식 엮기 생성기), `run_controller.dart`의 툭·니어미스, `_TapCounter`, 한 번 더 툭 시트. 엔진 kind 23종과 렌더러는 남긴다(갈래 B가 다시 쓴다) |
