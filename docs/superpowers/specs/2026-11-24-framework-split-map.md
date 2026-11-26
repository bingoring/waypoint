# FRAMEWORK.md 분할 대조표

- 작성일: 2026-11-24
- 원본: `FRAMEWORK.md` (커밋 ba64aee 기준. 맨 위의 「플러그인으로 이전 중」 안내 줄은 이 분할에서 추가했다)
- 대상: `plugin/core-rules.md`, `plugin/skills/{start,stage,build-spec,review-gate,decisions,git}/SKILL.md`
- 검사: `sh tests/check-framework-split.sh FRAMEWORK.md docs/superpowers/specs/2026-11-24-framework-split-map.md plugin/core-rules.md plugin/skills/*/SKILL.md`
  - FRAMEWORK의 각 줄은 대상 파일 가운데 정확히 한 곳에 그대로 있어야 한다.
  - 한 곳이 아닌 줄은 이 문서의 2~4절에 원문이 적혀 있어야 한다.
- 설계: `docs/superpowers/specs/2026-11-24-plugin-split-design.md` 5.2절

## 1. 절별 배치

FRAMEWORK 줄 번호는 커밋 ba64aee 기준이다(이전 안내 줄을 넣기 전).

| FRAMEWORK 절 (줄) | 옮긴 곳 |
|---|---|
| 제목·소개 (1–3) | 옮기지 않음(4절) |
| 세션 시작 프로토콜 (5–13) | `skills/start` |
| 절대 규칙 (17–25) | `core-rules.md` |
| 브랜치 규칙 (27–33) | `skills/git` |
| 상태 생애주기 (35–46), 비가역 게이트 (48–54) | `skills/stage` |
| 리뷰 게이트 (56–93) | `skills/review-gate` |
| 승인 결과 기록 (95–104), 외부 사실 표기 (106–112), STATUS.md 업데이트 규칙 (114–116), 문서 깊이 (118–129) | `skills/stage` |
| 구현 스펙 (131–173) | `skills/build-spec` |
| 결정 로그 (175–182) | `skills/decisions` |
| 버전 관리 (184–194) | `skills/git`. 186–188, 189, 192행은 `core-rules.md`에도 둔다(3절) |

분할하면서 새로 넣은 문장(FRAMEWORK에 없던 것):
- 모든 스킬 맨 앞의 안내문: 「이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다 …」
- `core-rules.md`의 제목과 한 줄 안내
- `core-rules.md` 각 규칙 끝의 「(자세히: `waypoint:<스킬>`)」
- `stage`, `review-gate`, `build-spec`, `decisions` 끝의 템플릿 사용 안내(Read로 읽고 Write로 복사). `stage`에는 스테이지·게이트 템플릿 경로도 넣었다. FRAMEWORK에는 없었지만, 플러그인으로 옮기면 템플릿이 플러그인 캐시 안에 있어서 경로를 알려 주지 않으면 찾을 수 없다.
- `start` 끝의 한 단락: 「4단계(`AI Proposal` 작성) 전에 `waypoint:stage`를 호출한다 …」. 예전에는 세션마다 FRAMEWORK 전체를 읽어서 Build Spec·리뷰 게이트 규칙이 늘 컨텍스트에 있었다. 스킬로 나눈 뒤에는 어느 스킬을 부를지 알려 주지 않으면 이 규칙들이 조용히 빠질 수 있어서 넣었다(설계 5.2절).
- `git`의 「### 문서 커밋 흐름(STATUS·DECISIONS·핸드오프)」 하위 절 전체: 설계 9절이 `skills/git`에 넣으라고 한 자세한 절차(메인 체크아웃 확인 → `pull --rebase` → 고치고 커밋·push, 읽을 때도 메인 체크아웃).
- `decisions`의 「항목은 메인 체크아웃의 `docs/waypoint/DECISIONS.md`에 추가한다 …」: 설계 9절.
- `git`과 `core-rules.md`의 문서 커밋 흐름 문장에 든 「핸드오프(`docs/waypoint/inputs/`)」: 2-15 참고.

## 2. 고친 문장

종류는 두 가지다.
- **경로:** 참조나 경로만 새 구조에 맞게 고쳤다. 뜻은 같다.
- **사실 바뀜:** 이전 때문에 원문이 사실이 아니게 되어 새 흐름에 맞게 고쳐 썼다. 새 흐름은 설계 문서 9절이다.
- **규칙 바뀜(2단계):** 2단계 STATUS 정리 설계(`docs/superpowers/specs/2026-11-25-status-cleanup-design.md`, 2026-11-25 오너 승인)에 따라 규칙 자체를 바꿨다. 각 항목에 설계의 절 번호를 적는다.

FRAMEWORK 줄 번호는 이전 안내 줄을 넣은 뒤 기준이다(ba64aee 기준 번호 + 2). 「원문」과 「새 문장」은 파일에서 그대로 옮겼고, 검사기가 둘 다 대조한다.

### 2-1 (start)
- 원문: `projects/{project-name}/STATUS.md`를 읽는다
- 새 문장: 메인 체크아웃의 `docs/waypoint/STATUS.md`를 읽는다
- 종류: 사실 바뀜 + 경로. 경로를 바꾸면서 「메인 체크아웃의」를 붙였다(설계 9절: STATUS는 메인 체크아웃의 것을 읽는다).

### 2-2 (core-rules)
- 원문: 코드를 산출하는 Construction phase 이후, Operations 진입 전 **독립 코드 리뷰 게이트**(`🔍`)를 통과해야 한다 (아래 "리뷰 게이트")
- 새 문장: 코드를 산출하는 Construction phase 이후, Operations 진입 전 **독립 코드 리뷰 게이트**(`🔍`)를 통과해야 한다 (자세히: `waypoint:review-gate`)
- 종류: 경로. 「(아래 "…")」 참조를 스킬 이름으로 바꿨다.

### 2-3 (core-rules)
- 원문: 중요한 결정이 내려지면 `projects/{name}/DECISIONS.md`에 항목을 추가한다 (아래 "결정 로그")
- 새 문장: 중요한 결정이 내려지면 메인 체크아웃의 `docs/waypoint/DECISIONS.md`에 항목을 추가한다 (자세히: `waypoint:decisions`)
- 종류: 사실 바뀜 + 경로. `projects/{name}/` → `docs/waypoint/`, 그리고 「메인 체크아웃의」를 붙였다(설계 9절).

### 2-4 (core-rules)
- 원문: 사람이 채팅으로 게이트에 답하면 AI는 `AI Proposal`을 고쳐 쓰지 않고 검토 게이트 아래 **`승인 결과`** 에 기록한다 (아래 "승인 결과 기록")
- 새 문장: 사람이 채팅으로 게이트에 답하면 AI는 `AI Proposal`을 고쳐 쓰지 않고 검토 게이트 아래 **`승인 결과`** 에 기록한다 (자세히: `waypoint:stage`)
- 종류: 경로

### 2-5 (core-rules)
- 원문: 버전·가격·스토어 정책 같은 **외부 사실**은 조회일·출처 URL·확인 수준을 함께 적는다 (아래 "외부 사실 표기")
- 새 문장: 버전·가격·스토어 정책 같은 **외부 사실**은 조회일·출처 URL·확인 수준을 함께 적는다 (자세히: `waypoint:stage`)
- 종류: 경로

### 2-6 (core-rules)
- 원문: **PR · 기능 브랜치를 base(develop · master · main)에 맞출 때는 rebase 만 한다.** base 를 기능 브랜치에 merge 하지 않는다. 충돌 해결 · 서브모듈 포인터 갱신도 rebase 중에 하고 `push --force-with-lease` (아래 "브랜치 규칙")
- 새 문장: **PR · 기능 브랜치를 base(develop · master · main)에 맞출 때는 rebase 만 한다.** base 를 기능 브랜치에 merge 하지 않는다. 충돌 해결도 rebase 중에 하고 `push --force-with-lease` (자세히: `waypoint:git`)
- 종류: 사실 바뀜 + 경로. 이전 뒤 waypoint 프로젝트 레포에는 서브모듈 포인터가 없으므로 「· 서브모듈 포인터 갱신」을 뺐다. 다른 서브모듈을 쓰는 레포를 위한 일반 규칙은 git 스킬에 범위를 좁혀 남겼다(2-7).

### 2-7 (git)
- 원문: **서브모듈 포인터 충돌:** 어느 한쪽 해시를 고르지 않는다. 양쪽을 모두 담은 서브모듈 커밋(서브모듈 PR 이 머지됐으면 서브모듈 base 의 머지 커밋, 아니면 서브모듈 기능 브랜치를 먼저 rebase 한 tip)으로 맞춘다.
- 새 문장: 서브모듈을 쓰는 레포에서: **서브모듈 포인터 충돌:** 어느 한쪽 해시를 고르지 않는다. 양쪽을 모두 담은 서브모듈 커밋(서브모듈 PR 이 머지됐으면 서브모듈 base 의 머지 커밋, 아니면 서브모듈 기능 브랜치를 먼저 rebase 한 tip)으로 맞춘다.
- 종류: 사실 바뀜. 원문은 그대로 두고 앞에 적용 범위(「서브모듈을 쓰는 레포에서:」)만 붙였다. 검사기는 원문이 들어 있어 통과하지만 뜻이 좁아졌으므로 기록한다.

### 2-8 (review-gate)
- 원문: 리뷰어에게 `_templates/reviewer-brief-template.md`(적대적 리뷰 지시 템플릿)를 채워 전달한다.
- 새 문장: 리뷰어에게 `${CLAUDE_PLUGIN_ROOT}/templates/reviewer-brief-template.md`(적대적 리뷰 지시 템플릿)를 채워 전달한다.
- 종류: 경로

### 2-9 (review-gate)
- 원문: 템플릿: 스테이지 문서 `_templates/review-stage-template.md`, 리뷰어 지시 `_templates/reviewer-brief-template.md`.
- 새 문장: 템플릿: 스테이지 문서 `${CLAUDE_PLUGIN_ROOT}/templates/review-stage-template.md`, 리뷰어 지시 `${CLAUDE_PLUGIN_ROOT}/templates/reviewer-brief-template.md`.
- 종류: 경로

### 2-10 (build-spec, 표 다섯 줄)
- 원문: | **domain-entities** | 엔티티·타입·데이터 shape·관계·상태·영속성·allowed-set | `_templates/build-spec/domain-entities.md` |
- 원문: | **business-rules** | 불변식·검증·제약·권한 규칙·엣지케이스 매핑 | `_templates/build-spec/business-rules.md` |
- 원문: | **business-logic-model** | 워크플로·알고리즘·상태 전이·시퀀스·통합 지점 | `_templates/build-spec/business-logic-model.md` |
- 원문: | **frontend-components** (조건부) | 컴포넌트 트리·props·상태·상호작용·API·화면 상태 | `_templates/build-spec/frontend-components.md` |
- 원문: | *인덱스* | 개요·범위·분해·아티팩트 매니페스트·미해결질문·체크리스트·검증·NFR·편차 | `_templates/build-spec/build-spec-index.md` |
- 새 문장: | **domain-entities** | 엔티티·타입·데이터 shape·관계·상태·영속성·allowed-set | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/domain-entities.md` |
- 새 문장: | **business-rules** | 불변식·검증·제약·권한 규칙·엣지케이스 매핑 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/business-rules.md` |
- 새 문장: | **business-logic-model** | 워크플로·알고리즘·상태 전이·시퀀스·통합 지점 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/business-logic-model.md` |
- 새 문장: | **frontend-components** (조건부) | 컴포넌트 트리·props·상태·상호작용·API·화면 상태 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/frontend-components.md` |
- 새 문장: | *인덱스* | 개요·범위·분해·아티팩트 매니페스트·미해결질문·체크리스트·검증·NFR·편차 | `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/build-spec-index.md` |
- 종류: 경로

### 2-11 (build-spec)
- 원문: **크면 분리(기본 권장)**: `projects/{name}/{phase}/<topic>/`에 **아티팩트별 파일**(인덱스 + 4). 콘텐츠 시리즈는
- 새 문장: **크면 분리(기본 권장)**: `docs/waypoint/{phase}/<topic>/`에 **아티팩트별 파일**(인덱스 + 4). 콘텐츠 시리즈는
- 종류: 경로

### 2-12 (build-spec)
- 원문: 템플릿: `_templates/build-spec/`(인덱스 + 4 아티팩트). 실사례: `projects/forin/02-construction/departments/<dept>/`(부서당 디렉토리 + 5파일).
- 새 문장: 템플릿: `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/`(인덱스 + 4 아티팩트). 실사례: forin 레포의 `docs/waypoint/02-construction/departments/<dept>/`(부서당 디렉토리 + 5파일).
- 종류: 경로

### 2-13 (decisions)
- 원문: 각 프로젝트는 `projects/{name}/DECISIONS.md`(**append-only, ADR 스타일**)를 둔다.
- 새 문장: 각 프로젝트는 `docs/waypoint/DECISIONS.md`(**append-only, ADR 스타일**)를 둔다.
- 종류: 경로. 바로 다음 줄에 「항목은 메인 체크아웃의 …에 추가한다」를 새로 넣었다(1절).

### 2-14 (decisions)
- 원문: 템플릿: `_templates/decisions-template.md`.
- 새 문장: 템플릿: `${CLAUDE_PLUGIN_ROOT}/templates/decisions-template.md`.
- 종류: 경로

### 2-15 (git과 core-rules, 두 줄을 두 문장으로)
- 원문: **모노레포 순서**: 문서·핸드오프 변경은 `docs/dlc`(waypoint 서브모듈)에서 **먼저 커밋+push** → 그 다음 메인 repo에서
- 원문: 코드 변경 + **서브모듈 포인터 갱신**을 커밋+push. DECISIONS/STATUS/Build Spec은 코드와 같은 체크포인트에서 함께 커밋.
- 새 문장: **문서 커밋 흐름**: STATUS.md와 DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 메인 체크아웃(세션 시작 때 주입된 `<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다.
- 새 문장: **문서 커밋 흐름**: STATUS.md와 DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 메인 체크아웃(세션 시작 때 주입된 `<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다.
- 새 문장: Build Spec은 코드와 같은 체크포인트에서 함께 커밋한다.
- 종류: 사실 바뀜. 서브모듈 순서를 설계 9절의 문서 커밋 흐름으로 바꿨다. 같은 문장을 `core-rules.md`에도 「(자세히: `waypoint:git`)」 꼬리와 함께 두었다(그래서 새 문장을 두 번 적었다). 원문의 「Build Spec은 코드와 같은 체크포인트에서 함께 커밋」은 이전과 상관없으므로 별도 문장으로 되살렸다. 원문의 「핸드오프」는 STATUS·DECISIONS와 함께 기본 브랜치로 바로 가는 공유 문서로 분류했다(실행자 판단: 여러 작업이 함께 보는 입력이라 원문의 「먼저 커밋+push」와 같은 취지).

### 2-16 (core-rules)
- 원문: `HUMAN_APPROVED` 없이는 다음 스테이지로 진행하지 않는다
- 새 문장: 앞 스테이지의 계획이 승인되기 전에는 다음 스테이지로 진행하지 않는다 (자세히: `waypoint:stage`)
- 종류: 규칙 바뀜(2단계, 설계 5.2절 「다음 스테이지로 넘어가는 조건」, 5.9절). 상태 값의 이름이 바뀌어도 원래 뜻(계획 승인 뒤에 다음 스테이지)을 유지하도록 문장을 고쳤다.

### 2-17 (core-rules)
- 원문: STATUS.md의 상태 표는 항상 실제 문서 상태와 동기화되어야 한다
- 새 문장: 스테이지 상태의 원본은 메인 체크아웃 `docs/waypoint/STATUS.md`의 표 한 곳이다. 상태가 바뀌면 그 줄을 고친다 (자세히: `waypoint:stage`)
- 종류: 규칙 바뀜(2단계, 설계 5.3절·5.9절). 스테이지 문서 frontmatter의 `status:`를 없애서 「문서 상태와 동기화」할 대상이 사라졌다.

### 2-18 (stage, 상태 표)
- 원문: | 상태 | 설명 |
- 원문: | `PENDING` | 시작 전. 이전 스테이지가 APPROVED되지 않으면 진입 불가 |
- 원문: | `IN_PROGRESS` | AI가 현재 작업 중 |
- 원문: | `AI_PROPOSED` | AI 제안 완료. 사람의 검토 대기 |
- 원문: | `HUMAN_APPROVED` | 사람이 승인. 다음 스테이지 언락 |
- 새 문장: | 상태 값 | 보드 열 | 뜻 |
- 새 문장: | `PENDING` | 대기 | 시작 전 |
- 새 문장: | `IN_PROGRESS` | 진행 중 | AI가 작업 중이다. 계획을 쓰는 중이거나, 계획 승인 뒤 구현하는 중이다. |
- 새 문장: | `AI_PROPOSED` | 검토 대기 | 오너가 검토할 차례다. 계획 검토인지 결과 검토인지는 「지금」 칸에 적는다. |
- 새 문장: | `HUMAN_APPROVED` | 승인 | 오너가 결과를 승인했지만 PR이 아직 머지되지 않았다(예: 「머지·배포는 나중에」). |
- 새 문장: | `MERGED` | 머지됨 | 스테이지의 PR이 기본 브랜치에 머지되어 스테이지가 끝났다. |
- 새 문장: | `DEFERRED` | 보류 | 오너가 보류했다. 보류 전 상태와 다시 시작할 조건은 「지금」에 적는다. |
- 종류: 규칙 바뀜(2단계, 설계 5.2절). 상태 값을 보드 열과 1:1로 맞추고 `MERGED`, `DEFERRED`를 더했다. 원문 코드 블록의 `PENDING → IN_PROGRESS → AI_PROPOSED → HUMAN_APPROVED`는 새 「설계 스테이지」 흐름 줄(`… → MERGED`)이 그대로 포함하므로 검사기는 옮겨진 것으로 센다. 뜻은 「흐름」 목록으로 넓어졌다.

### 2-19 (stage, 승인 결과 기록)
- 원문: 사후에 고쳐 쓰지 않는다. 대신 AI가 검토 게이트 아래 `### 승인 결과 (날짜, 결정자)` 표에 질문별 답을 기록한다.
- 새 문장: 사후에 고쳐 쓰지 않는다. 대신 AI가 검토 게이트 아래 `### 승인 결과`의 `#### 계획 승인 (날짜, 결정자)`·`#### 결과 승인 (날짜, 결정자)` 표에 질문별 답을 기록한다.
- 종류: 규칙 바뀜(2단계, 설계 5.3절). 「승인 결과」를 계획 승인과 결과 승인 두 표로 나눴다.

### 2-20 (stage, STATUS 표)
- 원문: 스테이지 상태가 변경될 때마다 STATUS.md의 테이블을 함께 업데이트한다.
- 새 문장: 스테이지 상태의 원본은 메인 체크아웃 `docs/waypoint/STATUS.md`의 표 한 곳이다. 스테이지 문서와 Build Spec은 스테이지 상태를 들고 있지 않다. 표의 한 줄이 보드의 카드 한 장이다.
- 종류: 규칙 바뀜(2단계, 설계 5.1절·5.2절·5.9절). 「STATUS.md 업데이트 규칙」 절을 「STATUS 표」 절(칸 규칙, 「지금」 머리말, 오너 할 일, 누가 언제 고치는가)로 바꿨다.

### 2-21 (core-rules, 2-15의 문서 커밋 흐름 줄)
- 새 문장: 모든 스테이지는 worktree의 작업 브랜치와 PR로 진행하고, 메인 체크아웃은 기본 브랜치에 둔다.
- 종류: 규칙 바뀜(2단계, 설계 4.4절·4.6절·5.9절). 2-15의 새 문장은 그대로 두고 그 뒤에 이 문장을 덧붙였다. 자세한 절차는 `skills/git`의 「스테이지 브랜치와 PR」에 있다.

### 2-22 (start, 세션 시작 프로토콜)
- 원문: `PENDING` 상태인 가장 앞 스테이지를 찾는다
- 원문: `AI Proposal` 섹션을 작성하고 status를 `AI_PROPOSED`로 변경한다
- 원문: 사람에게 리뷰를 요청하고 대기한다
- 새 문장: 새 스테이지를 시작할 때는 오너가 정한 스테이지를 고른다. 오너가 정하지 않았다면 `PENDING` 가운데 ID가 가장 앞선 스테이지를 제안하고 오너의 확인을 받는다.
- 새 문장: `AI_PROPOSED` 카드는 오너가 답하기 전에는 건드리지 않는다.
- 종류: 규칙 바뀜(2단계, 설계 5.7절). 여러 스테이지가 동시에 진행되고 세션은 오너가 지정한 카드를 이어 가므로, 「PENDING인 가장 앞 스테이지부터」를 세션 시작 요약 확인, PR 상태 확인, 오너가 지정한 카드 이어 가기로 바꿨다. `AI Proposal`을 쓰고 상태를 바꾸는 일은 frontmatter가 아니라 STATUS에서 하므로 `skills/stage`의 「상태 생애주기」와 `skills/git`의 「스테이지 브랜치와 PR」로 옮겼다. 원문의 「해당 스테이지 문서를 열고 `Inputs` 섹션에 명시된 파일을 모두 읽는다」는 새 6번이 그대로 포함하고, 2-1의 새 문장은 새 1번이 그대로 포함한다.

## 3. 두 곳에 둔 문장

설계 문서 5.2절에 따라 `skills/git`과 `core-rules.md` 양쪽에 둔다. 커밋은 스킬을 부르지 않고도 일어나기 때문이다. `core-rules.md` 쪽에는 「(자세히: `waypoint:git`)」 꼬리만 붙였다.

- **체크포인트마다 커밋한다.** 하나의 완결된 수정/기능/문서 단위가 끝나면(빌드·tsc·테스트 그린 확인 후) **바로 커밋**한다.
- 여러 무관한 변경을 한 커밋에 몰지 않는다 — 테마별로 나눈다(예: `fix(map): 엘리베이터 전환`, `feat(map/pharma): 5g-e`,
- `fix(map/peds): NICU 하단 정리`).
- **커밋 직후 push.** 솔로/공개 모노레포이므로 원격을 항상 최신으로 유지. 실패한 상태(테스트 레드)는 커밋하지 않는다.
- **Co-Authored-By 등 공동작업 트레일러 금지**(솔로 작업 외형). AI 서명/`Generated with` 류도 넣지 않는다.

## 4. 옮기지 않은 문장

| 원문 | 사유 |
|---|---|
| 이 문서는 AI가 Waypoint 프레임워크 안에서 동작할 때 반드시 따라야 하는 계약서다. | FRAMEWORK 자체를 소개하는 문장이다. 규칙은 이제 플러그인에 있으므로 옮길 곳이 없다. 5단계에서 FRAMEWORK를 사람용 개요로 바꿀 때 함께 정리한다. |
| **플러그인으로 이전 중(2026-11-24).** 규칙 원본은 `plugin/core-rules.md`와 `plugin/skills/`다. 아직 이전하지 않은 프로젝트는 이 파일을 계속 따른다. | 이 분할에서 FRAMEWORK에 추가한 이전 안내다. |
