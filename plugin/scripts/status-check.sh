#!/bin/sh
# waypoint STATUS 형식 검사(설계 docs/superpowers/specs/2026-11-25-status-cleanup-design.md 5.5절 「검사 2」).
#
# 사용: status-check.sh <STATUS 파일> [<id 목록 파일>]
#   - id 목록 파일: 한 줄에 "<docs/waypoint 기준 상대 경로><TAB><id>".
#     주면 검사 1~10을 모두 하고, 주지 않으면 index가 필요한 검사 6과 8을 건너뛴다(내용 검사만).
#   - 통과하면 아무것도 출력하지 않고 0. 실패하면 문제마다 stderr에 한 줄을 쓰고 1.
#
# 아래 표지 줄 사이의 블록은 plugin/githooks/pre-commit에 글자 그대로 들어 있다
# (tests/plugin-files.test.sh의 hook-block-match가 확인한다). 블록을 고치면 훅도 같이 고치고 훅 버전을 올린다.

# >>> waypoint status-check >>>
# wp_status_check <STATUS 파일> [<id 목록 파일>]
# 글자 수는 UTF-8 연속 바이트(0x80-0xBF)를 뺀 바이트 수로 센다. 로케일과 상관없이 한글 한 글자가 1이 된다.
wp_status_check() {
  _wp_out=$(LC_ALL=C awk -v ids="${2:-}" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function clen(s) { gsub(/[\200-\277]/, "", s); return length(s) }
function bad(ln, k, msg) {
  if (ln == "") print "STATUS.md: [검사 " k "] " msg
  else print "STATUS.md:" ln ": [검사 " k "] " msg
}
function starts(s, p) { return substr(s, 1, length(p)) == p }
BEGIN {
  HEADER = "| ID | 스테이지 | 상태 | 줄기 | 지금 | 기다림 | 링크 |"
  split("PENDING IN_PROGRESS AI_PROPOSED HUMAN_APPROVED MERGED DEFERRED", sv, " ")
  for (i in sv) okstate[sv[i]] = 1
  P1 = "계획: "; P2 = "구현: "; P3 = "계획 검토: "; P4 = "결과 검토: "
  ALLOWED = "STATUS에는 제목, 링크 한 줄, \"## 스테이지\" 표, \"## 오너 할 일\"의 \"- [ ] \" 줄만 둔다(지난 기록은 HISTORY.md, 하위 진행은 스테이지 문서의 \"진행 기록\")"
  full = (ids != "")
  nid = 0
  if (full) {
    while ((r = (getline l < ids)) > 0) {
      sub(/\r$/, "", l)
      if (l == "") continue
      t = index(l, "\t")
      if (t == 0) continue
      p = substr(l, 1, t - 1); v = substr(l, t + 1)
      docid[p] = v
      nid++; idpath[nid] = p
    }
    if (r < 0) { print "STATUS.md: [검사 6] id 목록 파일 " ids "을 읽을 수 없다."; exit 1 }
  }
  sec = "head"; heads = 0; tstate = ""; seen_stage = 0; nblock = 0
}
{
  line = $0
  sub(/\r$/, "", line)
  ln = NR
  if (NR == 1) {
    if (!starts(line, "# ")) bad(ln, 10, "첫 줄은 \"# <프로젝트> — waypoint 현황\" 같은 제목이어야 한다. " ALLOWED ".")
    next
  }
  if (starts(line, "## ")) {
    if (line == "## 스테이지") {
      if (seen_stage) bad(ln, 10, "\"## 스테이지\" 절이 두 번 있다. 표는 하나만 둔다.")
      sec = "stage"; seen_stage = 1; tstate = "header"
    } else if (line == "## 오너 할 일") {
      sec = "owner"
    } else {
      bad(ln, 10, "허용하지 않는 절이다. " ALLOWED ".")
      sec = "other"
    }
    next
  }
  if (sec == "other") next
  if (starts(line, "#")) { bad(ln, 10, "허용하지 않는 제목 줄이다. " ALLOWED "."); next }
  if (line ~ /^[ \t]*$/) {
    if (sec == "stage" && tstate == "rows") tstate = "done"
    next
  }
  if (sec == "head") {
    heads++
    if (heads > 1 || index(line, "](") == 0) bad(ln, 10, "제목과 \"## 스테이지\" 사이에는 링크 한 줄만 둔다. " ALLOWED ".")
    next
  }
  if (sec == "owner") {
    if (!starts(line, "- [ ] ")) { bad(ln, 10, "\"## 오너 할 일\"에는 \"- [ ] <할 일> (막음: <ID>)\" 줄만 둔다. 끝난 할 일은 체크하지 말고 줄을 지운다."); next }
    rest = line; sub(/[ \t]+$/, "", rest)
    if (match(rest, /\(막음: [^)]*\)$/)) {
      lst = substr(rest, RSTART + length("(막음: "), RLENGTH - length("(막음: ") - 1)
      m = split(lst, bi, ",")
      for (j = 1; j <= m; j++) { nblock++; bid[nblock] = trim(bi[j]); bln[nblock] = ln }
    }
    next
  }
  # sec == "stage"
  if (!starts(line, "|") || tstate == "done") {
    bad(ln, 10, "\"## 스테이지\" 아래에는 표 하나만 둔다. " ALLOWED ".")
    next
  }
  if (tstate == "header") {
    if (trim(line) != HEADER) bad(ln, 1, "표의 머리 줄이 정해진 형식과 다르다. \"" HEADER "\"로 쓴다.")
    tstate = "sep"; next
  }
  if (tstate == "sep") {
    s = trim(line); n = split(s, f, "|")
    if (s !~ /^[|: -]+$/ || n - 2 != 7) bad(ln, 1, "머리 줄 다음에는 구분 줄 \"|---|---|---|---|---|---|---|\"을 둔다.")
    tstate = "rows"; next
  }
  # 본문 줄
  s = trim(line)
  n = split(s, f, "|")
  if (substr(s, length(s), 1) == "|") nc = n - 2; else nc = n - 1
  if (nc != 7 || substr(s, length(s), 1) != "|") {
    bad(ln, 2, "칸이 " nc "개다. 줄은 \"|\"로 시작하고 끝나며 칸은 정확히 7개다. 셀 안에서는 \"|\"와 줄바꿈을 쓰지 않는다.")
    next
  }
  id = trim(f[2]); st = trim(f[4]); now = trim(f[6]); link = trim(f[8])
  if (id !~ /^[123R]-[0-9]+$/) bad(ln, 4, "ID \"" id "\"의 형식이 틀렸다. \"<단계>-<번호>\"(예: 1-1, 2-16, R-1)로 쓴다.")
  else if (id in rowln) bad(ln, 4, "ID \"" id "\"가 " rowln[id] "행과 겹친다. 한 ID는 한 줄에만 쓰고, 정한 ID는 바꾸거나 다시 쓰지 않는다.")
  if (!(id in rowln)) rowln[id] = ln
  if (!(st in okstate)) { bad(ln, 3, "상태 \"" st "\"는 쓸 수 없다. PENDING, IN_PROGRESS, AI_PROPOSED, HUMAN_APPROVED, MERGED, DEFERRED 가운데 하나를 쓴다."); next }
  if (clen(now) > 80) bad(ln, 5, "\"지금\"이 " clen(now) "자다. 80자 이하의 한 줄로 줄이고, 하위 진행은 스테이지 문서의 \"진행 기록\"에 쓴다.")
  if ((st == "PENDING" || st == "MERGED") && now != "") bad(ln, 5, st " 줄의 \"지금\"은 비워 둔다.")
  if (st == "IN_PROGRESS" && !starts(now, P1) && !starts(now, P2)) bad(ln, 5, "IN_PROGRESS 줄의 \"지금\"은 \"" P1 "\"(계획을 쓰는 중) 또는 \"" P2 "\"(계획 승인 뒤 구현 중)로 시작한다.")
  if (st == "AI_PROPOSED" && !starts(now, P3) && !starts(now, P4)) bad(ln, 5, "AI_PROPOSED 줄의 \"지금\"은 \"" P3 "\" 또는 \"" P4 "\"로 시작한다.")
  if (st == "DEFERRED" && !starts(now, P1) && !starts(now, P2) && !starts(now, P3) && !starts(now, P4)) bad(ln, 5, "DEFERRED 줄의 \"지금\"은 보류 전 상태의 머리말(\"" P1 "\", \"" P2 "\", \"" P3 "\", \"" P4 "\")로 시작하고 보류 이유나 재개 조건을 붙인다.")
  if ((st == "IN_PROGRESS" || st == "AI_PROPOSED" || st == "HUMAN_APPROVED") && link !~ /\[[^]]*\]\([^)]+\)/) bad(ln, 7, st " 줄의 링크 칸에 링크가 없다. PR 링크나 스테이지 문서 링크를 적는다.")
  if (full && st == "MERGED") {
    rel = 0; hit = 0; why = ""
    rest = link
    while (match(rest, /\]\([^)]+\)/)) {
      p = substr(rest, RSTART + 2, RLENGTH - 3)
      rest = substr(rest, RSTART + RLENGTH)
      if (p ~ /^[a-zA-Z]+:/ || starts(p, "#")) continue
      sub(/#.*$/, "", p); sub(/^\.\//, "", p)
      rel++
      if ((p in docid) && docid[p] == id) { hit = 1; break }
      if (why == "") {
        if (p in docid) why = "문서 \"" p "\"의 id가 \"" docid[p] "\"다. 줄의 ID(" id ")와 같아야 한다."
        else why = "문서 \"" p "\"가 커밋에 없거나 \"id:\" frontmatter가 없다. 머지된 스테이지 문서를 가리키고, 그 문서에 \"id: " id "\"를 둔다."
      }
    }
    if (rel == 0) bad(ln, 6, "MERGED 줄의 링크 칸에 스테이지 문서의 상대 경로 링크가 없다. [문서](<docs/waypoint 기준 경로>) 링크를 더한다.")
    else if (!hit) bad(ln, 6, why)
  }
}
END {
  if (!seen_stage) bad("", 1, "\"## 스테이지\" 절이 없다. 제목과 링크 줄 아래에 \"## 스테이지\"와 표를 둔다.")
  else if (tstate == "header") bad("", 1, "\"## 스테이지\" 아래에 표가 없다. 머리 줄 \"" HEADER "\"로 표를 시작한다.")
  for (j = 1; j <= nblock; j++)
    if (!(bid[j] in rowln)) bad(bln[j], 9, "\"(막음: …)\"의 ID \"" bid[j] "\"가 표에 없다. 표에 있는 ID를 쓴다.")
  if (full)
    for (j = 1; j <= nid; j++)
      if (!(docid[idpath[j]] in rowln))
        print "docs/waypoint/" idpath[j] ": [검사 8] \"id: " docid[idpath[j]] "\"인 스테이지 문서가 있지만 STATUS 표에 " docid[idpath[j]] " 줄이 없다. 표에 그 스테이지의 줄을 더한다."
}
' "$1")
  _wp_rc=$?
  if [ "$_wp_rc" -ne 0 ] || [ -n "$_wp_out" ]; then
    [ -n "$_wp_out" ] && printf '%s\n' "$_wp_out" >&2
    return 1
  fi
  return 0
}
# <<< waypoint status-check <<<

wp_status_check "$@"
exit $?
