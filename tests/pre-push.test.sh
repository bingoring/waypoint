#!/bin/sh
# plugin/githooks/pre-push(보드 동기화를 띄우는 훅, 4단계 설계 5.6절)를 확인한다.
# board-sync.sh 자리에는 받은 인자를 적는 대역을 둔다. 진짜 gh는 부르지 않는다.
# 실행: sh tests/pre-push.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
HOOK="$ROOT/plugin/githooks/pre-push"
T=$(mktemp -d)
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT
fails=0
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }
export LAUNCH_LOG="$T/launched"

R="$T/repo"
g() { git -C "$R" -c user.name=t -c user.email=t@example.com -c core.hooksPath=/dev/null "$@"; }
git init -q --bare -b main "$T/remote.git"
git init -q -b main "$R"
g remote add origin "$T/remote.git"
mkdir -p "$R/docs/waypoint" "$R/.githooks"
cp "$HOOK" "$R/.githooks/pre-push"
cat > "$R/.githooks/board-sync.sh" <<'EOF'
#!/bin/sh
printf 'start %s\n' "$*" >> "$LAUNCH_LOG"
[ -n "${STUB_SLEEP:-}" ] && sleep "$STUB_SLEEP"
printf 'done\n' >> "$LAUNCH_LOG"
EOF
echo "# s" > "$R/docs/waypoint/STATUS.md"; echo a > "$R/a"
g add -A; g commit -q -m one; base=$(g rev-parse HEAD)
g push -q origin main
echo b > "$R/a"; g commit -qam other; other=$(g rev-parse HEAD)
echo "# s2" > "$R/docs/waypoint/STATUS.md"; g commit -qam status; st=$(g rev-parse HEAD)
Z=0000000000000000000000000000000000000000

# hook <stdin 줄>: 훅을 직접 부른다(git이 하듯 원격 이름과 주소를 인자로, ref 줄을 stdin으로).
hook() { rm -f "$LAUNCH_LOG"; (cd "$R" && printf '%s\n' "$1" | sh .githooks/pre-push origin "$T/remote.git") > "$T/out" 2> "$T/err"; echo $? > "$T/rc"; }
# launched: 대역이 실행되었으면 그 인자를 출력한다(백그라운드라 3초까지 기다린다)
launched() { i=0; while [ $i -lt 30 ]; do [ -s "$LAUNCH_LOG" ] && { sed -n 's/^start //p' "$LAUNCH_LOG"; return 0; }; sleep 0.1; i=$((i + 1)); done; return 1; }

hook "refs/heads/feature $st refs/heads/feature $base"
launched > /dev/null && fail feature-branch "기능 브랜치 push에서 띄움"
[ "$(cat "$T/rc")" = 0 ] || fail feature-branch "exit $(cat "$T/rc")"

hook "(delete) $Z refs/heads/main $base"
launched > /dev/null && fail delete "삭제 push에서 띄움"

hook "refs/heads/main $other refs/heads/main $base"
launched > /dev/null && fail no-status-change "STATUS가 그대로인데 띄움"

hook "refs/heads/main $st refs/heads/main $base"
[ "$(launched)" = "--commit $st" ] || fail status-change "인자: $(launched)"

hook "refs/heads/main $st refs/heads/main $Z"
[ "$(launched)" = "--commit $st" ] || fail new-default-branch "인자: $(launched)"

hook "refs/heads/main $st refs/heads/main 1234567890123456789012345678901234567890"
[ "$(launched)" = "--commit $st" ] || fail unknown-remote "인자: $(launched)"

# origin-head: 원격의 HEAD가 develop이면 main push는 대상이 아니다.
g symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop
hook "refs/heads/main $st refs/heads/main $base"
launched > /dev/null && fail origin-head "기본 브랜치가 아닌 push에서 띄움"
hook "refs/heads/develop $st refs/heads/develop $base"
[ "$(launched)" = "--commit $st" ] || fail origin-head-develop "인자: $(launched)"
g symbolic-ref --delete refs/remotes/origin/HEAD

# prev-failure: 직전 동기화가 실패했으면 stderr에 한 줄 알린다. push는 막지 않는다.
mkdir -p "$R/.git/waypoint"
echo 'fail 2026-11-26T10:00:00+0900 board: Project를 읽지 못함' > "$R/.git/waypoint/board-sync.status"
hook "refs/heads/feature $st refs/heads/feature $base"
grep -qxF 'waypoint: 직전 보드 동기화 실패(2026-11-26T10:00:00+0900): board: Project를 읽지 못함' "$T/err" || fail prev-failure "stderr: $(cat "$T/err")"
[ "$(cat "$T/rc")" = 0 ] || fail prev-failure "exit $(cat "$T/rc")"
echo 'ok 2026-11-26T10:00:00+0900' > "$R/.git/waypoint/board-sync.status"
hook "refs/heads/feature $st refs/heads/feature $base"
[ -s "$T/err" ] && fail prev-ok "성공인데 출력: $(cat "$T/err")"

# no-board-sync: board-sync.sh 사본이 없으면 아무것도 하지 않는다.
mv "$R/.githooks/board-sync.sh" "$T/bs.bak"
hook "refs/heads/main $st refs/heads/main $base"
[ "$(cat "$T/rc")" = 0 ] || fail no-board-sync "exit $(cat "$T/rc")"
mv "$T/bs.bak" "$R/.githooks/board-sync.sh"

# push-returns: 실제 git push가 10초 걸리는 동기화를 기다리지 않는다.
rm -f "$LAUNCH_LOG"
g config core.hooksPath .githooks
t0=$(date +%s)
(cd "$R" && STUB_SLEEP=10 git -c user.name=t push -q origin main) > /dev/null 2>&1
t1=$(date +%s)
[ $((t1 - t0)) -le 3 ] || fail push-returns "push가 $((t1 - t0))초 걸림"
[ "$(launched)" = "--commit $st" ] || fail push-returns "동기화가 시작되지 않음"
grep -q '^done' "$LAUNCH_LOG" && fail push-returns "동기화가 push 안에서 끝남(분리되지 않음)"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
