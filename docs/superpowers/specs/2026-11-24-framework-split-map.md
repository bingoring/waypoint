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

## 2. 고친 문장

종류는 두 가지다.
- **경로:** 참조나 경로만 새 구조에 맞게 고쳤다. 뜻은 같다.
- **사실 바뀜:** 이전 때문에 원문이 사실이 아니게 되어 새 흐름에 맞게 고쳐 썼다. 새 흐름은 설계 문서 9절이다.

### 2-1 (start)
- 원문: `projects/{project-name}/STATUS.md`를 읽는다
- 새 문장: 메인 체크아웃의 `docs/waypoint/STATUS.md`를 읽는다
- 종류: 경로

### 2-2 (core-rules)
- 원문: 코드를 산출하는 Construction phase 이후, Operations 진입 전 **독립 코드 리뷰 게이트**(`🔍`)를 통과해야 한다 (아래 "리뷰 게이트")
- 새 문장: … 통과해야 한다 (자세히: `waypoint:review-gate`)
- 종류: 경로

### 2-3 (core-rules)
- 원문: 중요한 결정이 내려지면 `projects/{name}/DECISIONS.md`에 항목을 추가한다 (아래 "결정 로그")
- 새 문장: 중요한 결정이 내려지면 `docs/waypoint/DECISIONS.md`에 항목을 추가한다 (자세히: `waypoint:decisions`)
- 종류: 경로

### 2-4 (core-rules)
- 원문: 사람이 채팅으로 게이트에 답하면 AI는 `AI Proposal`을 고쳐 쓰지 않고 검토 게이트 아래 **`승인 결과`** 에 기록한다 (아래 "승인 결과 기록")
- 새 문장: … 에 기록한다 (자세히: `waypoint:stage`)
- 종류: 경로

### 2-5 (core-rules)
- 원문: 버전·가격·스토어 정책 같은 **외부 사실**은 조회일·출처 URL·확인 수준을 함께 적는다 (아래 "외부 사실 표기")
- 새 문장: … 함께 적는다 (자세히: `waypoint:stage`)
- 종류: 경로

### 2-6 (core-rules)
- 원문: **PR · 기능 브랜치를 base(develop · master · main)에 맞출 때는 rebase 만 한다.** base 를 기능 브랜치에 merge 하지 않는다. 충돌 해결 · 서브모듈 포인터 갱신도 rebase 중에 하고 `push --force-with-lease` (아래 "브랜치 규칙")
- 새 문장: … base 를 기능 브랜치에 merge 하지 않는다. 충돌 해결도 rebase 중에 하고 `push --force-with-lease` (자세히: `waypoint:git`)
- 종류: 사실 바뀜(이전 뒤 waypoint 프로젝트에는 서브모듈 포인터가 없다) + 경로

### 2-7 (git)
- 원문: **서브모듈 포인터 충돌:** 어느 한쪽 해시를 고르지 않는다. … 으로 맞춘다.
- 새 문장: 서브모듈을 쓰는 레포에서: **서브모듈 포인터 충돌:** … (원문은 그대로 두고 앞에 적용 범위만 붙였다)
- 종류: 사실 바뀜(검사기는 원문이 그대로 들어 있어 통과하지만, 뜻이 좁아졌으므로 기록한다)

### 2-8 (review-gate)
- 원문: 리뷰어에게 `_templates/reviewer-brief-template.md`(적대적 리뷰 지시 템플릿)를 채워 전달한다.
- 새 문장: 리뷰어에게 `${CLAUDE_PLUGIN_ROOT}/templates/reviewer-brief-template.md`(적대적 리뷰 지시 템플릿)를 채워 전달한다.
- 종류: 경로

### 2-9 (review-gate)
- 원문: 템플릿: 스테이지 문서 `_templates/review-stage-template.md`, 리뷰어 지시 `_templates/reviewer-brief-template.md`.
- 새 문장: `_templates/` → `${CLAUDE_PLUGIN_ROOT}/templates/` (두 곳)
- 종류: 경로

### 2-10 (build-spec, 표 다섯 줄)
- 원문: | **domain-entities** | 엔티티·타입·데이터 shape·관계·상태·영속성·allowed-set | `_templates/build-spec/domain-entities.md` |
- 원문: | **business-rules** | 불변식·검증·제약·권한 규칙·엣지케이스 매핑 | `_templates/build-spec/business-rules.md` |
- 원문: | **business-logic-model** | 워크플로·알고리즘·상태 전이·시퀀스·통합 지점 | `_templates/build-spec/business-logic-model.md` |
- 원문: | **frontend-components** (조건부) | 컴포넌트 트리·props·상태·상호작용·API·화면 상태 | `_templates/build-spec/frontend-components.md` |
- 원문: | *인덱스* | 개요·범위·분해·아티팩트 매니페스트·미해결질문·체크리스트·검증·NFR·편차 | `_templates/build-spec/build-spec-index.md` |
- 새 문장: 각 줄의 `_templates/` → `${CLAUDE_PLUGIN_ROOT}/templates/`
- 종류: 경로

### 2-11 (build-spec)
- 원문: **크면 분리(기본 권장)**: `projects/{name}/{phase}/<topic>/`에 **아티팩트별 파일**(인덱스 + 4). 콘텐츠 시리즈는
- 새 문장: `projects/{name}/{phase}/<topic>/` → `docs/waypoint/{phase}/<topic>/`
- 종류: 경로

### 2-12 (build-spec)
- 원문: 템플릿: `_templates/build-spec/`(인덱스 + 4 아티팩트). 실사례: `projects/forin/02-construction/departments/<dept>/`(부서당 디렉토리 + 5파일).
- 새 문장: 템플릿: `${CLAUDE_PLUGIN_ROOT}/templates/build-spec/`(인덱스 + 4 아티팩트). 실사례: forin 레포의 `docs/waypoint/02-construction/departments/<dept>/`(부서당 디렉토리 + 5파일).
- 종류: 경로

### 2-13 (decisions)
- 원문: 각 프로젝트는 `projects/{name}/DECISIONS.md`(**append-only, ADR 스타일**)를 둔다.
- 새 문장: 각 프로젝트는 `docs/waypoint/DECISIONS.md`(**append-only, ADR 스타일**)를 둔다.
- 종류: 경로

### 2-14 (decisions)
- 원문: 템플릿: `_templates/decisions-template.md`.
- 새 문장: 템플릿: `${CLAUDE_PLUGIN_ROOT}/templates/decisions-template.md`.
- 종류: 경로

### 2-15 (git, 두 줄을 한 문장으로)
- 원문: **모노레포 순서**: 문서·핸드오프 변경은 `docs/dlc`(waypoint 서브모듈)에서 **먼저 커밋+push** → 그 다음 메인 repo에서
- 원문: 코드 변경 + **서브모듈 포인터 갱신**을 커밋+push. DECISIONS/STATUS/Build Spec은 코드와 같은 체크포인트에서 함께 커밋.
- 새 문장: **문서 커밋 흐름**: STATUS.md와 DECISIONS.md는 메인 체크아웃(세션 시작 때 주입된 `<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다.
- 종류: 사실 바뀜. 같은 문장을 `core-rules.md`에도 「(자세히: `waypoint:git`)」 꼬리와 함께 두었다.

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
