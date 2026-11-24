---
name: start
description: waypoint 프로젝트에서 세션을 시작하거나 다음 작업을 고를 때 사용한다. STATUS.md를 읽고 다음 스테이지를 찾는 절차.
---

> 이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다. 없으면 그 레포의 `docs/dlc/FRAMEWORK.md`(duty는 `waypoint/FRAMEWORK.md`)를 따른다.

## 세션 시작 프로토콜

AI가 새 세션을 시작할 때 반드시 아래 순서를 따른다:

1. 메인 체크아웃의 `docs/waypoint/STATUS.md`를 읽는다
2. `PENDING` 상태인 가장 앞 스테이지를 찾는다
3. 해당 스테이지 문서를 열고 `Inputs` 섹션에 명시된 파일을 모두 읽는다
4. `AI Proposal` 섹션을 작성하고 status를 `AI_PROPOSED`로 변경한다
5. 사람에게 리뷰를 요청하고 대기한다
