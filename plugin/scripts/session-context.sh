#!/bin/sh
# waypoint SessionStart 훅: waypoint를 쓰는 레포에서만 핵심 규칙(core-rules.md)과 안내를 출력한다.
#
# - 시작 디렉터리: ${CLAUDE_PROJECT_DIR:-$PWD} (상대 경로면 $PWD 기준으로 절대화)
# - 레포 루트: 시작 디렉터리에서 위로 올라가며 docs/waypoint/STATUS.md 가 있는 곳.
#   그 전에 .git 이 있는 디렉터리(waypoint를 쓰지 않는 레포)에 닿으면 아무것도 출력하지 않는다.
# - 레포 밖(어느 조상에도 .git 이 없음)에서 시작했으면, 시작 디렉터리 바로 아래의
#   */docs/waypoint/STATUS.md 를 찾아 레포별 경로를 알린다. 하나도 없으면 아무것도 출력하지 않는다.
# - 메인 체크아웃: 레포의 .git 이 디렉터리면 그 레포, 파일(worktree)이면 그 gitdir 에서 계산한다.
# - SessionStart 시점에는 PATH가 비어 있을 수 있으므로 셸 내장 명령만 쓴다. 항상 exit 0.

case "$0" in
  */*) here=${0%/*} ;;
  *) here=. ;;
esac
core="$here/../core-rules.md"

start=${CLAUDE_PROJECT_DIR:-$PWD}
case $start in
  /*) ;;
  *) start="$PWD/$start" ;;
esac

# main_of <레포 경로>: 메인 체크아웃 경로를 $main 에 넣는다.
main_of() {
  main=$1
  [ -f "$1/.git" ] || return 0
  line=
  IFS= read -r line < "$1/.git" || [ -n "$line" ] || true
  gitdir=${line#gitdir: }
  case $gitdir in
    /*) ;;
    *) gitdir="$1/$gitdir" ;;
  esac
  case $gitdir in
    */.git/worktrees/*) main=${gitdir%/.git/worktrees/*} ;;
  esac
}

print_core() {
  printf '%s\n' '<waypoint>'
  if [ -r "$core" ]; then
    while IFS= read -r l || [ -n "$l" ]; do
      printf '%s\n' "$l"
    done < "$core"
  fi
  printf '\n'
}

# 위로 올라가며 레포 루트를 찾는다.
dir=$start
root=
while :; do
  if [ -f "$dir/docs/waypoint/STATUS.md" ]; then
    root=$dir
    break
  fi
  [ -e "$dir/.git" ] && exit 0
  [ "$dir" = / ] && break
  next=${dir%/*}
  [ -z "$next" ] && next=/
  [ "$next" = "$dir" ] && break
  dir=$next
done

if [ -n "$root" ]; then
  main_of "$root"
  print_core
  printf '%s\n' '이 레포는 waypoint 플러그인으로 진행한다.'
  printf '%s\n' "메인 체크아웃: $main"
  printf '%s\n' "현황: $main/docs/waypoint/STATUS.md"
  printf '%s\n' '작업을 시작하면 `waypoint:start` 스킬을 호출한다.'
  printf '%s\n' '</waypoint>'
  exit 0
fi

# 레포 밖에서 시작했다: 바로 아래 자식 가운데 waypoint 레포를 찾는다.
found=
for f in "$start"/*/docs/waypoint/STATUS.md; do
  [ -f "$f" ] && found=1 && break
done
[ -n "$found" ] || exit 0

print_core
printf '%s\n' "이 세션은 레포 밖($start)에서 시작했다. 아래 레포들이 waypoint 플러그인으로 진행한다. 작업할 레포를 정한 뒤 그 레포의 메인 체크아웃 경로를 쓴다."
for f in "$start"/*/docs/waypoint/STATUS.md; do
  [ -f "$f" ] || continue
  repo=${f%/docs/waypoint/STATUS.md}
  name=${repo##*/}
  main_of "$repo"
  printf '%s\n' "메인 체크아웃($name): $main"
  printf '%s\n' "현황($name): $main/docs/waypoint/STATUS.md"
done
printf '%s\n' '작업을 시작하면 `waypoint:start` 스킬을 호출한다.'
printf '%s\n' '</waypoint>'
exit 0
