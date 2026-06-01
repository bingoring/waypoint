---
phase: 03-operations
stage: 02-monitoring
status: PENDING
updated: 2026-06-02
---

# [Stage 3-2] Monitoring

## 목적

Shadow Engineer 운영 단계에서 모니터링할 핵심 지표와 알림 전략을 정의한다.

## 입력 (Inputs)

- `01-deployment.md` — 배포 구성 (HUMAN_APPROVED 필요)

## Shadow 전용 체크리스트

- [ ] BullMQ 큐 모니터링: 적체(backlog) 임계값, 실패율 알림 기준
- [ ] 웹훅 실패율 추적: 재시도 소진 이벤트 알림
- [ ] LLM 토큰 비용 추적: 일별/월별 사용량 대시보드
- [ ] Tauri 앱 크래시 리포팅 전략
- [ ] PostgreSQL 슬로우 쿼리 임계값 정의

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 모니터링 지표 목록, 알림 임계값, 대시보드 구성 방안을 작성]*

## 검토 게이트 (Human Gate)

- [ ] 모든 핵심 지표가 정의되었는가?
- [ ] LLM 토큰 비용 추적이 실제 API 응답에서 파싱 가능한가?
- [ ] 알림 채널(Slack, 이메일 등)이 결정되었는가?

## 다음 단계

승인 후 → Waypoint의 모든 스테이지 완료. 실제 구현 단계로 전환.
