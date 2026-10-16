---
phase: 02-construction
stage: 09-yawn-relay
status: AI_PROPOSED
updated: 2026-10-16
---

# [Stage 2-9] Yawn! (구 가칭 하품 릴레이)

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

- [x] Build Spec 작성 — [`yawn-relay/build-spec-index.md`](yawn-relay/build-spec-index.md) (comprehensive, `QUESTIONS_OPEN`)
- [x] Claude Design 요청서 초안 — [`yawn-relay/design-brief-2026-10-16.md`](yawn-relay/design-brief-2026-10-16.md)
- [x] 미해결 질문 해소 → Build Spec `READY` (2026-10-16)
- [x] Claude Design 핸드오프 수령 → `frontend-components` §7 매핑 (2026-10-16, `inputs/design-handoff-yawn-relay_v1/`)
- [ ] 구현 (Build Spec §4)
- [ ] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **규칙은 프로토타입을 1:1로 옮긴다.** 오너가 재미를 확인한 규칙이므로 판정은 바꾸지 않는다. 프로토타입 풀이기를 `solver.js`로 복원해 기록 표의 숫자 16개를 재현했고, Flutter 엔진은 이 숫자를 골든 테스트로 맞춘다.
2. **홈은 가상의 지하철 노선도다.** 역이 곧 레벨이고, 노선마다 새 승객 하나를 소개한다. 스크린숏 한 장으로 게임을 알리는 상징이자, 2-7의 「휑한 메뉴」 문제를 구조로 푼다.
3. **화면과 캐릭터는 Claude Design에 맡긴다.** 저장소를 못 읽는 디자이너도 바로 쓸 수 있는 요청서를 썼고, 돌려받는 형식은 forin 핸드오프와 같다.
4. **APP_DESIGN_PROMPT에 게임 라인 보충이 필요하다.** 시안 도구 금지와 반복 애니메이션 금지 조항이 오너가 정한 게임 흐름과 어긋난다(Build Spec Q3).
5. **2-7에서 만든 것을 재사용한다.** 광고 게이트, 효과음·진동, 저장 패턴, 레벨 도구 구조, 테스트, 5단계 검사, 템플릿 R8 규칙. 새로 만드는 것은 엔진·생성기·화면·캐릭터뿐이다.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec 미해결 질문에 답했는가? (`READY`)
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

`READY` → Claude Design 핸드오프 → 구현 → R-1 독립 리뷰 → 3-1 출시
