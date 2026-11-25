#!/bin/sh
# tests/check-framework-split.sh 의 동작을 고정 입력으로 확인한다.
# 실행: sh tests/check-framework-split.test.sh (레포 루트에서)

HERE=$(cd "$(dirname "$0")" && pwd)
CHECK="$HERE/check-framework-split.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

# 공통 framework: 제목·빈 줄·코드 펜스·표 구분선은 검사 대상이 아니고, 규칙 문장 세 줄만 검사 대상이다.
cat > "$T/fw.md" <<'EOF'
# 제목

- 첫째 규칙 문장입니다
  둘째 규칙 문장입니다
```
|---|---|
- 셋째 규칙 문장입니다
EOF
: > "$T/empty-map.md"

# 대조표: 2절(고친 문장), 3절(두 곳에 둔 문장), 4절(옮기지 않은 문장)
cat > "$T/map.md" <<'EOF'
# 대조표

## 2. 고친 문장

### 2-1
- 원문: 둘째 규칙 문장입니다
- 새 문장: 둘째 규칙 문장을 고쳤습니다

## 3. 두 곳에 둔 문장

- 첫째 규칙 문장입니다

## 4. 옮기지 않은 문장

| 원문 | 사유 |
|---|---|
| 셋째 규칙 문장입니다 | 옮길 곳이 없다 |
EOF

all3() { printf '%s\n' '- 첫째 규칙 문장입니다' '둘째 규칙 문장입니다' '셋째 규칙 문장입니다'; }

# case_ok + case_skips: 세 문장이 target에 한 번씩 있으면 통과하고, 검사한 줄 수는 3이다.
all3 > "$T/ok.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/empty-map.md" "$T/ok.md"); rc=$?
[ "$rc" -eq 0 ] || fail case_ok "exit $rc, want 0: $out"
last=$(printf '%s\n' "$out" | tail -n 1)
[ "$last" = "OK: 3 lines" ] || fail case_skips "last line '$last', want 'OK: 3 lines'"

# case_missing: 대조표에 없는 문장이 빠지면 MISSING으로 실패한다.
printf '%s\n' '- 첫째 규칙 문장입니다' '셋째 규칙 문장입니다' > "$T/missing.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/empty-map.md" "$T/missing.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_missing "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'MISSING: 둘째 규칙 문장입니다' || fail case_missing "no MISSING line: $out"

# case_duplicate: 대조표에 없는 문장이 두 곳에 있으면 DUPLICATE(2)로 실패한다.
printf '%s\n' '첫째 규칙 문장입니다' > "$T/dup.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/empty-map.md" "$T/ok.md" "$T/dup.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_duplicate "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'DUPLICATE(2): 첫째 규칙 문장입니다' || fail case_duplicate "no DUPLICATE line: $out"

# 대조표를 쓰는 정상 대상: 첫째는 두 곳, 둘째는 고친 문장으로, 셋째는 옮기지 않음
printf '%s\n' '- 첫째 규칙 문장입니다' '둘째 규칙 문장을 고쳤습니다' > "$T/a.md"
printf '%s\n' '첫째 규칙 문장입니다 (자세히)' > "$T/b.md"

# case_mapped: 대조표대로 옮겼으면 통과한다.
out=$(sh "$CHECK" "$T/fw.md" "$T/map.md" "$T/a.md" "$T/b.md"); rc=$?
[ "$rc" -eq 0 ] || fail case_mapped "exit $rc, want 0: $out"

# case_new_missing: 대조표에 적힌 새 문장이 대상에서 사라지면 실패한다.
printf '%s\n' '- 첫째 규칙 문장입니다' > "$T/a2.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/map.md" "$T/a2.md" "$T/b.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_new_missing "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'MISSING-NEW(0/1): 둘째 규칙 문장을 고쳤습니다' || fail case_new_missing "no MISSING-NEW line: $out"

# case_dup_lost: 두 곳에 두기로 한 문장이 한 곳에서 사라지면 실패한다.
out=$(sh "$CHECK" "$T/fw.md" "$T/map.md" "$T/a.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_dup_lost "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'EXPECTED-2(1): 첫째 규칙 문장입니다' || fail case_dup_lost "no EXPECTED-2 line: $out"

# case_dup_gone: 두 곳에 두기로 한 문장이 양쪽에서 모두 사라져도 실패한다.
printf '%s\n' '둘째 규칙 문장을 고쳤습니다' > "$T/a3.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/map.md" "$T/a3.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_dup_gone "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'EXPECTED-2(0): 첫째 규칙 문장입니다' || fail case_dup_gone "no EXPECTED-2(0) line: $out"

# case_original_left: 고쳤다고 적은 원문이 대상에 그대로 남아 있으면(두 곳) 실패한다.
printf '%s\n' '둘째 규칙 문장입니다' '둘째 규칙 문장입니다' > "$T/c.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/map.md" "$T/a.md" "$T/b.md" "$T/c.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_original_left "exit $rc, want 1"

# case_ellipsis: 대조표의 새 문장에 줄임표가 있으면 실패한다(전문을 적어야 대조할 수 있다).
sed 's/- 새 문장: 둘째 규칙 문장을 고쳤습니다/- 새 문장: 둘째 … 고쳤습니다/' "$T/map.md" > "$T/map-ellipsis.md"
out=$(sh "$CHECK" "$T/fw.md" "$T/map-ellipsis.md" "$T/a.md" "$T/b.md"); rc=$?
[ "$rc" -eq 1 ] || fail case_ellipsis "exit $rc, want 1"
printf '%s\n' "$out" | grep -qF 'ELLIPSIS:' || fail case_ellipsis "no ELLIPSIS line: $out"

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
