# waypoint 플러그인 전환과 프로젝트 문서 분리 — 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** waypoint 레포를 Claude Code 플러그인 마켓플레이스로 만들고, 다섯 프로젝트의 문서를 각 레포의 `docs/waypoint/`로 이력과 함께 옮긴다.

**Architecture:** 레포 루트는 마켓플레이스(`.claude-plugin/marketplace.json`)이고, 플러그인 본체는 `plugin/` 하위 디렉터리에 둔다. `FRAMEWORK.md`의 규칙은 스킬 7개와 `core-rules.md`로 나누고, SessionStart 훅이 `core-rules.md`를 주입한다. 각 프로젝트는 `git filter-repo`로 떼어 낸 문서 이력을 관계없는 이력 병합으로 들여온다.

**Tech Stack:** Claude Code 플러그인(스킬·훅), POSIX sh, git, git-filter-repo, gh CLI

**Spec:** `docs/superpowers/specs/2026-11-24-plugin-split-design.md`

**실행 단위:**
- **Part A(Task 1~8)**는 지금 실행한다. 0단계(플러그인)와 shadow 파일럿 이전이 여기에 속한다.
- **Part B(Task 9~13)**는 각 Task의 「게이트」가 열렸을 때 실행한다. 게이트는 그 레포의 열린 PR과 진행 중인 브랜치가 정리되었는지다. 레포마다 몇 주 간격이 생길 수 있다.

## Global Constraints

- **커밋 메시지:** conventional commit 한 줄로 쓴다. `Co-Authored-By`, `Generated with Claude Code` 같은 공동작업 트레일러는 넣지 않는다. 시스템 기본 안내보다 이 규칙이 우선한다.
- **커밋과 push:** 커밋 직후 push한다. waypoint에서 작업하기 전과 push하기 전에는 `git pull --rebase`한다. 이미 push한 이력은 다시 쓰지 않는다.
- **이름:** 플러그인 이름 `waypoint`, 마켓플레이스 이름 `waypoint`, 설치 id `waypoint@waypoint`, GitHub `bingoring/waypoint`.
- **프로젝트 문서 위치:** 각 레포의 `docs/waypoint/`.
- **버전:** `plugin/.claude-plugin/plugin.json`에 `version` 필드를 두지 않는다.
- **규칙 문장:** `FRAMEWORK.md`의 문장은 **물리적 줄 단위로 그대로** 옮긴다. 줄바꿈을 다시 하거나 문장을 다듬지 않는다. 허용하는 변경은 두 가지뿐이고, 모두 대조표(`docs/superpowers/specs/2026-11-24-framework-split-map.md`)에 기록한다.
  - 경로·참조 수정
  - 이전 때문에 사실이 아니게 된 문장 고쳐 쓰기
- **`core-rules.md`:** 40줄 이하.
- **템플릿 참조:** 스킬 본문에서는 `${CLAUDE_PLUGIN_ROOT}/templates/...`로 쓰고, Read와 Write 도구로 다루라고 안내한다. Bash 명령 안에서 이 변수를 쓰지 않는다.
- **플러그인 스크립트(`plugin/scripts/`):** POSIX sh로 쓰고 셸 내장 명령만 쓴다. SessionStart 시점에는 PATH가 비어 있을 수 있다. 테스트 스크립트(`tests/`)는 git 등 외부 명령을 써도 된다.
- **레포별 빌드·테스트 검증:** 그 레포의 CI(`.github/workflows/*.yml`)가 실행하는 테스트 명령을 로컬에서 그대로 실행한다. 경로 주석만 바뀐 Python 스크립트는 `python3 -m py_compile <파일>`로 확인한다.
- **waypoint의 `projects/<name>/`:** 그 레포의 이전 PR이 머지되기 전에는 지우지 않는다.
- **이전 PR:** merge commit으로 머지한다. squash를 쓰지 않는다.
- **문서 커밋 흐름(이전 뒤):** STATUS.md와 DECISIONS.md는 메인 체크아웃에서 기본 브랜치로 바로 커밋한다. 스테이지 문서, Build Spec, 리뷰 문서는 작업 브랜치에 싣는다.

## Review Focus

1. **아직 이전하지 않은 레포에서 waypoint 스킬이 호출되는 경우.** 플러그인은 사용자 범위로 설치되므로 forin 같은 레포에서도 스킬이 보인다. 스킬이 `docs/waypoint/` 경로와 새 커밋 흐름을 지시하면, 옛 방식과 충돌한다. 기대 동작: 스킬 본문 맨 앞의 안내문이 그 레포의 옛 FRAMEWORK를 따르라고 한다. 이 동작은 Task 3의 `skills-have-guard` 테스트가 검증한다.
2. **worktree, 하위 디렉터리, PATH가 빈 환경에서 훅이 실행되는 경우.** 기대 동작: 핵심 규칙이 그대로 주입되고, 메인 체크아웃 경로가 정확하다. Task 4의 테스트 3~5번이 검증한다.
3. **waypoint를 쓰지 않는 레포의 세션.** waypoint 레포 자신, 회사 레포가 여기에 해당한다. 기대 동작: 훅이 아무것도 출력하지 않는다. Task 4의 테스트 1번과 6번이 검증한다.
4. **대조표 검사기가 아무것도 검사하지 않고 통과하는 경우.** 기대 동작: 빠진 줄과 중복된 줄이 있으면 실패한다. Task 2의 고정 입력 테스트가 검증한다.
5. **이전 뒤 다른 worktree에 남은 옛 submodule 디렉터리.** 세션이 그 안의 낡은 FRAMEWORK를 읽을 수 있다. 기대 동작: 모든 worktree에서 옛 submodule 경로가 사라진다. 절차 M의 M10 검증 단계가 확인한다.

---

## 파일 구조 (waypoint 레포, 0단계 뒤)

```
waypoint/
├── .claude-plugin/marketplace.json     # Task 1. 마켓플레이스. plugins[0].source = "./plugin"
├── plugin/                             # 플러그인 본체. 설치 시 이 디렉터리만 캐시로 복사된다
│   ├── .claude-plugin/plugin.json      # Task 1
│   ├── core-rules.md                   # Task 3
│   ├── skills/{start,stage,build-spec,review-gate,decisions,git}/SKILL.md   # Task 3
│   ├── skills/init/SKILL.md            # Task 5
│   ├── hooks/hooks.json                # Task 4
│   ├── scripts/session-context.sh      # Task 4
│   ├── templates/                      # Task 5. _templates/ 사본 + STATUS.template.md + claude-md-block.md + project-settings.json
│   └── githooks/commit-msg             # Task 5
├── tests/
│   ├── check-framework-split.sh        # Task 2. 대조표 검사기
│   ├── check-framework-split.test.sh   # Task 2
│   ├── session-context.test.sh         # Task 4
│   └── plugin-files.test.sh            # Task 3·5. 스킬 안내문, 템플릿 경로, commit-msg
├── docs/superpowers/specs/2026-11-24-framework-split-map.md   # Task 3. 대조표
├── FRAMEWORK.md, _templates/, STATUS.template.md, projects/, .githooks/   # 5단계(Task 13)까지 유지
```

**설계 문서와 다른 점(계획 단계에서 정함):** 설계 문서 5.1절은 플러그인을 레포 루트에 둔다. 이 계획은 플러그인을 `plugin/` 하위 디렉터리로 옮긴다.
- 이유: 플러그인을 설치하면 플러그인 디렉터리 전체가 `~/.claude/plugins/cache/`로 복사된다. 루트를 플러그인으로 두면 `projects/`(약 150MB)와 `tests/`, `docs/`까지 복사된다.
- 설계 문서 5.1절에도 같은 변경을 반영했다.

---

## Part A — 지금 실행

작업 위치: waypoint의 **별도 worktree**를 `feat/plugin` 브랜치로 만들어 쓴다(superpowers:using-git-worktrees). waypoint 메인 체크아웃(`/Users/ywyeom/private/waypoint`)에서는 다른 세션이 master에 문서를 커밋하기 때문이다. Task 1~6은 이 worktree에서, Task 7은 메인 체크아웃에서, Task 8은 shadow 레포에서 한다.

### Task 1: 마켓플레이스와 플러그인 매니페스트

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugin/.claude-plugin/plugin.json`

**Interfaces:**
- Produces: 플러그인 루트 `plugin/`, 설치 id `waypoint@waypoint`

- [ ] **Step 1: 검증이 실패하는지 확인**

Run: `claude plugin validate .`
Expected: 매니페스트가 없어서 실패(exit ≠ 0)

- [ ] **Step 2: `marketplace.json` 작성**

`name: "waypoint"`, `owner: {"name": "bingoring"}`, `plugins`에 항목 하나를 둔다. 항목은 `name: "waypoint"`, `source: "./plugin"`, `description: "AI 제안 → 사람 승인 게이트 기반의 Markdown 개발 라이프사이클 프레임워크"`다. 형식은 `~/.claude/plugins/marketplaces/everytime-marketplace/.claude-plugin/marketplace.json`을 참고한다.

- [ ] **Step 3: `plugin.json` 작성**

`name: "waypoint"`, 위와 같은 `description`, `author: {"name": "bingoring"}`, `repository: "https://github.com/bingoring/waypoint"`를 넣는다. `version`은 넣지 않는다.

- [ ] **Step 4: 검증 통과 확인**

Run: `claude plugin validate . && claude plugin validate plugin`
Expected: 둘 다 exit 0. 스킬이 아직 없다는 경고는 괜찮다.

- [ ] **Step 5: 커밋**

```bash
git add .claude-plugin plugin/.claude-plugin
git commit -m "feat(plugin): 마켓플레이스와 플러그인 매니페스트"
```

### Task 2: 대조표 검사기

**Files:**
- Create: `tests/check-framework-split.sh`
- Test: `tests/check-framework-split.test.sh`

**Interfaces:**
- Produces: `tests/check-framework-split.sh <framework.md> <map.md> <target>...`
  - 출력: 문제가 있는 줄마다 `MISSING: <줄>` 또는 `DUPLICATE(<n>): <줄>`. 문제가 없으면 마지막 줄에 `OK: <검사한 줄 수> lines`.
  - 종료 코드: 문제가 하나라도 있으면 1, 없으면 0.

검사 규칙:
1. framework 파일의 각 물리적 줄을 다음 순서로 다듬는다.
   - 앞뒤 공백을 지운다.
   - 줄 앞의 `> `, `- [ ] `, `- `, `* `, `<숫자>. `를 한 번 떼어 낸다.
2. 다음에 해당하는 줄은 건너뛴다.
   - 빈 줄
   - `#`로 시작하는 줄
   - `` ``` ``로 시작하는 줄
   - `|---`나 `|-`로 시작하는 표 구분선
   - 다듬은 뒤 8자보다 짧은 줄
3. 남은 줄은 target 파일들에서 그 문자열을 포함하는 줄의 개수를 센다(`grep -F`).
4. 개수가 1이 아니면 map 파일을 확인한다. map 파일에 그 문자열이 있으면 통과이고, 없으면 문제로 출력한다.

- [ ] **Step 1: 실패하는 테스트 작성**

테스트는 `mktemp -d` 안에 고정 입력 파일을 만들어 검사기를 실행한다. 다섯 경우를 확인한다.

```sh
# framework: "# 제목", 빈 줄, "- 첫째 규칙 문장입니다", "  둘째 규칙 문장입니다", "```", "|---|---|"
case_ok:        target에 두 문장 모두 있음        → exit 0, 출력 마지막 줄 "OK: 2 lines"
case_missing:   target에 둘째 문장 없음           → exit 1, 출력에 "MISSING: 둘째 규칙 문장입니다"
case_mapped:    case_missing + map에 둘째 문장 있음 → exit 0
case_duplicate: 첫째 문장이 target 두 파일에 있음  → exit 1, 출력에 "DUPLICATE(2): 첫째 규칙 문장입니다"
case_skips:     제목·빈 줄·코드 펜스·표 구분선은 "OK: 2 lines"의 2에 포함되지 않음 (case_ok와 같은 단언)
```

각 경우가 실패하면 `FAIL <경우 이름>`을 출력한다. 하나라도 실패하면 exit 1로 끝낸다.

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `sh tests/check-framework-split.test.sh`
Expected: 검사기가 없어서 FAIL, exit 1

- [ ] **Step 3: `tests/check-framework-split.sh` 구현**

위 검사 규칙대로 구현한다. 줄 읽기는 `while IFS= read -r`로 한다.

- [ ] **Step 4: 테스트 통과 확인**

Run: `sh tests/check-framework-split.test.sh`
Expected: exit 0, `FAIL` 출력 없음

- [ ] **Step 5: 커밋**

```bash
git add tests/check-framework-split.sh tests/check-framework-split.test.sh
git commit -m "test(plugin): FRAMEWORK 분할 대조표 검사기"
```

### Task 3: FRAMEWORK를 core-rules와 스킬 여섯 개로 나누기

**Files:**
- Create: `plugin/core-rules.md`
- Create: `plugin/skills/{start,stage,build-spec,review-gate,decisions,git}/SKILL.md`
- Create: `docs/superpowers/specs/2026-11-24-framework-split-map.md`
- Modify: `FRAMEWORK.md` (맨 위에 안내 한 줄만 추가)
- Test: `tests/plugin-files.test.sh`

**Interfaces:**
- Consumes: Task 2의 `tests/check-framework-split.sh`
- Produces: 스킬 이름 `waypoint:start`, `waypoint:stage`, `waypoint:build-spec`, `waypoint:review-gate`, `waypoint:decisions`, `waypoint:git`
- Produces: `plugin/core-rules.md`. 이 파일의 첫 줄은 `# waypoint 핵심 규칙`이다(Task 4 테스트가 이 줄을 찾는다).

**절별 배치(FRAMEWORK 줄 번호는 커밋 3d1698c 기준):**

| FRAMEWORK 절 (줄) | 파일 |
|---|---|
| 세션 시작 프로토콜 (5–14) | `skills/start` |
| 절대 규칙 (15–26) | `core-rules.md` |
| 브랜치 규칙 (27–34) | `skills/git` |
| 상태 생애주기 (35–47), 비가역 게이트 (48–55) | `skills/stage` |
| 리뷰 게이트 (56–94) | `skills/review-gate` |
| 승인 결과 기록 (95–105), 외부 사실 표기 (106–113), STATUS 업데이트 (114–117), 문서 깊이 (118–130) | `skills/stage` |
| 구현 스펙 (131–174) | `skills/build-spec` |
| 결정 로그 (175–183) | `skills/decisions` |
| 버전 관리 (184–194) | `skills/git`. 186–188, 189, 191은 `core-rules.md`에도 둔다 |

**정해 둔 문장 변경(대조표 2절에 기록):**
- 절대 규칙의 각 줄 끝에 있는 「(아래 "…")」 참조는 「(자세히: `waypoint:<스킬>`)」로 바꾼다. 참조가 없는 줄에도 같은 꼬리를 붙인다. 붙일 스킬은 다음과 같다.
  - 17·18·19·21·23·24행 → `stage`
  - 20행 → `review-gate`
  - 22행 → `decisions`
  - 25행 → `git`
- 25행: 「충돌 해결 · 서브모듈 포인터 갱신도 rebase 중에 하고」 → 「충돌 해결도 rebase 중에 하고」 (사실 바뀜)
- 31행(서브모듈 포인터 충돌): 앞에 「서브모듈을 쓰는 레포에서:」를 붙인다 (사실 바뀜)
- 193–194행(모노레포 순서): 아래 문장 하나로 바꾼다 (사실 바뀜). `core-rules.md`에는 같은 문장을 「(자세히: `waypoint:git`)」 꼬리와 함께 둔다.
  `- **문서 커밋 흐름**: STATUS.md와 DECISIONS.md는 메인 체크아웃(세션 시작 때 주입된 \`<waypoint>\` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다.`
- 7행(세션 시작 1번): `projects/{project-name}/STATUS.md` → 메인 체크아웃의 `docs/waypoint/STATUS.md` (경로)
- `_templates/...`, `../../_templates/...` → `${CLAUDE_PLUGIN_ROOT}/templates/...` (경로)
- `FRAMEWORK "<절 이름>"`, `(아래 "<절 이름>")` 같은 절 참조 → `waypoint:<스킬>` (경로)
- 3행(「이 문서는 AI가 … 계약서다」)은 옮기지 않는다. 대조표 4절에 기록한다.

**스킬 공통 형식:**
- frontmatter에는 `name`과 `description`을 둔다. `description`은 아래 표의 문장을 그대로 쓴다.
- 본문 첫 줄은 다음 안내문이다.
  `> 이 스킬은 \`docs/waypoint/STATUS.md\`가 있는 레포에서만 적용한다. 없으면 그 레포의 \`docs/dlc/FRAMEWORK.md\`(duty는 \`waypoint/FRAMEWORK.md\`)를 따른다.`

| 스킬 | description |
|---|---|
| start | waypoint 프로젝트에서 세션을 시작하거나 다음 작업을 고를 때 사용한다. STATUS.md를 읽고 다음 스테이지를 찾는 절차. |
| stage | waypoint 스테이지 문서를 쓰거나 고칠 때, 스테이지 상태를 바꿀 때, 사람의 게이트 답을 기록할 때 사용한다. 상태 생애주기, 비가역 게이트, 승인 결과 기록, 외부 사실 표기, STATUS 갱신, 문서 깊이. |
| build-spec | 로직·화면·알고리즘·콘텐츠를 산출하는 waypoint 스테이지에서 코딩 전에 구현 스펙(Build Spec)을 쓸 때 사용한다. |
| review-gate | waypoint의 Construction을 마치고 Operations에 들어가기 전, 독립 코드 리뷰 게이트를 진행할 때 사용한다. |
| decisions | waypoint 프로젝트에서 중요한 결정이 내려져 DECISIONS.md에 항목을 추가할 때 사용한다. |
| git | waypoint 프로젝트에서 커밋·push할 때, PR 브랜치를 base에 맞출 때, STATUS·DECISIONS 같은 문서를 커밋할 때 사용한다. 브랜치 규칙과 커밋 규칙. |

- [ ] **Step 1: 실패하는 테스트 작성 — `tests/plugin-files.test.sh`의 첫 검사들**

```sh
skills-exist:      plugin/skills/{start,stage,build-spec,review-gate,decisions,git}/SKILL.md 가 모두 있음
skills-have-guard: 위 여섯 파일 모두 "docs/waypoint/STATUS.md\`가 있는 레포에서만 적용한다" 문자열을 포함
core-rules-size:   plugin/core-rules.md 가 있고 40줄 이하, 첫 줄이 "# waypoint 핵심 규칙"
no-old-paths:      plugin/core-rules.md 와 plugin/skills/*/SKILL.md 에 "_templates/" 와 "docs/dlc" 가 없음
                   (단 안내문 줄의 "docs/dlc/FRAMEWORK.md"는 제외: 안내문 줄을 걸러 낸 뒤 검사)
framework-split:   sh tests/check-framework-split.sh FRAMEWORK.md docs/superpowers/specs/2026-11-24-framework-split-map.md plugin/core-rules.md plugin/skills/*/SKILL.md 가 exit 0
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `sh tests/plugin-files.test.sh`
Expected: `FAIL skills-exist` 등, exit 1

- [ ] **Step 3: `FRAMEWORK.md` 맨 위(1행 제목 바로 아래)에 안내 한 줄 추가**

`> **플러그인으로 이전 중(2026-11-24).** 규칙 원본은 \`plugin/core-rules.md\`와 \`plugin/skills/\`다. 아직 이전하지 않은 프로젝트는 이 파일을 계속 따른다.`

이 줄은 대조표 4절에 「옮기지 않음: 이전 안내」로 기록한다.

- [ ] **Step 4: `core-rules.md`와 스킬 여섯 개 작성**

배치 표대로 줄을 옮긴다. `core-rules.md`의 구성은 다음과 같다.
1. 제목 `# waypoint 핵심 규칙`
2. 한 줄 안내: 「아래 규칙은 항상 적용된다. 스테이지에 들어가기 전에 해당 스킬을 호출해 자세한 절차를 읽는다.」
3. 절대 규칙 9줄
4. 문서 커밋 흐름 1줄
5. 버전 관리에서 가져온 줄들(186–188, 189, 191)

스킬 본문은 각 스킬의 안내문 다음에 FRAMEWORK의 절 제목(`##`, `###`)을 유지한 채로 옮긴다. 스킬 본문에서 템플릿을 언급하는 곳에는 「Read 도구로 읽어 Write 도구로 프로젝트에 복사한다」는 문장을 둔다.

- [ ] **Step 5: 대조표 `docs/superpowers/specs/2026-11-24-framework-split-map.md` 작성**

- 1절 「절별 배치」: 위 배치 표
- 2절 「고친 문장」: 표 형식(원문 | 새 문장 | 종류: 경로 / 사실 바뀜)
- 3절 「두 곳에 둔 문장」: 186–188, 189, 191행의 원문
- 4절 「옮기지 않은 문장」: 원문 | 사유

원문 칸에는 FRAMEWORK의 줄을 그대로 붙여 넣는다. 검사기는 이 칸의 문자열을 찾는다.

- [ ] **Step 6: 테스트 통과 확인**

Run: `sh tests/plugin-files.test.sh`
Expected: exit 0. `framework-split` 검사의 출력이 `OK: <N> lines`이다.

- [ ] **Step 7: 대조표의 2절과 3절을 원문과 나란히 놓고 직접 읽는다**

각 「새 문장」의 뜻이 원문과 같은지(경로 수정), 또는 설계 문서 9절과 같은지(사실 바뀜) 확인한다. 뜻이 달라진 곳이 있으면 고친다.

- [ ] **Step 8: 검증과 커밋**

Run: `claude plugin validate plugin` → exit 0

```bash
git add plugin/core-rules.md plugin/skills docs/superpowers/specs/2026-11-24-framework-split-map.md FRAMEWORK.md tests/plugin-files.test.sh
git commit -m "feat(plugin): FRAMEWORK를 core-rules와 스킬 여섯 개로 나눔"
```

### Task 4: SessionStart 훅

**Files:**
- Create: `plugin/scripts/session-context.sh` (실행 권한 부여)
- Create: `plugin/hooks/hooks.json`
- Test: `tests/session-context.test.sh`

**Interfaces:**
- Consumes: `plugin/core-rules.md` (Task 3)
- Produces: 세션 컨텍스트에 들어가는 `<waypoint>` … `</waypoint>` 블록. 블록 안에는 다음 세 줄이 들어 있다. Task 5의 CLAUDE.md 블록과 스킬이 이 줄들을 가리킨다.
  - `메인 체크아웃: <절대 경로>`
  - `현황: docs/waypoint/STATUS.md`
  - `작업을 시작하면 \`waypoint:start\` 스킬을 호출한다.`

**`session-context.sh` 동작:**
1. 플러그인 루트를 정한다. `$0`의 디렉터리 + `/..`이다. superpowers의 `hooks/session-start`처럼 `case`로 자른다.
2. 시작 디렉터리를 정한다. `${CLAUDE_PROJECT_DIR:-$PWD}`이다.
3. 레포 루트를 찾는다. 시작 디렉터리에서 위로 올라가며 `docs/waypoint/STATUS.md`가 있는 디렉터리를 찾는다. `.git`이 있는 디렉터리에 닿을 때까지 찾지 못하면, 또는 `/`에 닿으면 아무것도 출력하지 않고 exit 0으로 끝낸다.
4. 메인 체크아웃을 정한다.
   - 루트의 `.git`이 디렉터리면 루트 자신이다.
   - `.git`이 파일이면 `gitdir: <경로>`를 읽는다. 경로가 `*/.git/worktrees/*` 꼴이면 `${경로%/.git/worktrees/*}`이고, 아니면 루트다.
5. 출력(stdout, 일반 텍스트):

```
<waypoint>
{core-rules.md 전체}

이 레포는 waypoint 플러그인으로 진행한다.
메인 체크아웃: {메인 체크아웃}
현황: docs/waypoint/STATUS.md
작업을 시작하면 `waypoint:start` 스킬을 호출한다.
</waypoint>
```

6. 외부 명령(`git`, `cat`, `dirname` 등)을 쓰지 않는다. 항상 exit 0으로 끝낸다.

**`hooks.json`:** `SessionStart` 이벤트, matcher `startup|resume|clear|compact`, `type: "command"`, `command: "\"${CLAUDE_PLUGIN_ROOT}/scripts/session-context.sh\""`, `async: false`.

- [ ] **Step 1: 실패하는 테스트 작성 — `tests/session-context.test.sh`**

설정에는 `mktemp -d`, `git init -q`, `git worktree add`를 쓴다. 이 명령들은 테스트 설정에만 쓰고, 검사 대상 스크립트는 쓰지 않는다. 스크립트는 `/bin/sh plugin/scripts/session-context.sh`로 실행한다.

```sh
1 plain-repo:   git 레포, docs/waypoint 없음, CLAUDE_PROJECT_DIR=레포 → stdout 비어 있음, exit 0
2 waypoint:     레포에 docs/waypoint/STATUS.md 있음, CLAUDE_PROJECT_DIR=레포
                → stdout에 "# waypoint 핵심 규칙", "현황: docs/waypoint/STATUS.md",
                  "waypoint:start", "메인 체크아웃: <레포 절대 경로>" 가 모두 있음
3 subdir:       CLAUDE_PROJECT_DIR 없음, 작업 디렉터리 = 레포/src → 2와 같은 단언
4 worktree:     레포의 worktree(브랜치에 docs/waypoint/STATUS.md 포함), CLAUDE_PROJECT_DIR=worktree
                → "메인 체크아웃: <원래 레포 절대 경로>"
5 empty-path:   2의 조건 + PATH="" → 2와 같은 단언
6 non-git:      git이 아닌 빈 디렉터리 → stdout 비어 있음, exit 0
```

경로를 비교할 때는 양쪽을 `cd <경로> && pwd -P`로 정규화한다. macOS에서는 `/var`가 `/private/var`로 바뀌기 때문이다.

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `sh tests/session-context.test.sh`
Expected: 스크립트가 없어서 FAIL, exit 1

- [ ] **Step 3: `session-context.sh`와 `hooks.json` 구현**

`chmod +x plugin/scripts/session-context.sh`를 실행한다.

- [ ] **Step 4: 테스트 통과 확인**

Run: `sh tests/session-context.test.sh && claude plugin validate plugin`
Expected: 둘 다 exit 0

- [ ] **Step 5: 커밋**

```bash
git add plugin/scripts plugin/hooks tests/session-context.test.sh
git commit -m "feat(plugin): SessionStart 훅으로 핵심 규칙 주입"
```

### Task 5: 템플릿, commit-msg 훅, init 스킬

**Files:**
- Create: `plugin/templates/` (`_templates/` 전체 사본 + `STATUS.template.md`)
- Create: `plugin/templates/claude-md-block.md`
- Create: `plugin/templates/project-settings.json`
- Create: `plugin/githooks/commit-msg` (실행 권한 부여)
- Create: `plugin/skills/init/SKILL.md`
- Modify: `tests/plugin-files.test.sh` (검사 추가)

**Interfaces:**
- Consumes: Task 4의 `<waypoint>` 블록 문구
- Produces: 다음 세 파일. 절차 M의 M6 단계와 init 스킬이 이 파일들을 그대로 쓴다.
  - `plugin/templates/claude-md-block.md`
  - `plugin/templates/project-settings.json`
  - `plugin/githooks/commit-msg`

**`claude-md-block.md` 내용(그대로):**

```markdown
## Waypoint

- 이 레포는 waypoint 플러그인(`waypoint@waypoint`)으로 개발을 진행한다. 문서는 `docs/waypoint/`, 현황은 `docs/waypoint/STATUS.md`에 있다.
- 세션 시작 때 `<waypoint>` 블록(핵심 규칙)이 주입되지 않았다면 플러그인이 설치되지 않은 것이다. 작업 전에 오너에게 `claude plugin marketplace add bingoring/waypoint`와 `claude plugin install waypoint@waypoint`를 안내한다.
- STATUS.md와 DECISIONS.md는 메인 체크아웃(`<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 싣는다.
- 커밋 메시지에 `Co-Authored-By`, `Generated with Claude Code` 같은 공동작업 트레일러를 넣지 않는다. 새로 클론했다면 `git config core.hooksPath .githooks`를 한 번 실행한다.
```

**`project-settings.json`:** 설계 문서 5.4절의 JSON을 그대로 쓴다. 키는 `extraKnownMarketplaces.waypoint.source = {source: "github", repo: "bingoring/waypoint"}`와 `enabledPlugins["waypoint@waypoint"] = true`다.

**init 스킬:**
- description: 「새 프로젝트 레포를 waypoint에 연결할 때 사용한다. docs/waypoint 골격, STATUS·DECISIONS, 플러그인 설정, commit-msg 훅, CLAUDE.md 블록을 만든다.」
- 본문은 설계 문서 5.6절의 1~4단계다.
- 템플릿은 `${CLAUDE_PLUGIN_ROOT}/templates/`에서 Read로 읽는다.
- `.claude/settings.json`이 이미 있으면 키를 합친다. CLAUDE.md가 이미 있으면 블록을 끝에 덧붙인다.
- 안내문은 넣지 않는다. 아직 `docs/waypoint/`가 없는 레포에서 쓰는 스킬이기 때문이다.

- [ ] **Step 1: 실패하는 테스트 추가 — `tests/plugin-files.test.sh`**

```sh
templates-copied:     _templates/ 의 모든 파일이 plugin/templates/ 에 같은 상대 경로로 있음, plugin/templates/STATUS.template.md 있음
templates-no-old-ref: plugin/templates/ 에 "_templates" 와 "FRAMEWORK" 문자열이 없음
block-and-settings:   claude-md-block.md 에 "## Waypoint" 와 "docs/waypoint/STATUS.md" 가 있음, project-settings.json 이 JSON으로 파싱됨(python3 -m json.tool)
commit-msg-rejects:   "feat: x\n\nCo-Authored-By: A <a@b>" 메시지 파일 → plugin/githooks/commit-msg exit 1
commit-msg-rejects-2: "feat: x\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)" → exit 1
commit-msg-accepts:   "feat: x" → exit 0
init-skill:           plugin/skills/init/SKILL.md 있음, "claude-md-block.md" 와 "project-settings.json" 을 언급
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `sh tests/plugin-files.test.sh`
Expected: 새 검사들이 FAIL, exit 1

- [ ] **Step 3: 템플릿 복사와 경로 수정**

`_templates/`를 `plugin/templates/`로 복사하고, `STATUS.template.md`도 복사한다. 그다음 `grep -rn '_templates\|FRAMEWORK' plugin/templates`에 걸리는 곳을 고친다. 2026-11-24 기준으로 걸리는 곳은 네 군데다.
- `stage-template.md:33`
- `review-stage-template.md:19`
- `build-spec/build-spec-index.md:12`
- `STATUS.template.md:44`

고칠 때는 `waypoint:<스킬>` 이름이나 `${CLAUDE_PLUGIN_ROOT}/templates/...`로 바꾼다.

- [ ] **Step 4: 나머지 파일 작성**

`claude-md-block.md`, `project-settings.json`, `init/SKILL.md`를 쓴다. `githooks/commit-msg`는 `.githooks/commit-msg`의 사본으로 만들고, 주석의 「FRAMEWORK.md 「버전 관리」」만 「waypoint:git」으로 바꾼다. `chmod +x`를 실행한다.

- [ ] **Step 5: 테스트 통과 확인**

Run: `sh tests/plugin-files.test.sh && claude plugin validate plugin`
Expected: 둘 다 exit 0

- [ ] **Step 6: 커밋**

```bash
git add plugin/templates plugin/githooks plugin/skills/init tests/plugin-files.test.sh
git commit -m "feat(plugin): 템플릿·commit-msg 훅·init 스킬"
```

### Task 6: 실제 세션 검증과 waypoint PR

**Files:** 없음(검증과 PR)

- [ ] **Step 1: 테스트 전체와 매니페스트 검증**

Run: `sh tests/check-framework-split.test.sh && sh tests/session-context.test.sh && sh tests/plugin-files.test.sh && claude plugin validate . && claude plugin validate plugin`
Expected: 모두 exit 0

- [ ] **Step 2: 실제 세션에서 주입 확인**

임시 디렉터리에 git 레포를 만들고 `docs/waypoint/STATUS.md`를 넣는다. 그 레포에서 다음을 실행한다.
`claude -p --plugin-dir <worktree>/plugin "세션 시작 때 주입된 <waypoint> 블록에서 '메인 체크아웃:' 줄을 그대로 출력하라"`
Expected: `메인 체크아웃: <임시 레포 경로>`

- [ ] **Step 3: compact 뒤 재주입 확인**

Step 2의 세션 id로 다음을 차례로 실행한다.
1. `claude -p --resume <id> --plugin-dir <worktree>/plugin "/compact"`
2. 같은 질문을 다시 보낸다.

Expected: 같은 줄이 출력된다. `-p`로 compact를 실행할 수 없으면, 실측하지 못했다는 사실을 PR 본문 「미확인」에 적는다. 이 경우 오너에게 플러그인 설치 후 대화형 세션에서 `/compact`로 확인해 달라고 요청한다.

- [ ] **Step 4: waypoint를 쓰지 않는 디렉터리에서 조용한지 확인**

waypoint 메인 체크아웃에서 `CLAUDE_PROJECT_DIR=/Users/ywyeom/private/waypoint sh plugin/scripts/session-context.sh`를 실행한다.
Expected: 출력 없음

- [ ] **Step 5: push와 PR**

```bash
git push -u origin feat/plugin
gh pr create --base master --title "feat(plugin): waypoint를 Claude Code 플러그인으로" --body-file <본문 파일>
```

PR 본문에 넣을 것:
- 요약
- 대조표 링크와 「고친 문장」 표 전문
- Step 1~4 결과
- 「이 PR을 머지하는 순간 플러그인 내용이 적용된다(version 생략)」
- 「`projects/`와 FRAMEWORK.md는 그대로라 이전 안 한 레포에 영향 없음」
- 미확인 항목

PR 본문에도 트레일러를 넣지 않는다.

- [ ] **Step 6: 오너가 머지하면 설치**

Run: `claude plugin marketplace add bingoring/waypoint && claude plugin install waypoint@waypoint`
Expected: 설치 성공. `claude plugin list`에 `waypoint@waypoint`가 보인다.

### Task 7: shadow의 미커밋 문서를 waypoint에 커밋

**작업 위치:** waypoint 메인 체크아웃 `/Users/ywyeom/private/waypoint` (master)

**대상:** `/Users/ywyeom/private/shadow/docs/dlc`의 변경. 이 체크아웃은 detached HEAD 8782782이다. 8782782 이후 waypoint master에서 `projects/shadow`가 바뀐 적이 없으므로 그대로 적용된다.
- 수정: `projects/shadow/STATUS.md`, `projects/shadow/01-inception/01-context-synthesis.md`
- 새 파일: `projects/shadow/{prd.md,prd-tech.md,DECISIONS.md}`

- [ ] **Step 1: 변경을 밖으로 빼낸다**

```bash
T=$(mktemp -d)
git -C /Users/ywyeom/private/shadow/docs/dlc diff > "$T/shadow.patch"
cp /Users/ywyeom/private/shadow/docs/dlc/projects/shadow/{prd.md,prd-tech.md,DECISIONS.md} "$T/"
```

Expected: `shadow.patch`가 두 파일을 바꾼다(`git apply --stat "$T/shadow.patch"`로 확인).

- [ ] **Step 2: waypoint master에 적용하고 커밋**

```bash
cd /Users/ywyeom/private/waypoint && git pull --rebase
git apply "$T/shadow.patch" && cp "$T"/{prd.md,prd-tech.md,DECISIONS.md} projects/shadow/
git add projects/shadow && git commit -m "docs(shadow): 2026-07-10에 쓰고 커밋하지 않았던 문서 반영(PRD 사본·DECISIONS·1-1 보강)" && git push
```

- [ ] **Step 3: shadow의 submodule 체크아웃을 정리**

```bash
cd /Users/ywyeom/private/shadow/docs/dlc
git checkout -- . && rm projects/shadow/{prd.md,prd-tech.md,DECISIONS.md}
git fetch -q && git checkout -q origin/master
for f in prd.md prd-tech.md DECISIONS.md; do cmp "$T/$f" "projects/shadow/$f"; done
git status --porcelain
```

Expected: `cmp`가 아무것도 출력하지 않는다. `git status --porcelain`의 출력이 비어 있다.

### Task 8: shadow 이전 (파일럿)

**매개변수:** `NAME=shadow`, `REPO=/Users/ywyeom/private/shadow`, `SUB=docs/dlc`, `BASE=master`, GitHub `bingoring/shadow`

**게이트:** 열린 PR이 없고, 미머지 브랜치가 없고, Task 7이 끝났어야 한다. 이 레포에서 작업하는 다른 세션이 없는지 오너에게 확인받는다.

**레포 고유 사항:**
- CLAUDE.md가 없으므로 블록만 담아 새로 만든다.
- CI와 빌드가 없다.
- 루트의 `prd.md`, `prd-tech.md`는 `docs/waypoint/`의 같은 이름 파일과 내용이 같다. 둘 다 그대로 두고, 이 사실을 PR 본문에 적는다.
- grep 예외: `docs/superpowers/plans/2026-06-02-waypoint-framework.md`, `docs/superpowers/specs/2026-06-02-waypoint-framework-design.md`. 둘 다 과거 기록이다.

- [ ] **Step 1: 아래 「절차 M」의 M0~M10을 이 매개변수로 실행한다.** 각 M 단계의 Expected를 확인한다.
- [ ] **Step 2: 실제 세션 확인**

PR이 머지되고 M10까지 끝나면 shadow에서 다음을 실행한다.
`claude -p "세션 시작 때 주입된 <waypoint> 블록에서 '메인 체크아웃:' 줄을 그대로 출력하라"`
Expected: `메인 체크아웃: /Users/ywyeom/private/shadow`

- [ ] **Step 3: 절차 M 보완**

파일럿에서 절차 M과 다르게 해야 했던 점이 있으면, 이 계획 문서의 절차 M을 고쳐 커밋한다. 나머지 레포가 같은 절차를 쓰기 때문이다.

---

## 절차 M — 레포 이전 공통 절차

매개변수: `NAME`(waypoint `projects/` 아래 이름), `REPO`(로컬 경로), `SUB`(submodule 경로), `BASE`(기본 브랜치), `GH`(GitHub `owner/repo`). 사전 준비로 `git-filter-repo`가 없으면 `brew install git-filter-repo`를 실행한다.

`plugin/...` 경로는 waypoint 메인 체크아웃(`/Users/ywyeom/private/waypoint/plugin/...`)의 파일을 가리킨다.

> **shadow 파일럿에서 보완한 점(2026-11-25):**
> - M0: 실행 중인 다른 세션은 `lsof -a -d cwd -c claude -Fn | grep '^n'`으로 확인할 수 있다. `$REPO`나 그 worktree가 나오면 오너에게 멈춰 달라고 요청한다.
> - M3: 서브모듈이 하나뿐이면 `.gitmodules`가 빈 파일로 남는다. 같은 커밋에서 `git rm .gitmodules`로 지운다.
> - M6: CLAUDE.md가 없던 레포는 `# <NAME>` 제목 한 줄 뒤에 블록을 넣는다.
> - M10: `git rm -rq projects/$NAME`은 디렉터리까지 지우므로 `mkdir -p projects/$NAME` 뒤에 MOVED.md를 만든다.
> - 마무리 확인: 설치된 플러그인으로 `$REPO`에서 `claude -p "…<waypoint> 블록의 '메인 체크아웃' 줄을 출력하라"`를 실행해 `메인 체크아웃: $REPO`가 나오는지 본다.

- [ ] **M0 게이트 확인**

```bash
gh pr list -R $GH --state open                      # 비어 있어야 함
git -C $REPO fetch -q && git -C $REPO branch -a --no-merged origin/$BASE   # 비어 있어야 함
git -C $REPO worktree list                          # 각 worktree <wt> 에 대해 아래 두 줄
git -C <wt> status --porcelain                      # 비어 있어야 함
git -C <wt>/$SUB status --porcelain                 # 비어 있어야 함
git -C $REPO branch --show-current                  # $BASE 여야 함
```

메인 체크아웃이 `$BASE`가 아니면, 그 브랜치를 맡은 세션이나 오너가 먼저 그 작업을 worktree로 옮긴다(2단계 설계 `2026-11-25-status-cleanup-design.md` 5.8절). 새 규칙에서는 메인 체크아웃을 늘 기본 브랜치에 둔다.

하나라도 비어 있지 않으면 멈추고 오너에게 보고한다. 모두 비어 있으면 오너에게 「지금 $REPO에서 작업 중인 다른 세션을 멈춰 달라」고 요청하고 확인을 받는다.

- [ ] **M1 문서 이력 떼어 내기**

```bash
W=$(mktemp -d) && git clone -q https://github.com/bingoring/waypoint "$W/wp"
SPLIT_FROM=$(git -C "$W/wp" rev-parse HEAD)
git -C "$W/wp" filter-repo --force --path projects/$NAME/ --path-rename projects/$NAME/:docs/waypoint/
```

Expected:
- `git -C "$W/wp" ls-files | grep -v '^docs/waypoint/'`의 출력이 비어 있다.
- `git -C "$W/wp" log --oneline | wc -l`이 1보다 크다.

- [ ] **M2 브랜치 만들기**

`git -C $REPO switch -c chore/waypoint-plugin origin/$BASE`

- [ ] **M3 submodule 제거**

```bash
cd $REPO && git submodule deinit -f $SUB && git rm -f $SUB && rm -rf .git/modules/$SUB
git commit -m "chore(waypoint): waypoint 서브모듈 제거"
```

Expected: `.gitmodules`가 없어졌거나 `$SUB` 항목이 빠져 있다.

- [ ] **M4 문서 이력 병합**

```bash
git remote add wp-split "$W/wp" && git fetch -q wp-split
git merge --allow-unrelated-histories --no-edit wp-split/master -m "chore(waypoint): waypoint 문서 이력 가져오기 (projects/$NAME → docs/waypoint, 관계없는 이력 1회 병합이라 브랜치 규칙의 base merge가 아님)"
git remote remove wp-split
```

Expected: `git log --oneline -- docs/waypoint/STATUS.md | wc -l`이 1보다 크다.

- [ ] **M5 경로 바꾸기**

치환 대상은 `git grep -l -e "docs/dlc/projects/$NAME/" -e "$SUB/projects/$NAME/"`로 찾는다. 다음 경로는 대상에서 뺀다.
- `docs/waypoint/DECISIONS.md`
- `docs/superpowers/`

찾은 파일에서 다음을 바꾼다. 바꾼 결과는 `git diff`로 한 줄씩 읽는다.
- 위 두 접두어 → `docs/waypoint/`
- `docs/dlc/FRAMEWORK.md`, `$SUB/FRAMEWORK.md` → `waypoint:start` 등 해당 스킬 이름
- `docs/waypoint/` 안의 `../../FRAMEWORK.md`, `../../_templates/` → 해당 스킬 이름(`git grep -n '\.\./\.\./\(FRAMEWORK\|_templates\)' docs/waypoint`로 찾는다)

```bash
git commit -am "docs(waypoint): 문서 경로를 docs/waypoint로 바꿈"
```

- [ ] **M6 플러그인 설정·훅·CLAUDE.md**

1. `.claude/settings.json`이 없으면 `plugin/templates/project-settings.json`을 복사한다. 있으면 두 키를 합친다.
2. `.githooks/commit-msg`가 없으면 `plugin/githooks/commit-msg`를 복사하고 `chmod +x`한다. `.githooks/pre-commit`도 없으면 `plugin/githooks/pre-commit`을 복사하고 `chmod +x`한다. `.githooks/pre-commit`이 이미 있으면 덮어쓰지 말고 멈춰서 오너에게 알린다(합친 파일의 둘째 줄에도 `# waypoint-hook-version: <번호>`가 있어야 세션 시작 때 낡은 훅을 알아챈다).
3. `git config core.hooksPath .githooks`를 실행한다.
4. CLAUDE.md를 정리한다.
   - waypoint·`docs/dlc`·서브모듈 커밋 순서를 말하던 문장을 지운다.
   - `plugin/templates/claude-md-block.md`의 내용을 넣는다.
   - 레포 고유 규칙은 그대로 둔다.

```bash
git add -A .claude .githooks CLAUDE.md && git commit -m "chore(waypoint): 플러그인 설정·commit-msg 훅·CLAUDE.md 블록"
```

- [ ] **M6a STATUS 변환**

2단계 설계(`docs/superpowers/specs/2026-11-25-status-cleanup-design.md`) 5.8절 「변환 절차」 1~8번을 따른다. 기준이 되는 옛 STATUS는 M5까지 반영된 커밋의 `docs/waypoint/STATUS.md`다. M6에서 설치한 pre-commit 훅이 변환 결과를 검사한다.

```bash
OLD=$(git rev-parse HEAD)                     # M5·M6까지 반영된 커밋
{ printf '%s STATUS 정리 때 옮긴 기록이다. 이후로는 쓰지 않는다.\n\n' "$(date +%F)"; git show "$OLD:docs/waypoint/STATUS.md"; } > docs/waypoint/HISTORY.md
# 2~6번: 새 표 작성(상태 값 대응표), 스테이지 문서 frontmatter(id:)·진행 기록, 오너 확인 목록 → 오너 답 반영
tail -n +3 docs/waypoint/HISTORY.md | diff - <(git show "$OLD:docs/waypoint/STATUS.md")   # 출력 없음
git add docs/waypoint && WAYPOINT_ALLOW_BRANCH_STATUS=1 git commit -m "docs(waypoint): STATUS를 새 형식으로 변환(옛 내용은 HISTORY.md)"
```

Expected: `diff` 출력이 없고, 커밋이 pre-commit 검사를 통과한다. `WAYPOINT_ALLOW_BRANCH_STATUS=1`은 이 커밋에만 쓴다.

- [ ] **M6b 보드 적용(선택)**

4단계 설계(`docs/superpowers/specs/2026-11-25-board-sync-design.md`) 5.10절 「레포마다 하는 일」이다. M6a의 새 형식 STATUS가 있어야 한다. 오너가 보드를 원하지 않으면 건너뛴다. 템플릿 Project(「waypoint 보드 템플릿」)가 아직 없으면 먼저 `sh <waypoint 체크아웃>/plugin/scripts/board-setup.sh template <소유자>`로 만들고, 출력 끝의 「GitHub 화면에서 할 일」 세 가지를 마친다.

```bash
gh auth status 2>&1 | grep -q "'project'" || echo "오너가 gh auth refresh -s project 를 먼저 실행한다"
sh <waypoint 체크아웃>/plugin/scripts/board-setup.sh repo $REPO <템플릿 주소>
git add CLAUDE.md .githooks/pre-push .githooks/board-sync.sh && git commit -m "chore(waypoint): 보드 동기화(보드 줄과 pre-push 훅)"
```

Expected: 「복사함」과 「연결함」이 나오고, CLAUDE.md의 「검토 대기 상한」 줄 아래에 `- 보드: <주소>` 줄이 생긴다. 이 브랜치의 push는 기본 브랜치로 가지 않으므로 동기화를 띄우지 않는다. 첫 동기화는 M10의 7번에서 한다. M9에서 M1부터 다시 하게 되면 `board-setup.sh repo`를 다시 실행하지 않는다(Project가 하나 더 생긴다). 앞 브랜치의 보드 줄과 `.githooks/` 두 사본을 같은 내용으로 다시 넣어 커밋한다.

- [ ] **M7 CI**

`.gitmodules`가 없어졌다면 `.github/workflows/*.yml`의 `submodules: true` 줄을 지운다. 문서 경로로 판정하는 조건(`waypoint`, `docs/dlc`)은 `docs/waypoint/**`로 바꾼다. 바뀐 것이 있으면 커밋한다: `git commit -am "ci: waypoint 서브모듈 체크아웃 제거"`.

- [ ] **M8 검증**

```bash
git grep -n -e 'docs/dlc' -e 'waypoint/projects' -- ':!docs/waypoint/DECISIONS.md' ':!docs/waypoint/HISTORY.md' ':!docs/superpowers'   # 0줄
git grep -nw waypoint -- ':!docs/waypoint' ':!docs/superpowers' ':!CLAUDE.md' ':!.claude'                 # 한 줄씩 판단
git log --merges --oneline origin/$BASE..HEAD                                                             # M4 커밋 한 줄만
CLAUDE_PROJECT_DIR=$REPO sh <waypoint 체크아웃>/plugin/scripts/session-context.sh | head -3             # "<waypoint>", "# waypoint 핵심 규칙"
```

그리고 레포 고유의 빌드와 테스트를 실행한다. 이 명령들은 각 Task에 적혀 있다.

- [ ] **M9 PR**

```bash
git push -u origin chore/waypoint-plugin
gh pr create -R $GH --base $BASE --title "chore(waypoint): waypoint 문서를 docs/waypoint로 옮기고 플러그인으로 전환" --body-file <본문 파일>
```

본문에 넣을 것:
- 무엇을 옮겼는지
- `SPLIT_FROM` 해시
- grep 예외 목록
- 「**merge commit으로 머지할 것(squash 금지: 이력이 사라짐)**」
- 머지 뒤 남은 브랜치 처리법(설계 문서 5.5절 「남는 브랜치의 처리」)

오너가 머지하기 직전에 `git -C /Users/ywyeom/private/waypoint fetch -q && git -C /Users/ywyeom/private/waypoint log --oneline $SPLIT_FROM..origin/master -- projects/$NAME`를 실행한다. 출력이 있으면 M1부터 다시 하고(M6a의 STATUS 변환도 다시 한다) 브랜치를 force-with-lease로 갱신한다.

- [ ] **M10 머지 뒤 정리**

1. waypoint 메인 체크아웃에서 `git pull --rebase`를 실행한다.
2. `git rm -rq projects/$NAME`을 실행한다.
3. `projects/$NAME/MOVED.md`를 아래 내용으로 만든다.
4. `git add projects/$NAME && git commit -m "docs($NAME): 문서를 $GH의 docs/waypoint로 옮김" && git push`를 실행한다.

```markdown
# $NAME 문서는 이전되었습니다

- 새 위치: https://github.com/$GH/tree/$BASE/docs/waypoint
- 이전 날짜: YYYY-MM-DD
- 이 디렉터리의 마지막 내용: waypoint 커밋 $SPLIT_FROM
- 이 경로에 문서를 다시 쓰지 않는다. waypoint 플러그인(`waypoint@waypoint`)을 설치하고 새 위치를 쓴다.
```

5. 프로젝트 레포에서 `git -C $REPO switch $BASE && git -C $REPO pull --rebase`를 실행한다.
6. 각 worktree `<wt>`에서 옛 submodule 디렉터리가 남아 있으면 지운다. 남아 있는 디렉터리는 추적되지 않는 상태여야 한다.

Expected: 모든 worktree에서 `test ! -e <wt>/$SUB`가 참이다.

7. M6b를 했으면 프로젝트 레포의 메인 체크아웃에서 `sh .githooks/board-sync.sh`로 첫 동기화를 한다. `git config core.hooksPath`가 `.githooks`인지도 확인한다.

Expected: `.git/waypoint/board-sync.status`가 `ok`로 시작하고, `MERGED`가 아닌 STATUS 줄마다 이슈가 하나씩 보드에 들어가 있다.

---

## Part B — 게이트가 열리면 실행

각 Task는 절차 M을 실행한다. 게이트는 M0의 확인 결과다. Task 번호는 우선순위이고, 게이트가 먼저 열린 레포부터 한다.

### Task 9: tokens-are-running-out

- **매개변수:** `NAME=tokens-are-running-out`, `REPO=/Users/ywyeom/private/tokens-are-running-out`, `SUB=docs/dlc`, `BASE=main`, `GH=bingoring/tokens-are-running-out`
- **게이트(2026-11-24 기준 닫힘):** 에이전트 worktree 브랜치 2개(`.claude/worktrees/agent-*`)가 머지되거나 버려져야 한다.
- **고유 사항**
  - `core.hooksPath`가 `docs/dlc/.githooks`를 가리킨다. M6에서 `.githooks`로 바꾼다.
  - CLAUDE.md의 「Waypoint」 절과 「커밋과 브랜치」 절의 `docs/dlc` 문장(15행 근처)을 블록으로 교체한다.
  - `README.md`의 참조를 바꾼다.
- **검증:** 레포 CI가 실행하는 테스트 명령을 실행한다(Global Constraints).
- **기록:** 문서 포인터만 바꾸던 PR 흐름(#12~#14)은 이제 필요 없다. 이 사실을 PR 본문에 적는다.

### Task 10: duty

- **매개변수:** `NAME=duty`, `REPO=/Users/ywyeom/private/duty`, `SUB=waypoint`, `BASE=main`, `GH=bingoring/duty`
- **게이트(닫힘):** `feature/3-13-cutover-monitoring`이 머지되어야 한다.
- **고유 사항**
  - M5 치환 접두어는 `waypoint/projects/duty/`다.
  - M7·M8에서 다음을 손본다.
    - `.dockerignore`, `.prettierignore`의 `waypoint` 줄을 `docs/waypoint`로 바꾼다.
    - `.github/workflows/ci.yml` 29행 근처의 「문서·waypoint 포인터만 바뀐 커밋」 판정 경로를 `docs/waypoint/**`로 바꾼다.
  - `deploy/gcp/serverless.sh`, `deploy/cloudrun/README.md`, `fixtures/paper-2026-10.json`의 참조를 바꾼다.
  - CLAUDE.md가 없으므로 새로 만든다.
- **검증:** 레포 CI가 실행하는 테스트 명령을 실행한다. 그리고 `ci.yml`의 「문서 전용 변경」 판정 단계를 로컬에서 그대로 실행해, `docs/waypoint/`만 바꾼 커밋이 여전히 문서 전용으로 판정되는지 확인한다.

### Task 11: app-factory

- **매개변수:** `NAME=app-factory`, `REPO=/Users/ywyeom/private/app-factory`, `SUB=docs/dlc`, `BASE=main`(M0 전에 `git -C $REPO symbolic-ref refs/remotes/origin/HEAD`로 확인), `GH=bingoring/app-factory`
- **게이트(닫힘):** 다음이 모두 머지되거나 정리되어야 한다.
  - PR #22, #23, #24
  - golf-proto, target-families 브랜치
  - worktree 4곳(`app-factory`, `app-factory-golf`, `app-factory-release`, `app-factory-yawn`)의 브랜치
- **고유 사항**
  - `.githooks/`가 이미 있으므로 그대로 둔다.
  - CLAUDE.md 9행 근처의 서브모듈 순서 문장을 블록으로 교체한다.
  - `README.md`, `prototypes/ball-roguelite/README.md`, `apps/yawn/tool/sprites/export.py`의 사용법 주석(5행, `../../docs/dlc/projects/app-factory/...` → `../../docs/waypoint/...`)을 바꾼다.
  - 레포가 private이므로 문서도 이제 비공개가 된다. 이 사실을 PR 본문에 적는다.
  - M9에서 PR을 `gh pr create --draft`로 연다. 거절되면 일반 PR로 열고, 그 결과를 오너에게 알린다. 개인 계정의 private 레포에서 초안 PR을 쓸 수 있는지가 2단계 설계 10절의 미확인 사항이다. 쓸 수 없으면 이 레포의 스테이지 PR은 제목 앞 `[작업 중]` 표시로 대신한다(`waypoint:git`).
  - M10에서 worktree 4곳 모두의 `docs/dlc`를 확인한다.
- **검증:** 레포 CI가 실행하는 테스트 명령을 실행한다. 그리고 `python3 -m py_compile apps/yawn/tool/sprites/export.py`를 실행한다.

### Task 12: forin

- **매개변수:** `NAME=forin`, `REPO=/Users/ywyeom/private/forin`, `SUB=docs/dlc`, `BASE=master`, `GH=bingoring/forin`
- **게이트(닫힘):** 다음이 모두 머지되거나 정리되어야 한다.
  - PR #32~#38
  - `content/or-batch6`
  - 메인 체크아웃의 미커밋 yaml 변경
- **고유 사항**
  - 참조가 37곳이다. M5 대상에 다음이 포함된다.
    - `server/content/tools/*.py`
    - `server/internal/ports/ports.go`
    - `mobile/src/components/**`
    - `.claude/launch.json`
    - `README.md`, `infra/README.md`, `.gitignore` 주석
  - `mobile/src/components/nb/nbMotion.test.tsx`와 `ficons.test`가 디자인 참조 파일을 직접 읽는다. 그 파일을 읽는 경로를 바꾼다.
  - M7: `.github/workflows/build.yml`, `ota.yml`, `mobile.yml`의 `submodules: true`를 지운다.
  - 문서 117MB가 레포에 들어온다. 체크아웃 크기 증가를 PR 본문에 적는다.
- **검증**
  - `cd mobile && npx jest nbMotion ficons`
  - 레포 CI(`build.yml`, `ota.yml`, `mobile.yml`)가 실행하는 나머지 테스트 명령
  - 경로를 바꾼 `server/content/tools/*.py` 각각에 `python3 -m py_compile`
  - PR의 CI 세 워크플로가 통과하는지 확인한다.

### Task 13: 5단계 — waypoint 마무리

- **게이트:** `projects/` 아래에 `MOVED.md`만 있는 디렉터리가 다섯 개이고, 다른 파일이 없어야 한다.
- [ ] **Step 1:** 다음을 지운다.
  - `projects/`
  - `_templates/`
  - `STATUS.template.md`
  - 루트 `.githooks/`
  - `tests/check-framework-split.sh`, `tests/check-framework-split.test.sh`
  - `tests/plugin-files.test.sh`의 `framework-split` 검사
  
  waypoint 레포 자신의 훅 경로는 `git config core.hooksPath plugin/githooks`로 바꾼다.
- [ ] **Step 2:** 여섯 스킬의 안내문 줄과 `skills-have-guard` 검사를 지운다. 이제 옛 방식을 쓰는 레포가 없기 때문이다.
- [ ] **Step 3:** `FRAMEWORK.md`를 사람용 개요와 스킬 색인으로 바꾼다. 규칙 본문은 두지 않는다.
- [ ] **Step 4:** `README.md`를 바꾼다. 「새 프로젝트에 적용하기」에 플러그인 설치 두 명령과 `waypoint:init`을 쓴다.
- [ ] **Step 5:** `CLAUDE.md`를 플러그인 개발용으로 바꾼다. 내용은 다음과 같다.
  - 규칙 원본은 `plugin/core-rules.md`와 `plugin/skills/`다.
  - 커밋 규칙
  - 「머지하면 바로 적용되므로 규칙 변경은 PR로」
- [ ] **Step 6:** 남은 테스트를 실행한다. `sh tests/session-context.test.sh && sh tests/plugin-files.test.sh && claude plugin validate . && claude plugin validate plugin`이 모두 exit 0이어야 한다.
- [ ] **Step 7:** PR로 올리고 오너가 머지한다.
