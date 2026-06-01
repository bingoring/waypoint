---
phase: 02-construction
stage: 02-nestjs-backend
status: PENDING
updated: 2026-06-02
---

# [Stage 2-2] NestJS Backend

## 목적

NestJS 애플리케이션의 모듈 구조, BullMQ 워커 설계, Prisma 스키마, 웹훅 핸들러를 설계한다.

## 입력 (Inputs)

- `../01-inception/03-architecture-decision.md` — 확정된 기술 스택
- `../01-inception/02-domain-model.md` — 엔티티 및 웹훅 이벤트 스키마

## Shadow 전용 체크리스트

- [ ] 모듈 구조 정의: AuthModule, WebhookModule, QueueModule, ContextModule, AgentModule
- [ ] Jira 웹훅 핸들러: `In Progress` 상태 변경 이벤트 처리 로직
- [ ] Slack 웹훅 핸들러: 특정 채널 메시지 필터링 및 파싱
- [ ] Notion/Confluence API 폴링 또는 웹훅 수신 전략
- [ ] BullMQ 큐 설계: 큐 이름, 워커 수, Retry 전략, Dead Letter Queue
- [ ] Prisma 스키마: 도메인 모델 기반 테이블 정의
- [ ] OAuth 토큰 저장 및 갱신 전략

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 NestJS 모듈 구조, 웹훅 핸들러 로직, BullMQ 설계, Prisma 스키마 초안을 작성]*

## 검토 게이트 (Human Gate)

- [ ] 4개 외부 툴의 웹훅/API 수신 전략이 모두 정의되었는가?
- [ ] BullMQ Retry 전략이 웹훅 폭주 시나리오를 커버하는가?
- [ ] Prisma 스키마가 도메인 모델과 1:1 대응되는가?
- [ ] OAuth 토큰 보안 저장 방식이 명시되었는가?

## 다음 단계

승인 후 → STATUS.md의 2-2를 `HUMAN_APPROVED`로 업데이트 → `03-langgraph-agent.md`로 이동
