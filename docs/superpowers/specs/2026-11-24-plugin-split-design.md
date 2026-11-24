# waypoint 플러그인 전환과 프로젝트 문서 분리 — 설계

- 작성일: 2026-11-24
- 상태: 오너 검토 대기
- 범위: waypoint 고도화 4단계 중 1단계

## 1. 배경과 목적

waypoint는 Markdown 문서와 사람 승인 게이트로 AI 개발을 진행하는 개인용 프레임워크다. 지금은 프레임워크 규칙(`FRAMEWORK.md`, `_templates/`)과 다섯 프로젝트의 문서(`projects/{name}/`)가 한 레포에 함께 있고, 각 프로젝트 레포가 이 레포를 git submodule로 넣어 쓴다.

실사용에서 드러난 문제는 다음과 같다.

- **포인터가 계속 뒤처진다.** waypoint 커밋 913개 가운데 대부분이 프로젝트 문서 변경이다(`docs(forin)` 343개, `app-factory` 149개 등). 한 프로젝트가 문서를 커밋하면 다른 네 레포의 submodule 포인터가 뒤처진다. 「작업 전 `pull --rebase`」, 「이력 재작성 금지」 규칙도 이 구조 때문에 생겼다.
- **세션마다 규칙 전체를 읽는다.** 세션 시작 프로토콜이 `FRAMEWORK.md` 194줄 전체를 읽게 한다. 지금 단계에 필요 없는 규칙(리뷰 게이트, Build Spec 등)도 매번 컨텍스트에 올라간다.
- **연결 방식이 제각각이다.** duty는 `waypoint/` 경로와 SSH URL을, 나머지는 `docs/dlc/` 경로와 HTTPS URL을 쓴다.
- **2~4단계를 담을 자리가 없다.** 이어질 단계(STATUS 정리, 중재자와 작업 세션 구조, Notion·GitHub 동기화)에는 서브에이전트, 훅, 스크립트가 필요하다. 지금 구조에는 이것들을 둘 곳이 없다.

이 단계의 목적은 두 가지다. 프레임워크는 Claude Code 플러그인으로 배포하고, 프로젝트 문서는 각 프로젝트 레포가 직접 소유하게 한다.

### 전체 로드맵에서의 위치

| 단계 | 내용 | 이 문서 |
|---|---|---|
| 1 | 프레임워크와 프로젝트 문서 분리, 플러그인 전환 | ✅ |
| 2 | STATUS 정리(상태 표만 남기고 진행 기록은 분리) | 별도 설계 |
| 3 | 중재자 세션과 작업 세션 구조(병렬, worktree) | 별도 설계 |
| 4 | md 원본에서 Notion 칸반과 GitHub 이슈·PR로 단방향 동기화 | 별도 설계 |

오너가 내린 상위 결정(2026-11-24):
- 진행 상태의 원본은 md다. Notion과 GitHub는 md에서 한 방향으로 갱신되는 보기용이다.
- waypoint는 개인 프로젝트 전용이다. 회사 업무에는 쓰지 않는다.
- 1단계는 플러그인 전환 방식으로 한다.

## 2. 목표, 비목표, 실패 조건

### 목표
- waypoint 레포를 Claude Code 플러그인 마켓플레이스와 플러그인 하나로 만든다.
- `FRAMEWORK.md`의 규칙을 스킬 단위로 나눠, 해당 단계에 들어갈 때만 로드되게 한다.
- 항상 지켜야 하는 핵심 규칙은 플러그인 훅이 세션 시작과 compact 직후에 주입한다.
- 다섯 프로젝트의 문서를 각 레포의 `docs/waypoint/`로 옮기고, 그 문서의 git 이력을 보존한다.
- 각 프로젝트 레포에서 submodule을 제거하고, 코드·테스트·CI가 참조하는 경로를 새 경로로 바꾼다.

### 비목표
- 규칙 **내용**의 변경. 이 단계에서는 규칙을 옮기고 나누기만 한다. 규칙을 고치는 일은 2~4단계와 이후 회고에서 한다.
- STATUS 정리(2단계), 세션 구조(3단계), Notion·GitHub 동기화(4단계).
- 회사 쪽 사본(`~/vinulabs/everytime/dlc`, `~/vinulabs/everytime/waypoint`) 정리.
- waypoint 레포의 과거 이력 재작성. 과거 이력에는 공개되면 안 되는 프로젝트 문서(예: app-factory의 사업자 관련 내용)가 남아 있다. 하지만 이력을 재작성하면 각 레포의 과거 커밋이 가리키는 submodule 포인터가 깨진다. 이력 정리가 필요하면 오너가 따로 결정한다.

### 실패 조건 (기술적으로 돌아가도 실패로 보는 경우)
- **규칙의 뜻이 바뀐다.** 나누는 과정에서 규칙 문장이 빠지거나, 두 곳에 중복되어 서로 달라지거나, 뜻이 뒤집히면 실패다. 채널톡 사례에서 규칙을 번역하다가 「존댓말과 약어 금지」가 「존댓말 금지」로 바뀐 일이 있었다.
- **이전 도중 작업이 유실된다.** 다른 세션이 진행 중이던 문서 변경이나 기능 브랜치의 작업이 이전 과정에서 사라지면 실패다.
- **forin의 테스트나 CI가 문서 경로 때문에 깨진 채로 남는다.**
- **문서가 두 군데로 갈라진다.** 이전 뒤에도 옛 경로(`docs/dlc/projects/...`)에 누군가 문서를 계속 쓸 수 있으면 실패다.

## 3. 제약

- **동시 작업:** waypoint와 각 프로젝트 레포에서는 다른 세션이 계속 작업하고 있다. 2026-11-24에도 forin STATUS 커밋이 들어왔다. app-factory는 worktree 4개가 각자 기능 브랜치에 있고, forin도 `content/or-batch6` 브랜치에서 작업 중이다.
- **forin의 경로 의존:** forin은 코드와 문서에서 `docs/dlc/...`를 37곳 참조한다.
  - 테스트(`mobile/src/components/nb/nbMotion.test.tsx`, `ficons.test`)가 `inputs/design-handoff_v42/reference/` 파일을 직접 읽는다.
  - CI(`.github/workflows/build.yml`, `ota.yml`, `mobile.yml`)는 `submodules: true`로 문서를 받는다.
  - 그 밖에 `server/content/tools/*.py`, `ports.go`, `.claude/launch.json`, `README.md`, `infra/README.md`, `.gitignore`에도 참조가 있다.
- **다른 레포의 참조:**
  - app-factory: `README.md`, `CLAUDE.md`, `prototypes/ball-roguelite/README.md`, `apps/yawn/tool/sprites/export.py`
  - duty: `README.md`, `deploy/gcp/serverless.sh`, `deploy/cloudrun/README.md`, `fixtures/paper-2026-10.json`
  - tokens-are-running-out: `README.md`, `CLAUDE.md`. 그리고 `core.hooksPath docs/dlc/.githooks`에 의존한다.
  - shadow: `.gitmodules`만 참조한다.
- **용량:** 프로젝트 문서는 forin 117MB(대부분 `inputs/` 디자인 핸드오프), app-factory 29MB, duty 2.3MB, tokens-are-running-out 76KB, shadow 40KB다. waypoint `.git` 전체는 22MB다.
- **공개 범위:** forin, duty, shadow, tokens-are-running-out, waypoint는 public이고, app-factory만 private이다.
- **플러그인 제약(공식 문서, 2026-11-24 조회, https://code.claude.com/docs/en/plugins/manifest-reference.md, 공식 확인):**
  - 플러그인 루트의 `CLAUDE.md`는 로드되지 않는다.
  - 스킬은 호출될 때만 로드된다.
  - `${CLAUDE_PLUGIN_ROOT}`는 스킬 본문과 훅 명령 안에서 치환되지만, Bash 도구의 환경변수로는 노출되지 않는다.
  - `plugin.json`에 `version`을 적지 않으면 플러그인은 커밋을 따라간다.
  - 프로젝트 `.claude/settings.json`의 `enabledPlugins`만으로는 자동 설치되지 않는다.
- **훅 제약(공식 문서, https://code.claude.com/docs/en/hooks.md, 공식 확인):** `SessionStart` 훅은 matcher `startup|resume|clear|compact`를 지원한다. stdout은 컨텍스트에 들어간다. 이 경로에서는 `mcp_tool` 핸들러가 건너뛰어지므로 `command` 핸들러를 쓴다.
- **커밋 규칙:** waypoint와 각 레포는 공동작업 트레일러를 금지한다. 커밋 메시지는 conventional commit 한 줄로 쓰고, 커밋 직후 push한다.

## 4. 접근 방식

| 방식 | 내용 | 판정 |
|---|---|---|
| **A. 플러그인 전환** | waypoint 레포를 마켓플레이스와 플러그인으로 만든다. 규칙은 스킬, 템플릿은 플러그인 파일, 항상 필요한 규칙은 SessionStart 훅이 주입한다. 프로젝트 문서는 각 레포로 옮긴다. | **채택** |
| B. 프레임워크 전용 submodule | `projects/`만 각 레포로 옮기고, 연결은 submodule로 유지한다. | 탈락: 규칙을 고칠 때마다 다섯 레포에서 포인터를 올려야 하고, 규칙 전체를 매번 읽는 비용이 남는다. 3·4단계의 훅과 스크립트는 결국 레포마다 따로 연결해야 한다. |
| C. 스크립트 복사 | Spec Kit처럼 `init`·`upgrade` 스크립트로 레포마다 규칙을 복사한다. | 탈락: 레포마다 사본이 생겨 버전이 어긋난다. 혼자 쓰는 환경에서 CLI를 유지할 이유가 약하다. |

A를 고른 이유: 문서 분리만 놓고 보면 B로도 충분하다. 하지만 2~4단계가 서브에이전트, 훅, 스크립트를 필요로 하므로, 지금 플러그인으로 옮겨야 이전 작업을 두 번 하지 않는다. 혼자 쓰는 환경에서는 사용자 범위로 한 번만 설치하면 모든 레포에 적용된다. 결정자: 오너(2026-11-24).

## 5. 설계

### 5.1 waypoint 레포의 새 구조

```
waypoint/
├── .claude-plugin/
│   └── marketplace.json      # 마켓플레이스 "waypoint", 플러그인 하나(source: "./plugin")
├── plugin/                   # 플러그인 본체. 설치하면 이 디렉터리만 캐시로 복사된다
│   ├── .claude-plugin/plugin.json   # name "waypoint", version 생략(커밋을 따라감)
│   ├── core-rules.md         # 항상 지켜야 하는 규칙. SessionStart 훅이 주입
│   ├── skills/
│   │   ├── start/SKILL.md        # 세션 시작 프로토콜
│   │   ├── stage/SKILL.md        # 스테이지 생애주기·승인 결과·비가역 게이트·문서 깊이·외부 사실 표기
│   │   ├── build-spec/SKILL.md   # 구현 스펙
│   │   ├── review-gate/SKILL.md  # 독립 코드 리뷰 게이트
│   │   ├── decisions/SKILL.md    # 결정 로그
│   │   ├── git/SKILL.md          # 브랜치 규칙·커밋 규칙
│   │   └── init/SKILL.md         # 새 프로젝트를 waypoint에 연결
│   ├── templates/            # 지금의 _templates/ 전부 + STATUS.template.md
│   ├── hooks/hooks.json      # SessionStart → scripts/session-context.sh
│   ├── scripts/session-context.sh
│   └── githooks/commit-msg   # 지금의 .githooks/commit-msg (init이 각 레포로 복사)
├── tests/                    # 플러그인 스크립트와 분할 검사의 테스트(설치 대상 아님)
├── FRAMEWORK.md              # 사람용 개요와 스킬 색인. 규칙 본문은 두지 않는다
├── README.md                 # 설치·사용법
├── CLAUDE.md                 # 이 레포(플러그인 자체)를 고치는 세션용 규칙
└── docs/superpowers/         # 이 설계 문서 같은 waypoint 자체의 설계와 계획
```

`projects/`는 이전이 모두 끝나면 지운다. 이전 중의 처리는 5.5절에 적었다.

> **계획 단계 변경(2026-11-24):** 처음 설계에서는 플러그인을 레포 루트에 두었다. 이것을 `plugin/` 하위 디렉터리로 바꿨다. 플러그인을 설치하면 플러그인 디렉터리 전체가 `~/.claude/plugins/cache/`로 복사되는데, 루트를 플러그인으로 두면 `projects/`(약 150MB)와 테스트·문서까지 복사되기 때문이다. 이 문서의 다른 절에 나오는 `core-rules.md`, `skills/`, `templates/`, `hooks/`, `scripts/`, `githooks/`는 모두 `plugin/` 아래의 경로로 읽는다.

### 5.2 규칙의 배치

`FRAMEWORK.md`의 각 절은 정확히 한 곳으로 옮긴다. 한 규칙 문장이 두 파일에 중복되면 안 된다. 다른 파일에서 필요하면 링크나 스킬 이름으로 참조한다.

| 현재 FRAMEWORK.md 절 | 옮길 곳 |
|---|---|
| 세션 시작 프로토콜 | `skills/start` |
| 절대 규칙 | `core-rules.md` (아래 원칙에 따라 요약하지 않고 그대로 옮김) |
| 브랜치 규칙 | `skills/git` |
| 상태 생애주기 | `skills/stage` |
| 비가역 게이트 추가 체크리스트 | `skills/stage` |
| 리뷰 게이트 | `skills/review-gate` |
| 승인 결과 기록 | `skills/stage` |
| 외부 사실 표기 | `skills/stage` |
| STATUS.md 업데이트 규칙 | `skills/stage` |
| 문서 깊이 | `skills/stage` |
| 구현 스펙 (Build Spec) | `skills/build-spec` |
| 결정 로그 | `skills/decisions` |
| 버전 관리 | `skills/git`. 단, 「트레일러 금지」와 「체크포인트마다 커밋 후 push」 두 줄은 `core-rules.md`에도 둔다. 커밋은 스킬을 부르지 않고도 일어나기 때문이다. |

원칙:
- **`core-rules.md`는 짧게 유지한다.** 목표는 40줄 이하다. 지금의 「절대 규칙」 목록을 그대로 옮기고, 각 항목 끝에 자세한 내용을 담은 스킬 이름을 붙인다. 예: 「… (자세히: `waypoint:review-gate`)」.
- **이전 검증:** 이전 커밋 전에 대조표를 만든다. `FRAMEWORK.md`의 모든 문장이 새 파일 중 정확히 한 곳에 있는지 확인하는 표다. 이 표는 0단계의 waypoint PR 본문에 넣는다(5.5절). 문장을 다듬는 일은 하지 않는다. 허용하는 변경은 다음 두 가지뿐이다.
  - 템플릿 경로 같은 참조를 새 구조에 맞게 고치는 것.
  - **이전 때문에 사실이 아니게 된 문장을 새 흐름에 맞게 고쳐 쓰는 것.** 해당 문장은 다음과 같다.
    - 「버전 관리」의 모노레포 순서(`docs/dlc`에서 먼저 커밋·push한 뒤 포인터 갱신)
    - 「절대 규칙」 마지막 항목의 「서브모듈 포인터 갱신도 rebase 중에」
    - 「브랜치 규칙」의 서브모듈 포인터 충돌 항목
    - 각 레포 CLAUDE.md의 같은 취지 문장(tokens-are-running-out 15행, app-factory 9행 등)
  - 고쳐 쓴 문장은 대조표에 「수정(이전으로 사실이 바뀜)」으로 표시한다. 새 문장의 내용은 9절의 「이전 뒤 문서 커밋 흐름」을 따른다. 그대로 옮기면 틀린 지시가 `core-rules.md`를 통해 세션마다 주입되기 때문에 이 예외를 둔다.
- **스킬의 `description`:** 스킬이 언제 호출되어야 하는지 적는다. 예를 들어 `stage`의 description은 「스테이지 문서를 작성·갱신하거나 상태를 바꿀 때」다. `core-rules.md`와 `start` 스킬은 「다음 스테이지에 들어가기 전에 해당 스킬을 호출하라」고 안내한다.
- **템플릿 경로:** 템플릿은 스킬 본문에서 `${CLAUDE_PLUGIN_ROOT}/templates/...`로 참조한다. 이 변수는 Bash 환경변수로 노출되지 않는다. 그래서 스킬은 Read 도구로 템플릿을 읽고 Write 도구로 복사하도록 안내한다. `cp $CLAUDE_PLUGIN_ROOT/...` 같은 명령은 쓰지 않는다.

### 5.3 SessionStart 훅

`hooks/hooks.json`:
- 이벤트는 `SessionStart`, matcher는 `startup|resume|clear|compact`다.
- 핸들러 타입은 `command`이고, 명령은 `${CLAUDE_PLUGIN_ROOT}/scripts/session-context.sh`다.

`scripts/session-context.sh`의 동작:
1. 현재 작업 디렉터리에서 git 루트를 찾는다. 루트에 `docs/waypoint/STATUS.md`가 없으면 아무것도 출력하지 않고 종료한다. 플러그인을 사용자 범위로 설치하므로, waypoint를 쓰지 않는 레포에서는 조용해야 한다.
2. 파일이 있으면 다음을 출력한다.
   - `core-rules.md`의 내용
   - 「이 레포의 waypoint 문서는 `docs/waypoint/`에 있다. 현황은 `docs/waypoint/STATUS.md`다. 작업을 시작하면 `waypoint:start` 스킬을 호출하라」는 안내
3. STATUS.md의 **내용은 주입하지 않는다.** forin의 STATUS는 1,409줄이다. STATUS를 요약해서 주입하는 일은 2단계에서 정한다.

이 훅으로 얻는 것:
- 핵심 규칙이 플러그인 안에서 관리된다.
- compact 직후에도 핵심 규칙이 다시 들어간다(matcher `compact`).

스크립트는 POSIX sh로 쓰고, 외부 의존성은 `git`만 둔다.

### 5.4 각 프로젝트 레포의 새 구조

```
<project>/
├── .claude/settings.json     # 마켓플레이스 등록 + enabledPlugins (기존 내용과 합침)
├── .githooks/commit-msg      # waypoint githooks/commit-msg 사본
├── CLAUDE.md                 # waypoint 블록(아래) + 레포 고유 규칙
└── docs/waypoint/            # 옛 waypoint/projects/<name>/ 의 내용 전체
    ├── STATUS.md
    ├── DECISIONS.md
    ├── 01-inception/ ...
    └── inputs/ ...
```

**`.claude/settings.json`에 넣을 항목:**
```json
{
  "extraKnownMarketplaces": {
    "waypoint": { "source": { "source": "github", "repo": "bingoring/waypoint" } }
  },
  "enabledPlugins": { "waypoint@waypoint": true }
}
```
이 설정은 다른 기기나 새 클론에서 이 레포가 waypoint 플러그인을 쓴다는 것을 알려 주는 기록이기도 하다. 실제 설치는 오너가 기기마다 한 번 실행한다. 명령은 `claude plugin install waypoint@waypoint`(사용자 범위)다.

**CLAUDE.md의 waypoint 블록(모든 레포 공통, 5줄 내외):**
- 이 레포는 waypoint 플러그인으로 개발을 진행한다. 문서는 `docs/waypoint/`, 현황은 `docs/waypoint/STATUS.md`에 있다.
- 세션 시작 시 핵심 규칙이 주입되지 않았다면, 플러그인이 설치되지 않은 것이다. 이때는 작업 전에 오너에게 `claude plugin install waypoint@waypoint`를 안내한다.
- 커밋 메시지에 공동작업 트레일러를 넣지 않는다. 새로 클론했다면 `git config core.hooksPath .githooks`를 실행한다.
- STATUS.md와 DECISIONS.md는 메인 체크아웃(`<경로>`)에서 기본 브랜치로 바로 커밋한다. 스테이지 문서와 Build Spec은 작업 브랜치에 싣는다(9절).

레포 고유의 기존 규칙(예: tokens-are-running-out의 제품 설명)은 그대로 둔다. `docs/dlc`를 언급하는 문장만 새 경로로 바꾼다. 지금 CLAUDE.md가 없는 duty와 shadow에는 waypoint 블록만 넣은 CLAUDE.md를 새로 만든다.

**commit-msg 훅:** 각 레포의 `.githooks/`에 사본을 두고 `core.hooksPath .githooks`를 쓴다. 플러그인의 PreToolUse 훅으로 막는 방식은 쓰지 않는다. Claude가 `-F 파일`로 커밋하거나 오너가 터미널에서 직접 커밋하는 경우를 잡지 못하기 때문이다. app-factory는 이미 `.githooks/`가 있으므로 그대로 둔다.

### 5.5 이전 절차

**순서:** shadow → tokens-are-running-out → duty → app-factory → forin
- 열린 PR과 진행 중인 브랜치가 정리된 레포만 이전한다(9절). 위 순서는 준비된 레포가 여럿일 때의 우선순위다.
- 작고 참조가 적은 레포부터 진행한다. shadow로 절차를 검증한다. shadow는 이전 전에 미커밋 문서 5개를 waypoint에 먼저 커밋한다(9절).
- forin은 코드·테스트·CI 참조와 용량이 가장 크므로 마지막에 한다.

**0단계: 플러그인 준비(waypoint 레포)**
1. 5.1~5.3의 구조를 만든다. 이 단계에서는 `projects/`와 기존 `FRAMEWORK.md`, `_templates/`를 지우지 않는다. 이전이 끝나지 않은 레포가 아직 submodule로 읽기 때문이다.
   - 새 `templates/`는 `_templates/`의 사본으로 시작한다.
   - 기존 `FRAMEWORK.md`는 파일 맨 위에 「플러그인으로 이전 중. 규칙 원본은 `skills/`와 `core-rules.md`」라는 한 줄을 붙여 둔다. 사람용 개요로 바꾸는 작업은 5단계에서 한다.
2. 로컬 검증 순서:
   - `claude plugin validate`로 플러그인 구조를 검사한다.
   - `claude --plugin-dir <waypoint 경로>`로 shadow 레포에서 세션을 띄운다.
   - SessionStart 훅이 핵심 규칙을 주입하는지, 스킬이 목록에 뜨는지 확인한다.
   - waypoint를 쓰지 않는 디렉터리에서는 훅이 아무것도 출력하지 않는지 확인한다.
3. **waypoint에 PR로 올린다.** 브랜치 이름은 `feat/plugin`이고, PR 본문에 5.2절의 대조표를 넣는다. 플러그인은 `version`을 생략해 기본 브랜치의 커밋을 따라가므로, 이 PR을 머지하는 순간이 곧 적용 시점이다. 그래서 오너가 대조표를 검토하고 머지한다. 이 단계에서는 `projects/`를 건드리지 않으므로, 다른 세션의 문서 커밋과 충돌하지 않는다.
4. 머지된 뒤 `claude plugin marketplace add bingoring/waypoint`와 `claude plugin install waypoint@waypoint`로 설치한다.

**레포별 이전(각 레포에 같은 절차를 적용한다)**

사전 조건:
- 그 프로젝트의 waypoint 문서 변경이 모두 waypoint `master`에 push되어 있어야 한다. 레포의 submodule 체크아웃과 그 레포의 모든 worktree에서 `git -C <submodule 경로> status`를 실행해, 커밋되지 않은 문서가 없는지 확인한다. 있으면 이전을 시작하지 않고 오너에게 알린다. 예: 2026-11-24 기준 shadow의 `docs/dlc`에는 2026-07-10에 작성된 미커밋 문서 5개가 있다.
- 9절의 「진행 중인 PR과 브랜치」 처리 방침에 따라 이 레포를 이전할 시점인지 확인한다.
- 그 레포와 그 프로젝트 문서를 건드리는 다른 세션이 없어야 한다. 이전하는 세션이 오너에게 「지금 <레포>에서 작업 중인 다른 세션이 있으면 멈춰 달라」고 확인받고 시작한다.

절차:
1. **문서를 이력과 함께 떼어 낸다.** waypoint를 임시 디렉터리에 새로 클론한다. 그 클론에서 `projects/<name>/`의 이력만 남기고 경로를 `docs/waypoint/`로 바꾼 브랜치를 만든다. 도구는 `git filter-repo --subdirectory-filter projects/<name> --to-subdirectory-filter docs/waypoint`를 쓰고, 없으면 `git subtree split --prefix=projects/<name>`을 쓴다. 어느 도구를 쓸지는 구현자가 정한다.
2. **프로젝트 레포의 기본 브랜치에 새 브랜치를 만든다.** 브랜치 이름은 `chore/waypoint-plugin`이다.
3. **submodule을 제거한다.** `git submodule deinit -f <경로>`, `git rm -f <경로>`를 실행하고 `.git/modules/<경로>`도 정리한다.
4. **1의 브랜치를 가져와 합친다.** `git merge --allow-unrelated-histories`를 쓴다. 이 merge는 「base를 기능 브랜치에 merge하지 않는다」는 브랜치 규칙의 대상이 아니다. 관계없는 이력을 들여오는 일회성 작업이다. 커밋 메시지에 그 사실을 적는다.
5. **경로를 바꾼다.** 레포 전체에서 경로 참조를 일괄 치환하고, 치환 결과를 사람이 읽고 확인한다.
   - `docs/dlc/projects/<name>/` → `docs/waypoint/`
   - duty는 `waypoint/projects/duty/` → `docs/waypoint/`
   - `docs/dlc/FRAMEWORK.md`나 `_templates`를 가리키던 참조는 플러그인 스킬 이름이나 README 링크로 바꾼다.
   - `docs/waypoint/` 안의 문서끼리 걸린 상대 링크는 그대로 유지된다.
   - 문서 안에서 `../../FRAMEWORK.md`, `../../_templates/` 같은 waypoint 루트 참조가 나오면 플러그인 스킬 이름으로 바꾼다.
6. **5.4의 settings.json, `.githooks/`, CLAUDE.md 블록을 넣고 `core.hooksPath`를 설정한다.**
7. **CI의 `submodules: true`를 제거한다.** forin의 세 워크플로가 대상이다. 다른 submodule이 없다면 이 옵션은 더 필요 없다.
8. **검증한다.**
   - `grep -r 'docs/dlc'`와 `grep -r 'waypoint/projects'`의 결과가 0건이어야 한다. 다음은 역사 기록이므로 예외다. 예외로 둔 항목은 PR 본문에 적는다.
     - `docs/waypoint/` 안의 과거 기록(DECISIONS 등)에 남은 언급
     - `docs/superpowers/plans/` 같은 과거 계획 문서(forin, duty)
   - 위 grep 패턴으로 잡히지 않는 참조도 확인한다.
     - duty: `.dockerignore`, `.prettierignore`의 `waypoint` 항목, `ci.yml`의 「문서 전용 변경」 판정 경로
     - 그 밖에 `waypoint`만 단독으로 쓴 경로 항목(`grep -rw waypoint`로 찾고 하나씩 판단)
   - 레포의 빌드와 테스트가 통과해야 한다. forin은 `nbMotion.test`와 `ficons.test`를 포함한다.
   - 새 세션에서 SessionStart 훅이 핵심 규칙을 주입하는지 확인한다.
9. **PR을 열고, 오너가 머지한다.**
   - PR 본문에 「merge commit으로 머지할 것. squash하면 보존한 이력이 사라진다」고 적는다.
   - 머지 직전에 waypoint `master`에 이 프로젝트의 새 커밋이 들어왔는지 확인한다(`git log <떼어 낸 시점>..origin/master -- projects/<name>`). 있으면 1번부터 다시 떼어 내서 PR을 갱신한다.
10. **waypoint 쪽을 막는다.** waypoint에서 `projects/<name>/`의 내용을 지우고 `MOVED.md` 한 장만 남긴다. MOVED.md에는 새 위치, 이전 커밋 해시, 이전 날짜를 적는다. 이렇게 하면 옛 브랜치에서 작업하던 세션이 `docs/dlc/projects/<name>/`에 다시 쓰려 해도 문서가 없어서 바로 드러난다.

**진행 중인 기능 브랜치:** 이전 시점은 9절의 방침을 따른다. 이전 뒤에도 남는 브랜치는 아래처럼 처리한다. 2026-11-24 기준 현황은 다음과 같다.
- forin: 열린 PR 7개(#32·#33은 master 대상, #34~#38은 #33 위에 쌓임). `content/or-batch6`은 master보다 55커밋 앞서 있다. 메인 체크아웃에 미커밋 yaml 변경이 있다.
- app-factory: #23이 #22 위에 쌓여 있고 #24가 따로 있다. worktree 4개, worktree 없는 미머지 브랜치 2개(golf-proto, target-families)가 있다.
- duty: `feature/3-13-cutover-monitoring`에서 운영 서버리스 전환이 진행 중이다.
- tokens-are-running-out: 에이전트 worktree 브랜치 2개가 머지되지 않았다.

남는 브랜치의 처리:
- 이 브랜치들은 이전 PR이 머지된 뒤 기본 브랜치에 rebase한다.
- 브랜치가 submodule 포인터를 바꾼 커밋은 rebase 중 충돌한다. 이때는 포인터 변경을 버린다. 해당 문서 변경은 사전 조건에 따라 이미 waypoint `master`에 있었으므로, 이전된 `docs/waypoint/`에 들어와 있다.
- 브랜치의 코드에 새로 추가된 `docs/dlc` 참조는 rebase 뒤에 5번 치환을 다시 적용한다.
- 이 처리는 이전을 맡은 세션이 직접 하지 않는다. 각 브랜치를 맡은 세션이나 오너가 할 일로 PR 본문에 적는다.

**5단계: 마무리(waypoint 레포)**
- 다섯 레포가 모두 이전되면 `projects/`, `_templates/`, `STATUS.template.md`, 루트 `.githooks/`를 지운다. 플러그인 쪽에는 이미 `templates/`, `githooks/`가 있다.
- `FRAMEWORK.md`를 사람용 개요와 스킬 색인으로 바꾼다.
- `README.md`의 「새 프로젝트에 적용하기」를 플러그인 설치와 `waypoint:init` 사용법으로 바꾼다.
- 플러그인을 고치는 세션용 `CLAUDE.md`를 다시 쓴다. 이 문서에는 커밋 규칙과 「규칙 원본은 `skills/`와 `core-rules.md`」라는 안내를 넣는다.

### 5.6 `waypoint:init` 스킬

새 프로젝트를 시작할 때 쓴다. 기존 README의 submodule 안내를 대체한다. 동작은 다음과 같다.
1. `docs/waypoint/{01-inception,02-construction,03-operations}`를 만든다.
2. 템플릿에서 STATUS.md와 DECISIONS.md를 만든다.
3. 5.4의 settings.json 항목, `.githooks/commit-msg`, CLAUDE.md 블록을 넣는다.
4. `git config core.hooksPath .githooks`를 실행한다.

Notion 페이지 URL을 받는 일은 4단계에서 이 스킬에 추가한다.

## 6. 오너가 정한 것

- 진행 상태의 원본은 md다(2026-11-24).
- waypoint는 개인 프로젝트 전용이다(2026-11-24).
- 1단계 방식은 플러그인 전환이다(2026-11-24).
- 이전 뒤 STATUS와 DECISIONS는 기본 브랜치로 바로 가고, 나머지 문서는 기능 브랜치와 PR로 간다(2026-11-24, 9절).
- 열린 PR과 진행 중인 브랜치가 정리된 레포부터 이전한다(2026-11-24, 9절).
- shadow의 미커밋 문서 5개는 살려서 이전한다(2026-11-24, 9절).

## 7. 설계자가 정한 것 (오너 확인 필요)

- 프로젝트 문서 위치는 `docs/waypoint/`로 한다.
- 문서 이력은 filter-repo나 subtree로 보존한다. 단순 복사는 waypoint에만 이력이 남아서, 각 레포에서 `git log`나 `blame`으로 결정의 경위를 따라갈 수 없기 때문이다.
- 플러그인 `version`은 생략해서 커밋을 따라가게 한다. 혼자 쓰므로 릴리스마다 버전을 올리는 절차는 비용만 크다.
- 핵심 규칙은 플러그인 SessionStart 훅으로 주입하고, 각 레포 CLAUDE.md에는 5줄 내외만 둔다.
- commit-msg 훅은 레포마다 사본을 둔다. 플러그인 PreToolUse 훅은 쓰지 않는다.
- 이전 순서는 shadow, tokens-are-running-out, duty, app-factory, forin 순으로 한다. 단, 9절의 이전 시점 방침이 이 순서보다 우선한다.
- 0단계(규칙 나누기)는 waypoint에 PR로 올리고, 오너가 대조표를 검토한 뒤 머지한다.
- 이전 때문에 사실이 아니게 된 규칙 문장(서브모듈 관련)은 새 흐름에 맞게 고쳐 쓰고 대조표에 표시한다.

## 8. 구현자에게 맡기는 것

- filter-repo와 subtree 중 어느 도구를 쓸지.
- 스킬 본문의 세부 구성. 단 5.2의 「한 문장은 한 곳에」 원칙과 대조표는 지킨다.
- `session-context.sh`의 출력 형식.
- 각 레포 PR의 커밋 분할 방식. 이 경우에도 공동작업 트레일러는 넣지 않는다.

## 9. 빌더 점검에서 나온 질문과 오너의 답 (2026-11-24)

**이전 뒤 문서 커밋 흐름: 공유 문서만 기본 브랜치로 보낸다.**
- **STATUS.md와 DECISIONS.md:** 기본 브랜치에 바로 커밋하고 push한다. 기능 브랜치의 worktree에서 일하는 세션은 다음 순서로 처리한다.
  1. 메인 체크아웃 경로에서 `git -C <메인 체크아웃> pull --rebase`로 최신화한다.
  2. 그 경로의 파일을 고친다.
  3. 커밋하고 push한다.
  - 이 두 파일을 읽을 때도 메인 체크아웃 경로의 것을 읽는다. 기능 브랜치에 있는 사본은 브랜치를 만든 시점의 상태라서 낡았을 수 있다.
- **스테이지 문서, Build Spec, 리뷰 문서:** 그 작업의 기능 브랜치에 실어 PR과 함께 머지한다.
- **반영할 곳:** 이 규칙은 `core-rules.md`(한 줄)와 `skills/git`(자세한 절차)에 넣는다. FRAMEWORK의 서브모듈 관련 문장(5.2절)은 이 규칙으로 고쳐 쓴다. 각 레포 CLAUDE.md의 waypoint 블록에도 한 줄 넣는다.
- **3단계와의 관계:** 3단계에서는 중재자 세션이 메인 체크아웃에서 STATUS를 혼자 쓰는 구조로 이어진다.

**진행 중인 PR과 브랜치: PR이 정리된 레포부터 이전한다.**
- 열린 PR과 진행 중인 기능 브랜치가 모두 머지된 레포만 이전한다. 5.5절의 순서(shadow → tokens-are-running-out → duty → app-factory → forin)는 준비된 레포가 여럿일 때의 우선순위로만 쓴다.
- 0단계에서는 waypoint의 `projects/`를 지우지 않는다. 그래서 아직 이전하지 않은 레포는 그동안 submodule을 그대로 쓴다. 플러그인을 설치한 뒤에도 그런 레포에는 `docs/waypoint/STATUS.md`가 없어서 SessionStart 훅이 조용하다. 따라서 옛 방식과 충돌하지 않는다.
- 2026-11-24 기준으로 바로 이전할 수 있는 레포는 shadow다. tokens-are-running-out은 에이전트 worktree 브랜치 2개가 정리되어야 하고, duty는 서버리스 전환 브랜치가 머지되어야 한다. app-factory와 forin은 쌓인 PR이 머지되어야 한다.
- 5단계(waypoint 마무리)는 다섯 레포가 모두 이전된 뒤에 한다. forin이 늦어지면 5단계도 함께 늦어진다.

**shadow의 미커밋 문서: 살려서 이전한다.**
- shadow 이전 전에 `shadow/docs/dlc`의 미커밋 문서 5개를 waypoint `master`에 커밋하고 push한다. 이 체크아웃은 detached HEAD이고 origin/master보다 29커밋 뒤처져 있다. 그래서 바로 커밋하지 않고, 최신 master를 받은 뒤 그 위에 다시 적용한다. 대상 문서는 다음과 같다.
  - 새 파일: `prd.md`, `prd-tech.md`, `DECISIONS.md`
  - 수정: `STATUS.md`, `01-inception/01-context-synthesis.md`
- 커밋 메시지는 2026-07-10에 작성된 문서를 뒤늦게 커밋한다는 사실을 밝힌다.

## 10. 미확인 사항

- `SessionStart` 훅의 `compact` matcher가 자동 compact 직후에 실제로 실행되어 주입 내용이 남는지는 문서로만 확인했다(공식 확인, 실측 전). 0단계 로컬 검증에서 `/compact`를 실행해 확인한다.
- 마켓플레이스 자동 업데이트를 켰을 때 갱신 주기는 확인하지 못했다(미확인). 반영이 늦으면 `claude plugin marketplace update waypoint`를 수동으로 실행한다.
