---
name: build-spec
description: 로직·화면·알고리즘·콘텐츠를 산출하는 waypoint 스테이지에서 코딩 전에 구현 스펙(Build Spec)을 쓸 때 사용한다.
---

> 이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다. 없으면 그 레포의 `docs/dlc/FRAMEWORK.md`(duty는 `waypoint/FRAMEWORK.md`)를 따른다.

## 구현 스펙 (Build Spec)

스테이지 문서의 `AI Proposal`은 **무엇을·왜**(설계 결정)를 다룬다. 하지만 실제 **로직·화면·알고리즘·콘텐츠**를 산출하는
스테이지는, 결정만으로는 구현 시 매번 SoT(핸드오프/PRD/디자인)를 재해석하게 되고 **누락·불일치**가 조용히 생긴다.
이를 막기 위해 **코딩 전에 구현 스펙(Build Spec)** 을 쓴다. (AI-DLC functional-design 차용 — 단, 우리 방식으로:
유닛 병렬분해·persona·user-story·raw audit.md 없이, **네 아티팩트 + 인덱스**로.)

### 트리거 — 언제 Build Spec이 필요한가
- **필수**: 스테이지가 실제 로직/화면/알고리즘, 또는 콘텐츠 시리즈(예: 부서 인테리어)를 산출한다.
- **불필요(린 유지)**: 순수 설계·결정·조사 스테이지 → 기존처럼 `AI Proposal`만.

### 구성 — 네 아티팩트 + 인덱스
Build Spec은 각각 **자체 상세 템플릿**을 가진 네 개의 1급 아티팩트와, 이를 묶는 인덱스로 이뤄진다. 각 아티팩트는
관심사를 분리해 **정밀하게** 다룬다(뭉치면 에러·데이터 계약·엣지케이스가 조용히 누락된다):

| 아티팩트 | 다루는 것 | 템플릿 |
|---|---|---|
| **domain-entities** | 엔티티·타입·데이터 shape·관계·상태·영속성·allowed-set | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/domain-entities.md` |
| **business-rules** | 불변식·검증·제약·권한 규칙·엣지케이스 매핑 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/business-rules.md` |
| **business-logic-model** | 워크플로·알고리즘·상태 전이·시퀀스·통합 지점 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/business-logic-model.md` |
| **frontend-components** (조건부) | 컴포넌트 트리·props·상태·상호작용·API·화면 상태 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/frontend-components.md` |
| *인덱스* | 개요·범위·분해·아티팩트 매니페스트·미해결질문·체크리스트·검증·NFR·편차 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/build-spec-index.md` |

### 원칙
1. **SoT 1:1 유도.** SoT를 "재해석"이 아니라 라인 단위로 유도해, **다시 유도하지 않고 바로 구현 가능한** 수준으로
   구체화한다(타입/좌표/props/데이터 shape/엣지케이스까지).
2. **관심사 분리 = 완결성.** 네 아티팩트로 나눠 각각을 정밀하게. 무관한 아티팩트는 만들지 말되 인덱스 매니페스트에
   **`N/A + 사유`**(의도적 생략 증명). 아티팩트 간 중복 서술 금지 — 링크로 참조.
3. **적응형 깊이 티어.** `minimal`(인덱스만) · `standard`(인덱스+domain-entities+business-rules+관련 1개) ·
   `comprehensive`(4개 전부 + NFR). 티어별 생성 아티팩트는 인덱스 템플릿 표에 정의.
4. **Plan-first + 옵션형 질문 루프.** 애매함은 인덱스 §미해결 질문에 모으고 **구현 착수 전 `AskUserQuestion`(옵션형)
   으로 해소**, 확정 결정은 `DECISIONS.md`로 이관(원시 트랜스크립트 미적재). 미해소면 `status: QUESTIONS_OPEN`, 코딩 금지.
5. **체크리스트로 실행 추적.** 인덱스 §구현 체크리스트를 **구현하며 즉시 체크**. 전 항목 + §검증 통과 = `IMPLEMENTED`.
6. **편차는 승인 후 기록.** SoT 대비 의도적 편차만 §편차 로그에. 미승인 불일치는 편차가 아니라 버그다.

### 위치 (하이브리드)
- **작으면 인라인/압축**: 인덱스 하나에 필요한 아티팩트를 섹션으로 접어 넣음(minimal 티어).
- **크면 분리(기본 권장)**: `docs/waypoint/{phase}/<topic>/`에 **아티팩트별 파일**(인덱스 + 4). 콘텐츠 시리즈는
  항목마다 자체 디렉토리(예: `departments/<dept>/` — 부서당 5파일). 스테이지 문서에서 링크.
- 상태 흐름: `DRAFT → QUESTIONS_OPEN → READY → IMPLEMENTED`. 스테이지 승인 게이트는 **READY**(구현 착수 승인) 후
  구현, 코드 산출물은 기존 **리뷰 게이트 🔍**를 그대로 통과한다.

> 템플릿: `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/`(인덱스 + 4 아티팩트). 실사례: forin 레포의 `docs/waypoint/02-construction/departments/<dept>/`(부서당 디렉토리 + 5파일).

> 템플릿 파일은 Read 도구로 읽어 Write 도구로 프로젝트에 복사한다. Bash 명령 안에서는 `${CLAUDE_PLUGIN_ROOT}`를 쓰지 않는다(환경변수로 노출되지 않는다).
