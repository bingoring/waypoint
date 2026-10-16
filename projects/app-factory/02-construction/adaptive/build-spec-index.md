---
build-spec: adaptive
stage: 02-construction/10-adaptive-difficulty
status: QUESTIONS_OPEN
depth: comprehensive
updated: 2026-10-16
---

# Build Spec — 공통 적응형 난이도 `factory_adaptive`

## §0. 개요 & 범위
- **목표(한 줄):** 게임이 「판 생성기 + 측정기(풀이기)」만 꽂으면, 기믹 커리큘럼·실력 추정·목표 난이도·상황 신호·생성과 대체·익명 보정을 해 주는 공통 패키지 `packages/factory_adaptive`. 첫 소비자는 2-9 하품 릴레이.
- **SoT:** 오너 요구(2-10 입력), DECISIONS 2026-10-16(익명 보정, 알리고 끌 수 있게, 기믹 간격·노선 선택), 조사 [`research-2026-10-16.md`](research-2026-10-16.md), 스테이지 문서 [`../10-adaptive-difficulty.md`](../10-adaptive-difficulty.md) §2 설계안.
- **규모:** 순수 Dart 핵심(Director·커리큘럼·Glicko-2·목표·예측·생성 루프) + Flutter 연결(isolate·저장·원격 설정·분석·설정 타일) + 도구 2개(시뮬레이터, 보정).
- **깊이 티어:** `comprehensive` — 모든 하이퍼캐주얼이 의존하는 공통 모듈이고, 플레이어 경험과 정책(다크 패턴·개인정보)에 직접 닿는다.

## §1. 분해
| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `lib/src/core/` (순수 Dart) | `AdaptiveGame` 인터페이스, `Director`, 커리큘럼, Glicko-2, 목표, 예측 | `factory_game_kit/rng.dart` | 신규 |
| `lib/src/flutter/` | isolate 생성 실행기, `KeyValueStore` 저장, 원격 설정 읽기, 분석 이벤트, 상황 신호, `AdaptiveTile` | `factory_core`, `factory_runtime`, `connectivity_plus` | 신규 |
| `tool/` (게임별 `simulate.dart`, 공통 `fit_difficulty.dart`) | 가상 플레이어 시뮬레이션, 출시 뒤 보정 | core | 신규 |
| `check_deps` 규칙 | `factory_adaptive`는 `factory_core`·`factory_runtime`·`factory_game_kit`만 의존(앱·광고 구현 의존 금지) | | 규칙 추가 |

## §2. 아티팩트 인덱스
| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ DRAFT | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ DRAFT | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ DRAFT | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ DRAFT (설정 타일 하나) | [`frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문
- [ ] **Q1 BigQuery 연결 (오너 작업):** 출시 뒤 보정(BLM §6)에는 Firebase Analytics 원시 이벤트가 필요하다. Firebase 프로젝트에서 BigQuery 연결을 켜야 한다(무료 샌드박스 범위로 시작 가능 [추정 — 연결 시 확인]). 각 게임 출시 전에 켜면 된다. 대안은 Analytics 화면의 집계만 쓰는 것인데, 기믹별 보정이 어렵다.
- [ ] **Q2 초기 수치 확인:** 목표 패배 확률 10% → 35%(120판에 걸쳐), 톱니 `[-5, 0, +5, +10, -10]%p`, 2연패 −8%p. 수치는 시뮬레이션 뒤 다시 보여 드리고 원격 설정으로 바꿀 수 있다. 출발점으로 괜찮은가?

## §4. 구현 체크리스트
- [ ] 패키지 생성 + `check_deps` 규칙
- [ ] core: 인터페이스·Director·커리큘럼·목표·예측·Glicko-2 + 단위 테스트(BLM §7)
- [ ] flutter: isolate 실행기, 저장(`adaptive.<game>.v1`), 원격 설정 키, 분석 이벤트 `adaptive_result`, 상황 신호, `AdaptiveTile`(ko·en)
- [ ] 하품 릴레이 어댑터: `generate`(구성형 생성기, 프로토타입 `gen2.js` 방식 이식) · `measure`(풀이기) · 소개 판 = 프로토타입 역
- [ ] `pool.json` 도구: 기믹 묶음별 검증된 판 미리 생성
- [ ] 시뮬레이터 + 결과 문서 `sim-yawn-<날짜>.md` → 기본 설정값 확정
- [ ] 보정 도구 `fit_difficulty.dart` (출시 뒤 사용)
- [ ] 앱 문서: data-safety·개인정보처리방침에 「게임 진행 기록」, 스토어 설명 한 줄(A-UI-2)

## §5. 검증 계획
- [ ] 분석·포맷·의존 검사, 패키지 라인 커버리지 ≥ 90%
- [ ] BLM §7 테스트 전부 (Glicko-2 골든 포함)
- [ ] 하품 릴레이 시뮬레이션: 판별 승률 목표 ±5%p, 모든 기믹 해금 중앙값 ≥ 150판, 3연패 이상 비율 기록
- [ ] 실기기: 생성 시간 p95 ≤ 300ms(isolate), 판 전환 때 프레임 끊김 없음
- [ ] 분석 이벤트 디버그뷰로 매개변수 확인, 실력·상황 신호가 없는지 확인(A-PRIV-1)

## §6. NFR
| 항목 | 목표 | 측정 |
|---|---|---|
| 생성 시간 | p95 ≤ 300ms, UI 스레드 0ms(isolate) | 실기기 프로파일 |
| 메모리 | isolate 포함 추가 ≤ 20MB | G1 측정 절차 |
| 저장 | 판마다 1회, ≤ 4KB | 단위 테스트 |
| 개인정보 | 기기 밖으로 실력·상황 신호 0건 | 이벤트 검사 테스트 |
| 결정성 | 같은 상태·시드 → 같은 판 | 단위 테스트 |
| 원격 조정 | §3 표 키 전부 원격 설정으로 변경 가능, 잘못된 값이면 기본값 | 단위 테스트 |

## §7. 편차 로그 — 구현 후
| SoT | 실제 구현 | 사유 |
|---|---|---|
| | | |
