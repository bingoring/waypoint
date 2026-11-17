---
build-spec: rebuild-analysis
stage: 02-construction/02-rebuild-analysis
status: IMPLEMENTED
depth: standard
updated: 2026-11-17
---

# Build Spec — 재구축 판정 · 원인 분류 · 비용 분해

## §0. 개요 & 범위
- **목표(한 줄):** 기간을 받아, 그 기간의 호출을 공식 가격으로 환산하고 캐시 재구축을 원인별로 분류해 `UsageReport`를 돌려주는 분석 코어와 `running-out report`.
- **SoT(진실 공급원):**
  - [`../../inputs/design.md`](../../inputs/design.md) 6.1 ~ 6.6
  - [`../../01-inception/02-domain-model.md`](../../01-inception/02-domain-model.md)의 Rebuild, Cause, CostWeights, Period(2-2 계약 정정 포함)
  - [`../../DECISIONS.md`](../../DECISIONS.md): 짧은 휴식과 긴 휴식(3시간), 메뉴 막대 숫자
  - 2-1의 `Indexer.timeline(of:)`(파일 순서, 그 파일에 쓰인 값, `owned`)
  - 메인 저장소 `prototype/drain.py`(가격표 반영판)와 `pricing.json`
- **규모/제약:**
  - 개발자 기기 기준 호출 약 4만 4천 건, 기록 파일 670개
  - 화면이 열릴 때마다 계산하므로 7일 보고서가 빨라야 한다(§5)
  - 외부 의존성과 네트워크는 쓰지 않는다
- **깊이 티어 & 사유:** `standard`. 판정과 분류 규칙이 핵심이고, 화면은 2-3에서 다룬다.

## §1. 분해 (Decomposition)

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `pricing.json` (`Sources/RunningOutCore/Resources/`) | 공식 가격표. 프로토타입이 읽고, 앱에는 `scripts/embed-pricing.py`가 Swift 상수(`PricingData.swift`)로 내장한다 | 없음 | 신규 |
| `PriceTable` | 가격표 로드, 정확히 같거나 날짜 접미사인 키 일치, 단계별 Haiku 5.5 구간, 대체 모델 검사 | `pricing.json` | 신규 |
| `CallCost` | 단계 하나 또는 호출 하나(단계 비용의 합)의 (캐시 쓰기 비용, 그 밖의 비용, 쓴 토큰을 캐시 읽기로 냈다면의 비용) | `PriceTable` | 신규 |
| `UsagePart`, `RecordParser` | `usage.iterations`를 단계로 읽고 advisor 단계를 구분, 토큰 수 범위 검사 | 2-1 | 기존 확장(구현 중 추가) |
| `Indexer` 스키마 v3 | 같은 메시지의 마지막 줄 usage와 단계를 저장(R16) | 2-1 | 기존 확장(구현 중 추가) |
| `RebuildClassifier` | 파일 하나의 타임라인을 순서대로 걸으며 소유 호출의 재구축 여부와 원인을 정한다 | 2-1 `TimelineEvent` | 신규 |
| `UsageAnalyzer` | 기간 안의 소유 호출이 있는 파일을 찾아 분류하고, 비용을 분해해 `UsageReport`를 만든다 | `Indexer`, 위 둘 | 신규 |
| `Indexer.ownedFiles(from:to:)` | 기간 안에 소유 호출이 있는 파일과 그 종류·세션 ID | SQLite | 기존 확장 |
| `ReportPeriod` | 최근 5시간, 오늘(로컬 자정), 최근 7일 → `[from, to)` | Foundation `Calendar` | 신규 |
| `IndexService` | 위 분석을 actor 뒤로 노출 | `UsageAnalyzer` | 기존 확장 |
| `running-out report` | 프로토타입과 같은 형식으로 출력 | `UsageAnalyzer` | 신규 |
| `prototype/drain.py` | `pricing.json`을 읽어 같은 보고서를 출력 | `pricing.json` | 기존 수정 |
| `prototype/parity.sh`, `ParityTests` | 합성 픽스처에서 앱과 프로토타입의 출력이 같은지 확인(CI) | 위 둘 | 신규(독립 리뷰 반영) |

## §2. 아티팩트 인덱스 (Manifest)

| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`./domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`./business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`./business-logic-model.md`](business-logic-model.md) |
| frontend-components | N/A | 2-2에는 화면이 없다. 화면은 2-3에서 다룬다. |

## §3. 미해결 질문 (Open Questions)

없음. 작성자 판단으로 정한 것은 [DECISIONS](../../DECISIONS.md)에 기록했다.

## §4. 구현 체크리스트

- [x] `pricing.json`과 `PriceTable`(정확히 같거나 날짜 접미사, 단계별 Haiku 구간, 미확인 모델 집계)
- [x] `CallCost`(단계별, 1시간·5분 쓰기 분리, 세부가 덮지 못한 쓰기는 1시간으로 계산)
- [x] `RebuildClassifier`(규칙 R1 ~ R8, 파일 맥락은 복사된 호출 포함)
- [x] `Indexer.ownedFiles(from:to:)`
- [x] `UsageAnalyzer`와 `UsageReport`(버킷, 재구축 목록, 메뉴 막대 숫자, 줄일 수 있었던 양)
- [x] `ReportPeriod`
- [x] `IndexService`에 분석 노출
- [x] `running-out report --from --to`
- [x] 프로토타입이 `pricing.json`을 읽고 같은 형식으로 출력
- [x] 합성 픽스처 단위 테스트(business-rules §5의 모든 경계)
- [x] 세 기간 기준값 대조와 7일 보고서 성능 측정, 결과를 스테이지 문서에 기록
- [x] 독립 리뷰와 그 반영
- [x] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획
- [x] 엄격 빌드(경고=오류), `swift format lint --strict`, 기존 테스트 포함 전체 통과
- [x] PR 브랜치에 base merge 커밋 없음
- [x] 단위 테스트: business-rules §5의 경계마다 하나 이상. 비용 기대값은 손으로 계산한 값을 쓴다
- [x] 기준값: 세 기간(2026-10-01 ~ 11-01, 11-01 ~ 11-10, 11-10 ~ 11-17)에서 `running-out report`의 출력이 `prototype/drain.py`의 출력과 **글자 단위로** 같다. 기준 기간의 주요 값은 아래와 같다(구현 중 단계별 계산·마지막 줄 규칙을 반영해 바뀐 값. 제안 당시 값은 취소선).
  - 호출 4,133건, 재구축 ~~80건~~ **81건**(서브에이전트 18, 메인 ~~62~~ **63**: 만료 50, 압축 직후 9, 모델 변경 ~~3~~ **4**)
  - 만료 중 짧은 휴식 16건, 긴 휴식 34건
  - API 정가 환산 ~~$616.33~~ **$807.63**(그중 advisor 75건 $188.28, 23.3%)
  - 버킷: 일반 작업 63.3%, 짧은 휴식 후 재구축 6.1%, 긴 휴식 후 재구축 12.1%, 세션 시작과 압축 0.6%, 서브에이전트 16.5%, 모델 변경과 업데이트 1.5%, 원인 불명 0.0%
  - 메뉴 막대 숫자 ~~23.9%~~ **18.2%**, 줄일 수 있었던 양 ~~7.8%~~ **5.9%**
- [x] 합성 픽스처에서도 두 출력이 같다(`prototype/parity.sh`, `ParityTests`, CI)
- [x] 성능(개발자 기기, 색인이 이미 있을 때): 최근 7일 보고서 1초 이내, 오늘 보고서 0.3초 이내. 측정값을 스테이지 문서에 기록

## §6. NFR · 성능 (comprehensive 전용)

N/A (standard). 성능 목표는 §5에 포함했다.

## §7. 편차 로그 (Deviations) — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| design 6.1 "캐시 읽기 ×0.1" | 모델별 공식 가격표 | 공식 가격이 모델마다 다르다(2-2 제안, 구현 전 확정) |
| design 6.1 가격 | fast mode, 미국 전용 추론(1.1배) 요금 미반영 | 실제 기록 0건. v2 후보 |
| R9: 호출의 최상위 usage 하나로 계산 | 단계(`usage.iterations`)마다 그 단계의 모델·TTL 세부로 계산해 더함 | 최상위 usage는 advisor 단계의 입력·출력을 빼고 TTL 세부는 첫 단계 것만 담는다. 기준 기간에서 advisor 비용 $188.28이 빠져 있었다 |
| R2: 호출 합계로 재구축 판정 | 본 모델 단계마다 판정, 원인 버킷에는 재구축한 단계의 쓰기만 | 첫 단계가 재구축하고 다음 단계가 다시 읽으면 합계로는 가려진다. 실제 기록 전체에서 46건(파일 단위) |
| 2-1 R5: 같은 메시지는 첫 줄만 | 위치·시각·모델·버전은 첫 줄, usage와 단계는 마지막 줄(R16, 스키마 v3) | 스트리밍 중 쓴 첫 줄 usage가 미완성인 경우가 504건(파일·메시지 쌍)이었다. 10월 비용이 $86.98 달라진다 |
| R10: 가장 긴 접두사 일치 | 정확히 같거나 날짜 접미사일 때만 | 독립 리뷰 MEDIUM. `claude-opus-5-6` 같은 새 마이너 버전이 옛 가격으로 '확인됨' 처리되었다 |
| `pricing.json`을 번들 리소스로 읽음 | Swift 상수로 내장, 보고서를 처음 만들 때 로드 | 독립 리뷰 MEDIUM. 리소스 번들을 못 찾으면 앱 전체가 멈출 수 있었다 |
| (명세 없음) | 토큰 수 범위 검사(R17), CLI 소수 초 거부, 공개 값 타입의 public init, 보고서의 advisor 합계 줄(R15) | 독립 리뷰 MEDIUM·LOW, DECISIONS |
| domain-entities: 금액 Double, INV1 오차 1e-9 | 나노달러 정수, INV1 정확히 같음 | 구현 착수 때 정한 대로(문서만 늦게 맞춤) |
