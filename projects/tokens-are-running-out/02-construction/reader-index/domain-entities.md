---
artifact: domain-entities
build-spec: reader-index
status: READY
updated: 2026-11-17
---

# Domain & Entities — 기록 리더와 색인

> **구현 반영(스키마 v2, 2026-11-17):** 독립 리뷰에 따라 파일마다 쓰인 값(ts, model, version, 토큰, TTL)을 `occurrences`에 저장하고, `calls`에는 집계에 쓰는 소유 파일의 값(ts, 토큰 4종)만 둔다. `titles`는 (file_id, seq) 행으로 쌓는다. `files`에 `head_length`, `head_hash`(앞부분 지문)를 더했다. 자세한 차이는 [인덱스 §7 편차 로그](build-spec-index.md).
>
> 색인 위치: `~/Library/Application Support/TokensAreRunningOut/index.sqlite`(CLI는 `--db`로 바꿀 수 있음). 원본에서 다시 만들 수 있는 파생 데이터다.
> enum성 값은 코드의 allowed-set으로 관리하고 DB CHECK를 쓰지 않는다.

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT 출처 |
|---|---|---|---|
| `TranscriptFile` | 기록 파일 하나와 읽은 위치 | 테이블 `files` | design 5장, 1-2 Transcript |
| `ApiCall` | API 호출 한 번(전체 기록에서 `message.id`로 유일) | 테이블 `calls` | 1-2 ApiCall, 2-1 계약 확장 |
| `CallOccurrence` | 어떤 호출이 어떤 파일의 몇 번째 사건으로 나타났는지 | 테이블 `occurrences` | 2-1 계약 확장 |
| `CompactionMark` | 압축 경계 | 테이블 `marks` | 1-2 CompactionMark |
| `SessionTitle` | 세션 제목(가장 최근 값) | 테이블 `titles` | design 5장 세션 제목 |
| `IndexMeta` | 스키마 버전, 마지막 색인 시각 | 테이블 `meta` | 신규 |

## 2. 엔티티 상세

### `TranscriptFile` (`files`)
| 필드 | 타입 | 필수 | 기본값 | 제약/allowed-set | 설명 |
|---|---|---|---|---|---|
| `id` | INTEGER | ✅ | 자동 | PK | |
| `path` | TEXT | ✅ | | UNIQUE | 절대 경로 |
| `kind` | TEXT | ✅ | | `main`, `subagent` | 경로 형태로 판별 |
| `session_id` | TEXT | ✅ | | | 메인: 파일 이름, 서브에이전트: 상위 디렉터리 이름 |
| `agent_id` | TEXT | | NULL | | 서브에이전트만. `agent-<id>.jsonl`의 `<id>` |
| `inode` | INTEGER | ✅ | | | 교체 감지용 |
| `birthtime` | REAL | ✅ | | | 생성 시각(초). 소유 파일 결정에 씀 |
| `size` | INTEGER | ✅ | | | 마지막으로 본 크기 |
| `offset` | INTEGER | ✅ | 0 | 0 ≤ offset ≤ size | 다음에 읽을 바이트 위치(항상 줄 시작) |
| `next_seq` | INTEGER | ✅ | 0 | | 이 파일에서 다음 사건에 붙일 순번 |
| `lines_read` | INTEGER | ✅ | 0 | | 읽은 완결된 줄 수 |
| `candidate_lines` | INTEGER | ✅ | 0 | | 사전 필터를 통과한 줄 수 |
| `parse_failures` | INTEGER | ✅ | 0 | | 디코딩에 실패한 후보 줄 수 |

### `ApiCall` (`calls`)
| 필드 | 타입 | 필수 | 기본값 | 제약/allowed-set | 설명 |
|---|---|---|---|---|---|
| `message_id` | TEXT | ✅ | | PK | `message.id` |
| `owner_file_id` | INTEGER | ✅ | | FK `files.id` | 비용과 개수를 세는 파일(R4) |
| `ts` | REAL | ✅ | | | `timestamp`(UTC 초) |
| `model` | TEXT | ✅ | | `<synthetic>` 제외 | `message.model` |
| `version` | TEXT | | NULL | | 줄의 `version` |
| `input_tokens` | INTEGER | ✅ | 0 | ≥ 0 | |
| `output_tokens` | INTEGER | ✅ | 0 | ≥ 0 | |
| `cache_read_tokens` | INTEGER | ✅ | 0 | ≥ 0 | `cache_read_input_tokens` |
| `cache_write_tokens` | INTEGER | ✅ | 0 | ≥ 0 | `cache_creation_input_tokens` |
| `cache_write_1h` | INTEGER | ✅ | 0 | ≥ 0 | `cache_creation.ephemeral_1h_input_tokens` |
| `cache_write_5m` | INTEGER | ✅ | 0 | ≥ 0 | `cache_creation.ephemeral_5m_input_tokens` |
| `ttl` | TEXT | | NULL | `1h`, `5m`, NULL | 0이 아닌 쪽. 둘 다 0이면 NULL(2-2에서 직전 값으로 보충) |

- 사용량 값은 같은 `message.id`의 모든 줄과 모든 파일에서 같다고 본다(표본 확인). 다르면 먼저 기록된 값을 유지하고 `IndexMeta`의 불일치 계수를 올린다.

### `CallOccurrence` (`occurrences`)
| 필드 | 타입 | 필수 | 기본값 | 제약/allowed-set | 설명 |
|---|---|---|---|---|---|
| `file_id` | INTEGER | ✅ | | PK(복합), FK | |
| `message_id` | TEXT | ✅ | | PK(복합) | |
| `seq` | INTEGER | ✅ | | 파일 안에서 유일 | 그 파일에서 몇 번째 사건인지(호출과 압축 경계가 같은 순번 공간을 씀) |
| `line_session_id` | TEXT | | NULL | | 줄의 `sessionId`. 소유 파일 결정에 씀 |

### `CompactionMark` (`marks`)
| 필드 | 타입 | 필수 | 기본값 | 제약/allowed-set | 설명 |
|---|---|---|---|---|---|
| `file_id` | INTEGER | ✅ | | PK(복합), FK | |
| `seq` | INTEGER | ✅ | | PK(복합) | 호출과 같은 순번 공간 |
| `ts` | REAL | | NULL | | 줄에 시각이 있으면 기록 |

### `SessionTitle` (`titles`)
| 필드 | 타입 | 필수 | 기본값 | 제약/allowed-set | 설명 |
|---|---|---|---|---|---|
| `session_id` | TEXT | ✅ | | PK | |
| `title` | TEXT | ✅ | | | `customTitle` |
| `file_id` | INTEGER | ✅ | | FK | 제목을 마지막으로 본 파일 |
| `seq_hint` | INTEGER | ✅ | | | 같은 세션에서 나중에 본 값이 이김 |

### `IndexMeta` (`meta`)
| 키 | 값 |
|---|---|
| `schema_version` | `1` |
| `last_full_index_at` | 마지막 전체 색인 완료 시각 |
| `usage_mismatch_count` | 같은 `message.id`인데 사용량이 다른 경우의 수 |

- 스키마 버전이 코드와 다르면 색인 파일을 지우고 다시 만든다(파생 데이터).

## 3. 관계 (Relationships)

| 좌 | 카디널리티 | 우 | 비고 |
|---|---|---|---|
| `TranscriptFile` | 1─* | `CallOccurrence` | 파일 재색인 시 그 파일의 occurrence를 모두 지움 |
| `ApiCall` | 1─* | `CallOccurrence` | occurrence가 0개가 되면 call도 지움 |
| `ApiCall` | *─1 | `TranscriptFile`(owner) | R4로 결정, occurrence가 바뀔 때 재계산 |
| `TranscriptFile` | 1─* | `CompactionMark` | 재색인 시 지움 |

## 4. 열거형 / Allowed-set

| 이름 | 값 | 확장 규칙 |
|---|---|---|
| `TranscriptKind` | `main`, `subagent` | 새 경로 형태가 생기면 추가 |
| `CacheTTL` | `1h`, `5m` | API가 새 TTL을 내면 추가 |

## 5. SoT 매핑 (SoT → 타입)

| SoT 요소(기록의 JSON) | 엔티티.필드 | 비고 |
|---|---|---|
| `type == "assistant"` | (필터) | 다른 type은 사용량에 쓰지 않음 |
| `message.id` | `ApiCall.message_id`, `CallOccurrence.message_id` | |
| `message.model` | `ApiCall.model` | `<synthetic>`이면 버림 |
| `message.usage.input_tokens` 등 | `ApiCall.*_tokens` | 없는 필드는 0 |
| `message.usage.cache_creation.ephemeral_1h_input_tokens` | `ApiCall.cache_write_1h` | |
| `message.usage.cache_creation.ephemeral_5m_input_tokens` | `ApiCall.cache_write_5m` | |
| `timestamp` | `ApiCall.ts` | ISO 8601, 소수점 초 포함 |
| `version` | `ApiCall.version` | |
| `sessionId` | `CallOccurrence.line_session_id` | |
| `type == "system"`, `subtype == "compact_boundary"` | `CompactionMark` | |
| `type == "custom-title"`, `customTitle` | `SessionTitle.title` | |
