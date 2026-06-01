---
phase: 01-inception
stage: 03-architecture-decision
status: PENDING
updated: 2026-06-02
---

# [Stage 1-3] Architecture Decision ⚠️ 비가역 게이트

## 목적

Shadow Engineer의 기술 스택을 최종 확정한다. 이 결정은 이후 모든 Construction 스테이지의 기반이 되며, 번복 시 전면 재설계가 필요하다.

## 입력 (Inputs)

- `02-domain-model.md` — 엔티티 및 데이터 흐름 (HUMAN_APPROVED 필요)
- `../../prd-tech.md` — 전체 기술 스택 권장안

## Shadow 전용 체크리스트

- [ ] 로컬 클라이언트: Tauri v2 확정 (Electron 대비 메모리 이점 수치 제시)
- [ ] AI 에이전트 언어: LangGraph.js(TypeScript 통일) vs LangGraph(Python 분리) 결정
- [ ] 벡터 DB: pgvector(PostgreSQL 플러그인) vs Qdrant 독립 서버 결정
- [ ] 모노레포 구조 확정: Nx 사용 여부, 패키지 분리 전략
- [ ] AST 파싱: Tree-sitter(Rust) vs ts-morph(TypeScript) 결정
- [ ] 각 결정의 대안 탈락 이유 문서화

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 각 기술 결정에 대해 대안 비교, 권장 결정, 탈락 이유를 ADR 형식으로 작성]*

## 검토 게이트 (Human Gate)

### 기본 게이트
- [ ] AI 제안이 prd-tech.md의 권장 스택과 일치하거나 탈락 이유가 명확한가?
- [ ] 모든 기술 결정이 내려졌는가?

### 비가역성 확인 ⚠️
- [ ] 이 결정을 번복할 경우 영향받는 파일/레이어 목록을 작성했는가?
- [ ] 대안 기술 스택을 검토하고 탈락 이유를 문서화했는가?
- [ ] 외부 API 의존성(Atlassian, Notion, Slack) 및 비용 구조를 확인했는가?
- [ ] LangGraph.js vs Python 선택으로 인한 장기 lock-in을 수용할 수 있는가?

## 다음 단계

승인 후 → STATUS.md의 1-3을 `HUMAN_APPROVED`로 업데이트 → Phase 2 Construction 시작
