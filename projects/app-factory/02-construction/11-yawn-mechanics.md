---
phase: 02-construction
stage: 11-yawn-mechanics
status: AI_PROPOSED
updated: 2026-10-17
---

# [Stage 2-11] Yawn! 기믹 확장 — 노선 7~20

## 목적

출시에 넣기로 한 기믹 14종(출시 확정 6종 + 새 8종)을 Flutter 앱에 연결해 노선을 20개로 늘린다. 엔진·풀이기·생성기·역 데이터·커리큘럼·캐릭터 렌더러 v2·화면 효과를 함께 바꾼다.

## 입력 (Inputs)

- 규칙 SoT: 프로토타입 `prototypes/yawn-relay/index.html` `#engine`(역 1~36, solver.js 검증) — [`hypercasual/yawn-relay-prototype-2026-10-16.md`](hypercasual/yawn-relay-prototype-2026-10-16.md) §4·§5
- 그림 SoT: 핸드오프 v2 (`design_handoff_yawn_relay_v2/`) — 확인 [`yawn-relay/handoff-v2-review-2026-10-17.md`](yawn-relay/handoff-v2-review-2026-10-17.md), 정정본 v2.1 반영 확인([`yawn-relay/design-correction-v2-2026-10-17.md`](yawn-relay/design-correction-v2-2026-10-17.md))
- 기존 구현: 2-9 Build Spec [`yawn-relay/`](yawn-relay/build-spec-index.md), 2-10 `factory_adaptive`
- [`../DECISIONS.md`](../DECISIONS.md) 2026-10-17 — 후보 6종·새 8종 포함, 노선 20색, 판 5×8, 크기 단계, 풀이기 최적화

## 체크리스트

- [x] Build Spec 초안 — [`yawn-mechanics/build-spec-index.md`](yawn-mechanics/build-spec-index.md) (comprehensive, `QUESTIONS_OPEN`)
- [x] 미해결 질문 해소 → `READY` (2026-10-17, 오너 승인 「승인할게, 구현 시작해줘」)
- [x] 구현 (Build Spec §4) — U1~U5 `0510003`, U6 렌더러 v2.1, U7·U8 `03f17c2`, 화면 흐름 `7ed9199`, 고난이도 성능 `1d9a0fe`
- [x] 검증 (Build Spec §5) → `IMPLEMENTED` (2026-10-17, 고난이도 스트레스 시험 포함 — Build Spec §5·§6·§7)

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **규칙은 프로토타입 그대로, 그림이 규칙을 따른다.** 새 8종 엔진은 프로토타입 `step`을 1:1로 옮기고, 역 21~36의 solver.js 수치를 골든으로 맞춘다. 출입문·기둥은 디자이너 정정본 v2.1이 규칙과 맞아 그대로 구현한다.
2. **서서 가는 승객이 구조를 바꾼다.** 승객 위치가 바뀌므로 판 격자를 상태로 옮기고, 풀이기의 시선 캐시는 그런 판에서 끈다. 기존 역 1~20 결과가 바뀌지 않는 것을 대조 테스트로 증명한다(프로토타입에서 한 것과 같은 방식).
3. **한 판에 기믹을 너무 많이 섞지 않는다.** 노선 20에서는 지금 생성기가 판마다 기믹을 평균 5개쯤 섞는다 — 읽을 수 없다. 노선 기믹 + 이전 기믹 최대 2개로 묶는다.
4. **렌더러 v2를 Dart로 옮긴다.** SVG는 메타데이터·CSS 변형 때문에 직접 쓰지 않고 골든 기준으로만 쓴다(v1과 같음).

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] Build Spec이 `READY`로 승인되었는가? (2026-10-17)
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가? (AI: 통과 — 오너 확인 대기. 편차 11건은 Build Spec §7)

## 다음 단계

`READY` → 구현 → R-1 독립 리뷰(2-9와 함께) → 3-1 출시
