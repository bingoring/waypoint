---
phase: 01-inception
stage: 02-domain-model
status: PENDING
updated: 2026-06-02
---

# [Stage 1-2] Domain Model

## 목적

Shadow Engineer의 핵심 엔티티, 데이터 흐름, DTO 초안을 정의한다. 이 문서가 NestJS Prisma 스키마와 LangGraph 상태 스키마의 기반이 된다.

## 입력 (Inputs)

- `01-context-synthesis.md` — 4각 툴 역할 및 3-Layer 전략 (HUMAN_APPROVED 필요)
- `../../prd.md` — 섹션 4.1, 4.2, 5
- `../../prd-tech.md` — 섹션 2, 3

## Shadow 전용 체크리스트

- [ ] 핵심 엔티티 정의: User, Integration, Ticket, ContextSnapshot, ArchitecturePlan
- [ ] 엔티티 간 관계(ERD 텍스트 형식) 작성
- [ ] 3-Layer 병합 결과물인 ContextSnapshot의 필드 구조 정의
- [ ] ArchitecturePlan 엔티티 (AI가 생성하는 설계도) 구조 정의
- [ ] 웹훅 이벤트 스키마: Jira StatusChange, Slack Message, Notion Page 각각 정의
- [ ] Conflict 발생 시 사용자에게 전달하는 Elicitation 메시지 구조 정의

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 엔티티 정의, ERD, DTO/스키마 초안, 웹훅 이벤트 구조를 여기에 작성]*

## 검토 게이트 (Human Gate)

- [ ] 모든 핵심 엔티티가 정의되었는가?
- [ ] ContextSnapshot 구조가 3-Layer 전략을 수용할 수 있는가?
- [ ] 웹훅 이벤트 스키마가 실제 API 문서와 대조 가능한 수준인가?
- [ ] Prisma 스키마로 바로 변환 가능한 수준으로 구체적인가?

## 다음 단계

승인 후 → STATUS.md의 1-2를 `HUMAN_APPROVED`로 업데이트 → `03-architecture-decision.md`로 이동
