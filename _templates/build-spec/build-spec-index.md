---
build-spec: <topic-slug>            # 예: exercise-grading, auth-session, departments/peds
stage: XX-phase/XX-stage            # 이 스펙이 속한 Construction 스테이지
status: DRAFT                       # DRAFT → QUESTIONS_OPEN → READY → IMPLEMENTED
depth: standard                     # minimal | standard | comprehensive
updated: YYYY-MM-DD
---

# Build Spec — <제목>

> **구현 스펙(Build Spec)** = 실제 로직·화면·알고리즘·콘텐츠를 산출하는 스테이지에서, **코딩 전에** SoT(핸드오프/
> PRD/디자인)를 라인 단위로 유도해 "다시 유도하지 않고 바로 구현 가능한" 수준으로 구체화한 것. (FRAMEWORK "구현 스펙")
>
> Build Spec은 **네 개의 1급 아티팩트** + 이 **인덱스**로 구성된다. 각 아티팩트는 자체 상세 템플릿을 가진다:
> - `domain-entities.md` — 엔티티·타입·데이터 shape·관계·상태
> - `business-rules.md` — 불변식·검증·제약·권한 규칙
> - `business-logic-model.md` — 워크플로·알고리즘·상태 전이·시퀀스
> - `frontend-components.md` — 컴포넌트 트리·props·상태·상호작용·API·화면 상태 (조건부)
>
> **이 인덱스**는 넷을 묶고 교차 사항(범위·분해·미해결질문·체크리스트·검증·편차)을 담는다.

## 깊이 티어 — 어떤 아티팩트를 만드나 (frontmatter `depth`)

| 티어 | 대상 | 생성 아티팩트 |
|---|---|---|
| `minimal` | 단순·저위험 | 인덱스만 (필요 시 domain-entities). 인라인 가능 |
| `standard` | 일반(대부분) | 인덱스 + domain-entities + business-rules + (business-logic-model / frontend-components 중 관련) |
| `comprehensive` | 고위험·복잡·비가역 | 인덱스 + 4개 전부 + **§6 NFR·성능** |

> 만들지 않는 아티팩트는 §2 아티팩트 인덱스에 **`N/A + 사유`**로 명시(의도적 생략 증명).

## §0. 개요 & 범위
- **목표(한 줄):** <이 스펙이 산출하는 것>
- **SoT(진실 공급원):** <핸드오프/PRD/디자인 파일 경로 + 라인/컴포넌트>. 재해석이 아니라 **1:1 유도**한다.
- **규모/제약:** <데이터량·화면 수·성능/플랫폼 제약 등>
- **깊이 티어 & 사유:** `<depth>` — <왜 이 티어인지>

## §1. 분해 (Decomposition)
> 무엇을 어떤 단위로 구현하는가. 각 단위의 책임·의존·신규여부.

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
|  |  |  |  |

## §2. 아티팩트 인덱스 (Manifest)
| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ☐/✅/N/A | `./domain-entities.md` 또는 사유 |
| business-rules | ☐/✅/N/A | … |
| business-logic-model | ☐/✅/N/A | … |
| frontend-components | ☐/✅/N/A | … |

## §3. 미해결 질문 (Open Questions)
> 구현 전 반드시 해소. **AskUserQuestion 옵션형**으로 묻고, 확정 결정은 `DECISIONS.md`로 이관 후 여기서 제거.
> 남아 있으면 `status: QUESTIONS_OPEN` — 코딩 착수 금지.

- [ ] Q1: <질문> → (해소 시) DECISIONS `#날짜-키`

## §4. 구현 체크리스트
> 실제 코딩 단위. **구현하며 즉시 `[x]`**. 전 항목 + §5 검증 통과 = `IMPLEMENTED`.

- [ ] <작업 1>

## §5. 검증 계획
- [ ] `tsc`/린트 = 0
- [ ] 단위/통합 테스트: <검증 대상 + 파일>
- [ ] 수동/시각 검증: <절차 + 통과 기준> (프로젝트 검증 SOP 링크)

## §6. NFR · 성능 (comprehensive 전용)
> 정량 목표(지연/부하/동시성/보안/접근성) + 측정 방법. 그 외 티어는 `N/A`.

## §7. 편차 로그 (Deviations) — 구현 후
> SoT 대비 **의도적** 편차 + 근거. 미승인 불일치는 편차가 아니라 버그.

| SoT | 실제 구현 | 사유 |
|---|---|---|
|  |  |  |
