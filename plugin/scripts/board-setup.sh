#!/bin/sh
# waypoint 보드 설정. waypoint 플러그인의 scripts/board-setup.sh.
#
#   sh board-setup.sh template <소유자>
#     「waypoint 보드 템플릿」 Project를 만든다. 소유자(사용자 또는 조직)마다 한 번만 실행한다.
#     Status 선택지 여섯 개, 필드 다섯 개(줄기, 지금, 기다림, 단계, ID), 기본 자동화 삭제, 표 보기와 보드 보기.
#     API로 할 수 없는 설정 세 가지는 끝에 출력한다. 오너가 GitHub 화면에서 하거나, 오너가 허락하면 AI가 앱의 브라우저로 한다.
#
#   sh board-setup.sh repo <레포 경로> <템플릿 주소> [<훅 사본 폴더>]
#     템플릿을 「<레포 이름> 보드」로 복사하고(비공개), CLAUDE.md waypoint 블록의 「검토 대기 상한」 줄 아래에
#     「- 보드: <주소>」 줄을 넣고, .githooks/에 pre-push와 board-sync.sh 사본을 넣은 뒤 Project를 레포에 연결한다.
#     커밋은 하지 않는다. 세션이 바뀐 파일을 waypoint:git대로 메인 체크아웃의 기본 브랜치에 커밋한다.
#     훅 사본 폴더를 빼면 이 스크립트가 있는 폴더에서 board-sync.sh와 pre-push를 찾는다(플러그인 안에서는 ../githooks/pre-push).
#
# 세션은 Bash에서 플러그인 경로를 모르므로, 이 파일과 githooks/pre-push, scripts/board-sync.sh를 Read 도구로 읽어
# 레포 밖의 같은 임시 폴더에 Write한 뒤 실행한다(waypoint:init).
# 설계: docs/superpowers/specs/2026-11-25-board-sync-design.md 5.10절(waypoint 레포).

set -u

BS_TITLE="waypoint 보드 템플릿"
# 단일 선택 필드는 선택지가 하나 이상 있어야 한다. 줄기에는 자리표시를 두고, 첫 동기화가 줄기를 더할 때 지운다(board-sync.sh).
BS_STEM_PLACEHOLDER="(없음)"
BS_URL_RE='^https://github\.com/(users|orgs)/[A-Za-z0-9._-]+/projects/[0-9]+/?$'
BS_HEADER='| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |'

bs_die() { echo "board-setup: $*" >&2; exit 1; }
bs_usage() {
  echo "쓰는 법: sh board-setup.sh template <소유자>" >&2
  echo "         sh board-setup.sh repo <레포 경로> <템플릿 주소> [<훅 사본 폴더>]" >&2
  exit 2
}
bs_tools() {
  command -v gh > /dev/null 2>&1 || bs_die "gh가 없다. GitHub CLI를 설치하고 gh auth login, gh auth refresh -s project를 실행한다"
  command -v jq > /dev/null 2>&1 || bs_die "jq가 없다"
}

BS_TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$BS_TMP"' EXIT

# bs_parse_url <주소>: BS_KIND(user|organization), BS_OWNER, BS_NUM을 정한다.
bs_parse_url() {
  printf '%s\n' "$1" | grep -Eq "$BS_URL_RE" || return 1
  _p=${1#https://github.com/}
  case $_p in users/*) BS_KIND=user ;; *) BS_KIND=organization ;; esac
  _p=${_p#*/}
  BS_OWNER=${_p%%/*}
  BS_NUM=${_p##*/projects/}
  BS_NUM=${BS_NUM%/}
}

# bs_read: BS_KIND·BS_OWNER·BS_NUM의 Project를 읽어 $BS_TMP/fields.json(이름 → 필드), workflows.json, views.json, pid를 만든다.
bs_read() {
  _q='query($owner: String!, $number: Int!) { OWNERKIND(login: $owner) { projectV2(number: $number) { id fields(first: 50) { nodes { ... on ProjectV2FieldCommon { id name dataType } ... on ProjectV2SingleSelectField { options { id name color description } } } } workflows(first: 50) { nodes { id name } } views(first: 20) { nodes { id name layout } } } } }'
  _q=$(printf '%s' "$_q" | sed "s/OWNERKIND/$BS_KIND/")
  gh api graphql -F owner="$BS_OWNER" -F number="$BS_NUM" -f query="$_q" > "$BS_TMP/read.json" || return 1
  _k=$BS_KIND
  jq -e --arg k "$_k" '.data[$k].projectV2.id' "$BS_TMP/read.json" > /dev/null || return 1
  jq -r --arg k "$_k" '.data[$k].projectV2.id' "$BS_TMP/read.json" > "$BS_TMP/pid"
  jq --arg k "$_k" '[.data[$k].projectV2.fields.nodes[] | select(.name != null) | {key: .name, value: .}] | from_entries' "$BS_TMP/read.json" > "$BS_TMP/fields.json"
  jq --arg k "$_k" '[.data[$k].projectV2.workflows.nodes[]]' "$BS_TMP/read.json" > "$BS_TMP/workflows.json"
  jq --arg k "$_k" '[.data[$k].projectV2.views.nodes[]]' "$BS_TMP/read.json" > "$BS_TMP/views.json"
}

# bs_ids <필드 이름>...: 필드 id들을 JSON 배열로 출력한다.
bs_ids() {
  jq -c '[$ARGS.positional[] as $n | .[$n].id]' --args "$@" < "$BS_TMP/fields.json"
}

bs_template() {
  [ $# -eq 1 ] || bs_usage
  _owner=$1
  bs_tools

  gh project create --owner "$_owner" --title "$BS_TITLE" --format json > "$BS_TMP/create.json" ||
    bs_die "Project를 만들지 못했다. gh auth status로 토큰에 project 권한이 있는지 확인한다(없으면 오너가 gh auth refresh -s project)"
  _url=$(jq -r .url "$BS_TMP/create.json")
  bs_parse_url "$_url" || bs_die "만든 Project의 주소를 알 수 없다: $(cat "$BS_TMP/create.json")"
  echo "만듦: $_url"
  _stop="여기서 멈췄다. 만든 Project($_url)를 GitHub에서 지운 뒤 다시 실행한다"
  bs_read || bs_die "만든 Project를 읽지 못했다. $_stop"

  # Status: 기본 선택지(Todo, In Progress, Done)의 id를 대기, 진행 중, 머지됨에 이어 쓰고 셋을 더한다.
  jq '.Status as $f
    | {"Todo": "대기", "In Progress": "진행 중", "Done": "머지됨"} as $m
    | ($f.options | map({key: ($m[.name] // .name), value: .id}) | from_entries) as $ids
    | [["대기", "GRAY"], ["진행 중", "BLUE"], ["검토 대기", "YELLOW"], ["승인", "GREEN"], ["머지됨", "PURPLE"], ["보류", "RED"]]
    | {query: "mutation($f: ID!, $o: [ProjectV2SingleSelectFieldOptionInput!]) { updateProjectV2Field(input: {fieldId: $f, singleSelectOptions: $o}) { projectV2Field { ... on ProjectV2SingleSelectField { options { id name } } } } }",
       variables: {f: $f.id, o: [.[] | {name: .[0], color: .[1], description: ""} + (if $ids[.[0]] then {id: $ids[.[0]]} else {} end)]}}' \
    "$BS_TMP/fields.json" > "$BS_TMP/status.json"
  gh api graphql --input "$BS_TMP/status.json" > /dev/null || bs_die "Status 선택지를 바꾸지 못했다. $_stop"

  # 필드 다섯 개
  for _f in "줄기:SINGLE_SELECT:$BS_STEM_PLACEHOLDER" "지금:TEXT:" "기다림:TEXT:" "단계:SINGLE_SELECT:1,2,R,3" "ID:TEXT:"; do
    _n=${_f%%:*}; _r=${_f#*:}; _t=${_r%%:*}; _o=${_r#*:}
    if [ -n "$_o" ]; then
      gh project field-create "$BS_NUM" --owner "$BS_OWNER" --name "$_n" --data-type "$_t" --single-select-options "$_o" --format json > /dev/null
    else
      gh project field-create "$BS_NUM" --owner "$BS_OWNER" --name "$_n" --data-type "$_t" --format json > /dev/null
    fi || bs_die "「$_n」 필드를 만들지 못했다. $_stop"
  done

  # 기본 자동화: 모두 지운다. Status는 동기화만 바꾼다(설계 5.3절).
  for _w in $(jq -r '.[].id' "$BS_TMP/workflows.json"); do
    jq -n --arg w "$_w" '{query: "mutation($w: ID!) { deleteProjectV2Workflow(input: {workflowId: $w}) { deletedWorkflowId } }", variables: {w: $w}}' > "$BS_TMP/wf.json"
    gh api graphql --input "$BS_TMP/wf.json" > /dev/null || bs_die "기본 자동화($_w)를 지우지 못했다. $_stop"
  done

  # 보기: 기본 표 보기는 「표」로 바꾸고 새 필드가 보이게 한다. 보드 보기를 만든다(열은 Status, 보이는 필드는 지금·기다림).
  bs_read || bs_die "필드를 만든 뒤 Project를 읽지 못했다. $_stop"
  _pid=$(cat "$BS_TMP/pid")
  _table=$(jq -r '[.[] | select(.layout == "TABLE_LAYOUT")][0].id // ""' "$BS_TMP/views.json")
  _tf=$(bs_ids Status 줄기 단계 지금 기다림 ID)
  if [ -n "$_table" ]; then
    jq -n --arg v "$_table" --argjson f "$_tf" '{query: "mutation($v: ID!, $name: String, $f: [ID!]) { updateProjectV2View(input: {viewId: $v, name: $name, configuration: {visibleFieldIds: $f}}) { projectV2View { id name layout } } }", variables: {v: $v, name: "표", f: $f}}' > "$BS_TMP/view.json"
  else
    jq -n --arg p "$_pid" --argjson f "$_tf" '{query: "mutation($p: ID!, $name: String!, $layout: ProjectV2ViewLayout!, $f: [ID!]) { createProjectV2View(input: {projectId: $p, name: $name, layout: $layout, configuration: {visibleFieldIds: $f}}) { projectV2View { id name layout } } }", variables: {p: $p, name: "표", layout: "TABLE_LAYOUT", f: $f}}' > "$BS_TMP/view.json"
  fi
  gh api graphql --input "$BS_TMP/view.json" > /dev/null || bs_die "표 보기를 설정하지 못했다. $_stop"
  jq -n --arg p "$_pid" --argjson f "$(bs_ids 지금 기다림)" '{query: "mutation($p: ID!, $name: String!, $layout: ProjectV2ViewLayout!, $f: [ID!]) { createProjectV2View(input: {projectId: $p, name: $name, layout: $layout, configuration: {visibleFieldIds: $f}}) { projectV2View { id name layout } } }", variables: {p: $p, name: "보드", layout: "BOARD_LAYOUT", f: $f}}' > "$BS_TMP/view.json"
  gh api graphql --input "$BS_TMP/view.json" > /dev/null || bs_die "보드 보기를 만들지 못했다. $_stop"

  _base=${_url%/}
  cat <<EOF

템플릿을 만들었다: $_base
GitHub 화면에서 할 일 세 가지(API로 설정할 수 없다. 복사본에 그대로 옮겨진다):
1. 「보드」 보기의 View 메뉴에서 Swimlanes를 「줄기」로 정하고 Save를 누른다.
2. $_base/workflows 에서 Auto-archive items를 켜고 필터를 「is:issue is:closed updated:<@today-14d」로 정한 뒤 저장한다.
3. 같은 화면의 「Sync with issue status」를 끈다(Status는 동기화만 바꾼다).
레포에 적용할 때 이 주소를 템플릿 주소로 쓴다: sh board-setup.sh repo <레포 경로> $_base
EOF
}

# bs_repo_name <origin 주소>: owner/repo를 출력한다(https, git@, ssh:// 모양).
bs_repo_name() {
  printf '%s\n' "$1" | sed -E -e 's#^(https://|ssh://git@|git@)github\.com[:/]##' -e 's#\.git$##' -e 's#/$##' |
    grep -E '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$'
}

# bs_hook_ok <파일>: waypoint 훅(둘째 줄이 버전 줄)인지 본다.
bs_hook_ok() { sed -n 2p "$1" | grep -q '^# waypoint-hook-version: '; }

bs_repo() {
  [ $# -eq 2 ] || [ $# -eq 3 ] || bs_usage
  _r=$1 _tpl=$2
  _src=${3:-$(cd "$(dirname "$0")" && pwd -P)}

  # 먼저 모두 확인한다. 하나라도 어긋나면 GitHub을 건드리지 않고 멈춘다.
  _top=$(git -C "$_r" rev-parse --show-toplevel 2> /dev/null) || bs_die "$_r 는 git 레포가 아니다"
  _md="$_top/CLAUDE.md"
  [ -f "$_md" ] || bs_die "CLAUDE.md가 없다. waypoint:init을 먼저 한다"
  grep -q '^- 검토 대기 상한:' "$_md" || bs_die "CLAUDE.md의 waypoint 블록에 「- 검토 대기 상한:」 줄이 없다. 플러그인의 claude-md-block.md대로 블록을 먼저 고친다"
  if _old=$(grep -m1 '^- 보드:' "$_md"); then
    bs_die "CLAUDE.md에 이미 보드 줄이 있다($_old). 이 레포는 이미 적용했다. 다시 하려면 그 줄과 Project를 먼저 정리한다"
  fi
  _st="$_top/docs/waypoint/STATUS.md"
  grep -qxF "$BS_HEADER" "$_st" 2> /dev/null || bs_die "docs/waypoint/STATUS.md가 없거나 새 형식이 아니다. STATUS를 먼저 새 형식으로 바꾼다(2단계 설계 5.8절)"
  bs_parse_url "$_tpl" || bs_die "템플릿 주소가 Project 주소가 아니다: $_tpl (예: https://github.com/users/<소유자>/projects/<번호>)"
  _tkind=$BS_KIND _towner=$BS_OWNER _tnum=$BS_NUM
  _repo=$(bs_repo_name "$(git -C "$_top" remote get-url origin 2> /dev/null)") || bs_die "origin이 GitHub 레포가 아니다"
  _owner=${_repo%%/*} _name=${_repo#*/}
  _pp="$_src/pre-push"
  [ -f "$_pp" ] || _pp="$_src/../githooks/pre-push"
  _bs="$_src/board-sync.sh"
  for _f in "$_pp" "$_bs"; do
    [ -f "$_f" ] && bs_hook_ok "$_f" || bs_die "훅 원본이 없거나 waypoint 훅이 아니다: $_f"
  done
  for _f in pre-push board-sync.sh; do
    if [ -e "$_top/.githooks/$_f" ] && ! bs_hook_ok "$_top/.githooks/$_f"; then
      bs_die ".githooks/$_f 가 이미 있고 waypoint 훅이 아니다. 기존 훅과 합치는 방법을 오너와 정한다(합친 파일의 둘째 줄에도 「# waypoint-hook-version: <번호>」가 있어야 한다)"
    fi
  done
  bs_tools

  # 1. 복사(비공개)
  gh project copy "$_tnum" --source-owner "$_towner" --target-owner "$_owner" --title "$_name 보드" --format json > "$BS_TMP/copy.json" ||
    bs_die "템플릿을 복사하지 못했다. 주소($_tpl)와 gh 토큰의 project 권한을 확인한다"
  _url=$(jq -r '.url // ""' "$BS_TMP/copy.json")
  _num=$(jq -r '.number // ""' "$BS_TMP/copy.json")
  _url=${_url%/}
  [ -n "$_url" ] && [ -n "$_num" ] || bs_die "복사본의 주소를 알 수 없다: $(cat "$BS_TMP/copy.json")"
  echo "복사함: $_url"

  # 2. CLAUDE.md: 「검토 대기 상한」 줄 바로 아래(waypoint 블록의 끝)에 보드 줄
  awk -v line="- 보드: $_url" '{ print } /^- 검토 대기 상한:/ && !done { print line; done = 1 }' "$_md" > "$BS_TMP/md" &&
    cat "$BS_TMP/md" > "$_md" || bs_die "CLAUDE.md를 고치지 못했다. 복사본($_url)은 남아 있다"

  # 3. 훅 사본
  mkdir -p "$_top/.githooks" &&
    cp "$_pp" "$_top/.githooks/pre-push" && cp "$_bs" "$_top/.githooks/board-sync.sh" &&
    chmod +x "$_top/.githooks/pre-push" "$_top/.githooks/board-sync.sh" || bs_die "훅 사본을 넣지 못했다"

  _changed="바뀐 파일(커밋하지 않았다): CLAUDE.md, .githooks/pre-push, .githooks/board-sync.sh"
  # 4. 레포에 연결. 실패해도 위의 일은 남기고 직접 연결하는 명령을 알린다.
  if ! gh project link "$_num" --owner "$_owner" --repo "$_repo" > /dev/null; then
    echo "$_changed"
    bs_die "Project를 레포에 연결하지 못했다. 나머지는 끝났다. 직접 연결한다: gh project link $_num --owner $_owner --repo $_repo"
  fi
  echo "연결함: $_repo"
  echo "$_changed"
  cat <<EOF
다음 할 일:
1. 바뀐 파일을 메인 체크아웃의 기본 브랜치에 커밋하고 push한다(waypoint:git). core.hooksPath가 .githooks인지 확인한다.
2. 첫 동기화: 레포 루트에서 sh .githooks/board-sync.sh 를 실행하고 .git/waypoint/board-sync.status 가 ok로 시작하는지 본다.
   MERGED가 아닌 줄마다 이슈가 만들어져 보드에 들어간다.
EOF
}

case ${1:-} in
  template) shift; bs_template "$@" ;;
  repo) shift; bs_repo "$@" ;;
  *) bs_usage ;;
esac
