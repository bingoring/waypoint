---
artifact: domain-entities
build-spec: salary
status: DRAFT
updated: 2026-10-14
---

# Domain Entities — 연봉 실수령액 계산기

> 금액은 모두 `int` 원 단위다. 요율은 `int` 100만분율(ppm, 4.75% = 47,500)로 들고, 부동소수점을 계산에 쓰지 않는다.

| 엔티티 | 필드 | 비고 |
|---|---|---|
| `PayInput` | `annualSalary`(원), `nonTaxableMonthly`(원, 기본 200,000), `dependents`(1~11, 기본 1), `children`(8~20세 자녀 0~`dependents−1`, 기본 0), `withholding`(80·100·120, 기본 100), `severanceIncluded`(bool, 기본 false) | 사용자 입력. 기기에만 저장 (S-DATA-1) |
| `InsuranceRates` | `from`(날짜), `npsPpm` 47,500, `npsBaseMin` 410,000, `npsBaseMax` 6,590,000, `healthPpm` 35,950, `healthBaseMin` 280,528, `healthBaseMax` 127,725,730, `ltcPpm` 4,724, `employmentPpm` 9,000 | 기간별 행. 국민연금 상·하한은 7월, 나머지는 1월에 바뀐다 → 기간 행을 날짜로 고른다 |
| `TaxTable` | `from` 2026-03-01, `rows: List<(lo, hi, taxes[11])>`(천 원), `at10000: taxes[11]`, `childCredit` (20,830 / 45,830 / +33,330) | 시행령 별표2. 초과 구간 6개 산식은 코드 상수 (S-TAX-3) |
| `RateBook` | `insurance: List<InsuranceRates>`, `tax: List<TaxTable>`, `source`(bundled·remote) | 에셋 ∪ 원격 중 유효하고 더 새 것 (S-DATA-3) |
| `Payslip` | `gross`(월 지급액), `nonTaxable`, `nps`, `health`, `ltc`, `employment`, `incomeTax`, `localTax`, `deductions`(합계), `net`(실지급액), `basis`(적용 요율 기간·세액표 시행일) | 급여명세서 순서 그대로 (조사 §5) |
| `RaiseComparison` | `before: Payslip`, `after: Payslip`, `grossRate`(연봉 인상률), `netDelta`(월 실수령 차이), `netRate`(실수령 증가율) | |
| `WorkSchedule` | `weekdays`(기본 월~금), `start` 09:00, `end` 18:00, `lunch` 12:00~13:00(on/off, 기본 on), `payday`(1~31 또는 말일, 기본 25), 주말 규칙: 직전 평일 | 사용자 설정. 기기에만 저장 |
| `PayPeriod` | `start`(직전 실제 월급날 00:00), `end`(다음 실제 월급날 00:00), `workSeconds`(기간 안 근무 초) | 순수 계산 결과 |
| `LiveEarnings` | `today`, `period`, `year`, `periodProgress`(0~1), `daysToPayday`(D-n), `state`(근무 중·근무 전·근무 끝·쉬는 날) | `now`의 순수 함수 (S-LIVE-1) |
