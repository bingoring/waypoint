#!/bin/sh
# waypoint SessionStart 훅: waypoint를 쓰는 레포에서만 핵심 규칙(core-rules.md)과 안내를 출력한다.
#
# - 레포 루트: ${CLAUDE_PROJECT_DIR:-$PWD} 에서 위로 올라가며 docs/waypoint/STATUS.md 가 있는 곳.
#   .git 이 있는 디렉터리(레포 루트)나 / 에 닿을 때까지 못 찾으면 아무것도 출력하지 않는다.
# - 메인 체크아웃: 루트의 .git 이 디렉터리면 루트, 파일(worktree)이면 그 gitdir 에서 계산한다.
# - SessionStart 시점에는 PATH가 비어 있을 수 있으므로 셸 내장 명령만 쓴다.
# - 항상 exit 0 으로 끝낸다.

case "$0" in
  */*) here=${0%/*} ;;
  *) here=. ;;
esac
core="$here/../core-rules.md"

dir=${CLAUDE_PROJECT_DIR:-$PWD}
root=
while :; do
  if [ -f "$dir/docs/waypoint/STATUS.md" ]; then
    root=$dir
    break
  fi
  if [ -e "$dir/.git" ] || [ -z "$dir" ] || [ "$dir" = / ]; then
    exit 0
  fi
  dir=${dir%/*}
  [ -z "$dir" ] && dir=/
done

main=$root
if [ -f "$root/.git" ]; then
  line=
  IFS= read -r line < "$root/.git" || [ -n "$line" ] || true
  gitdir=${line#gitdir: }
  case $gitdir in
    /*) ;;
    *) gitdir="$root/$gitdir" ;;
  esac
  case $gitdir in
    */.git/worktrees/*) main=${gitdir%/.git/worktrees/*} ;;
  esac
fi

printf '%s\n' '<waypoint>'
if [ -r "$core" ]; then
  while IFS= read -r l || [ -n "$l" ]; do
    printf '%s\n' "$l"
  done < "$core"
fi
printf '\n%s\n' '이 레포는 waypoint 플러그인으로 진행한다.'
printf '%s\n' "메인 체크아웃: $main"
printf '%s\n' '현황: docs/waypoint/STATUS.md'
printf '%s\n' '작업을 시작하면 `waypoint:start` 스킬을 호출한다.'
printf '%s\n' '</waypoint>'
exit 0
