---
phase: 02-construction
stage: 10-adaptive-difficulty
status: AI_PROPOSED
updated: 2026-10-16
---

# [Stage 2-10] 공통 적응형 난이도 (가칭 `factory_adaptive`)

## 목적

고정된 역(레벨) 대신, 플레이어의 실력과 상황에 맞춰 다음 판을 그때그때 만들어 내는 공통 모듈을 설계한다. 모든 하이퍼캐주얼 게임이 「판 생성기 + 난이도 측정기(풀이기)」만 꽂아 쓰게 한다. 첫 적용 대상은 2-9 하품 릴레이다.

## 입력 (Inputs)

- 오너 요구 (2026-10-16): 판 진행 시간, 실패 수, 시도 수, 몇 번 만에 성공했는지, 가만히 있던 시간, 출퇴근 시간대, 와이파이·LTE 등으로 다음 판의 구조·기믹을 유기적으로 배치. 반드시 클리어 가능. 첫 판을 빨리 깼다고 어려운 기믹을 바로 열지 않음. 하드코딩하지 않고 알고리즘으로. 모든 하이퍼캐주얼에 적용.
- [`yawn-relay/business-logic-model.md`](yawn-relay/business-logic-model.md) §3 — 풀이기 지표(이기는 조합, 니어미스)
- [`hypercasual/research-2026-10-15.md`](hypercasual/research-2026-10-15.md) §3 — 재미 설계 원칙

## 체크리스트

- [ ] 조사: 출시 게임의 적응형 난이도·절차적 레벨 사례, 학술 연구, 정책·개인정보 — [`adaptive/research-2026-10-16.md`](adaptive/research-2026-10-16.md)
- [ ] 설계 제안: 층 구조(커리큘럼·실력 모델·난이도 목표·상황 신호·생성/검증·원격 조정), 게임 인터페이스, 시뮬레이션 방법
- [ ] 오너 승인 → 하품 릴레이 Build Spec(2-9)에 반영

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

(조사 뒤 채운다.)

## 검토 게이트 (Human Gate)

- [ ] 설계 방향에 동의하는가?

## 다음 단계

승인 → `factory_adaptive` Build Spec → 2-9 하품 릴레이와 함께 구현
