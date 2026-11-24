#!/bin/sh
# 플러그인 파일(스킬·core-rules·템플릿·commit-msg 훅)을 검사한다.
# 실행: sh tests/plugin-files.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1
P=plugin
SKILLS="start stage build-spec review-gate decisions git"
GUARD='docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다'
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

# skills-exist: 여섯 스킬 파일이 모두 있다.
for s in $SKILLS; do
  [ -f "$P/skills/$s/SKILL.md" ] || fail skills-exist "$P/skills/$s/SKILL.md 없음"
done

# skills-have-guard: 여섯 스킬 모두 옛 방식 레포를 위한 안내문을 담고 있다.
for s in $SKILLS; do
  [ -f "$P/skills/$s/SKILL.md" ] || continue
  grep -qF -e "$GUARD" "$P/skills/$s/SKILL.md" || fail skills-have-guard "$s 에 안내문 없음"
done

# core-rules-size: core-rules.md 가 있고 40줄 이하이며 첫 줄이 정해진 제목이다.
if [ -f "$P/core-rules.md" ]; then
  n=$(wc -l < "$P/core-rules.md" | tr -d ' ')
  [ "$n" -le 40 ] || fail core-rules-size "$n 줄 (40 초과)"
  first=$(head -n 1 "$P/core-rules.md")
  [ "$first" = "# waypoint 핵심 규칙" ] || fail core-rules-size "첫 줄 '$first'"
else
  fail core-rules-size "$P/core-rules.md 없음"
fi

# no-old-paths: core-rules 와 스킬에 옛 경로가 없다(안내문 줄은 제외).
for f in "$P/core-rules.md" "$P"/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  hits=$(grep -vF -e "$GUARD" "$f" | grep -nE '_templates/|docs/dlc')
  [ -z "$hits" ] || fail no-old-paths "$f: $hits"
done

# framework-split: FRAMEWORK.md 의 모든 줄이 정확히 한 곳에 있거나 대조표에 적혀 있다.
MAP=docs/superpowers/specs/2026-11-24-framework-split-map.md
if [ -f "$MAP" ]; then
  # shellcheck disable=SC2086
  out=$(sh tests/check-framework-split.sh FRAMEWORK.md "$MAP" "$P/core-rules.md" "$P"/skills/*/SKILL.md) \
    || fail framework-split "$out"
else
  fail framework-split "$MAP 없음"
fi

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
