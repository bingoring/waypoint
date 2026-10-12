# App Factory — Waypoint Status

**Framework:** [Waypoint](https://github.com/bingoring/waypoint)
**PRD:** [prd.md](prd.md) (AI 초안, 1-1 승인 시 확정)
**Decisions (audit):** [DECISIONS.md](DECISIONS.md)
**Last updated:** 2026-10-13

> 📝 **1-1 Context Synthesis 제안 → 승인 대기 (2026-10-13).** 수익 가설(게임 ARPDAU ≈ ₩46 → 월 1,000만 원에 DAU 약 7,200),
> 반복 콘텐츠 정책 대응 포트폴리오 규칙 P1~P6, 공통 모듈 12종, Wave 1 후보 5개(로또·연봉 계산기·소음 측정기·물 마시기·퍼즐). 미해결 질문 Q1~Q8.

---

## Phase 1 — Inception (What)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 1-1 Context Synthesis | [01-context-synthesis.md](01-inception/01-context-synthesis.md) | AI_PROPOSED |
| 1-2 Domain Model | [02-domain-model.md](01-inception/02-domain-model.md) | PENDING |
| 1-3 Architecture Decision ⚠️ | [03-architecture-decision.md](01-inception/03-architecture-decision.md) | PENDING |

## Phase 2 — Construction (How)

> 스테이지 목록은 1-3 승인 후 확정한다. 아래는 1-1 기준 예정안이다.

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 2-1 Core Packages (ads·consent·analytics·remote_config·iap·rating·app_shell) | (예정) | PENDING |
| 2-2 App Generator + Build Pipeline | (예정) | PENDING |
| 2-3 Wave 1 · 로또 번호 생성기 | (예정) | PENDING |
| 2-4 Wave 1 · 연봉 실수령액 계산기 | (예정) | PENDING |
| 2-5 Wave 1 · 소음 측정기 | (예정) | PENDING |
| 2-6 Wave 1 · 물 마시기 알림 | (예정) | PENDING |
| 2-7 Game Kit + Wave 1 퍼즐 | (예정) | PENDING |

## Phase R — Independent Code Review 🔍 (Construction → Operations 게이트)

> 작성자와 **컨텍스트가 분리된** 독립·적대적 리뷰어가 코드를 검토한다. FRAMEWORK "리뷰 게이트" 참조.

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| R-1 Independent Code Review | (예정) | PENDING |

## Phase 3 — Operations (Ship)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 3-1 Store Release ⚠️ (계정·서명·정책 체크리스트·스토어 등록) | (예정) | PENDING |
| 3-2 Portfolio Monitoring (30일 지표 → 확장·유지·중단 판단) | (예정) | PENDING |

---

## AI 진입점

> AI는 위 테이블에서 `PENDING` 상태인 가장 앞 스테이지부터 작업을 시작하세요.
> 규칙: [`FRAMEWORK.md`](../../FRAMEWORK.md) 참조
