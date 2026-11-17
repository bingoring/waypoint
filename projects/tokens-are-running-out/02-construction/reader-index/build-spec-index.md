---
build-spec: reader-index
stage: 02-construction/01-reader-and-index
status: IMPLEMENTED
depth: standard
updated: 2026-11-17
---

# Build Spec — 기록 리더와 색인

## §0. 개요 & 범위
- **목표(한 줄):** `~/.claude/projects` 아래의 기록 파일을 읽기 전용으로 증분 색인해서, 호출(ApiCall), 압축 경계, 세션 제목을 SQLite에 쌓는 `RunningOutCore`와 개발용 CLI `running-out`.
- **SoT(진실 공급원):**
  - [`../../01-inception/02-domain-model.md`](../../01-inception/02-domain-model.md) 엔티티와 불변식(2-1 계약 확장 포함)
  - [`../../inputs/design.md`](../../inputs/design.md) 5장(데이터 출처 표), 7장(구성 요소, 성능 목표), 10장(기준값)
  - 메인 저장소 `prototype/drain.py`의 `iter_calls`, `owners`
- **규모/제약:**
  - 개발자 기기 기준 1.7GB, 파일 하나가 228MB까지, 호출 줄 약 10만 8천 개.
  - 읽기 전용. 네트워크 금지. 외부 의존성 없음.
  - macOS 14 이상, Swift 6 언어 모드.
- **깊이 티어 & 사유:** `standard`. 로직(증분 읽기, 중복 처리, 소유 파일 결정)이 핵심이고 화면은 없다.

## §1. 분해 (Decomposition)

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `Package.swift` | 라이브러리 `RunningOutCore`, 실행 파일 `running-out`, 테스트 타깃. `swift-tools-version: 6.0`, `platforms: [.macOS(.v14)]` | 없음 | 신규 |
| `TranscriptLocator` | 루트 아래에서 메인과 서브에이전트 기록 파일을 찾고 종류·세션 ID·에이전트 ID를 판별 | Foundation | 신규 |
| `LineReader` | 파일의 지정 오프셋부터 끝까지 완결된 줄만 청크 단위로 읽음 | Foundation | 신규 |
| `RecordParser` | 줄 사전 필터와 JSON 디코딩으로 `CallRecord`, `CompactionRecord`, `TitleRecord`를 만듦 | Foundation | 신규 |
| `IndexStore` | SQLite3 래퍼. 스키마, 트랜잭션, upsert, 소유 파일 재계산, 조회 | SQLite3 | 신규 |
| `Indexer` | 파일 상태 비교 → 증분/재색인 결정 → 파서 → 저장소 | 위 전부 | 신규 |
| `TranscriptWatcher` | FSEvents로 루트를 감시하고 바뀐 경로를 묶어서 `Indexer`에 전달 | CoreServices | 신규 |
| `running-out` | `index`, `stats`, `watch` 명령 | `RunningOutCore` | 신규 |
| `Tests/RunningOutCoreTests` | 합성 픽스처 단위 테스트 | XCTest 또는 Swift Testing | 신규 |
| `.github/workflows/ci.yml` | macOS 러너에서 빌드·테스트·린트 | GitHub Actions | 신규 |

## §2. 아티팩트 인덱스 (Manifest)

| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`./domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`./business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`./business-logic-model.md`](business-logic-model.md) |
| frontend-components | N/A | 2-1에는 화면이 없다. 화면은 2-3에서 다룬다. |

## §3. 미해결 질문 (Open Questions)

없음. 작성자 판단으로 정한 것(외부 의존성 없음, `swift format`, 1-2 계약 확장)은 [DECISIONS](../../DECISIONS.md)에 기록했다.

## §4. 구현 체크리스트

- [x] `Package.swift`, `.swift-format`, 디렉터리 골격
- [x] `TranscriptLocator`: 메인 `<root>/<project>/<sessionId>.jsonl`, 서브에이전트 `<root>/<project>/<sessionId>/subagents/agent-<agentId>.jsonl` 판별
- [x] `LineReader`: 청크 읽기, 마지막 줄바꿈까지만 소비, 다음 오프셋 반환
- [x] `RecordParser`: 사전 필터(business-rules R1), 디코딩, 무시 규칙(R2, R3), 파싱 실패 계수
- [x] `IndexStore`: 스키마(domain-entities §2), WAL, 준비된 문장, 파일 단위 트랜잭션
- [x] 소유 파일 결정과 재계산(R4, business-logic-model §2.2)
- [x] `Indexer`: 신규·증분·잘림·교체 처리(business-logic-model §3)
- [x] `TranscriptWatcher`: FSEvents, 0.5초 묶음, 같은 파일 중복 요청 병합
- [x] `running-out index | stats | watch`
- [x] 합성 픽스처와 단위 테스트(business-rules §5의 모든 케이스)
- [x] CI 워크플로
- [x] 기준값 대조와 성능 측정, 결과를 스테이지 문서에 기록
- [x] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획
- [x] `swift build` 경고 0건(Swift 6 언어 모드), `swift format lint --strict --recursive Sources Tests` 0건
- [x] PR 브랜치에 base merge 커밋 없음: `git log --merges origin/main..HEAD`가 비어 있다(최신화는 rebase)
- [x] 단위 테스트: business-rules §5의 엣지케이스마다 하나 이상
- [x] 기준값: `running-out stats --from 2026-11-10T00:00:00Z --to 2026-11-17T00:00:00Z`의 출력이 아래와 정확히 같다
  - API 호출 4,133건
  - input=8,466, output=4,904,851, cache_read=1,285,099,861, cache_write=32,306,214
- [x] 성능(개발자 기기): 첫 색인 2분 이내, 기록 한 줄 추가 뒤 색인 반영 1초 이내, 최대 메모리 100MB 이하. 측정 방법과 값을 스테이지 문서에 기록
- [x] 보안: `Sources/`에 `URLSession`, `Network` 사용 0건. 기록 파일은 읽기 모드로만 연다. 색인 파일 외에는 쓰지 않는다
- [x] 개인정보: 커밋 전에 저장소에 `.jsonl`, `.sqlite`가 없고, 픽스처가 합성 데이터뿐인지 확인

## §6. NFR · 성능 (comprehensive 전용)

N/A (standard). 성능 목표는 §5에 포함했다.

## §7. 편차 로그 (Deviations) — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| domain-entities: `calls`에 사용량·TTL 등 모든 값을 저장 | 스키마 v2: 파일마다 쓰인 값은 `occurrences`에, 집계에 쓰는 소유 파일의 값(ts, 토큰 4종)은 `calls`에 저장 | 독립 리뷰 MEDIUM. 먼저 읽은 복사본의 값이 들어가 읽는 순서에 따라 결과가 달라질 수 있었다(INV5). `timeline`은 그 파일에 쓰인 값을 돌려준다 |
| domain-entities: `titles(session_id, title, file_id, seq_hint)` | `titles(id, file_id, seq, session_id, title)` 행을 파일별로 쌓고, 최신 값은 조회할 때 계산 | 독립 리뷰 MEDIUM. 파일이 잘리거나 지워질 때 그 파일의 제목을 함께 지우기 위해서 |
| `IndexMeta.usage_mismatch_count` 저장 | `usageMismatchCount()`가 occurrences에서 그때그때 계산 | 저장값은 재색인 때마다 맞추기 어렵다. 실제 기록에서 0건 |
| 앱에 "부분 결과 준비" 신호와 변경 알림 | 2-3(화면)으로 옮김 | 신호를 받는 쪽이 앱이므로 화면과 함께 설계한다 |
| R2: `usage`가 있으면 호출 | 비어 있지 않은 `usage`, 비어 있지 않은 `id`, `model` 필수 | 프로토타입(오라클)과 맞춤. 실제 기록에 해당 사례 0건 |
| (2-2에서 확장) | 스키마 v3: `occurrences.iterations`, 같은 메시지의 마지막 줄 usage | [rebuild-analysis 편차 로그](../rebuild-analysis/build-spec-index.md) |
| (명세 없음) | 파일 앞부분 1KB의 지문으로 제자리 덮어쓰기 감지(R7 확장), busy timeout 5초, 손상된 색인은 지우고 다시 만듦, `--db`가 `~/.claude`나 루트 안이면 거부 | 독립 리뷰 LOW·MEDIUM |
