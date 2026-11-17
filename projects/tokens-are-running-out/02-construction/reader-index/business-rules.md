---
artifact: business-rules
build-spec: reader-index
status: READY
updated: 2026-11-17
---

# Business Rules — 기록 리더와 색인

## 1. 규칙 표 (Rules)

| ID | 규칙 (결정적 서술) | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| R1 | 줄 사전 필터: 바이트에 `"compact_boundary"`가 있으면 압축 후보, `"custom-title"`이 있으면 제목 후보, `"assistant"`와 `"usage"`가 모두 있으면 호출 후보. 나머지 줄은 디코딩하지 않는다 | `RecordParser` | 해당 없음 | prototype `iter_calls`, 성능 |
| R2 | 호출 후보는 `type == "assistant"`, `timestamp` 있음, 비어 있지 않은 `message.id`, 비어 있지 않은 `message.usage` 객체, 비어 있지 않고 `<synthetic>`이 아닌 `message.model`을 모두 만족할 때만 ApiCall이다(구현 후 프로토타입과 맞춤) | `RecordParser` | 조건을 못 맞추면 조용히 버림(실패로 세지 않음) | 1-2 불변식 2, design 5장 |
| R3 | 후보 줄의 JSON 디코딩이 실패하면 그 줄만 버리고 `parse_failures`를 1 올린다. 모르는 필드와 모르는 type은 무시한다 | `RecordParser` | 크래시 금지 | design 3장 |
| R4 | 소유 파일: 같은 `message.id`의 occurrence 중에서 키가 가장 작은 파일이 소유한다. 키 = (`kind == main`이고 `line_session_id == files.session_id`이면 0, 아니면 1) → `birthtime` → `path` | `IndexStore` | 해당 없음 | 2-1 계약 확장, prototype `owners` |
| R5 | 같은 파일 안에서 같은 `message.id`가 다시 나오면 첫 occurrence만 남기고 순번도 새로 주지 않는다 | `Indexer` | 해당 없음 | 1-2 불변식 1. 2-2에서 확장: usage는 마지막 줄 값([rebuild-analysis R16](../rebuild-analysis/business-rules.md)) |
| R6 | 오프셋은 항상 줄 시작을 가리킨다. 마지막 줄에 줄바꿈이 없으면 그 줄은 소비하지 않고 다음 읽기에서 다시 본다 | `LineReader` | 해당 없음 | 기록이 쓰이는 중일 수 있음 |
| R7 | 파일의 inode가 바뀌었거나, 크기가 저장된 오프셋보다 작아졌거나, 이미 읽은 앞부분(최대 1KB)의 지문이 달라졌으면, 그 파일의 occurrence와 압축 경계를 모두 지우고 처음부터 다시 읽는다 | `Indexer` | 해당 없음 | 교체·잘림 대응 |
| R8 | 파일이 사라지면 그 파일의 occurrence, 압축 경계, files 행을 지운다. 그 결과 occurrence가 0개가 된 call은 지우고, 남은 call은 소유 파일을 다시 정한다 | `Indexer`, `IndexStore` | 해당 없음 | Claude Code의 기록 정리 |
| R9 | 앱과 CLI는 `~/.claude` 아래 어떤 파일도 쓰기 모드로 열지 않는다. 쓰기는 색인 파일에만 한다. 색인 경로가 `~/.claude`나 루트 안이면 CLI가 거부한다 | 전체 | CLI 종료 코드 2, CI 소스 검사 | 반목표 |
| R10 | 네트워크 API(`URLSession`, `Network`)를 쓰지 않는다 | 전체 | CI에서 소스 검사로 막음 | 반목표 |
| R11 | 제목은 가장 늦게 만들어진 파일의, 그 파일 안에서 가장 나중의 `custom-title`이 이긴다. 파일이 재색인되거나 지워지면 그 파일의 제목도 지운다 | `IndexStore` | 해당 없음 | design 5장, 독립 리뷰 |
| R13 | 파일 하나를 읽다가 생긴 오류(권한, 읽는 도중 사라짐)는 그 파일만 건너뛰고 `skippedFiles`로 보고한다. 색인 저장소 오류는 그대로 던진다 | `Indexer` | 다음 스캔이나 이벤트에서 다시 시도 | 독립 리뷰 HIGH |
| R14 | 읽을 수 없는 폴더 아래의 파일은 사라진 것으로 보지 않는다(기록 유지) | `Indexer`, `TranscriptLocator` | 경고 없이 보존 | 독립 리뷰 MEDIUM |
| R15 | 다른 연결이 쓰기 잠금을 잡고 있으면 최대 5초 기다린다. 색인 파일이 손상되었으면 지우고 다시 만든다. 조회문은 끝나면 반드시 reset한다 | `SQLiteDatabase`, `Indexer` | 기다린 뒤에도 실패하면 오류 | 독립 리뷰 CRITICAL·MEDIUM |
| R12 | `stats`는 소유 occurrence의 호출만, `from ≤ ts < to`로 센다 | CLI | 해당 없음 | prototype 기준값 |

## 2. 검증 규칙 (Validation)

| 입력 | 규칙 | 경계/형식 | 실패 메시지·코드 |
|---|---|---|---|
| `--from`, `--to` | ISO 8601(UTC, `Z`), `from < to` | 초 단위까지 | "Use ISO 8601 UTC, e.g. 2026-11-10T00:00:00Z", 종료 코드 2 |
| `--root` | 존재하는 디렉터리 | | "No Claude Code transcripts at <path>", 종료 코드 3 |
| `--db` | 쓸 수 있는 경로 | 상위 디렉터리를 만듦 | "Cannot open index at <path>", 종료 코드 4 |

## 3. 권한 / 접근 규칙 (Authz)

| 액션 | 허용 조건 | 거부 시 동작 |
|---|---|---|
| 기록 파일 읽기 | 사용자 권한으로 읽을 수 있을 때 | 그 파일을 건너뛰고 경고를 한 번 출력 |
| 색인 쓰기 | 색인 파일 경로에 한해 | 2절의 오류 |

## 4. 불변식 (Invariants)

- INV1: `calls`의 모든 행은 occurrence를 1개 이상 가진다.
- INV2: `calls.owner_file_id`는 그 call의 occurrence가 있는 파일 중 R4의 키가 가장 작은 파일이다.
- INV3: 한 파일 안에서 `seq`는 occurrence와 압축 경계를 통틀어 유일하고, 파일에 나타난 순서와 같다.
- INV4: `files.offset`은 0이거나 줄바꿈 바로 다음 위치다.
- INV5: 같은 입력 파일 집합을 색인하면, 한 번에 읽든 여러 번에 나눠 읽든 결과(calls, occurrences, marks, titles)가 같다.
- INV6: `running-out stats`의 결과는 같은 기간에 대한 `prototype/drain.py`의 호출 수와 토큰 합계와 같다.

## 5. 엣지케이스 · 에러 매핑

| 케이스 | 조건 | 기대 동작 |
|---|---|---|
| 같은 파일 안 중복 줄 | 콘텐츠 블록마다 같은 `message.id` 줄이 반복됨 | 호출 1개, occurrence 1개(R5) |
| 파일 간 복사, sessionId 유지 | 원래 파일과 새 파일에 같은 id, 새 파일의 줄 `sessionId`는 원래 세션 | 원래 파일이 소유(R4 첫 키) |
| 파일 간 복사, sessionId 바뀜 | 두 파일 모두 줄 `sessionId`가 자기 파일 ID | 먼저 생성된 파일이 소유(R4 둘째 키) |
| 서브에이전트 간 복사 | 서브에이전트 파일 여러 개에 같은 id | 먼저 생성된 파일이 소유 |
| 원래 파일이 나중에 사라짐 | 소유 파일 삭제 | 남은 occurrence 중에서 소유 파일을 다시 정함(R8) |
| `<synthetic>` 메시지 | model이 `<synthetic>` | 버림, 순번도 주지 않음 |
| 쓰는 중인 마지막 줄 | 줄바꿈 없이 끝남 | 소비하지 않음(R6), 다음 읽기에서 처리 |
| 파일 잘림 | 크기 < 오프셋 | 그 파일만 재색인(R7) |
| 파일 교체 | inode 변경 | 그 파일만 재색인(R7) |
| 깨진 JSON 줄 | 디코딩 실패 | 버리고 `parse_failures` 증가(R3) |
| `usage` 없는 assistant 줄 | 중간 스트리밍 줄 등 | 버림(R2) |
| `cache_creation` 세부 필드 없음 | 구버전 기록 | `cache_write_1h = 0`, `cache_write_5m = 0`, `ttl = NULL` |
| 매우 긴 줄 | 수 MB 줄 | 청크 경계를 넘어도 하나의 줄로 이어 붙임 |
| 빈 루트 | 기록 없음 | 색인은 비어 있고 오류 아님. CLI는 "0 files" 출력 |
| 읽을 수 없는 파일 | 권한 없음 | 건너뛰고 경고 1회 |
| 같은 id의 사용량 불일치 | 드묾 | 먼저 기록된 값 유지, `usage_mismatch_count` 증가 |
