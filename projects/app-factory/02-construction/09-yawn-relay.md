---
phase: 02-construction
stage: 09-yawn-relay
status: AI_PROPOSED
updated: 2026-10-16
---

# [Stage 2-9] 하품 릴레이 (가칭)

## 목적

2-8에서 재미 판정을 통과한 하품 릴레이를 출시 앱으로 만든다. 한 사람이 하품하면 그 사람을 보고 있던 사람이 따라 하품하고 잠든다. 툭 한두 번으로 지하철 한 칸을 전부 재우는 퍼즐이다.
이 스테이지는 오너가 정한 흐름(2026-10-16)을 따른다: ① 규칙·화면 흐름 문서(이 Build Spec 앞부분) → ② Claude Design이 화면·캐릭터를 디자인해 핸드오프 → ③ Flutter 구현.

## 입력 (Inputs)

- [`08-hypercasual-concept.md`](08-hypercasual-concept.md) §4 C1, §6 재미 검증 게이트
- [`hypercasual/yawn-relay-prototype-2026-10-16.md`](hypercasual/yawn-relay-prototype-2026-10-16.md) — 검증된 규칙, 레벨 8개 풀이 결과, 아트 요구사항
- 메인 저장소 `prototypes/yawn-relay/index.html` — **규칙 엔진의 진실 공급원**(`#engine` 스크립트)
- [`hypercasual/research-2026-10-15.md`](hypercasual/research-2026-10-15.md) — 재미 설계 원칙, 수익 구조
- [`../APP_DESIGN_PROMPT.md`](../APP_DESIGN_PROMPT.md) v1
- [`../DECISIONS.md`](../DECISIONS.md) — 2026-10-16 이모지 금지, 캐릭터 선제작, 5종 개발 순서

## 체크리스트

- [ ] Build Spec 작성 — [`yawn-relay/build-spec-index.md`](yawn-relay/build-spec-index.md) (comprehensive)
- [ ] Claude Design 요청서 — [`yawn-relay/design-brief-2026-10-16.md`](yawn-relay/design-brief-2026-10-16.md)
- [ ] 미해결 질문 해소 → Build Spec `READY`
- [ ] Claude Design 핸드오프 수령 → `frontend-components` 갱신
- [ ] 구현 (Build Spec §4)
- [ ] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

(Build Spec 작성 뒤 채운다.)

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec 미해결 질문에 답했는가? (`READY`)
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

`READY` → Claude Design 핸드오프 → 구현 → R-1 독립 리뷰 → 3-1 출시
