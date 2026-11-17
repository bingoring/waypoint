---
build-spec: rebuild-analysis
stage: 02-construction/02-rebuild-analysis
status: READY
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
| `pricing.json` (`Sources/RunningOutCore/Resources/`) | 공식 가격표. 프로토타입도 같은 파일을 읽는다 | 없음 | 신규 |
| `PriceTable` | 가격표 로드, 모델 ID의 가장 긴 접두사 일치, Haiku 5.5 구간, 표에 없는 모델 집계 | `pricing.json` | 신규 |
| `CallCost` | 호출 하나의 (캐시 쓰기 비용, 그 밖의 비용, 쓴 토큰을 캐시 읽기로 냈다면의 비용) | `PriceTable` | 신규 |
| `RebuildClassifier` | 파일 하나의 타임라인을 순서대로 걸으며 소유 호출의 재구축 여부와 원인을 정한다 | 2-1 `TimelineEvent` | 신규 |
| `UsageAnalyzer` | 기간 안의 소유 호출이 있는 파일을 찾아 분류하고, 비용을 분해해 `UsageReport`를 만든다 | `Indexer`, 위 둘 | 신규 |
| `Indexer.ownedFiles(from:to:)` | 기간 안에 소유 호출이 있는 파일과 그 종류·세션 ID | SQLite | 기존 확장 |
| `ReportPeriod` | 최근 5시간, 오늘(로컬 자정), 최근 7일 → `[from, to)` | Foundation `Calendar` | 신규 |
| `IndexService` | 위 분석을 actor 뒤로 노출 | `UsageAnalyzer` | 기존 확장 |
| `running-out report` | 프로토타입과 같은 형식으로 출력 | `UsageAnalyzer` | 신규 |
| `prototype/drain.py` | `pricing.json`을 읽어 같은 보고서를 출력 | `pricing.json` | 기존 수정 |

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

- [ ] `pricing.json`과 `PriceTable`(접두사 일치, Haiku 구간, 미확인 모델 집계)
- [ ] `CallCost`(1시간·5분 쓰기 분리, 세부 필드가 없으면 1시간으로 계산)
- [ ] `RebuildClassifier`(규칙 R1 ~ R8, 파일 맥락은 복사된 호출 포함)
- [ ] `Indexer.ownedFiles(from:to:)`
- [ ] `UsageAnalyzer`와 `UsageReport`(버킷, 재구축 목록, 메뉴 막대 숫자, 줄일 수 있었던 양)
- [ ] `ReportPeriod`
- [ ] `IndexService`에 분석 노출
- [ ] `running-out report --from --to`
- [ ] 프로토타입이 `pricing.json`을 읽고 같은 형식으로 출력
- [ ] 합성 픽스처 단위 테스트(business-rules §5의 모든 경계)
- [ ] 세 기간 기준값 대조와 7일 보고서 성능 측정, 결과를 스테이지 문서에 기록
- [ ] 독립 리뷰와 그 반영
- [ ] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획
- [ ] 엄격 빌드(경고=오류), `swift format lint --strict`, 기존 테스트 포함 전체 통과
- [ ] PR 브랜치에 base merge 커밋 없음
- [ ] 단위 테스트: business-rules §5의 경계마다 하나 이상. 비용 기대값은 손으로 계산한 값을 쓴다
- [ ] 기준값: 세 기간(2026-10-01 ~ 11-01, 11-01 ~ 11-10, 11-10 ~ 11-17)에서 `running-out report`의 출력이 `prototype/drain.py`의 출력과 **글자 단위로** 같다. 기준 기간의 주요 값은 다음과 같다.
  - 호출 4,133건, 재구축 80건(서브에이전트 18, 메인 62: 만료 50, 압축 직후 9, 모델 변경 3)
  - 만료 중 짧은 휴식 16건, 긴 휴식 34건
  - API 정가 환산 $616.33
  - 버킷: 일반 작업 61.1%, 짧은 휴식 후 재구축 8.0%, 긴 휴식 후 재구축 15.9%, 세션 시작과 압축 0.7%, 서브에이전트 12.8%, 모델 변경과 업데이트 1.5%, 원인 불명 0.0%
  - 메뉴 막대 숫자 23.9%, 줄일 수 있었던 양 7.8%
- [ ] 성능(개발자 기기, 색인이 이미 있을 때): 최근 7일 보고서 1초 이내, 오늘 보고서 0.3초 이내. 측정값을 스테이지 문서에 기록

## §6. NFR · 성능 (comprehensive 전용)

N/A (standard). 성능 목표는 §5에 포함했다.

## §7. 편차 로그 (Deviations) — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| design 6.1 "캐시 읽기 ×0.1" | 모델별 공식 가격표 | 공식 가격이 모델마다 다르다(2-2 제안, 구현 전 확정) |
| design 6.1 가격 | fast mode, 미국 전용 추론(1.1배) 요금 미반영 | 실제 기록 0건. v2 후보 |
