#!/bin/sh
# plugin/githooks/pre-commit(커밋 위치 검사와 STATUS 형식 검사, 설계 5.5절)을 확인한다.
# 실행: sh tests/pre-commit.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
HK="$ROOT/plugin/githooks"
T=$(mktemp -d)
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }
# g: 준비용(훅 없음), h: 훅을 켠 커밋
g() { git -c user.name=t -c user.email=t@example.com -c core.hooksPath=/dev/null -c init.defaultBranch=main "$@"; }
h() { git -c user.name=t -c user.email=t@example.com -c core.hooksPath="$HK" "$@"; }

S=docs/waypoint/STATUS.md

# status <파일> <표 본문 줄>...: 올바른 머리와 표 아래에 줄을 넣은 STATUS를 쓴다.
status() {
  f=$1; shift
  mkdir -p "$(dirname "$f")"
  {
    printf '# t — waypoint 현황\n\n## 스테이지\n\n'
    printf '| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |\n|---|---|---|---|---|---|---|\n'
    for r in "$@"; do printf '%s\n' "$r"; done
  } > "$f"
}
GOOD='| 1-1 | A | PENDING | | | | |'
GOOD2='| 1-2 | B | PENDING | | | | |'
BADROW='| 1-2 | B | READY | | | | |'

# mkrepo <디렉터리>: main 브랜치에 올바른 STATUS가 커밋된 레포
mkrepo() {
  g init -q "$1"
  status "$1/$S" "$GOOD"
  g -C "$1" add -A
  g -C "$1" commit -q -m init
}

# ok <경우> <디렉터리> [<환경>...] -- 커밋 인자...: 훅을 켠 커밋이 성공하고 stderr가 비어 있다.
# bad <경우> <디렉터리> <기대 문자열> ...: 커밋이 실패하고 stderr에 기대 문자열이 있다.
commit_in() {
  d=$1; shift
  err=$(cd "$d" && h "$@" 2>&1 >/dev/null); rc=$?
}
ok() {
  n=$1; d=$2; shift 2
  commit_in "$d" "$@"
  [ "$rc" -eq 0 ] || fail "$n" "커밋 실패(exit $rc): $err"
  [ -z "$err" ] || fail "$n" "stderr 있음: $err"
}
bad() {
  n=$1; d=$2; want=$3; shift 3
  commit_in "$d" "$@"
  [ "$rc" -ne 0 ] || fail "$n" "커밋이 성공함"
  case $err in *"$want"*) ;; *) fail "$n" "'$want' 없음: $err" ;; esac
}

# plain-repo: STATUS가 없는 레포에서는 아무것도 하지 않는다.
g init -q "$T/plain"
echo x > "$T/plain/a"
g -C "$T/plain" add -A && g -C "$T/plain" commit -q -m init
g -C "$T/plain" switch -q -c feature
echo y > "$T/plain/a" && g -C "$T/plain" add -A
ok plain-repo "$T/plain" commit -q -m "feat: a"

# other-files: STATUS·DECISIONS를 건드리지 않는 커밋은 기능 브랜치에서도 통과한다.
mkrepo "$T/r1"
g -C "$T/r1" switch -q -c feature
mkdir -p "$T/r1/src" && echo x > "$T/r1/src/a" && g -C "$T/r1" add -A
ok other-files "$T/r1" commit -q -m "feat: a"

# branch-status / branch-decisions: 기능 브랜치에서 STATUS·DECISIONS를 바꾸면 거부한다.
status "$T/r1/$S" "$GOOD" "$GOOD2" && g -C "$T/r1" add -A
bad branch-status "$T/r1" "기본 브랜치" commit -q -m "docs(status): 1-2 PENDING"
case $err in *"main 또는 master"*) ;; *) fail branch-status-criterion "판정 기준(main 또는 master) 안내 없음: $err" ;; esac
g -C "$T/r1" reset -q
echo '# d' > "$T/r1/docs/waypoint/DECISIONS.md" && g -C "$T/r1" add docs/waypoint/DECISIONS.md
bad branch-decisions "$T/r1" "기본 브랜치" commit -q -m "docs: d"
g -C "$T/r1" reset -q

# allow-var-ok / allow-var-bad: 예외 변수는 검사 1만 건너뛴다.
g -C "$T/r1" add "$S"
err=$(cd "$T/r1" && export WAYPOINT_ALLOW_BRANCH_STATUS=1 && h commit -q -m "docs(waypoint): 변환" 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 0 ] || fail allow-var-ok "커밋 실패: $err"
status "$T/r1/$S" "$GOOD" "$BADROW" && g -C "$T/r1" add -A
err=$(cd "$T/r1" && export WAYPOINT_ALLOW_BRANCH_STATUS=1 && h commit -q -m "docs(waypoint): 변환" 2>&1 >/dev/null); rc=$?
[ "$rc" -ne 0 ] || fail allow-var-bad "커밋이 성공함"
case $err in *"[검사 3]"*) ;; *) fail allow-var-bad "'[검사 3]' 없음: $err" ;; esac
g -C "$T/r1" checkout -q -- . 2>/dev/null; g -C "$T/r1" reset -q --hard

# detached: detached HEAD에서는 거부한다.
mkrepo "$T/r2"
g -C "$T/r2" checkout -q --detach
status "$T/r2/$S" "$GOOD" "$GOOD2" && g -C "$T/r2" add -A
bad detached "$T/r2" "detached HEAD" commit -q -m "docs(status): 1-2 PENDING"

# main-ok / main-bad: 기본 브랜치에서는 형식 검사만 한다.
mkrepo "$T/r3"
status "$T/r3/$S" "$GOOD" "$GOOD2" && g -C "$T/r3" add -A
ok main-ok "$T/r3" commit -q -m "docs(status): 1-2 PENDING"
status "$T/r3/$S" "$GOOD" "$BADROW" && g -C "$T/r3" add -A
bad main-bad "$T/r3" "[검사 3]" commit -q -m "docs(status): 1-2 READY"
g -C "$T/r3" reset -q --hard

# index-not-worktree / worktree-not-index: 작업 트리가 아니라 커밋될 내용을 검사한다.
status "$T/r3/$S" "$GOOD" "$BADROW" && g -C "$T/r3" add -A
status "$T/r3/$S" "$GOOD" "$GOOD2"
bad index-not-worktree "$T/r3" "[검사 3]" commit -q -m "docs(status): x"
g -C "$T/r3" reset -q --hard
status "$T/r3/$S" "$GOOD" "$GOOD2" '| 1-3 | C | PENDING | | | | |' && g -C "$T/r3" add -A
status "$T/r3/$S" "$GOOD" "$BADROW"
ok worktree-not-index "$T/r3" commit -q -m "docs(status): 1-2 PENDING"
g -C "$T/r3" reset -q --hard

# commit-am / commit-only: 임시 index로 하는 커밋도 검사한다.
status "$T/r3/$S" "$GOOD" "$BADROW"
bad commit-am "$T/r3" "[검사 3]" commit -q -am "docs(status): x"
bad commit-only "$T/r3" "[검사 3]" commit -q "$S" -m "docs(status): x"
g -C "$T/r3" reset -q --hard

# origin-head: origin/HEAD가 있으면 그 브랜치만 기본 브랜치다.
mkrepo "$T/r4"
g -C "$T/r4" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop
status "$T/r4/$S" "$GOOD" "$GOOD2" && g -C "$T/r4" add -A
bad origin-head-main "$T/r4" "기본 브랜치" commit -q -m "docs(status): 1-2 PENDING"
case $err in *"origin/HEAD가 가리키는 develop"*) ;; *) fail origin-head-criterion "판정 기준(origin/HEAD) 안내 없음: $err" ;; esac
g -C "$T/r4" switch -q -c develop
ok origin-head-develop "$T/r4" commit -q -m "docs(status): 1-2 PENDING"

# unborn-main: 아직 커밋이 없는 main의 첫 커밋.
g init -q "$T/r5"
status "$T/r5/$S" "$GOOD" && g -C "$T/r5" add -A
ok unborn-main "$T/r5" commit -q -m "docs(waypoint): 시작"

# index-docs: 검사 6과 8은 index의 스테이지 문서를 본다.
mkrepo "$T/r6"
mkdir -p "$T/r6/docs/waypoint/01-inception"
printf -- '---\nid: 1-1\nphase: 01-inception\n---\n\n# 1-1\n' > "$T/r6/docs/waypoint/01-inception/01-a.md"
status "$T/r6/$S" '| 1-1 | A | MERGED | | | | [문서](01-inception/01-a.md) |'
g -C "$T/r6" add -A
ok index-docs-ok "$T/r6" commit -q -m "docs(status): 1-1 MERGED"
printf -- '---\nid: 1-2\n---\n\n# 1-2\n' > "$T/r6/docs/waypoint/01-inception/02-b.md"
printf -- '# 빌드 스펙\n\nid: 9-9 는 frontmatter가 아니다\n' > "$T/r6/docs/waypoint/01-inception/spec.md"
status "$T/r6/$S" '| 1-1 | A | MERGED | | | | [문서](01-inception/01-a.md) |' '| 1-3 | C | PENDING | | | | |'
g -C "$T/r6" add -A
bad index-docs-missing-row "$T/r6" "[검사 8]" commit -q -m "docs(status): 1-3 PENDING"
case $err in *"9-9"*) fail index-docs-frontmatter-only "frontmatter 밖의 id: 를 읽음: $err" ;; esac

# rebase-conflict: 기본 브랜치에서 pull --rebase 중 STATUS 충돌을 풀고 이어 가도 막히지 않는다.
mkrepo "$T/up"
g clone -q "$T/up" "$T/me"
git -C "$T/me" config core.hooksPath "$HK"
git -C "$T/me" config user.name t
git -C "$T/me" config user.email t@example.com
status "$T/up/$S" '| 1-1 | AA | PENDING | | | | |' && g -C "$T/up" commit -q -am "docs(status): up"
status "$T/me/$S" '| 1-1 | AB | PENDING | | | | |' && git -C "$T/me" commit -q -am "docs(status): me"
git -C "$T/me" pull -q --rebase > /dev/null 2>&1 && fail rebase-conflict "충돌이 나지 않음(테스트 오류)"
status "$T/me/$S" '| 1-1 | AC | PENDING | | | | |' && git -C "$T/me" add "$S"
err=$(cd "$T/me" && GIT_EDITOR=true git rebase --continue 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail rebase-conflict "rebase --continue 실패: $err"
[ "$(git -C "$T/me" branch --show-current)" = main ] || fail rebase-conflict "rebase가 끝나지 않음"
git -C "$T/me" log --format=%s -1 | grep -qxF "docs(status): me" || fail rebase-conflict "로컬 커밋이 없음"

# config-and-korean-path: 사용자 git 설정(색, column, 패턴 종류)과 한글 파일명에도 index의 id: 를 바르게 읽는다.
mkrepo "$T/r7"
mkdir -p "$T/r7/docs/waypoint/01-inception"
printf -- '---\nid: 1-1\n---\n\n# 1-1\n' > "$T/r7/docs/waypoint/01-inception/01-한글 문서.md"
status "$T/r7/$S" '| 1-1 | A | MERGED | | | | [문서](01-inception/01-한글 문서.md) |'
g -C "$T/r7" add -A
git -C "$T/r7" config color.ui always
git -C "$T/r7" config grep.column true
git -C "$T/r7" config grep.patternType fixed
ok config-and-korean-path "$T/r7" commit -q -m "docs(status): 1-1 MERGED"

# rebase-direct-commit: rebase 중 충돌을 풀고 rebase --continue 대신 git commit 을 직접 해도,
# 기본 브랜치의 rebase면 검사 1을 통과하고 검사 2는 그대로 한다.
mkrepo "$T/up2"
g clone -q "$T/up2" "$T/me2"
git -C "$T/me2" config core.hooksPath "$HK"
git -C "$T/me2" config user.name t
git -C "$T/me2" config user.email t@example.com
status "$T/up2/$S" '| 1-1 | AA | PENDING | | | | |' && g -C "$T/up2" commit -q -am "docs(status): up"
status "$T/me2/$S" '| 1-1 | AB | PENDING | | | | |' && git -C "$T/me2" commit -q -am "docs(status): me"
git -C "$T/me2" pull -q --rebase > /dev/null 2>&1 && fail rebase-direct-commit "충돌이 나지 않음(테스트 오류)"
status "$T/me2/$S" '| 1-1 | AC | READY | | | | |' && git -C "$T/me2" add "$S"
err=$(cd "$T/me2" && git commit -q -m "docs(status): me" 2>&1); rc=$?
[ "$rc" -ne 0 ] || fail rebase-direct-commit-bad "잘못된 STATUS 커밋이 성공함"
case $err in *"[검사 3]"*) ;; *) fail rebase-direct-commit-bad "'[검사 3]' 없음: $err" ;; esac
status "$T/me2/$S" '| 1-1 | AC | PENDING | | | | |' && git -C "$T/me2" add "$S"
err=$(cd "$T/me2" && git commit -q -m "docs(status): me" 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail rebase-direct-commit "rebase 중 직접 커밋이 막힘: $err"
err=$(cd "$T/me2" && GIT_EDITOR=true git rebase --continue 2>&1); rc=$?
[ "$rc" -eq 0 ] || fail rebase-direct-commit "rebase --continue 실패: $err"
[ "$(git -C "$T/me2" branch --show-current)" = main ] || fail rebase-direct-commit "rebase가 끝나지 않음"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
