---
artifact: frontend-components
build-spec: yawn-generator
status: DRAFT
updated: 2026-10-18
---

# Frontend Components — Yawn! 큰 판 7×11 · 렌더러 v4.7 · 빌런 효과 · 노선 28개

> 그림 SoT: 핸드오프 **v4.7**(`inputs/design_handoff_yawn_relay_v4.7/`) + v3.4 화면(04)·컴포넌트(02). 확인 기록 `yawn-relay/handoff-v3-review-…`·`handoff-v4-review-…`.
> 지금 코드: `ui/board_view.dart`(BoardLayout·시선선), `ui/character/character.dart`(렌더러 v2.1 이식), `ui/run_controller.dart`, `ui/car_page.dart`, `ui/line_map_page.dart`, `ui/lines.dart`.

## 1. 컴포넌트 트리 (바뀌는 곳만)

```
CarPage
 ├─ 머리줄(52dp, 큰 판)          ← v3 04
 ├─ BoardView
 │   ├─ 좌석 칸 (앞턱 없음, 칸<56: 여백 3·모서리 9)   ← v4.2
 │   ├─ 승객 paintCharacter(…, lod, side)            ← 렌더러 v4.7
 │   ├─ 타일 paintTile(cart 6조각 / door / …)          ← v4.3
 │   ├─ 시선선 (dense: 1.3dp·30% + 어두운 테두리)      ← v3 02
 │   ├─ 효과층 FX (music·smell·sniff·call·shine·whistle·shout·watch·ting·drowse)  ← v4·v4.6
 │   └─ 누른 칸 강조(손가락 닿는 동안)                 ← v3 02 (채택 권장, Q 아님 — 핸드오프 확인에서 권장)
 └─ 툭 표시(한 줄, 52dp)
LineMapPage
 ├─ 노선 28개 (색 28: 1~21 v3, 22~28 v4) · 아이콘 28
 └─ 빌런 노선 머리 「빌런 칸」 표시(villainMark)
```

## 2. 컴포넌트 상세

### `BoardLayout` (변경)
- 칸 = `min(72, floor((폭 − 12 − 여백×2)/열), floor((남은 높이 − 여백×2)/행))` (v3 04). **칸 < 44면 안 됨** — 생성기 판 크기(최대 7×11)가 360×780 화면에서 46dp가 되도록 맞춰져 있다.
- 칸 ≤ 56 → `lod: 's'`(렌더러 작은 칸 단계), 좌석 여백 3·모서리 9.
- 판이 5×6보다 크면 시선선 `dense`.
- 412×915 → 7×11 칸 52, 360×780 → 46 (v3 04 표).

### `paintCharacter` (렌더러 v2.1 → v4.7 이식)
| 바뀜 | 내용 |
|---|---|
| 몸 아래 끝 | 앉은 몸·까치발·선 몸 경로 3개(v4.5) |
| 뒷모습 | 위를 볼 때 앞쪽 옷 장식 숨김·등 장식(v2.2) |
| 선 몸 | 서서 가는·순찰(v2.2) |
| 작은 칸 `lod` | 선 ×1.3, 눈·배지 키움, z 하나, 장식 뺌(v3) |
| 잠듦 z | `side`(±1) 쪽 위(v4.7). 승객마다 `side` = 판 시드로 정한 ±1 |
| 새 kind | 짐수레 `H`(어깨 표 `tag`) · 빌런 `V Q F L Z R U` (쩍벌 128×64, 통화 `left` 배지, 순찰 `walk`, 호통 다음 방향 배지 `next`·`shout` 상태) |
| 새 외형 | `BALD`, `KING[0..1]` |
기준 그림: `tool/sprites/export.py`를 v4.7 렌더러로 다시 돌려 기존 164장 갱신 + 새 kind·상태·작은 칸 견본 추가. 내보내기 도구의 「신발 버그 고침」 가정은 v3부터 렌더러에서 고쳐졌으므로 없앤다.

### `paintTile` (변경)
- `cart`: 조각 6개(`frame b1 b2 tag strap loose`), `st up/down`, 흐트러짐 자세 `CART_POSE`, 짐표 색 `tag`(BR Y2-GEN-10).
- `door`: v2.1 그림 그대로(v3.4에서 정정 확인).

### `FxLayer` (신규, `FX(type, o)` 이식)
| 효과 | 언제 | 칸 |
|---|---|---|
| `music` (+`noteMark` 이웃) | 스피커 깨어 있는 동안, 박자마다 | 스피커 + 이웃 4 |
| `smell` / `sniff` | 치킨 깨어 있는 동안 / 이웃이 돌린 고개 | 치킨 + 이웃 |
| `call` (+ 남은 박자 배지 `left` 1·2) | 통화 홀수 박자 | 보는 쪽 줄 |
| `shine {from}` | 깨어 있는 대머리에 시선이 닿아 갈라질 때 | 대머리 |
| `whistle` | 순찰이 걸은 뒤 | 순찰 + 이웃 4 |
| `shout` | 호통 버럭(`startle` 사건) | 호통 → 대상 |
| `watch {dir}` | 호통 깨어 있는 동안 — **바로 앞 칸** + 시선 끝 사람에게 「!」 | |
| `ting` | 호통 툭 거절(`TapResult.armored`) | 호통 |
| `drowse {from}` | 호통이 안 볼 때 옆 사람이 하품(다음 박자 호통 하품) | 이웃 → 호통 |
움직임 길이·이징은 핸드오프 06(v4, v4.6). 애니메이션 줄이기에서는 정지 표시(06).

### `RunController` (변경)
- 시도 기록 `AttemptLog`: 시도 시작(판 보임·「다시」) 시각, 첫 툭 시각, 툭 한 사람 묶음, 결과. 일시정지·백그라운드 동안 시계 멈춤, 입력 없이 60초 넘은 구간 제외(BR Y2-MAS-5).
- 호통 툭 → `Cue.refuse` + `ting` 효과, 툭 수 그대로.
- 다음 판 미리 만들기 isolate 시작(BLM W4).

### `CarPage` (변경)
- 힌트·「한 번 더 툭」: `Station.plan`이 있으면 그것(즉시), 없으면 기존 `firstSolution`.
- 판 끝: `Kit.finish(…)` → `PlayRecord`·`LineMastery.update`·`Director.report`·저장(BLM W2). 이김뿐 아니라 **나감**도 `PlayRecord`(진 시도가 0이어도 — 지금은 fails>0일 때만 보고).
- 졸업 → 노선도 「새 노선 열림」 연출(기존 `open_line` 흐름 재사용).

### `LineMapPage` (변경)
- 노선 28개, 노선 머리 아이콘 28(`GIMMICKS` 순서 = `lineMechanics`), 22~28에 `villainMark`.
- 역 노드: 지금처럼 끝 없는 노선(지난 3역·다음 역·잠긴 자리·환승). 환승 노드는 다음 노선이 열렸는지(졸업)로 표시.
- 노선 색 28(1~20 v2·21 v3 강철색·22~28 v4).

## 3. 전역 · 공유 상태

| 상태 | 소스 | 읽기/쓰기 |
|---|---|---|
| 저장 v2 (`LineProgress`·`Pace`) | `progress.dart` (v2) | `Kit` 쓰기, `LineMapPage`·`CarPage` 읽기 |
| 다음 판 미리 만들기 | `Kit` (isolate Future) | `CarPage` |
| 실패 종류 분류 | `Kit` (isolate Future, 판마다) | 판 끝에 모음 |

## 4. 화면 상태

| 상태 | 트리거 | UI |
|---|---|---|
| loading | 다음 판 생성이 카드 연출보다 늦음 | 카드 그대로 두고 「다음 역」 버튼 잠깐 비활성(스피너 없음) |
| empty | — | N/A |
| error | 생성 실패 | 대체 판(풀·소개)으로 조용히 |
| success | 판 준비 | 기존 |

## 5. 상호작용 · 네비게이션
- 누른 칸 강조: 손가락이 닿으면 강조, **떼면 툭**, 칸 밖으로 밀어 떼면 취소(v3 02). 첫 역 손가락 안내도 「떼기」에 맞춤.
- 쩍벌 꼬리 칸을 눌러도 그 사람을 툭.

## 6. 디자인 SoT 매핑

| SoT | 컴포넌트 | 데이터 |
|---|---|---|
| v3 04 칸 크기·세로 구성 | `BoardLayout`, `CarPage` 머리줄·툭 표시 | 판 rows·cols |
| v3 02 dense 시선선·누른 칸 | `BoardView` | |
| v4.3 수레 조각·`CART_POSE` | `paintTile(cart)` | 주인 잠 상태 |
| v4 03 빌런 7종 · v4.6 호통 배지 | `paintCharacter` | kind·상태·`next` |
| v4·v4.6 `FX` | `FxLayer` | 엔진 사건·상태 |
| v4 05 노선 22~28·`villainMark` | `LineMapPage` | |
| v4.7 z `side` | `paintCharacter` | 승객별 ±1 |
