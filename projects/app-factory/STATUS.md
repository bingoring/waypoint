# App Factory — Waypoint Status

**Framework:** [Waypoint](https://github.com/bingoring/waypoint)
**PRD:** [prd.md](prd.md) (v1.0 확정)
**Decisions (audit):** [DECISIONS.md](DECISIONS.md)  
**앱 디자인 프롬프트:** [APP_DESIGN_PROMPT.md](APP_DESIGN_PROMPT.md) (v1, 2-3 로또에 첫 적용 — 결과를 보고 계속 사용 여부 결정)
**Last updated:** 2026-10-16

> ✅ **1-1 승인 (2026-10-13).** PRD v1.0 확정, P1~P6 채택, Q1~Q8 결정(조직 계정·한영 동시·Android 먼저·AdMob 단독·광고 제거 IAP 포함·Wave 1 순서 확정).
> ⏳ **오너 선행 작업:** 사업자등록 → D-U-N-S → Play 조직 계정 개설, KIPRIS 상표 확인 (3-1 전까지). `smallmatter.app` 결제 완료(2026-10-13, 가비아) — 레지스트리 반영은 3-1 전 재확인. 스튜디오명 Smallmatter, 앱 ID `app.smallmatter.<slug>` 확정.
> ✅ **1-2 승인 (2026-10-13).** 코어/앱 경계·`app.yaml`·광고 정책·원격 설정·분석 계약 확정. 광고 제거 ₩2,500 / $1.99, 전면 광고 보수적 기본값, 보상형 실패 시 보상 지급.
> ✅ **1-3 승인 (2026-10-13) → Inception 완료.** Flutter 3.47.7 + pub workspace·Melos 8.9, 앱별 독립 프로젝트·Firebase, GitHub Actions + fastlane, §7 품질 기준 확정.
> ✅ **2-1 Core Packages 승인 (2026-10-13).** 패키지 7개·CI·검증 앱, 테스트 124개. 메모리 예산 조정(G1: 200/300MB + 코어 항목별).
> ✅ **2-2 App Generator + Release Pipeline 승인 (2026-10-13).** factory_cli 6개 명령·템플릿·fastlane·release 워크플로.
> ✅ **2-3 로또 번호 생성기 승인 (2026-10-14).** 출시 전 남은 일(3-1): `app-ads.txt`·방침 게시(smallmatter.app DNS 대기), 문구 검토 (AdMob 단위 완료). 10/18 첫 당첨 자동 등록 확인.
> ✅ **2-4 연봉 실수령액 계산기 승인 (2026-10-14).** 메모리 예산 초과(219~237MB)는 1.1 메모리 점검에서. 코어 `BannerSlot` 자리 유지, 성능 측정 절차 채택. 출시 전 남은 일(3-1): `app-ads.txt`·방침 게시(smallmatter.app DNS 대기), 문구 검토 (업로드 키 시크릿·AdMob 단위 완료).
> ✅ **2-5 소음 측정기 승인 (2026-10-15).** 첫 ko·en 앱, 자체 dB 엔진. AdMob·업로드 키 완료. 3-1 실기기: 정확도·앱 오프닝 광고 중 마이크 정지·GA 경고.
> ⏸ **2-6 물 마시기 알림 보류 (2026-10-15, 오너).**
> ⏸ **2-7 조각보 블록 퍼즐 보류 (2026-10-16, 오너).** 구현 완료(`IMPLEMENTED`) 상태로 멈춤. 재개 시 남은 일: AdMob 단위 4개·업로드 키 시크릿(오너) → 릴리스 G1 측정, 드래그 손맛은 3-1 실기기.
> ✅ **2-8 하이퍼캐주얼 신작 컨셉 승인 (2026-10-16).** 5종 모두 개발: 하품 릴레이 → 새떼 그림 → 번짐 → 샴페인 타워 → 눈꽃 가위. 컨셉마다 HTML 프로토타입 → 오너 재미 판정 → Flutter.
> ✅ **하품 릴레이 프로토타입 통과 (2026-10-16, 오너).** 앱 화면 이모지 금지 → 캐릭터·아이콘을 미리 그려 준비(목록: `hypercasual/yawn-relay-prototype-2026-10-16.md` §3, 제작 방식은 오너 결정). 다음 프로토타입: 새떼 그림.
> 🚧 **Yawn! (2-9) 화면 구현 1차 끝 (2026-10-16), 오너 「마음에 든다」.** 다음 세션은 [`yawn-relay/handoff-2026-10-16.md`](02-construction/yawn-relay/handoff-2026-10-16.md)부터 — 에뮬레이터 검사 → 릴리스 빌드 → `IMPLEMENTED`. 오너: FC §7.2 D10~D18 확인, 후보 기믹 판정, AdMob·Firebase·업로드 키·BigQuery, 상표.
> 🧪 **Yawn! 에뮬레이터 검사·릴리스 리허설 (2026-10-17).** 정적 검사 통과, AAB 최대 다운로드 11.57MB / 25MB, `validate --release`는 AdMob ID만 남음. 화면 전부 ko·en·다크·130%·애니메이션 끔 정상. 문제 3개 **고침** (FC §9.1, DECISIONS 2026-10-17): 배너 높이 처음부터 예약(모든 앱 공통 코어), 생성 판을 사람 범위로 자름, 도착 안내 때 헤더 흐림.
> 📋 **Yawn! Build Spec 체크리스트 정리·박자 측정 (2026-10-17).** §4·§5 20개 중 14개 근거와 함께 체크. 박자: 가상 시계 누적 오차 0, 실제 간격 평균 650.3ms·±1프레임 56/58, 백그라운드 복귀 뒤 이어짐 → 통과(§5.1). `IMPLEMENTED`까지 남은 것: 화면 테스트 3개(AI) · Firebase·AdMob·업로드 키·G1·`sync_site`(오너 몫 이후).
> ✅ **Yawn! Build Spec `IMPLEMENTED` → 2-9 승인 대기 (2026-10-17).** 화면 테스트 3개 추가(니어미스 → 한 번 더 툭, 커피 거절, 재시작 뒤 진행), 테스트 30개 통과. 오너: D10·D17·D18 확인, 후보 기믹 판정. 승인 뒤 R-1 독립 리뷰.
> 🧪 **Yawn! 기믹 확장 2 (2026-10-17).** 후보 6종 출시 확정. 새 기믹 8종(고양이·서서 가는 승객·커플·근시·까치발·이어폰·터널·알람) 프로토타입 역 21~36, 풀이기 검증 → **오너 판정 대기**(기록 §5.3). 판 상한 5열 × 8행 적용, 큰 크기 단계는 풀이기 최적화·단계 선택 뒤로 보류. Claude Design 요청서 v2 준비.
> ⚙️ **풀이기 최적화·크기 단계 (2026-10-17).** 분기 탐색(결과 동일, 대조 테스트) + 큰 판 표본 어림 → 40/18/3 단계 측정 p95 2.8초 → 50ms, 힌트 최대 4ms. `factory_adaptive` 크기 단계 열림(`sizeUnlockAt`), Yawn! 단계 5개 `[0,10,30,80,200]`판. 예측식 재적합은 출시 뒤 실제 데이터로.
> 🎨 **디자인 핸드오프 v2 확인 (2026-10-17).** 요청서 v2 묶음 A~E 모두 충족, 게임 규칙과 어긋남 없음, SVG 정상(메타데이터·CSS 변형 때문에 렌더러를 Dart로 이식). 오너 결정 3개: 노선 20색 통일, 툭 표시 숫자만, 새 8종 판정 — `yawn-relay/handoff-v2-review-2026-10-17.md`.
> ✅ **핸드오프 v2 결정 (2026-10-17).** 노선 20색·툭 숫자만 앱 반영, 새 8종 출시 포함(노선 20개), 출입문·기둥 디자이너 정정 요청서 준비(`yawn-relay/design-correction-v2-2026-10-17.md`). 다음: 8종 Flutter 구현을 위한 2-9 Build Spec 보강.
> 📝 **2-11 기믹 확장 Build Spec 초안 (2026-10-17).** 노선 7~20 연결 전체(엔진 상태 격자·새 8종 규칙·박자 순서 11단계·판당 기믹 상한·렌더러 v2·효과·터널·노선 아이콘). 미해결 질문 Q1~Q4.
> 📝 **2-11 Build Spec `READY` (2026-10-17).** 질문 4개 해소 — 핸드오프 순서, 20개 모두 켜고 출시, 디자이너 v2.1(문·기둥 정정) 그대로 구현, 노선 여는 간격 유지(리서치: Royal Match 초반 약 10판). 오너가 구현 착수를 승인했다.
> 🔧 **2-11 구현 U1~U5 (2026-10-17, 메인 `0510003`).** 새 8종 엔진·상태 격자·박자 11단계, 역 1~36 골든이 solver.js와 일치, 생성기 기믹 상한·새 기믹 넣기, 노선 20개. 테스트 59개 통과, 노선별 측정 p95 ≤ 84ms·힌트 최대 34ms. 다음: 렌더러 v2(U6)·화면 효과(U7)·노선도 아이콘(U8).
> ✅ **2-11 구현·검증 끝 (2026-10-17) → `AI_PROPOSED`.** 렌더러 v2.1 Dart 이식(기준 그림 164장 일치), 판 화면 v2(시선선 6종·기믹 효과·터널·문·알람), 노선 아이콘 20개, 화면 흐름 테스트. **고난이도 시험**(오너 요청): 가장 큰 단계 노선 20 × 120판·큰 판 탐색↔전수 14개 일치·표본 오차 최대 1.5%p·퍼징 80만 박자 위반 0·후반 300판~ 목표 대비 9.2%p. 힌트 최대 233→21ms, 걷는 판 측정 최대 241→85ms로 고침. 편차 11건(Build Spec §7). 다음: 오너 확인 → R-1 독립 리뷰(2-9·2-11) → 3-1.
> 🔍 **R-1 독립 리뷰 (2026-10-17) → `AI_PROPOSED`.** 컨텍스트가 분리된 리뷰어 3명(정확성·화면/수명·보안/정책, 하나는 다른 모델). 엔진·풀이기는 프로토타입 차분 시험 1.5만 판 불일치 0. 채택 수정: 노선 기믹 빠진 판(이어폰 노선 30%), 동의 철회 미반영, 화면 잠김·재진입, 노선도 매 프레임 문단 재생성, 배너 재펼침, 진행 저장 전체 초기화, 출시 검사 §7.3·워크플로 게이트·bundletool 해시. **저장소 CI가 10-16부터 실패 중이던 것을 발견해 고침**(quality·security 통과). 반박·보류 10건 근거 기록. 3-1로: Firebase 키 제한, 심볼 업로드, 방침 확정, 액션 SHA 고정.
> 🗺️ **개발 대기열:** 하품 릴레이(아트 → Build Spec) · 새떼 그림 · 번짐 · 샴페인 타워 · 눈꽃 가위 · **로그라이크 2종(사다리 원정, 딱지왕 — 고도화 설계 `roguelike/design-direction-2026-10-16.md`)**.
> 📌 **3-1 공통:** 네 앱 모두 런처 아이콘이 아직 Flutter 기본 아이콘이다.

---

## Phase 1 — Inception (What)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 1-1 Context Synthesis | [01-context-synthesis.md](01-inception/01-context-synthesis.md) | HUMAN_APPROVED |
| 1-2 Domain Model | [02-domain-model.md](01-inception/02-domain-model.md) | HUMAN_APPROVED |
| 1-3 Architecture Decision ⚠️ | [03-architecture-decision.md](01-inception/03-architecture-decision.md) | HUMAN_APPROVED |

## Phase 2 — Construction (How)

> 1-3 §11에서 확정. 각 스테이지는 구현 전에 Build Spec을 쓴다(FRAMEWORK "구현 스펙").

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 2-1 Core Packages (저장소·workspace·lint·CI 게이트, factory_core~factory_ui) · comprehensive | [01-core-packages.md](02-construction/01-core-packages.md) · [Build Spec](02-construction/core-packages/build-spec-index.md) | HUMAN_APPROVED |
| 2-2 App Generator + Release Pipeline · standard | [02-app-generator.md](02-construction/02-app-generator.md) · [Build Spec](02-construction/app-generator/build-spec-index.md) | HUMAN_APPROVED |
| 2-3 로또 번호 생성기 · standard | [03-lotto.md](02-construction/03-lotto.md) · [Build Spec](02-construction/lotto/build-spec-index.md) | HUMAN_APPROVED |
| 2-4 연봉 실수령액 계산기 · standard | [04-salary.md](02-construction/04-salary.md) · [Build Spec](02-construction/salary/build-spec-index.md) | HUMAN_APPROVED |
| 2-5 소음 측정기 · standard | [05-noise.md](02-construction/05-noise.md) · [Build Spec](02-construction/noise/build-spec-index.md) | HUMAN_APPROVED |
| 2-6 물 마시기 알림 · standard | (보류, DECISIONS 2026-10-15) | DEFERRED |
| 2-7 Game Kit + 조각보 블록 퍼즐 · comprehensive | [07-game-kit-puzzle.md](02-construction/07-game-kit-puzzle.md) · [Build Spec](02-construction/puzzle/build-spec-index.md) (보류, DECISIONS 2026-10-16) | DEFERRED |
| 2-8 하이퍼캐주얼 신작 컨셉 · 조사·결정 | [08-hypercasual-concept.md](02-construction/08-hypercasual-concept.md) | HUMAN_APPROVED |
| 2-9 Yawn! (하품) · comprehensive | [09-yawn-relay.md](02-construction/09-yawn-relay.md) · [Build Spec](02-construction/yawn-relay/build-spec-index.md) | AI_PROPOSED (Build Spec `IMPLEMENTED` 2026-10-17 — 오너 승인 대기) |
| 2-10 공통 적응형 난이도 · 조사·설계 | [10-adaptive-difficulty.md](02-construction/10-adaptive-difficulty.md) | AI_PROPOSED (Build Spec `READY`, `factory_adaptive` 구현 끝 — 남은 일: `fit_difficulty.dart`, `pool.json` 도구) |
| 2-11 Yawn! 기믹 확장 (노선 7~20) · comprehensive | [11-yawn-mechanics.md](02-construction/11-yawn-mechanics.md) · [Build Spec](02-construction/yawn-mechanics/build-spec-index.md) | AI_PROPOSED (Build Spec `IMPLEMENTED` — 오너 확인 대기) |

## Phase R — Independent Code Review 🔍 (Construction → Operations 게이트)

> 작성자와 **컨텍스트가 분리된** 독립·적대적 리뷰어가 코드를 검토한다. FRAMEWORK "리뷰 게이트" 참조.

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| R-1 Independent Code Review | [01-independent-review.md](0R-review/01-independent-review.md) | AI_PROPOSED (독립 리뷰어 3명 — HIGH 5·MEDIUM 15건 수정, CI 통과 — 오너 승인 대기) |

## Phase 3 — Operations (Ship)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 3-1 Store Release ⚠️ (계정·서명·정책 체크리스트·스토어 등록) | (예정) | PENDING |
| 3-2 Portfolio Monitoring (30일 지표 → 확장·유지·중단 판단) | (예정) | PENDING |

---

## AI 진입점

> AI는 위 테이블에서 `PENDING` 상태인 가장 앞 스테이지부터 작업을 시작하세요.
> 규칙: [`FRAMEWORK.md`](../../FRAMEWORK.md) 참조
