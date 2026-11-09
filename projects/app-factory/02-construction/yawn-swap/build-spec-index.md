---
build-spec: yawn-swap
stage: 02-construction/16-yawn-swap (갈래 A)
status: READY
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

## §4. 구현 체크리스트

- [ ] U1 `swap-core.js` 분리, `arrange.html` 동작 그대로(실험판 화면으로 확인)
- [ ] U2 대조 자료 생성
- [ ] U3 `cartOwners`·`X.` + 엔진 단위 테스트(기존 엔진 테스트 전부 통과)
- [ ] U4 배치 층 + `chain` 캐시
- [ ] U5 `generateSwap`·`swapSpec`
- [ ] U6 대조 테스트 통과(판·연쇄 글자 단위 일치)
- [ ] U7 `ArrangeController` + 단위 테스트(상태 전이, SW-MOVE-1~8, 힌트 SW-HINT-1·2)
- [ ] U8 판 그림 7층 + 골든
- [ ] U9 판 화면 연결
- [ ] U10 `Kit` 연결·`PlayRecord` 매핑·원격 설정 키
- [ ] U11 저장 v3·이어 하기
- [ ] U12 분석 이벤트
- [ ] U13 탭 방식 제거(분석 0·사용하지 않는 코드 0)
- [ ] U14 화면 흐름 테스트·기준 그림
- [ ] U15 디자인 요청서 v6

## §5. 검증 계획

- [ ] 저장소 루트 `flutter analyze` 0 · `dart format` 변경 0
- [ ] 단위·대조: U6(생성기 판 300개 이상·연쇄 1만 배치 일치), U7 상태 전이, U3 엔진 회귀(기존 테스트 전부)
- [ ] 불변식 시험: 노선 1~28 설계 값 × 씨앗 50 → I-2(고정 승객 = 정답 칸)·I-3(`solved` 풀림)·SW-GEN-4(고정물 모두 쓰임)·SW-GEN-9(섞인 배치 안 풀림)·생성 실패 0
- [ ] 화면 흐름: 첫 역 끌어서 풀기 → 도착 → 다음 역, 되돌리기·처음 배치, 힌트(광고 가짜), 백그라운드 → 이어 하기, 5역 줄 끝 → 다음 노선 열림, 섞기 장
- [ ] 에뮬레이터 직접 플레이(ko·en·다크·글자 130%·애니메이션 끔), 7×11 판에서 끌기 손맛, 스크린숏을 오너에게
- [ ] §6 NFR 측정

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

## §7. 편차 로그

| SoT | 실제 구현 | 사유 |
|---|---|---|
|  |  |  |
