---
phase: XX-phase-name
stage: XX-stage-name
status: PENDING
updated: YYYY-MM-DD
---

# [Stage X-Y] 스테이지 이름

## 목적

이 스테이지에서 AI가 달성해야 하는 목표와 최종 산출물을 한 문장으로 기술.

## 입력 (Inputs)

- 이전 스테이지 문서: `../XX-phase/XX-stage.md`
- 참조 문서: `../../prd.md`

## 체크리스트

- [ ] 항목 1
- [ ] 항목 2
- [ ] 항목 3

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[AI가 분석 결과와 설계안을 여기에 작성]*

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] AI 제안이 PRD 요구사항과 일치하는가?
- [ ] 다음 스테이지 진행에 필요한 결정이 모두 내려졌는가?
- [ ] 산출물이 명확하게 정의되었는가?

## 다음 단계

승인 후 → `STATUS.md`의 이 스테이지 상태를 `HUMAN_APPROVED`로 업데이트 → `XX-next-stage.md`로 이동
