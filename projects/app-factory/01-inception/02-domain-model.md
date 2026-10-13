---
phase: 01-inception
stage: 02-domain-model
status: IN_PROGRESS
updated: 2026-10-13
---

# [Stage 1-2] Domain Model

## 목적

App Factory의 핵심 데이터 계약을 정의한다: 앱 설정 스키마, 기능 모듈 계약, 광고 정책 모델, 원격 설정 키, 분석 이벤트 스키마.
이 계약이 공통 코어와 개별 앱의 경계가 된다.

## 입력 (Inputs)

- [`01-context-synthesis.md`](01-context-synthesis.md) (HUMAN_APPROVED 필요) — §5 포트폴리오 규칙, §6 공통 모듈 요구사항, §7 Wave 1
- [`../prd.md`](../prd.md)
- [`../DECISIONS.md`](../DECISIONS.md)

## 체크리스트

- [ ] `AppConfig` 스키마: 앱 ID, 이름, 패키지 ID, 지원 언어, 광고 단위 ID, 디자인 토큰, 기능 플래그 기본값
- [ ] 기능 모듈 계약: 코어가 앱에 제공하는 것 / 앱이 코어에 제공하는 것
- [ ] 광고 정책 모델: 형식별 노출 규칙, 빈도 제한, 광고 제거 상태, 디버그 테스트 ID 강제
- [ ] 원격 설정 키 체계: 공통 키와 앱별 키의 네임스페이스, 내장 기본값
- [ ] 분석 이벤트 스키마: 공통 이벤트, 앱별 이벤트 명명 규칙, 광고 수익 이벤트
- [ ] 동의 상태 흐름: UMP·ATT 결과가 광고·분석 초기화에 미치는 영향
- [ ] 광고 제거 인앱결제 상품 모델과 가격

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[1-1 승인 후 작성]*

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] 모든 Wave 1 앱을 이 계약만으로 표현할 수 있는가?
- [ ] 포트폴리오 규칙 P3(보이는 셸 비공유)이 계약에 반영되었는가?
- [ ] 광고 정책 모델이 AdMob 정책(1-1 E4)을 위반하지 않는가?

## 다음 단계

승인 후 → `STATUS.md`에서 1-2 상태를 `HUMAN_APPROVED`로 업데이트 → `03-architecture-decision.md`로 이동
