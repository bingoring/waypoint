---
build-spec: yawn-swap
stage: 02-construction/16-yawn-swap (갈래 A)
status: IN_PROGRESS
depth: comprehensive
updated: 2026-11-09
---

# Build Spec — Yawn! 자리 교환 방식 뼈대 (배치 층 · 교환 생성기 · 끌어서 맞바꾸기 · 실시간 경로 · 노선 진행)

## §0. 개요 & 범위

- **목표(한 줄):** 실험판에서 검증한 자리 교환 퍼즐을 앱의 유일한 게임 방식으로 옮긴다. 승객 번호가 바뀌지 않는 배치 층 위에서 기존 엔진으로 연쇄를 계산하고, 실험판 생성기를 줄 단위로 이식하며, 끌어서 맞바꾸는 판 화면과 실시간 경로, 노선 진행 곡선, 실력 판정 연결, 힌트 광고, 진행 저장을 만든다.
- **SoT:**
  - 규칙·생성: `prototypes/yawn-relay/arrange.html` (worktree `yawn/arrange-progress`, `c095258`) — `rays`·`run`(138~173), `makePuzzle`(177~278), `swapMove`(281~290), `lineSpec`(108~122), 화면 `draw`·`person`·끌기(316~451). **줄 단위 이식, 재해석 금지.**
  - 결정: DECISIONS 2026-10-21 「교환 방식」 · 「옮김 제한 없음」, 2026-10-26 「승객 수 노선 초반 적게」 · 「승객 수 곡선 보정」, 2026-10-27 「실시간 경로」, 2026-11-09 「교환 방식 Build Spec 질문 4개」.
  - 오너 실험 확인: STATUS 「Yawn! 재검토」 배너 2차~7차(2026-10-30 경로·테두리·배지, 2026-11-06 창문·기둥, 7차 짐수레).
  - 기존 앱: 엔진 `domain/engine.dart`, 노선도 v5, 적응형 `packages/factory_adaptive`, 렌더러 v5.
- **규모:** 판 최대 11×7 · 46명, 고정물 4종(짐 상자·창문·기둥·짐수레), 승객 종류 v1 = 기본만(갈래 B에서 추가), 노선 v1 = 기본·창문·기둥·짐수레 4개(갈래 B 승인마다 추가, 출시는 28개).
- **깊이 티어:** `comprehensive` — 게임 방식 전체를 바꾸고(입력·판정·생성·저장·광고·분석), 결정성(같은 씨앗 같은 판)과 성능(끄는 동안 연쇄 재계산)이 걸려 있다.
- **범위 밖:** 기믹 28개 재설계(갈래 B — [16-yawn-swap.md](../16-yawn-swap.md) §3), 디자인 요청서 v6의 최종 그림(받기 전 임시 그림), 노선 순서 재배치.

## §1. 분해

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| U1 실험판 코어 분리 `prototypes/yawn-relay/swap-core.js` | `rng`·`rays`·`run`·`makePuzzle`·`swapMove`·`lineSpec`을 DOM 없는 모듈로, `arrange.html`이 가져다 씀(동작 그대로) | — | 기존 변경 |
| U2 대조 자료 `tool/fixtures/swap_trace.js` | 노선 5개 × n 1~20 × 씨앗 3 × 고정물 5종 → 판·연쇄 JSON, 무작위 배치 1만 개의 `beatOf` | U1 | 신규 |
| U3 엔진 변경 `domain/engine.dart` | `Board.parse(cartOwners:)`, 토큰 `X.`(짐 상자) — 기존 토큰·규칙은 그대로 | — | 기존 변경 |
| U4 배치 층 `domain/swap/arrangement.dart` | `Rider`·`Fixture`·`Arrangement`(`swap`·`toBoard`)·`SwapPuzzle`·`ChainResult`, `chain()` + 캐시 | U3 | 신규 |
| U5 교환 생성기 `domain/swap/generator.dart` | `generateSwap` 줄 단위 이식(LCG·순회 순서), `swapSpec`, `SwapGimmick` 확장점(v1은 빈 목록) | U4 | 신규 |
| U6 대조 테스트 `test/swap_generator_test.dart`·`swap_chain_test.dart` | U2 자료와 글자 단위 비교 | U2, U5 | 신규 |
| U7 `ui/arrange_controller.dart` | 상태 전이(BLM §3)·끌기·두 번 눌러 바꾸기·되돌리기·처음 배치·힌트·시간 | U4 | 신규 (`RunController` 대체) |
| U8 판 그림 `ui/swap_board_view.dart` + `ui/sight_painter.dart` | 층 1~7(FC §2), 기존 `_shape`/`_sights`를 `SightPainter`로 떼어 냄, 임시 그림(시작 배지·자물쇠·짐표·짐 상자) | U7, 렌더러 v5 | 신규 + 기존 분리 |
| U9 판 화면 연결 `ui/car_page.dart`·`result_sheets.dart` | 숫자 막대·버튼 막대·도착 안내·힌트 광고, 탭 입력 제거 | U7, U8 | 기존 변경 |
| U10 `Kit` 연결 `ui/providers.dart`·`domain/yawn_game.dart`·`yawn_config.dart` | 판 만들기 = `generateSwap`(isolate·미리 만들기), `PlayRecord` 매핑(BLM §2.5), 노선 v1 4개, 원격 설정 키 5개 | U5 | 기존 변경 |
| U11 저장 v3 `data/progress.dart` | `ClearedStation`(moves·ms·hints), 진행 중 역 저장·복원·검증 | U4, U10 | 기존 변경 |
| U12 분석 | `swap_clear`·`swap_abandon` 이벤트(익명) | U10 | 기존 확장 |
| U13 탭 방식 제거 | `round.dart` 툭 흐름·`solver.dart`·`difficulty.dart`·`weave.dart`·툭/니어미스/한 번 더 툭·`_TapCounter`·관련 테스트·`stations.json` 탭 판 | U9, U10 | 삭제 |
| U14 화면 흐름 테스트·기준 그림 | `progress_flow_test.dart`를 교환 방식으로(끌어서 풀기 도우미), `shots_test.dart`, 판 그림 골든 | U9~U11 | 기존 변경 |
| U15 디자인 요청서 v6 | 시작 배지·자물쇠·짐표·테마별 짐 상자·끄는 상태·숫자/버튼 막대·도착 안내 | — | 신규 문서 |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ | [domain-entities.md](domain-entities.md) |
| business-rules | ✅ | [business-rules.md](business-rules.md) |
| business-logic-model | ✅ | [business-logic-model.md](business-logic-model.md) |
| frontend-components | ✅ | [frontend-components.md](frontend-components.md) |

## §3. 미해결 질문

모두 해소했다(2026-11-09 오너 답변 → DECISIONS 2026-11-09).

- [x] Q1 출시 노선 구성 → **28개 모두 재설계 후 출시.** 갈래 A는 검증된 4개 노선으로 뼈대를 만들고, 갈래 B 승인마다 노선을 더한다.
- [x] Q2 보상형 광고 자리 → **힌트 = 한 명을 정답 자리로**(고정). 한 번 더 툭·니어미스 부활 제거, 전면 광고 2역마다 유지.
- [x] Q3 노선 첫 두 역 → **실험판대로**: 그 노선 기믹 하나만, 짐 상자·자물쇠 없음, 승객 3명 안팎.
- [x] Q4 탭 방식 → **교환 방식으로 완전히 교체**, 쓰지 않는 코드는 지운다(엔진 kind·렌더러는 갈래 B를 위해 남김).

AI가 정한 것(오너가 바꿀 수 있음, 편차 후보):
- 실력 판정 입력 매핑(BLM §2.5) — `factory_adaptive`를 바꾸지 않고 옮김을 `otherFails`로.
- 판 화면에 시계를 보이지 않음(도착 안내에만).
- 힌트 버튼은 30초 또는 옮김 10번 뒤에 나타남.
- 두 번 눌러 바꾸기(끌기의 대체 입력, 접근성).
- 진행 중 역 저장(되돌리기 기록은 저장 안 함).
- 승객 수 곡선의 n = 그 노선의 **계단 높이**(SW-LINE-2). DECISIONS 2026-10-26은 「역 번호와 계단 높이가 함께」라고 적었는데, 역 번호는 쉬어 가는 판(5역 줄 끝)에만 쓴다. 다른 안: n = 그 노선에서 깬 역 수(실험판과 같음, 실력과 무관하게 늘어남).

## §4. 구현 체크리스트

worktree `yawn/arrange-progress` → 메인 `60b9456`(U1~U6), `913b5d7`(U7~U14), `056d2bc`·`5977963`(짐표·화면 사진).

- [x] U1 `swap-core.js` 분리, `arrange.html` 동작 그대로 (브라우저 확인: 판·연결 수·콘솔 오류 0)
- [x] U2 대조 자료 생성 — `prototypes/yawn-relay/fixtures-swap.js` → `test/fixtures/swap_port.json` (설계 값 5,600 · 판 600(만든 판 590) · 무작위 배치 연쇄 11,800)
- [x] U3 `cartOwners`·`X.` + 기존 엔진 테스트 전부 통과
- [x] U4 배치 층 `domain/swap/swap.dart` + `ChainCache`
- [x] U5 `generateSwap`·`swapSpec` `domain/swap/generator.dart`, 적응형 어댑터 `domain/swap/swap_game.dart`
- [x] U6 대조 테스트 `test/swap_port_test.dart` — 판·연쇄가 실험판과 글자 단위로 같음. 변이 시험 4개(나무 키우기 확률·짐표 번호·수레 주인 무시·짐 상자 통과) 모두 실패로 잡힘
- [x] U7 `ui/arrange_controller.dart` + `test/arrange_controller_test.dart` 9개
- [x] U8 판 그림 — `BoardPainter`에 `SwapOverlay` 층(§7 편차 2)
- [x] U9 판 화면 `ui/car_page.dart` (숫자 막대·버튼 막대·도착 요약·힌트 광고·칸 낭독)
- [x] U10 `Kit` 연결·`PlayRecord` 매핑·원격 설정 `app_adaptive.swap`
- [x] U11 저장 v3·이어 하기 `data/progress.dart`
- [x] U12 분석 이벤트 `swap_clear`·`swap_leave` (`app.yaml` → codegen)
- [x] U13 탭 방식 제거 — `solver.dart`·`difficulty.dart`·`weave.dart`·`YawnGame`·패배 카드·한 번 더 툭·툭 표시, 관련 테스트·도구. 엔진 kind 23종·렌더러·`RunController`(연쇄 재생)는 남김
- [x] U14 화면 흐름 테스트 `flow_test`(6)·`progress_flow_test`(3)·`map_v5_test`(5)·`board_paint_test`, 화면 사진 도구 교환 판 장면
- [x] U15 디자인 요청서 v6 초안 `yawn-relay/design-brief-v6-2026-11-09.md` (오너 확인 뒤 발송)

## §5. 검증 계획

- [x] 저장소 루트 `flutter analyze` 0 · `dart format` 변경 0
- [x] 단위·대조: U6(판 590개·연쇄 11,800 배치 일치), U7 상태 전이, U3 엔진 회귀 — Yawn! 테스트 98개 · `factory_adaptive` 73개 통과
- [~] 불변식 시험: 노선 1·10·28 × 고정물 5 × 계단 8 × 씨앗 1 (`swap_port_test` 「불변식」) — Build Spec의 「노선 28 × 씨앗 50」보다 좁다. 생성 실패는 성능 측정 200판에서 0
- [x] 화면 흐름: 끌어서 풀기 → 도착 → 다음 역, 두 번 눌러 바꾸기·되돌리기·처음 배치, 힌트(광고 가짜), 일시정지 → 이어 하기, 5역 줄 끝 → 다음 노선 개통, 복습 판, 섞기 장 저장 이전
- [~] 에뮬레이터 직접 플레이: 1호선 1역을 끌어서 깨고 연쇄 재생 → 도착까지 확인(영어). 고정물 판은 화면 사진 도구로 확인. **남음:** ko·다크·글자 130%·애니메이션 끔, 7×11 판 끌기 손맛, 오너 플레이
- [~] §6 NFR — 호스트 측정 끝, 기기(프로필 빌드) 측정 남음

## §6. NFR · 성능

| 항목 | 목표 | 측정 |
|---|---|---|
| 연쇄 재계산(`chain`, 캐시 없이) | 46명 판 p95 ≤ 2ms | 벤치 테스트(무작위 배치 1,000개), 프로필 빌드 에뮬레이터 |
| 끄는 동안 프레임 | 7×11 판에서 프레임 빌드+래스터 p95 ≤ 16ms | 프로필 빌드 타임라인 |
| 판 생성(isolate) | 46명·고정물 전부 p95 ≤ 400ms, 최대 1s. 미리 만들기로 화면 대기 0 | 벤치(노선 28 × n 20 × 씨앗 10) |
| 결정성 | 같은 (씨앗, 설계 값) → 같은 판, JS와 일치 | U6 |
| 메모리 | 기존 Yawn! 대비 증가 ≤ 10MB | 기존 G1 측정 절차 |
| 접근성 | 화면 낭독기로 두 번 눌러 바꾸기만으로 클리어 가능 | 수동 확인 |

에뮬레이터 성능 측정은 `-gpu host`, 부하 2 미만, 기준 앱과 같은 부팅에서 3회씩 잰다(기존 측정 조건).

### §6 측정 (2026-11-09, 호스트 CPU — 기기 측정 전 사전 확인)

| 항목 | 목표 | 측정 | 도구 |
|---|---|---|---|
| 연쇄 재계산 (캐시 없이) | 46명 p95 ≤ 2ms | 45명 7×9: p50 0.05ms · p95 0.18ms · 최대 0.91ms | `tool/bench_swap.dart` |
| 판 생성 | p95 ≤ 400ms, 최대 1s | 28호선 고정물 전부 계단 1~20 × 씨앗 10: p50 1.4ms · p95 17ms · 최대 43ms · 실패 0/200 | `tool/bench_swap.dart` |
| 끄는 동안 프레임 (미리 보기 + 그림 기록) | p95 ≤ 16ms | 46명 7×9: 평균 3.4ms · p95 8.4ms · 최대 22.7ms (칸이 바뀌는 프레임) | `tool/bench_paint_test.dart` |
| 연쇄 재생 프레임 (그림 기록) | p95 ≤ 16ms | 평균 2.7ms · p95 5.2ms · 최대 17.2ms | 같음 |

## §7. 편차 로그 (Deviations)

| # | SoT | 실제 구현 | 사유 |
|---|---|---|---|
| 1 | U2 `tool/fixtures/swap_trace.js`, 테스트 `swap_generator_test`·`swap_chain_test` | `prototypes/yawn-relay/fixtures-swap.js`, 테스트 `swap_port_test.dart` 하나 | 기존 대조 도구 관례(`fixtures-weave.js`·`load.js`)를 따름 |
| 2 | FC: 새 `SwapBoardView`·`SwapBoardPainter`, `SightPainter` 분리 | 기존 `BoardPainter`에 `SwapOverlay` 층을 더하고, 배치가 바뀔 때마다 그 배치로 `RunController`를 다시 만든다. 클리어는 시작 자리 승객을 0박자에 툭 해 기존 연쇄 연출로 재생 | 하품·잠·소리·안내 방송·도착 흐름을 그대로 재사용, 그림 코드 중복 없음. 판 시계는 `origin`으로 이어 숨쉬기가 튀지 않게 |
| 3 | FC 층 목록 | **바라보는 방향 삼각형**을 더함 (실험판 `person()`에 있던 것) | 바로 앞이 벽인 승객은 시선선이 없어 방향을 알 수 없었다(에뮬레이터 확인) |
| 4 | 엔진 시선 | `Board.sights(toWall:)` — 아무도 못 본 시선도 벽(짐 상자) 앞 칸까지 | 실험판 「시선 늘 보임」. 탭 방식 그림은 그대로(기본값 false) |
| 5 | FC 버튼 막대 아이콘 버튼 | 글자 있는 알약 버튼, 좁은 화면에서 막대 전체가 줄어듦 | 꺼진 아이콘 버튼이 어두운 객차에서 보이지 않았다. 힌트 문구가 길어 411dp에서 넘침(테스트로 발견) |
| 6 | DE `Station.locked` | `Station.cartOwners`만 더함, 고정은 `Rider.locked` | 엔진 역은 그림·재생용이라 고정 여부가 필요 없다 |
| 7 | BLM §5 원격 설정 키 5개(최상위) | `app_adaptive.swap` 안에 `lock_ratio`·`hint_after_ms`·`hint_after_moves`·`move_fail_unit` | `app.yaml` 원격 기본값을 바꾸지 않고 기존 `app_adaptive` JSON에 둠. 빈자리 비율은 0 고정(키 없음) |
| 8 | SW-LINE-2 n = 계단 높이 | `swapNOf`: 0·1단계 → n 1·2, 꼭대기(11단계)에서 그 호선 승객 상한에 닿게 늘림 | 계단은 0~11이라 n = 높이 + 1이면 28호선이 25명에서 멈춘다. 쉬어 가는 판은 실험판처럼 n이 5의 배수일 때(깬 역 수가 아님 — 생성 요청에 역 수가 없다) |
| 9 | SW-LINE-7 「v1은 노선 기믹만」 | 복습 기믹이 고정물이면 `창문+짐수레`처럼 함께 넣는다(종류마다 18명당 하나, 첫 두 역은 노선 기믹만) | 2-13에서 승인된 복습 섞기가 동작하게(진행 흐름 테스트) |
| 10 | 분석 `swap_abandon` | `swap_leave` (역을 나감 — 이어 하므로 포기가 아님), `use_extra_tap` 삭제 | 이름이 뜻에 맞게 |
| 11 | — | 끌기는 손가락이 처음 닿은 칸에서 시작(`DragStartBehavior.down`) | 기본값은 끌기로 인정된 지점이라 칸 경계에서 옆 승객이 집혔다(진행 흐름 테스트로 발견) |
| 12 | — | 짐수레 주인 짐표를 모든 외형에 그림 (`character.dart`, 짐꾼 외형만이던 조건을 넓힘) | 교환 방식은 누구나 주인. 기준 그림 519장 변화 없음 |
| 13 | — | `assets/stations.json`을 `test/fixtures/`로 옮김(앱에 넣지 않음) | 앱이 더는 쓰지 않는다. 엔진·그림 테스트만 읽음 |
| 14 | SW-GEN-12 「그래도 실패면 승객 −1」 | 씨앗 8번 → 적응형 대체 판 묶음(기본 노선 작은 판 3개) | 측정에서 실패 0. 묶음은 `Director._fallback`이 이미 처리 |
| 15 | DE `ClearedStation` 필드 | 판은 저장 형식(`json`)으로 들고 미리 보기를 열 때 만든다 | 앱을 켤 때 수십 판을 다시 만들지 않게 |
