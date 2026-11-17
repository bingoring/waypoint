---
artifact: domain-entities
build-spec: rebuild-analysis
status: READY
updated: 2026-11-17
---

# Domain & Entities — 재구축 판정 · 원인 분류 · 비용 분해

> 2-2의 엔티티는 모두 계산 결과이며 저장하지 않는다. 색인(2-1)에서 매번 계산한다. 금액은 API 정가 환산이고, 단위는 나노달러(1e-9 USD) 정수다. 단가는 백만 토큰당 1/1000 USD 정수다(예: $0.125 → 125). 그래서 합계가 더하는 순서와 무관하게 정확하다(구현 정정).

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT 출처 |
|---|---|---|---|
| `PriceTable` | 모델별 공식 가격 | `pricing.json`을 Swift 상수로 내장(`PricingData.swift`) | 공식 가격 페이지, 2-2 계약 정정 |
| `Prices` / `ModelPricing` | 한 구간의 백만 토큰당 가격 / 한 모델의 기본 구간과 긴 프롬프트 구간 | `pricing.json` | 같음 |
| `UsagePart` | 호출 안의 단계 하나(`usage.iterations`의 항목)의 사용량 | 색인 `occurrences.iterations`(2-1 확장) | 실제 기록 확인, DECISIONS 2026-11-17 |
| `AdvisorTotals` | 기간 안 advisor 단계의 합계 | 없음 | DECISIONS 2026-11-17 |
| `CallCost` | 호출 하나의 비용 분해 | 없음(계산) | design 6.1, 6.4 |
| `RebuildCause` | 재구축 원인 | 없음 | design 6.3, DECISIONS |
| `CostBucket` | 비용 분해 항목 | 없음 | design 6.4, DECISIONS |
| `RebuildEvent` | 재구축 하나와 분류 근거 | 없음 | design 6.3, 8.1 "분류 근거 보기" |
| `UsageReport` | 기간 하나의 분석 결과 | 없음 | design 6.4 ~ 6.6 |
| `ReportPeriod` | 화면의 기간 선택 | 없음 | design 6.6 |

## 2. 엔티티 상세

### `Prices` (구현에서 `ModelPrices`를 `Prices`와 `ModelPricing`으로 나눔)
| 필드 | 타입 | 필수 | 기본값 | 제약 | 설명 |
|---|---|---|---|---|---|
| `input` | Int | ✅ | | ≥ 0 | 백만 토큰당 입력(1/1000 USD) |
| `cacheWrite5m` | Int | ✅ | | ≥ 0 | 5분 캐시 쓰기 |
| `cacheWrite1h` | Int | ✅ | | ≥ 0 | 1시간 캐시 쓰기 |
| `cacheRead` | Int | ✅ | | ≥ 0 | 캐시 읽기 |
| `output` | Int | ✅ | | ≥ 0 | 출력 |

### `ModelPricing`
| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `base` | `Prices` | ✅ | 기본 구간 |
| `longContext` | (`overPromptTokens`: Int, `prices`: `Prices`) | | Haiku 5.5처럼 긴 프롬프트 구간이 있는 모델만 |

### `UsagePart`
| 필드 | 타입 | 설명 |
|---|---|---|
| `kind` | `message` / `advisor` | `type == "advisor_message"`이면 `advisor` |
| `model` | String? | 그 단계의 모델. nil이면 호출의 모델 |
| `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheWriteTokens`, `cacheWrite1h`, `cacheWrite5m` | Int | 그 단계의 사용량 |

- 2-1의 `CallRecord`에 `iterations: [UsagePart]`를 더했다. 단계가 하나뿐이고 최상위 값과 같으면 비워 둔다. `parts`는 `iterations`가 비면 최상위 값 하나를, 아니면 `iterations`를 돌려준다.
- 실제 기록의 최상위 usage는 advisor 단계의 입력·출력을 빼고, TTL 세부는 첫 단계 것만 담는다. 그래서 비용은 `parts`로 계산한다.

### `AdvisorTotals`
| 필드 | 타입 | 설명 |
|---|---|---|
| `calls` | Int | advisor 단계가 있던 소유 호출 수 |
| `inputTokens`, `outputTokens` | Int | advisor 단계의 합 |
| `cost` | Int | 나노달러. 이미 각 호출의 버킷에 들어 있다 |

### `PriceTable`
- `pricing.json` 형식(키 이름은 JSON 그대로):
  ```json
  {"source": "https://platform.claude.com/docs/en/about-claude/pricing", "retrieved": "2026-11-17",
   "unit": "USD per million tokens, standard speed, global inference",
   "models": {"claude-opus-5-5": {"input": 4, "cache_write_5m": 5, "cache_write_1h": 8, "cache_read": 0.2, "output": 20},
              "claude-haiku-5-5": {"input": 0.1, "...": "...", "long_context": {"over_prompt_tokens": 100000, "input": 0.5, "...": "..."}}}}
  ```
- `fallbackModel = "claude-opus-5-5"`
- 모델 ID는 키와 정확히 같거나 날짜 접미사(`-YYYYMMDD`)가 붙은 경우에만 그 키의 가격을 쓴다(R10).
- `unpricedModels: [String: Int]`는 `UsageReport`에 둔다(가격표에 없던 모델과 호출 수).

### `CallCost`
| 필드 | 타입 | 설명 |
|---|---|---|
| `cacheWrite` | Int | 1시간 쓰기 토큰 × 1시간 단가 + 5분 쓰기 토큰 × 5분 단가(나노달러) |
| `other` | Int | 입력, 출력, 캐시 읽기 비용의 합 |
| `writtenAsRead` | Int | 이번에 쓴 캐시 토큰을 캐시 읽기로 처리했다면의 비용 |
| `known` | Bool | 모든 단계의 모델이 가격표에 있었는가 |
| `total` | Int | `cacheWrite + other` |

- 단계 하나의 비용(`cost(of: UsagePart, model:)`)과 호출 하나의 비용(단계 비용의 합)을 같은 타입으로 나타낸다.

### `RebuildEvent`
| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `messageID` | String | ✅ | |
| `timestamp` | Double | ✅ | 이 호출의 시각 |
| `file` | URL | ✅ | 소유 파일 |
| `sessionID` | String | ✅ | |
| `title` | String? | | 세션 제목(없으면 nil) |
| `cause` | `RebuildCause` | ✅ | |
| `previousTimestamp` | Double? | | 같은 파일의 직전 호출 시각(세션 시작이면 nil) |
| `gapSeconds` | Double? | | `timestamp - previousTimestamp` |
| `previousTTL` | `CacheTTL` | ✅ | 판정에 쓴 TTL |
| `previousModel`, `model` | String?, String | | 모델 변경 근거 |
| `previousVersion`, `version` | String?, String? | | 업데이트 근거 |
| `cacheWriteTokens` | Int | ✅ | 재구축한 단계가 쓴 토큰 |
| `cacheWriteCost` | Int | ✅ | 재구축한 단계의 캐시 쓰기 비용(나노달러) |
| `reducibleCost` | Int | ✅ | 짧은 휴식이면 `cacheWrite - writtenAsRead`(재구축한 단계 기준), 아니면 0 |

- 서브에이전트의 재구축은 `RebuildEvent`로 만들지 않고 개수만 센다(design 8.1: 목록에서 제외).

### `UsageReport`
| 필드 | 타입 | 설명 |
|---|---|---|
| `from`, `to` | Double | `[from, to)` |
| `calls` | Int | 소유 호출 수 |
| `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheWriteTokens` | Int | |
| `totalCost` | Int | 나노달러 |
| `bucketCosts` | `[CostBucket: Int]` | 모든 버킷을 포함(0이어도) |
| `rebuildCount` | Int | 메인과 서브에이전트 합 |
| `rebuildTokens` | Int | |
| `subagentRebuildCount` | Int | |
| `mainRebuildCounts` | `[RebuildCause: Int]` | 만료는 짧은 휴식과 긴 휴식으로 나뉜다 |
| `shortBreak`, `longBreak` | `BreakTotals`(count, tokens, cost: Int) | |
| `advisor` | `AdvisorTotals` | advisor 단계 합계(R15) |
| `idleRebuildShare` | Double | 메뉴 막대 숫자 |
| `reducibleShare` | Double | |
| `rebuilds` | `[RebuildEvent]` | 메인 세션의 재구축, 시각 순 |
| `unpricedModels` | `[String: Int]` | |

## 3. 관계 (Relationships)

| 좌 | 카디널리티 | 우 | 비고 |
|---|---|---|---|
| `UsageReport` | 1─* | `RebuildEvent` | |
| `RebuildEvent` | *─1 | 2-1 `TranscriptFile`(소유 파일) | |
| `CallRecord` | 1─* | `UsagePart` | `parts` |
| `UsagePart` | *─1 | `ModelPricing` | 키와 정확히 같거나 날짜 접미사(R10) |

## 4. 열거형 / Allowed-set

| 이름 | 값 | 확장 규칙 |
|---|---|---|
| `RebuildCause` | `sessionStart`, `afterCompaction`, `modelChanged`, `expiredShortBreak`, `expiredLongBreak`, `versionChanged`, `unknown` | 새 원인은 판정 순서와 함께 추가 |
| `CostBucket` | `normalWork`, `shortBreakRebuild`, `longBreakRebuild`, `sessionStartAndCompaction`, `subagents`, `modelChangeAndUpdate`, `unknown` | 화면(2-3) 표기와 함께 추가 |
| `ReportPeriod` | `last5Hours`, `today`, `last7Days` | |

## 5. SoT 매핑 (SoT → 타입)

| SoT 요소 | 엔티티.필드 | 비고 |
|---|---|---|
| design 6.4 "일반 작업" | `CostBucket.normalWork` | |
| design 6.4 "짧은 휴식 후 캐시 재구축" | `CostBucket.shortBreakRebuild` | |
| design 6.4 "긴 휴식 후 캐시 재구축" | `CostBucket.longBreakRebuild` | |
| design 6.4 "세션 시작과 압축" | `CostBucket.sessionStartAndCompaction` | |
| design 6.4 "서브에이전트" | `CostBucket.subagents` | |
| design 6.4 "모델 변경과 업데이트" | `CostBucket.modelChangeAndUpdate` | |
| design 6.4 "원인 불명" | `CostBucket.unknown` | |
| design 6.4 "메뉴 막대의 숫자" | `UsageReport.idleRebuildShare` | |
| design 6.4 "줄일 수 있었던 양" | `UsageReport.reducibleShare`, `RebuildEvent.reducibleCost` | |
| design 8.1 "분류 근거 보기" | `RebuildEvent`의 previous* 필드 | |
