---
build-spec: salary
stage: 02-construction/04-salary
status: READY
depth: standard
updated: 2026-10-14
---

# Build Spec — 연봉 실수령액 계산기

## §0. 개요 & 범위
- **목표(한 줄):** 연봉 → 급여명세서형 월 실수령액 + 연봉 인상 비교 + 근무 시간에 초 단위로 쌓이는 실시간 수입 앱 `apps/salary`.
- **SoT:** 1-1 §7(연봉), 1-2 §10(매핑), DECISIONS 2026-10-14(기능 범위·입력 기본값·근무 기본값·전면 광고 자리).
- **규모/제약:** 오프라인 동작(요율 에셋 내장), 서버 0원, 권한 추가 없음, 한국어 전용, 다운로드 ≤ 15MB. 입력값은 기기 밖으로 나가지 않는다.
- **깊이 티어 & 사유:** `standard` + frontend-components. 세금 계산은 규칙이 많아 BR·BLM에 계산 순서와 끝수를 고정한다.

## §1. 분해

| 단위 | 책임 |
|---|---|
| `lib/domain/` | 명세서 계산(4대 보험·소득세·지방소득세), 인상 비교, 근무 일정·월급 기간·실시간 수입 — 순수 Dart |
| `lib/data/` | 요율 저장소(에셋 ∪ 원격, 형식 검사), 입력·근무 설정 저장 |
| `lib/ui/` | 명세서 · 비교 · 지금 · 설정 화면, `PayslipCard`, `RollingAmount`, 숫자 패드 |
| `assets/rates.json` | 4대 보험 기간 행 + 2026.3 간이세액표(646행 + 1,000만 원 행) |
| `tool/convert_tax_table.dart` | 홈택스 Excel → `rates.json` 세액표, 구조·단조성·예시 대조 |
| `test/golden_test.dart` | 공식 모의계산에서 모은 입력→출력 쌍 |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 |
|---|---|---|
| research | ✅ | [`research-2026-10-14.md`](research-2026-10-14.md) — 외부 사실 표기 규칙 적용 |
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) — APP_DESIGN_PROMPT v1 |

## §3. 미해결 질문

- [x] 입력 기본값 → 비과세 식대 20만 원, 퇴직금 별도(÷12), 부양가족 1명, 자녀 0명, 100% (2026-10-14)
- [x] 근무 기본값 → 월~금 09:00~18:00, 점심 1시간 제외, 월급날 25일(주말이면 직전 금요일), 공휴일 미반영 (2026-10-14)
- [x] 전면 광고 → 인상 비교를 3번 할 때마다 1번 (2026-10-14)
- [x] 간이세액표 원본 → 홈택스 Excel 내려받기 (2026-10-14 허용, 646행 검사 통과)
- [x] 끝수 3개와 골든 벡터 → 공식 모의계산 화면 조회 허용 (2026-10-14), 구현 첫 단계에서 확정 (BLM §3)
- [x] `READY` 승인 (2026-10-14)

## §4. 구현 체크리스트

- [x] `factory new salary --category calculator` · `factory firebase salary` (커밋 `e5106de`)
- [ ] `app.yaml`: 시드 색 #1E6B52, placements(`banner_home`·`banner_live`·`interstitial_compare` everyN 3), keyAction `calculate_net`, events(`compare_raise`·`setup_live`·`open_live`·`expand_line`), 원격 기본값 `app_salary_rates_v1: ""`
- [ ] 끝수 확정 + 골든 벡터 수집 (§3)
- [ ] `tool/convert_tax_table.dart` → `assets/rates.json` + 원본 1:1 대조 테스트
- [ ] domain: 명세서 계산·비교·근무 일정·실시간 수입 + 단위 테스트(골든·경계·기간 계산)
- [ ] data: 요율 저장소(원격 형식 검사)·입력 저장 + 단위 테스트
- [ ] UI: 명세서·비교·지금·설정, `PayslipCard`, `RollingAmount`, 숫자 패드
- [ ] 위젯 테스트(핵심 흐름, 숨은 탭에서 실시간 타이머 정지, 누수 0)
- [ ] store 문구(ko)·data-safety·개인정보처리방침 초안
- [ ] 릴리스 리허설: 서명 AAB → `validate --release` → `size`

## §5. 검증 계획
- [ ] 분석·포맷·의존 검사·`validate` 통과
- [ ] 골든 벡터 15개 이상 일치, 세액표 646행 원본 일치
- [ ] 실시간: 기간 경계(월급날 주말·말일·2월), 근무 전·후·점심·쉬는 날, 시간 변경 후 즉시 정합
- [ ] 위젯 테스트: 연봉 입력 → 명세서 갱신, 비교 3회 → 전면 광고 판정, 설정 → 지금 화면 증가, 숨은 탭 타이머 정지
- [ ] 에뮬레이터: 전 화면 스크린숏, 프롬프트 5단계 검사(FC §9)
- [ ] 크기 ≤ 15MB, 콜드 스타트 ≤ 1.5초, PSS ≤ 200MB, 「지금」 화면 1분 유지 시 프레임 드롭·메모리 증가 없음

## §6. NFR
N/A (standard). 2-1 G1·1-3 §7.4 예산을 §5에서 측정한다.

## §7. 편차 로그

| SoT | 실제 구현 | 사유 |
|---|---|---|
| 시드 색 | 생성기 제안 #BF569E → #1E6B52 | 「늘어나는 돈」 상징, 대비 6.4:1 (FC §5) |
