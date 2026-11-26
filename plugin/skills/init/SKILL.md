---
name: init
description: 새 프로젝트 레포를 waypoint에 연결할 때 사용한다. docs/waypoint 골격, STATUS·DECISIONS, 플러그인 설정, commit-msg·pre-commit 훅, CLAUDE.md 블록을 만든다.
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
5. **커밋하고 push한다.** 만든 파일을 기본 브랜치에 바로 커밋하고 push한다(예: `chore(waypoint): waypoint 연결`).

마치면 새 세션을 열어 `<waypoint>` 블록이 주입되는지 확인하고, `waypoint:start`로 시작할 스테이지를 오너와 정한다.
