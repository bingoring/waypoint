---
phase: 02-construction
stage: 01-tauri-client
status: PENDING
updated: 2026-06-02
---

# [Stage 2-1] Tauri Client

## 목적

Tauri v2 로컬 앱의 컴포넌트 구조, IPC 인터페이스, AST 파싱 플로우, VS Code API 연동 방식을 설계한다.

## 입력 (Inputs)

- `../01-inception/03-architecture-decision.md` — 확정된 기술 스택 (HUMAN_APPROVED 필요)
- `../01-inception/02-domain-model.md` — ArchitecturePlan 엔티티 구조

## Shadow 전용 체크리스트

- [ ] Tauri v2 커맨드(IPC) 목록 정의: 백엔드 호출, 파일 주입, Git 브랜치 생성
- [ ] React 컴포넌트 트리 설계: 팝업 UI, ArchPlan 뷰어, Apply 버튼 플로우
- [ ] Tree-sitter(또는 ts-morph) AST 스캔 로직: NestJS 패턴(@Module, @Injectable) 인식
- [ ] 파일 주입 로직: `src/domains/{domain_name}` 하위 파일셋 생성 규칙
- [ ] 의존성 자동 업데이트: 상위 모듈 imports 배열 자동 수정 로직
- [ ] 로컬 백엔드 WebSocket 연결 관리

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 Tauri IPC 커맨드 목록, React 컴포넌트 구조, AST 파싱 플로우, 파일 주입 알고리즘을 설계]*

## 검토 게이트 (Human Gate)

- [ ] IPC 커맨드가 PRD 섹션 4.2의 로컬 에이전트 역할을 모두 커버하는가?
- [ ] AST 파싱이 실제 NestJS 프로젝트 패턴을 정확히 인식하는가?
- [ ] 파일 주입 후 의존성 자동 업데이트 로직이 안전한가? (기존 코드 파괴 없음)
- [ ] 20~30MB 메모리 제약이 설계에 반영되었는가?

## 다음 단계

승인 후 → STATUS.md의 2-1을 `HUMAN_APPROVED`로 업데이트 → `02-nestjs-backend.md`로 이동
