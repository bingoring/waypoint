---
artifact: business-logic-model
build-spec: rebuild-analysis
status: READY
updated: 2026-11-17
---

# Business Logic Model — 재구축 판정 · 원인 분류 · 비용 분해

## 1. 주요 워크플로 (Workflows)

### `Analyze(from, to)`
1. **트리거:** 화면(2-3)의 기간 선택이나 색인 갱신, 또는 CLI `report`.
2. **단계:** `Indexer.ownedFiles(from:to:)` → 파일마다 `timeline(of:)` → `RebuildClassifier`가 파일을 순서대로 걸으며 소유 호출을 분류 → `CallCost`로 비용 계산 → 버킷과 목록에 누적 → `UsageReport`.
3. **결과/부작용:** 없음(읽기만).
4. **적용 규칙:** R1 ~ R13.

### `Report CLI`
1. **트리거:** `running-out report --from --to [--root] [--db]`.
2. **단계:** 증분 색인(`indexAll`) → `Analyze` → 프로토타입과 같은 형식으로 출력(§4).

## 2. 알고리즘 (Algorithms)

### 2.1 파일 하나 걷기
```
classify(file, events, window):
  last = nil; lastTTL = (file.kind == main ? 1h : 5m); compacted = false
  for e in events (seq 순):
    if e is compaction: compacted = true; continue
    call = e.call
    if call.owned and window.contains(call.ts):           # R1
      rebuild = any(isRebuild(part) for part in call.parts)            # R2: 단계별
      cost = sum(price(part, part.model ?? call.model) for part in call.parts)   # R9 ~ R11
      rebuilt = sum(price(part).cacheWrite for part in call.parts if rebuild and isRebuild(part))
      advisor += parts where kind == advisor                         # R15
      if file.kind == subagent:
        bucket[subagents] += cost.total                    # R7
        if rebuild: count subagent rebuild
      else if not rebuild:
        bucket[normalWork] += cost.total
      else:
        cause = causeOf(call, last, lastTTL, compacted)    # R4
        bucket[normalWork] += cost.total - rebuilt.cacheWrite          # R8
        bucket[bucketOf(cause)] += rebuilt.cacheWrite
        if cause == expiredShortBreak: reducible += rebuilt.cacheWrite - rebuilt.writtenAsRead   # R12
        rebuilds.append(RebuildEvent(...))
    last = call                                            # R3: 복사된 호출도 맥락
    lastTTL = call.ttl ?? lastTTL                          # R5
    compacted = false                                      # R6
```

### 2.2 원인
```
causeOf(call, last, lastTTL, compacted):
  if last == nil: sessionStart
  elif compacted: afterCompaction
  elif call.model != last.model: modelChanged
  elif call.ts - last.ts > seconds(lastTTL):
      (call.ts - last.ts) <= 3h ? expiredShortBreak : expiredLongBreak
  elif call.version != last.version: versionChanged
  else: unknown
```

### 2.3 가격
```
prices(model, promptTokens):                   # promptTokens는 단계 하나의 값
  key = table[model] != nil ? model
      : (model matches "<key>-YYYYMMDD" and table[key] != nil) ? key
      : nil                                     # 새 마이너 버전도 nil
  p = table[key ?? "claude-opus-5-5"]           # nil이면 unpriced에 호출마다 한 번
  return (p.longContext != nil and promptTokens > p.longContext.over) ? p.longContext : p.base
```

## 3. 상태 전이 (State Transitions)

파일 걷기의 상태는 (`last`, `lastTTL`, `compacted`)다.

| 현재 상태 | 이벤트 | 다음 상태 | 액션 |
|---|---|---|---|
| 아무 상태 | 압축 경계 | `compacted = true` | |
| 아무 상태 | 호출(소유 여부와 무관) | `last = 호출`, `lastTTL = 호출.ttl ?? lastTTL`, `compacted = false` | 소유이고 기간 안이면 분류·집계 |

## 4. 시퀀스 / 상호작용 (Sequence)

1. 화면이 기간을 고르면 `IndexService.report(period:)`를 부른다(actor). 색인 쓰기와 겹치지 않는다.
2. CLI `report`의 출력 형식은 프로토타입과 같다. 숫자 형식은 `en_US` 천 단위 구분, 비율은 소수 첫째 자리, 금액은 `$`와 소수 둘째 자리다. 버킷 순서는 `normal work`, `rebuild after short break`, `rebuild after long break`, `session start & compaction`, `subagents`, `model change & update`, `unknown`.

## 5. 통합 지점 (Integration Points)

| 대상 | 호출 시점 | 요청/응답 요지 | 실패 처리 |
|---|---|---|---|
| 2-1 `Indexer` | 분석마다 | `ownedFiles`, `timeline`, `title` | 색인 오류는 그대로 던짐 |
| `pricing.json`(Swift 상수로 내장) | 보고서를 처음 만들 때 한 번 | 가격표 로드 | 형식 오류는 개발 오류(테스트와 CI로 막음). 색인은 가격표와 무관하게 동작 |
