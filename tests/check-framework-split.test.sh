#!/bin/sh
# tests/check-framework-split.sh 의 동작을 고정 입력으로 확인한다.
# 실행: sh tests/check-framework-split.test.sh (레포 루트에서)

HERE=$(cd "$(dirname "$0")" && pwd)
CHECK="$HERE/check-framework-split.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

# 공통 framework: 제목·빈 줄·코드 펜스·표 구분선은 검사 대상이 아니고, 규칙 문장 두 줄만 검사 대상이다.
cat > "$T/fw.md" <<'EOF'
# 제목

- 첫째 규칙 문장입니다
  둘째 규칙 문장입니다
```
|---|---|
EOF
: > "$T/empty-map.md"

# case_ok + case_skips: 두 문장이 target에 한 번씩 있으면 통과하고, 검사한 줄 수는 2다.
printf '%s\n' '- 첫째 규칙 문장입니다' '둘째 규칙 문장입니다' > "$T/ok.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/empty-map.md" "$T/ok.md"); rc=$?
[ "$rc" -eq 0 ] || fail case_ok "exit $rc, want 0: $out"
last=$(printf '%s\n' "$out" | tail -n 1)
[ "$last" = "OK: 2 lines" ] || fail case_skips "last line '$last', want 'OK: 2 lines'"

# case_missing: 둘째 문장이 없으면 실패하고 그 문장을 MISSING으로 알린다.
printf '%s\n' '- 첫째 규칙 문장입니다' > "$T/missing.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/empty-map.md" "$T/missing.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_missing "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'MISSING: 둘째 규칙 문장입니다' || fail case_missing "no MISSING line: $out"

# case_mapped: 빠진 문장이 대조표(map)에 적혀 있으면 통과한다.
printf '%s\n' '| 둘째 규칙 문장입니다 | (고친 문장) | 경로 |' > "$T/map.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/map.md" "$T/missing.md"); rc=$?
[ "$rc" -eq 0 ] || fail case_mapped "exit $rc, want 0: $out"

# case_duplicate: 같은 문장이 두 target에 있으면 실패하고 DUPLICATE(2)로 알린다.
printf '%s\n' '첫째 규칙 문장입니다' > "$T/dup.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/empty-map.md" "$T/ok.md" "$T/dup.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_duplicate "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'DUPLICATE(2): 첫째 규칙 문장입니다' || fail case_duplicate "no DUPLICATE line: $out"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
