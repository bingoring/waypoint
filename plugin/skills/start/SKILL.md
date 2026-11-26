---
name: start
description: waypoint 프로젝트에서 세션을 시작하거나 다음 작업을 고를 때 사용한다. 세션 시작 요약을 확인하고 이어 갈 카드를 고르는 절차.
---

> 이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다. 없으면 그 레포의 `docs/dlc/FRAMEWORK.md`(duty는 `waypoint/FRAMEWORK.md`)를 따른다.

## 세션 시작 프로토콜

지시문에 「중재자가 시작한 작업 세션」이라고 적힌 세션은 이 절차 대신 `waypoint:worker`의 「첫 턴」을 따른다.

AI가 새 세션을 시작할 때 반드시 아래 순서를 따른다:

1. 세션 시작 때 주입된 `<waypoint>` 블록의 요약(「현황(<레포>)」 줄, 활성 줄, 오너 할 일)을 확인한다. STATUS 전체가 필요할 때만 메인 체크아웃의 `docs/waypoint/STATUS.md`를 읽는다. 요약 앞에 경고가 있으면 먼저 오너에게 알린다.
2. 활성 줄 가운데 링크 칸에 PR이 있는 줄은 `gh pr view`로 PR 상태(`state`)를 확인한다. 머지된 PR이 그 스테이지의 마지막 PR이면 오너에게 알리고 그 줄을 `MERGED`로 정리한다(`waypoint:git`의 「스테이지 브랜치와 PR」 6번). 중간 PR이면 STATUS를 바꾸지 않는다. 그 PR의 기록은 머지 전에 PR 안의 「진행 기록」에 써 두었다.
3. 오너가 지정한 카드가 있으면 그 카드를 이어서 진행한다.
4. 새 스테이지를 시작할 때는 오너가 정한 스테이지를 고른다. 오너가 정하지 않았다면 `PENDING` 가운데 ID가 가장 앞선 스테이지를 제안하고 오너의 확인을 받는다. 앞 스테이지의 계획이 승인되었는지 확인한다(`waypoint:stage`의 「다음 스테이지로 넘어가는 조건」).
5. `AI_PROPOSED` 카드는 오너가 답하기 전에는 건드리지 않는다.
6. 스테이지를 이어 가거나 시작할 때는 해당 스테이지 문서를 열고 `Inputs` 섹션에 명시된 파일을 모두 읽는다.

스테이지 문서(`AI Proposal` 포함)를 쓰기 전에 `waypoint:stage`를 호출한다. 로직·화면·알고리즘·콘텐츠를 산출하는 스테이지면 `waypoint:build-spec`을, Construction에서 Operations로 넘어가는 리뷰 게이트면 `waypoint:review-gate`를 먼저 호출한다. 결정이 내려지면 `waypoint:decisions`를, 커밋할 때는 `waypoint:git`을 따른다.

**중재자:** 데스크톱 앱에서는 `/waypoint:mediator`로 레포의 중재자 세션을 둘 수 있다. 중재자가 있으면 위 2번(머지 정리)은 중재자가 맡는다(`waypoint:mediator`).
