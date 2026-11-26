#!/bin/sh
# plugin/scripts/board-setup.sh(템플릿 Project 만들기와 레포 적용, 4단계 설계 5.10절)를 가짜 gh로 확인한다.
# 실행: sh tests/board-setup.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
SETUP="$ROOT/plugin/scripts/board-setup.sh"
T=$(mktemp -d)
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT
fails=0
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

export FAKE_GH_DIR="$T/state" FAKE_GH_LOG="$T/gh.log"
export PATH="$ROOT/tests/fake-gh:$PATH"
. "$ROOT/tests/board-lib.sh"

# ---- template ----
board_seed_project
sh "$SETUP" template test > "$T/out" 2>&1; rc=$?
[ "$rc" = 0 ] || fail template "exit $rc: $(cat "$T/out")"
[ "$(board_calls '^project create --owner test --title waypoint 보드 템플릿')" = 1 ] || fail template-create "$(head -3 "$FAKE_GH_LOG")"
st=$(jq -r '.fields[] | select(.name == "Status") | [.options[].name] | join(",")' "$FAKE_GH_DIR/project.json")
[ "$st" = "대기,진행 중,검토 대기,승인,머지됨,보류" ] || fail template-status "Status 선택지: $st"
# 기존 Todo·In Progress·Done의 id를 대기·진행 중·머지됨으로 이어 썼다
ids=$(jq -r '.fields[] | select(.name == "Status") | [.options[] | select(.name == "대기" or .name == "진행 중" or .name == "머지됨") | .id] | join(",")' "$FAKE_GH_DIR/project.json")
[ "$ids" = "o_todo,o_prog,o_done" ] || fail template-status-ids "$ids"
for f in "줄기:SINGLE_SELECT" "지금:TEXT" "기다림:TEXT" "단계:SINGLE_SELECT" "ID:TEXT"; do
  n=${f%%:*}; ty=${f#*:}
  [ "$(jq -r --arg n "$n" '.fields[] | select(.name == $n) | .dataType' "$FAKE_GH_DIR/project.json")" = "$ty" ] || fail template-fields "$n($ty) 없음"
done
[ "$(jq -r '.fields[] | select(.name == "단계") | [.options[].name] | join(",")' "$FAKE_GH_DIR/project.json")" = "1,2,R,3" ] || fail template-phase "단계 선택지"
# 단일 선택 필드는 선택지가 하나 이상 있어야 해서 줄기에는 자리표시 「(없음)」을 둔다. 첫 동기화가 지운다(board-sync.test.sh stem-placeholder).
[ "$(jq -r '.fields[] | select(.name == "줄기") | [.options[].name] | join(",")' "$FAKE_GH_DIR/project.json")" = "(없음)" ] || fail template-stem "줄기 선택지"
[ "$(jq 'length' "$FAKE_GH_DIR/workflows.json")" = 0 ] || fail template-workflows "기본 자동화가 남음: $(cat "$FAKE_GH_DIR/workflows.json")"
jq -e '.[] | select(.name == "보드" and .layout == "BOARD_LAYOUT")' "$FAKE_GH_DIR/views.json" > /dev/null || fail template-board-view "$(cat "$FAKE_GH_DIR/views.json")"
# 기본 표 보기(View 1)는 이름을 「표」로 바꾸고, 새 필드가 보이게 한다.
jq -e '.[] | select(.name == "표" and .layout == "TABLE_LAYOUT" and (.visible | length) == 6)' "$FAKE_GH_DIR/views.json" > /dev/null || fail template-table-view "$(cat "$FAKE_GH_DIR/views.json")"
[ "$(jq 'length' "$FAKE_GH_DIR/views.json")" = 2 ] || fail template-views "보기 수: $(cat "$FAKE_GH_DIR/views.json")"
# 보드 보기: 보이는 필드는 지금·기다림, 열은 Status, 가로 묶음은 줄기. REST(만들 때만 가로 묶음을 받는다)로 만든다.
vnames() { jq -r --slurpfile p "$FAKE_GH_DIR/project.json" --arg k "$1" '.[] | select(.name == "보드") | [(.[$k] // [])[] as $v | $p[0].fields[] | select(.id == $v) | .name] | join(",")' "$FAKE_GH_DIR/views.json"; }
[ "$(vnames visible)" = "지금,기다림" ] || fail template-board-fields "$(cat "$FAKE_GH_DIR/views.json")"
[ "$(vnames group)" = "줄기" ] || fail template-board-swimlanes "가로 묶음: $(vnames group)"
[ "$(vnames vertical)" = "Status" ] || fail template-board-columns "열: $(vnames vertical)"
[ "$(board_calls '^api -X POST -H X-GitHub-Api-Version: 2026-03-10 /users/test/projectsV2/1/views ')" = 1 ] || fail template-board-rest "$(grep '^api' "$FAKE_GH_LOG")"
for want in 'is:issue is:closed updated:<@today-14d' 'Sync with issue status' 'https://github.com/users/test/projects/1'; do
  grep -qF -e "$want" "$T/out" || fail template-output "출력에 '$want' 없음"
done
grep -qF 'Swimlanes' "$T/out" && fail template-output "가로 묶음을 화면 할 일로 안내함(이제 API로 정한다)"

# template-org: 조직 소유자면 REST 경로가 /orgs/ 다.
board_seed_project
FAKE_GH_OWNER_KIND=orgs sh "$SETUP" template acme > "$T/out" 2>&1 || fail template-org "$(cat "$T/out")"
[ "$(board_calls '^api -X POST -H X-GitHub-Api-Version: 2026-03-10 /orgs/acme/projectsV2/1/views ')" = 1 ] || fail template-org "$(grep '^api' "$FAKE_GH_LOG")"

# ---- repo ----
R="$T/repo"; H="$T/hooks"
g() { git -C "$R" -c user.name=t -c user.email=t@example.com -c core.hooksPath=/dev/null "$@"; }
mk() {
  rm -rf "$R"; git init -q -b main "$R"; g remote add origin https://github.com/test/repo.git
  printf '# repo\n\n## Waypoint\n\n- 이 레포는 waypoint\n- 검토 대기 상한: 3 (설명)\n\n## 다른 절\n\n- 다른 줄\n' > "$R/CLAUDE.md"
  mkdir -p "$R/docs/waypoint"
  printf '# repo\n\n## 스테이지\n\n| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |\n|---|---|---|---|---|---|---|\n| 1-1 | 설계 | PENDING | 앱 | | | |\n' > "$R/docs/waypoint/STATUS.md"
}
mkdir -p "$H"; printf '#!/bin/sh\n# waypoint-hook-version: 1\n# pre-push\n' > "$H/pre-push"; printf '#!/bin/sh\n# waypoint-hook-version: 1\n# board-sync\n' > "$H/board-sync.sh"

mk; board_seed_project
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" = 0 ] || fail repo "exit $rc: $(cat "$T/out")"
[ "$(board_calls '^project copy 9 --source-owner test --target-owner test --title repo 보드')" = 1 ] || fail repo-copy "$(cat "$FAKE_GH_LOG")"
[ "$(board_calls '^project link 2 --owner test --repo test/repo')" = 1 ] || fail repo-link "$(cat "$FAKE_GH_LOG")"
# 「- 보드:」 줄은 「검토 대기 상한」 줄 바로 아래에 들어간다
[ "$(sed -n '/검토 대기 상한/{n;p;}' "$R/CLAUDE.md")" = "- 보드: https://github.com/users/test/projects/2" ] || fail repo-claude-md "$(cat "$R/CLAUDE.md")"
grep -qF '## 다른 절' "$R/CLAUDE.md" || fail repo-claude-md "다른 절이 사라짐"
for f in pre-push board-sync.sh; do
  [ -x "$R/.githooks/$f" ] || fail repo-hooks "$f 사본 없음 또는 실행 권한 없음"
done
for want in CLAUDE.md .githooks/pre-push .githooks/board-sync.sh; do
  grep -qF -e "$want" "$T/out" || fail repo-output "바뀐 파일 목록에 $want 없음: $(cat "$T/out")"
done
[ -z "$(g log --oneline 2>/dev/null)" ] || fail repo-no-commit "커밋을 만듦"

# repo-already: 이미 「보드:」 줄이 있으면 GitHub을 건드리지 않고 멈춘다.
board_seed_project
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" != 0 ] || fail repo-already "멈추지 않음"
[ -s "$FAKE_GH_LOG" ] && fail repo-already "gh를 부름: $(cat "$FAKE_GH_LOG")"

# repo-default-hooks: 훅 사본 폴더를 빼면 스크립트 옆(플러그인 안에서는 ../githooks의 pre-push)에서 찾는다.
mk; board_seed_project
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 > "$T/out" 2>&1; rc=$?
[ "$rc" = 0 ] || fail repo-default-hooks "exit $rc: $(cat "$T/out")"
cmp -s "$R/.githooks/pre-push" "$ROOT/plugin/githooks/pre-push" || fail repo-default-hooks "pre-push가 플러그인 것과 다름"
cmp -s "$R/.githooks/board-sync.sh" "$ROOT/plugin/scripts/board-sync.sh" || fail repo-default-hooks "board-sync.sh가 플러그인 것과 다름"

# repo-old-status: STATUS가 2단계의 새 형식이 아니면 GitHub을 건드리지 않고 멈춘다.
mk; board_seed_project
printf '# repo\n\n| 스테이지 | 상태 |\n|---|---|\n' > "$R/docs/waypoint/STATUS.md"
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" != 0 ] || fail repo-old-status "멈추지 않음"
[ -s "$FAKE_GH_LOG" ] && fail repo-old-status "gh를 부름"

# repo-bad-url: 템플릿 주소가 Project 주소가 아니면 멈춘다.
mk; board_seed_project
sh "$SETUP" repo "$R" https://github.com/test/repo "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" != 0 ] || fail repo-bad-url "멈추지 않음"
[ -s "$FAKE_GH_LOG" ] && fail repo-bad-url "gh를 부름"

# repo-link-fail: 연결에 실패해도 CLAUDE.md 줄과 훅 사본은 남기고, 직접 연결하는 명령을 알린다.
mk; board_seed_project
FAKE_GH_FAIL="project link" sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" != 0 ] || fail repo-link-fail "실패를 알리지 않음"
grep -qF -- '- 보드: https://github.com/users/test/projects/2' "$R/CLAUDE.md" || fail repo-link-fail "보드 줄이 없음"
grep -qF 'gh project link 2 --owner test --repo test/repo' "$T/out" || fail repo-link-fail "직접 연결 명령 안내 없음: $(cat "$T/out")"

# repo-reuse: 같은 제목의 Project가 이미 있으면(앞선 실행이 복사한 뒤 멈춘 경우) 다시 복사하지 않고 그것을 쓴다.
mk; board_seed_project
echo '[{"number":5,"title":"repo 보드","url":"https://github.com/users/test/projects/5","id":"PVT_5"}]' > "$FAKE_GH_DIR/projects.json"
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" = 0 ] || fail repo-reuse "exit $rc: $(cat "$T/out")"
[ "$(board_calls '^project copy')" = 0 ] || fail repo-reuse "또 복사함"
[ "$(sed -n '/검토 대기 상한/{n;p;}' "$R/CLAUDE.md")" = "- 보드: https://github.com/users/test/projects/5" ] || fail repo-reuse "$(cat "$R/CLAUDE.md")"
[ "$(board_calls '^project link 5 ')" = 1 ] || fail repo-reuse "연결하지 않음"
rm -f "$FAKE_GH_DIR/projects.json"

# repo-hook-fail: 훅 사본을 넣지 못하면 CLAUDE.md에 보드 줄을 쓰지 않는다(다시 실행할 수 있게).
mk; board_seed_project
: > "$R/.githooks"
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" != 0 ] || fail repo-hook-fail "멈추지 않음"
grep -qF -- '- 보드:' "$R/CLAUDE.md" && fail repo-hook-fail "보드 줄을 씀"

# repo-ssh-alias: ssh 설정의 별칭 호스트(git@github.com-work:…)도 GitHub 레포로 읽는다.
mk; board_seed_project
g remote set-url origin git@github.com-work:test/repo.git
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" = 0 ] || fail repo-ssh-alias "exit $rc: $(cat "$T/out")"
[ "$(board_calls '^project link 2 --owner test --repo test/repo')" = 1 ] || fail repo-ssh-alias "$(cat "$FAKE_GH_LOG")"

# repo-real-block: 실제 CLAUDE.md 블록 템플릿으로 적용하면 board-sync가 주소를 정확히 하나, 경고 없이 읽는다.
mk; board_seed_project
{ printf '# repo\n\n'; cat "$ROOT/plugin/templates/claude-md-block.md"; } > "$R/CLAUDE.md"
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1 || fail repo-real-block "$(cat "$T/out")"
urls=$(WP_BOARD_SYNC_LIB=1; . "$ROOT/plugin/scripts/board-sync.sh"; wp_board_urls "$R/CLAUDE.md" 2> "$T/err")
[ "$urls" = "https://github.com/users/test/projects/2" ] || fail repo-real-block "주소: $urls"
[ -s "$T/err" ] && fail repo-real-block "경고: $(cat "$T/err")"

# repo-foreign-hook: waypoint가 아닌 pre-push가 있으면 멈춘다.
mk; board_seed_project
mkdir -p "$R/.githooks"; printf '#!/bin/sh\necho 내 훅\n' > "$R/.githooks/pre-push"
sh "$SETUP" repo "$R" https://github.com/users/test/projects/9 "$H" > "$T/out" 2>&1; rc=$?
[ "$rc" != 0 ] || fail repo-foreign-hook "멈추지 않음"
[ -s "$FAKE_GH_LOG" ] && fail repo-foreign-hook "gh를 부름"
grep -qF '내 훅' "$R/.githooks/pre-push" || fail repo-foreign-hook "기존 훅을 덮어씀"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
