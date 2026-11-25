# Shadow Engineer — 결정 로그 (Decision Log / Audit)

> **append-only 감사 추적.** 중요한 결정 1건 = 항목 1개. *왜/대안/결정자*를 남겨, 최종 문서엔
> 증류되지 않는 "결정 provenance"를 보존한다. 스테이지 문서(*무엇을/결과*)·git 커밋과 상호보완.
> 원시 대화 트랜스크립트는 적재하지 않는다(노이즈·시크릿 위험). AI가 결정 시점마다 한 항목씩 추가한다.

형식: `날짜 · 제목` → 결정 / 근거 / 대안(탈락) / 결정자.

---

## 2026-07-10 · waypoint 프로젝트 문서 위치 = submodule 내부
- **결정:** shadow의 waypoint 스테이지 문서를 `docs/dlc/projects/shadow/`(bingoring/waypoint submodule) 안에 둔다.
- **근거:** forin 예시와 동일한 프레임워크 규칙(`projects/{name}/`)을 그대로 따름. 커밋은 waypoint 레포로 감.
- **대안(탈락):** shadow 레포 내 `docs/waypoint/projects/shadow/`(프레임워크는 읽기전용 참조) — 관심사 분리는 깔끔하나 규칙 이탈.
- **결정자:** 사용자.

## 2026-07-10 · Context Synthesis — 3-Layer 병합 = 가중치 × 최신성, 비가역 override는 Elicitation
- **결정:** 가중치(Skeleton Low / Constraint Medium / Pivot High)를 정적 우선순위가 아닌 "충돌 시 기본 신뢰도"로 두고,
  충돌 판정은 `weight × recency_factor`로 결정. 단 명세(Confluence)를 뒤집는 광범위/비가역 영향 결정은 자동 확정하지 않고 사용자에게 Elicitation.
- **근거:** PRD §1 가중치 표 + §4.1 충돌 예시를 실행 가능한 로직으로 구체화. 자동화의 편의와 비가역 결정의 안전성을 분리.
- **대안(탈락):** 순수 정적 우선순위(Slack > Jira > Notion/Confluence) — 오래된 Slack 잡담이 최신 명세를 뒤집는 오판 위험.
- **결정자:** AI(권고) — 사람 승인 대기(1-1 게이트).

## 2026-07-10 · MVP 툴 우선순위 = Jira+Confluence(P0) → Notion(P1) → Slack(P2)
- **결정:** 파이프라인 방아쇠인 Jira와 동일 Atlassian OAuth로 확보되는 Confluence를 P0, Notion P1, Slack P2로 착수.
- **근거:** PRD §6 Week1~2("Atlassian OAuth"+"Jira 웹훅")와 정렬. 단일 OAuth 앱으로 인증 구현 부담 최소.
- **대안(탈락):** Slack 우선(가중치 최상위) — Events API/스레드 파싱 복잡도가 높아 MVP 방아쇠 확보를 지연시킴.
- **미해결 긴장:** Slack이 가중치 최상위인데 도입이 최후행 → P0~P1 기간 Pivot 부재. 순서 조정 여부는 사람 판단 대기.
- **결정자:** AI(권고) — 사람 승인 대기(1-1 게이트).
