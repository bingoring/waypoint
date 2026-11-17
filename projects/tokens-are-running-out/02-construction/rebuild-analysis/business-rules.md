---
artifact: business-rules
build-spec: rebuild-analysis
status: READY
updated: 2026-11-17
---

# Business Rules — 재구축 판정 · 원인 분류 · 비용 분해

## 1. 규칙 표 (Rules)

| ID | 규칙 (결정적 서술) | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| R1 | 기간 판정은 소유 호출만 대상으로 하고, 그 호출의 시각(소유 파일에 쓰인 값)이 `from ≤ ts < to`일 때 기간 안이다 | `UsageAnalyzer` | | 2-1 R12, prototype |
| R2 | 재구축: 캐시 쓰기 ≥ 50,000이고 캐시 쓰기 > 캐시 읽기 | 소유 호출 | | design 6.2 |
| R3 | 직전 호출은 **같은 파일**의 직전 호출이다. 복사된(소유하지 않은) 호출도 직전 호출이 된다. 기간 밖의 호출도 맥락이 된다 | `RebuildClassifier` | | 2-1 계약 확장, prototype |
| R4 | 메인 파일의 재구축 원인은 아래 순서로 처음 맞는 것이다. ① 직전 호출 없음 → `sessionStart` ② 직전 호출 뒤에 압축 경계가 있음 → `afterCompaction` ③ 모델이 다름 → `modelChanged` ④ 간격 > 직전 TTL → 간격 ≤ 3시간이면 `expiredShortBreak`, 아니면 `expiredLongBreak` ⑤ 버전이 다름 → `versionChanged` ⑥ 그 밖 → `unknown` | `RebuildClassifier` | | design 6.3, DECISIONS |
| R5 | 직전 TTL: 직전 호출의 `ttl`. 없으면 같은 파일에서 가장 최근에 확인된 TTL. 그것도 없으면 메인 1시간, 서브에이전트 5분 | `RebuildClassifier` | | design 6.3 |
| R6 | 압축 경계 표시는 압축 경계를 만나면 켜지고, 다음 호출을 처리한 뒤 꺼진다(그 호출이 재구축이든 아니든) | `RebuildClassifier` | | prototype |
| R7 | 서브에이전트 파일의 소유 호출은 비용 전부를 `subagents`에 넣는다. 재구축이면 개수와 토큰만 센다(원인 없음, 목록 제외) | `UsageAnalyzer` | | design 6.4, 8.1 |
| R8 | 메인 파일의 재구축 호출은 캐시 쓰기 비용만 원인 버킷에 넣고, 나머지는 `normalWork`에 넣는다. 재구축이 아닌 호출은 전부 `normalWork`다. 원인 → 버킷: `sessionStart`·`afterCompaction` → `sessionStartAndCompaction`, `modelChanged`·`versionChanged` → `modelChangeAndUpdate`, 만료는 휴식 길이별 버킷, `unknown` → `unknown` | `UsageAnalyzer` | | design 6.4 |
| R9 | 비용: 쓰기 = 1시간 쓰기 토큰 × `cacheWrite1h` + 5분 쓰기 토큰 × `cacheWrite5m`. 세부 필드가 둘 다 0인데 캐시 쓰기 토큰이 있으면 전부 1시간으로 본다. 그 밖 = 입력 × `input` + 출력 × `output` + 캐시 읽기 × `cacheRead`. 단가는 백만 토큰당이다 | `CallCost` | | 공식 가격, prototype |
| R10 | 가격 선택: 모델 ID와 같거나 `키 + "-"`로 시작하는 키 중 가장 긴 키. 그 모델에 `longContext`가 있고 프롬프트(입력 + 캐시 읽기 + 캐시 쓰기) > `overPromptTokens`이면 긴 구간 가격 | `PriceTable` | | 공식 가격 "Long context pricing" |
| R11 | 맞는 키가 없으면 `claude-opus-5-5` 가격으로 계산하고 `unpricedModels`에 센다 | `PriceTable` | 보고서에 표시 | 2-2 결정 |
| R12 | 줄일 수 있었던 양 = 짧은 휴식 재구축마다 (캐시 쓰기 비용 − 쓴 토큰 × `cacheRead`)의 합 | `UsageAnalyzer` | | DECISIONS |
| R13 | 메뉴 막대 숫자 = (짧은 휴식 + 긴 휴식 재구축의 캐시 쓰기 비용) ÷ 전체 비용. 전체 비용이 0이면 0 | `UsageAnalyzer` | | DECISIONS |
| R14 | 기간: `last5Hours` = `[now − 5h, now)`, `today` = `[로컬 오늘 자정, now)`, `last7Days` = `[now − 7 × 24h, now)` | `ReportPeriod` | | design 6.6 |

## 2. 검증 규칙 (Validation)

| 입력 | 규칙 | 경계/형식 | 실패 메시지·코드 |
|---|---|---|---|
| `report --from`, `--to` | `stats`와 같음(ISO 8601 UTC, `from < to`) | | 종료 코드 2 |
| `pricing.json` | 모든 모델이 다섯 단가를 가진다. 단가 ≥ 0 | | 앱 시작 시 실패하면 개발 오류(테스트로 막음) |

## 3. 권한 / 접근 규칙 (Authz)

해당 없음. 색인만 읽는다.

## 4. 불변식 (Invariants)

- INV1: 버킷 비용의 합 = `totalCost`(부동소수 오차 1e-9 이내).
- INV2: `rebuildCount = subagentRebuildCount + Σ mainRebuildCounts`.
- INV3: 원인 판정은 그 호출보다 앞선 사건만 본다.
- INV4: 같은 기간의 `running-out report` 출력은 `prototype/drain.py` 출력과 글자 단위로 같다.
- INV5: 결과는 파일을 읽은 순서와 무관하다(2-1 INV5에 의존).

## 5. 엣지케이스 · 에러 매핑

| 케이스 | 조건 | 기대 동작 |
|---|---|---|
| 임계값 경계 | 캐시 쓰기 = 50,000 / 49,999 | 재구축 / 아님 |
| 쓰기 = 읽기 | 캐시 쓰기 = 캐시 읽기 ≥ 50,000 | 재구축 아님 |
| TTL 경계 | 간격 = 3,600초(1시간 TTL) / 3,601초 | 만료 아님(버전 같으면 `unknown`) / 만료 |
| 휴식 경계 | 간격 = 3시간 / 3시간 + 1초 | 짧은 휴식 / 긴 휴식 |
| 5분 TTL | 직전 호출의 TTL이 5분, 간격 6분 | 만료(짧은 휴식) |
| TTL 없는 직전 호출 | 직전 호출의 쓰기 세부가 둘 다 0 | 파일에서 가장 최근 TTL, 없으면 기본값 |
| 압축 다음 호출 | 압축 경계 직후의 재구축 | `afterCompaction`(간격과 무관) |
| 압축 뒤 재구축 아닌 호출 | 압축 직후 호출이 재구축이 아님 | 압축 표시가 꺼져 그다음 재구축에 영향 없음 |
| 모델 변경과 만료가 겹침 | 모델이 다르고 간격도 TTL 초과 | `modelChanged`(순서상 먼저) |
| 복사된 직전 호출 | 직전 호출이 다른 파일 소유 | 맥락으로 쓰되 개수·비용에는 넣지 않음 |
| 기간 밖 직전 호출 | 직전 호출이 `from` 이전 | 맥락으로 씀 |
| 서브에이전트 재구축 | 서브에이전트 파일 | 개수·토큰만, 비용 전부 `subagents` |
| 가격표에 없는 모델 | 예: `claude-future-9` | Opus 5.5 가격, `unpricedModels`에 1 |
| 날짜 붙은 모델 ID | `claude-sonnet-4-5-20250929` | `claude-sonnet-4-5` 가격 |
| `claude-opus-5-5` | `claude-opus-5`와 `claude-opus-5-5`가 모두 접두사 | 더 긴 `claude-opus-5-5` |
| Haiku 구간 경계 | 프롬프트 = 100,000 / 100,001 | 기본 / 긴 구간 |
| 빈 기간 | 호출 0건 | 모든 값 0, 메뉴 막대 숫자 0 |
| 오늘 | 로컬 시간대 | 자정은 사용자의 현재 시간대 기준 |
