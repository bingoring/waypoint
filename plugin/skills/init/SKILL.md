---
name: init
description: 새 프로젝트 레포를 waypoint에 연결할 때 사용한다. docs/waypoint 골격, STATUS·DECISIONS, 플러그인 설정, commit-msg·pre-commit 훅, CLAUDE.md 블록을 만들고, 오너가 원하면 GitHub Project 보드를 붙인다.
---

# waypoint 프로젝트 초기화

새 프로젝트 레포의 루트(메인 체크아웃)에서, 메인 체크아웃의 기본 브랜치에서 아래 순서로 진행한다. 세션용 worktree나 기능 브랜치에서 하면 pre-commit 훅이 STATUS·DECISIONS 커밋을 거부한다(`waypoint:git`의 「pre-commit 검사」). 템플릿은 모두 `${CLAUDE_PLUGIN_ROOT}/templates/`에 있다. 템플릿 파일은 Read 도구로 읽어 Write 도구로 프로젝트에 복사한다. Bash 명령 안에서는 `${CLAUDE_PLUGIN_ROOT}`를 쓰지 않는다(환경변수로 노출되지 않는다).

0. **이미 waypoint를 쓰는 레포인지 확인한다.** `.gitmodules`에 waypoint 서브모듈(`docs/dlc` 또는 `waypoint` 경로)이 있거나 `docs/waypoint/`가 이미 있으면 멈추고 오너에게 알린다. 기존 프로젝트를 옮기는 일은 이 스킬이 아니라 waypoint 레포의 이전 절차(`docs/superpowers/plans/2026-11-24-plugin-split.md`의 절차 M)로 한다.
1. **문서 골격을 만든다.** `docs/waypoint/01-inception`, `docs/waypoint/02-construction`, `docs/waypoint/03-operations` 디렉터리를 만든다.
2. **STATUS와 DECISIONS를 만든다.**
   - `${CLAUDE_PLUGIN_ROOT}/templates/STATUS.template.md` → `docs/waypoint/STATUS.md`. `{Project Name}`을 채운다.
   - `${CLAUDE_PLUGIN_ROOT}/templates/decisions-template.md` → `docs/waypoint/DECISIONS.md`. `{Project Name}`을 채운다.
3. **플러그인 설정, commit-msg·pre-commit 훅, CLAUDE.md 블록을 넣는다.**
   - `${CLAUDE_PLUGIN_ROOT}/templates/project-settings.json`의 두 키(`extraKnownMarketplaces`, `enabledPlugins`)를 `.claude/settings.json`에 넣는다. 파일이 이미 있으면 기존 키를 지우지 말고 합친다.
   - `${CLAUDE_PLUGIN_ROOT}/githooks/commit-msg` → `.githooks/commit-msg`. 이미 있으면 그대로 둔다. 새로 만들었으면 `chmod +x .githooks/commit-msg`를 실행한다.
   - `${CLAUDE_PLUGIN_ROOT}/githooks/pre-commit` → `.githooks/pre-commit`. 새로 만들었으면 `chmod +x .githooks/pre-commit`을 실행한다. 이미 있으면 덮어쓰지 말고 멈춰서 오너에게 알린다. 기존 훅과 합치는 방법은 오너와 정한다(합친 파일의 둘째 줄에도 `# waypoint-hook-version: <번호>`가 있어야 세션 시작 때 낡은 훅을 알아챈다).
   - `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-block.md`의 내용을 `CLAUDE.md`에 넣는다. `CLAUDE.md`가 없으면 새로 만들고, 있으면 끝에 덧붙인다.
4. **훅 경로를 설정한다.** `git config core.hooksPath .githooks`를 실행한다.
5. **보드를 붙인다(오너가 원할 때).** 보드는 STATUS를 GitHub Project 보드와 스테이지 이슈로 보여 준다(`waypoint:git`의 「보드 동기화」). 오너에게 보드를 쓸지와 템플릿 Project 주소(「waypoint 보드 템플릿」)를 묻는다. 쓰지 않으면 6번으로 간다.
   - `gh auth status`의 토큰 권한에 `project`가 없으면 오너에게 `gh auth refresh -s project` 실행을 부탁한다. 브라우저 로그인이 필요해서 오너가 직접 한다.
   - `${CLAUDE_PLUGIN_ROOT}/scripts/board-setup.sh`, `${CLAUDE_PLUGIN_ROOT}/scripts/board-sync.sh`, `${CLAUDE_PLUGIN_ROOT}/githooks/pre-push`를 Read 도구로 읽어, 레포 밖의 같은 임시 폴더(예: 세션의 scratchpad 안 `waypoint-board/`)에 Write 도구로 쓴다.
   - 템플릿이 아직 없으면 `sh <임시 폴더>/board-setup.sh template <소유자>`로 만든다. 출력 끝의 「GitHub 화면에서 할 일」 세 가지를 오너에게 안내한다. 오너가 허락하면 앱의 브라우저로 대신 설정한다. 템플릿은 소유자마다 한 번만 만든다.
   - 레포 루트에서 `sh <임시 폴더>/board-setup.sh repo . <템플릿 주소>`를 실행한다. 템플릿을 `<레포 이름> 보드`로 복사해 레포에 연결하고, CLAUDE.md의 「검토 대기 상한」 줄 아래에 `- 보드: <주소>` 줄을, `.githooks/`에 `pre-push`와 `board-sync.sh` 사본을 넣는다. 커밋은 하지 않는다. 기존 `pre-push`가 있어서 멈추면 합치는 방법을 오너와 정한다.
6. **커밋하고 push한다.** 만든 파일을 기본 브랜치에 바로 커밋하고 push한다(예: `chore(waypoint): waypoint 연결`).
7. **첫 동기화(보드를 붙였을 때).** 레포 루트에서 `sh .githooks/board-sync.sh`를 실행하고 `.git/waypoint/board-sync.status`가 `ok`로 시작하는지 본다. `MERGED`가 아닌 STATUS 줄마다 이슈가 만들어져 보드에 들어간다.

마치면 새 세션을 열어 `<waypoint>` 블록이 주입되는지 확인하고, `waypoint:start`로 시작할 스테이지를 오너와 정한다.
