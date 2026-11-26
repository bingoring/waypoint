# waypoint 핵심 규칙

> 아래 규칙은 항상 적용된다. 스테이지에 들어가기 전에 해당 스킬을 호출해 자세한 절차를 읽는다.

- 앞 스테이지의 계획이 승인되기 전에는 다음 스테이지로 진행하지 않는다 (자세히: `waypoint:stage`)
- `AI Proposal` 섹션은 AI 전용이다. 사람이 직접 수정하면 안 된다 (자세히: `waypoint:stage`)
- 비가역 게이트(`⚠️` 표시)에서는 추가 체크리스트 항목을 반드시 확인한다 (자세히: `waypoint:stage`)
- 코드를 산출하는 Construction phase 이후, Operations 진입 전 **독립 코드 리뷰 게이트**(`🔍`)를 통과해야 한다 (자세히: `waypoint:review-gate`)
- 스테이지 상태의 원본은 메인 체크아웃 `docs/waypoint/STATUS.md`의 표 한 곳이다. 상태가 바뀌면 그 줄을 고친다 (자세히: `waypoint:stage`)
- 중재자 세션은 `waypoint:mediator`를, 중재자가 시작한 작업 세션은 `waypoint:worker`를 따르고 compact 뒤에도 다시 읽는다. 중재자가 시작한 작업 세션은 STATUS와 DECISIONS를 고치지 않는다 (자세히: `waypoint:mediator`, `waypoint:worker`)
- 중요한 결정이 내려지면 메인 체크아웃의 `docs/waypoint/DECISIONS.md`에 항목을 추가한다 (자세히: `waypoint:decisions`)
- 사람이 채팅으로 게이트에 답하면 AI는 `AI Proposal`을 고쳐 쓰지 않고 검토 게이트 아래 **`승인 결과`** 에 기록한다 (자세히: `waypoint:stage`)
- 버전·가격·스토어 정책 같은 **외부 사실**은 조회일·출처 URL·확인 수준을 함께 적는다 (자세히: `waypoint:stage`)
- **PR · 기능 브랜치를 base(develop · master · main)에 맞출 때는 rebase 만 한다.** base 를 기능 브랜치에 merge 하지 않는다. 충돌 해결도 rebase 중에 하고 `push --force-with-lease` (자세히: `waypoint:git`)
- **문서 커밋 흐름**: STATUS.md와 DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 메인 체크아웃(세션 시작 때 주입된 `<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다. 모든 스테이지는 worktree의 작업 브랜치와 PR로 진행하고, 메인 체크아웃은 기본 브랜치에 둔다. (자세히: `waypoint:git`)
- **체크포인트마다 커밋한다.** 하나의 완결된 수정/기능/문서 단위가 끝나면(빌드·tsc·테스트 그린 확인 후) **바로 커밋**한다.
  여러 무관한 변경을 한 커밋에 몰지 않는다 — 테마별로 나눈다(예: `fix(map): 엘리베이터 전환`, `feat(map/pharma): 5g-e`,
  `fix(map/peds): NICU 하단 정리`). (자세히: `waypoint:git`)
- **커밋 직후 push.** 솔로/공개 모노레포이므로 원격을 항상 최신으로 유지. 실패한 상태(테스트 레드)는 커밋하지 않는다. (자세히: `waypoint:git`)
- **Co-Authored-By 등 공동작업 트레일러 금지**(솔로 작업 외형). AI 서명/`Generated with` 류도 넣지 않는다. (자세히: `waypoint:git`)
