#!/bin/sh
# FRAMEWORK.md 의 각 줄이 새 파일들(target) 가운데 정확히 한 곳에 옮겨졌는지 검사한다.
#
# 사용: check-framework-split.sh <framework.md> <map.md> <target>...
#
# 판정 (n = 그 줄을 포함하는 target 줄의 수)
#   - n = 1                         : 통과
#   - 대조표 3절(두 곳에 둔 문장)     : n = 2 여야 한다      → 아니면 EXPECTED-2(n)
#   - 대조표 2절 원문 / 4절 원문      : n = 0 이어야 한다    → 아니면 DUPLICATE(n)
#   - 그 밖                          : MISSING / DUPLICATE(n)
# 대조표 자체도 검사한다
#   - 3절의 각 줄은 n = 2 여야 한다(FRAMEWORK 쪽 판정과 별도로)
#   - 2절의 각 「새 문장」은 대조표에 적힌 횟수 이상 target에 있어야 한다 → 아니면 MISSING-NEW
#   - 「새 문장」에 줄임표(…)를 쓰면 안 된다(전문이 있어야 대조할 수 있다) → ELLIPSIS
#
# 대조표 형식
#   ## 2. …          아래의 "- 원문: <줄>" / "- 새 문장: <줄>"
#   ## 3. …          아래의 "- <줄>"
#   ## 4. …          아래 표의 첫 칸 "| <줄> | 사유 |"
#
# 출력: 문제마다 한 줄, 문제가 없으면 마지막 줄 "OK: <검사한 FRAMEWORK 줄 수> lines"
# 종료 코드: 문제가 있으면 1, 없으면 0

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <framework.md> <map.md> <target>..." >&2
  exit 2
fi

fw=$1
map=$2
shift 2

W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
: > "$W/orig"; : > "$W/new"; : > "$W/dup"; : > "$W/dropped"
cat "$@" > "$W/targets"

count() { grep -cF -e "$1" "$W/targets"; }

# --- 대조표 읽기 ---
sec=
while IFS= read -r l || [ -n "$l" ]; do
  case $l in
    '## 2.'*) sec=2; continue ;;
    '## 3.'*) sec=3; continue ;;
    '## 4.'*) sec=4; continue ;;
    '## '*) sec=; continue ;;
  esac
  case $sec in
    2)
      case $l in
        '- 원문: '*) printf '%s\n' "${l#- 원문: }" >> "$W/orig" ;;
        '- 새 문장: '*) printf '%s\n' "${l#- 새 문장: }" >> "$W/new" ;;
      esac
      ;;
    3)
      case $l in
        '- '*) printf '%s\n' "${l#- }" >> "$W/dup" ;;
      esac
      ;;
    4)
      case $l in
        '|---'* | '| 원문 |'*) ;;
        '| '*)
          cell=${l#| }
          printf '%s\n' "${cell%% | *}" >> "$W/dropped"
          ;;
      esac
      ;;
  esac
done < "$map"

in_list() { grep -qxF -e "$1" "$2"; }

checked=0
problems=0
report() { echo "$1"; problems=$((problems + 1)); }

# --- FRAMEWORK 줄 검사 ---
while IFS= read -r line || [ -n "$line" ]; do
  s=$line
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}

  case $s in
    '' | '#'* | '```'* | '|-'*) continue ;;
  esac

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

  n=$(count "$s")
  [ "$n" -eq 1 ] && ! in_list "$s" "$W/dup" && continue

  if in_list "$s" "$W/dup"; then
    [ "$n" -eq 2 ] || report "EXPECTED-2($n): $s"
  elif in_list "$s" "$W/orig" || in_list "$s" "$W/dropped"; then
    [ "$n" -eq 0 ] || report "DUPLICATE($n): $s"
  elif [ "$n" -eq 0 ]; then
    report "MISSING: $s"
  else
    report "DUPLICATE($n): $s"
  fi
done < "$fw"

# --- 대조표 쪽 검사 ---
while IFS= read -r s || [ -n "$s" ]; do
  [ -n "$s" ] || continue
  case $s in
    *'…'*) report "ELLIPSIS: $s"; continue ;;
  esac
  need=$(grep -cxF -e "$s" "$W/new")
  n=$(count "$s")
  [ "$n" -ge "$need" ] || report "MISSING-NEW($n/$need): $s"
done < "$W/new"

if [ "$problems" -gt 0 ]; then
  echo "$problems problem(s) in $checked lines"
  exit 1
fi
echo "OK: $checked lines"
