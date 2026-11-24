#!/bin/sh
# FRAMEWORK.md 의 각 줄이 새 파일들(target) 가운데 정확히 한 곳에 옮겨졌는지 검사한다.
# 한 곳이 아닌 줄(빠졌거나 두 곳 이상)은 대조표(map)에 그 줄이 적혀 있어야 통과한다.
#
# 사용: check-framework-split.sh <framework.md> <map.md> <target>...
# 출력: 문제마다 "MISSING: <줄>" 또는 "DUPLICATE(<n>): <줄>", 문제가 없으면 마지막 줄 "OK: <N> lines"
# 종료 코드: 문제가 있으면 1, 없으면 0

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <framework.md> <map.md> <target>..." >&2
  exit 2
fi

fw=$1
map=$2
shift 2

checked=0
problems=0

while IFS= read -r line || [ -n "$line" ]; do
  s=$line
  # 앞뒤 공백 제거
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}

  # 검사하지 않는 줄
  case $s in
    '' | '#'* | '```'* | '|-'*) continue ;;
  esac

  # 줄 앞 표지 하나 떼기
  case $s in
    '> '*) s=${s#> } ;;
    '- [ ] '*) s=${s#- \[ \] } ;;
    '- '*) s=${s#- } ;;
    '* '*) s=${s#\* } ;;
    [0-9]*'. '*)
      num=${s%%. *}
      case $num in
        *[!0-9]*) ;;
        *) s=${s#*. } ;;
      esac
      ;;
  esac

  [ "${#s}" -lt 8 ] && continue
  checked=$((checked + 1))

  n=$(cat "$@" | grep -cF -e "$s")
  [ "$n" -eq 1 ] && continue
  grep -qF -e "$s" "$map" && continue

  problems=$((problems + 1))
  if [ "$n" -eq 0 ]; then
    echo "MISSING: $s"
  else
    echo "DUPLICATE($n): $s"
  fi
done < "$fw"

if [ "$problems" -gt 0 ]; then
  echo "$problems problem(s) in $checked lines"
  exit 1
fi
echo "OK: $checked lines"
