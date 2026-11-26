---
name: decisions
description: waypoint 프로젝트에서 중요한 결정이 내려져 DECISIONS.md에 항목을 추가할 때 사용한다.
---

> 이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다. 없으면 그 레포의 `docs/dlc/FRAMEWORK.md`(duty는 `waypoint/FRAMEWORK.md`)를 따른다.

## 결정 로그 (Decision Log)

각 프로젝트는 `docs/waypoint/DECISIONS.md`(**append-only, ADR 스타일**)를 둔다.
항목은 메인 체크아웃의 `docs/waypoint/DECISIONS.md`에 추가한다. 순서는 `waypoint:git`의 「문서 커밋 흐름」을 따른다.

- **중요한 결정마다 AI가 한 항목**을 추가: `날짜 · 결정 · 근거 · 탈락한 대안 · 결정자`.
- **원시 대화 트랜스크립트는 적재하지 않는다**(시크릿·노이즈). 큐레이션된 "왜/대안"만.
- STATUS.md에서 링크한다. 스테이지 문서(*무엇을/결과*)·git 커밋과 상호보완하는 **감사 추적**이다.
- 템플릿: `${CLAUDE_PLUGIN_ROOT}/templates/decisions-template.md`.

### 중재자를 쓰는 동안

중재자 세션(`waypoint:mediator`)을 쓰는 동안에는 DECISIONS를 중재자만 쓴다. 게이트 답처럼 작업 세션이 근거와 탈락한 대안을 알고 있는 결정은, 작업 세션이 위 형식으로 항목 초안을 써서 중재자에게 보내고(`waypoint:worker`의 「결정 기록」), 중재자가 그대로 붙인다. 중재자가 스테이지 문서를 읽어 항목을 새로 쓰지 않는다.

> 템플릿 파일은 Read 도구로 읽어 Write 도구로 프로젝트에 복사한다. Bash 명령 안에서는 `${CLAUDE_PLUGIN_ROOT}`를 쓰지 않는다(환경변수로 노출되지 않는다).
