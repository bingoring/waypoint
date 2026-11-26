# waypoint 보드 동기화(4단계) — 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 레포마다 GitHub Project 보드를 두고, STATUS를 기본 브랜치로 push하면 pre-push 훅이 스테이지 이슈와 보드 카드를 STATUS에 맞추게 한다. 작업 세션은 세부 진행을 스테이지 이슈 본문에 쓴다.

**Architecture:** `plugin/scripts/board-sync.sh`가 STATUS를 읽어 카드마다 원하는 값을 계산하고, `gh`로 Project와 이슈를 읽어 다른 것만 고친다. `plugin/githooks/pre-push`가 기본 브랜치로 가는 push에서 STATUS가 바뀌었으면 동기화를 띄운다. 둘 다 레포 `.githooks/`에 사본으로 들어가고, 2단계의 검사 블록을 board-sync.sh에도 그대로 넣는다. `board-setup.sh`가 템플릿 Project와 레포별 Project를 만든다.

**Tech Stack:** POSIX sh, `gh` 2.91.0(`gh project`, `gh issue`, `gh api graphql`), `jq`, git 훅

**Spec:** `docs/superpowers/specs/2026-11-25-board-sync-design.md`(이하 「설계」). 관련: 2단계 설계(STATUS 형식, `status-check`), 3단계 설계와 지금의 `plugin/skills/{worker,mediator}`(5.11절이 바꿀 곳).

**실행 단위:**
- **Part A(Task 1):** 비공개 시험 레포와 시험 Project로 설계 5.14절의 확인 다섯 가지. 시험 레포와 Project를 만들기 전에 오너의 승낙을 받는다.
- **Part B(Task 2~9):** worktree에서 스크립트·훅·스킬을 만들고 PR을 연다.
- **Part C(Task 10):** 머지 뒤 템플릿 Project를 만들고, tokens-are-running-out에 적용해 첫 동기화를 한다.
- **4단계의 끝:** PR 머지, tokens-are-running-out 보드의 첫 동기화 성공, 오너가 보드에서 카드와 세부 진행을 확인.

## 설계와 다른 점 (오너 확인용)

1. **첫 적용 레포:** 설계 5.10·5.14절은 shadow부터 적용한다. 오너가 2026-11-26에 「shadow는 지금 개발하지 않는다」고 했고, tokens-are-running-out이 이미 새 형식으로 이전되어 3-1·3-2가 진행 중이다. 그래서 tokens-are-running-out에 먼저 적용한다. tokens는 public 레포라 3-1·3-2의 스테이지 이슈가 공개로 생긴다(설계 4.1절이 받아들인 조건). shadow는 오너가 원할 때 같은 절차로 적용한다.
2. **보기와 자동화의 API(2026-11-26, GitHub GraphQL 스키마 조회로 확인):** `createProjectV2View`·`updateProjectV2View`가 있지만 설정할 수 있는 것은 보이는 필드(`visibleFieldIds`)뿐이고, 열·가로 묶음은 정할 수 없다. 자동화는 `deleteProjectV2Workflow`(삭제)만 있고 켜거나 만드는 API는 없다. 그래서 `board-setup.sh`가 템플릿의 기본 자동화 두 개를 API로 지우고, 보드 보기의 가로 묶음(줄기)과 14일 보관 자동화만 화면에서 설정한다. 설계 10절의 「보기를 API로 만들 수 있는지」는 「만들 수는 있지만 가로 묶음은 화면에서」로 답이 바뀐다.
3. **CLAUDE.md 블록 템플릿:** 설계 5.13절은 `claude-md-block.md`에 `보드:` 줄을 둔다. 주소는 레포마다 다르므로 템플릿에는 넣지 않고, `board-setup.sh`가 레포의 CLAUDE.md에 `- 보드: <주소>` 줄을 더한다. 템플릿에는 이 줄을 설명하는 문장만 둔다.

## Global Constraints

- **작업 위치:** Part B는 worktree `/Users/ywyeom/private/waypoint/.claude/worktrees/board-sync`, 브랜치 `feat/board-sync`(`origin/master`에서 시작).
- **커밋:** conventional commit 한 줄. 트레일러와 AI 서명은 커밋과 PR 본문에 넣지 않는다. 커밋 직후 push. PR 전 `git rebase origin/master`.
- **손대지 않는 파일:** `FRAMEWORK.md`, `_templates/`.
- **스크립트:** `pre-push`, `board-sync.sh`, `board-setup.sh`는 POSIX sh. 외부 명령(`git`, `gh`, `jq`, `awk`, `sed`, `grep`, `mktemp`, `date`, `kill`)을 쓸 수 있다. `session-context.sh`는 지금처럼 셸 내장 명령만 쓴다.
- **훅 버전 줄:** `plugin/githooks/pre-push`와 `plugin/scripts/board-sync.sh`의 둘째 줄은 `# waypoint-hook-version: 1`이다. `pre-commit`은 1 그대로 둔다.
- **검사 블록:** `board-sync.sh`에 `status-check.sh`의 표지 블록(`# >>> waypoint status-check >>>` ~ `# <<< waypoint status-check <<<`)을 글자 그대로 넣고, id 목록 없이(내용 검사만) 부른다. `hook-block-match` 테스트가 세 파일을 대조한다.
- **상태 파일과 로그:** `$(git rev-parse --git-common-dir)/waypoint/`(메인 체크아웃의 `.git/waypoint/`) 아래에 둔다.
  - `board-sync.status`: 한 줄. 성공은 `ok <ISO 시각>`, 실패는 `fail <ISO 시각> <단계>: <이유>`.
  - `board-sync.log`: 실행마다 덧붙이고, 500줄을 넘으면 뒤 500줄만 남긴다.
  - 잠금 `board-sync.lock/`(안에 `pid`, `started`), 재실행 표시 `board-sync.rerun`.
- **필드 이름과 값(설계 5.2절, 정확히):** `Status`(`대기`, `진행 중`, `검토 대기`, `승인`, `머지됨`, `보류`), `줄기`, `지금`, `기다림`, `단계`(`1`, `2`, `R`, `3`), `ID`.
- **상태 대응:** `PENDING`→`대기`, `IN_PROGRESS`→`진행 중`, `AI_PROPOSED`→`검토 대기`, `HUMAN_APPROVED`→`승인`, `MERGED`→`머지됨`, `DEFERRED`→`보류`.
- **이슈:** 제목 `[<ID>] <스테이지 이름>`, 라벨 `waypoint`. `MERGED`면 닫고 그 밖은 연다. 본문은 만들 때만 넣는다.
- **`보드:` 줄:** CLAUDE.md의 `- 보드: <주소> [<주소> ...]`. 주소는 `https://github.com/users/<소유자>/projects/<번호>` 또는 `https://github.com/orgs/<조직>/projects/<번호>`. 형식이 맞지 않는 주소는 건너뛰고 경고한다.
- **push를 막지 않는다:** `pre-push`는 늘 0으로 끝난다.
- **사용자에게 보이는 문구는 한국어.**

## Review Focus

1. **AI 세션의 `git push`가 동기화를 기다리는 경우.** 기대: push는 동기화가 끝나기 전에 돌아온다(물러선 경우에는 몇 초). Task 5의 `push-returns` 테스트가 느린 가짜 동기화로 잰다.
2. **이슈가 두 개 생기는 경우.** 이슈를 만든 뒤 Project에 넣기 전에 실패했거나, 동기화가 겹쳐 실행되었을 때. 기대: 다음 실행이 라벨과 제목으로 기존 이슈를 찾고, 겹친 실행은 잠금에서 재실행 표시만 남긴다. Task 4의 `find-before-create`, Task 5의 `lock-busy` 테스트.
3. **보드를 쓰지 않는 레포, `gh`·`jq`가 없는 환경.** 기대: `보드:` 줄이 없으면 조용히 끝나고, 도구가 없으면 실패로 기록하되 push는 막지 않는다. Task 4의 `no-board`, `no-gh` 테스트.
4. **작업 세션이 쓴 이슈 본문.** 기대: 동기화는 이미 있는 이슈의 본문을 한 번도 고치지 않는다. Task 4의 `body-untouched` 테스트가 가짜 `gh` 호출 기록에서 `--body`를 찾는다.
5. **동기화하지 않아야 하는 push.** 기능 브랜치 push, 브랜치 삭제, STATUS가 바뀌지 않은 push. 기대: 동기화를 띄우지 않는다. 원격 커밋을 로컬에서 찾을 수 없는 강제 push와 새 기본 브랜치 push는 동기화한다. Task 5의 판정 테스트.

---

## 파일 구조

| 파일 | 할 일 |
|---|---|
| `plugin/scripts/board-sync.sh` | 새 파일. 동기화의 원본(설계 5.6~5.8절). 레포에는 `.githooks/board-sync.sh` 사본. |
| `plugin/githooks/pre-push` | 새 파일. 대상 판정, 직전 실패 알림, 동기화 띄우기. |
| `plugin/scripts/board-setup.sh` | 새 파일. `template`(템플릿 Project)과 `repo`(레포별 적용) 두 명령. |
| `plugin/scripts/session-context.sh` | 동기화 실패 줄, 낡은 사본 경고에 `pre-push`·`board-sync.sh`. |
| `plugin/skills/{git,init,stage,worker,mediator}/SKILL.md`, `plugin/templates/{worker-brief-template,claude-md-block}.md` | 설계 5.11·5.13절. |
| `tests/board-sync.test.sh`, `tests/pre-push.test.sh`, `tests/board-setup.test.sh` | 새 파일. 가짜 `gh`(`tests/fake-gh/gh`)와 Task 1에서 받은 JSON(`tests/fixtures/board/`)을 쓴다. |
| `tests/plugin-files.test.sh`, `tests/session-context.test.sh` | 블록 일치, 문장 검사, 실패 줄. |
| `docs/superpowers/plans/2026-11-24-plugin-split.md` | 절차 M에 보드 적용 단계. |
| `docs/superpowers/specs/2026-11-25-board-sync-design.md` | 10절에 Task 1 결과. |

---

## Part A — 시험 레포로 확인

### Task 1: 설계 5.14절의 확인 다섯 가지

**목적:** 스크립트를 쓰기 전에 앱과 GitHub의 실제 동작을 확인하고, 테스트에 쓸 `gh` JSON을 받아 둔다.

- [ ] **Step 1: 오너 승낙.** 비공개 레포 `bingoring/waypoint-board-test`와 사용자 Project 「waypoint 보드 시험」을 만들어도 되는지 묻는다. 승낙을 받은 턴에서만 Step 2를 한다.
- [ ] **Step 2: 시험 환경.** `gh repo create bingoring/waypoint-board-test --private --add-readme`, `gh project create --owner @me --title "waypoint 보드 시험"`, `gh project link <번호> --owner @me --repo bingoring/waypoint-board-test`. 시험 레포를 scratchpad에 클론하고, 2단계 형식의 짧은 STATUS(줄 세 개, 줄기 두 가지)를 커밋해 둔다.
- [ ] **Step 3: JSON 받기.** 시험 이슈 두 개를 만들어 Project에 넣고 필드를 채운 뒤 다음 출력을 `$SP/board-fixtures/`에 저장한다: `gh project field-list --format json`, `gh project item-list --format json --limit 200`, `gh issue list --label waypoint --state all --json number,title,state,labels`, `gh project view --format json`. Task 2~4의 픽스처가 된다.
- [ ] **Step 4: 확인 3·4(단일 선택 선택지).** GraphQL `updateProjectV2Field`에 `singleSelectOptions`를 넘겨 (a) 「줄기」에 기존 선택지의 `id`를 유지한 채 새 선택지를 더하고, (b) 기본 Status의 선택지를 `대기`~`보류` 여섯 개로 바꾼다. 각각 전후로 카드의 값을 읽어 유지되는지 본다. `id`를 넘기지 않을 때도 한 번 시험한다.
- [ ] **Step 5: 확인 5(복사).** 시험 Project의 기본 자동화를 `deleteProjectV2Workflow`로 지우고, 보기 하나를 `createProjectV2View`로 만든 뒤 `gh project copy`로 복사한다. 복사본의 `workflows { name enabled }`와 `views { name layout groupByFields verticalGroupByFields visibleFields }`를 GraphQL로 읽어 원본과 비교한다.
- [ ] **Step 6: 확인 2(보관 자동화).** 14일 보관 조건은 화면에서만 볼 수 있다. 오너에게 시험 Project의 Workflows 화면에서 「Auto-archive items」의 조건(`is:closed updated:<@today-14d` 같은 필터)을 확인해 달라고 하거나, 오너가 허락하면 앱의 브라우저로 확인한다.
- [ ] **Step 7: 확인 1(백그라운드 실행).** 시험 레포 클론에 탐지용 `pre-push`를 넣는다: `nohup sh probe.sh </dev/null >/dev/null 2>&1 &` 뒤 바로 `exit 0`. `probe.sh`는 `command -v gh jq`, `gh api user --jq .login`, `gh project item-list <번호> --owner @me --format json | jq '.items | length'`, 시작·끝 시각을 로그에 적는다. **이 세션의 Bash에서** `git push`를 실행하고 push가 돌아온 시각과 로그를 비교한다. 오너 터미널에서도 한 번 push해 달라고 부탁한다(선택).
- [ ] **Step 8: 결과 기록.** 설계 10절의 해당 항목 끝에 「확인(2026-11-26): …」를 덧붙이고, 실패한 항목의 물러서기(설계 5.14절)를 정한다. 메인 체크아웃 master에 커밋·push(`docs(framework): 4단계 GitHub Projects 동작 확인 결과`). 시험 레포와 Project는 Part C까지 두고, 지울지는 끝에 오너에게 묻는다.

---

## Part B — 구현

각 Task는 2·3단계처럼 테스트를 먼저 쓰고 실패를 본 뒤 구현한다. 가짜 `gh`(`tests/fake-gh/gh`)는 호출을 한 줄씩 `$FAKE_GH_LOG`에 적고, `$FAKE_GH_DIR`의 픽스처로 답한다. 실패를 주입할 때는 `$FAKE_GH_FAIL`에 실패시킬 하위 명령(예: `project item-add`)을 넣는다.

### Task 2: 가짜 gh와 픽스처

**Files:** Create `tests/fake-gh/gh`, `tests/fixtures/board/*.json`(Task 1 Step 3의 출력을 개인 정보 없이 줄여서).

**Interfaces:**
- Produces: `PATH="$ROOT/tests/fake-gh:$PATH"`로 쓰는 `gh`. 지원하는 하위 명령: `project field-list|item-list|view|item-add|item-edit|field-create`, `issue list|create|edit|close|reopen`, `label list|create`, `api graphql`. 만드는 명령은 새 번호나 ID를 차례로 돌려주고 상태를 `$FAKE_GH_DIR/state/`에 남겨 다음 `list`에 반영한다.

- [ ] **Step 1:** 가짜 `gh`의 자기 시험(`tests/board-sync.test.sh` 앞부분): 호출 기록, 픽스처 응답, 만든 이슈가 다음 `issue list`에 나오는지, 실패 주입.
- [ ] **Step 2:** 구현하고 통과시킨다. **커밋:** `test(plugin): 보드 동기화용 가짜 gh와 픽스처`

### Task 3: STATUS에서 원하는 카드 계산

**Files:** Create `plugin/scripts/board-sync.sh`(이 Task에서는 함수만). Test: `tests/board-sync.test.sh`.

**Interfaces:**
- Produces:
  - `wp_desired_cards <STATUS 파일>`: 줄마다 탭으로 나눈 `ID 제목 Status선택지 줄기 지금 기다림 단계 open|closed`. 제목은 `[<ID>] <스테이지 이름>`.
  - `wp_board_urls <CLAUDE.md 파일>`: `- 보드:` 줄의 주소를 한 줄에 하나씩. 형식이 틀린 주소는 stderr에 경고.
  - 표지 블록 `wp_status_check`(2단계 원본 그대로).
- 「기다림」이 `오너 할 일`이면 「오너 할 일」 절에서 `(막음: …)`에 그 ID가 든 줄의 내용(`(막음: …)`을 뗀 할 일 글)을 ` · `로 이어 `오너 할 일: <내용>`으로 쓴다(설계 5.2절). 해당 줄이 없으면 `오너 할 일` 그대로.

- [ ] **Step 1: 테스트.** 경우: 여섯 상태의 대응, 줄기·지금이 빈 줄, `⚠️`·`🔍`가 든 이름, 기다림 확장(한 줄, 두 줄, 해당 줄 없음), 단계(`R-1`→`R`), MERGED만 `closed`. `보드:` 줄 0개·1개·2개·틀린 주소.
- [ ] **Step 2~4:** 실패 확인, 구현, 통과. **커밋:** `feat(plugin): 보드 동기화 — STATUS에서 카드 값 계산`

### Task 4: Project와 이슈 맞추기

**Files:** Modify `plugin/scripts/board-sync.sh`. Test: `tests/board-sync.test.sh`.

**Interfaces:**
- Consumes: Task 3의 함수, Task 2의 가짜 `gh`.
- Produces: `board-sync.sh [--commit <sha>]`의 본체. `--commit`이 없으면 기본 브랜치 끝 커밋을 쓴다. STATUS와 `보드:` 줄은 모두 그 커밋에서 읽는다(`git show <sha>:docs/waypoint/STATUS.md`, `git show <sha>:CLAUDE.md`). 단계 이름(상태 파일의 `<단계>`): `check`, `tools`, `board`, `fields`, `items`, `issue`, `field-edit`.

설계 5.7절 순서대로: 도구 확인(`gh`, `jq`) → 내용 검사 → `보드:` 줄(없으면 `ok`로 끝) → Project마다 필드·선택지·항목 읽기 → 라벨 확인 → 「줄기」 선택지 맞추기(Task 1 결과에 따라 기존 값 다시 적기 포함) → 줄마다 비교와 수정 → STATUS에 없는 카드 경고 → 상태 파일과 로그. 이슈 본문 틀은 다음 내용 그대로다.

```
이 이슈는 waypoint STATUS에서 만들어졌다. 상태는 STATUS가 정하고, 이 본문은 작업 세션이 세부 진행을 적는 곳이다.

## 체크리스트

## 최근 진행
```

- [ ] **Step 1: 테스트(가짜 gh).**

  | 경우 | 기대 |
  |---|---|
  | `create-new` | 카드도 이슈도 없는 `IN_PROGRESS` 줄 → `issue create`(제목·라벨·본문 틀), `project item-add`, 필드 여섯 개 `item-edit` |
  | `find-before-create` | 이슈는 있는데 카드가 없음 → `issue create` 없이 `item-add` |
  | `merged-no-card` | 카드 없는 `MERGED` 줄 → 아무 호출 없음 |
  | `diff-only` | 카드의 「지금」만 다름 → `item-edit` 한 번 |
  | `close-merged` / `reopen` | `MERGED`면 `issue close`, 손으로 닫힌 비 MERGED면 `issue reopen` |
  | `title-change` | 스테이지 이름이 바뀜 → `issue edit --title`만 |
  | `body-untouched` | 어떤 경우에도 이미 있는 이슈에 `--body`/`--body-file` 호출 없음 |
  | `unknown-card` | STATUS에 없는 ID의 카드 → 경고 로그, 삭제 호출 없음 |
  | `new-stem` | 처음 보는 줄기 → 선택지 추가 뒤 기존 카드의 줄기 값 유지(또는 다시 적기) |
  | `two-boards` | `보드:` 주소 둘 → 이슈 하나, Project마다 카드 |
  | `no-board` | `보드:` 줄 없음 → `gh` 호출 없이 `ok` |
  | `no-gh` / `no-jq` | PATH에 없음 → `fail … tools: …`, 종료 0 |
  | `check-fail` | 내용 검사 실패 STATUS → `fail … check: …`, `gh` 호출 없음 |
  | `gh-error` | `item-add` 실패 주입 → `fail … items: …`, 다음 실행은 `find-before-create`대로 |

- [ ] **Step 2~4:** 실패 확인, 구현, 통과. **커밋:** `feat(plugin): 보드 동기화 — Project와 스테이지 이슈 맞추기`

### Task 5: 잠금, 재실행, pre-push

**Files:** Modify `plugin/scripts/board-sync.sh`(잠금). Create `plugin/githooks/pre-push`. Test: `tests/pre-push.test.sh`, `tests/board-sync.test.sh`.

**Interfaces:**
- Produces: `pre-push`(git이 stdin으로 `<로컬 ref> <로컬 sha> <원격 ref> <원격 sha>` 줄을 준다). 기본 브랜치 판정은 pre-commit과 같다(`origin/HEAD`, 없으면 `main`·`master`).
- 띄우는 방식은 Task 1 Step 7 결과로 정한다. 백그라운드가 되면 `nohup sh .githooks/board-sync.sh --commit <sha> </dev/null >/dev/null 2>&1 &`, 안 되면 같은 프로세스에서 실행한다(설계 5.9절).

- [ ] **Step 1: 테스트.**

  | 경우 | 기대 |
  |---|---|
  | `feature-branch` | 원격 ref가 기능 브랜치 → 띄우지 않음 |
  | `delete` | 로컬 sha가 0 → 띄우지 않음 |
  | `no-status-change` | STATUS가 같은 범위 → 띄우지 않음 |
  | `status-change` | 기본 브랜치, STATUS 바뀜 → `--commit <로컬 sha>`로 띄움 |
  | `new-default-branch` | 원격 sha가 0 → 띄움 |
  | `unknown-remote` | 원격 sha가 로컬에 없음(강제 push) → 띄움 |
  | `prev-failure` | 상태 파일이 `fail` → stderr에 `waypoint: 직전 보드 동기화 실패(<시각>): <이유>`, 종료 0 |
  | `push-returns` | 10초 걸리는 가짜 동기화로 실제 `git push`(로컬 bare 원격) → 2초 안에 돌아옴(백그라운드 방식일 때) |
  | `lock-busy` | 잠금이 살아 있는 PID → 재실행 표시만 남기고 끝; 잠금을 쥔 실행이 끝날 때 기본 브랜치 끝으로 한 번 더 |
  | `lock-stale` | 죽은 PID의 잠금 → 지우고 실행 |
  | `lock-old` | 살아 있는 PID, 10분 넘음 → `fail … lock: 잠금이 오래 풀리지 않음` |

- [ ] **Step 2~4:** 실패 확인, 구현, 통과. `tests/plugin-files.test.sh`의 `hook-block-match`에 board-sync.sh를 더하고, `pre-push`와 board-sync.sh의 버전 줄과 실행 권한을 검사한다. **커밋:** `feat(plugin): pre-push 보드 동기화와 잠금`

### Task 6: board-setup.sh

**Files:** Create `plugin/scripts/board-setup.sh`. Test: `tests/board-setup.test.sh`.

**Interfaces:**
- `board-setup.sh template <소유자>`: 「waypoint 보드 템플릿」 Project를 만들고, Status 선택지를 여섯 개로 바꾸고(Task 1 Step 4 결과대로), 필드 다섯 개(`줄기`, `지금`, `기다림`, `단계`, `ID`)를 만들고, 기본 자동화를 지우고, 표 보기와 보드 보기를 만든다(보이는 필드: 지금, 기다림). 끝에 화면에서 할 일(보드 보기의 가로 묶음을 줄기로, 14일 보관 자동화)을 출력한다.
- `board-setup.sh repo <레포 경로> <템플릿 주소>`: 템플릿을 `<레포> 보드`로 복사(비공개), 레포에 연결, CLAUDE.md waypoint 블록 끝에 `- 보드: <주소>`, `.githooks/`에 `pre-push`·`board-sync.sh` 사본(이미 `pre-push`가 있으면 멈추고 알림), 실행 권한. 커밋은 하지 않고 바뀐 파일을 출력한다(커밋은 세션이 `waypoint:git`대로).
- 세션은 플러그인 경로를 Bash에서 모르므로, 이 스크립트를 Read 도구로 읽어 레포 밖 임시 경로에 Write한 뒤 실행한다(`waypoint:init`에 적는다).

- [ ] **Step 1: 테스트(가짜 gh).** `template`의 호출 순서와 이름, `repo`의 복사·연결·CLAUDE.md 줄(이미 있으면 덧붙이지 않음)·훅 사본·기존 `pre-push`가 있을 때 멈춤.
- [ ] **Step 2~4:** 실패 확인, 구현, 통과. **커밋:** `feat(plugin): 보드 설정 스크립트(템플릿, 레포 적용)`

### Task 7: 세션 시작 요약

**Files:** Modify `plugin/scripts/session-context.sh`. Test: `tests/session-context.test.sh`.

- 메인 체크아웃의 `.git/waypoint/board-sync.status`가 `fail`로 시작하면, 요약의 경고 줄 자리에 `보드 동기화 실패(<시각>): <단계>: <이유>` 한 줄을 붙인다(셸 내장 `read`만).
- 낡은 사본 경고를 `.githooks/pre-push`와 `.githooks/board-sync.sh`에도 적용한다. 파일 이름이 경고 문장에 들어간다.

- [ ] **Step 1: 테스트(기본 PATH와 `PATH=''`).** `sync-fail`, `sync-ok`(줄 없음), `sync-none`(파일 없음), `stale-pre-push`, `stale-board-sync`. 기존 경우는 그대로 통과.
- [ ] **Step 2~4:** 실패 확인, 구현, 통과. **커밋:** `feat(plugin): 세션 시작 때 보드 동기화 실패와 낡은 훅 사본 알림`

### Task 8: 스킬과 템플릿(설계 5.11·5.13절)

**Files:** Modify `plugin/skills/{git,init,stage,worker,mediator}/SKILL.md`, `plugin/templates/{worker-brief-template,claude-md-block}.md`, `tests/plugin-files.test.sh`.

- **stage:** 「진행 기록」의 PR 본문 문장을 「스테이지 이슈 본문(`gh issue edit <번호> --body-file`)의 `## 체크리스트`·`## 최근 진행`」으로 바꾼다. PR 본문에는 `Refs #<이슈 번호>`와 짧은 설명만 둔다. `Closes`·`Fixes`를 쓰지 않는다. 이슈의 제목·라벨·열림과 Project 필드는 동기화만 고친다.
- **worker:** 「세부 진행」이 stage를 가리키는 문장에서 `gh pr edit`를 `gh issue edit`로 바꾼다. 지시문의 「스테이지 이슈」 번호를 쓴다. 번호가 없으면 `gh issue list --label waypoint --search "[<ID>] in:title"`로 찾는다.
- **mediator:** 지시문에 이슈 번호를 채우는 방법(Project의 ID 필드나 위 검색, 없으면 `.githooks/board-sync.sh`를 직접 실행한 뒤 찾기). 세션 시작 요약의 「보드 동기화 실패」 줄을 보면 원인을 고치고 동기화를 직접 실행한다. `gh` 권한 문제면 오너 할 일로 올린다.
- **git:** 새 하위 절 `### 보드 동기화`(pre-push가 언제 띄우는지, 상태 파일과 로그 위치, 직접 실행, 실패를 고치는 법, 낡은 사본 교체). 「스테이지 브랜치와 PR」 2번의 초안 PR 본문에 `Refs #<이슈 번호>`.
- **init:** 보드 설정 단계(템플릿 주소를 오너에게 묻고 `board-setup.sh repo`, 첫 동기화).
- **worker-brief-template:** `- 스테이지 이슈: #{이슈 번호}` 줄.
- **claude-md-block:** 「보드: 줄은 `board-setup.sh`가 더한다. 이 줄이 있으면 STATUS push 때 보드가 동기화된다」는 문장(설계와 다른 점 3).

- [ ] **Step 1: 검사.** `has`로 각 문장, `worker`에 `gh pr edit`가 없음, 절 참조 검사(xref) 통과, 대조표 검사 통과.
- [ ] **Step 2~4:** 실패 확인, 고치기, 통과. **커밋:** `feat(plugin): 세부 진행을 스테이지 이슈 본문에, 보드 동기화 안내`

### Task 9: 절차 M, 전체 검증, 독립 리뷰, PR

- [ ] **Step 1: 절차 M.** M6a 뒤에 `M6b 보드 적용(선택)`: `board-setup.sh repo`로 Project 복사·연결·`보드:` 줄·훅 사본, 커밋. M10에 「머지 뒤 메인 체크아웃에서 `.githooks/board-sync.sh` 첫 실행」. 커밋 `docs(plan): 절차 M에 보드 적용 단계`.
- [ ] **Step 2:** 전체 테스트와 대조표 검사. 실제 레포(shadow, tokens, 레포 밖)에서 `session-context.sh` 출력이 master와 같은지(보드 줄이 없으므로) 비교.
- [ ] **Step 3: 독립 리뷰.** 브랜치 전체를 새 서브에이전트(가장 강한 모델)에. 설계, 이 계획, Review Focus, Task 1 결과를 준다. 특히 이슈 중복, 본문 덮어쓰기, push 지연, 잠금, 2·3단계 규칙과의 충돌.
- [ ] **Step 4: PR.** rebase 뒤 `gh pr create -R bingoring/waypoint --base master --head feat/board-sync --title "feat(plugin): 보드 동기화(4단계) — pre-push로 GitHub Projects와 스테이지 이슈"`. 본문: 바뀐 파일, Task 1 결과, 설계와 다른 점, 머지 뒤 할 일.

---

## Part C — 머지 뒤

### Task 10: 템플릿 만들기와 tokens-are-running-out 적용

- [ ] **Step 1: 플러그인 갱신**(사용자 범위, shadow·tokens 프로젝트 범위).
- [ ] **Step 2: 템플릿.** `board-setup.sh template bingoring`. 출력된 화면 설정(보드 보기의 가로 묶음 = 줄기, 14일 보관 자동화)을 오너가 하거나, 오너가 허락하면 앱의 브라우저로 한다.
- [ ] **Step 3: tokens 적용.** 메인 체크아웃이 `main`이고 깨끗한지, tokens에서 일하는 세션(중재자, 3-2 작업 세션)이 쉬고 있는지 확인한다. `board-setup.sh repo /Users/ywyeom/private/tokens-are-running-out <템플릿 주소>` → CLAUDE.md·훅 사본 커밋·push(`chore(waypoint): 보드 설정과 pre-push 훅`) → `.githooks/board-sync.sh` 첫 실행. 기대: 3-1, 3-2 이슈 두 개가 생기고(MERGED 줄은 카드 없음), 보드의 「진행 중」 열에 두 카드, 3-1 카드의 기다림에 「오너 할 일: 3-1 소개 글 게시(Show HN, GeekNews)」.
- [ ] **Step 4: 실제 push로 확인.** 다음 실제 STATUS 변경(예: 3-2가 계획 검토로 바뀌어 중재자가 push할 때)에서 pre-push가 보드를 고치는지, 상태 파일이 `ok`인지 확인한다. 시험만을 위해 STATUS를 바꾸지 않는다.
- [ ] **Step 5: 3-2 작업 세션 안내.** 3-2는 PR #16 본문에 세부 진행을 적어 왔다. 중재자를 통해 「앞으로는 스테이지 이슈 본문에, PR 본문에는 `Refs #<번호>`」를 전하도록 오너에게 안내한다.
- [ ] **Step 6: 정리.** 시험 레포와 시험 Project를 지울지 오너에게 묻는다(지우기는 되돌릴 수 없다). 인계 메모 `stage4-implementation.md`.
