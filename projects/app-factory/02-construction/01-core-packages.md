---
phase: 02-construction
stage: 01-core-packages
status: AI_PROPOSED
updated: 2026-10-13
---

# [Stage 2-1] Core Packages

## 목적

메인 저장소의 골격(pub workspace·Melos·FVM·공통 lint·CI 품질 게이트)과 공통 코어 패키지
(`factory_core`·`factory_runtime`·`factory_ads`·`factory_firebase`·`factory_iap`·`factory_ui`·`factory_lints`)를 구현한다.
모든 앱이 이 패키지 위에서 만들어지므로, 1-2 계약과 1-3 §7 품질 기준을 코드로 고정하는 단계다.

## 입력 (Inputs)

- [`../01-inception/02-domain-model.md`](../01-inception/02-domain-model.md) — 계약 전체 (승인 결과 D1~D3 포함)
- [`../01-inception/03-architecture-decision.md`](../01-inception/03-architecture-decision.md) — §3 구조, §4 라이브러리, §7 품질 기준, §8 계약 확장
- [`../DECISIONS.md`](../DECISIONS.md)

## 체크리스트

- [x] 메인 저장소 생성(`bingoring/app-factory`, 비공개), waypoint 서브모듈 연결 (2026-10-13)
- [x] Build Spec 작성 — [`core-packages/build-spec-index.md`](core-packages/build-spec-index.md) (comprehensive)
- [x] Build Spec 미해결 질문 해소 → `READY` 승인 (2026-10-13)
- [x] 구현 (Build Spec §4 체크리스트) — 저장소 `bingoring/app-factory` 커밋 `ac86cc3`까지
- [x] 검증 (Build Spec §5) — 메모리 예산만 미달, 예산 조정 결정 대기 (Build Spec §6 측정 결과)

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

이 스테이지의 설계 결정은 1-2·1-3에서 이미 승인되었으므로, 이 문서에서는 **구현 방식의 핵심 선택**만 요약하고 상세는 Build Spec에 둔다.

1. **정책 엔진과 서비스 구현을 순수 Dart(`factory_core`)에 둔다.** 광고 SDK·Firebase·결제는 `factory_core`가 정의한 *게이트웨이 인터페이스*
   뒤에 숨기고, 어댑터 패키지가 이를 구현한다. 그 결과 빈도 판정·보상형 처리·광고 제거·리뷰 요청 같은 핵심 로직 전부를
   Flutter·기기 없이 단위 테스트할 수 있다(1-3 §7.5 커버리지 90% 목표의 전제).
2. **AppConfig는 런타임에 YAML을 읽지 않는다.** `app.yaml` → Dart 상수 코드 생성은 2-2 `factory_cli`가 맡고,
   2-1은 `AppConfig` 모델과 검증기를 `factory_core`에 둔다. 검증기는 런타임(디버그 assert)과 CLI가 공유한다.
3. **검증용 예제 앱 `examples/core_demo`를 둔다.** 출시하지 않는 앱이며, 부트스트랩·광고(테스트 ID)·결제 흐름을 에뮬레이터에서
   통합 테스트하는 용도다. 출시 앱(`apps/`)과 디렉터리를 분리해 릴리스 파이프라인이 집지 않게 한다.
4. **CI 게이트 중 앱이 있어야 하는 검사**(권한 허용 목록, 다운로드 크기)는 2-2에서 `factory_cli validate`와 함께 추가한다.
   2-1의 CI는 format·analyze(경고 0)·test·커버리지·의존 방향·금지 import·비밀 스캔·OSV 스캔을 강제한다.

### 구현 결과 요약 (2026-10-13)

- 패키지 7개(`factory_lints`·`core`·`runtime`·`ads`·`firebase`·`iap`·`ui`) + 검증 앱 `examples/core_demo` + CI(품질·보안 2개 잡, GitHub에서 통과).
- 테스트 124개(core 88 · runtime 12 · ads 7 · firebase 5 · iap 3 · ui 9 · 통합 1), `factory_core` 라인 커버리지 99%, 위젯 테스트 전체 누수 검사 0건.
- 구현·검증 중 발견해 고친 결함 4건: 보상형 광고 직후 앱 오프닝 광고 연속 노출, 초기화 중 판정 오분류(`disabled`), 서비스 해제 누락(누수), 복원 안내 스낵바 누적. 모두 회귀 테스트 포함.
- 편차 13건은 Build Spec §7에 기록했다.

### 미해결 질문

| # | 질문 | AI 기본안 |
|---|------|----------|
| G1 | 1-3 §7.4 메모리 예산 조정 | 앱 전체 PSS: 유틸리티 **≤ 200MB**, 게임 **≤ 300MB**(에뮬레이터 기준, 측정 173MB). 대신 코어가 통제하는 항목을 따로 예산화: 광고 객체 ≤ 20MB(측정 11MB), 코어·UI 추가분 ≤ 40MB(측정 36MB). 실기기 확보 시 재측정 |

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] Build Spec이 `READY`로 승인되었는가? (구현 착수 승인)
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?
- [ ] 메모리 예산 조정안(아래 G1)에 동의하는가?

## 다음 단계

승인 후 → `STATUS.md`에서 2-1 상태를 `HUMAN_APPROVED`로 업데이트 → 2-2 App Generator + Release Pipeline
