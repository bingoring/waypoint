#!/bin/sh
# 보드 동기화 테스트용 가짜 gh(tests/fake-gh/gh)의 자기 시험.
# 실행: sh tests/fake-gh.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

export FAKE_GH_DIR="$T/state" FAKE_GH_LOG="$T/gh.log"
export PATH="$ROOT/tests/fake-gh:$PATH"
. "$ROOT/tests/board-lib.sh"
board_seed_project

Q='query($owner: String!, $number: Int!, $after: String) { user(login: $owner) { projectV2(number: $number) { id } } }'

# log: 모든 호출을 한 줄씩 기록한다.
gh label list -R "$FAKE_REPO" --json name --limit 200 > /dev/null
[ "$(board_calls '^label list -R test/repo')" = 1 ] || fail log "호출 기록 없음: $(cat "$FAKE_GH_LOG")"

# issue-create: 만든 이슈의 주소를 출력하고, 다음 issue list 에 나온다.
printf 'b\n' > "$T/body"
url=$(gh issue create -R "$FAKE_REPO" --title "[2-1] 시험" --label waypoint --body-file "$T/body")
[ "$url" = "https://github.com/test/repo/issues/1" ] || fail issue-create "주소: $url"
n=$(gh issue list -R "$FAKE_REPO" --label waypoint --state all --limit 1000 --json number,title,state,url | jq 'length')
[ "$n" = 1 ] || fail issue-create "목록 길이 $n"

# item-add / item-edit: 카드를 넣고 글·선택지·지우기를 반영한다.
item=$(gh project item-add 1 --owner test --url "$url" --format json | jq -r .id)
[ -n "$item" ] || fail item-add "id 없음"
gh project item-edit --project-id PVT_test --id "$item" --field-id F_ID --text "2-1"
gh project item-edit --project-id PVT_test --id "$item" --field-id F_STATUS --single-select-option-id s2
gh project item-edit --project-id PVT_test --id "$item" --field-id F_STEM --single-select-option-id t1
gh project item-edit --project-id PVT_test --id "$item" --field-id F_NOW --text "구현: x"
gh project item-edit --project-id PVT_test --id "$item" --field-id F_NOW --clear
card=$(board_card 2-1)
[ "$(printf '%s' "$card" | jq -r '.values.Status')" = "진행 중" ] || fail item-edit "Status: $card"
[ "$(printf '%s' "$card" | jq -r '.values["지금"] // "없음"')" = "없음" ] || fail item-edit "지우기 안 됨: $card"

# graphql-read: Project 읽기 응답의 모양이 실제 응답(픽스처)과 같은 경로를 쓴다.
gh api graphql -F owner=test -F number=1 -f query="$Q" > "$T/read.json"
norm='[paths | map(if type=="number" then 0 else . end) | map(tostring) | join(".")] | unique | .[]'
jq -r "$norm" "$ROOT/tests/fixtures/board/project-graphql.json" | sort -u > "$T/real.paths"
jq -r "$norm" "$T/read.json" | grep -vE '\.(color|description|isArchived|number|dataType)$' | grep -vE 'pageInfo' | sort -u > "$T/fake.paths"
extra=$(comm -13 "$T/real.paths" "$T/fake.paths")
[ -z "$extra" ] || fail graphql-read "실제 응답에 없는 경로: $extra"
v=$(jq -r '.data.user.projectV2.items.nodes[0].fieldValues.nodes[] | select(.field.name=="줄기") | .name' "$T/read.json")
[ "$v" = "앱" ] || fail graphql-read "줄기 값: $v"

# options-keep-id / options-without-id: 선택지를 id와 함께 바꾸면 값이 남고, id 없이 바꾸면 지워진다(실제 GitHub 동작).
cat > "$T/m1.json" <<'EOF'
{"query":"mutation($f: ID!, $o: [ProjectV2SingleSelectFieldOptionInput!]) { updateProjectV2Field(input: {fieldId: $f, singleSelectOptions: $o}) { projectV2Field { ... on ProjectV2SingleSelectField { options { id name color description } } } } }",
 "variables":{"f":"F_STEM","o":[{"id":"t1","name":"앱","color":"GRAY","description":""},{"name":"출시","color":"GRAY","description":""}]}}
EOF
out=$(gh api graphql --input "$T/m1.json")
[ "$(printf '%s' "$out" | jq '.data.updateProjectV2Field.projectV2Field.options | length')" = 2 ] || fail options-keep-id "응답: $out"
[ "$(board_card 2-1 | jq -r '.values["줄기"]')" = "앱" ] || fail options-keep-id "값이 지워짐"
sed 's/"id":"t1",//' "$T/m1.json" > "$T/m2.json"
gh api graphql --input "$T/m2.json" > /dev/null
[ "$(board_card 2-1 | jq -r '.values["줄기"]')" = "null" ] || fail options-without-id "값이 남음(실제와 다름)"

# close-reopen-title
gh issue close 1 -R "$FAKE_REPO"
[ "$(board_card 2-1 | jq -r .state)" = CLOSED ] || fail close "닫히지 않음"
gh issue reopen 1 -R "$FAKE_REPO"
gh issue edit 1 -R "$FAKE_REPO" --title "[2-1] 새 이름"
c=$(board_card 2-1)
[ "$(printf '%s' "$c" | jq -r .state)" = OPEN ] || fail reopen "$c"
[ "$(printf '%s' "$c" | jq -r .title)" = "[2-1] 새 이름" ] || fail title "$c"

# fail-inject: FAKE_GH_FAIL 에 든 하위 명령은 실패한다.
if FAKE_GH_FAIL="project item-add" gh project item-add 1 --owner test --url "$url" --format json > /dev/null 2>&1; then
  fail fail-inject "실패하지 않음"
fi

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
