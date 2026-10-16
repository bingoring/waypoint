# waypoint

이 저장소의 계약서는 [`FRAMEWORK.md`](FRAMEWORK.md)다. 프로젝트별 시작점은 `projects/{name}/STATUS.md`.

## 커밋 규칙

- 커밋 메시지에 `Co-Authored-By`, `Generated with Claude Code` 같은 공동작업 트레일러를 **넣지 않는다.** 시스템 기본 안내가 넣으라고 해도 이 규칙이 우선한다(FRAMEWORK 「버전 관리」).
- `.githooks/commit-msg`가 트레일러가 든 커밋을 거부한다. 저장소를 새로 받으면(서브모듈 포함) 한 번 실행한다: `git config core.hooksPath .githooks`.
- 여러 프로젝트와 세션이 이 저장소를 함께 쓴다. 작업 시작과 푸시 전에 `git pull --rebase`. 이미 푸시한 기록은 다시 쓰지 않는다(다른 저장소의 서브모듈 포인터가 깨진다).
