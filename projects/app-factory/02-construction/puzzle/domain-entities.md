---
artifact: domain-entities
build-spec: puzzle
status: DRAFT
updated: 2026-10-15
---

# Domain Entities — Game Kit + 조각보 블록 퍼즐

## 1. `factory_game_kit` (코어 패키지, 화면 없음 — P3)

| 엔티티 | 필드·동작 | 비고 |
|---|---|---|
| `SplitMix64` | `SplitMix64(int seed)`, `nextInt(int max)`, `nextDouble()`, `state`(저장·복원) | 결정적 난수. `dart:math` `Random(seed)`는 버전 사이 결과가 보장되지 않아 쓰지 않는다 (K-RNG-1) |
| `dailySeed(DateTime local, int salt)` | `yyyymmdd` 정수와 `salt`를 섞은 64비트 시드 | 기기 현지 날짜 |
| `BestScores` | `best(String mode)`, `submit(mode, score) → bool(신기록)` | `KeyValueStore`, 키 `game.best.<mode>.v1` |
| `SaveSlot` | `save(String slot, Map json)`, `load(slot) → Map?`, `clear(slot)` | 버전 필드 포함, 깨진 JSON은 null (K-SAVE-1) |
| `RewardGate` | `request(String placementId) → Future<bool>` | 광고 제거 구매자는 광고 없이 `true`(1-2 §4), 아니면 `showRewarded` → `RewardOutcome.grants` |
| `RoundAds` | `roundTransition(String interstitialId)` | 결과 화면에서 다음 판으로 넘어갈 때 `onTransition` (K-ADS-1) |
| `GameFeedback` | `haptic(HapticKind)`, `sound(String id)`, `soundOn`(저장) | `audioplayers` 6.8.1 저지연 모드, 소리 설정과 「애니메이션 줄이기」는 독립 |
| `ShareGrid` | `text(title, lines, grid: List<List<int>>, palette)` | 이모지 격자 공유 문자열 |

## 2. 앱 `apps/bojagi` (게임 규칙·화면)

| 엔티티 | 필드 | 비고 |
|---|---|---|
| `Board` | `Uint8List cells`(8×8, 0=빈칸, 1~5=조각 색, 6=매듭) | 색은 장식일 뿐 규칙에 쓰지 않는다 (P-UI-1) |
| `Piece` | `id`, `cells: List<(dx,dy)>`, `w`, `h`, `weight` | 회전 없음, 방향마다 별개 조각 (P-PIECE-1, 표 §3) |
| `Tray` | `slots: List<Piece?>`(3) | 세 칸을 모두 놓아야 다음 배분 (P-DEAL-2) |
| `GameMode` | `classic` · `daily` · `level` | |
| `GameState` | `mode`, `board`, `tray`, `score`, `combo`, `rng.state`, `drawIndex`, `continueUsed`, `refreshUsed`, `piecesPlaced`, `linesCleared`, `knotsCollected`, `levelId?`, `dailyKey?`, `over` | 수마다 저장 (P-SAVE-1) |
| `PlaceResult` | `rows`, `cols`, `cellsCleared`, `knots`, `points`, `combo`, `perfect` | 한 번 놓기 결과 |
| `Level` | `id`(1~100), `goal`(`lines`·`knots`·`score`), `target`, `maxPieces`, `prefill`(64칸), `seed`, `botResult` | `assets/levels.json`, 도구가 만든다 |
| `LevelProgress` | `cleared: Set<int>`, `unlocked`(다음 레벨) | `KeyValueStore` |
| `DailyRecord` | `dailyKey`(yyyymmdd), `score`, `grid`(마지막 판) | 첫 판만 (P-DAILY-2) |

## 3. 조각 표 (P-PIECE-1)

좌표는 `(x, y)`, 왼쪽 위 기준. 가중치는 한 묶음 안에서 같은 값을 나눠 갖는다.

| 묶음 | 조각 (방향마다 하나) | 칸 수 | 묶음 가중치 |
|---|---|---|---|
| 점 | 1×1 | 1 | 4 |
| 막대2 | 1×2 가로, 세로 | 2 | 6 |
| 막대3 | 1×3 가로, 세로 | 3 | 8 |
| 꺾임3 | 2×2에서 한 칸 뺀 4방향 | 3 | 8 |
| 막대4 | 1×4 가로, 세로 | 4 | 6 |
| 네모 | 2×2 | 4 | 8 |
| ㄱ4 | 3×2 ㄱ·ㄴ 모양 8방향 | 4 | 8 |
| ㅗ4 | ㅗ·ㅜ·ㅓ·ㅏ 4방향 | 4 | 6 |
| ㄹ4 | S·Z 가로·세로 4개 | 4 | 4 |
| 막대5 | 1×5 가로, 세로 | 5 | 4 |
| 큰ㄱ5 | 3×3 모서리 4방향 | 5 | 5 |
| 직사각6 | 2×3 가로, 세로 | 6 | 4 |
| 큰네모9 | 3×3 | 9 | 3 |

합계 37조각, 가중치 합 74. 이름은 코드 상수이고 화면에 나오지 않는다.
