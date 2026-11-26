# waypoint STATUS 정리(2단계) — 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** STATUS.md를 「스테이지 한 줄 = 카드 한 장」인 표로 바꾸는 규칙, 검사, 세션 시작 요약을 플러그인에 넣고, 머지 직후 이미 이전된 레포(지금은 shadow)의 STATUS를 새 형식으로 옮긴다.

**Architecture:** 검사 2(STATUS 형식)의 본문은 `plugin/scripts/status-check.sh`의 표지 줄 사이 함수 하나에 두고, `plugin/githooks/pre-commit`에 같은 블록을 그대로 넣는다. 테스트가 두 블록이 같은지 확인한다. SessionStart 훅은 셸 내장 명령만으로 메인 체크아웃의 STATUS 표를 줄 단위로 읽어 요약을 붙인다. 규칙 문장은 `core-rules.md`와 스킬 네 개(stage, start, git, init)와 템플릿에 나눠 넣는다.

**Tech Stack:** POSIX sh, git, Claude Code 플러그인(스킬·훅)

**Spec:** `docs/superpowers/specs/2026-11-25-status-cleanup-design.md`(이하 「설계」). 관련: `docs/superpowers/specs/2026-11-25-board-sync-design.md`(4단계, 5.7절이 내용 검사만 쓴다).

**실행 단위:**
- **Part A(Task 1~8):** 지금 실행한다. waypoint worktree에서 플러그인을 고치고 PR을 연다.
- **Part B(Task 9):** 오너가 PR을 머지한 직후 실행한다.
- **2단계의 끝:** PR 머지, Task 9의 변환 완료, 변환한 레포에서 새 세션을 열었을 때 요약이 주입되는 것.

## Global Constraints

- **작업 위치:** worktree `/Users/ywyeom/private/waypoint/.claude/worktrees/status-cleanup`, 브랜치 `feat/status-cleanup`(`origin/master`에서 시작). waypoint 메인 체크아웃에서 브랜치를 바꾸지 않는다.
- **커밋:** conventional commit 한 줄. `Co-Authored-By`, `Generated with` 같은 트레일러와 AI 서명은 커밋 메시지와 PR 본문 어디에도 넣지 않는다. 커밋 직후 push한다. PR을 열기 전 `git rebase origin/master`로 맞춘다(merge 금지).
- **손대지 않는 파일:** `FRAMEWORK.md`, `_templates/`. 아직 이전하지 않은 레포가 서브모듈로 읽는다. 바꾸는 템플릿은 `plugin/templates/`뿐이다.
- **`plugin/scripts/session-context.sh`:** 셸 내장 명령만 쓴다(SessionStart 때 PATH가 비어 있을 수 있다). 항상 exit 0.
- **`status-check.sh`와 `pre-commit`:** POSIX sh. 커밋 시점에 실행되므로 `git`, `grep`, `sed`, `tr`, `wc`, `awk`, `mktemp`를 쓸 수 있다. index는 반드시 git 명령(`git diff --cached`, `git show :<경로>`, `git grep --cached`, `git cat-file`)으로 읽는다. `commit -a`와 `git commit <경로>`는 임시 index(`GIT_INDEX_FILE`)를 쓰기 때문이다.
- **「지금」 글자 수:** `printf '%s' "$s" | LC_ALL=C tr -d '\200-\277' | wc -c`로 센다. 2026-11-26 실측: `${#s}`는 `LC_ALL=C`에서, macOS `awk`(20200816)는 로케일과 상관없이 바이트 수를 냈다. 위 방법은 C, en_US.UTF-8, ko_KR.UTF-8에서 모두 글자 수를 냈다.
- **STATUS 표 머리 줄(정확히):** `| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |`
- **상태 값 여섯 개:** `PENDING`, `IN_PROGRESS`, `AI_PROPOSED`, `HUMAN_APPROVED`, `MERGED`, `DEFERRED`. 보드 열: 대기, 진행 중, 검토 대기, 승인, 머지됨, 보류.
- **「지금」 머리말(정확히):** `계획: `, `구현: `(IN_PROGRESS), `계획 검토: `, `결과 검토: `(AI_PROPOSED), DEFERRED는 넷 가운데 하나.
- **ID 형식:** `^[123R]-[0-9]+$`. 다섯 레포의 지금 ID는 모두 이 형식이다(2026-11-26 확인).
- **예외 변수:** `WAYPOINT_ALLOW_BRANCH_STATUS=1`은 검사 1만 건너뛴다.
- **훅 버전 줄:** `plugin/githooks/pre-commit`의 둘째 줄은 `# waypoint-hook-version: 1`이다.
- **기본 브랜치:** `refs/remotes/origin/HEAD`가 있으면 그 대상, 없으면 `main`과 `master`를 모두 기본 브랜치로 본다. pre-commit과 session-context가 같은 규칙을 쓴다.
- **`core-rules.md`:** 지금 19줄이다. 줄 수를 늘리지 않는다.
- **대조표:** 스킬과 core-rules에서 FRAMEWORK에서 온 줄을 고치면 `docs/superpowers/specs/2026-11-24-framework-split-map.md`에 기록한다. `- 새 문장:`에는 `…`를 쓰지 않는다(ELLIPSIS로 실패한다). 검사기는 부분 문자열로 세므로, 새 줄이 옛 줄을 포함하면 옛 줄은 그대로 있는 것으로 센다.
- **스킬 첫 줄 안내문:** 모든 스킬의 「이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다」 줄을 지우지 않는다.
- **사용자에게 보이는 문구:** 훅과 스크립트의 메시지는 한국어로 쓴다.

**4단계 설계와 다른 점(오너 확인용):** 4단계 5.13절은 `status-check.sh`의 「내용 검사만」 모드를 4단계에서 만든다고 적었다. 이 계획은 그 모드를 지금 만든다(Task 1). 레포마다 복사한 pre-commit 사본을 4단계에서 다시 바꾸지 않으려는 것이다. 동작은 4단계 설계와 같다.

## Review Focus

1. **기본 브랜치에서 `git pull --rebase` 중 STATUS가 충돌하는 경우.** rebase 중에는 HEAD가 분리되어 있다. 기대 동작: 충돌을 풀고 `git rebase --continue`하면 막히지 않고 끝난다(2026-11-26 실측: rebase는 pre-commit을 부르지 않는다). Task 2의 `rebase-conflict` 테스트가 고정한다.
2. **한글 「지금」이 80자와 81자인 경우.** 로케일이 C이거나 비어 있어도 80자는 통과하고 81자는 실패해야 한다. Task 1의 `now-80`, `now-81` 테스트를 `LC_ALL=C`와 `env -u LANG -u LC_ALL`에서 모두 돌린다.
3. **새 형식이 아닌 레포.** pre-commit 사본이 있지만 `docs/waypoint/STATUS.md`가 없는 레포에서는 출력 없이 통과해야 한다. 옛 형식 STATUS를 가진 레포에서는 세션 시작 출력이 지금과 한 글자도 달라지지 않아야 한다. Task 2의 `plain-repo`, Task 3의 `old-format`, Task 8의 실제 shadow 비교가 확인한다.
4. **실제 index를 쓰지 않는 커밋.** `git commit -am`과 `git commit <경로> -m`은 임시 index로 커밋한다. 기대 동작: 커밋될 내용이 검사된다. Task 2의 `commit-am`, `commit-only` 테스트가 확인한다.
5. **레포 밖 세션에서 옆에 `<레포>-<ID>` worktree가 있는 경우.** worktree에도 `docs/waypoint/STATUS.md` 사본이 있고, 그 사본은 낡았을 수 있다. 기대 동작: 레포마다 개수 줄이 한 번만 나오고, 숫자는 메인 체크아웃의 STATUS에서 온다. Task 3의 `parent-dedupe` 테스트가 확인한다.

---

## 파일 구조

| 파일 | 할 일 |
|---|---|
| `plugin/scripts/status-check.sh` | 새 파일. 검사 2의 원본. 함수 `wp_status_check`를 표지 줄 사이에 둔다. |
| `plugin/githooks/pre-commit` | 새 파일. 적용 범위, 검사 1, index에서 id 목록 만들기, 검사 2 호출. 검사 2 블록은 `status-check.sh`와 글자 그대로 같다. |
| `plugin/scripts/session-context.sh` | 요약, 기본 브랜치 경고, 낡은 훅 경고, 레포 밖 세션의 중복 제거. |
| `plugin/templates/STATUS.template.md`, `stage-template.md`, `review-stage-template.md`, `claude-md-block.md` | 설계 5.1, 5.3, 5.9절. |
| `plugin/core-rules.md`, `plugin/skills/{stage,start,git,init}/SKILL.md` | 설계 5.9절 표. |
| `docs/superpowers/specs/2026-11-24-framework-split-map.md` | 2단계에서 고친 FRAMEWORK 줄의 기록. |
| `docs/superpowers/plans/2026-11-24-plugin-split.md` | 절차 M의 M0, M6, M6a(새로), M8, Task 11 메모. |
| `tests/status-check.test.sh`, `tests/pre-commit.test.sh` | 새 파일. |
| `tests/session-context.test.sh`, `tests/plugin-files.test.sh` | 경우 추가. |

전체 테스트 실행: `for t in tests/*.test.sh; do sh "$t" || echo "FAILED: $t"; done`(레포 루트에서). 이 계획 전에 네 파일 모두 `all passed`가 나와야 한다(`check-framework-split.test.sh` 포함).

---

## Part A — 지금 실행

### Task 1: STATUS 형식 검사(`status-check.sh`)

**Files:**
- Create: `plugin/scripts/status-check.sh`
- Test: `tests/status-check.test.sh`

**Interfaces:**
- Produces:
  - `sh plugin/scripts/status-check.sh <STATUS 파일> [<id 목록 파일>]`. 통과하면 출력 없이 0. 실패하면 문제마다 stderr에 한 줄을 쓰고 1.
  - id 목록 파일: 한 줄에 `<docs/waypoint 기준 상대 경로><TAB><id>`. 주면 검사 1~10을 모두 하고, 주지 않으면 6과 8을 건너뛴다(4단계의 내용 검사).
  - 본문은 `# >>> waypoint status-check >>>` 줄과 `# <<< waypoint status-check <<<` 줄 사이에 둔 함수 `wp_status_check <STATUS 파일> [<id 목록 파일>]` 하나다. 이 블록 밖의 코드는 `wp_status_check "$@"`를 부르고 그 종료 코드로 끝내는 것뿐이다. Task 2와 4단계의 `board-sync.sh`가 이 블록을 그대로 복사한다.
  - 실패 줄 형식: `STATUS.md:<줄 번호>: [검사 <k>] <무엇이 틀렸나>. <고치는 법>`. 줄 번호가 없는 문제는 `STATUS.md: [검사 <k>] …`, 검사 8은 `<문서 경로>: [검사 8] …`.

검사 항목은 설계 5.5절 「검사 2」의 1~10번 그대로다. 다음은 설계가 열어 둔 부분을 정한 것이다.
- 표: `## 스테이지` 다음의 첫 비어 있지 않은 줄이 머리 줄, 그다음이 구분 줄(`|`, `-`, `:`, 공백만으로 된 칸 7개), 그 뒤 `|`로 시작하는 줄이 끝날 때까지가 본문 줄이다. 칸은 앞뒤 `|`를 뗀 뒤 `|`로 나누고 앞뒤 공백을 지운다.
- 검사 6: 링크 칸에서 `](경로)`를 모두 뽑는다. `http`로 시작하지 않는 경로가 상대 경로다. 앞의 `./`와 뒤의 `#…`를 뗀다. 상대 경로 가운데 하나 이상이 id 목록에 있고 그 id가 줄의 ID와 같아야 한다.
- 검사 7: 링크 칸에 `[…](…)` 형태의 링크가 하나 이상 있다.
- 검사 9: `## 오너 할 일`의 `- [ ] ` 줄 끝 `(막음: A, B)`를 `, `로 나눠 각 ID를 확인한다.
- 검사 10: 첫 줄은 `# `로 시작한다. 제목과 `## 스테이지` 사이에는 비어 있지 않은 줄이 최대 한 줄(링크 줄) 있다. 허용하는 `##` 절은 `## 스테이지`와 `## 오너 할 일`뿐이고, `## 오너 할 일`은 없어도 된다. `## 스테이지` 아래에는 표 줄과 빈 줄, `## 오너 할 일` 아래에는 `- [ ] ` 줄과 빈 줄만 둔다.

- [ ] **Step 1: 테스트를 쓴다.** `tests/status-check.test.sh`는 기존 테스트 파일과 같은 틀(`fail`, `fails`, 끝의 `all passed`)을 쓴다. 통과 예시 `good`을 heredoc으로 만든다. 이 예시는 다음을 모두 담는다.
  - 여섯 상태 값을 한 줄씩. DEFERRED 줄은 `구현: 오너 보류, 출시 뒤 재개`.
  - 링크 칸이 `[문서](./02-construction/09-a.md) · [#38](https://github.com/o/r/pull/38)`인 MERGED 줄(id 목록에 `02-construction/09-a.md<TAB><그 ID>`).
  - `(막음: 3-1, 3-2)`인 오너 할 일 한 줄.
  - 「지금」이 정확히 80자인 줄: `"구현: $(printf '가%.0s' $(seq 76))"`.

  경우와 기대 결과는 아래와 같다. 실패 경우는 `good`을 `sed`로 한 곳만 바꿔 만들고, 종료 코드 1과 stderr의 `[검사 <k>]`를 확인한다.

  | 경우 | 바꾸는 곳 | 기대 |
  |---|---|---|
  | `good` | 없음 | 0, 출력 없음 |
  | `good-content-only` | id 목록 없이 실행 | 0 |
  | `h1-no-section` | `## 스테이지` 지움 | 검사 1 |
  | `h1-header` | 머리 줄의 `스테이지`를 `이름`으로 | 검사 1 |
  | `c2-cells` | 한 줄의 칸을 6개로 | 검사 2 |
  | `s3-state` | 상태를 `IMPLEMENTED`로 | 검사 3 |
  | `i4-format` | ID를 `2-9a`로 | 검사 4 |
  | `i4-dup` | ID 하나를 다른 줄과 같게 | 검사 4 |
  | `now-80` | 없음(`good`의 80자 줄). `LC_ALL=C`와 `env -u LANG -u LC_ALL`에서 각각 | 0 |
  | `now-81` | 80자 줄에 `가` 하나 추가. 두 로케일에서 각각 | 검사 5 |
  | `n5-pending` | PENDING 줄의 「지금」에 글 | 검사 5 |
  | `n5-prefix` | IN_PROGRESS 줄을 머리말 없이 | 검사 5 |
  | `n5-wrong-prefix` | AI_PROPOSED 줄을 `구현: `으로 | 검사 5 |
  | `m6-pr-only` | MERGED 줄의 링크를 PR 링크만 | 검사 6 |
  | `m6-missing` | MERGED 줄의 문서 경로를 목록에 없는 경로로 | 검사 6 |
  | `m6-id` | id 목록의 그 문서 id를 다른 값으로 | 검사 6 |
  | `m6-content-only` | `m6-pr-only`를 id 목록 없이 | 0 |
  | `l7-no-link` | IN_PROGRESS 줄의 링크 칸 비움 | 검사 7 |
  | `d8-missing-row` | id 목록에 `02-construction/15-x.md<TAB>2-15` 추가 | 검사 8 |
  | `d8-content-only` | `d8-missing-row`를 id 목록 없이 | 0 |
  | `b9-block` | `(막음: 9-9)` | 검사 9 |
  | `a10-banner` | 링크 줄 아래에 `> **배너**` 줄 | 검사 10 |
  | `a10-section` | 끝에 `## 메모` 절 | 검사 10 |
  | `a10-two-links` | 링크 줄 두 개 | 검사 10 |
  | `a10-checked` | 오너 할 일을 `- [x] …`로 | 검사 10 |
  | `two-problems` | `s3-state`와 `b9-block`을 함께 | 1, stderr 두 줄 이상 |

- [ ] **Step 2: 실패를 확인한다.** Run: `sh tests/status-check.test.sh`. Expected: 스크립트가 없어서 FAIL이 여러 줄 나온다.
- [ ] **Step 3: `plugin/scripts/status-check.sh`를 쓴다.** 첫 줄 `#!/bin/sh`, 실행 권한을 준다. 위 Interfaces대로 함수와 표지 줄을 둔다. 함수 안에서 임시 파일이 필요하면 `mktemp`로 만들고 함수 끝에서 지운다.
- [ ] **Step 4: 통과를 확인한다.** Run: `sh tests/status-check.test.sh`. Expected: `all passed`.
- [ ] **Step 5: 커밋하고 push한다.** `git add plugin/scripts/status-check.sh tests/status-check.test.sh && git commit -m "feat(plugin): STATUS 형식 검사 스크립트" && git push -u origin feat/status-cleanup`

### Task 2: pre-commit 훅

**Files:**
- Create: `plugin/githooks/pre-commit`
- Test: `tests/pre-commit.test.sh`, `tests/plugin-files.test.sh`(블록 일치 검사 추가)

**Interfaces:**
- Consumes: Task 1의 표지 블록(`wp_status_check`).
- Produces: `.githooks/pre-commit`으로 복사할 훅. 둘째 줄 `# waypoint-hook-version: 1`. Task 3이 이 줄을 읽는다.

훅의 순서:
1. `git cat-file -e :docs/waypoint/STATUS.md`가 실패하면 출력 없이 0.
2. `git diff --cached --name-only`에 `docs/waypoint/STATUS.md`도 `docs/waypoint/DECISIONS.md`도 없으면 0.
3. 검사 1(`WAYPOINT_ALLOW_BRANCH_STATUS=1`이면 건너뜀): `git symbolic-ref -q --short HEAD`가 비면(detached) 거부한다. 기본 브랜치(Global Constraints)가 아니면 거부한다. 메시지 예: `pre-commit: STATUS.md·DECISIONS.md는 메인 체크아웃의 기본 브랜치에서 커밋한다(현재 <브랜치>). waypoint:git 「문서 커밋 흐름」을 따른다.`
4. STATUS가 커밋에 있으면 `git show :docs/waypoint/STATUS.md`를 임시 파일로 꺼내고, id 목록을 만들어 `wp_status_check`를 부른다. 실패하면 끝에 `pre-commit: STATUS.md 형식 검사에 실패했다. 위 줄을 고쳐 다시 add한 뒤 커밋한다(waypoint:stage 「STATUS 표」).`를 덧붙이고 1.

id 목록은 함수 `wp_index_ids`(훅에만 있다)가 만든다. `git grep --cached -n -e '^---$' -e '^id: ' -- 'docs/waypoint/*.md'` 한 번의 출력에서, 1행이 `---`이고 두 번째 `---`보다 앞에 있는 `id: ` 줄만 고른다. 값의 앞뒤 공백과 따옴표를 뗀다.

- [ ] **Step 1: 테스트를 쓴다.** `tests/pre-commit.test.sh`는 임시 레포마다 `git -c core.hooksPath=$ROOT/plugin/githooks`로 커밋한다(commit-msg 훅도 함께 돈다. 메시지에 트레일러를 넣지 않는다). Task 1의 `good` 예시를 공유하려면 `tests/fixtures/status-good.md`로 빼도 된다. 경우와 기대:

  | 경우 | 준비와 동작 | 기대 |
  |---|---|---|
  | `plain-repo` | STATUS 없는 레포, 기능 브랜치에서 아무 파일 커밋 | 성공, stderr 비어 있음 |
  | `other-files` | waypoint 레포, 기능 브랜치에서 `src/a` 커밋 | 성공 |
  | `branch-status` | 기능 브랜치에서 올바른 STATUS 커밋 | 실패, 「기본 브랜치」 |
  | `branch-decisions` | 기능 브랜치에서 DECISIONS 커밋 | 실패 |
  | `detached` | detached HEAD에서 STATUS 커밋 | 실패 |
  | `allow-var-ok` | `WAYPOINT_ALLOW_BRANCH_STATUS=1`, 기능 브랜치, 올바른 STATUS | 성공 |
  | `allow-var-bad` | 같은 변수, 상태 값이 틀린 STATUS | 실패, `[검사 3]` |
  | `main-ok` / `main-bad` | main에서 올바른/틀린 STATUS | 성공 / 실패 |
  | `index-not-worktree` | 틀린 STATUS를 add한 뒤 작업 트리만 고침 | 실패 |
  | `worktree-not-index` | 올바른 STATUS를 add한 뒤 작업 트리만 틀리게 | 성공 |
  | `commit-am` | 추적 중인 STATUS를 틀리게 고치고 `commit -am` | 실패 |
  | `commit-only` | 틀리게 고치고 `git commit docs/waypoint/STATUS.md -m …` | 실패 |
  | `origin-head` | `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop` 뒤 main에서 커밋 / develop에서 커밋 | 실패 / 성공 |
  | `unborn-main` | 첫 커밋(브랜치 `main`, 아직 커밋 없음)에 올바른 STATUS | 성공 |
  | `index-docs` | MERGED 줄이 가리키는 문서(`id:` 일치)를 같은 커밋에 / `id:`가 있지만 표에 없는 문서를 추가 | 성공 / 실패, `[검사 8]` |
  | `rebase-conflict` | 원격과 로컬이 STATUS의 같은 줄을 다르게 고침. `pull --rebase` → 충돌 해결 → `add` → `GIT_EDITOR=true git rebase --continue` | 성공, 로컬 커밋이 rebase됨 |

  `tests/plugin-files.test.sh`에 `hook-block-match`를 더한다. 두 파일에서 표지 줄 사이(표지 줄 포함)를 `sed -n '/^# >>> waypoint status-check >>>$/,/^# <<< waypoint status-check <<<$/p'`로 뽑아 `cmp`한다. 블록이 비어 있어도 실패로 본다. 같은 검사에서 `pre-commit`의 둘째 줄이 `# waypoint-hook-version: `로 시작하고 실행 권한이 있는지도 본다.
- [ ] **Step 2: 실패를 확인한다.** Run: `sh tests/pre-commit.test.sh; sh tests/plugin-files.test.sh`. Expected: FAIL.
- [ ] **Step 3: `plugin/githooks/pre-commit`을 쓴다.** 위 순서대로 쓰고 `status-check.sh`의 표지 블록을 그대로 붙여 넣는다. `chmod +x`.
- [ ] **Step 4: 통과를 확인한다.** Run: `sh tests/pre-commit.test.sh && sh tests/plugin-files.test.sh`. Expected: 둘 다 `all passed`.
- [ ] **Step 5: 커밋하고 push한다.** `git add plugin/githooks/pre-commit tests/ && git commit -m "feat(plugin): pre-commit 훅(커밋 위치·STATUS 형식 검사)" && git push`

### Task 3: 세션 시작 요약과 경고

**Files:**
- Modify: `plugin/scripts/session-context.sh`
- Test: `tests/session-context.test.sh`

**Interfaces:**
- Consumes: Task 2 훅의 둘째 줄(`$here/../githooks/pre-commit`).
- Produces: `<waypoint>` 블록 안 `waypoint:start` 안내 줄 뒤, `</waypoint>` 앞에 다음 순서로 붙는 줄들. STATUS가 새 형식이 아니면(설계 5.6절 「구현 제약」) 아무것도 붙이지 않는다.

```
경고: 메인 체크아웃이 기본 브랜치가 아니다(현재 <브랜치>). 요약이 낡았을 수 있다.
경고: .githooks/pre-commit이 낡았다(레포 <n>, 플러그인 <m>). 플러그인의 githooks/pre-commit으로 바꿔라.
현황(<이름>): 진행 중 N · 검토 대기 N · 승인 N · 대기 N · 보류 N · 오너 할 일 N
- <ID> <상태> [<줄기>] <지금> (기다림: <기다림>)
오너 할 일:
- <할 일 줄에서 `- [ ] `를 뗀 나머지>
```

- 첫째 경고는 메인 체크아웃이 기본 브랜치가 아닐 때만 낸다. `<메인>/.git/HEAD`가 `ref: refs/heads/<b>`가 아니면 `<브랜치>`는 `detached HEAD`다. 기본 브랜치는 `<메인>/.git/refs/remotes/origin/HEAD` 파일을 `read`로 읽고, 파일이 없으면 `main`·`master`로 본다.
- 둘째 경고는 `<메인>/.githooks/pre-commit`이 있고, 그 둘째 줄의 번호가 플러그인 훅의 번호보다 작을 때만 낸다. 버전 줄이 없거나 숫자가 아니면 0으로 본다.
- `<이름>`은 메인 체크아웃 경로의 마지막 디렉터리 이름이다. 빈 칸은 생략한다: 줄기가 비면 `[…]`를, 기다림이 비면 `(기다림: …)`를 쓰지 않는다. 활성 줄은 `IN_PROGRESS`, `AI_PROPOSED`, `HUMAN_APPROVED`이고 표의 순서를 따른다. `오너 할 일:` 머리 줄은 할 일이 있을 때만 쓴다.
- 20줄 상한은 개수 줄, 활성 줄, `오너 할 일:`, 할 일 줄을 합해 센다(경고 줄은 세지 않는다). 넘치면 앞 19줄을 쓰고 20번째 줄을 `… 외 <남은 줄 수>개 (STATUS.md 참조)`로 쓴다.
- 레포 밖에서 시작한 세션: 레포마다 기존 두 줄(`메인 체크아웃(<이름>)`, `현황(<이름>): <경로>`) 뒤에 개수 줄만 붙인다. 같은 메인 체크아웃은 한 번만 출력하고, `<이름>`은 발견한 디렉터리가 아니라 메인 체크아웃의 이름이다. 경고는 내지 않는다.

- [ ] **Step 1: 테스트를 더한다.** 새 형식 STATUS(진행 중 1, 검토 대기 1, 승인 1, 대기 2, 보류 1, 머지됨 1, 오너 할 일 2)를 가진 레포 `$T/new`(브랜치 `main`)를 만든다. 아래 경우를 모두 기본 PATH와 `PATH=''`에서 한 번씩 돌린다. 줄은 `grep -qxF`로 줄 전체를 대조한다.
  - `summary`: 개수 줄, 활성 줄 세 개(줄기 있는 줄, 줄기와 기다림이 빈 줄, 기다림 있는 줄), `오너 할 일:`과 두 줄이 정확히 나온다. 경고 줄은 없다.
  - `old-format`: 기존 `$T/repo`(`# STATUS`)에서 `현황(`이나 `경고:`로 시작하는 줄이 없다. 기존 경우 1~8은 그대로 통과한다.
  - `cap`: 활성 줄 25개, 오너 할 일 0개인 STATUS. 요약이 20줄이고 마지막 줄이 `… 외 7개 (STATUS.md 참조)`다.
  - `branch-warn`: `$T/new`에서 `git switch -c feature` 뒤 첫째 경고가 `(현재 feature)`로 나온다. `refs/remotes/origin/HEAD` 파일에 `ref: refs/remotes/origin/develop`을 쓰면 `main`에서도 경고가 나온다.
  - `stale-hook`: `.githooks/pre-commit` 둘째 줄이 `# waypoint-hook-version: 0`이면 `(레포 0, 플러그인 1)` 경고가 나온다. 플러그인과 같은 번호이거나 파일이 없으면 경고가 없다.
  - `parent-dedupe`: `$T/parent2/proj`(새 형식)와 그 worktree `$T/parent2/proj-2-9`를 만들고, worktree의 STATUS 사본을 다른 숫자로 고친다. 출력에 `현황(proj): 진행 중 …` 줄이 정확히 한 번 있고 숫자는 메인 체크아웃 STATUS의 것이다. `proj-2-9`라는 이름은 나오지 않는다.
- [ ] **Step 2: 실패를 확인한다.** Run: `sh tests/session-context.test.sh`. Expected: 새 경우들이 FAIL.
- [ ] **Step 3: `session-context.sh`를 고친다.** 표는 `while IFS='|' read -r …`로 읽고 앞뒤 공백은 매개변수 확장으로 지운다. 외부 명령(`grep`, `sed`, `cat`, `wc` 등)과 `$(…)` 안의 외부 명령을 쓰지 않는다.
- [ ] **Step 4: 통과를 확인한다.** Run: `sh tests/session-context.test.sh`. Expected: `all passed`.
- [ ] **Step 5: 커밋하고 push한다.** `git add plugin/scripts/session-context.sh tests/session-context.test.sh && git commit -m "feat(plugin): 세션 시작 때 활성 스테이지 요약과 경고" && git push`

### Task 4: 템플릿

**Files:**
- Modify: `plugin/templates/STATUS.template.md`, `plugin/templates/stage-template.md`, `plugin/templates/review-stage-template.md`, `plugin/templates/claude-md-block.md`
- Test: `tests/plugin-files.test.sh`

**Interfaces:**
- Consumes: Task 1의 `status-check.sh`.
- Produces: init 스킬(Task 6)과 Task 9가 쓰는 템플릿.

`STATUS.template.md`는 아래 내용 그대로 쓴다.

```markdown
# {Project Name} — waypoint 현황

[PRD](prd.md) · [결정 로그](DECISIONS.md)

## 스테이지

| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |
|---|---|---|---|---|---|---|
| 1-1 | Context Synthesis | PENDING | | | | |
| 1-2 | Domain Model | PENDING | | | | |
| 1-3 | Architecture Decision ⚠️ | PENDING | | | | |
| R-1 | Independent Code Review 🔍 | PENDING | | | | |
| 3-1 | Deployment | PENDING | | | | |
| 3-2 | Monitoring | PENDING | | | | |

## 오너 할 일
```

`stage-template.md`와 `review-stage-template.md`(설계 5.3절):
- frontmatter: `status:`, `updated:`를 지우고 첫 키로 `id: X-Y`(review는 `id: R-1`)를 넣는다. `phase:`, `stage:`는 남긴다.
- 「검토 게이트」의 안내문과 「다음 단계」의 문구에서 frontmatter 상태와 `HUMAN_APPROVED`로 바꾸라는 말을 없앤다. 대신 오너가 답하면 AI가 「승인 결과」에 기록하고 메인 체크아웃 STATUS의 그 줄을 고친다고 쓴다(`waypoint:stage`).
- `### 승인 결과` 아래를 `#### 계획 승인 (YYYY-MM-DD, 결정자)`와 `#### 결과 승인 (YYYY-MM-DD, 결정자)` 두 표로 나누고, 「설계 스테이지는 계획 승인만 쓴다」는 안내를 한 줄 둔다. review 템플릿에도 같은 「승인 결과」를 넣는다.
- 맨 끝에 `## 진행 기록` 절과 `- YYYY-MM-DD 내용` 형식 안내 한 줄을 둔다.

`claude-md-block.md`: STATUS·DECISIONS 줄 끝에 「스테이지 작업은 worktree의 작업 브랜치에서 하고, 메인 체크아웃은 늘 기본 브랜치에 둔다.」를 덧붙인다.

- [ ] **Step 1: 테스트를 더한다.** `tests/plugin-files.test.sh`에 다음을 넣는다.
  - `status-template-valid`: `sed 's/{Project Name}/x/'`한 템플릿과 빈 id 목록 파일로 `status-check.sh`가 0을 낸다.
  - `stage-templates`: 두 템플릿 모두 첫 frontmatter 키가 `id: `로 시작하고, `^status:`와 `^updated:` 줄이 없고, `## 진행 기록`, `#### 계획 승인 (YYYY-MM-DD, 결정자)`, `#### 결과 승인 (YYYY-MM-DD, 결정자)`가 있고, `HUMAN_APPROVED`라는 글자가 없다.
  - `block-worktree`: `claude-md-block.md`에 `메인 체크아웃은 늘 기본 브랜치에 둔다`가 있다.
- [ ] **Step 2: 실패를 확인한다.** Run: `sh tests/plugin-files.test.sh`. Expected: 위 세 검사가 FAIL.
- [ ] **Step 3: 네 템플릿을 고친다.**
- [ ] **Step 4: 통과를 확인한다.** Run: `sh tests/plugin-files.test.sh`. Expected: `all passed`.
- [ ] **Step 5: 커밋하고 push한다.** `git add plugin/templates tests/plugin-files.test.sh && git commit -m "feat(plugin): 새 STATUS·스테이지 템플릿" && git push`

### Task 5: core-rules와 stage 스킬, 대조표

**Files:**
- Modify: `plugin/core-rules.md:5,9,14`, `plugin/skills/stage/SKILL.md`, `docs/superpowers/specs/2026-11-24-framework-split-map.md`
- Test: `tests/plugin-files.test.sh`

**Interfaces:**
- Produces: stage 스킬의 절 이름 `## STATUS 표`, `## 진행 기록`. Task 2 훅의 메시지와 Task 6의 스킬이 이 이름을 가리킨다.

`core-rules.md`의 세 줄은 아래처럼 바꾼다(줄 수는 그대로).
- 5행: `- 앞 스테이지의 계획이 승인되기 전에는 다음 스테이지로 진행하지 않는다 (자세히: \`waypoint:stage\`)`
- 9행: `- 스테이지 상태의 원본은 메인 체크아웃 \`docs/waypoint/STATUS.md\`의 표 한 곳이다. 상태가 바뀌면 그 줄을 고친다 (자세히: \`waypoint:stage\`)`
- 14행: 「…PR과 함께 머지한다.」 바로 뒤, ` (자세히:` 앞에 ` 모든 스테이지는 worktree의 작업 브랜치와 PR로 진행하고, 메인 체크아웃은 기본 브랜치에 둔다.`를 넣는다. 기존 문장은 글자 그대로 둔다(대조표 2-15의 새 문장이 두 곳에 있어야 한다).

stage 스킬:
- `## 상태 생애주기`를 설계 5.2절로 바꾼다: 여섯 값과 보드 열의 표, 설계 스테이지와 코드 스테이지의 흐름, 수정 요청·보류·바로 머지, 「다음 스테이지로 넘어가는 조건」, Build Spec 상태와의 관계, 승인의 기록.
- `## STATUS.md 업데이트 규칙`을 지우고 `## STATUS 표`를 둔다: 설계 5.1절의 파일 구성, 칸 규칙 표, 「지금」 머리말 표, 오너 할 일 규칙, 5.2절의 「누가 언제 고치는가」. 커밋 방법은 `waypoint:git`을 가리키기만 한다.
- `## 승인 결과 기록`에 계획 승인과 결과 승인을 따로 적는다는 것과 설계 스테이지는 하나만 쓴다는 것을 넣는다.
- `## 진행 기록`을 새로 둔다: 설계 5.3절의 frontmatter `id:` 규칙, 「진행 기록」 형식과 커밋 위치, 「시작한 스테이지에는 반드시 스테이지 문서가 하나 있다」.

대조표: `sh tests/check-framework-split.sh FRAMEWORK.md docs/superpowers/specs/2026-11-24-framework-split-map.md plugin/core-rules.md plugin/skills/*/SKILL.md`가 보고하는 줄마다 2절에 `### 2-16`부터 항목을 더한다. 2절 첫머리의 종류 목록에 「**규칙 바뀜(2단계):** STATUS 정리 설계(`2026-11-25-status-cleanup-design.md`)에 따라 규칙 자체를 바꿨다」를 더하고, 각 항목의 「종류」 줄에 설계의 절 번호를 적는다. 바뀐 줄이 없어진 경우에는 `- 원문:`만 적는다.

- [ ] **Step 1: 테스트를 더한다.** `tests/plugin-files.test.sh`에 `has` 검사를 더한다.
  - `stage-states`: stage 스킬에 `| \`MERGED\` | 머지됨 |`, `| \`DEFERRED\` | 보류 |`, `| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |`, `` `계획 검토: ` ``, `` `결과 검토: ` ``, `80자`, `## 진행 기록`, `docs(status)`가 있다.
  - `stage-no-old`: stage 스킬에 `STATUS.md의 테이블을 함께 업데이트`가 없다.
  - `core-rules-new`: core-rules에 `앞 스테이지의 계획이 승인되기 전에는`, `스테이지 상태의 원본은 메인 체크아웃`, `메인 체크아웃은 기본 브랜치에 둔다`가 있고, `HUMAN_APPROVED\` 없이는`이 없으며, 줄 수가 19 이하다.
- [ ] **Step 2: 실패를 확인한다.** Run: `sh tests/plugin-files.test.sh`. Expected: 위 검사가 FAIL.
- [ ] **Step 3: core-rules와 stage 스킬을 고친다.**
- [ ] **Step 4: 대조표를 맞춘다.** Run: 위 검사기 명령. Expected: 보고되는 줄을 대조표에 적은 뒤 `OK: <n> lines`.
- [ ] **Step 5: 통과를 확인한다.** Run: `sh tests/plugin-files.test.sh && sh tests/check-framework-split.test.sh`. Expected: 둘 다 `all passed`.
- [ ] **Step 6: 커밋하고 push한다.** `git add plugin/core-rules.md plugin/skills/stage docs/superpowers/specs/2026-11-24-framework-split-map.md tests/plugin-files.test.sh && git commit -m "feat(plugin): 상태 생애주기와 STATUS 표 규칙(core-rules·stage)" && git push`

### Task 6: start·git·init 스킬

**Files:**
- Modify: `plugin/skills/start/SKILL.md`, `plugin/skills/git/SKILL.md`, `plugin/skills/init/SKILL.md`, 필요하면 대조표
- Test: `tests/plugin-files.test.sh`

**Interfaces:**
- Consumes: Task 5의 절 이름(`waypoint:stage`의 `## STATUS 표`), Task 2의 훅 경로와 변수, Task 4의 템플릿.

- **start:** 「세션 시작 프로토콜」을 설계 5.7절의 여섯 단계로 바꾼다. 끝의 「`AI Proposal` 작성 전에 `waypoint:stage`를 호출한다 …」 단락은 남기되 단계 번호를 새 절차에 맞춘다. frontmatter `description`의 「STATUS.md를 읽고 다음 스테이지를 찾는 절차」를 「세션 시작 요약을 확인하고 이어 갈 카드를 고르는 절차」로 바꾼다.
- **git:** 설계 5.4절을 `### 스테이지 브랜치와 PR` 하위 절로 넣는다(1~7번, PR이 여러 개인 스테이지, 옛 흐름에서 시작한 스테이지, 앞 스테이지가 머지되지 않았을 때, 작업 위치). `### STATUS 커밋`에는 `docs(status): <ID> <새 상태>` 형식을 둔다. `### pre-commit 검사`에는 두 검사가 무엇을 막는지, `WAYPOINT_ALLOW_BRANCH_STATUS=1`은 절차 M의 변환 커밋에만 쓴다는 것, 그 밖의 예외는 오너가 판단해 `--no-verify`로 넘긴다는 것, 낡은 훅 경고를 받으면 `${CLAUDE_PLUGIN_ROOT}/githooks/pre-commit`을 Read로 읽어 `.githooks/pre-commit`에 Write하고 `chmod +x`한다는 것을 둔다. 「문서 커밋 흐름」 0번의 「기본 브랜치(main 또는 master)」는 Global Constraints의 기본 브랜치 규칙과 맞춘다.
- **init:** 2번에서 STATUS 템플릿의 「날짜를 채운다」를 지운다. 3번에 `${CLAUDE_PLUGIN_ROOT}/githooks/pre-commit` → `.githooks/pre-commit` 복사와 `chmod +x`를 더한다(이미 있으면 기존 훅을 지우지 않고 끝에서 waypoint 검사를 부르도록 합친다, 설계 5.5절). 마지막 문장의 「첫 스테이지(1-1)를 시작한다」를 「`waypoint:start`로 시작할 스테이지를 오너와 정한다」로 바꾼다. frontmatter `description`의 「commit-msg 훅」을 「commit-msg·pre-commit 훅」으로 바꾼다.

- [ ] **Step 1: 테스트를 더한다.** `tests/plugin-files.test.sh`에 `has` 검사를 더한다.
  - `start-new`: start에 `` `gh pr view` ``가 있고 `PENDING\` 상태인 가장 앞 스테이지를 찾는다`가 없다.
  - `git-new`: git에 `### 스테이지 브랜치와 PR`, `worktree add`, `git worktree remove`, `[작업 중]`, `` `docs(status): <ID> <새 상태>` ``, `WAYPOINT_ALLOW_BRANCH_STATUS=1`이 있다.
  - `init-new`: init에 `githooks/pre-commit`이 있고 `첫 스테이지(1-1)를 시작한다`가 없다.
- [ ] **Step 2: 실패를 확인한다.** Run: `sh tests/plugin-files.test.sh`. Expected: 위 검사가 FAIL.
- [ ] **Step 3: 세 스킬을 고친다.** 같은 규칙 문장을 두 스킬에 두지 않는다(1단계 설계 5.2절). 칸 규칙은 stage에만, 브랜치·PR 흐름은 git에만 둔다.
- [ ] **Step 4: 통과를 확인한다.** Run: `sh tests/plugin-files.test.sh && sh tests/check-framework-split.test.sh`와 Task 5의 검사기 명령. Expected: `all passed`, `OK: <n> lines`. 검사기가 줄을 보고하면 Task 5와 같은 방법으로 대조표에 더한다.
- [ ] **Step 5: 커밋하고 push한다.** `git add plugin/skills docs/superpowers/specs/2026-11-24-framework-split-map.md tests/plugin-files.test.sh && git commit -m "feat(plugin): start·git·init 스킬을 새 STATUS 흐름으로" && git push`

### Task 7: 절차 M 고치기

**Files:**
- Modify: `docs/superpowers/plans/2026-11-24-plugin-split.md`(「절차 M」 절과 Task 11)

설계 5.8절과 5.9절 마지막 줄을 반영한다.
- **M0:** `git -C $REPO branch --show-current`가 `$BASE`인지 확인하는 줄을 더한다. 아니면 그 브랜치를 맡은 세션이나 오너가 먼저 worktree로 옮긴다.
- **M6:** 2번에 「`.githooks/pre-commit`이 없으면 `plugin/githooks/pre-commit`을 복사하고 `chmod +x`한다. 있으면 기존 훅 끝에서 waypoint 검사를 부르도록 합친다」를 더한다. 커밋 명령은 그대로 둔다(`.githooks`를 이미 add한다).
- **M6a(새로, M6과 M7 사이):** 「STATUS 변환」. 설계 5.8절 「변환 절차」 1~8번을 가리키고, 아래 명령을 둔다.

  ```bash
  OLD=$(git rev-parse HEAD)                     # M5까지 반영된 커밋
  { printf '%s STATUS 정리 때 옮긴 기록이다. 이후로는 쓰지 않는다.\n\n' "$(date +%F)"; git show "$OLD:docs/waypoint/STATUS.md"; } > docs/waypoint/HISTORY.md
  # 2~6번: 새 표 작성, 스테이지 문서 frontmatter·진행 기록, 오너 확인 목록 → 오너 답 반영
  tail -n +3 docs/waypoint/HISTORY.md | diff - <(git show "$OLD:docs/waypoint/STATUS.md")   # 출력 없음
  git add docs/waypoint && WAYPOINT_ALLOW_BRANCH_STATUS=1 git commit -m "docs(waypoint): STATUS를 새 형식으로 변환(옛 내용은 HISTORY.md)"
  ```

- **M8:** 첫 grep의 예외에 `':!docs/waypoint/HISTORY.md'`를 더한다.
- **M9의 재확인:** 다시 떼어 내면 M6a도 다시 한다는 줄을 더한다.
- **Task 11(app-factory):** 「M9에서 `gh pr create --draft`로 연다. 거절되면 일반 PR로 열고, 결과를 설계 10절의 초안 PR 항목 답으로 오너에게 알린다」를 더한다.

- [ ] **Step 1: 위 다섯 곳을 고친다.**
- [ ] **Step 2: 확인한다.** Run: `grep -n 'M6a\|HISTORY.md\|pre-commit\|--draft' docs/superpowers/plans/2026-11-24-plugin-split.md`. Expected: M0, M6, M6a, M8, M9, Task 11에 해당하는 줄이 보인다.
- [ ] **Step 3: 커밋하고 push한다.** `git add docs/superpowers/plans/2026-11-24-plugin-split.md && git commit -m "docs(plan): 절차 M에 STATUS 변환 단계(M6a)와 pre-commit 복사" && git push`

### Task 8: 전체 검증, 독립 리뷰, PR

- [ ] **Step 1: 모든 테스트를 돌린다.** Run: `for t in tests/*.test.sh; do sh "$t" || echo "FAILED: $t"; done`. Expected: 모두 `all passed`, `FAILED` 줄 없음.
- [ ] **Step 2: 실제 레포에서 출력이 변하지 않음을 확인한다.** 머지 전에는 shadow의 STATUS가 옛 형식이므로 출력이 지금과 같아야 한다.

  ```bash
  M=/Users/ywyeom/private/waypoint/plugin/scripts/session-context.sh
  W=$PWD/plugin/scripts/session-context.sh
  for d in /Users/ywyeom/private/shadow /Users/ywyeom/private /Users/ywyeom/private/waypoint; do
    diff <(CLAUDE_PROJECT_DIR=$d sh $M) <(CLAUDE_PROJECT_DIR=$d sh $W) && echo "same: $d"
  done
  ```
  Expected: `same:` 세 줄.
- [ ] **Step 3: 변환 뒤 모습을 미리 본다.** shadow의 STATUS를 새 형식으로 바꾼 사본을 scratchpad의 임시 레포에 만들고 `CLAUDE_PROJECT_DIR`로 훅을 실행해 요약을 눈으로 확인한다. 실제 shadow는 건드리지 않는다.
- [ ] **Step 4: 독립 리뷰.** 브랜치 전체(`git diff origin/master...HEAD`)를 새 서브에이전트에 맡긴다. 설계 문서, 이 계획, Review Focus를 함께 준다. 지적마다 검증하고, 받아들인 것은 고쳐 테스트를 더한 뒤 커밋한다.
- [ ] **Step 5: PR을 연다.**

  ```bash
  git fetch -q && git rebase origin/master && git push --force-with-lease
  gh pr create -R bingoring/waypoint --base master --head feat/status-cleanup \
    --title "feat(plugin): STATUS 정리(2단계) — 새 STATUS 형식, pre-commit 검사, 세션 시작 요약" --body-file <본문 파일>
  ```

  본문에 넣을 것: 바뀐 파일과 이유(설계 5.9절 표), 테스트 결과, 「머지하는 순간 모든 waypoint 레포에 적용되므로 머지 직후 Task 9를 한다」, 4단계 설계와 다른 점(내용 검사 모드를 지금 만듦). 트레일러와 AI 서명은 넣지 않는다.
- [ ] **Step 6: 오너에게 PR 링크를 알리고 머지를 기다린다.** 머지는 오너가 한다.

---

## Part B — 머지 직후 실행

### Task 9: 이미 이전된 레포의 STATUS 변환

**대상:** 머지 시점에 `docs/waypoint/STATUS.md`가 있는 레포 전부. 실행할 때 `ls /Users/ywyeom/private/*/docs/waypoint/STATUS.md`로 다시 확인한다(2026-11-26 기준 shadow 하나). 절차 M을 진행 중인 레포는 M6a에서 변환하므로 여기서 하지 않는다.

레포 `$REPO`마다:

- [ ] **Step 1: 사전 조건을 확인한다.** 하나라도 어긋나면 멈추고 오너에게 알린다.
  - `git -C $REPO branch --show-current`가 기본 브랜치이고 `git -C $REPO status --porcelain`이 비어 있다.
  - `lsof -a -d cwd -c claude -Fn | grep '^n'`에 `$REPO`나 그 worktree가 없다(있으면 오너에게 그 세션을 멈춰 달라고 한다).
  - `git -C $REPO pull --rebase`.
- [ ] **Step 2: 훅과 CLAUDE.md 블록을 갱신한다.** `plugin/githooks/pre-commit`(머지된 master의 것) → `$REPO/.githooks/pre-commit`, `chmod +x`. `git -C $REPO config core.hooksPath`가 `.githooks`인지 확인한다. CLAUDE.md의 waypoint 블록을 `plugin/templates/claude-md-block.md`대로 고친다. `git add .githooks CLAUDE.md && git commit -m "chore(waypoint): pre-commit 훅과 CLAUDE.md 블록 갱신" && git push`
- [ ] **Step 3: STATUS를 변환한다.** 설계 5.8절 「변환 절차」 1~7번. HISTORY.md는 Task 7의 M6a 명령과 같은 방법으로 만들고 `diff`로 확인한다. 상태 값 대응과 「지금」 머리말은 설계 5.8절 3번 표를 따른다. shadow의 경우 1-1이 `AI_PROPOSED`이므로 스테이지 문서 frontmatter의 `status:`와 같은지, 설계 스테이지의 계획 검토인지(`계획 검토: `)를 문서의 승인 결과로 판단한다.
- [ ] **Step 4: 오너 확인 목록을 보여 주고 답을 받는다.** 설계 5.8절 6번의 항목 가운데 해당하는 것만. 없으면 「확인할 항목 없음」이라고 알리고 진행한다.
- [ ] **Step 5: 커밋하고 push한다.** `git add docs/waypoint && git commit -m "docs(waypoint): STATUS를 새 형식으로 변환(옛 내용은 HISTORY.md)" && git push`. Expected: pre-commit의 검사 1과 검사 2가 통과한다(커밋이 거부되지 않는다).
- [ ] **Step 6: 세션 시작 요약을 확인한다.** Run: `CLAUDE_PROJECT_DIR=$REPO sh /Users/ywyeom/private/waypoint/plugin/scripts/session-context.sh`. Expected: `현황(<이름>): …` 줄과 활성 줄. 설치된 플러그인으로 `$REPO`에서 새 세션을 열어 같은 요약이 주입되는지 본다(플러그인 캐시가 머지된 커밋을 따라오지 않았으면 `claude plugin marketplace update waypoint`).
- [ ] **Step 7: 오너에게 2단계 완료를 알린다.** 다음은 3단계 구현 계획이다.
