---
artifact: domain-entities
build-spec: yawn-mechanics
status: IMPLEMENTED
updated: 2026-10-17
---

# Domain Entities — Yawn! 기믹 확장

> **SoT:** `prototypes/yawn-relay/index.html` `#engine` `KIND`·`parseLevel`·`makeState`(메인 `729b286`). 기존 형태는 2-9 [`../yawn-relay/domain-entities.md`](../yawn-relay/domain-entities.md). 아래는 **추가·변경분만**.

## 1. 역 토큰 (추가)

| 토큰 | 뜻 | 엔진 `Kind` / 판 요소 |
|---|---|---|
| `k?` | 고양이 (방향 글자는 무시) | `Kind.cat` |
| `w?` | 서서 가는 승객 (방향 = 걷는 방향 = 시선) | `Kind.walker` |
| `h?` | 커플 승객 (상하좌우로 붙은 `h`끼리 짝) | `Kind.couple` |
| `g?` | 근시 승객 | `Kind.myopic` |
| `x?` | 까치발 아이 | `Kind.tiptoe` |
| `i?` | 이어폰 승객 | `Kind.earphone` |
| `A.` | 알람 시계 칸 (사람 없음, 시선 통과, 걷기 막음) | `Board.alarm` |

기존: `n p c s r z b t m`(승객), `..`, `/.` `\.`(창문), `O.`(기둥). 문은 토큰이 아니라 역 설정 `doors`.

## 2. 역 설정 (`Station` JSON 필드 추가)

| 필드 | 타입 | 설명 |
|---|---|---|
| `tunnelEvery` | int? (≥ 2) | 터널 주기 N. 박자 `k % N == N-1`이 터널 박자 |
| `alarmAt` | int? (≥ 1) | 알람이 울리는 박자 K. `A.` 칸이 있을 때만 의미 |

`doors`·`doorEvery`(기존)와 함께 `Station.toJson`·`fromJson`·`mechanicsOf`에 넣는다.

## 3. 런타임 상태 (변경)

### 3.1 `Board` (정적)
- `alarm: (int, int)?` 추가.
- `people[i].partner: int` — 커플 짝 id(없으면 −1). 파싱 때 정한다: 커플 승객마다 위·오른쪽·아래·왼쪽 순으로 짝 없는 커플 승객을 찾아 먼저 만난 쪽과 짝.
- `walks: bool` — 서서 가는 승객이 하나라도 있는가(풀이기 캐시 판단).

### 3.2 `Engine` (판 진행 중)
| 필드 | 초기값 | 설명 |
|---|---|---|
| `grid` | `Board.grid` 복사 | **상태 격자.** 서서 가는 승객이 움직이면 바뀐다. 시선·이웃·잠꼬대·문은 이 격자를 본다 |
| `people[i].r`, `.c` | 정의값 | 서서 가는 승객만 바뀐다 (`Passenger`에 위치 필드 추가) |

`copy()`는 `grid`와 위치를 함께 복사한다.

### 3.3 사건 (`BeatEvent.type` 추가)
`meow`(고양이 하품, id) · `lean`(커플 기대어 잠듦, 기댄 사람 id) · `alarm`(알람 울림, id 없음 — 칸 좌표) · `walk`(이동, id·이전 칸) · `turn`(돌아섬, id). 화면 연출용이며 판정에는 쓰지 않는다.

## 4. 골든 수치 — 역 21~36 (solver.js, 프로토타입 기록 §5.2)

| 역 | 기믹 | (이기는 시작점, 이기는 묶음, 니어미스) |
|---|---|---|
| 21 | 고양이 | (1, 8, 16) |
| 22 | 고양이 + 커피 | (1, 64, 164) |
| 23 | 서서 가는 | (1, 4, 8) |
| 24 | 서서 가는 + 두리번 | (1, 2, 2) |
| 25 | 커플 | (1, 8, 8) |
| 26 | 커플 + 코골이 | (1, 7, 115) |
| 27 | 근시 | (1, 8, 8) |
| 28 | 근시 + 말똥말똥 | (1, 58, 213) |
| 29 | 까치발 | (1, 8, 8) |
| 30 | 까치발 + 마스크 | (1, 64, 284) |
| 31 | 이어폰 | (1, 8, 8) |
| 32 | 이어폰 + 아기 | (1, 4, 4) |
| 33 | 터널 | (1, 2, 4) |
| 34 | 터널 + 두리번 | (1, 1, 3) |
| 35 | 알람 | (1, 3, 8) |
| 36 | 알람 + 말똥말똥 | (1, 19, 119) |

역 1~20 수치(`engine_golden_test.dart`)는 바뀌지 않아야 한다.

## 5. 노선 설정 (`yawn_config.dart`)

| 노선 | 기믹 id | 소개 판(stations 순번) | 대체 판 |
|---|---|---|---|
| 1~6 | basic·phone·coffee·window·stubborn·rot | 0·2·3·4·5·6 (기존) | 1·7 (기존) |
| 7 | snorer | 8 | 9 |
| 8 | baby | 10 | 11 |
| 9 | talker | 12 | 13 |
| 10 | mask | 14 | 15 |
| 11 | pillar | 16 | 17 |
| 12 | door | 18 | 19 |
| 13 | cat | 20 | 21 |
| 14 | walker | 22 | 23 |
| 15 | couple | 24 | 25 |
| 16 | myopic | 26 | 27 |
| 17 | tiptoe | 28 | 29 |
| 18 | earphone | 30 | 31 |
| 19 | tunnel | 32 | 33 |
| 20 | alarm | 34 | 35 |

(순서는 Q1 답에 따른다.)

**예측식 기믹 가중치 초안** (`defaultModel`, 로짓 단위 — 출시 뒤 실제 데이터로 다시 맞춤): 기존 `m_phone .2 · m_coffee .3 · m_window .4 · m_stubborn .4 · m_rot .6`에 더해
`m_snorer .5 · m_baby .5 · m_talker .2 · m_mask .5 · m_pillar .3 · m_door .6 · m_cat .1 · m_walker .7 · m_couple .5 · m_myopic .4 · m_tiptoe .4 · m_earphone .1 · m_tunnel .6 · m_alarm .6`.
근거: 프로토타입 기믹 효과(함정이 큰 기믹은 높게, 돕는 기믹은 낮게). 추정값임을 코드 주석에 적는다.

## 6. 영속 데이터
변경 없음. `yawn.map.v1`은 노선 수를 저장된 값과 `lines.length` 중 큰 쪽으로 읽는다(노선이 늘어도 진행 유지 — BLM §4 이전 처리).
