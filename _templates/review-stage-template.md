---
phase: 0R-review
stage: 01-independent-review
status: PENDING
updated: YYYY-MM-DD
---

# [Stage R-1] Independent Code Review 🔍

## 목적

작성자(구현 주체)와 **컨텍스트가 분리된** 독립·적대적 리뷰어가 Construction 산출물(코드+테스트)을 검토하여
설계 게이트가 놓치는 코드 레벨 결함을 선제적으로 잡고, 진짜 결함을 수정한 뒤 Operations 진입을 게이트한다.

## 입력 (Inputs)

- Construction 전 스테이지 산출물: `{소스 경로}`
- 결정 로그: `../DECISIONS.md`
- 리뷰어 지시: `../../_templates/reviewer-brief-template.md` (채워서 사용)

## 체크리스트

- [ ] 독립 리뷰어(작성자와 분리된 별도 에이전트/세션/모델 또는 사람)로 적대적 리뷰 실행
- [ ] findings 를 severity 별로 정리하고 **각 항목 검증**(맹목 수용 금지)
- [ ] 진짜 결함 수정 + 회귀 테스트 추가
- [ ] 반박 항목은 근거 기록
- [ ] 수정 후 test/build/coverage 재확인

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 방식

- 리뷰어: {별도 에이전트/모델/사람 — 컨텍스트 분리 명시}, refute 모드.
- 받은 findings 를 그대로 구현하지 않고 각각 검증 후 채택/반박.

### 채택한 결함 (수정함)

| # | 심각도 | 결함 | 수정 | 테스트 |
|---|--------|------|------|--------|
| 1 | | | | |

### 반박/보류한 findings (근거)

- **[심각도] 항목** — {왜 결함이 아닌지/왜 수용 보류인지 근거}

### 수정 후 재검증

- 테스트 / 빌드 / 커버리지 결과.

## 검토 게이트 (Human Gate)

- [ ] 채택/반박 판정에 동의하는가?
- [ ] 수정된 결함(특히 CRITICAL/HIGH)이 적절히 해결되었는가?
- [ ] Operations 진입을 승인하는가?

## 다음 단계

승인 후 → `STATUS.md` 의 R-1 을 `HUMAN_APPROVED` 로 → Operations phase.
