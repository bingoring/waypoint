#!/bin/sh
# plugin/scripts/board-sync.sh(보드 동기화, 4단계 설계 5.6~5.8절)를 가짜 gh로 확인한다.
# 실행: sh tests/board-sync.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
BS="$ROOT/plugin/scripts/board-sync.sh"
T=$(mktemp -d)
T=$(cd "$T" && pwd -P)
trap 'rm -rf "$T"' EXIT
fails=0
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

export FAKE_GH_DIR="$T/state" FAKE_GH_LOG="$T/gh.log"
export PATH="$ROOT/tests/fake-gh:$PATH"
. "$ROOT/tests/board-lib.sh"

# ---- Task 3: STATUS에서 원하는 카드 계산 ----
WP_BOARD_SYNC_LIB=1 . "$BS"

cat > "$T/STATUS.md" <<'EOF'
# t — waypoint 현황

## 스테이지

| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |
|---|---|---|---|---|---|---|
| 1-1 | 설계 | MERGED | | | | [문서](a.md) |
| 1-3 | Architecture Decision ⚠️ | PENDING | | | | |
| 2-1 | 구현 "따옴표" \ 역슬래시 | IN_PROGRESS | 앱 | 구현: 시험 중 | | [#1](https://github.com/test/repo/pull/1) |
| 2-2 | 검토 | AI_PROPOSED | 출시 | 결과 검토: 시험 | 오너 할 일 | [#2](https://github.com/test/repo/pull/2) |
| 2-3 | 승인 | HUMAN_APPROVED | | 배포 묶음 | 오너 할 일 | [#3](https://github.com/test/repo/pull/3) |
| R-1 | Review 🔍 | DEFERRED | | 구현: 보류 | Play 신원확인 | |

## 오너 할 일

- [ ] 키 발급 (막음: 2-2)
- [ ] 계정 만들기 (막음: 2-2, R-1)
- [ ] 도메인 구입
EOF
wp_desired_cards "$T/STATUS.md" > "$T/desired.jsonl"
d() { jq -r --arg id "$1" "select(.id == \$id) | $2" "$T/desired.jsonl"; }

[ "$(wc -l < "$T/desired.jsonl" | tr -d ' ')" = 6 ] || fail desired-count "$(cat "$T/desired.jsonl")"
for pair in "1-1 머지됨" "1-3 대기" "2-1 진행 중" "2-2 검토 대기" "2-3 승인" "R-1 보류"; do
  id=${pair%% *}; want=${pair#* }
  [ "$(d "$id" .status)" = "$want" ] || fail desired-status "$id: $(d "$id" .status) (기대 $want)"
done
[ "$(d 1-1 .open)" = false ] || fail desired-open "MERGED는 닫힘"
[ "$(d 2-1 .open)" = true ] || fail desired-open "IN_PROGRESS는 열림"
[ "$(d R-1 .open)" = true ] || fail desired-open "DEFERRED는 열림"
[ "$(d 1-3 .title)" = "[1-3] Architecture Decision ⚠️" ] || fail desired-title "$(d 1-3 .title)"
[ "$(d 2-1 .title)" = '[2-1] 구현 "따옴표" \ 역슬래시' ] || fail desired-escape "$(d 2-1 .title)"
[ "$(d 2-1 .stem)" = 앱 ] || fail desired-stem "$(d 2-1 .stem)"
[ "$(d 1-3 .stem)" = "" ] || fail desired-stem-empty "$(d 1-3 .stem)"
[ "$(d 1-3 .now)" = "" ] || fail desired-now-empty "$(d 1-3 .now)"
[ "$(d 2-1 .phase)" = 2 ] || fail desired-phase "$(d 2-1 .phase)"
[ "$(d R-1 .phase)" = R ] || fail desired-phase-r "$(d R-1 .phase)"
[ "$(d 2-2 .wait)" = "오너 할 일: 키 발급 · 계정 만들기" ] || fail wait-two "$(d 2-2 .wait)"
[ "$(d 2-3 .wait)" = "오너 할 일" ] || fail wait-none "$(d 2-3 .wait)"
[ "$(d R-1 .wait)" = "Play 신원확인" ] || fail wait-plain "$(d R-1 .wait)"
[ "$(d 2-1 .wait)" = "" ] || fail wait-empty "$(d 2-1 .wait)"
# R-1이 막힌 오너 할 일이 있어도 「기다림」이 오너 할 일이 아니면 그대로 둔다(설계 5.2절: 값이 「오너 할 일」일 때만 확장)

# board-urls: CLAUDE.md 의 「- 보드:」 줄
printf '# r\n\n## Waypoint\n\n- 이 레포는 waypoint\n' > "$T/c0.md"
[ -z "$(wp_board_urls "$T/c0.md" 2>/dev/null)" ] || fail urls-none "줄이 없는데 주소가 나옴"
printf -- '- 보드: https://github.com/users/test/projects/1\n' > "$T/c1.md"
[ "$(wp_board_urls "$T/c1.md")" = "https://github.com/users/test/projects/1" ] || fail urls-one "$(wp_board_urls "$T/c1.md")"
printf -- '- 보드: https://github.com/users/test/projects/1 https://github.com/orgs/o/projects/22/\n' > "$T/c2.md"
[ "$(wp_board_urls "$T/c2.md" | wc -l | tr -d ' ')" = 2 ] || fail urls-two "$(wp_board_urls "$T/c2.md")"
printf -- '- 보드: https://example.com/x https://github.com/users/test/projects/1\n' > "$T/c3.md"
out=$(wp_board_urls "$T/c3.md" 2> "$T/err")
[ "$out" = "https://github.com/users/test/projects/1" ] || fail urls-bad "$out"
grep -qF 'example.com' "$T/err" || fail urls-bad-warn "경고 없음"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
