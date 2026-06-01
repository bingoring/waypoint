---
phase: 02-construction
stage: 04-integration
status: PENDING
updated: 2026-06-02
---

# [Stage 2-4] Integration

## 목적

NestJS ↔ LangGraph 통신 프로토콜, Tauri ↔ Backend WebSocket 설계, 전체 E2E 시나리오를 검증한다.

## 입력 (Inputs)

- `01-tauri-client.md` — Tauri IPC 및 WebSocket 클라이언트 (HUMAN_APPROVED 필요)
- `02-nestjs-backend.md` — NestJS 모듈 및 큐 구조 (HUMAN_APPROVED 필요)
- `03-langgraph-agent.md` — LangGraph 그래프 및 상태 스키마 (HUMAN_APPROVED 필요)

## Shadow 전용 체크리스트

- [ ] NestJS → LangGraph 호출 방식: HTTP REST vs gRPC vs 직접 함수 호출(모노레포)
- [ ] LangGraph → NestJS 결과 반환 형식: ArchitecturePlan JSON 스키마 확정
- [ ] Tauri ↔ NestJS WebSocket 이벤트 목록: plan_ready, apply_requested, apply_done
- [ ] E2E 시나리오 1: Jira 티켓 In Progress → 팝업 표시까지 전체 흐름
- [ ] E2E 시나리오 2: Conflict 발생 → Elicit → 사용자 응답 → Generate 재실행
- [ ] 오류 처리: 각 레이어 장애 시 Tauri UI에 표시되는 에러 메시지 정의
- [ ] 모노레포 패키지 간 타입 공유 전략 (DTO 공유 패키지)

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 통신 프로토콜, WebSocket 이벤트 목록, E2E 시퀀스 다이어그램, 오류 처리 전략을 작성]*

## 검토 게이트 (Human Gate)

- [ ] E2E 시나리오가 PRD 섹션 5의 유저 시나리오와 정확히 일치하는가?
- [ ] 타입 공유 전략이 TypeScript 모노레포 환경에서 실제로 동작하는가?
- [ ] 오류 처리가 모든 레이어(Tauri/NestJS/LangGraph)를 커버하는가?
- [ ] WebSocket 이벤트 이름과 페이로드가 Tauri 클라이언트 설계와 일치하는가?

## 다음 단계

승인 후 → STATUS.md의 2-4를 `HUMAN_APPROVED`로 업데이트 → Phase 3 Operations 시작
