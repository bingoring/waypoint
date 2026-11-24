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

# templates-copied: _templates/ 의 모든 파일이 plugin/templates/ 에 같은 상대 경로로 있고, STATUS 템플릿도 있다.
for f in $(cd _templates && find . -type f | sed 's#^\./##'); do
  [ -f "$P/templates/$f" ] || fail templates-copied "$P/templates/$f 없음"
done
[ -f "$P/templates/STATUS.template.md" ] || fail templates-copied "$P/templates/STATUS.template.md 없음"

# templates-no-old-ref: 플러그인 템플릿이 옛 경로나 FRAMEWORK를 가리키지 않는다.
if [ -d "$P/templates" ]; then
  hits=$(grep -rnE '_templates|FRAMEWORK' "$P/templates")
  [ -z "$hits" ] || fail templates-no-old-ref "$hits"
fi

# block-and-settings: CLAUDE.md 블록과 프로젝트 설정 템플릿.
B="$P/templates/claude-md-block.md"
if [ -f "$B" ]; then
  grep -qF '## Waypoint' "$B" || fail block-and-settings "블록에 '## Waypoint' 없음"
  grep -qF 'docs/waypoint/STATUS.md' "$B" || fail block-and-settings "블록에 STATUS 경로 없음"
else
  fail block-and-settings "$B 없음"
fi
python3 -m json.tool "$P/templates/project-settings.json" > /dev/null 2>&1 \
  || fail block-and-settings "project-settings.json 이 없거나 JSON이 아님"
grep -qF '"waypoint@waypoint": true' "$P/templates/project-settings.json" 2>/dev/null \
  || fail block-and-settings "enabledPlugins 항목 없음"

# commit-msg: 공동작업 트레일러가 든 메시지는 거부하고, 일반 메시지는 받는다.
H="$P/githooks/commit-msg"
if [ -x "$H" ]; then
  M=$(mktemp)
  printf 'feat: x\n\nCo-Authored-By: A <a@b>\n' > "$M"
  sh "$H" "$M" 2>/dev/null && fail commit-msg-rejects "Co-Authored-By 메시지를 받아들임"
  printf 'feat: x\n\n\360\237\244\226 Generated with [Claude Code](https://claude.com/claude-code)\n' > "$M"
  sh "$H" "$M" 2>/dev/null && fail commit-msg-rejects-2 "Generated with 메시지를 받아들임"
  printf 'feat: x\n' > "$M"
  sh "$H" "$M" 2>/dev/null || fail commit-msg-accepts "일반 메시지를 거부함"
  rm -f "$M"
else
  fail commit-msg-rejects "$H 없음 또는 실행 권한 없음"
fi

# init-skill: init 스킬이 있고 블록과 설정 템플릿을 쓴다.
I="$P/skills/init/SKILL.md"
if [ -f "$I" ]; then
  grep -qF 'claude-md-block.md' "$I" || fail init-skill "claude-md-block.md 언급 없음"
  grep -qF 'project-settings.json' "$I" || fail init-skill "project-settings.json 언급 없음"
else
  fail init-skill "$I 없음"
fi

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
