---
phase: 01-inception
stage: 01-context-synthesis
status: PENDING
updated: 2026-06-02
---

# [Stage 1-1] Context Synthesis

## 목적

prd.md와 prd-tech.md를 분석하여 Shadow Engineer가 통합할 4각 툴(Notion/Confluence/Jira/Slack)의 역할, 데이터 가중치, 3-Layer 병합 전략을 명세한다.

## 입력 (Inputs)

- `../../prd.md` — 제품 요구사항 (섹션 1~3 중점)
- `../../prd-tech.md` — 기술 스택 및 아키텍처

## Shadow 전용 체크리스트

- [ ] 4각 툴 각각의 역할(Skeleton/Constraint/Pivot)과 데이터 가중치 정의
- [ ] 3-Layer 병합 전략 (Base→Scope→Adjustment) 구체적 로직 기술
- [ ] Conflict Resolution 예시 시나리오 최소 2개 작성
- [ ] 각 툴의 인증 방식(OAuth 등) 및 데이터 접근 방식 목록화
- [ ] MVP 단계에서 연동할 툴 우선순위 결정

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 prd.md를 분석한 뒤 4각 툴 역할 정의, 가중치 설계, 3-Layer 로직, Conflict Resolution 전략을 여기에 작성]*

## 검토 게이트 (Human Gate)

- [ ] 4각 툴의 역할과 가중치가 PRD 섹션 1의 표와 일치하는가?
- [ ] 3-Layer 병합 로직이 실제 구현 가능한 수준으로 구체화되었는가?
- [ ] Conflict Resolution 예시가 PRD 섹션 4.1의 예시를 포함하는가?
- [ ] MVP 우선순위가 PRD 섹션 6의 Week 1~2 태스크와 정렬되는가?

## 다음 단계

승인 후 → STATUS.md의 1-1을 `HUMAN_APPROVED`로 업데이트 → `02-domain-model.md`로 이동
