#!/bin/sh
# plugin/scripts/status-check.sh(STATUS 형식 검사, 설계 5.5절 「검사 2」)를 확인한다.
# 실행: sh tests/status-check.test.sh (레포 루트에서)

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
C="$ROOT/plugin/scripts/status-check.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0

fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

# ok <경우> <명령>...: 종료 코드 0, 출력 없음
ok() {
  n=$1; shift
  out=$("$@" 2>&1); rc=$?
  [ "$rc" -eq 0 ] || fail "$n" "exit $rc: $out"
  [ -z "$out" ] || fail "$n" "출력이 있음: $out"
}

# bad <경우> <검사 번호> <명령>...: 종료 코드 1, 출력에 "[검사 k]"
bad() {
  n=$1; k=$2; shift 2
  out=$("$@" 2>&1); rc=$?
  [ "$rc" -eq 1 ] || fail "$n" "exit $rc (1 기대): $out"
  case $out in
    *"[검사 $k]"*) ;;
    *) fail "$n" "'[검사 $k]' 없음: $out" ;;
  esac
}

# mk <경우> <필터 명령>...: good.md 를 필터에 통과시켜 <경우>.md 를 만든다. 바뀐 것이 없으면 테스트 자체의 오류다.
mk() {
  n=$1; shift
  "$@" < "$T/good.md" > "$T/$n.md"
  cmp -s "$T/good.md" "$T/$n.md" && fail "$n" "필터가 아무것도 바꾸지 않음(테스트 오류)"
}

L80="구현: $(printf '가%.0s' $(seq 76))"
L81="${L80}가"

cat > "$T/good.md" <<EOF
# 테스트 — waypoint 현황

[PRD](prd.md) · [결정 로그](DECISIONS.md)

## 스테이지

| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |
|---|---|---|---|---|---|---|
| 1-1 | Context Synthesis | MERGED | | | | [문서](01-inception/01-context.md) |
| 1-2 | Domain Model | PENDING | | | | |
| 2-9 | 상황 학습 | MERGED | 콘텐츠 | | | [문서](./02-construction/09-a.md) · [#38](https://github.com/o/r/pull/38) |
| 2-10 | 묶음 저작 | IN_PROGRESS | 콘텐츠 | $L80 | | [#39](https://github.com/o/r/pull/39) |
| 2-11 | 설계 초안 | IN_PROGRESS | | 계획: 설계 초안 작성 | | [문서](02-construction/11-b.md) |
| 3-1 | Deployment | AI_PROPOSED | 출시 | 결과 검토: Android 첫 빌드 | 오너 할 일 | [#40](https://github.com/o/r/pull/40) |
| 3-2 | Monitoring | HUMAN_APPROVED | 출시 | 배포 묶음을 모아 한 번에 머지 | | [#41](https://github.com/o/r/pull/41) |
| 3-3 | 알림 | DEFERRED | | 구현: 오너 보류, 출시 뒤 재개 | | |

## 오너 할 일

- [ ] Google Play 서비스 계정 키 발급 (막음: 3-1, 3-2)
- [ ] 도메인 구입
EOF
printf '01-inception/01-context.md\t1-1\n02-construction/09-a.md\t2-9\n' > "$T/ids"

# 통과 예시
ok good sh "$C" "$T/good.md" "$T/ids"
ok good-content-only sh "$C" "$T/good.md"

# 검사 1: 절과 머리 줄
mk h1-no-section sed '/^## 스테이지$/d'
bad h1-no-section 1 sh "$C" "$T/h1-no-section.md" "$T/ids"
mk h1-header sed 's/^| ID | 스테이지 |/| ID | 이름 |/'
bad h1-header 1 sh "$C" "$T/h1-header.md" "$T/ids"

# 검사 2: 칸 수
mk c2-cells sed 's/^| 1-2 | Domain Model | PENDING | | | | |$/| 1-2 | Domain Model | PENDING | | | |/'
bad c2-cells 2 sh "$C" "$T/c2-cells.md" "$T/ids"

# 검사 3: 상태 값
mk s3-state sed 's/| AI_PROPOSED |/| IMPLEMENTED |/'
bad s3-state 3 sh "$C" "$T/s3-state.md" "$T/ids"

# 검사 4: ID
mk i4-format sed 's/^| 2-11 |/| 2-9a |/'
bad i4-format 4 sh "$C" "$T/i4-format.md" "$T/ids"
mk i4-dup sed 's/^| 2-11 |/| 2-10 |/'
bad i4-dup 4 sh "$C" "$T/i4-dup.md" "$T/ids"

# 검사 5: 「지금」 (80자 경계는 로케일과 상관없이)
for loc in C unset; do
  if [ "$loc" = C ]; then run="env LC_ALL=C"; else run="env -u LANG -u LC_ALL -u LC_CTYPE"; fi
  # shellcheck disable=SC2086
  ok "now-80($loc)" $run sh "$C" "$T/good.md" "$T/ids"
done
mk now-81 sed "s/$L80/$L81/"
for loc in C unset; do
  if [ "$loc" = C ]; then run="env LC_ALL=C"; else run="env -u LANG -u LC_ALL -u LC_CTYPE"; fi
  # shellcheck disable=SC2086
  bad "now-81($loc)" 5 $run sh "$C" "$T/now-81.md" "$T/ids"
done
mk n5-pending sed 's/^| 1-2 | Domain Model | PENDING | | |/| 1-2 | Domain Model | PENDING | | 메모 |/'
bad n5-pending 5 sh "$C" "$T/n5-pending.md" "$T/ids"
mk n5-prefix sed 's/| 계획: 설계 초안 작성 |/| 설계 초안 작성 |/'
bad n5-prefix 5 sh "$C" "$T/n5-prefix.md" "$T/ids"
mk n5-wrong-prefix sed 's/| 결과 검토: Android 첫 빌드 |/| 구현: Android 첫 빌드 |/'
bad n5-wrong-prefix 5 sh "$C" "$T/n5-wrong-prefix.md" "$T/ids"

# 검사 6: MERGED 줄의 문서 링크(내용 검사만일 때는 건너뜀)
mk m6-pr-only sed 's#\[문서\](\./02-construction/09-a\.md) · ##'
bad m6-pr-only 6 sh "$C" "$T/m6-pr-only.md" "$T/ids"
mk m6-missing sed 's#\./02-construction/09-a\.md#./02-construction/09-z.md#'
bad m6-missing 6 sh "$C" "$T/m6-missing.md" "$T/ids"
printf '01-inception/01-context.md\t1-1\n02-construction/09-a.md\t2-8\n' > "$T/ids-m6"
bad m6-id 6 sh "$C" "$T/good.md" "$T/ids-m6"
ok m6-content-only sh "$C" "$T/m6-pr-only.md"

# 검사 7: 활성 줄의 링크
mk l7-no-link sed 's#| \[\#39\](https://github.com/o/r/pull/39) |$#| |#'
bad l7-no-link 7 sh "$C" "$T/l7-no-link.md" "$T/ids"

# 검사 8: id 가 있는 문서마다 표에 줄(내용 검사만일 때는 건너뜀)
{ cat "$T/ids"; printf '02-construction/15-x.md\t2-15\n'; } > "$T/ids-d8"
bad d8-missing-row 8 sh "$C" "$T/good.md" "$T/ids-d8"
ok d8-content-only sh "$C" "$T/good.md"

# 검사 9: 오너 할 일의 (막음: …)
mk b9-block sed 's/(막음: 3-1, 3-2)/(막음: 3-1, 9-9)/'
bad b9-block 9 sh "$C" "$T/b9-block.md" "$T/ids"

# 검사 10: 허용하는 줄만
mk a10-banner awk '{ print } /^\[PRD\]/ { print "> **배너**" }'
bad a10-banner 10 sh "$C" "$T/a10-banner.md" "$T/ids"
mk a10-section awk '{ print } END { print ""; print "## 메모"; print "- 아무거나" }'
bad a10-section 10 sh "$C" "$T/a10-section.md" "$T/ids"
mk a10-two-links awk '{ print } /^\[PRD\]/ { print }'
bad a10-two-links 10 sh "$C" "$T/a10-two-links.md" "$T/ids"
mk a10-checked sed 's/^- \[ \] 도메인 구입$/- [x] 도메인 구입/'
bad a10-checked 10 sh "$C" "$T/a10-checked.md" "$T/ids"

# 여러 문제는 모두 보고한다.
mk two-problems sed -e 's/| AI_PROPOSED |/| IMPLEMENTED |/' -e 's/(막음: 3-1, 3-2)/(막음: 3-1, 9-9)/'
out=$(sh "$C" "$T/two-problems.md" "$T/ids" 2>&1); rc=$?
[ "$rc" -eq 1 ] || fail two-problems "exit $rc (1 기대)"
case $out in *"[검사 3]"*) ;; *) fail two-problems "'[검사 3]' 없음: $out" ;; esac
case $out in *"[검사 9]"*) ;; *) fail two-problems "'[검사 9]' 없음: $out" ;; esac

if [ "$fails" -gt 0 ]; then
  echo "$fails failed"
  exit 1
fi
echo "all passed"
