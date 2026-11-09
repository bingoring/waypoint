---
artifact: domain-entities
build-spec: yawn-swap
status: READY
updated: 2026-11-09
---

# Domain & Entities — Yawn! 자리 교환 방식

> SoT: `prototypes/yawn-relay/arrange.html`(`makePuzzle` 177~278, `swapMove` 281~290, `run` 159~173, `lineSpec` 108~122). 기존 타입은 `apps/yawn/lib/domain/engine.dart`·`yawn_game.dart`.

## 1. 엔티티 개요

| 엔티티 | 신규/기존 | 책임 |
|---|---|---|
| `SwapPuzzle` | 신규 | 생성기가 만든 한 판: 고정 칸(짐 상자·창문·기둥·짐수레), 시작 자리, 승객 정의, 섞인 배치, 정답 배치 |
| `Rider` | 신규 | 바뀌지 않는 번호를 가진 승객: 종류·바라보는 방향·고정 여부·외형 씨앗 |
| `Arrangement` | 신규 (**중심**) | 승객 번호 → 칸. 불변 값. 한 번 옮길 때마다 새 값 |
| `Fixture` | 신규 | 고정 칸 하나: 짐 상자 / 창문(기울기) / 기둥 / 짐수레(주인 승객 번호, 짐표 색 번호) |
| `ChainResult` | 신규 | 배치 하나에 대한 연쇄 결과: 박자별 하품 승객, 승객별 하품 박자, 연결 수, 다 이어졌는가 |
| `SwapSpec` | 신규 | 판 설계 값: 행·열, 승객 수, 짐 상자·창문·기둥·짐수레 수, 고정 비율 |
| `SwapSession` | 신규 | 진행 중인 역: 지금 배치, 되돌리기 기록, 옮김 수, 쓴 시간, 힌트 수 |
| `Board` | 기존 변경 | `Board.parse`에 `cartOwners` 입력, 토큰 `X.`(짐 상자) |
| `Station` | 기존 변경 | `locked`(고정 칸 목록) 추가, `plan` = 시작 자리 하나, `taps = 1` |
| `PlayRecord` | 기존 (그대로) | 실력 판정 입력 — 교환 측정값을 기존 필드로 옮긴다 (business-logic-model §2.5) |
| `ClearedStation` | 기존 변경 | `attempts` 대신 `moves`·`ms`·`hints` |

## 2. 엔티티 상세

### `Rider`

| 필드 | 타입 | 필수 | 설명 · 제약 |
|---|---|---|---|
| `id` | `int` | ✅ | 판 안에서 0부터. **판이 끝날 때까지 바뀌지 않는다.** 외형(`id * 5 + seed`), 짐표, 자물쇠, 효과(Fx)가 모두 이 번호를 쓴다 |
| `kind` | `Kind` | ✅ | 엔진 승객 종류. 갈래 A에서는 `Kind.normal`만 생성한다. 갈래 B에서 승인된 종류가 늘어난다 |
| `dir` | `Dir` | ✅ | 바라보는 방향. **자리를 옮겨도 방향은 승객과 함께 간다**(실험판 `b.people[i].dir`) |
| `locked` | `bool` | ✅ | 고정 승객. 옮길 수 없고, 다른 승객이 이 자리로 올 수도 없다 |

### `Fixture`

| 필드 | 타입 | 설명 |
|---|---|---|
| `cell` | `(int, int)` | 행, 열 |
| `type` | `FixtureType` | `box`·`window`·`pillar`·`cart` |
| `slant` | `Slant?` | 창문만: `/` 또는 `\` |
| `owner` | `int?` | 짐수레만: 주인 `Rider.id` |
| `tag` | `int?` | 짐수레만: 짐표 색 번호(0~3, 판 안에서 수레마다 다름) |

고정 칸에는 아무도 앉지 못한다. 짐수레는 주인이 잠들기 전까지 시선을 막고, 주인이 잠든 다음 박자부터 넘어져 시선이 지나간다.

### `Arrangement`

| 필드 | 타입 | 설명 |
|---|---|---|
| `cells` | `List<(int, int)>` | 인덱스 = `Rider.id`, 값 = 앉은 칸 |

- 불변 값이다. `swap(id, cell)`은 새 `Arrangement`를 돌려주거나, 옮길 수 없으면 `null`을 돌려준다(business-rules SW-MOVE-1~4).
- `toBoard(puzzle)`이 엔진용 `Board`와 **엔진 번호 → `Rider.id` 표**를 함께 만든다. 엔진 번호는 판 문자열을 읽는 순서(행 우선)라 배치마다 다르다. 화면과 저장은 엔진 번호를 절대 쓰지 않는다.
- `==`·`hashCode`는 `cells` 내용으로 정한다(연쇄 결과 캐시 키).

### `SwapPuzzle`

| 필드 | 타입 | 설명 |
|---|---|---|
| `rows`, `cols` | `int` | 2×3 ~ 11×7 (`GRIDS`), 열 최대 7 |
| `fixtures` | `Map<(int, int), Fixture>` | 고정 칸 |
| `start` | `(int, int)` | 시작 자리. 고정 칸이 아니다. 여기에 앉은 승객이 0박자에 하품한다 |
| `riders` | `List<Rider>` | 인덱스 = `id` |
| `scrambled` | `Arrangement` | 처음 보여 줄 섞인 배치 |
| `solved` | `Arrangement` | 생성기가 만든 정답 배치(힌트에 쓴다). 정답이 하나뿐이라는 보장은 없다 |
| `par` | `int` | 섞을 때 맞바꾼 수(정답까지 걸리는 옮김 수의 **상한**) |
| `seed` | `int` | 생성 씨앗(같은 씨앗 = 같은 판) |
| `spec` | `SwapSpec` | 만든 설계 값 |

### `ChainResult`

| 필드 | 타입 | 설명 |
|---|---|---|
| `beats` | `List<List<int>>` | 박자마다 하품한 `Rider.id` |
| `beatOf` | `Map<int, int>` | `Rider.id` → 하품한 박자 |
| `linked` | `int` | 잠든 승객 수(= `beatOf.length`) |
| `ok` | `bool` | 모두 잠들었는가 |
| `litRays` | `Set<(int, int)>` | 하품을 실제로 옮긴 시선 갈래: (보는 승객, 보인 승객), `beatOf[보인] == beatOf[보는] − 1` |

### `SwapSpec`

| 필드 | 타입 | 설명 |
|---|---|---|
| `rows`, `cols` | `int` | `GRIDS`에서 고른 판 |
| `people` | `int` | 승객 수 |
| `boxes`, `windows`, `pillars`, `carts` | `int` | 고정 칸 수 |
| `lockRatio` | `double` | 고정 승객 비율 (첫 두 역은 0) |
| `intro` | `bool` | 노선 첫 두 역인가 |

### `SwapSession` (화면 상태, 저장 대상)

| 필드 | 타입 | 설명 |
|---|---|---|
| `puzzle` | `SwapPuzzle` | |
| `now` | `Arrangement` | 지금 배치 |
| `history` | `List<Arrangement>` | 되돌리기 |
| `moves` | `int` | 옮김 수(되돌리기도 1로 센다) |
| `elapsedMs` | `int` | 화면이 앞에 있던 시간만 센다 |
| `hints` | `int` | 쓴 힌트 수 |
| `hintLocked` | `Set<int>` | 힌트로 정답 자리에 고정된 `Rider.id` |

### `ClearedStation` (기존 변경)

| 필드 | 변경 | 설명 |
|---|---|---|
| `n`, `helped` | 그대로 | |
| `board` | **변경** | 판 문자열 대신 (씨앗, `SwapSpec`) — 다시 만들 수 있으므로 |
| `attempts` | **삭제** | 탭 방식의 시도 수 |
| `moves`, `ms`, `hints` | **추가** | 분석·복습용 |

## 3. 관계

- `SwapPuzzle` 1 — N `Rider`, 1 — N `Fixture`, 1 — 2 `Arrangement`(섞인 배치·정답 배치).
- `Fixture(cart).owner` → `Rider.id` (N:1이 아니라 1:1 — 한 승객은 수레 하나의 주인만 된다).
- `SwapSession` 1 — 1 `SwapPuzzle`, 1 — N `Arrangement`(지금 + 되돌리기 기록).
- `Arrangement` + `SwapPuzzle` → `Board`(엔진) → `ChainResult`.

## 4. 열거형 / Allowed-set

| 이름 | 값 | 비고 |
|---|---|---|
| `FixtureType` | `box`, `window`, `pillar`, `cart` | 갈래 B에서 판 사건(출입문·터널)이 고정 칸으로 들어오면 늘린다 |
| `Slant` | `/`, `\` | 엔진 `mirrors` 토큰과 같은 글자 |
| `Kind` (생성 허용) | v1: `normal` | 갈래 B 승인마다 추가. 엔진 `Kind` 23종은 그대로 두되 생성기 허용 목록으로 막는다 |
| 엔진 토큰 (추가) | `X.` = 짐 상자 | 기존 `C.`(수레)·`/.`·`\.`(창문)·`O.`(기둥)와 같은 두 글자 형식 |
| 짐표 색 | 4색 순환 `#e2787f`·`#5fb3e6`·`#8fd16a`·`#f2b84b` | 실험판 `TAGS`. 디자인 확정 전 임시 |

## 5. SoT 매핑

| 실험판 | Dart |
|---|---|
| `b.people[i] = { id, dir }` | `Rider(id, kind: normal, dir, locked)` |
| `b.locked` | `Rider.locked` |
| `b.block` / `b.mirror` / `b.pillar` / `b.cart` | `Fixture(type: box / window / pillar / cart)` |
| `b.cart.get(k) = { owner, tag }` | `Fixture.owner`, `Fixture.tag` |
| `b.start` | `SwapPuzzle.start` → `Station.plan = [start]` |
| `pos` (`[[r, c]]`) | `Arrangement.cells` |
| `makePuzzle` 반환 `{ b, pos, solved, par }` | `SwapPuzzle(scrambled, solved, par)` |
| `run` 반환 `{ beats, asleep, beatOf, ok }` | `ChainResult` |
| `lineSpec(n, …, L, fix)` | `SwapSpec` (`swapSpec(n, line)`) |
| `S.moves`, `S.hist`, `S.t0` | `SwapSession.moves`, `history`, `elapsedMs` |
