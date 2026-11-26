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

# ---- 새 형식 STATUS의 요약과 경고(설계 5.6절). 모든 경우를 기본 PATH와 PATH=''에서 돌린다. ----

# new_status <파일> <표 본문 줄>... [-- <오너 할 일 줄>...]
new_status() {
  f=$1; shift
  mkdir -p "${f%/*}"
  {
    printf '# t — waypoint 현황\n\n[결정 로그](DECISIONS.md)\n\n## 스테이지\n\n'
    printf '| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |\n|---|---|---|---|---|---|---|\n'
    while [ "$#" -gt 0 ] && [ "$1" != -- ]; do printf '%s\n' "$1"; shift; done
    if [ "$1" = -- ]; then
      shift
      printf '\n## 오너 할 일\n\n'
      for o in "$@"; do printf -- '- [ ] %s\n' "$o"; done
    fi
  } > "$f"
}

# summary_of <출력>: `waypoint:start` 안내 줄과 </waypoint> 사이의 줄
summary_of() { printf '%s\n' "$1" | sed -n '/waypoint:start/,/^<\/waypoint>$/p' | sed '1d;$d'; }

# run2 <경우> <기대 요약 파일> <CLAUDE_PROJECT_DIR>: 두 PATH에서 요약 부분이 기대와 같은지 본다.
run2() {
  for pth in default empty; do
    if [ "$pth" = empty ]; then out=$(PATH='' CLAUDE_PROJECT_DIR="$3" /bin/sh "$S"); rc=$?
    else out=$(CLAUDE_PROJECT_DIR="$3" /bin/sh "$S"); rc=$?; fi
    [ "$rc" -eq 0 ] || fail "$1($pth)" "exit $rc"
    got=$(summary_of "$out")
    want=$(cat "$2")
    [ "$got" = "$want" ] || fail "$1($pth)" "요약이 다름
--- 기대
$want
--- 실제
$got"
  done
}

ROWS_NEW='| 1-1 | A | MERGED | | | | [문서](01-inception/01-a.md) |
| 2-1 | 진행 | IN_PROGRESS | 콘텐츠 | 구현: OR 묶음 7 저작 중 | | [#38](https://x/pull/38) |
| 2-2 | 대기1 | PENDING | | | | |
| 2-3 | 대기2 | PENDING | | | | |
| 3-1 | 배포 | AI_PROPOSED | 출시 | 결과 검토: Android 첫 빌드 | 오너 할 일 | [#40](https://x/pull/40) |
| 3-2 | 모니터링 | HUMAN_APPROVED | | 배포 묶음을 모아 한 번에 머지 | | [#41](https://x/pull/41) |
| 3-3 | 알림 | DEFERRED | | 구현: 오너 보류 | | |'
OWN1='Google Play 서비스 계정 키 발급 (막음: 3-1)'
OWN2='도메인 구입'

g init -q -b main "$T/new"
# shellcheck disable=SC2086
(IFS='
'; new_status "$T/new/docs/waypoint/STATUS.md" $ROWS_NEW -- "$OWN1" "$OWN2")
g -C "$T/new" add -A
g -C "$T/new" commit -q -m init

cat > "$T/want-new" <<'EOF'
현황(new): 진행 중 1 · 검토 대기 1 · 승인 1 · 대기 2 · 보류 1 · 오너 할 일 2
- 2-1 IN_PROGRESS [콘텐츠] 구현: OR 묶음 7 저작 중
- 3-1 AI_PROPOSED [출시] 결과 검토: Android 첫 빌드 (기다림: 오너 할 일)
- 3-2 HUMAN_APPROVED 배포 묶음을 모아 한 번에 머지
오너 할 일:
- Google Play 서비스 계정 키 발급 (막음: 3-1)
- 도메인 구입
EOF

# 9 summary: 개수 줄, 활성 줄, 오너 할 일이 안내 뒤, </waypoint> 앞에 나온다. 경고는 없다.
run2 summary "$T/want-new" "$T/new"

# 10 old-format: 옛 형식 STATUS에는 요약도 경고도 붙이지 않는다.
for pth in default empty; do
  if [ "$pth" = empty ]; then out=$(PATH='' CLAUDE_PROJECT_DIR="$T/repo" /bin/sh "$S"); else out=$(CLAUDE_PROJECT_DIR="$T/repo" /bin/sh "$S"); fi
  printf '%s\n' "$out" | grep -qE '^(현황\(|경고:)' && fail "old-format($pth)" "요약이나 경고가 있음: $out"
done

# 11 cap: 요약은 20줄까지. 넘치면 20번째 줄이 「… 외 N개」다.
g init -q -b main "$T/cap"
rows=
i=1
while [ "$i" -le 25 ]; do
  rows="$rows| 2-$i | s$i | IN_PROGRESS | | 구현: x$i | | [#$i](https://x/pull/$i) |
"
  i=$((i + 1))
done
# shellcheck disable=SC2086
(IFS='
'; new_status "$T/cap/docs/waypoint/STATUS.md" $rows)
{
  echo '현황(cap): 진행 중 25 · 검토 대기 0 · 승인 0 · 대기 0 · 보류 0 · 오너 할 일 0'
  i=1
  while [ "$i" -le 18 ]; do echo "- 2-$i IN_PROGRESS 구현: x$i"; i=$((i + 1)); done
  echo '… 외 7개 (STATUS.md 참조)'
} > "$T/want-cap"
run2 cap "$T/want-cap" "$T/cap"

# 12 branch-warn: 메인 체크아웃이 기본 브랜치가 아니면 요약 앞에 경고 한 줄.
g -C "$T/new" switch -q -c feature
{ echo '경고: 메인 체크아웃이 기본 브랜치가 아니다(현재 feature). 요약이 낡았을 수 있다.'; cat "$T/want-new"; } > "$T/want-feature"
run2 branch-warn-feature "$T/want-feature" "$T/new"
g -C "$T/new" checkout -q --detach
{ echo '경고: 메인 체크아웃이 기본 브랜치가 아니다(현재 detached HEAD). 요약이 낡았을 수 있다.'; cat "$T/want-new"; } > "$T/want-detached"
run2 branch-warn-detached "$T/want-detached" "$T/new"
g -C "$T/new" switch -q main
mkdir -p "$T/new/.git/refs/remotes/origin"
echo 'ref: refs/remotes/origin/develop' > "$T/new/.git/refs/remotes/origin/HEAD"
{ echo '경고: 메인 체크아웃이 기본 브랜치가 아니다(현재 main). 요약이 낡았을 수 있다.'; cat "$T/want-new"; } > "$T/want-originhead"
run2 branch-warn-origin-head "$T/want-originhead" "$T/new"
rm -f "$T/new/.git/refs/remotes/origin/HEAD"

# 13 stale-hook: 레포의 .githooks/pre-commit 버전이 플러그인보다 낮으면 경고 한 줄.
PV=$(sed -n 's/^# waypoint-hook-version: //p' "$ROOT/plugin/githooks/pre-commit")
mkdir -p "$T/new/.githooks"
printf '#!/bin/sh\n# waypoint-hook-version: 0\n' > "$T/new/.githooks/pre-commit"
{ echo "경고: .githooks/pre-commit이 낡았다(레포 0, 플러그인 $PV). 플러그인의 githooks/pre-commit으로 바꿔라."; cat "$T/want-new"; } > "$T/want-stale"
run2 stale-hook "$T/want-stale" "$T/new"
printf '#!/bin/sh\necho old\n' > "$T/new/.githooks/pre-commit"
run2 stale-hook-noversion "$T/want-stale" "$T/new"
printf '#!/bin/sh\n# waypoint-hook-version: %s\n' "$PV" > "$T/new/.githooks/pre-commit"
run2 stale-hook-current "$T/want-new" "$T/new"
rm -rf "$T/new/.githooks"
run2 stale-hook-none "$T/want-new" "$T/new"

# 13b stale-pre-push, stale-board-sync: 보드 동기화 훅 사본(4단계 설계 5.9절)도 같은 방식으로 경고한다.
PPV=$(sed -n 's/^# waypoint-hook-version: //p' "$ROOT/plugin/githooks/pre-push")
BSV=$(sed -n 's/^# waypoint-hook-version: //p' "$ROOT/plugin/scripts/board-sync.sh")
mkdir -p "$T/new/.githooks"
printf '#!/bin/sh\n# waypoint-hook-version: 0\n' > "$T/new/.githooks/pre-push"
{ echo "경고: .githooks/pre-push가 낡았다(레포 0, 플러그인 $PPV). 플러그인의 githooks/pre-push로 바꿔라."; cat "$T/want-new"; } > "$T/want-stale-pp"
run2 stale-pre-push "$T/want-stale-pp" "$T/new"
printf '#!/bin/sh\n# waypoint-hook-version: %s\n' "$PPV" > "$T/new/.githooks/pre-push"
printf '#!/bin/sh\necho old\n' > "$T/new/.githooks/board-sync.sh"
{ echo "경고: .githooks/board-sync.sh가 낡았다(레포 0, 플러그인 $BSV). 플러그인의 scripts/board-sync.sh로 바꿔라."; cat "$T/want-new"; } > "$T/want-stale-bs"
run2 stale-board-sync "$T/want-stale-bs" "$T/new"
rm -rf "$T/new/.githooks"

# 13c sync-fail, sync-ok, sync-none: 메인 체크아웃의 보드 동기화 상태 파일이 실패면 경고 한 줄(4단계 설계 5.8절).
mkdir -p "$T/new/.git/waypoint"
echo 'fail 2026-11-26T10:00:00+0900 board: Project를 읽지 못함($URL)' > "$T/new/.git/waypoint/board-sync.status"
{ echo '경고: 보드 동기화 실패(2026-11-26T10:00:00+0900): board: Project를 읽지 못함($URL)'; cat "$T/want-new"; } > "$T/want-sync-fail"
run2 sync-fail "$T/want-sync-fail" "$T/new"
echo 'ok 2026-11-26T10:00:00+0900' > "$T/new/.git/waypoint/board-sync.status"
run2 sync-ok "$T/want-new" "$T/new"
rm -rf "$T/new/.git/waypoint"
run2 sync-none "$T/want-new" "$T/new"

# 14 parent-dedupe: 레포 밖 세션은 레포마다 개수 줄만, 같은 메인 체크아웃은 한 번만, 숫자는 메인 체크아웃의 STATUS에서.
g init -q -b main "$T/parent2/proj"
# shellcheck disable=SC2086
(IFS='
'; new_status "$T/parent2/proj/docs/waypoint/STATUS.md" $ROWS_NEW -- "$OWN1" "$OWN2")
g -C "$T/parent2/proj" add -A
g -C "$T/parent2/proj" commit -q -m init
g -C "$T/parent2/proj" worktree add -q "$T/parent2/proj-2-9" -b content/2-9
new_status "$T/parent2/proj-2-9/docs/waypoint/STATUS.md" '| 2-1 | 진행 | IN_PROGRESS | | 구현: 낡은 사본 | | [#1](https://x/pull/1) |'
want='현황(proj): 진행 중 1 · 검토 대기 1 · 승인 1 · 대기 2 · 보류 1 · 오너 할 일 2'
for pth in default empty; do
  if [ "$pth" = empty ]; then out=$(PATH='' CLAUDE_PROJECT_DIR="$T/parent2" /bin/sh "$S"); else out=$(CLAUDE_PROJECT_DIR="$T/parent2" /bin/sh "$S"); fi
  n=$(printf '%s\n' "$out" | grep -c '^현황(proj): 진행 중')
  [ "$n" -eq 1 ] || fail "parent-dedupe($pth)" "개수 줄이 ${n}개: $out"
  printf '%s\n' "$out" | grep -qxF "$want" || fail "parent-dedupe($pth)" "줄 '$want' 없음: $out"
  n=$(printf '%s\n' "$out" | grep -cxF "메인 체크아웃(proj): $T/parent2/proj")
  [ "$n" -eq 1 ] || fail "parent-dedupe($pth)" "메인 체크아웃 줄이 ${n}개"
  printf '%s\n' "$out" | grep -qF 'proj-2-9' && fail "parent-dedupe($pth)" "worktree 이름이 나옴: $out"
  printf '%s\n' "$out" | grep -qE '^(- [123R]-[0-9]+ |경고:|오너 할 일:)' && fail "parent-dedupe($pth)" "개수 줄 밖의 요약이나 경고가 있음: $out"
done
# 옛 형식 레포는 레포 밖 세션에서도 개수 줄이 없다(7번의 $T/parent).
out=$(CLAUDE_PROJECT_DIR="$T/parent" /bin/sh "$S")
printf '%s\n' "$out" | grep -q '^현황(proj): 진행 중' && fail parent-old-format "옛 형식에 개수 줄이 있음"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
