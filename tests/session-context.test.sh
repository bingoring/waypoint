#!/bin/sh
# plugin/scripts/session-context.sh(SessionStart 훅)의 동작을 확인한다.
# 테스트 준비에는 git을 쓰지만, 검사 대상 스크립트는 셸 내장 명령만 써야 한다(5번 경우).
# 실행: sh tests/session-context.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
S="$ROOT/plugin/scripts/session-context.sh"
T=$(mktemp -d)
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }
g() { git -c user.name=t -c user.email=t@example.com -c core.hooksPath=/dev/null "$@"; }

# 핵심 규칙이 들어간 블록인지 확인한다. $1=경우 이름, $2=출력, $3=기대하는 메인 체크아웃 경로
# 경로가 든 줄은 줄 전체가 일치해야 한다(부분 일치로 틀린 경로를 통과시키지 않도록).
expect_block() {
  for want in '<waypoint>' '# waypoint 핵심 규칙' 'waypoint:start' '</waypoint>'; do
    printf '%s\n' "$2" | grep -qF -e "$want" || fail "$1" "'$want' 없음"
  done
  for want in "메인 체크아웃: $3" "현황: $3/docs/waypoint/STATUS.md"; do
    printf '%s\n' "$2" | grep -qxF -e "$want" || fail "$1" "줄 '$want' 없음"
  done
}

# 준비: waypoint를 쓰지 않는 레포, 쓰는 레포(+하위 디렉터리, worktree), git이 아닌 디렉터리
mkdir -p "$T/plain" "$T/repo/src" "$T/repo/docs/waypoint" "$T/nogit"
g init -q "$T/plain"
g init -q "$T/repo"
echo '# STATUS' > "$T/repo/docs/waypoint/STATUS.md"
echo 'x' > "$T/repo/src/a.txt"
g -C "$T/repo" add -A
g -C "$T/repo" commit -q -m init
g -C "$T/repo" worktree add -q "$T/wt" -b feature

# 1 plain-repo: waypoint 문서가 없으면 아무것도 출력하지 않는다.
out=$(CLAUDE_PROJECT_DIR="$T/plain" /bin/sh "$S"); rc=$?
[ "$rc" -eq 0 ] || fail plain-repo "exit $rc"
[ -z "$out" ] || fail plain-repo "출력이 있음: $out"

# 2 waypoint: 핵심 규칙과 안내, 메인 체크아웃 경로를 출력한다.
out=$(CLAUDE_PROJECT_DIR="$T/repo" /bin/sh "$S"); rc=$?
[ "$rc" -eq 0 ] || fail waypoint "exit $rc"
expect_block waypoint "$out" "$T/repo"

# 3 subdir: CLAUDE_PROJECT_DIR가 없으면 작업 디렉터리에서 위로 올라가며 찾는다.
out=$(cd "$T/repo/src" && env -u CLAUDE_PROJECT_DIR /bin/sh "$S")
expect_block subdir "$out" "$T/repo"

# 4 worktree: worktree에서는 원래 레포를 메인 체크아웃으로 알린다.
out=$(CLAUDE_PROJECT_DIR="$T/wt" /bin/sh "$S")
expect_block worktree "$out" "$T/repo"

# 5 empty-path: PATH가 비어 있어도 같은 블록을 출력한다.
out=$(PATH='' CLAUDE_PROJECT_DIR="$T/repo" /bin/sh "$S"); rc=$?
[ "$rc" -eq 0 ] || fail empty-path "exit $rc"
expect_block empty-path "$out" "$T/repo"

# 6 non-git: git도 waypoint 문서도 없는 디렉터리에서는 아무것도 출력하지 않는다.
out=$(CLAUDE_PROJECT_DIR="$T/nogit" /bin/sh "$S"); rc=$?
[ "$rc" -eq 0 ] || fail non-git "exit $rc"
[ -z "$out" ] || fail non-git "출력이 있음: $out"

# 7 parent-dir: 레포 밖(여러 레포를 담은 상위 디렉터리)에서 시작하면, 바로 아래 waypoint 레포들의 경로를 알린다.
mkdir -p "$T/parent/proj/docs/waypoint" "$T/parent/other"
echo '# STATUS' > "$T/parent/proj/docs/waypoint/STATUS.md"
g init -q "$T/parent/proj"
g init -q "$T/parent/other"
out=$(CLAUDE_PROJECT_DIR="$T/parent" /bin/sh "$S"); rc=$?
[ "$rc" -eq 0 ] || fail parent-dir "exit $rc"
for want in '<waypoint>' '# waypoint 핵심 규칙' '레포 밖' 'waypoint:start' '</waypoint>'; do
  printf '%s\n' "$out" | grep -qF -e "$want" || fail parent-dir "'$want' 없음"
done
for want in "메인 체크아웃(proj): $T/parent/proj" "현황(proj): $T/parent/proj/docs/waypoint/STATUS.md"; do
  printf '%s\n' "$out" | grep -qxF -e "$want" || fail parent-dir "줄 '$want' 없음"
done
printf '%s\n' "$out" | grep -qF '(other)' && fail parent-dir "waypoint를 쓰지 않는 other가 목록에 있음"

# 8 relative-dir: 상대 경로가 들어와도 끝난다(무한 루프 없음).
# exec로 셸 자신을 스크립트로 바꿔, $!가 스크립트 프로세스를 가리키게 한다(멈췄을 때 정확히 종료하려고).
( cd "$T/nogit" && CLAUDE_PROJECT_DIR=no-such-rel exec /bin/sh "$S" > /dev/null 2>&1 ) &
pid=$!
sleep 1
if kill -0 "$pid" 2>/dev/null; then
  kill -9 "$pid" 2>/dev/null
  fail relative-dir "1초 안에 끝나지 않음"
fi

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
