#!/bin/sh
# waypoint SessionStart 훅: waypoint를 쓰는 레포에서만 핵심 규칙(core-rules.md)과 안내, 활성 스테이지 요약을 출력한다.
#
# - 시작 디렉터리: ${CLAUDE_PROJECT_DIR:-$PWD} (상대 경로면 $PWD 기준으로 절대화)
# - 레포 루트: 시작 디렉터리에서 위로 올라가며 docs/waypoint/STATUS.md 가 있는 곳.
#   그 전에 .git 이 있는 디렉터리(waypoint를 쓰지 않는 레포)에 닿으면 아무것도 출력하지 않는다.
# - 레포 밖(어느 조상에도 .git 이 없음)에서 시작했으면, 시작 디렉터리 바로 아래의
#   */docs/waypoint/STATUS.md 를 찾아 레포별 경로와 개수 한 줄을 알린다. 같은 메인 체크아웃은 한 번만.
#   하나도 없으면 아무것도 출력하지 않는다.
# - 메인 체크아웃: 레포의 .git 이 디렉터리면 그 레포, 파일(worktree)이면 그 gitdir 에서 계산한다.
# - 요약(설계 docs/superpowers/specs/2026-11-25-status-cleanup-design.md 5.6절)은 메인 체크아웃의 STATUS를 읽는다.
#   STATUS가 새 형식(## 스테이지 절과 정해진 머리 줄)이 아니면 요약과 경고를 붙이지 않는다.
# - SessionStart 시점에는 PATH가 비어 있을 수 있으므로 셸 내장 명령만 쓴다. 항상 exit 0.

case "$0" in
  */*) here=${0%/*} ;;
  *) here=. ;;
esac
core="$here/../core-rules.md"
plugin_hook="$here/../githooks/pre-commit"

NL='
'
CR=$(printf '\r')
HEADER='| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |'
CAP=20

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

# trim <문자열>: 앞뒤 공백을 지워 $t 에 넣는다.
trim() {
  t=$1
  t=${t#"${t%%[![:space:]]*}"}
  t=${t%"${t##*[![:space:]]}"}
}

# read_status <STATUS 경로>: 새 형식이면 개수(n_*)와 요약 줄($act, $own)을 채우고 0, 아니면 1.
read_status() {
  n_ip=0 n_ap=0 n_ha=0 n_pe=0 n_de=0 n_ow=0
  act= own= sec= tstate= ok=
  [ -r "$1" ] || return 1
  while IFS= read -r l || [ -n "$l" ]; do
    l=${l%"$CR"}
    case $l in
      '## 스테이지') sec=stage; tstate=header; continue ;;
      '## 오너 할 일') sec=owner; continue ;;
      '## '*) sec=; continue ;;
    esac
    case $sec in
      stage)
        case $tstate in
          header)
            trim "$l"
            [ -z "$t" ] && continue
            [ "$t" = "$HEADER" ] || return 1
            ok=1; tstate=sep ;;
          sep) tstate=rows ;;
          rows)
            case $l in
              '|'*) row "$l" ;;
              *) tstate=done ;;
            esac ;;
        esac ;;
      owner)
        case $l in
          '- [ ] '*) n_ow=$((n_ow + 1)); own="$own- ${l#"- [ ] "}$NL" ;;
        esac ;;
    esac
  done < "$1"
  [ -n "$ok" ]
}

# row <표 줄>: 상태별 개수를 세고, 활성 줄이면 요약 줄을 $act 에 덧붙인다.
row() {
  _ifs=$IFS
  set -f
  IFS='|'
  # shellcheck disable=SC2086
  set -- $1
  IFS=$_ifs
  set +f
  trim "$2"; r_id=$t
  trim "$4"; r_st=$t
  trim "$5"; r_stem=$t
  trim "$6"; r_now=$t
  trim "$7"; r_wait=$t
  case $r_st in
    IN_PROGRESS) n_ip=$((n_ip + 1)) ;;
    AI_PROPOSED) n_ap=$((n_ap + 1)) ;;
    HUMAN_APPROVED) n_ha=$((n_ha + 1)) ;;
    PENDING) n_pe=$((n_pe + 1)); return 0 ;;
    DEFERRED) n_de=$((n_de + 1)); return 0 ;;
    *) return 0 ;;
  esac
  s="- $r_id $r_st"
  [ -n "$r_stem" ] && s="$s [$r_stem]"
  [ -n "$r_now" ] && s="$s $r_now"
  [ -n "$r_wait" ] && s="$s (기다림: $r_wait)"
  act="$act$s$NL"
}

# hook_ver <파일>: 둘째 줄 "# waypoint-hook-version: N"의 N을 $ver 에 넣는다. 없거나 숫자가 아니면 0.
hook_ver() {
  ver=0 _l1= _l2=
  [ -r "$1" ] || return 0
  { IFS= read -r _l1; IFS= read -r _l2; } < "$1" || true
  _l2=${_l2%"$CR"}
  case $_l2 in
    '# waypoint-hook-version: '*) _v=${_l2#'# waypoint-hook-version: '} ;;
    *) return 0 ;;
  esac
  case $_v in
    '' | *[!0-9]*) return 0 ;;
  esac
  ver=$_v
}

# warnings <메인>: 메인 체크아웃이 기본 브랜치가 아니거나 레포의 pre-commit 사본이 낡았으면 경고 줄을 출력한다.
warnings() {
  if [ -d "$1/.git" ]; then
    h=
    IFS= read -r h < "$1/.git/HEAD" || [ -n "$h" ] || true
    case $h in
      'ref: refs/heads/'*) br=${h#ref: refs/heads/} ;;
      *) br= ;;
    esac
    d=
    if [ -r "$1/.git/refs/remotes/origin/HEAD" ]; then
      IFS= read -r d < "$1/.git/refs/remotes/origin/HEAD" || [ -n "$d" ] || true
      d=${d#ref: refs/remotes/origin/}
    fi
    isdef=
    if [ -n "$br" ]; then
      if [ -n "$d" ]; then
        [ "$br" = "$d" ] && isdef=1
      else
        case $br in main | master) isdef=1 ;; esac
      fi
    fi
    [ -n "$isdef" ] || printf '%s\n' "경고: 메인 체크아웃이 기본 브랜치가 아니다(현재 ${br:-detached HEAD}). 요약이 낡았을 수 있다."
  fi
  if [ -f "$1/.githooks/pre-commit" ]; then
    hook_ver "$plugin_hook"; pv=$ver
    hook_ver "$1/.githooks/pre-commit"; rv=$ver
    [ "$rv" -lt "$pv" ] && printf '%s\n' "경고: .githooks/pre-commit이 낡았다(레포 $rv, 플러그인 $pv). 플러그인의 githooks/pre-commit으로 바꿔라."
  fi
  return 0
}

# summary <메인> <full|count>: 새 형식 STATUS면 요약(full) 또는 개수 한 줄(count)을 출력한다.
summary() {
  read_status "$1/docs/waypoint/STATUS.md" || return 0
  cnt="현황(${1##*/}): 진행 중 $n_ip · 검토 대기 $n_ap · 승인 $n_ha · 대기 $n_pe · 보류 $n_de · 오너 할 일 $n_ow"
  if [ "$2" = count ]; then
    printf '%s\n' "$cnt"
    return 0
  fi
  warnings "$1"
  body="$cnt$NL$act"
  [ "$n_ow" -gt 0 ] && body="$body오너 할 일:$NL$own"
  total=0
  _ifs=$IFS; IFS=$NL; set -f
  for x in $body; do total=$((total + 1)); done
  i=0
  for x in $body; do
    i=$((i + 1))
    if [ "$total" -gt "$CAP" ] && [ "$i" -eq "$CAP" ]; then
      printf '%s\n' "… 외 $((total - CAP + 1))개 (STATUS.md 참조)"
      break
    fi
    printf '%s\n' "$x"
  done
  IFS=$_ifs; set +f
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
  summary "$main" full
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
seen=$NL
for f in "$start"/*/docs/waypoint/STATUS.md; do
  [ -f "$f" ] || continue
  repo=${f%/docs/waypoint/STATUS.md}
  main_of "$repo"
  case $seen in
    *"$NL$main$NL"*) continue ;;
  esac
  seen="$seen$main$NL"
  name=${main##*/}
  printf '%s\n' "메인 체크아웃($name): $main"
  printf '%s\n' "현황($name): $main/docs/waypoint/STATUS.md"
  summary "$main" count
done
printf '%s\n' '작업을 시작하면 `waypoint:start` 스킬을 호출한다.'
printf '%s\n' '</waypoint>'
exit 0
