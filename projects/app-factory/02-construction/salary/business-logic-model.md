---
artifact: business-logic-model
build-spec: salary
status: DRAFT
updated: 2026-10-14
---

# Business Logic Model — 연봉 실수령액 계산기

## 1. 흐름

### 1.1 계산 (`calculate(PayInput, RateBook, DateTime basisDate) → Payslip`)
1. S-PAY-1·2로 월 지급액·과세 월급여를 구한다.
2. `RateBook`에서 `basisDate`에 해당하는 `InsuranceRates`·`TaxTable`을 고른다 (S-RATE-1).
3. 4대 보험(S-INS-1~4) → 소득세(S-TAX-1~4) → 지방소득세(S-TAX-5).
4. `deductions` = 6개 합, `net` = `gross` − `deductions`. `basis`에 고른 기간을 담는다.

입력이 바뀔 때마다 동기 계산한다(수 μs). 결과는 Riverpod `Provider`로 파생하고 저장하지 않는다.

### 1.2 인상 비교
`before` = 현재 입력, `after` = 같은 입력에 새 연봉(직접 입력 또는 +3·5·10%). 비교 결과를 처음 볼 때 이벤트 `compare_raise`.

### 1.3 실시간 수입 (`liveEarnings(now, WorkSchedule, net) → LiveEarnings`)
1. S-LIVE-3으로 `now`를 포함하는 기간을 구하고, 기간 근무 초를 센다(하루 단위 반복, 최대 31일).
2. 기간 초당 금액 = `net ÷ workSeconds` (계산은 `int` 원 × 초 ÷ 초, 표시 직전에만 버림).
3. `today`·`period`·`year` (S-LIVE-4). `year`는 최대 13개 기간 → 1초마다 다시 계산해도 수십 μs.
4. 근무 시간 밖이면 `nextTick` = 다음 근무 시작 시각을 함께 돌려 준다 (S-LIVE-6).

### 1.4 요율 데이터
- 에셋 `assets/rates.json` = 보험 기간 행 + 세액표 1개(약 44KB). 앱 시작 뒤 첫 계산 때 한 번 읽어 `RateBook`으로 들고 있는다(디코딩 뒤 `Int32List` 646×11 ≈ 28KB).
- 원격 `app_salary_rates_v1`은 같은 형식. S-DATA-3 검사를 통과한 기간만 합친다.
- `tool/convert_tax_table.dart`: 홈택스 Excel → `rates.json`의 세액표 부분. 구조·단조성 검사(조사 §7)와 홈택스 예시 대조를 실패하면 쓰지 않는다. 다음 세액표 개정 때 다시 실행한다.
- 원격 갱신 절차(개정 시): 변환 → 골든 테스트 → Firebase 콘솔 또는 CLI로 `app_salary_rates_v1` 게시. 자동화는 개정이 1년에 1~2번이라 1.0 범위 밖이다.

## 2. 저장
| 키 | 내용 |
|---|---|
| `salary.input.v1` | `PayInput` JSON |
| `salary.schedule.v1` | `WorkSchedule` JSON |
| `salary.compare.v1` | 마지막 비교 연봉 |

`factory_core`의 `KeyValueStore`(`SharedPreferencesAsync`). 입력은 300ms 디바운스로 저장한다(입력값 유지 요청 대응).

## 3. 검증 (골든 벡터)
1. ✅ 끝수 3개(국민연금·고용보험·지방소득세)는 2026-10-14에 공식 모의계산 화면(4insure 4대보험 모의계산, 홈택스 간이세액표 조회)에 합성 입력을 넣어 확정한다. 홀수 천 원 급여(예: 2,001,000원 → 국민연금 95,047.5원)와 소득세 끝자리가 0이 아닌 경우를 고른다.
2. 같은 화면에서 입력→출력 쌍을 15개 이상 모아 `test/golden_test.dart` 고정값으로 쓴다: 저소득(월 106만 원 미만), 국민연금 상한 경계(659만), 건보 상한, 월 1,000만 원 정확히, 1,000만 초과 각 구간 1개(연 1억 3천 이상 포함), 자녀 1·2·3명, 80·120%.
3. 세액표 전체 646행은 원본 Excel과 1:1 대조 테스트(변환 도구 테스트).

## 4. 실패·경계
| 상황 | 동작 |
|---|---|
| 연봉 0 | 모든 줄 0원, 실시간 화면은 「연봉을 넣으면 시작해요」 |
| 기간 근무 초 0 (근무 요일을 모두 끔) | 설정 시트가 막는다 (요일 ≥ 1) |
| 기기 시간 변경·시간대 변경 | `now` 순수 함수라 다음 틱에 바로 맞는 값 |
| 원격 JSON 깨짐 | 무시, 비치명 기록 (S-DATA-3) |
