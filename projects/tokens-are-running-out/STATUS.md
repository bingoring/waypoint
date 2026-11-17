# tokens-are-running-out (내 토큰 어디 갔어?) — Waypoint Status

**Framework:** [Waypoint](https://github.com/bingoring/waypoint)  
**Repository:** [bingoring/tokens-are-running-out](https://github.com/bingoring/tokens-are-running-out)  
**Design input:** [inputs/design.md](inputs/design.md) (브레인스토밍 산출물, 2026-11-17)  
**Decisions (audit):** [DECISIONS.md](DECISIONS.md)  
**Last updated:** 2026-11-17

> 🔒 **공개 저장소:** 개발자 기기의 실제 Claude Code 기록, 세션 제목, 대화 내용은 커밋하지 않는다. 문서에는 집계 수치만 쓰고, 예시는 가상의 값으로 쓴다([DECISIONS](DECISIONS.md) 2026-11-17).

> 📝 **2-1 기록 리더와 색인 제안 (2026-11-17).** Build Spec READY, 승인 대기. 같은 호출이 여러 기록 파일에 복사되는 것을 발견해서, 전체 기록 단위로 한 번만 세도록 1-2 계약을 확장했다(기준값은 그대로). 터미널 세션 TTL 확인은 CLI 로그인이 만료되어 2-2 착수 전으로 옮겼다 — **사용자 작업: 터미널에서 `claude`를 실행해 다시 로그인**.

> ✅ **Inception 승인 (2026-11-17).** 1-1 ~ 1-3을 사용자가 승인했다. 다음: 2-1 제안 — 터미널(CLI) 세션의 캐시 TTL과 `--resume` 동작 확인, 기록 리더와 색인.

> 📝 **Inception 제안 (2026-11-17).** 브레인스토밍에서 정한 내용을 1-1 ~ 1-3으로 옮겼다. 세 스테이지 모두 승인 대기. 승인되면 Construction 첫 단계로 **터미널(CLI) 세션의 캐시 TTL과 `--resume` 동작 확인**을 한다(설계 13장의 주요 위험).

---

## Phase 1 — Inception (What)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 1-1 Context Synthesis | [01-context-synthesis.md](01-inception/01-context-synthesis.md) | HUMAN_APPROVED |
| 1-2 Domain Model | [02-domain-model.md](01-inception/02-domain-model.md) | HUMAN_APPROVED |
| 1-3 Architecture Decision ⚠️ | [03-architecture-decision.md](01-inception/03-architecture-decision.md) | HUMAN_APPROVED |

## Phase 2 — Construction (How)

> 1-3 승인 뒤 확정한다. 아래는 예정 분해다.

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 2-1 기록 리더와 색인 | [01-reader-and-index.md](02-construction/01-reader-and-index.md) · [Build Spec](02-construction/reader-index/build-spec-index.md) READY | AI_PROPOSED |
| 2-2 재구축 판정 · 원인 분류 · 집계 (기준값 대조). 착수 전: 터미널 세션 TTL 확인 | (예정) | PENDING |
| 2-3 메뉴 막대 앱 화면 · 만료 경고 · 알림 | (예정) | PENDING |
| 2-4 릴리스 파이프라인 (서명 · 공증 · Homebrew tap) | (예정) | PENDING |

## Phase R — Independent Code Review 🔍 (Construction → Operations 게이트)

> 작성자와 **컨텍스트가 분리된** 독립·적대적 리뷰어가 코드를 검토한다. FRAMEWORK "리뷰 게이트" 참조.

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| R-1 Independent Code Review | (예정) | PENDING |

## Phase 3 — Operations (Ship)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 3-1 첫 공개 (GitHub Releases · Homebrew tap) | (예정) | PENDING |
| 3-2 반응 확인 (수요 가설 검증) | (예정) | PENDING |

---

## AI 진입점

> AI는 위 테이블에서 `PENDING` 또는 승인 대기가 풀린 가장 앞 스테이지부터 작업을 시작하세요.
> 규칙: `FRAMEWORK.md` 참조
