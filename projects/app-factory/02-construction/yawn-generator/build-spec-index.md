---
build-spec: yawn-generator
stage: 02-construction/12-yawn-generator (+ 13-line-mastery, 14-yawn-villains)
status: QUESTIONS_OPEN
depth: comprehensive
updated: 2026-10-18
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
| U14 분석 | `adaptive_result`에 `level`·`evidence`·`graduated` (익명) | U8 | 기존 확장 |

## §2. 아티팩트 인덱스
| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ 초안 | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ 초안 | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ 초안 | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ 초안 | [`frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문 (구현 전 오너 결정)

- [x] **Q1 출시 범위 — 28개 모두 첫 출시 (오너 2026-10-18).** ~~ 노선 28개(빌런 포함) 모두 첫 출시에 / 21개로 출시하고 빌런 노선 7개는 첫 업데이트(「시즌 2」)로? (AI 권고: 코드는 28개 모두 만들고 **원격 설정으로 빌런 노선을 켜고 끄게** — 출시 뒤 반응을 보고 켤 수 있다)~~
- [ ] **Q2 Director(적응형 난이도)의 역할:** (난이도 실험실 2-12 §3.9·§3.10 — 시작점 숨기기 뒤 후보 사이 차이 ≥ 1인 묶음 71%. 오너에게 다시 묻는다) 엮기 판은 무작위 표본으로는 이기는 묶음을 거의 못 찾아(이기는 비율 0.0x%) 지금 `measure`가 「못 푸는 판」으로 버린다. 그래서 (a) **난이도는 계단(노선 길이 적응)이 정하고, Director는 Glicko 기록·분석·대체 흐름만** 맡는다 / (b) 같은 계단에서 시드 후보 3개를 만들어 예측 난이도가 목표에 가까운 판을 고른다(생성 시간 3배·예측식 새로 맞춤 필요). (AI 권고: a — 계단이 이미 플레이어에 맞춰 크기를 조절하고, b는 큰 판 생성 시간이 3배가 된다)
- [x] **Q3 새 노선 소개 판 — 생성기의 첫 역 (오너 2026-10-18).** ~~ (a) **생성기의 첫 역(n=0, 작은 판)**을 소개 판으로 / (b) 노선마다 사람이 만든 소개 판(지금 20개 + 짐수레·빌런 8개 새로). (AI 권고: a — 손으로 만든 소개 판 20개는 대체 판으로 남긴다. 첫 역 손가락 안내는 생성 판의 계획 풀이 첫 툭을 가리킨다)~~
- [x] **Q4 기존 저장 — 새로 시작 (오너 2026-10-18).** 저장 키를 `yawn.map.v2`로, v1은 읽지 않는다(이전 코드 없음). ~~ 아직 출시 전이라 진행 기록은 오너 기기(테스트)에만 있다. (a) **v1 → v2로 옮긴다**(BR Y2-LINE-2) / (b) 새로 시작(v2 빈 저장). (AI 권고: a — 옮김 코드는 작고 테스트로 지킬 수 있다)~~

## §4. 구현 체크리스트

- [ ] U1 엔진: kind `q v o f l j a e`, `C.`·`-.` 해석·검사, `carts`·`tails`, `effDir`, 박자 15단계(BR Y2-ENG-9), 사건 `startle`·`shout`·`call`, `TapResult.armored`
- [ ] U2 엔진 대조: JS 고정 자료(무작위 판 ≥ 2,000 · 플레이 ≥ 20 · 박자 40, 빌런·수레·쩍벌 포함, 순서 중요 사람 먼저 재우는 플레이 포함) → Dart 박자마다 상태 전체 일치
- [ ] U2 규칙 확인: `villain-rules.js` 16개를 Dart 테스트로
- [ ] U3 빠른 박자: U2 자료로 엔진과 일치 + 변이 시험 목록(BLM §2.2 — JS 대조 도구에서 잡힌 14+11+3가지를 Dart 테스트에 「일부러 틀린 구현」으로 넣어 잡히는지)
- [ ] U4 생성기: `weavePlan`·`weaveBuild`·`weaveRun`·`weaveNeutral`·`weaveEssential`·`weaveSweep`·`weaveCheck`·`weaveGenerate` 이식, mulberry32, 안정 정렬, 박자 한도
- [ ] U5 생성기 대조: JS 고정 자료(28노선 × 12역 × 시드 2 + 복습 판 36) → Dart 결과 글자 단위 일치
- [ ] U6 게임 연결: `generate`·`measure`(Q2)·노선 28·소개/대체 판(Q3)·`Station.plan`
- [ ] U7 실패 종류·고민 시간 + isolate
- [ ] U8 노선 길이 연결(계단 n·졸업·복습·`Director` 역할 Q2)
- [ ] U9 저장 v2(새로 시작) + 깨진 저장 견딤
- [ ] U10 렌더러 v4.7 + U11 기준 그림(164장 갱신·새 kind·작은 칸·FX 견본)
- [ ] U12 판 화면(칸 44dp·lod·dense·좌석·수레 움직임·효과층·누른 칸 강조·힌트 계획 풀이·미리 만들기)
- [ ] U13 노선도 28
- [ ] U14 분석 필드
- [ ] 화면 흐름 테스트: 호통 툭 거절, 수레 넘어짐 뒤 이어짐, 쩍벌 꼬리 툭, 졸업 → 새 노선, 복습 판, 저장 이전
- [ ] 판 사진 도구(`tool/shots/boards_test.dart`): 7×11·46dp 판, 빌런 7종 판, 412·360 폭
- [ ] 에뮬레이터 확인(프로필 빌드): 큰 판 생성 시간·노선도·빌런 효과

## §5. 검증 계획
- [ ] `flutter analyze --fatal-infos --fatal-warnings`(저장소 루트) · `dart format` = 0
- [ ] 단위: 엔진 대조(U2) · 빠른 박자(U3) · 생성기 대조(U5) · 규칙 16 · mastery 24 · 저장 이전 · 실패 분류(손으로 만든 판: 박자만 틀린 묶음 = 손 실수, 틀린 사람 = 풀이 실수)
- [ ] 기존 테스트 유지: 역 36 골든(`engine_golden_test`), 풀이기 대조, 화면 흐름
- [ ] 성능(§6) 측정 도구: `tool/bench_gen.dart`를 엮기 생성기로
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
|  |  |  |
