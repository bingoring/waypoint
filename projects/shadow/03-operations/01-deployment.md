---
phase: 03-operations
stage: 01-deployment
status: PENDING
updated: 2026-06-02
---

# [Stage 3-1] Deployment

## 목적

Shadow Engineer의 배포 구성(Docker Compose, 환경변수, Tauri 앱 빌드·배포 파이프라인)을 설계한다.

## 입력 (Inputs)

- `../02-construction/04-integration.md` — 전체 통합 아키텍처 (HUMAN_APPROVED 필요)
- `../../prd-tech.md` — 기술 스택

## Shadow 전용 체크리스트

- [ ] Docker Compose 서비스 정의: nestjs, postgres, redis, qdrant(또는 pgvector만 사용)
- [ ] 환경변수 목록: 각 외부 툴 OAuth 키, DB 연결 정보, LLM API 키
- [ ] Tauri 앱 빌드 파이프라인: macOS/Windows 바이너리 생성 전략
- [ ] 개발/스테이징/프로덕션 환경 분리 전략
- [ ] 시크릿 관리: .env 파일 vs 시크릿 매니저

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 Docker Compose 설정, 환경변수 목록, 배포 런북을 작성]*

## 검토 게이트 (Human Gate)

- [ ] Docker Compose가 모든 서비스를 포함하는가?
- [ ] 환경변수 목록에 누락된 키가 없는가?
- [ ] Tauri 앱 배포 방식이 실제로 실행 가능한가?

## 다음 단계

승인 후 → STATUS.md의 3-1을 `HUMAN_APPROVED`로 업데이트 → `02-monitoring.md`로 이동
