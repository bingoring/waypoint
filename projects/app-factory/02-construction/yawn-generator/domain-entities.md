---
artifact: domain-entities
build-spec: yawn-generator
status: DRAFT
updated: 2026-10-18
---

# Domain & Entities — Yawn! 엮기 생성기 이식 · 짐수레 · 빌런 노선 · 노선 길이 적응

> 지금 코드 기준(메인 `549ed65`): 엔진 `apps/yawn/lib/domain/engine.dart`, 풀이기 `solver.dart`, 생성 `yawn_game.dart`, 설정 `yawn_config.dart`, 진행 `data/progress.dart`, 적응형 `packages/factory_adaptive`.
> 규칙은 [`business-rules.md`](business-rules.md), 흐름은 [`business-logic-model.md`](business-logic-model.md).

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT |
|---|---|---|---|
| `Kind` (확장) | 승객 종류 15 → 23 | 판 문자 | `#engine` KIND |
| `Board` (확장) | 수레·쩍벌 꼬리 | 판 문자 + 설정 | `#engine` parseLevel |
| `Engine`/`Passenger` (확장) | 박자 처리 15단계 | 메모리 | `#engine` step |
| `FastEngine` (신규) | 생성기 전용 빠른 박자(결과 = `Engine`) | 메모리 | `engine-fast.js` |
| `WeavePlan`/`WeaveResult` (신규) | 생성 계획·결과(사람·사슬·기믹·필수 판정) | 메모리 | `weave.js` |
| `Station` (확장) | 판 + 계획 풀이(힌트) + 출처 | 저장(최근 판) | `yawn_game.dart` |
| `LineProgress` (신규, 저장 v2) | 기믹 id별 진행: 익힘 + 최근 판 | `yawn.map.v2` | 2-13 |
| `Pace` · `LineMastery` · `PlayRecord` | 노선 길이 적응 | `yawn.map.v2` | `mastery.dart` |
| `AttemptLog` (신규) | 한 판의 시도별 고민 시간·툭 묶음·실패 종류 | 메모리 | BR Y2-MAS-4·5 |

## 2. 엔티티 상세

### `Kind` 추가 (판 문자 → 이름)
| 문자 | 이름 | 핸드오프 kind | 툭 | 비고 |
|---|---|---|---|---|
| `q` | `porter` 짐수레 | `H` | 됨 | 앞 칸 `C.` |
| `v` | `speaker` 스피커 | `V` | 됨 | |
| `o` | `wide` 쩍벌 | `Q` | 됨 | 오른쪽 `-.`, 방향 U/D |
| `f` | `chicken` 치킨 | `F` | 됨 | |
| `l` | `caller` 스피커폰 통화 | `L` | 됨 | |
| `e` | `bald` 대머리 | `Z` | 됨 | |
| `j` | `patrol` 순찰 | `R` | 됨 | 걷기 |
| `a` | `startler` 호통(왕관) | `U` | **안 됨** | `Passenger.canBeTapped` |

`canSee`는 그대로(커피·휴대폰·고양이 제외). 판 문자 표는 `#engine` 주석과 같다.

### `Board` 추가 필드
| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `carts` | `Map<(int,int), int>` | `{}` | 수레 칸 → 주인 id(없으면 −1) |
| `tails` | `Map<int, (int,int)>` | `{}` | 쩍벌 id → 꼬리 칸. `grid`의 꼬리 칸 = 그 id |
| `walks` | `bool` | | 서서 가는 **또는 순찰**이 있으면 참(시선 캐시 끔) |
`blocked`에 수레 칸 추가. `sights`에 `at`(상태) 인자로 수레 주인·대머리 잠 상태를 본다 — 지금 `Expando` 캐시(`targets`)는 **수레·대머리·치킨이 있는 판에서 쓰지 않는다**(상태에 따라 대상이 바뀜). 생성기 쪽 빠른 계산은 `FastEngine`이 맡는다.

### `Engine` 추가
| 항목 | 설명 |
|---|---|
| `effDir(p)` | 치킨 냄새로 본 방향(BR Y2-ENG-4) |
| `step` | 15단계(BR Y2-ENG-9). 사건 `startle`·`shout`·`call` 추가 |
| `Round.tap` | `startler` → `TapResult.armored`(툭 안 줆, 효과 `ting`) |

### `WeavePlan` (신규, `weave.js` `weavePlan`)
| 필드 | 타입 | 설명 |
|---|---|---|
| `line` | `int` | 0부터 |
| `n` | `int` | 노선 안 역(= 계단 높이) |
| `people` (P) | `int` | 목표 사람 수 ≤ 46 |
| `chains` (K) | `int` | 1~4 |
| `rows`·`cols` | `int` | 3~11 · 3~7 |
| `focus` | `String?` | 노선 기믹 |
| `open` | `List<String>` | 0..line 기믹 |
| `review` | `String?` | 복습 기믹(있을 때만) |

### `WeaveResult` (신규)
| 필드 | 타입 | 설명 |
|---|---|---|
| `station` | `Station` | 판 |
| `people` | `List<WeavePerson>` | `{r, c, dir, kind, chain, root, tail?}` — 계획 풀이·대조용 |
| `gimmicks` | `List<WeaveGimmick>` | `{kind, r, c, r2?, c2?, companion?}` |
| `check` | `WeaveCheck` | `{ok, isolated, essential[], decoration}` |
| `tries` | `int` | |
| `reviewSkipped` | `bool` | |
대조 고정 자료(BR Y2-PORT-2)의 JSON 모양 = JS `weaveGenerate` 결과 + 돌린 박자 수 — 필드 이름·순서를 JS와 같게 직렬화한다.

### `Station` 추가 필드
| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `plan` | `List<(int,int)>?` | null | 계획 풀이 시작점(박자 0에 툭) — 힌트·「한 번 더」. 사람이 만든 판은 null(기존 풀이기) |
| `tags` | — | — | 짐수레 짐표 색은 저장하지 않는다(행·열 순서로 다시 계산, BR Y2-GEN-10) |
JSON 키 `plan: [[r,c],…]`(없으면 생략).

### 저장 v2 — `yawn.map.v2` (기존 `yawn.map.v1` 대체)
```
{ v: 2,
  lines: { <mechanicId>: { m: LineMastery.toJson(), cleared: int, recent: [{n, b: Station}] } },
  pace: Pace.toJson(),
  selected: <mechanicId>?, unseen: <mechanicId>?,
  fails: int, failsAt: [mechanicId, played]? }
```
- `cleared`는 화면용(노선도 역 번호), 생성 규모는 `m.l`(계단).
- 이전 v1(`yawn.map.v1`)은 **읽지 않는다** — 출시 전이라 새로 시작(오너 2026-10-18, Q4).
- `adaptive.yawn.v1`(Glicko·기믹 노출)은 그대로 — 기믹 id 기준이라 순서 변경과 무관.

### `PlayRecord` 채우기 (BR Y2-MAS-4·5)
| 필드 | 출처 |
|---|---|
| `won` / `abandoned` | 판 끝 이유 |
| `helped` | `_helped`(한 번 더 툭·힌트) |
| `planFails` / `executionFails` / `otherFails` | `AttemptLog` 분류 결과 |
| `thinkMs` | 시도별 「판 보임 ~ 첫 툭」 합(일시정지·백그라운드·60초 넘는 무입력 제외) |
| `complexity` | 사람 수 |

## 3. 관계

| 좌 | 카디널리티 | 우 | 비고 |
|---|---|---|---|
| 기믹 id | 1:1 | 노선 | 노선 번호 = `lineMechanics` 위치(28개) |
| 노선 | 1:1 | `LineMastery` | 저장 v2 |
| 플레이어 | 1:1 | `Pace` | 모든 노선 공용 |
| `Board` 짐수레 승객 | 1:1 | 수레 칸 | 바로 앞 칸 |

## 4. 열거형

| 이름 | 값 | 확장 규칙 |
|---|---|---|
| `lineMechanics` (28) | basic phone coffee pillar cart window stubborn rot snorer baby talker mask door cat walker couple myopic tiptoe earphone tunnel alarm speaker wide chicken caller bald patrol startler | 뒤에만 붙인다(기믹 id 기준 저장이라 중간 삽입도 안전하지만, 노선 색은 번호에 붙음) |
| `EventType` | 기존 + `startle` `shout` `call` | |
| `TapResult` | 기존 + `armored` | |

## 5. SoT 매핑

| SoT | 엔티티.필드 | 비고 |
|---|---|---|
| `#engine` KIND (q v o f l j a e) | `Kind` | 렌더러 kind 문자는 핸드오프 표(H V Q F L Z R U)로 따로 |
| `#engine` parseLevel `C.` `-.` | `Board.carts`·`tails` | |
| `weave.js` `weavePlan`·`weaveBuild`·`weaveGenerate` | `WeavePlan`·`WeaveResult` | 줄 단위 이식 |
| `engine-fast.js` | `FastEngine` | |
| `mastery.dart` | `LineMastery`·`Pace`·`PlayRecord` | 이미 Dart |
| 핸드오프 v4 `line-colors-v4.json` | `lineColors` 28 | |
