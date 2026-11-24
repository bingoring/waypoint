---
name: git
description: waypoint 프로젝트에서 커밋·push할 때, PR 브랜치를 base에 맞출 때, STATUS·DECISIONS 같은 문서를 커밋할 때 사용한다. 브랜치 규칙과 커밋 규칙.
---

> 이 스킬은 `docs/waypoint/STATUS.md`가 있는 레포에서만 적용한다. 없으면 그 레포의 `docs/dlc/FRAMEWORK.md`(duty는 `waypoint/FRAMEWORK.md`)를 따른다.

## 브랜치 규칙

- **PR 브랜치 최신화 = rebase.** `git rebase origin/<base>` → 충돌 해결 → `git log --merges origin/<base>..HEAD` 가 비어 있는지 확인 → `git push --force-with-lease`.
- **금지:** base 를 기능 브랜치에 merge 하는 모든 경로 — `git merge origin/<base>`, `--rebase` 없는 `git pull`, merge 모드의 `gh pr update-branch` · GitHub "Update branch". 그 merge 커밋은 PR 머지와 함께 base 이력(그리고 base 에서 내려가는 staging · release 브랜치)에 그대로 남아, base 가 자기 자신을 merge 한 기록이 생긴다.
- 서브모듈을 쓰는 레포에서: **서브모듈 포인터 충돌:** 어느 한쪽 해시를 고르지 않는다. 양쪽을 모두 담은 서브모듈 커밋(서브모듈 PR 이 머지됐으면 서브모듈 base 의 머지 커밋, 아니면 서브모듈 기능 브랜치를 먼저 rebase 한 tip)으로 맞춘다.
- **예외(merge 가 맞는 곳):** 기능 브랜치를 공용 통합 브랜치(`dev` 등)에 넣을 때, 그리고 PR 의 최종 머지.
- 구현 체크리스트와 PR 직전 점검에 "PR 브랜치에 base merge 커밋 없음" 을 넣는다(Build Spec 템플릿 §5).

## 버전 관리 (Commit & Push 주기)

- **체크포인트마다 커밋한다.** 하나의 완결된 수정/기능/문서 단위가 끝나면(빌드·tsc·테스트 그린 확인 후) **바로 커밋**한다.
  여러 무관한 변경을 한 커밋에 몰지 않는다 — 테마별로 나눈다(예: `fix(map): 엘리베이터 전환`, `feat(map/pharma): 5g-e`,
  `fix(map/peds): NICU 하단 정리`).
- **커밋 직후 push.** 솔로/공개 모노레포이므로 원격을 항상 최신으로 유지. 실패한 상태(테스트 레드)는 커밋하지 않는다.
- **메시지 = conventional-commit** 한 줄(`fix(scope): …` / `feat(scope): …` / `docs(scope): …`), 지금까지의 로그 스타일 유지.
  본문은 필요할 때만 간결히.
- **Co-Authored-By 등 공동작업 트레일러 금지**(솔로 작업 외형). AI 서명/`Generated with` 류도 넣지 않는다.
- **문서 커밋 흐름**: STATUS.md와 DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 메인 체크아웃(세션 시작 때 주입된 `<waypoint>` 블록에 적힌 경로)에서 기본 브랜치로 바로 커밋하고 push한다. 스테이지 문서·Build Spec·리뷰 문서는 작업 브랜치에 실어 PR과 함께 머지한다.
- Build Spec은 코드와 같은 체크포인트에서 함께 커밋한다.

### 문서 커밋 흐름(STATUS·DECISIONS·핸드오프)

STATUS.md, DECISIONS.md, 핸드오프(`docs/waypoint/inputs/`)는 여러 작업이 함께 보는 공유 문서다. 기능 브랜치나 worktree에서 일하더라도 아래 순서로 메인 체크아웃의 기본 브랜치에 바로 반영한다. `<메인>`은 세션 시작 때 주입된 `<waypoint>` 블록의 「메인 체크아웃」 경로다.

0. `git -C <메인> branch --show-current`가 기본 브랜치(main 또는 master)이고 `git -C <메인> status --porcelain`의 출력이 비어 있는지 확인한다. 둘 중 하나라도 아니면 고치지 말고 멈춰서 오너에게 알린다.
1. `git -C <메인> pull --rebase`로 최신화한다.
2. `<메인>/docs/waypoint/` 아래의 파일을 고친다. 작업 브랜치에 있는 사본은 고치지 않는다.
3. 고친 파일만 `git -C <메인> add`하고 커밋한 뒤 `git -C <메인> push`한다. push가 거절되면 `git -C <메인> pull --rebase`를 한 뒤 다시 push한다. `--rebase` 없는 pull은 쓰지 않는다.

이 파일들은 읽을 때도 메인 체크아웃의 것을 읽는다. 작업 브랜치에 있는 사본은 브랜치를 만든 시점의 상태라서 낡았을 수 있다.
