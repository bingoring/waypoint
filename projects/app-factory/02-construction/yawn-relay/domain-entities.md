---
artifact: domain-entities
build-spec: yawn-relay
status: DRAFT
updated: 2026-10-16
---

# Domain Entities — 하품 릴레이 (가칭)

> **SoT:** 메인 저장소 `prototypes/yawn-relay/index.html`의 `#engine` 스크립트(`parseLevel`·`trace`·`makeState`·`step`)와 UI 스크립트의 `tap`·`beat`·`finish`.
> 재해석하지 않고 1:1로 옮긴다. 각 항목 끝의 `[engine: …]`이 출처 함수다. 규칙은 [`business-rules.md`](business-rules.md), 흐름은 [`business-logic-model.md`](business-logic-model.md).

## 1. 정적 정의 (레벨 파일 `assets/levels.json`)

### 1.1 레벨 토큰 형식 — 프로토타입 형식을 그대로 쓴다
프로토타입 8개 역을 그대로 옮길 수 있도록, 판은 **행마다 공백으로 나눈 두 글자 토큰**이다. `[engine: parseLevel]`

| 토큰 | 뜻 |
|---|---|
| `..` | 빈칸 (시선이 지나간다) |
| `/.` · `\.` | 창문 반사 칸 (시선이 90° 꺾인다, 사람이 없다) |
| `<종류><방향>` | 승객. 종류 `n` 기본 · `p` 휴대폰 · `c` 커피 · `s` 말똥말똥 · `r` 두리번, 방향 `U` 위 · `R` 오른쪽 · `D` 아래 · `L` 왼쪽 |

예: `"nR .. /. pD"`

### 1.2 `Station` (레벨 = 역)

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | int (1~) | 역 번호, 진행 순서 |
| `line` | int | 노선 번호 (장(章), FC §3.1) |
| `name` | {ko, en} | 역 이름 (가상의 이름만, 실제 역명·노선 색 금지) |
| `taps` | int (1~3) | 이 역에서 쓸 수 있는 툭 수 |
| `map` | List\<String\> | 1.1 토큰 행. 모든 행의 토큰 수가 같다 (최대 6×6, NFR) |
| `guide` | int? | 첫 역 안내용: 손가락 표시를 띄울 승객 id `[engine: LEVELS[0].guide]` |
| `intro` | Mechanic? | 이 역에서 처음 나오는 요소 (한 줄 힌트를 띄운다, BR Y-UI-2) |
| `solution` | List\<TapPlan\> | 도구가 찾은 이기는 툭 하나 (보상형 「힌트」용, BR Y-ADS-3) |
| `stats` | {wins, nearMisses, combos} | 풀이기 결과 (레벨 검사 기록, BLM §3) |

`Mechanic` = `multiDir` · `phone` · `coffee` · `window` · `stubborn` · `rotate` (프로토타입 역 2~7의 새 요소).

### 1.3 `TapPlan`
| 필드 | 타입 | 설명 |
|---|---|---|
| `passenger` | int | 승객 id (판을 행 우선으로 읽은 순서, `[engine: parseLevel]`의 `people.length`) |
| `beat` | int (0~7) | 몇 번째 박자에 툭 하는가 |

## 2. 런타임 상태

### 2.1 `Board` (정적, 레벨에서 만든다) `[engine: parseLevel]`
- `rows`, `cols`
- `grid[r][c]` → 승객 id 또는 −1
- `mirrors` → `(r,c)` → `/` 또는 `\`
- `passengers` → `PassengerDef{id, r, c, dir, kind, need}`; `need` = 말똥말똥 2, 그 밖 1

### 2.2 `Passenger` (판 진행 중) `[engine: makeState]`

| 필드 | 초기값 | 바뀌는 때 |
|---|---|---|
| `dir` | 정의값 | 두리번 승객만, 박자 끝마다 시계 방향 (BR Y-BEAT-4) |
| `count` | 0 | 하품할 때마다 +1 |
| `asleep` | false | `count ≥ need`가 되는 순간 true, 이후 그대로 |

### 2.3 `RunState` (한 판)

| 필드 | 타입 | 설명 | 출처 |
|---|---|---|---|
| `beat` | int | 지난 박자 수 (`k`) | `makeState`·`step` |
| `tapsLeft` | int | 남은 툭 | `makeState`·`tap` |
| `yawnNow` | Set\<int\> | **이번 박자**에 하품하는 승객 (예약 + 이번 박자 툭) | UI `yawnNow` |
| `idleBeats` | int | 하품 없이 지난 박자 수 (패배 판정용) | UI `beatsIdle` |
| `extraTapUsed` | bool | 「한 번 더 툭」 보상형을 썼는가 (판마다 1회) | UI `adUsed` |
| `outcome` | `playing` · `won` · `lost` | | UI `ended`·`finish` |

### 2.4 시선 (계산값, 저장하지 않음) `[engine: trace]`
`Sight{target: int? , path: List<(r,c)>}` — 화면의 시선선(점선 → 하품 때 빛나는 실선)과 판정에 같은 값을 쓴다.

## 3. 영속 데이터 (`KeyValueStore`, 기기 안에만)

> **구현 2026-10-16:** 아래 `yawn.progress.v1`·`yawn.attempts.v1`은 2-10 노선 선택에 맞춰 `yawn.map.v1` 하나로 바뀌었다 — [FC §7.2 D12](frontend-components.md).

| 키 | 값 | 비고 |
|---|---|---|
| `yawn.progress.v1` | int | 깬 가장 높은 역 번호. 그 다음 역까지 열린다 (프로토타입 `yawn.progress`) |
| `yawn.attempts.v1` | Map\<역, 시도 수\> | 분석·힌트 제안용 (BR Y-ADS-3), 최근 역만 |
| `game.sound.v1` · `game.haptic.v1` | bool | `factory_game_kit` `GameFeedback` 그대로 |

**판 중간 상태는 저장하지 않는다.** 한 판이 10~40초라, 앱을 다시 열면 그 역 처음부터 시작한다(2-7과 다름 — 2-7은 판이 길어 수마다 저장했다).

## 4. 관계

```
levels.json ─┬─ Station ──(parse)── Board ──(start)── RunState ── Passenger×N
             └─ Line (노선: 이름·색·Station 묶음)
progress ── 열린 역 범위 → 노선도(FC)
```
