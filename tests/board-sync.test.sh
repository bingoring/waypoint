#!/bin/sh
# plugin/scripts/board-sync.sh(보드 동기화, 4단계 설계 5.6~5.8절)를 가짜 gh로 확인한다.
# 실행: sh tests/board-sync.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
BS="$ROOT/plugin/scripts/board-sync.sh"
T=$(mktemp -d)
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT
fails=0
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

export FAKE_GH_DIR="$T/state" FAKE_GH_LOG="$T/gh.log"
export PATH="$ROOT/tests/fake-gh:$PATH"
. "$ROOT/tests/board-lib.sh"

# ---- Task 3: STATUS에서 원하는 카드 계산 ----
# 함수만 읽는다. 특수 내장 명령(.) 앞의 변수 지정은 셸에 남아 자식에게 넘어가므로 읽은 뒤 지운다.
WP_BOARD_SYNC_LIB=1
. "$BS"
unset WP_BOARD_SYNC_LIB

cat > "$T/STATUS.md" <<'EOF'
# t — waypoint 현황

## 스테이지

| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |
|---|---|---|---|---|---|---|
| 1-1 | 설계 | MERGED | | | | [문서](a.md) |
| 1-3 | Architecture Decision ⚠️ | PENDING | | | | |
| 2-1 | 구현 "따옴표" \ 역슬래시 | IN_PROGRESS | 앱 | 구현: 시험 중 | | [#1](https://github.com/test/repo/pull/1) |
| 2-2 | 검토 | AI_PROPOSED | 출시 | 결과 검토: 시험 | 오너 할 일 | [#2](https://github.com/test/repo/pull/2) |
| 2-3 | 승인 | HUMAN_APPROVED | | 배포 묶음 | 오너 할 일 | [#3](https://github.com/test/repo/pull/3) |
| R-1 | Review 🔍 | DEFERRED | | 구현: 보류 | Play 신원확인 | |

## 오너 할 일

- [ ] 키 발급 (막음: 2-2)
- [ ] 계정 만들기 (막음: 2-2, R-1)
- [ ] 도메인 구입
EOF
wp_desired_cards "$T/STATUS.md" > "$T/desired.jsonl"
d() { jq -r --arg id "$1" "select(.id == \$id) | $2" "$T/desired.jsonl"; }

[ "$(wc -l < "$T/desired.jsonl" | tr -d ' ')" = 6 ] || fail desired-count "$(cat "$T/desired.jsonl")"
for pair in "1-1 머지됨" "1-3 대기" "2-1 진행 중" "2-2 검토 대기" "2-3 승인" "R-1 보류"; do
  id=${pair%% *}; want=${pair#* }
  [ "$(d "$id" .status)" = "$want" ] || fail desired-status "$id: $(d "$id" .status) (기대 $want)"
done
[ "$(d 1-1 .open)" = false ] || fail desired-open "MERGED는 닫힘"
[ "$(d 2-1 .open)" = true ] || fail desired-open "IN_PROGRESS는 열림"
[ "$(d R-1 .open)" = true ] || fail desired-open "DEFERRED는 열림"
[ "$(d 1-3 .title)" = "[1-3] Architecture Decision ⚠️" ] || fail desired-title "$(d 1-3 .title)"
[ "$(d 2-1 .title)" = '[2-1] 구현 "따옴표" \ 역슬래시' ] || fail desired-escape "$(d 2-1 .title)"
[ "$(d 2-1 .stem)" = 앱 ] || fail desired-stem "$(d 2-1 .stem)"
[ "$(d 1-3 .stem)" = "" ] || fail desired-stem-empty "$(d 1-3 .stem)"
[ "$(d 1-3 .now)" = "" ] || fail desired-now-empty "$(d 1-3 .now)"
[ "$(d 2-1 .phase)" = 2 ] || fail desired-phase "$(d 2-1 .phase)"
[ "$(d R-1 .phase)" = R ] || fail desired-phase-r "$(d R-1 .phase)"
[ "$(d 2-2 .wait)" = "오너 할 일: 키 발급 · 계정 만들기" ] || fail wait-two "$(d 2-2 .wait)"
[ "$(d 2-3 .wait)" = "오너 할 일" ] || fail wait-none "$(d 2-3 .wait)"
[ "$(d R-1 .wait)" = "Play 신원확인" ] || fail wait-plain "$(d R-1 .wait)"
[ "$(d 2-1 .wait)" = "" ] || fail wait-empty "$(d 2-1 .wait)"
# R-1이 막힌 오너 할 일이 있어도 「기다림」이 오너 할 일이 아니면 그대로 둔다(설계 5.2절: 값이 「오너 할 일」일 때만 확장)

# board-urls: CLAUDE.md 의 「- 보드:」 줄
printf '# r\n\n## Waypoint\n\n- 이 레포는 waypoint\n' > "$T/c0.md"
[ -z "$(wp_board_urls "$T/c0.md" 2>/dev/null)" ] || fail urls-none "줄이 없는데 주소가 나옴"
printf -- '- 보드: https://github.com/users/test/projects/1\n' > "$T/c1.md"
[ "$(wp_board_urls "$T/c1.md")" = "https://github.com/users/test/projects/1" ] || fail urls-one "$(wp_board_urls "$T/c1.md")"
printf -- '- 보드: https://github.com/users/test/projects/1 https://github.com/orgs/o/projects/22/\n' > "$T/c2.md"
[ "$(wp_board_urls "$T/c2.md" | wc -l | tr -d ' ')" = 2 ] || fail urls-two "$(wp_board_urls "$T/c2.md")"
printf -- '- 보드: https://example.com/x https://github.com/users/test/projects/1\n' > "$T/c3.md"
out=$(wp_board_urls "$T/c3.md" 2> "$T/err")
[ "$out" = "https://github.com/users/test/projects/1" ] || fail urls-bad "$out"
grep -qF 'example.com' "$T/err" || fail urls-bad-warn "경고 없음"

# ---- Task 4: Project와 이슈 맞추기 ----

# parity: 실제 GitHub 응답(픽스처)을 board-sync의 카드 해석으로 읽을 수 있다.
jq -c --arg k user --arg repo bingoring/waypoint-board-test "$WP_JQ_CARDS" "$ROOT/tests/fixtures/board/project-graphql.json" > "$T/real-cards.json"
[ "$(jq -r '.[0].v.ID' "$T/real-cards.json")" = 2-1 ] || fail parity "ID: $(cat "$T/real-cards.json")"
[ "$(jq -r '.[0].v["줄기"]' "$T/real-cards.json")" = 앱 ] || fail parity "줄기: $(cat "$T/real-cards.json")"
[ "$(jq -r '.[0].number' "$T/real-cards.json")" = 1 ] || fail parity "이슈 번호"

R="$T/repo"
g() { git -C "$R" -c user.name=t -c user.email=t@example.com -c core.hooksPath=/dev/null "$@"; }
# mkrepo <CLAUDE.md의 보드 줄(없으면 빈 문자열)> <STATUS 표 본문 줄>... [-- <오너 할 일>...]
mkrepo() {
  rm -rf "$R"; git init -q -b main "$R"; g remote add origin https://github.com/test/repo.git
  if [ -n "$1" ]; then printf '# r\n\n## Waypoint\n\n%s\n' "$1" > "$R/CLAUDE.md"; else printf '# r\n' > "$R/CLAUDE.md"; fi
  shift
  mkdir -p "$R/docs/waypoint"
  {
    printf '# r — waypoint 현황\n\n## 스테이지\n\n| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |\n|---|---|---|---|---|---|---|\n'
    while [ "$#" -gt 0 ] && [ "$1" != -- ]; do printf '%s\n' "$1"; shift; done
    if [ "$1" = -- ]; then shift; printf '\n## 오너 할 일\n\n'; for o in "$@"; do printf -- '- [ ] %s\n' "$o"; done; fi
  } > "$R/docs/waypoint/STATUS.md"
  g add -A; g commit -q -m init
}
BOARD="- 보드: $FAKE_URL"
ROW_21='| 2-1 | 구현 | IN_PROGRESS | 앱 | 구현: 시험 | | [#1](https://github.com/test/repo/pull/1) |'
run_sync() { (cd "$R" && sh "$BS" "$@") > "$T/out" 2>&1; }
status_line() { cat "$R/.git/waypoint/board-sync.status" 2>/dev/null; }
card_val() { board_card "$1" | jq -r --arg k "$2" '.values[$k] // ""'; }
# 모든 필드 값이 맞는 2-1 카드(이슈 1)를 만든다
seed_21() {
  board_add_issue 1 "[2-1] 구현" "${1:-OPEN}"
  board_add_item PVTI_1 1 '{"ID":"2-1","Status":"s2","줄기":"t1","지금":"구현: 시험","단계":"p2"}'
}

# create-new: 카드도 이슈도 없는 진행 중 줄 → 이슈를 만들고 카드에 넣고 필드를 채운다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
run_sync
case $(status_line) in ok*) ;; *) fail create-new "상태: $(status_line) / $(cat "$T/out")" ;; esac
[ "$(board_calls '^issue create')" = 1 ] || fail create-new "issue create $(board_calls '^issue create')번"
[ "$(board_calls '^label create waypoint')" = 1 ] || fail create-new "라벨을 만들지 않음"
for kv in "Status=진행 중" "줄기=앱" "지금=구현: 시험" "단계=2" "ID=2-1"; do
  [ "$(card_val 2-1 "${kv%%=*}")" = "${kv#*=}" ] || fail create-new "${kv%%=*}: $(board_card 2-1)"
done
jq -r '.[0].body' "$FAKE_GH_DIR/issues.json" | grep -qF '## 최근 진행' || fail create-new "본문 틀 없음"

# find-before-create: 이슈는 있는데 카드가 없음 → 이슈를 새로 만들지 않고 카드만 넣는다.
board_seed_project; board_add_issue 5 "[2-1] 구현" OPEN; mkrepo "$BOARD" "$ROW_21"
run_sync
[ "$(board_calls '^issue create')" = 0 ] || fail find-before-create "이슈를 또 만듦"
[ "$(board_card 2-1 | jq -r .issue)" = 5 ] || fail find-before-create "$(board_card 2-1)"

# merged-no-card: 카드 없는 MERGED 줄은 아무것도 만들지 않는다.
board_seed_project; mkrepo "$BOARD" '| 1-1 | 설계 | MERGED | | | | [문서](a.md) |'
run_sync
[ "$(board_calls '^(issue create|project item-add)')" = 0 ] || fail merged-no-card "$(cat "$FAKE_GH_LOG")"

# diff-only: 「지금」만 다르면 item-edit 한 번.
board_seed_project; seed_21; mkrepo "$BOARD" '| 2-1 | 구현 | IN_PROGRESS | 앱 | 구현: 바뀜 | | [#1](https://github.com/test/repo/pull/1) |'
run_sync
[ "$(board_calls '^project item-edit')" = 1 ] || fail diff-only "item-edit $(board_calls '^project item-edit')번: $(grep item-edit "$FAKE_GH_LOG")"
[ "$(card_val 2-1 지금)" = "구현: 바뀜" ] || fail diff-only "$(board_card 2-1)"
[ "$(board_calls '^(issue edit|issue close|issue reopen)')" = 0 ] || fail diff-only "이슈를 고침"

# no-change: 모두 같으면 쓰는 호출이 없다.
board_seed_project; seed_21; mkrepo "$BOARD" "$ROW_21"
run_sync
[ "$(board_calls '^(project item-edit|issue edit|issue close|issue reopen|issue create|project item-add)')" = 0 ] || fail no-change "$(cat "$FAKE_GH_LOG")"

# close-merged: MERGED가 되면 이슈를 닫고 Status를 머지됨으로.
board_seed_project; seed_21; mkrepo "$BOARD" '| 2-1 | 구현 | MERGED | 앱 | | | [문서](a.md) |'
run_sync
[ "$(board_card 2-1 | jq -r .state)" = CLOSED ] || fail close-merged "$(board_card 2-1)"
[ "$(card_val 2-1 Status)" = 머지됨 ] || fail close-merged "$(board_card 2-1)"
[ "$(card_val 2-1 지금)" = "" ] || fail close-merged "지금을 비우지 않음"

# reopen: 손으로 닫힌 이슈인데 MERGED가 아니면 다시 연다.
board_seed_project; seed_21 CLOSED; mkrepo "$BOARD" "$ROW_21"
run_sync
[ "$(board_card 2-1 | jq -r .state)" = OPEN ] || fail reopen "$(board_card 2-1)"

# title-change: 스테이지 이름이 바뀌면 제목만 고친다.
board_seed_project; seed_21; mkrepo "$BOARD" '| 2-1 | 새 이름 | IN_PROGRESS | 앱 | 구현: 시험 | | [#1](https://github.com/test/repo/pull/1) |'
run_sync
[ "$(board_card 2-1 | jq -r .title)" = "[2-1] 새 이름" ] || fail title-change "$(board_card 2-1)"
# body-untouched: 이미 있는 이슈를 고칠 때 본문은 건드리지 않는다(제목을 고친 이 경우의 호출 기록으로 본다).
[ "$(board_calls '^issue edit')" -ge 1 ] || fail body-untouched "issue edit가 없어 검사가 의미 없음"
grep -E '^issue edit' "$FAKE_GH_LOG" | grep -qE -- '--body' && fail body-untouched "본문을 고침"

# unknown-card: STATUS에 없는 ID의 카드는 지우지 않고 경고한다.
board_seed_project; seed_21; board_add_issue 9 "[9-9] 옛" OPEN; board_add_item PVTI_9 9 '{"ID":"9-9"}'; mkrepo "$BOARD" "$ROW_21"
run_sync
grep -qF '9-9' "$R/.git/waypoint/board-sync.log" || fail unknown-card "경고 없음"
[ "$(board_card 9-9 | jq -r .issue)" = 9 ] || fail unknown-card "카드가 사라짐"

# new-stem: 처음 보는 줄기는 선택지를 더하고, 기존 카드의 줄기 값은 남는다.
board_seed_project; seed_21; mkrepo "$BOARD" "$ROW_21" '| 3-1 | 배포 | IN_PROGRESS | 출시 | 계획: 시작 | | [#2](https://github.com/test/repo/pull/2) |'
run_sync
[ "$(card_val 2-1 줄기)" = 앱 ] || fail new-stem "기존 값이 지워짐: $(board_card 2-1)"
[ "$(card_val 3-1 줄기)" = 출시 ] || fail new-stem "새 값: $(board_card 3-1)"

# stem-placeholder: 템플릿 줄기의 자리표시 「(없음)」은 줄기 선택지를 처음 더할 때 지운다. 쓰는 줄이 있으면 남긴다.
board_seed_project
jq '.fields |= map(if .name == "줄기" then .options = [{id:"t0", name:"(없음)", color:"GRAY", description:""}] else . end)' "$FAKE_GH_DIR/project.json" > "$T/p" && mv "$T/p" "$FAKE_GH_DIR/project.json"
mkrepo "$BOARD" "$ROW_21"
run_sync
[ "$(jq -r '.fields[] | select(.name == "줄기") | [.options[].name] | join(",")' "$FAKE_GH_DIR/project.json")" = "앱" ] || fail stem-placeholder "$(jq -c '.fields[] | select(.name == "줄기")' "$FAKE_GH_DIR/project.json")"
[ "$(card_val 2-1 줄기)" = 앱 ] || fail stem-placeholder "$(board_card 2-1)"

# wait-expand: 「기다림」이 오너 할 일이면 그 내용을 적는다.
board_seed_project; mkrepo "$BOARD" '| 3-1 | 배포 | AI_PROPOSED | 출시 | 결과 검토: 시험 | 오너 할 일 | [#2](https://github.com/test/repo/pull/2) |' -- '키 발급 (막음: 3-1)'
run_sync
[ "$(card_val 3-1 기다림)" = "오너 할 일: 키 발급" ] || fail wait-expand "$(board_card 3-1)"

# two-boards: 주소가 둘이어도 이슈는 하나다(가짜 gh는 두 주소에 같은 Project를 돌려준다).
board_seed_project; mkrepo "- 보드: $FAKE_URL https://github.com/users/test/projects/2" "$ROW_21"
run_sync
[ "$(board_calls '^issue create')" = 1 ] || fail two-boards "issue create $(board_calls '^issue create')번"
[ "$(board_calls 'number=2')" -ge 1 ] || fail two-boards "두 번째 Project를 읽지 않음"

# no-board: 「보드:」 줄이 없으면 gh를 부르지 않고 상태 파일도 만들지 않는다.
board_seed_project; mkrepo "" "$ROW_21"
run_sync; rc=$?
[ "$rc" = 0 ] || fail no-board "exit $rc"
[ -s "$FAKE_GH_LOG" ] && fail no-board "gh를 부름: $(cat "$FAKE_GH_LOG")"
[ -e "$R/.git/waypoint" ] && fail no-board "상태 디렉터리를 만듦"

# no-gh: PATH에 gh가 없으면 실패를 기록한다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
(cd "$R" && PATH=/usr/bin:/bin sh "$BS") > "$T/out" 2>&1
case $(status_line) in "fail "*" tools: "*) ;; *) fail no-gh "상태: $(status_line)" ;; esac

# check-fail: 내용 검사에 실패한 STATUS는 gh를 부르지 않고 실패로 기록한다.
board_seed_project; mkrepo "$BOARD" '| 2-1 | 구현 | READY | | | | |'
run_sync
case $(status_line) in "fail "*" check: "*) ;; *) fail check-fail "상태: $(status_line)" ;; esac
[ -s "$FAKE_GH_LOG" ] && fail check-fail "gh를 부름"

# gh-error: item-add가 실패하면 실패로 기록하고, 다음 실행은 이슈를 다시 만들지 않는다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
(cd "$R" && FAKE_GH_FAIL="project item-add" sh "$BS") > "$T/out" 2>&1
case $(status_line) in "fail "*) ;; *) fail gh-error "상태: $(status_line)" ;; esac
run_sync
case $(status_line) in ok*) ;; *) fail gh-error-retry "상태: $(status_line) / $(cat "$T/out")" ;; esac
[ "$(board_calls '^issue create')" = 1 ] || fail gh-error-retry "이슈를 또 만듦"

# commit-arg: --commit 으로 준 커밋의 STATUS를 읽는다(작업 트리가 아니라).
board_seed_project; mkrepo "$BOARD" "$ROW_21"
first=$(g rev-parse HEAD)
printf '%s\n' '| 2-2 | 다음 | IN_PROGRESS | | 계획: x | | [#3](https://github.com/test/repo/pull/3) |' >> "$R/docs/waypoint/STATUS.md"
g commit -qam two
run_sync --commit "$first"
[ -z "$(board_card 2-2)" ] || fail commit-arg "주지 않은 커밋의 줄을 반영함"
[ -n "$(board_card 2-1)" ] || fail commit-arg "준 커밋의 줄을 반영하지 않음"

# ---- 독립 리뷰에서 나온 경우 ----

# url-bad-fail: 「보드:」 줄은 있는데 주소 형식이 모두 틀리면 조용히 끝내지 않고 실패로 기록한다.
board_seed_project; mkrepo "- 보드: $FAKE_URL/views/1" "$ROW_21"
run_sync
case $(status_line) in "fail "*" board: "*) ;; *) fail url-bad-fail "상태: $(status_line)" ;; esac
# url-one-bad: 하나만 틀리면 맞는 Project는 맞추고 실패로 기록한다.
board_seed_project; mkrepo "- 보드: $FAKE_URL https://example.com/x" "$ROW_21"
run_sync
[ -n "$(board_card 2-1)" ] || fail url-one-bad "맞는 Project도 맞추지 않음"
case $(status_line) in "fail "*"example.com"*) ;; *) fail url-one-bad "상태: $(status_line)" ;; esac
# crlf: CLAUDE.md 줄 끝이 CRLF여도 주소를 읽는다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
printf '# r\r\n\r\n## Waypoint\r\n\r\n%s\r\n' "$BOARD" > "$R/CLAUDE.md"; g commit -qam crlf
run_sync
case $(status_line) in ok*) ;; *) fail crlf "상태: $(status_line) / $(cat "$T/out")" ;; esac
[ -n "$(board_card 2-1)" ] || fail crlf "카드 없음"

# other-repo-card: 한 Project에 다른 레포의 같은 ID 카드가 있어도 이 레포의 카드로 보지 않는다(설계 5.12 통합 보드).
board_seed_project
board_add_issue 7 "[2-1] 남의 것" OPEN
jq 'map(if .number == 7 then .repo = "other/repo" | .url = "https://github.com/other/repo/issues/7" else . end)' "$FAKE_GH_DIR/issues.json" > "$T/i" && mv "$T/i" "$FAKE_GH_DIR/issues.json"
board_add_item PVTI_7 7 '{"ID":"2-1","Status":"s1"}'
mkrepo "$BOARD" "$ROW_21"
run_sync
[ "$(board_calls '^issue create')" = 1 ] || fail other-repo-card "이 레포의 이슈를 만들지 않음: $(cat "$FAKE_GH_LOG")"
[ "$(board_calls '^issue (edit|close|reopen) 7 ')" = 0 ] || fail other-repo-card "다른 레포의 이슈를 고침"
[ "$(jq -r '.[] | select(.id == "PVTI_7") | .values.Status' "$FAKE_GH_DIR/items.json")" = s1 ] || fail other-repo-card "다른 레포의 카드를 고침"

# merged-orphan: 카드 없이 남은 열린 이슈는 줄이 MERGED가 되면 닫는다(카드는 만들지 않는다).
board_seed_project; board_add_issue 3 "[1-1] 설계" OPEN; mkrepo "$BOARD" '| 1-1 | 설계 | MERGED | | | | [문서](a.md) |'
run_sync
[ "$(jq -r '.[] | select(.number == 3) | .state' "$FAKE_GH_DIR/issues.json")" = CLOSED ] || fail merged-orphan "이슈를 닫지 않음"
[ "$(board_calls '^project item-add')" = 0 ] || fail merged-orphan "카드를 만듦"

# paginate: 카드가 여러 페이지에 걸쳐도 모두 읽는다(가짜 gh가 한 장에 하나씩).
board_seed_project; seed_21
board_add_issue 2 "[2-2] 다음" OPEN; board_add_item PVTI_2 2 '{"ID":"2-2","Status":"s1","단계":"p2"}'
mkrepo "$BOARD" "$ROW_21" '| 2-2 | 다음 | PENDING | | | | |'
FAKE_GH_PAGE_SIZE=1 run_sync
[ "$(board_calls '^(issue create|project item-add|project item-edit|issue edit)')" = 0 ] || fail paginate "$(cat "$FAKE_GH_LOG")"

# stdin: 반복문 안의 gh 호출이 표준 입력을 읽어도 남은 줄을 잃지 않는다.
board_seed_project; mkrepo "$BOARD" "$ROW_21" '| 2-2 | 다음 | PENDING | | | | |' '| 2-3 | 셋째 | PENDING | | | | |'
FAKE_GH_EAT_STDIN=1 run_sync < /dev/null
for id in 2-1 2-2 2-3; do [ -n "$(board_card $id)" ] || fail stdin "$id 카드 없음"; done
[ "$(card_val 2-1 지금)" = "구현: 시험" ] || fail stdin "필드를 고치다 멈춤: $(board_card 2-1)"

# commit-noarg: --commit 뒤에 값이 없으면 사용법을 알리고 끝난다(멈추지 않는다).
(cd "$R" && exec sh "$BS" --commit > /dev/null 2>&1) & p=$!
sleep 2
if kill -0 "$p" 2> /dev/null; then kill "$p"; fail commit-noarg "끝나지 않음"; fi
wait "$p" 2> /dev/null

# ---- Task 5: 잠금과 재실행 ----
LK="$R/.git/waypoint/board-sync.lock"
mklock() { mkdir -p "$LK"; echo "$1" > "$LK/pid"; echo "$2" > "$LK/started"; }

# lock-busy: 살아 있는 동기화가 잠금을 쥐고 있으면 훅이 띄운 실행(--commit)은 재실행 표시만 남기고 끝난다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
sleep 30 & live=$!
mklock "$live" "$(date +%s)"
run_sync --commit "$(g rev-parse HEAD)"
[ -s "$FAKE_GH_LOG" ] && fail lock-busy "gh를 부름"
[ -e "$R/.git/waypoint/board-sync.rerun" ] || fail lock-busy "재실행 표시가 없음"
[ -d "$LK" ] || fail lock-busy "남의 잠금을 지움"

# lock-old: 살아 있는 PID인데 10분이 넘은 잠금은 실패로 기록한다.
rm -rf "$LK" "$R/.git/waypoint/board-sync.rerun"
mklock "$live" "$(( $(date +%s) - 700 ))"
run_sync --commit "$(g rev-parse HEAD)"
case $(status_line) in "fail "*" lock: "*) ;; *) fail lock-old "상태: $(status_line)" ;; esac
kill "$live" 2> /dev/null; wait "$live" 2> /dev/null

# lock-stale: 죽은 PID의 잠금은 지우고 실행한다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
sh -c 'exit 0' & dead=$!; wait "$dead"
mklock "$dead" "$(date +%s)"
run_sync
case $(status_line) in ok*) ;; *) fail lock-stale "상태: $(status_line) / $(cat "$T/out")" ;; esac
[ -d "$LK" ] && fail lock-stale "끝난 뒤 잠금이 남음"

# lock-nopid: 막 만들어져 PID가 아직 없는 잠금은 남의 실행으로 보고 지우지 않는다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
mkdir -p "$LK"
run_sync --commit "$(g rev-parse HEAD)"
[ -s "$FAKE_GH_LOG" ] && fail lock-nopid "gh를 부름"
[ -d "$LK" ] || fail lock-nopid "남의 잠금을 지움"
[ -e "$R/.git/waypoint/board-sync.rerun" ] || fail lock-nopid "재실행 표시가 없음"
# lock-bad-started: 시작 시각이 비어 있어도 살아 있는 PID면 바쁜 잠금이다(실패로 적지 않는다).
rm -rf "$LK" "$R/.git/waypoint/board-sync.rerun" "$R/.git/waypoint/board-sync.status"
sleep 30 & live=$!
mkdir -p "$LK"; echo "$live" > "$LK/pid"; : > "$LK/started"
run_sync --commit "$(g rev-parse HEAD)"
[ -z "$(status_line)" ] || fail lock-bad-started "상태: $(status_line)"
[ -e "$R/.git/waypoint/board-sync.rerun" ] || fail lock-bad-started "재실행 표시가 없음"

# manual-wait: 직접 실행(--commit 없음)은 다른 동기화가 끝나기를 기다렸다가 실행한다.
rm -f "$R/.git/waypoint/board-sync.rerun"
(cd "$R" && sh "$BS") > "$T/out" 2>&1 & p=$!
sleep 2
kill -0 "$p" 2> /dev/null || fail manual-wait "기다리지 않고 끝남: $(cat "$T/out")"
rm -rf "$LK"; kill "$live" 2> /dev/null; wait "$live" 2> /dev/null
wait "$p"
case $(status_line) in ok*) ;; *) fail manual-wait "상태: $(status_line) / $(cat "$T/out")" ;; esac
[ -n "$(board_card 2-1)" ] || fail manual-wait "카드 없음"
grep -qF '성공' "$T/out" || fail manual-wait "결과를 알리지 않음: $(cat "$T/out")"
[ -e "$R/.git/waypoint/board-sync.rerun" ] && fail manual-wait "재실행 표시를 남김"

# rerun: 실행 중에 재실행 표시가 생기면, 끝난 뒤 기본 브랜치 끝 커밋으로 한 번 더 실행한다.
board_seed_project; mkrepo "$BOARD" "$ROW_21"
first=$(g rev-parse HEAD)
printf '%s\n' '| 2-2 | 다음 | IN_PROGRESS | | 계획: x | | [#3](https://github.com/test/repo/pull/3) |' >> "$R/docs/waypoint/STATUS.md"
g commit -qam two
mkdir -p "$R/.git/waypoint"; : > "$R/.git/waypoint/board-sync.rerun"
run_sync --commit "$first"
[ -n "$(board_card 2-2)" ] || fail rerun "다시 실행하지 않음(2-2 카드 없음)"
[ -e "$R/.git/waypoint/board-sync.rerun" ] && fail rerun "재실행 표시가 남음"
[ "$(grep -c '시작 commit=' "$R/.git/waypoint/board-sync.log")" = 2 ] || fail rerun "실행 횟수: $(grep -c '시작 commit=' "$R/.git/waypoint/board-sync.log")"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
