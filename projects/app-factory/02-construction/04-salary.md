---
phase: 02-construction
stage: 04-salary
status: AI_PROPOSED
updated: 2026-10-14
---

# [Stage 2-4] 연봉 실수령액 계산기

## 목적

Wave 1의 두 번째 앱. 연봉을 넣으면 급여명세서 형식으로 월 실수령액을 보여 주고, 연봉 인상 비교와 근무 시간에 초 단위로 쌓이는 실시간 수입을 제공한다.
생성기의 「2번째 앱부터 3일 이하」 가정을 이어서 검증한다.

## 입력 (Inputs)

- [`../01-inception/01-context-synthesis.md`](../01-inception/01-context-synthesis.md) §7 Wave 1(연봉)
- [`../01-inception/02-domain-model.md`](../01-inception/02-domain-model.md) §10 Wave 1 매핑
- [`02-app-generator.md`](02-app-generator.md), [`03-lotto.md`](03-lotto.md) — 생성기·파이프라인·첫 앱의 교훈
- [`../DECISIONS.md`](../DECISIONS.md) — 2026-10-14 연봉 계산기 기능 범위, 입력·근무 기본값

## 체크리스트

- [x] 기능 범위 질문 (2026-10-14): 계산 범위, 실시간 수입 기준, 보상형 여부
- [x] 계산 근거 조사 — [`salary/research-2026-10-14.md`](salary/research-2026-10-14.md)
- [x] 기본값 질문 (2026-10-14): 입력, 근무, 전면 광고, 세액표 원본
- [x] Build Spec 작성 — [`salary/build-spec-index.md`](salary/build-spec-index.md) (standard + frontend-components)
- [ ] Build Spec `READY` 승인
- [ ] 구현 (Build Spec §4)
- [ ] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **급여명세서가 주인공.** 결과는 실제 임금명세서 순서(지급액 → 공제 6줄 → 실지급액)로 보이고, 줄을 누르면 계산식이 펼쳐진다. 「다른 계산기와 다르다」는 불만(경쟁 앱 저평점 3위)에 화면이 직접 답한다.
2. **정확도는 테스트로 보장.** 간이세액표는 홈택스 Excel 원본에서 변환하고 646행 전체를 원본과 대조한다. 끝수 규칙과 골든 벡터는 공식 모의계산 화면에서 모아 테스트 고정값으로 쓴다.
   요율은 기간 행으로 관리하고 결과 아래에 적용 기준(「2026.7 4대보험 · 2026.3 간이세액표」)을 보인다.
3. **갱신 지연 대비.** 요율·세액표를 에셋에 넣어 오프라인으로 동작하고, 개정 때는 원격 `app_salary_rates_v1`(같은 형식, 약 44KB, Remote Config 한도 안)으로 앱 업데이트 없이 바꾼다.
4. **실시간 수입은 `now`의 순수 함수.** 누적 카운터를 두지 않아 앱 재시작·시간 변경에도 값이 어긋나지 않고, 화면이 보일 때만 1초 타이머가 돈다(로또의 숨은 탭 배너 교훈).
5. **입력값은 기기 밖으로 나가지 않는다.** 분석 이벤트에도 금액을 넣지 않는다(Data Safety: 앱이 수집하는 개인 데이터 없음, 광고·분석 SDK 항목만).

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec이 `READY`로 승인되었는가?
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

승인 후 → 2-5 소음 측정기
