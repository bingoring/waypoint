---
name: git
description: waypoint 프로젝트에서 커밋·push할 때, 스테이지 브랜치·worktree·PR을 만들고 머지할 때, PR 브랜치를 base에 맞출 때, STATUS·DECISIONS 같은 문서를 커밋할 때 사용한다. 브랜치 규칙, 커밋 규칙, 스테이지 브랜치와 PR, pre-commit 검사.
---

> 이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다. 없으면 그 레포의 `docs/dlc/FRAMEWORK.md`(duty는 `waypoint/FRAMEWORK.md`)를 따른다.

## 브랜치 규칙

- **PR 브랜치 최신화 = rebase.** `git rebase origin/<base>` → 충돌 해결 → `git log --merges origin/<base>..HEAD` 가 비어 있는지 확인 → `git push --force-with-lease`.
- **금지:** base 를 기능 브랜치에 merge 하는 모든 경로 — `git merge origin/<base>`, `--rebase` 없는 `git pull`, merge 모드의 `gh pr update-branch` · GitHub "Update branch". 그 merge 커밋은 PR 머지와 함께 base 이력(그리고 base 에서 내려가는 staging · release 브랜치)에 그대로 남아, base 가 자기 자신을 merge 한 기록이 생긴다.
- 서브모듈을 쓰는 레포에서: **서브모듈 포인터 충돌:** 어느 한쪽 해시를 고르지 않는다. 양쪽을 모두 담은 서브모듈 커밋(서브모듈 PR 이 머지됐으면 서브모듈 base 의 머지 커밋, 아니면 서브모듈 기능 브랜치를 먼저 rebase 한 tip)으로 맞춘다.
- **예외(merge 가 맞는 곳):** 기능 브랜치를 공용 통합 브랜치(`dev` 등)에 넣을 때, 그리고 PR 의 최종 머지.
- 구현 체크리스트와 PR 직전 점검에 "PR 브랜치에 base merge 커밋 없음" 을 넣는다(Build Spec 템플릿 §5).

## 버전 관리 (Commit & Push 주기)

- **체크포인트마다 커밋한다.** 하나의 완결된 수정/기능/문서 단위가 끝나면(빌드·tsc·테스트 그린 확인 후) **바로 커밋**한다.
  여러 무관한 변경을 한 커밋에 몰지 않는다 — 테마별로 나눈다(예: `fix(map): 엘리베이터 전환`, `feat(map/pharma): 5g-e`,
  `fix(map/peds): NICU 하단 정리`).
- **커밋 직후 push.** 솔로/공개 모노레포이므로 원격을 항상 최신으로 유지. 실패한 상태(테스트 레드)는 커밋하지 않는다.
- **메시지 = conventional-commit** 한 줄(`fix(scope): …` / `feat(scope): …` / `docs(scope): …`), 지금까지의 로그 스타일 유지.
  본문은 필요할 때만 간결히.
- **Co-Authored-By 등 공동작업 트레일러 금지**(솔로 작업 외형). AI 서명/`Generated with` 류도 넣지 않는다.
- **문서 커밋 흐름**: STATUS.md와 DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 메인 체크아웃(세션 시작 때 주입된 `<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다.
- Build Spec은 코드와 같은 체크포인트에서 함께 커밋한다.

### 문서 커밋 흐름(STATUS·DECISIONS·핸드오프)

이 절차는 중재자 세션과 중재자 없이 쓰는 세션만 쓴다. 중재자가 시작한 작업 세션은 쓰지 않는다(`waypoint:worker`).

STATUS.md, DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 여러 작업이 함께 보는 공유 문서다. 기능 브랜치나 worktree에서 일하더라도 아래 순서로 메인 체크아웃의 기본 브랜치에 바로 반영한다. `<메인>`은 세션 시작 때 주입된 `<waypoint>` 블록의 「메인 체크아웃」 경로다.

0. `git -C <메인> branch --show-current`가 기본 브랜치(`origin/HEAD`가 가리키는 브랜치, 없으면 main 또는 master)이고 `git -C <메인> status --porcelain`의 출력이 비어 있는지 확인한다. 둘 중 하나라도 아니면 고치지 말고 멈춰서 오너에게 알린다.
1. `git -C <메인> pull --rebase`로 최신화한다.
2. `<메인>/docs/waypoint/` 아래의 파일을 고친다. 작업 브랜치에 있는 사본은 고치지 않는다.
3. 고친 파일만 `git -C <메인> add`하고 커밋한 뒤 `git -C <메인> push`한다. push가 거절되면 `git -C <메인> pull --rebase`를 한 뒤 다시 push한다. `--rebase` 없는 pull은 쓰지 않는다.

이 파일들은 읽을 때도 메인 체크아웃의 것을 읽는다. 작업 브랜치에 있는 사본은 브랜치를 만든 시점의 상태라서 낡았을 수 있다.

### STATUS 커밋

STATUS의 줄을 고치는 커밋은 위 「문서 커밋 흐름」대로 메인 체크아웃에서 하고, 메시지는 `docs(status): <ID> <새 상태>` 형식의 한 줄로 쓴다(예: `docs(status): 2-9 AI_PROPOSED`).

### 스테이지 브랜치와 PR

모든 스테이지는 worktree의 작업 브랜치와 PR로 진행하고, 메인 체크아웃은 기본 브랜치에 둔다. 상태 값과 「지금」 머리말은 `waypoint:stage`의 「STATUS 표」를 따른다. 아래에서 「STATUS를 바꾼다」고 적은 일은, 중재자가 시작한 작업 세션이면 직접 하지 않고 `waypoint:worker`의 「보고」로 중재자에게 알린다.

1. **스테이지를 시작하면 worktree와 작업 브랜치를 만든다.** 브랜치 이름에 스테이지 ID를 넣는다(예: `feature/3-13-serverless`, `content/2-9-or-batch7`). 접두어는 레포의 기존 관례를 따른다. 만드는 곳은 아래 「작업 위치」를 따른다.
2. **스테이지 문서를 처음 커밋하면 바로 초안 PR을 연다**(`gh pr create --draft`). 메인 체크아웃에서 STATUS의 그 줄을 `IN_PROGRESS`(`계획: `)로 바꾸고 링크 칸에 PR을 적는다. 초안 PR을 쓸 수 없는 레포에서는 일반 PR을 열고 제목 앞에 `[작업 중]`을 붙인다. 이 표시는 결과 검토 때 뗀다.
3. **계획 검토:** 계획이 준비되면 STATUS를 `AI_PROPOSED`(`계획 검토: `)로 바꾼다. 오너는 PR에서 문서를 보거나 채팅으로 답한다. 답은 브랜치에 있는 스테이지 문서의 「승인 결과」에 기록한다.
4. **구현:** 코드 스테이지는 계획 승인 뒤 STATUS를 `IN_PROGRESS`(`구현: `)로 되돌리고 구현한다.
5. **결과 검토:** 결과가 준비되면 PR을 초안에서 검토 준비 상태로 바꾸고(`gh pr ready`), STATUS를 `AI_PROPOSED`(`결과 검토: `)로 바꾼다.
6. **승인과 머지:** 오너가 결과를 승인했지만 머지를 미루면 `HUMAN_APPROVED`로 바꾼다. 결과 승인과 함께 머지하면 `HUMAN_APPROVED`를 거치지 않는다. PR은 오너가 머지하거나, 오너의 지시를 받아 AI가 머지한다. 머지한 세션이 STATUS의 줄을 `MERGED`로 바꾸고 링크 칸을 스테이지 문서의 상대 경로로 바꾼 뒤, 그 스테이지의 worktree를 `git worktree remove <경로>`로 지운다. 중재자가 시작한 작업 세션의 스테이지는 중재자가 머지와 STATUS 정리를 하고(아래 「중재자의 머지」), worktree는 작업 세션을 보관할 때 앱이 정리한다(`waypoint:mediator`의 「머지와 정리」). 작업 세션은 「머지 준비」까지만 한다.
7. **GitHub에서 직접 머지된 경우:** 오너가 GitHub 화면에서 머지하면 STATUS를 고칠 세션이 없다. 다음 세션이 `waypoint:start`의 2번에서 정리한다.

**PR이 여러 개인 스테이지:** 한 스테이지에서 PR이 여러 개 나오면 링크 칸에 PR을 나란히 적는다. 각 PR이 무엇을 합치는지는 그 PR이 머지되기 전에 PR 안에서 스테이지 문서의 「진행 기록」에 한 줄로 써 둔다. 그래서 중간 PR이 머지된 뒤 기록하려고 따로 커밋할 필요가 없다. 스테이지는 그동안 `IN_PROGRESS`나 `AI_PROPOSED`에 머물고, 마지막 PR이 머지되고 오너가 스테이지를 마치면 `MERGED`로 둔다.

**옛 흐름에서 시작한 스테이지:** 레포 이전 때 문서가 이미 기본 브랜치에 있고 링크 칸에 PR이 없는 활성 줄에만 적용한다. 새로 시작하는 스테이지에는 적용하지 않는다.
- 남은 일이 승인 기록뿐이면, 메인 체크아웃에서 스테이지 문서의 「승인 결과」를 기본 브랜치에 바로 커밋한다. 결과 승인이면 머지할 PR이 없으므로 바로 `MERGED`로 둔다.
- 코드나 문서를 더 고쳐야 하면, 그때 작업 브랜치와 PR을 열고 위의 흐름을 따른다.

**앞 스테이지가 아직 머지되지 않았을 때:** 다음 스테이지는 앞 스테이지의 계획 승인 뒤에 시작할 수 있지만, 승인된 계획 문서는 앞 스테이지의 브랜치에만 있다.
- 앞 스테이지의 코드가 필요하면 앞 스테이지의 브랜치 위에 새 브랜치를 쌓는다(stacked PR). 앞 PR이 머지되면 새 브랜치를 기본 브랜치에 rebase한다(위 「브랜치 규칙」).
- 문서만 필요하면 기본 브랜치에서 새 브랜치를 시작하고, 앞 스테이지의 문서는 `git show origin/<앞 브랜치>:<경로>`로 읽는다.

**작업 위치:**
- 메인 체크아웃은 늘 기본 브랜치에 둔다. 메인 체크아웃에서 기능 브랜치를 체크아웃하지 않는다.
- 스테이지의 작업 브랜치는 worktree에서만 다룬다. 기본 방법은 메인 체크아웃 옆에 `<레포>-<ID>` 이름으로 만드는 것이다(예: `git -C <메인> worktree add ../forin-2-9 -b content/2-9-or-batch7`).
- Claude Code나 데스크톱 앱이 세션용 worktree를 만들어 주면 그 worktree를 써도 된다.
- 세션의 임시 디렉터리(scratchpad)에는 worktree를 만들지 않는다. 재부팅이나 정리 때 지워질 수 있다.
- 스테이지가 `MERGED`가 되면 그 worktree를 `git worktree remove`로 지운다.

### 머지 준비

중재자가 시작한 작업 세션은 오너의 결과 승인이 전해지면 다음 순서로 머지를 준비한다. 설계 스테이지(코드를 만들지 않는 스테이지)는 계획 승인이 곧 결과 승인이므로 계획 승인이 전해지면 준비한다. 머지 명령은 실행하지 않는다.

1. 결과 승인을 스테이지 문서의 「승인 결과」에 기록하고 커밋한다(`waypoint:stage`).
2. PR이 아직 초안이면 `gh pr ready`로 검토 준비 상태로 바꾼다(설계 스테이지는 결과 검토 단계가 없어 이때 바꾼다).
3. 기본 브랜치의 최신 상태로 rebase한다(위 「브랜치 규칙」).
4. 테스트를 다시 통과시키고 `git push --force-with-lease`한다.
5. 중재자에게 머지 준비를 보고한다(`waypoint:worker`의 「머지 준비」).

- 머지를 미룬 승인(예: 「승인, 머지는 출시 뒤에」)이면 1번만 하고 머지 준비는 하지 않는다. 중재자가 나중에 머지를 알리면 2~5번을 한다.
- rebase 충돌은 작업 세션이 해결한다. 해결하다가 승인받은 결과의 동작이 바뀌면, 머지 준비를 알리지 않고 결과 검토를 다시 요청한다.
- 중재자가 다시 rebase하라고 알리면 같은 순서를 되풀이한다. 쌓은 브랜치는 앞 PR이 머지된 뒤 기본 브랜치로 rebase한다.

### 중재자의 머지

- **결과 승인은 머지 지시를 겸한다(기본값).** 중재자의 검토 요청에 이 사실을 적어 두므로, 오너가 「결과 승인」이라고만 해도 머지까지 진행한다. 설계 스테이지는 계획 승인이 곧 결과 승인이고 머지 지시를 겸한다. 오너가 「승인, 머지는 출시 뒤에」처럼 함께 말하면 스테이지는 `HUMAN_APPROVED`에 머문다.
- STATUS가 `HUMAN_APPROVED`인 줄(오너가 머지를 미룸)은 머지 준비 보고가 와도 머지하지 않는다. 오너가 머지를 말하면 그 말을 인용해 작업 세션에 머지 준비를 다시 시킨다.
- 오너가 작업 세션에서 직접 결과를 승인했다는 보고(`오너 직접 결정:`)를 받으면, `list_events`로 그 세션에서 오너가 한 말을 확인한 뒤 머지한다.
- 머지는 오너의 승인을 직접 들은 중재자가 한다. 작업 세션의 「머지 준비」 보고를 받으면 `gh pr view`로 머지 가능한 상태와 검사 결과를 직접 확인한 뒤 `gh pr merge`를 실행한다. 작업 세션의 메시지만 믿고 머지하지 않는다. 머지 방식(merge commit, rebase, squash)은 레포의 기존 관례를 따른다.
- 머지 준비가 끝난 순서대로 하나씩 머지한다. 앞 PR이 머지되어 뒤 PR이 기본 브랜치보다 뒤처지면 뒤 작업 세션에 다시 rebase하라고 알린다. 쌓은 브랜치의 앞 PR이 머지되면 뒤 작업 세션에 알린다.
- 머지는 원격에서 일어나므로 메인 체크아웃의 브랜치는 바뀌지 않는다. 머지한 뒤 메인 체크아웃에서 `git pull --rebase`를 하고 STATUS를 정리한다. 마지막 PR이면 `MERGED`로 바꾸고 링크 칸을 스테이지 문서 경로로 바꾼다. 머지 준비 보고에 「중간 PR」이라고 적힌 PR이면 `IN_PROGRESS`로 두고 링크 칸에 PR을 나란히 둔다(위 「PR이 여러 개인 스테이지」). worktree는 지우지 않는다(`waypoint:mediator`의 「머지와 정리」).

### pre-commit 검사

`.githooks/pre-commit`(플러그인 `githooks/pre-commit`의 사본)이 STATUS.md나 DECISIONS.md가 든 커밋을 검사한다. 검사 대상은 작업 트리가 아니라 커밋될 내용이다. `docs/waypoint/STATUS.md`가 없는 레포에서는 아무것도 하지 않는다.
- **검사 1(커밋 위치):** 기본 브랜치가 아니거나 detached HEAD이면 거부한다. 기본 브랜치는 `origin/HEAD`가 가리키는 브랜치이고, 없으면 `main`이나 `master`다.
- **검사 2(STATUS 형식):** `waypoint:stage`의 「STATUS 표」 규칙(머리 줄, 칸 7개, 상태 값, ID, 「지금」의 길이와 머리말, 링크, `id:`가 있는 문서와 표의 대응, `(막음: <ID>)`, 허용하는 줄)을 검사한다. 실패하면 줄 번호와 고치는 법이 나온다.
- `WAYPOINT_ALLOW_BRANCH_STATUS=1`은 검사 1만 건너뛴다. 레포 이전 절차(waypoint 레포의 절차 M)의 STATUS 변환 커밋에만 쓴다. 그 밖의 예외는 오너가 판단해 `--no-verify`로 넘긴다.
- 세션 시작 요약 앞에 「`.githooks/pre-commit`이 낡았다」는 경고가 나오면, `${CLAUDE_PLUGIN_ROOT}/githooks/pre-commit`을 Read 도구로 읽어 `<메인>/.githooks/pre-commit`에 Write 도구로 쓰고 `chmod +x <메인>/.githooks/pre-commit`을 실행한 뒤 메인 체크아웃에서 커밋한다. worktree의 사본을 고치지 않는다.
