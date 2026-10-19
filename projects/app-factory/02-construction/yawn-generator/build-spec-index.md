---
build-spec: yawn-generator
stage: 02-construction/12-yawn-generator (+ 13-line-mastery, 14-yawn-villains)
status: IN_PROGRESS
depth: comprehensive
updated: 2026-10-19
---

# Build Spec — Yawn! 엮기 생성기 이식 · 짐수레 · 빌런 노선 · 노선 길이 적응 · 렌더러 v4.7

## §0. 개요 & 범위
- **목표(한 줄):** 웹 프로토타입에서 검증한 엮기 생성기(노선 28개)와 노선 길이 적응(2-13)을 Flutter 앱에 옮기고, 판을 7×11·칸 44dp까지 키우며, 그림을 핸드오프 v4.7로 올린다.
- **SoT:**
  - 규칙·생성: `prototypes/yawn-relay/` — `index.html #engine`, `engine-fast.js`, `weave.js`, `villain-rules.js`, 대조 도구 `engine-compare.js`·`weave-compare.js`(메인 `ace59d1`~`549ed65`). **줄 단위 이식, 재해석 금지.**
  - 노선 길이: `packages/factory_adaptive/lib/src/core/mastery.dart`(구현·테스트 24개), 설명서 `adaptive/line-mastery.md`.
  - 그림: 핸드오프 **v4.7**(`inputs/design_handoff_yawn_relay_v4.7/`) + v3.4 화면·컴포넌트. 확인 기록 `yawn-relay/handoff-v3-review-2026-10-18.md`·`handoff-v4-review-2026-10-18.md`.
  - 결정: DECISIONS 2026-10-17 「2-12 생성기 재설계 방향」 ~ 2026-10-18 「호통(왕관) 승객 규칙 강화」.
- **규모:** 엔진 kind 15 → 23·타일 2종(수레·쩍벌 꼬리)·박자 11 → 15단계, 생성기 약 900줄(JS) 이식, 노선 20 → 28, 판 최대 5×8 → 7×11(최대 46명), 렌더러 v2.1 → v4.7(kind 8 + 외형 3 + 효과층), 기준 그림 164장 갱신 + 추가, 저장 v1 → v2.
- **깊이 티어:** `comprehensive` — 엔진·생성기·저장·렌더러를 함께 바꾸고, 성능(큰 판 생성)과 결정성(같은 시드 같은 판)이 걸려 있다.

## §1. 분해

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| U1 엔진 확장 `domain/engine.dart`·`round.dart` | kind 8·수레·쩍벌 꼬리·`effDir`·15단계 박자·사건 3·호통 툭 거절 | — | 기존 확장 |
| U2 엔진 대조 고정 자료 | JS에서 무작위 판+툭+박자별 상태 자료 뽑기(`tool/fixtures/engine_trace.js`), Dart 테스트 | U1 | 신규 |
| U3 빠른 박자 `domain/fast_engine.dart` | `engine-fast.js` 이식, U2 자료로 검사 | U1 | 신규 |
| U4 엮기 생성기 `domain/weave.dart` | `weave.js` 줄 단위 이식(mulberry32·안정 정렬·박자 한도) | U3 | 신규 |
| U5 생성기 대조 고정 자료 | JS `weaveGenerate` 28노선×12역×시드 2 + 복습 판 → JSON, Dart 테스트 글자 단위 비교 | U4 | 신규 |
| U6 게임 연결 `domain/yawn_game.dart`·`yawn_config.dart` | `generate` = 엮기, `measure` = 계획 풀이 기반(표본 어림 대신), 노선 28 순서, 소개·대체 판 정리 | U4, Q2·Q3 | 기존 변경 |
| U7 실패 종류·고민 시간 `domain/attempts.dart` | BR Y2-MAS-4·5, isolate | U1 | 신규 |
| U8 노선 길이 연결 `ui/providers.dart`(`Kit`) | `LineMastery`·`Pace`·`ReviewPlanner` → 계단 n·졸업·복습, `Director` 역할 조정 | U6, U7, Q2 | 기존 변경 |
| U9 저장 v2 `data/progress.dart` | 기믹 id 기준, 새로 시작(v1 읽지 않음) | U8 | 기존 변경 |
| U10 렌더러 v4.7 `ui/character/` | 몸 경로·뒷모습·선 몸·lod·z side·짐수레·빌런 7·새 외형·`FX` | 핸드오프 | 기존 확장 |
| U11 기준 그림 | `tool/sprites/export.py` v4.7, 164장 갱신 + 추가 | U10 | 기존 변경 |
| U12 판 화면 `ui/board_view.dart`·`car_page.dart`·`run_controller.dart` | 칸 44dp·lod·dense 시선선·좌석·수레 조각 움직임·효과층·누른 칸 강조·힌트 = 계획 풀이·미리 만들기 | U1, U10 | 기존 변경 |
| U13 노선도 `ui/line_map_page.dart`·`lines.dart` | 노선 28·색 28·아이콘 28·빌런 칸 표시 | U10 | 기존 변경 |
| U14 분석 | `adaptive_result`에 `level`·`evidence`·`graduated` (익명) + 후보 3개 지표·뽑힌 판 | U8 | 기존 확장 |
| U15 후보 고르기 C `domain/difficulty.dart` | 같은 계단 후보 3개 → `lab/graph.js` 이식(옮는 길·원천 덩어리), 타이밍 여유(`weaveSweep`), 선형식(무게 = 실험실 데이터 최소제곱, 2-12 §3.11·§3.12) → Director 목표에 맞는 판 | U4, U8 | 신규 |
| U16 원격 조정값 `yawn_config.dart` + 원격 설정 `app_adaptive` | 고르기 C 무게, `MasteryConfig`(최소·최대 판 수·계단 기준), 생성기 `W_SCORE`·`W_SHAPE`·숨기기 비율을 원격 설정으로(기본값 = 프로토타입). 판 생성·판단은 기기에서(오프라인·결정성), 분석 → BigQuery → 다시 맞춘 값을 원격 설정으로(2026-10-19 오너 질문) | U4, U8, U15 | 기존 확장 |
| U17 섞기 장 커리큘럼 `factory_adaptive` | `mixOpenedAt`(늘 맨 끝·한 번 열리면 계속), 쓰는 기믹 = 열린 노선 전부, 주인공 기믹 고르기(약한 기믹 먼저), 전용 계단(졸업 없음), 업데이트로 노선이 끼어도 열림 유지(Y2-MIX-1~7) | U8 | 기존 확장 |
| U18 섞기 장 앱 연결 `providers.dart`·`progress.dart`·`yawn_game.dart` | `Kit.next(mix)`, 진행 저장 키 `mix`, 생성기 노선 위치 = 노선 수(규모 기준 21+ 같음), 분석 `line: mix`, 원격 `mix_start_level` | U17 | 기존 변경 |
| U19 노선도 섞기 장 `line_map_page.dart` | 마지막 노선 아래 닫힌 고리(역 10개 안팎·열차), 예고 고리 실루엣, 개통 연출, 머리 = 고리 기호 + 섞인 얼굴 아이콘(핸드오프 v5) | U18, 핸드오프 v5 | 기존 변경 |
| U20 업데이트 노선 추가 시험 | 저장 → 노선 목록에 노선 하나 끼움 → 이어서 플레이: 진행·섞기 장 열림 유지, 새 노선 개통 | U17 | 신규(테스트) |
| U21 디자인 요청서 v5 | 여러 줄 노선·섞기 장 고리·머리·색·예고·개통 (`yawn-relay/design-brief-v5-2026-10-19.md`) | — | 문서 |

## §2. 아티팩트 인덱스
| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ 초안 | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ 초안 | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ 초안 | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ 초안 | [`frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문 (구현 전 오너 결정)

- [x] **Q1 출시 범위 — 28개 모두 첫 출시 (오너 2026-10-18).** ~~ 노선 28개(빌런 포함) 모두 첫 출시에 / 21개로 출시하고 빌런 노선 7개는 첫 업데이트(「시즌 2」)로? (AI 권고: 코드는 28개 모두 만들고 **원격 설정으로 빌런 노선을 켜고 끄게** — 출시 뒤 반응을 보고 켤 수 있다)~~
- [x] **Q2 난이도 결정 — 계단 + 후보 3개 중 C 방식으로 고르기 (오너 2026-10-19).** 같은 계단에서 시드 후보 3개를 만들고, 「사람·툭·기믹 수 + 원천 덩어리 수 + 논리로 좁힘 + 타이밍 여유」 선형식(무게는 실험실 데이터로 맞춤, 2-12 §3.11)으로 플레이어 목표(Director 목표 패배 확률)에 맞는 판을 고른다. 후보 지표·뽑힌 판·실제 결과(시도 수·고민 시간)를 분석에 남겨 출시 뒤 다시 맞춘다. 근거: 실험실 비교 — 고르지 않을 때보다 손해 약 40% 감소, 비용은 판 생성의 일부.
- [x] **Q3 새 노선 소개 판 — 생성기의 첫 역 (오너 2026-10-18).** ~~ (a) **생성기의 첫 역(n=0, 작은 판)**을 소개 판으로 / (b) 노선마다 사람이 만든 소개 판(지금 20개 + 짐수레·빌런 8개 새로). (AI 권고: a — 손으로 만든 소개 판 20개는 대체 판으로 남긴다. 첫 역 손가락 안내는 생성 판의 계획 풀이 첫 툭을 가리킨다)~~
- [x] **Q4 기존 저장 — 새로 시작 (오너 2026-10-18).** 저장 키를 `yawn.map.v2`로, v1은 읽지 않는다(이전 코드 없음). ~~ 아직 출시 전이라 진행 기록은 오너 기기(테스트)에만 있다. (a) **v1 → v2로 옮긴다**(BR Y2-LINE-2) / (b) 새로 시작(v2 빈 저장). (AI 권고: a — 옮김 코드는 작고 테스트로 지킬 수 있다)~~

- [ ] **Q5 섞기 장 열림 조건 (2026-10-19 추가).** (a) **마지막 노선을 졸업하면**(AI 권고 — 졸업 = 그 기믹을 익힘, 강제 졸업 포함이라 막히지 않음) / (b) 모든 노선을 하나도 빠짐없이 졸업하면(앞 노선은 졸업 순서상 이미 끝나 있어 a와 거의 같지만, 강제 졸업 기믹의 복습이 끝나야 한다는 조건을 더함)

## §4. 구현 체크리스트

- [x] U1 엔진: kind `q v o f l j a e`, `C.`·`-.` 해석·검사, `carts`·`tails`, `effDir`, 박자 15단계(BR Y2-ENG-9), 사건 `startle`·`shout`·`call`, `TapResult.armored`
- [x] U2 엔진 대조 (판 841·플레이 6,800, `test/engine_port_test.dart` + 상태 보는 시선 targetsOn = sights 800판, 변이 9가지 모두 잡힘): JS 고정 자료(무작위 판 ≥ 2,000 · 플레이 ≥ 20 · 박자 40, 빌런·수레·쩍벌 포함, 순서 중요 사람 먼저 재우는 플레이 포함) → Dart 박자마다 상태 전체 일치
- [x] U2 규칙 확인: `villain-rules.js` 16개를 Dart 테스트로(`test/villain_rules_test.dart` 7묶음) — JS 16 통과 · Dart 16 통과
- [x] ~~U3 빠른 박자~~ — **하지 않음(편차)**: Dart 엔진만으로 생성기 대조 118판이 18초(JS + 빠른 박자 25초). 필요해지면 다시
- [x] U4 생성기 (`lib/domain/weave.dart`): `weavePlan`·`weaveBuild`·`weaveRun`·`weaveNeutral`·`weaveEssential`·`weaveSweep`·`weaveCheck`·`weaveGenerate` 이식, mulberry32, 안정 정렬, 박자 한도
- [x] U5 생성기 대조: JS 고정 자료 28노선 × 역 4 + 복습 판 6 = 118판 → Dart 결과(판·사람·기믹·검증·시도 수·돌린 박자 수) 글자 단위 일치(`test/weave_port_test.dart`). 변이 4가지 중 3가지 잡힘 — 정렬 동점 순서는 점수에 난수 항이 있어 이 118판에서 동점이 안 나 드러나지 않음
- [x] U6 게임 연결 (`yawn_game.dart`·`yawn_config.dart`): `generate` = `Weaver.generate(노선, 계단, 시드, 복습)`, `measure` = 고르기 C 지표 6개(생성 판은 계획 풀이로 풀림 확인, 사람이 만든 역은 풀이기·타이밍 여유 1), 노선 28(`lineMechanics = weaveOrder`), 소개 판은 1호선 첫 역만(Q3), 대체 판 그대로, `Station.plan`·`g`(기믹 수) 저장, `Kit`에 `mastery: masteryDefaults`. 테스트 `yawn_game_test` 10개(노선 28 × 계단 0·8 생성·풀림, 결정성, 복습, JSON, Director 계단 흐름)
- [x] U7 실패 종류·고민 시간 + isolate: `RunController.thinkMs`(시도마다 판 시계 0 ~ 첫 조작, 일시정지 제외·한 틱 100ms 상한·시도마다 `idleCapMs`)·`tapped`, 진 시도마다 `failKind` = isolate `classifyFail`(1초 넘으면 모름). 앱을 다시 켜 이어 하는 역은 고민 시간 null
- [x] U8 노선 길이 연결: `Kit.won`·`abandon`이 `Outcome.play`(PlayRecord: 도움·풀이/손/모름 실패·고민 시간·사람 수)를 넘김 → Director 계단·졸업·복습(패키지 `ladder_test`). 힌트 = 생성 판은 계획 풀이 첫 시작점(박자 0), 사람이 만든 역은 풀이기
- [x] U9 저장 v2(새로 시작) + 깨진 저장 견딤: `yawn.map.v2` 기믹 id 키(`lines{id: {cleared, recent}}`·`selected`·`unseen`·`failsAt[id, played]`), v1 안 읽음, 순서 바뀐 노선 목록으로도 이어짐(`progress_test` 5개)
- [x] U10 렌더러 v4.7 + U11 기준 그림 (메인 `ad18ee8`): `character.dart`에 몸 경로 3개·뒷모습·선 몸·작은 칸(`small`, 선 1.3배 — 굵기를 직접 준 선은 그대로)·z `side` 쪽·짐수레 주인 짐표·빌런 7종(소품·얼굴·대머리·왕관·다음 방향 배지, 쩍벌 128×64)·`Mood.shout`·짐수레 타일(6조각, 흐트러짐 진행 `fall` 0~1)·`paintFx` 11종·`paintVillainMark`. 기준 그림 `tool/sprites/export.py`를 v4.7로(신발 버그 고침 가정 삭제) 164 → **482장**(빌런 40·짐수레 3·타일 10·FX 18 추가, 그리고 **모든 견본의 작은 칸 판** — 선 굵기 배율 검사), **482장 모두 일치**(메인 `3fb4081`: 고정 굵기 선 3곳 — 문 틀·터널 외곽선·잠꼬대 말풍선). 만화 글꼴에 「버럭」·「커피 마시는 중」·「툭이 없어요」 글자가 없던 것을 고침(말풍선 문구를 `strings.dart`에서 읽어 서브셋). 글자 위치는 `tool/shots/text_check_test.dart`로 눈 확인. 판 화면 외형 매핑 교체(쩍벌은 두 칸 배치라 U12). 글자(z·배지 숫자·「버럭!」·「!」)는 기준 그림에서 숨기므로 코드로 대조
- [x] U12 판 화면 (메인 `933e0b9`): 칸 ≤ 56 작은 칸 그림, 큰 판(5×6 초과) 시선선 `dense`(1.3dp·30%·어두운 테두리·끝 점 1.7·빛 2.6·비켜 그리기 2.4), 머리줄 52·툭 표시 한 줄(손 30), 큰 판 좌우 여백 6(칸 = 화면 − 12 − 여백), 좌석 앞턱 없앰·안쪽 여백 3/5·모서리 9/12, 쩍벌 두 칸 좌석(안쪽 테두리 `#4A5570`)·128×64 그림, 순찰 선 몸·걸음, 짐수레 타일(흐트러짐 300ms·다시 섬 250ms·짐표 색 `cartTag`), 수레 막힘 가로막대(0.62칸 앞)·깨어 있는 대머리 갈라짐(0.42칸 앞), 효과층(음악·냄새·킁킁·통화 `reach`·반짝·고함·지켜봄·시선 끝 「!」·버럭·졸음·팅), 호통 툭 = 갑옷 튕김, 깨어 있는 얼굴 = 실제 보는 방향(`effDir`), 통화 남은 박자·호통 다음 방향 배지, 누르면 강조·떼면 툭·밀어 떼면 취소. 힌트 계획 풀이·미리 만들기는 U8에서 이미 됨. 칸 크기 단위 테스트(412 → 53·360 → 46·작은 판 64–72), 그리기 기록 7×11·37~40명 평균 0.6~0.7ms·최대 4.5ms(호스트, 래스터 제외)
- [x] U13 노선도 28 (메인 `ae65305`): 노선 색 28(1~20 v2, 21 v3 강철색 `#3F4F60`/`#98ADC4`, 22~28 v4 단계 D `line-colors-v4.json`), 노선 머리 아이콘 28(새 8개: 짐수레·스피커·쩍벌·치킨·통화·대머리·순찰·호통 — 렌더러 `GIMMICKS` 아이콘 28개를 기준 그림으로 비교, 510장 모두 일치), 22~28호선 번호 칩 옆 빌런 칸 표시(24), 환승역은 다음 노선이 열렸는지(졸업)로 — 기존 그대로. 노선도 사진 10·11(노선 28개, 라이트·다크)
- [x] U14 분석 필드: `adaptive_result`에 `level`·`evid`·`grad`·`c_pred`·`c_pick` + C 지표 6개(`f_*`), 24개(한도 25) — 고민 시간·실력 없음
- [x] U15 후보 고르기 C (`difficulty.dart`): 원천 덩어리(타잔 강연결요소)·타이밍 여유·실패 종류 이식, 무게 = `lab/fit-model.js` 값(`yawn_config.defaultModel`). 대조 `test/difficulty_port_test.dart` — JS 고정 자료(`fixtures-difficulty.js`) 생성 판 118 + 엔진 판 841의 덩어리 전부 일치, 생성 판 118의 이긴 조합 수 일치, 실패 종류 = 생성기 sweep 판정 116판 일치(풀이 실수 111·손 실수 5)
- [x] U16 원격 조정값: `app_adaptive`의 `model`(C 무게)·`mastery`(MasteryConfig)·`ladder_candidates`·`weave`(`cross`·`near`·`len`·`density`·`hide`·`hide_line`·`hide_n`, `WeaveTuning.fromMap` 범위 검사). 기본값 = 프로토타입(생성기 대조 118판 그대로 일치)
- [x] 노선도 C — 긴 노선 여러 줄(1~4줄)·앞쪽 깬 역 점 압축·꺾이는 역 번호 바깥쪽, 다시 하기 판 21개 저장 (메인 `04dea30`, DECISIONS 2026-10-19)
- [x] U21 디자인 요청서 v5
- [ ] U17 섞기 장 커리큘럼 · [ ] U18 앱 연결 · [ ] U19 노선도 고리(핸드오프 v5 뒤) · [ ] U20 업데이트 노선 추가 시험
- [ ] 화면 흐름 테스트: ~~호통 툭 거절, 수레 넘어짐 뒤 이어짐, 쩍벌 꼬리 툭~~ (`test/villain_screen_test.dart`, 통화 배지 포함 4개 — 메인 `933e0b9`), 졸업 → 새 노선, 복습 판, 저장 이전
- [x] 판 사진 도구(`tool/shots/boards_test.dart` 「v4 lines」): 5호선·22~28호선 계단 꼭대기 판(7×11) × 412·360 폭·움직임 줄이기·누른 칸
- [ ] 에뮬레이터 확인(프로필 빌드): 큰 판 생성 시간·노선도·빌런 효과

## §5. 검증 계획
- [ ] `flutter analyze --fatal-infos --fatal-warnings`(저장소 루트) · `dart format` = 0
- [ ] 단위: 엔진 대조(U2) · 빠른 박자(U3) · 생성기 대조(U5) · 규칙 16 · mastery 24 · 저장 이전 · 실패 분류(손으로 만든 판: 박자만 틀린 묶음 = 손 실수, 틀린 사람 = 풀이 실수)
- [ ] 기존 테스트 유지: 역 36 골든(`engine_golden_test`), 풀이기 대조, 화면 흐름
- [x] 성능(§6) 측정 도구: `tool/bench_gen.dart`를 엮기 생성기로 — 맥(JIT) 노선 28 × 계단 0·4·8·11: 판 하나 생성 중앙 25ms·p95 323ms·최대 1.1초, 측정 중앙 3ms, 「다음 판」(후보 3) 중앙 111ms·p95 938ms·최대 1.26초(무거운 노선: 걷는 승객·순찰·호통·확성기). 생성은 이미 isolate + 미리 만들기. 기기 측정은 에뮬레이터 단계에서
- [ ] 시각: 기준 그림 골든 + 판 사진 + 에뮬레이터

## §6. NFR · 성능
| 항목 | 목표 | 측정 |
|---|---|---|
| 판 생성 (기기, 프로필 빌드) | 중앙값 < 300ms, 최대 < 3초 — 미리 만들기로 「다음 역」 대기 0이 대부분 | `bench_gen` 28노선 × 12역, 에뮬레이터 af_api36 |
| 결정성 | 같은 입력 → 같은 판 (JS·Dart·기기 무관) | U5 |
| 실패 분류 | 패배 카드 뜨는 동안(≤ 1초) 끝, 못 끝나면 「모름」 | 박자 한도 2만 |
| 그리기 | 7×11·46명 판 60fps(박자 연출 중) | `bench_paint_test` |
| 메모리 | 생성 isolate 끝나면 해제 | DevTools |

## §7. 편차 로그 — 구현 후
| SoT | 실제 구현 | 사유 |
|---|---|---|
| U3 빠른 박자 계산(`engine-fast.js` 이식) | 이식하지 않음, 엔진(`Engine.step`)을 그대로 씀 | Dart 엔진이 JS 빠른 박자보다 빠르다(생성기 대조 118판 Dart 18초 vs JS 25초). 결과는 같음(대조 통과) |
| 개발 도구 `tool/simulate.dart`·`tool/stress_hard.dart`(구 생성기용) | 삭제 | 시선 나무 생성기·`win_ratio` 지표에 묶여 있었다. 같은 역할은 프로토타입 난이도 실험실(`difficulty-lab.js`·`lab/selection-test.js`)과 대조 테스트(엔진·생성기·지표)가 맡는다 |
| 풀이기 대조(`solver_equivalence_test`)의 생성 판 240개 | 엮기 생성 판 중 전수 시험이 되는 작은 판(계단 0~2, 24판) + 엔진 대조 판 중 작은 판 | 엮기 판은 툭 3~4·사람 20명 이상이 흔해 묶음 5만 개를 넘는다. 노선 기믹 28개가 모두 대조에 들어가는 것은 그대로 확인 |
| `Station`의 판 크기 단계(`sizes`) | 형식상 1단계만 남김 | 계단 방식은 판 규모를 계단 높이가 정한다(Director가 첫 항목을 넘김) |
| DE 저장 v2: `LineMastery`·`Pace`를 `yawn.map.v2`에 | 적응형 상태(`adaptive.yawn.v1`의 `ln`·`pc`)에 둠. `yawn.map.v2`는 노선도 진행(깬 역·최근 판·선택·실패 수)만 | 계단·졸업을 쓰는 Director와 같은 곳에 두어 저장 하나로 맞춘다(두 저장이 어긋날 일 없음). 기믹 id 키라 노선 순서 변경과 무관한 것은 같다 |
| 렌더러 옵션 `lod: 's'` | `small: bool` (`paintCharacter`·`paintTile`·`paintFx`) | 크기 단계가 둘뿐이라 불 값이 읽기 쉽다. 같은 동작(선 1.3배, `SK`·`L` 선만 — 굵기를 직접 준 선은 그대로) |
| 짐수레 흐트러짐 = 조각별 CSS 애니메이션(`o.anim`), 그림자는 `st`로 둘 중 하나 | `paintTile(cart, fall: 0~1)` 한 값으로 조각 자세·끈 투명도·그림자(cy 60→59, rx 19→28)를 함께 보간 | 판 시계로 그리는 앱 구조에 맞춤. 정지 그림(0·1)만 기준 그림과 대조되고 중간 프레임은 대조 밖 — U12 움직임 확인에서 눈으로 본다 |
| 쩍벌(`Q`) 128×64 | 렌더러는 이식, 판 화면은 아직 기본 외형(`Kind.wide → Look.b`) | ~~U12에서 해소~~ (메인 `933e0b9`): 두 칸 좌석·128×64 그림, 꼬리 칸은 엔진 격자가 그 사람 id라 탭이 그대로 그 사람 |
| FC §2 CarPage 「나감도 `PlayRecord`(진 시도가 0이어도)」 | 진 적 없이 나가면 보고하지 않는다(U8·D13 그대로) | 시도가 0인 판은 실패 종류·시도 수·고민 시간이 모두 비어 노선 길이 판단에 줄 증거가 없다. 같은 역 번호가 다시 나오게 하는 기존 규칙(D13)과도 맞다 |
| 툭 = 손가락이 닿는 순간 | 손가락을 **뗄 때** 툭(누른 칸 강조, v3 02) | 44dp 칸 실수 줄이기. 툭이 박자에 대해 100~200ms 늦게 들어가므로 툭 2개 판의 타이밍이 조금 빠듯해진다 — 에뮬레이터·실기기에서 확인 |
| v4 06 움직임 세부(음표 4dp 톡, 킁킁 2번 깜빡, 통화 호가 칸마다 60ms, 별 1 → 1.3 → 1, 졸음 김 120ms 간격, 스피커 고개 까딱) | 효과마다 한 장 그림을 300ms(팅 200ms) 동안 나타났다 사라지게, 버럭만 크기 0.6 → 1.1 → 1. 움직임 줄이기에서는 정지 한 장(한 박자) | 규칙이 읽히는 그림은 같고 세부 움직임은 기기 확인 뒤 다듬는다 |
