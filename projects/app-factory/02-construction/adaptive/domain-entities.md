---
artifact: domain-entities
build-spec: adaptive
status: DRAFT
updated: 2026-10-16
---

# Domain Entities — 공통 적응형 난이도 `factory_adaptive`

> 게임과 무관한 데이터만 둔다. 판(보드)의 모양은 게임이 소유하고, 이 패키지는 판을 `B`(제네릭)로만 다룬다.
> 규칙은 [`business-rules.md`](business-rules.md), 흐름은 [`business-logic-model.md`](business-logic-model.md).

## 1. 게임이 꽂는 인터페이스

```dart
/// 게임 하나가 구현한다. 순수 Dart (Flutter 의존 없음) — 앱·도구·시뮬레이터가 같이 쓴다.
abstract interface class AdaptiveGame<B> {
  String get id;                                  // 'yawn' — 저장 키·분석 값
  List<Mechanic> get mechanics;                   // 커리큘럼 순서대로
  B? generate(SplitMix64 rng, GenRequest req);    // 조건에 맞는 판 하나, 못 만들면 null
  LevelFeatures measure(B board);                 // 풀이기 지표 (반드시 풀림 확인 포함)
  B decode(Map<String, Object?> json);            // 미리 검증된 판 묶음·저장용
  Map<String, Object?> encode(B board);
}
```

| 타입 | 필드 | 설명 |
|---|---|---|
| `Mechanic` | `id`(String, 예 `snorer`), `introBoards`(List\<B json\>) | 기믹. 소개 역은 사람이 만든 판(BR A-CUR-3) |
| `GenRequest` | `allowed`(Set\<String\>), `fresh`(String? — 아직 못 익힌 기믹, 최대 1), `size`(SizeBudget), `seed`(int) | 생성 조건 |
| `SizeBudget` | `maxCells`(int), `maxPassengers`(int), `maxTaps`(int) | 판 크기 상한 (게임이 의미를 해석) |
| `LevelFeatures` | `solvable`(bool), `values`(Map\<String, double\>), `mechanics`(Set\<String\>) | 지표 이름은 게임이 정한다. 하품 릴레이: `win_ratio`, `near_ratio`, `taps`, `passengers`, `starts` |

## 2. 상태 (기기 안에만, `KeyValueStore` 키 `adaptive.<game>.v1`)

### 2.1 `MechanicProgress` — 기믹마다
| 필드 | 설명 |
|---|---|
| `introducedAt` | 소개 역을 처음 한 순번(판 수), 없으면 null |
| `exposures` | 이 기믹이 든 판을 한 횟수 |
| `wins` · `winsNoHelp` | 이긴 판 수 · 힌트·한 번 더 툭 없이 이긴 판 수 |
| `mastered` | `wins ≥ 2` 그리고 `winsNoHelp ≥ 1` (BR A-CUR-2) |

### 2.2 `PlayerRating` — Glicko-2
| 필드 | 초기값 | 설명 |
|---|---|---|
| `rating` | 1500 | 실력 |
| `rd` | 350 | 불확실성 (판이 쌓이면 줄어든다, 하한 60) |
| `volatility` | 0.06 | 변동성 |

### 2.3 `AdaptiveState`
| 필드 | 설명 |
|---|---|
| `played` | 끝낸 판 수(순번) |
| `mechanics` | `Map<String, MechanicProgress>` |
| `rating` | `PlayerRating` |
| `recent` | 최근 10판 `Outcome` (연패·톱니 계산) |
| `sessionPlayed` | 이번 세션 판 수 (앱을 열 때 0) |
| `enabled` | 「판을 내 플레이에 맞추기」 스위치 (기본 true, DECISIONS 2026-10-16) |
| `lastIntroAt` | 마지막 새 기믹 소개 순번 |

### 2.4 `Outcome` — 판 하나 결과 (게임이 넘긴다)
| 필드 | 설명 |
|---|---|
| `won` | 이겼는가 (이번 판의 마지막 시도 기준) |
| `attempts` | 시도 수 (다시 하기 포함) |
| `helped` | 힌트·한 번 더 툭 등 보상형 도움을 썼는가 |
| `durationMs` · `idleMs` | 걸린 시간 · 아무 입력 없던 시간 (보조 지표) |
| `features` | 그 판의 `LevelFeatures` |
| `abandoned` | 깨지 않고 나갔는가 |

### 2.5 `ContextSignals` — 기기 안 계산값, 저장·전송하지 않음
| 필드 | 출처 |
|---|---|
| `commute` | 현지 평일 07:00–09:30, 17:30–20:00 |
| `cellular` | 연결 종류(`connectivity_plus`), 권한 `ACCESS_NETWORK_STATE`(일반 권한) |
| `longSession` | `sessionPlayed ≥ 15` |

## 3. 설정 (원격 설정 + 기본값, `AdaptiveConfig`)

| 키 (`adaptive_<game>_…`) | 기본값 | 뜻 |
|---|---|---|
| `target_min` · `target_max` | 0.10 · 0.35 | 목표 패배 확률 범위 |
| `target_ramp` | 120 | `played`가 이만큼일 때 상한에 닿는 기본 곡선 |
| `sawtooth` | `[-0.05, 0, 0.05, 0.10, -0.10]` | 톱니 주기 오프셋 |
| `loss_step_down` | 0.08 | 2연패 때 내리는 폭 |
| `rating_delta_cap` | 60 | 판 하나로 움직이는 실력 상한 |
| `spacing` | `[6, 7, 8, 10, 12, 14, 16, 18, 20]` | 새 기믹 사이 최소 판 수(뒤로 갈수록 김) |
| `model` | JSON `{bias, weights{지표: 가중치}}` | 판 난이도 예측식 (BR A-PRED) |
| `gen_budget_ms` · `gen_candidates` | 300 · 40 | 생성 시간 예산 · 후보 수 |
| `breather_every` | 15 | 긴 세션 중 쉬어 가는 판 간격 |

## 4. 분석 이벤트 (익명, DECISIONS 2026-10-16)
`adaptive_result` — 매개변수(25개 이하): `game`, `seq`(played), `mechs`(쉼표로 이은 기믹, ≤100자), `fresh`(못 익힌 기믹 여부 0/1), `f_<지표>` 최대 8개, `pred_loss`, `target`, `won`, `attempts`, `helped`, `dur_s`, `enabled`. **실력 점수·상황 신호는 넣지 않는다.**

## 5. 산출 파일
| 파일 | 위치 | 내용 |
|---|---|---|
| `pool.json` | 앱 `assets/` | 기믹 묶음별 미리 검증된 판(대체용, BR A-GEN-3) + 지표 |
| `model.json` | 앱 `assets/` | 예측식 기본 가중치 (원격 설정이 덮어씀) |
