#!/bin/sh
# 플러그인 파일(스킬·core-rules·템플릿·commit-msg 훅)을 검사한다.
# 실행: sh tests/plugin-files.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
P=plugin
SKILLS="start stage build-spec review-gate decisions git worker mediator"
GUARD='docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다'
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

# skills-exist: 여섯 스킬 파일이 모두 있다.
for s in $SKILLS; do
  [ -f "$P/skills/$s/SKILL.md" ] || fail skills-exist "$P/skills/$s/SKILL.md 없음"
done

# skills-have-guard: 여섯 스킬 모두 옛 방식 레포를 위한 안내문을 담고 있다.
for s in $SKILLS; do
  [ -f "$P/skills/$s/SKILL.md" ] || continue
  grep -qF -e "$GUARD" "$P/skills/$s/SKILL.md" || fail skills-have-guard "$s 에 안내문 없음"
done

# core-rules-size: core-rules.md 가 있고 40줄 이하이며 첫 줄이 정해진 제목이다.
if [ -f "$P/core-rules.md" ]; then
  n=$(wc -l < "$P/core-rules.md" | tr -d ' ')
  [ "$n" -le 40 ] || fail core-rules-size "$n 줄 (40 초과)"
  first=$(head -n 1 "$P/core-rules.md")
  [ "$first" = "# waypoint 핵심 규칙" ] || fail core-rules-size "첫 줄 '$first'"
else
  fail core-rules-size "$P/core-rules.md 없음"
fi

# no-old-paths: core-rules 와 스킬에 옛 경로가 없다(안내문 줄은 제외).
# init 스킬은 옛 방식 레포를 알아보려고 docs/dlc 를 일부러 언급하므로 제외한다.
for f in "$P/core-rules.md" "$P"/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  [ "$f" = "$P/skills/init/SKILL.md" ] && continue
  hits=$(grep -vF -e "$GUARD" "$f" | grep -nE '_templates/|docs/dlc')
  [ -z "$hits" ] || fail no-old-paths "$f: $hits"
done

# framework-split: FRAMEWORK.md 의 모든 줄이 정확히 한 곳에 있거나 대조표에 적혀 있다.
MAP=docs/superpowers/specs/2026-11-24-framework-split-map.md
if [ -f "$MAP" ]; then
  # shellcheck disable=SC2086
  out=$(sh tests/check-framework-split.sh FRAMEWORK.md "$MAP" "$P/core-rules.md" "$P"/skills/*/SKILL.md) \
    || fail framework-split "$out"
else
  fail framework-split "$MAP 없음"
fi

# templates-copied: _templates/ 의 모든 파일이 plugin/templates/ 에 같은 상대 경로로 있고, STATUS 템플릿도 있다.
for f in $(cd _templates && find . -type f | sed 's#^\./##'); do
  [ -f "$P/templates/$f" ] || fail templates-copied "$P/templates/$f 없음"
done
[ -f "$P/templates/STATUS.template.md" ] || fail templates-copied "$P/templates/STATUS.template.md 없음"

# templates-no-old-ref: 플러그인 템플릿이 옛 경로나 FRAMEWORK를 가리키지 않는다.
if [ -d "$P/templates" ]; then
  hits=$(grep -rnE '_templates|FRAMEWORK' "$P/templates")
  [ -z "$hits" ] || fail templates-no-old-ref "$hits"
fi

# block-and-settings: CLAUDE.md 블록과 프로젝트 설정 템플릿.
B="$P/templates/claude-md-block.md"
if [ -f "$B" ]; then
  grep -qF '## Waypoint' "$B" || fail block-and-settings "블록에 '## Waypoint' 없음"
  grep -qF 'docs/waypoint/STATUS.md' "$B" || fail block-and-settings "블록에 STATUS 경로 없음"
else
  fail block-and-settings "$B 없음"
fi
python3 -m json.tool "$P/templates/project-settings.json" > /dev/null 2>&1 \
  || fail block-and-settings "project-settings.json 이 없거나 JSON이 아님"
grep -qF '"waypoint@waypoint": true' "$P/templates/project-settings.json" 2>/dev/null \
  || fail block-and-settings "enabledPlugins 항목 없음"

# commit-msg: 공동작업 트레일러가 든 메시지는 거부하고, 일반 메시지는 받는다.
H="$P/githooks/commit-msg"
if [ -x "$H" ]; then
  M=$(mktemp)
  printf 'feat: x\n\nCo-Authored-By: A <a@b>\n' > "$M"
  sh "$H" "$M" 2>/dev/null && fail commit-msg-rejects "Co-Authored-By 메시지를 받아들임"
  printf 'feat: x\n\n\360\237\244\226 Generated with [Claude Code](https://claude.com/claude-code)\n' > "$M"
  sh "$H" "$M" 2>/dev/null && fail commit-msg-rejects-2 "Generated with 메시지를 받아들임"
  printf 'feat: x\n' > "$M"
  sh "$H" "$M" 2>/dev/null || fail commit-msg-accepts "일반 메시지를 거부함"
  rm -f "$M"
else
  fail commit-msg-rejects "$H 없음 또는 실행 권한 없음"
fi

# hook-block-match: pre-commit 훅의 검사 블록이 status-check.sh의 블록과 글자 그대로 같다.
# 훅은 각 레포의 .githooks/에 사본으로 들어가므로, 블록을 고치면 훅도 같이 고치고 둘째 줄의 버전을 올린다.
PC="$P/githooks/pre-commit"
SC="$P/scripts/status-check.sh"
block() { sed -n '/^# >>> waypoint status-check >>>$/,/^# <<< waypoint status-check <<<$/p' "$1"; }
if [ -x "$PC" ] && [ -f "$SC" ]; then
  b1=$(block "$SC"); b2=$(block "$PC")
  [ -n "$b1" ] || fail hook-block-match "$SC 에 검사 블록이 없음"
  [ "$b1" = "$b2" ] || fail hook-block-match "$PC 의 검사 블록이 $SC 와 다름"
  second=$(sed -n 2p "$PC")
  case $second in
    '# waypoint-hook-version: '[0-9]*) ;;
    *) fail hook-block-match "$PC 둘째 줄이 버전 줄이 아님: $second" ;;
  esac
else
  fail hook-block-match "$PC(실행 권한) 또는 $SC 없음"
fi

# init-skill: init 스킬이 있고 블록과 설정 템플릿을 쓴다.
I="$P/skills/init/SKILL.md"
if [ -f "$I" ]; then
  grep -qF 'claude-md-block.md' "$I" || fail init-skill "claude-md-block.md 언급 없음"
  grep -qF 'project-settings.json' "$I" || fail init-skill "project-settings.json 언급 없음"
else
  fail init-skill "$I 없음"
fi

# has <검사 이름> <파일> <문자열>: 파일에 문자열이 있어야 한다.
has() { grep -qF -e "$3" "$2" 2>/dev/null || fail "$1" "$2 에 '$3' 없음"; }

# git-doc-flow: git 스킬에 설계 9절의 문서 커밋 절차가 있다(메인 체크아웃 확인 → pull --rebase → 고치고 커밋·push, 읽기도 메인 체크아웃).
G="$P/skills/git/SKILL.md"
has git-doc-flow "$G" '### 문서 커밋 흐름(STATUS·DECISIONS·핸드오프)'
has git-doc-flow "$G" 'branch --show-current'
has git-doc-flow "$G" 'pull --rebase'
has git-doc-flow "$G" '읽을 때도 메인 체크아웃'
has git-doc-flow "$P/core-rules.md" '메인 체크아웃의 `docs/waypoint/DECISIONS.md`'
has git-doc-flow "$P/skills/decisions/SKILL.md" '메인 체크아웃의 `docs/waypoint/DECISIONS.md`'

# git-buildspec-handoff: 2-15에서 빠졌던 Build Spec 체크포인트 문장과 핸드오프 위치가 있다.
has git-buildspec-handoff "$G" 'Build Spec은 코드와 같은 체크포인트에서 함께 커밋'
has git-buildspec-handoff "$G" '`docs/waypoint/inputs/`'

# start-calls-skills: start 스킬이 AI Proposal 전에 부를 스킬을 안내한다.
S0="$P/skills/start/SKILL.md"
has start-calls-skills "$S0" '`waypoint:stage`'
has start-calls-skills "$S0" '`waypoint:build-spec`'
has start-calls-skills "$S0" '`waypoint:review-gate`'

# init-precheck: init 스킬이 옛 방식 레포와 이미 연결된 레포에서 멈춘다.
has init-precheck "$I" '.gitmodules'
has init-precheck "$I" '이미 있으면 멈추고'

# block-outside-repo: CLAUDE.md 블록이 「레포 밖에서 시작한 세션」 가능성을 함께 안내한다.
has block-outside-repo "$B" '레포 밖에서 시작'

# status-template-valid: 새 STATUS 템플릿이 형식 검사(검사 1~10)를 통과한다.
W=$(mktemp -d)
sed 's/{Project Name}/x/' "$P/templates/STATUS.template.md" > "$W/STATUS.md"
: > "$W/ids"
out=$(sh "$SC" "$W/STATUS.md" "$W/ids" 2>&1) || fail status-template-valid "$out"
rm -rf "$W"

# stage-templates: 스테이지 문서 템플릿은 상태를 들고 있지 않고(id: 만), 승인 결과를 계획·결과로 나누고, 진행 기록을 둔다.
for f in "$P/templates/stage-template.md" "$P/templates/review-stage-template.md"; do
  case $(sed -n 2p "$f") in
    'id: '*) ;;
    *) fail stage-templates "$f: frontmatter 첫 키가 id: 가 아님" ;;
  esac
  grep -qE '^(status|updated):' "$f" && fail stage-templates "$f: status:/updated: 가 남아 있음"
  grep -qF 'HUMAN_APPROVED' "$f" && fail stage-templates "$f: HUMAN_APPROVED 로 바꾸라는 안내가 남아 있음"
  has stage-templates "$f" '## 진행 기록'
  has stage-templates "$f" '#### 계획 승인 (YYYY-MM-DD, 결정자)'
  has stage-templates "$f" '#### 결과 승인 (YYYY-MM-DD, 결정자)'
done

# stage-states / stage-no-old: stage 스킬에 2단계의 상태 값·STATUS 표·진행 기록 규칙이 있고 옛 갱신 문장이 없다.
ST="$P/skills/stage/SKILL.md"
for want in '| `MERGED` | 머지됨 |' '| `DEFERRED` | 보류 |' '| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |' \
  '`계획 검토: `' '`결과 검토: `' '80자' '## STATUS 표' '## 진행 기록' 'docs(status)'; do
  has stage-states "$ST" "$want"
done
grep -qF 'STATUS.md의 테이블을 함께 업데이트' "$ST" && fail stage-no-old "옛 STATUS 갱신 문장이 남아 있음"

# core-rules-new: core-rules의 세 규칙이 2단계 문장으로 바뀌었고 줄 수가 늘지 않았다.
CR="$P/core-rules.md"
has core-rules-new "$CR" '앞 스테이지의 계획이 승인되기 전에는'
has core-rules-new "$CR" '스테이지 상태의 원본은 메인 체크아웃'
has core-rules-new "$CR" '메인 체크아웃은 기본 브랜치에 둔다'
grep -qF '`HUMAN_APPROVED` 없이는' "$CR" && fail core-rules-new "옛 HUMAN_APPROVED 규칙이 남아 있음"
n=$(wc -l < "$CR" | tr -d ' ')
[ "$n" -le 19 ] || fail core-rules-new "$n 줄 (19 초과)"

# start-new: start 스킬이 세션 시작 요약과 PR 상태 확인으로 시작하고, 옛 「PENDING인 가장 앞 스테이지」 절차가 없다.
has start-new "$S0" '`gh pr view`'
grep -qF 'PENDING` 상태인 가장 앞 스테이지를 찾는다' "$S0" && fail start-new "옛 시작 절차가 남아 있음"

# git-new: git 스킬에 스테이지 브랜치·PR·worktree 흐름, STATUS 커밋 메시지, pre-commit 검사가 있다.
for want in '### 스테이지 브랜치와 PR' 'worktree add' 'git worktree remove' '[작업 중]' \
  '`docs(status): <ID> <새 상태>`' 'WAYPOINT_ALLOW_BRANCH_STATUS=1' '### pre-commit 검사'; do
  has git-new "$G" "$want"
done

# init-new: init 스킬이 pre-commit 훅도 복사하고, 첫 스테이지를 정하지 않고 오너와 정한다.
has init-new "$I" 'githooks/pre-commit'
grep -qF '첫 스테이지(1-1)를 시작한다' "$I" && fail init-new "옛 마무리 문장이 남아 있음"

# review-fixes: 독립 리뷰에서 고친 문장들.
has review-fixes "$I" '메인 체크아웃의 기본 브랜치에서'
has review-fixes "$G" '`<메인>/.githooks/pre-commit`'
grep -qF 'HUMAN_APPROVED`로 변경' "$P/templates/gate-template.md" && fail review-fixes "gate-template에 옛 HUMAN_APPROVED 안내가 남아 있음"
has review-fixes "$ST" 'R-1)의 결과가 승인된 뒤에 시작한다'

# worker-skill: 작업 세션 스킬에 3단계의 보고·질문·머지 준비 형식과 금지 규칙이 있다(설계 5.2·5.4·5.5·5.11절).
W="$P/skills/worker/SKILL.md"
for want in '중재자가 시작한 작업 세션' \
  '[<ID> <상태>] <지금> | 기다림: <기다림> | PR: <링크>' \
  '[<ID> 머지 준비] <한 줄> | PR: <링크> | 문서: <스테이지 문서 경로>' \
  '[<ID> 질문] <정해야 할 것> / <선택지와 추천> / <찾아본 문서>' \
  '오너 직접 결정:' '보내지 말라고 하지만' 'STATUS와 DECISIONS를 고치지 않는다' 'gh pr edit' \
  '## 첫 턴' '## 보고' '## 질문' '## 머지 준비'; do
  has worker-skill "$W" "$want"
done
grep -qF 'gh pr merge' "$W" 2>/dev/null && fail worker-skill "작업 세션 스킬에 gh pr merge 가 있음(머지는 중재자가 한다)"
# worker-scope: 적용 범위(중재자가 시작한 작업 세션만)가 스킬 앞부분에 있다.
head -n 12 "$W" 2>/dev/null | grep -qF '중재자가 시작한 작업 세션' || fail worker-scope "스킬 앞부분에 적용 범위가 없음"
# worker-brief: 지시문 템플릿에 스테이지마다 다른 자리와 스킬을 다시 읽으라는 문장이 있다.
WB="$P/templates/worker-brief-template.md"
for want in '{ID}' '{스테이지 이름}' '{줄기}' '{중재자 세션 id}' '{읽을 문서}' '{이어받기}' \
  '`waypoint:worker` 스킬을 먼저 읽고' 'compact된 뒤에도 다시 읽는다'; do
  has worker-brief "$WB" "$want"
done

# mediator-skill: 중재자 스킬에 설계 5.15절의 절과 절차가 있다.
M="$P/skills/mediator/SKILL.md"
for want in '## 시작 절차' '## 작업 세션 시작' '## 동시 진행 조절' '## 보고 처리' '## 질문 처리' \
  '## 검토 요청' '## 머지와 정리' '## compact 뒤' '## 처음 시작과 교체' \
  '"self"' 'list_sessions {"linked": true}' 'worker-brief-template.md' '그사이 생긴 일' \
  '10줄 이하' 'gh pr view' '오너의 말을 그대로 인용' '정보로만 쓰고'; do
  has mediator-skill "$M" "$want"
done
grep -F '`use_worktree`' "$M" 2>/dev/null | grep -qF '`true`' || fail mediator-skill "use_worktree 를 true 로 적는 줄이 없음"
# mediator-initiation: 보고 턴에서는 카드(own_initiative)로만 제안하고, 「승인」만 들은 턴도 카드다.
awk -v RS= '/보고 턴/ && /own_initiative/' "$M" 2>/dev/null | grep -q . || fail mediator-initiation "보고 턴과 own_initiative 가 같은 단락에 없음"
has mediator-initiation "$M" '「승인」만'
# mediator-cap: 검토 대기 상한 줄을 읽고, 없으면 3으로 본다.
has mediator-cap "$M" '검토 대기 상한:'
has mediator-cap "$M" '없으면 3'

# block-worktree: CLAUDE.md 블록이 worktree 규칙을 안내한다.
has block-worktree "$B" '메인 체크아웃은 늘 기본 브랜치에 둔다'

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
