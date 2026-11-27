# 보드 동기화 테스트의 공통 준비. tests/*.test.sh 에서 `. "$ROOT/tests/board-lib.sh"`로 읽는다.
# 가짜 gh(tests/fake-gh/gh)의 상태를 만들고 읽는 함수들.
#
# 상태 파일($FAKE_GH_DIR):
#   project.json  {"id","title","fields":[{"id","name","dataType","options":[{"id","name","color","description"}]}]}
#   items.json    [{"id","issue":<번호>,"isArchived":false,"values":{<필드 이름>: <글 또는 선택지 id>}}]
#   issues.json   [{"number","title","state":"OPEN|CLOSED","url","labels":[..],"body"}]
#   labels.json   ["waypoint", ...]
#   workflows.json [{"id","name","enabled"}]
#   views.json    [{"id","name","layout","visible":[<필드 id>]}] (없으면 가짜 gh가 빈 목록으로 만든다)

FAKE_REPO=test/repo
FAKE_URL=https://github.com/users/test/projects/1

# 안전장치: 테스트가 진짜 gh로 GitHub을 건드리지 않게, PATH의 gh가 가짜가 아니면 바로 멈춘다.
case $(command -v gh 2>/dev/null) in
  */tests/fake-gh/gh) ;;
  *) echo "STOP: PATH의 gh가 tests/fake-gh/gh가 아니다($(command -v gh)). 진짜 GitHub을 건드리지 않도록 멈춘다." >&2; exit 2 ;;
esac

# board_seed_project: waypoint 템플릿과 같은 필드를 가진 Project 상태를 만든다.
board_seed_project() {
  mkdir -p "$FAKE_GH_DIR"
  cat > "$FAKE_GH_DIR/project.json" <<'EOF'
{"id":"PVT_test","title":"repo 보드","number":1,"fields":[
 {"id":"F_TITLE","name":"Title","dataType":"TITLE"},
 {"id":"F_STATUS","name":"Status","dataType":"SINGLE_SELECT","options":[
  {"id":"s1","name":"대기","color":"GRAY","description":""},
  {"id":"s2","name":"진행 중","color":"BLUE","description":""},
  {"id":"s3","name":"검토 대기","color":"YELLOW","description":""},
  {"id":"s4","name":"승인","color":"GREEN","description":""},
  {"id":"s5","name":"머지됨","color":"PURPLE","description":""},
  {"id":"s6","name":"보류","color":"RED","description":""}]},
 {"id":"F_STEM","name":"줄기","dataType":"SINGLE_SELECT","options":[{"id":"t1","name":"앱","color":"GRAY","description":""}]},
 {"id":"F_NOW","name":"지금","dataType":"TEXT"},
 {"id":"F_WAIT","name":"기다림","dataType":"TEXT"},
 {"id":"F_PHASE","name":"단계","dataType":"SINGLE_SELECT","options":[
  {"id":"p1","name":"1","color":"GRAY","description":""},{"id":"p2","name":"2","color":"GRAY","description":""},
  {"id":"pR","name":"R","color":"GRAY","description":""},{"id":"p3","name":"3","color":"GRAY","description":""}]},
 {"id":"F_ID","name":"ID","dataType":"TEXT"}]}
EOF
  echo '[]' > "$FAKE_GH_DIR/items.json"
  echo '[]' > "$FAKE_GH_DIR/issues.json"
  echo '["bug"]' > "$FAKE_GH_DIR/labels.json"
  echo '[]' > "$FAKE_GH_DIR/workflows.json"
  echo '[]' > "$FAKE_GH_DIR/views.json"
  rm -f "$FAKE_GH_DIR/lag.json" "$FAKE_GH_DIR/lag-now.json"
  : > "$FAKE_GH_LOG"
}

# board_add_issue <번호> <제목> <OPEN|CLOSED> [본문]
board_add_issue() {
  jq --argjson n "$1" --arg t "$2" --arg s "$3" --arg b "${4:-본문}" --arg r "$FAKE_REPO" \
    '. + [{number:$n, title:$t, state:$s, url:("https://github.com/"+$r+"/issues/"+($n|tostring)), labels:["waypoint"], body:$b}]' \
    "$FAKE_GH_DIR/issues.json" > "$FAKE_GH_DIR/t" && mv "$FAKE_GH_DIR/t" "$FAKE_GH_DIR/issues.json"
}

# board_add_item <항목 id> <이슈 번호> <values JSON>  (단일 선택 값은 선택지 id)
board_add_item() {
  jq --arg i "$1" --argjson n "$2" --argjson v "$3" '. + [{id:$i, issue:$n, isArchived:false, values:$v}]' \
    "$FAKE_GH_DIR/items.json" > "$FAKE_GH_DIR/t" && mv "$FAKE_GH_DIR/t" "$FAKE_GH_DIR/items.json"
}

# board_card <ID>: 그 ID 카드의 값(선택지는 이름으로)과 이슈 상태·제목을 한 줄 JSON으로.
board_card() {
  jq -c --arg id "$1" --slurpfile p "$FAKE_GH_DIR/project.json" --slurpfile is "$FAKE_GH_DIR/issues.json" '
    ($p[0].fields | map({key:.name, value:(.options // [] | map({key:.id, value:.name}) | from_entries)}) | from_entries) as $opt
    | map(select(.values.ID == $id)) | .[0] // empty
    | . as $it | ($is[0] | map(select(.number == $it.issue)) | .[0]) as $iss
    | {issue:.issue, title:$iss.title, state:$iss.state,
       values:(.values | with_entries(.value = (if ($opt[.key] // {}) | length > 0 then ($opt[.key][.value] // null) else .value end)))}' \
    "$FAKE_GH_DIR/items.json"
}

# board_calls <패턴>: 가짜 gh 호출 기록에서 패턴(grep -E)이 든 줄 수
board_calls() { grep -cE -e "$1" "$FAKE_GH_LOG" 2>/dev/null || true; }
