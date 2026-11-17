---
artifact: business-logic-model
build-spec: reader-index
status: READY
updated: 2026-11-17
---

# Business Logic Model — 기록 리더와 색인

## 1. 주요 워크플로 (Workflows)

### `FullIndex` (첫 실행 또는 `running-out index`)
1. **트리거:** 색인 파일이 없거나 스키마 버전이 다름, 또는 CLI `index`.
2. **단계:** 루트 탐색(`TranscriptLocator`) → 파일 목록을 **수정 시각 내림차순**으로 정렬(최근 30일 파일 먼저) → 파일마다 `IndexFile` → 끝나면 `last_full_index_at` 기록.
3. **결과/부작용:** 색인이 채워짐. 앱은 최근 30일 파일이 끝나는 시점에 "부분 결과 준비" 신호를 받는다.
4. **적용 규칙:** R1 ~ R8, R11.

### `IndexFile(path)`
1. **트리거:** `FullIndex`, `IncrementalUpdate`.
2. **단계:** `stat` → 저장된 상태와 비교(§3 상태 전이) → 필요하면 재색인 준비(R7) → `LineReader`로 `[offset, size)`의 완결된 줄을 청크 단위로 읽음 → 줄마다 `RecordParser` → 사건(호출, 압축, 제목)을 순서대로 처리 → 파일 단위 트랜잭션으로 커밋 → `offset`, `size`, `inode`, `next_seq` 갱신.
3. **결과/부작용:** occurrences, calls, marks, titles 변경. 소유 파일 재계산 대상 id 집합.
4. **적용 규칙:** R1 ~ R7, R11.

### `IncrementalUpdate(paths)`
1. **트리거:** `TranscriptWatcher`가 FSEvents를 0.5초 동안 모아 경로 집합을 넘김.
2. **단계:** 경로마다 `.jsonl`이면 `IndexFile`, 없어진 파일이면 `RemoveFile`(R8).
3. **결과/부작용:** 변경된 call과 세션 ID 목록을 구독자(앱)에 알림.

### `RemoveFile(path)`
1. **트리거:** 감시 이벤트나 전체 색인에서 파일이 사라진 것을 발견.
2. **단계:** 그 파일의 occurrence와 압축 경계 삭제 → 영향받은 id마다 occurrence가 0이면 call 삭제, 아니면 소유 파일 재계산 → files 행 삭제.

## 2. 알고리즘 (Algorithms)

### 2.1 증분 줄 읽기
```
read(file, offset, size):
  pos = offset; carry = empty
  while pos < size:
    chunk = read up to 4 MiB from pos
    buf = carry + chunk
    last_nl = last index of '\n' in buf
    if last_nl is none: carry = buf; pos += len(chunk); continue   # 아주 긴 줄
    for line in buf[0 ... last_nl] split by '\n': yield line
    carry = buf[last_nl+1 ...]
    pos += len(chunk)
  return next_offset = size - len(carry)                             # 줄바꿈 없는 꼬리는 소비하지 않음(R6)
```

### 2.2 사건 처리와 소유 파일
```
for line in read(file):
  rec = parse(line)                                 # R1 ~ R3
  if rec is Compaction: marks.insert(file, seq=next_seq++, ts)
  if rec is Title:      titles.upsert(session_id, title)            # R11
  if rec is Call:
    if occurrences.exists(file, rec.id): continue                   # R5
    occurrences.insert(file, rec.id, seq=next_seq++, rec.line_session_id)
    if calls.exists(rec.id): touched.add(rec.id)                     # 다른 파일에도 있음
    else: calls.insert(rec, owner=file)
commit
for id in touched: calls.owner(id) = argmin over occurrences(id) of key(occ)   # R4
key(occ) = (0 if occ.file.kind == main and occ.line_session_id == occ.file.session_id else 1,
            occ.file.birthtime, occ.file.path)
```

### 2.3 기간 집계(`stats`)
```
select count(*), sum(input_tokens), sum(output_tokens), sum(cache_read_tokens), sum(cache_write_tokens)
from calls where ts >= :from and ts < :to                 # 소유 파일과 무관하게 call은 한 번만 존재(R12)
```

## 3. 상태 전이 (State Transitions)

파일 하나의 색인 상태(저장된 `inode`, `size`, `offset`과 현재 `stat` 비교).

| 현재 상태 | 이벤트 | 다음 상태 | 액션/부작용 | 가드 |
|---|---|---|---|---|
| 없음 | 파일 발견 | 색인됨 | 오프셋 0부터 읽기 | |
| 색인됨 | 크기 증가, inode 같음 | 색인됨 | 저장된 오프셋부터 읽기 | R6 |
| 색인됨 | 크기 같음, inode 같음 | 색인됨 | 아무것도 안 함 | |
| 색인됨 | 크기 < 오프셋 | 색인됨 | 그 파일 재색인 | R7 |
| 색인됨 | inode 변경 | 색인됨 | 그 파일 재색인 | R7 |
| 색인됨 | 파일 사라짐 | 없음 | `RemoveFile` | R8 |
| 색인됨 | 읽기 권한 없음 | 색인됨(이전 값 유지) | 경고 1회 | |

## 4. 시퀀스 / 상호작용 (Sequence)

1. 앱 시작 → `IndexStore.open`(스키마 확인) → `FullIndex`가 필요하면 백그라운드 작업으로 실행.
2. `TranscriptWatcher.start(root)`를 전체 색인보다 **먼저** 시작한다. 전체 색인 중에 온 이벤트는 actor 뒤에 줄 서서 전체 색인이 끝난 뒤 처리된다(독립 리뷰 반영).
3. 모든 쓰기는 하나의 직렬 작업자(actor)를 거친다. 읽기(화면 집계)는 WAL 덕분에 쓰기와 동시에 할 수 있다.
4. CLI `watch`는 같은 흐름을 터미널에서 돌리며 바뀐 파일과 반영 시간을 출력한다(증분 반영 1초 측정용).

## 5. 통합 지점 (Integration Points)

| 대상 | 호출 시점 | 요청/응답 요지 | 실패 처리 |
|---|---|---|---|
| 파일 시스템(`~/.claude/projects`) | 색인, 감시 | 읽기 전용 열기, `stat` | 권한 오류는 건너뛰기와 경고, 그 밖의 오류는 해당 파일만 다음 이벤트에 재시도 |
| FSEvents | 앱과 CLI `watch` | 하위 폴더 포함 경로 이벤트 | 이벤트 유실 플래그(`kFSEventStreamEventFlagMustScanSubDirs`)를 받으면 전체 탐색 후 파일별 상태 비교 |
| SQLite3(시스템) | 색인 쓰기와 읽기 | WAL, 준비된 문장 | 손상이나 스키마 불일치면 색인 파일을 지우고 `FullIndex` |
