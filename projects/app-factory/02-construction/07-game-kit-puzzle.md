---
phase: 02-construction
stage: 07-game-kit-puzzle
status: AI_PROPOSED
updated: 2026-10-15
---

# [Stage 2-7] Game Kit + 조각보 블록 퍼즐

## 목적

Wave 1의 게임(A) 앱이자 게임 키트의 첫 소비자. 8×8 판에 조각보 천 조각을 놓아 줄을 지우는 블록 퍼즐을 만들고, 보상형 광고(이어하기·조각 다시 받기) 매출 가설을 검증한다.

## 입력 (Inputs)

- [`../01-inception/01-context-synthesis.md`](../01-inception/01-context-synthesis.md) §3 수익 추정, §7 퍼즐·게임 키트
- [`../01-inception/02-domain-model.md`](../01-inception/02-domain-model.md) §4 보상형·광고 제거, §10 퍼즐 행
- [`../01-inception/03-architecture-decision.md`](../01-inception/03-architecture-decision.md) A6 순수 Flutter, §7 게임 예산
- [`../DECISIONS.md`](../DECISIONS.md) — 2026-10-15 보류·장르·범위·효과음·레벨·이어하기·오늘의 판

## 체크리스트

- [x] 장르 조사·결정 — [`puzzle/research-genre-2026-10-15.md`](puzzle/research-genre-2026-10-15.md)
- [x] 기능 범위 질문 (2026-10-15)
- [x] Build Spec 작성 — [`puzzle/build-spec-index.md`](puzzle/build-spec-index.md) (comprehensive)
- [ ] Build Spec `READY` 승인
- [ ] 구현 (Build Spec §4)
- [ ] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **공정한 배분이 판매 포인트.** 세 조각을 줄 때 지금 판에 놓일 조각을 하나 이상 보장하고(경쟁작 1점 리뷰의 대표 불만), 속성 테스트 1,000판으로 증명한다. 스토어 설명에도 적는다.
2. **게임 키트는 이 게임이 쓰는 것만.** 결정적 난수(버전 무관)·최고점·저장·보상형 게이트(광고 제거 구매자는 광고 없이)·결과 → 다음 판 전환 광고·피드백·공유. 화면은 앱이 소유한다.
3. **레벨 100은 오프라인 도구가 만든다.** 규칙 생성 + 자동 플레이 봇으로 모두 클리어 가능한 것만 넣고, 봇이 못 깨면 곡선을 고친다. 런타임에는 생성·검사가 없다.
4. **광고는 쉼에서만.** 게임판에는 배너가 없고, 전면은 결과에서 「다시 하기」를 누를 때 두 번에 한 번, 보상은 버튼에 적는다. 오늘의 판은 보조 없이 공정하게 비교한다.
5. **조각보라는 정체성.** 경쟁작(나무·보석·네온)과 다른 천 조각·바늘땀·조각보 지도. 색은 장식이고 규칙은 모양으로만 읽힌다(색약 대응). 캐릭터는 두지 않는다(대상 연령).

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec이 `READY`로 승인되었는가?
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

승인 후 → R-1 독립 리뷰 → 3-1 출시
