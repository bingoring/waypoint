---
build-spec: yawn-relay
stage: 02-construction/09-yawn-relay
status: QUESTIONS_OPEN
depth: comprehensive
updated: 2026-10-16
---

# Build Spec — 하품 릴레이 (가칭)

## §0. 개요 & 범위
- **목표(한 줄):** 시선을 따라 하품이 옮는 퍼즐 `apps/yawn`(가칭)을 ko·en으로 출시한다. 툭 한두 번으로 지하철 한 칸을 모두 재운다.
- **SoT:** ① 규칙 = 메인 저장소 `prototypes/yawn-relay/index.html` `#engine`(오너 재미 판정 통과, 2026-10-16) — **1:1 이식, 판정 규칙 변경 금지** ② 레벨 지표 = `prototypes/yawn-relay/solver.js`(프로토타입 기록 §2 표를 재현) ③ 화면·캐릭터 = Claude Design 핸드오프(수령 예정, [`design-brief-2026-10-16.md`](design-brief-2026-10-16.md)).
- **규모:** 화면 4개 + 판 위 카드 2개, 역 N개(Q1), 승객 종류 5, 판 최대 6×6.
- **깊이 티어:** `comprehensive` — 2-8 §6 결정. 레벨 생성기·풀이기, 박자 엔진, 캐릭터 에셋 파이프라인이 있다.

## §1. 분해

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `lib/domain/engine.dart` | 판 파싱·시선·박자·툭·승패 (순수 Dart) | `factory_game_kit/rng.dart` | 신규 (프로토타입 이식) |
| `lib/domain/solver.dart` | 풀이기 (앱은 힌트 검증용, 도구는 레벨 검사) | engine | 신규 |
| `tool/build_stations.dart` | 생성기 + 풀이기 → `assets/levels.json` | engine, solver | 신규 (2-7 `build_levels` 패턴) |
| `lib/data/` | 진행·시도 수 저장 | `KeyValueStore` | 2-7 `ProgressStore` 패턴 |
| `lib/ui/` | 노선도·객차·카드·설정, 승객 스프라이트 | `factory_ui`, `factory_ads`, 핸드오프 | 신규 |
| 보상형·전환 광고 | `RewardGate`·`RoundAds` | `factory_game_kit` | **기존 재사용** |
| 효과음·진동 | `GameFeedback` (미리 불러오기 비동기, 2-7 수정분) | `factory_game_kit` | **기존 재사용** |
| 효과음 합성 | 툭·하품·꾸벅·승리·거절 WAV | 2-7 `gen_sfx.dart` 패턴 | 패턴 재사용 |
| R8 keep 규칙(Room) | 릴리스 시작 직후 종료 방지 | 템플릿 | **기존(2-7에서 템플릿에 반영)** |

2-7 대비 새로 만드는 것은 엔진·생성기·화면·캐릭터뿐이다. 광고 게이트·피드백·저장·레벨 도구·테스트 구조·5단계 검사 형식은 재사용한다.

## §2. 아티팩트 인덱스
| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ DRAFT | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ DRAFT | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ DRAFT | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ DRAFT (핸드오프 뒤 §7 매핑) | [`frontend-components.md`](frontend-components.md) |
| (부속) Claude Design 요청서 | ✅ DRAFT | [`design-brief-2026-10-16.md`](design-brief-2026-10-16.md) |

## §3. 미해결 질문
> 해소됨 (2026-10-16, DECISIONS): Q3 게임 라인 보충 승인 · Q4 캐릭터는 Claude Design · Q5 광고 배치 확정.

- [x] Q1 1차 출시 범위 → 2-10 적응형 생성(역 끝없이, 노선 선택)으로 해소 (DECISIONS 2026-10-16)
- [x] Q2 잠버릇 도감 → 1.1 (DECISIONS 2026-10-16)
- [ ] **Q6 이름 (남은 유일한 질문):** 오너가 「하품 릴레이」를 다시 정하기로 함(2026-10-16). 이전 문구 — 「하품 릴레이 / Yawn Relay」 확정 여부와 상표 확인. 요청서는 가칭으로 보낸다(로고 작업 없음).

## §4. 구현 체크리스트
- [ ] `factory new yawn --category game` (slug·이름은 Q6), `factory firebase`
- [ ] `app.yaml`: placements `banner_map`·`interstitial_station`·`rewarded_extra_tap`·`rewarded_hint`, keyAction `clear_station`, events
- [ ] domain 엔진 이식 + BLM §4 골든 테스트 (solver.js 출력 16개 수치 일치)
- [ ] 풀이기·생성기·`levels.json` (Q1 역 수) + 결정성 테스트
- [ ] 효과음 합성 5종
- [ ] 캐릭터 스프라이트 파이프라인: 핸드오프 SVG → @2x·@3x 아틀라스 + 프레임 표
- [ ] UI: 노선도·객차·카드·설정 (핸드오프 기준), ko·en
- [ ] 위젯 테스트: 툭 → 연쇄 → 승리 → 다음 역(전면 판정), 니어미스 → 한 번 더 툭, 3번 실패 → 힌트, 커피 거절, 앱 재시작 뒤 진행 유지, 누수 0
- [ ] store 문구·data-safety·방침 → `sync_site`
- [ ] 릴리스 리허설: 키·AAB·`size`·`validate --release`

## §5. 검증 계획
- [ ] 분석·포맷·의존 검사·`validate`
- [ ] 골든: 프로토타입 8개 역의 시작점·니어미스·이기는 묶음이 solver.js와 같다
- [ ] 모든 역: 풀이기 `winningStarts ≥ 1`, BR Y-LV-2·3 조건
- [ ] 에뮬레이터: 전 화면 ko·en·다크·글자 130%, 프롬프트 5단계 검사(FC §9)
- [ ] 박자 정확도: 프로파일 빌드에서 650ms ± 1프레임, 백그라운드 복귀 뒤 이어짐
- [ ] G1 측정 절차(PSS·콜드 스타트, AdMob 단위 등록 뒤 릴리스 빌드)
- [ ] 실기기(3-1): 탭 반응, 하품 애니메이션 프레임, 효과음 지연

## §6. NFR

| 항목 | 목표 | 측정 |
|---|---|---|
| 프레임 | 하품 연쇄 중 16ms 이하(승객 18명 동시 애니메이션) | 프로파일 빌드 DevTools, 실기기 3-1 |
| 박자 | 650ms, 누적 오차 없음(시간이 아니라 박자 수로 판정) | 엔진 테스트 + 프로파일 |
| 탭 반응 | 탭 → 눌림 표시 1프레임 안 | 위젯 테스트 |
| 메모리·시작 | PSS ≤ 300MB(게임 예산), 콜드 스타트 ≤ 1.5초 | G1 |
| 크기 | 다운로드 ≤ 25MB (스프라이트 아틀라스 포함) | `factory size` |
| 판 크기 | 최대 6×6 → 360dp 폭에서 칸 ≥ 56dp | 레이아웃 테스트 |
| 오프라인 | 모든 기능 동작 | 비행기 모드 |
| 레벨 도구 | 역 하나 검사 1초 안팎, 전체 생성 1분 이내 | 도구 실행 시간 |

## §7. 편차 로그
| SoT | 실제 구현 | 사유 |
|---|---|---|
| 프로토타입 이모지 얼굴·배지 | 전용 스프라이트 | DECISIONS 2026-10-16 이모지 금지 |
| 프로토타입 「역 목록」 카드 | 노선도 화면 | 진행 시각화·볼거리 (FC §3.1) |
| 프로토타입 「광고 보고 한 번 더 툭」만 | + 「광고 보고 힌트」(3번 실패 뒤) | 막혔을 때만 힌트(리서치 §3, Arrows) — DECISIONS 2026-10-16 |
