---
phase: 02-construction
stage: 03-langgraph-agent
status: PENDING
updated: 2026-06-02
---

# [Stage 2-3] LangGraph Agent

## 목적

LangGraph의 그래프 노드 구조, 상태 스키마, 각 노드의 프롬프트 전략을 설계한다.

## 입력 (Inputs)

- `../01-inception/03-architecture-decision.md` — LangGraph.js vs Python 결정
- `../01-inception/01-context-synthesis.md` — 3-Layer 병합 전략
- `../01-inception/02-domain-model.md` — ContextSnapshot, ArchitecturePlan 구조

## Shadow 전용 체크리스트

- [ ] 그래프 노드 정의: Fetch, Merge, ConflictDetect, Elicit, Resolve, Generate, Validate
- [ ] 그래프 상태(State) 스키마: 각 노드 간 전달되는 데이터 구조
- [ ] Fetch 노드: 4각 툴 데이터 수집 및 가중치 적용 로직
- [ ] Merge 노드: 3-Layer 병합 알고리즘 (Base→Scope→Adjustment)
- [ ] ConflictDetect 노드: 충돌 감지 기준 정의
- [ ] Elicit 노드: 사용자에게 질문을 던지는 조건 및 메시지 포맷
- [ ] Generate 노드: 최종 ArchitecturePlan 생성 프롬프트 전략
- [ ] RAG 전략: pgvector로 과거 컨텍스트 검색하는 시점과 쿼리 방식

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 LangGraph 노드 다이어그램, 상태 스키마, 각 노드 프롬프트 전략, RAG 쿼리 전략을 작성]*

## 검토 게이트 (Human Gate)

- [ ] 그래프 노드가 PRD 섹션 5의 유저 시나리오 전체 흐름을 커버하는가?
- [ ] Elicit 노드의 조건이 명확한가? (언제 사용자에게 질문하는가)
- [ ] Generate 노드의 산출물이 Tauri 클라이언트가 소비할 수 있는 형식인가?
- [ ] RAG 쿼리가 실제로 유의미한 과거 컨텍스트를 찾을 수 있는 구조인가?

## 다음 단계

승인 후 → STATUS.md의 2-3을 `HUMAN_APPROVED`로 업데이트 → `04-integration.md`로 이동
