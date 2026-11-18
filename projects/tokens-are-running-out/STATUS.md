# tokens-are-running-out (내 토큰 어디 갔어?) — Waypoint Status

**Framework:** [Waypoint](https://github.com/bingoring/waypoint)  
**Repository:** [bingoring/tokens-are-running-out](https://github.com/bingoring/tokens-are-running-out)  
**Design input:** [inputs/design.md](inputs/design.md) (브레인스토밍 산출물, 2026-11-17)  
**Decisions (audit):** [DECISIONS.md](DECISIONS.md)  
**Last updated:** 2026-11-18

> 🔒 **공개 저장소:** 개발자 기기의 실제 Claude Code 기록, 세션 제목, 대화 내용은 커밋하지 않는다. 문서에는 집계 수치만 쓰고, 예시는 가상의 값으로 쓴다([DECISIONS](DECISIONS.md) 2026-11-17).

> 🏗️ **2-4 구현 → 비밀 값 등록 대기 (2026-11-18).** 아이콘, 유니버설 릴리스 빌드, 서명·공증 스크립트, 릴리스·tap 워크플로, cask, README를 구현했다. dry-run(ad-hoc + hardened runtime), `brew style`, 로컬 사본으로 tap push를 확인했다. macOS 27 Finder가 초타원 바탕의 아이콘을 회색 틀에 넣는 것을 렌더링으로 찾아 시스템 모양으로 바꿨다. 독립 리뷰의 지적 3건(토큰 전달, 산출물 폴더, 인자 확인)을 반영했다. Intel 실행은 Rosetta가 없어 Not verified. 다음: 사용자가 비밀 값을 등록하면 `v0.1.0-rc.1`로 끝까지 시험.

> ✅ **2-4 승인 (2026-11-18).** 구현 착수 — 브랜치 `feature/2-4-release-pipeline`. tap 저장소 생성과 사전 릴리스 `v0.1.0-rc.1` 공개도 승인됨.

> 📝 **2-4 릴리스 파이프라인 제안 (2026-11-18).** Build Spec READY, 승인 대기. Homebrew는 Gatekeeper 통과를 요구하고 cask에 quarantine을 붙이므로 서명·공증이 필수다(공식 문서). 유니버설 빌드와 hardened runtime 서명을 시험했다. 사용자 결정: zip, tap 자동 갱신, 아이콘 지금 제작, App Store Connect API 키. 인증서·API 키·토큰 생성과 비밀 값 등록은 사용자 작업.

> ✅ **2-3 머지 (2026-11-18).** 사용자가 기기 확인 체크리스트(VoiceOver, 키보드, 설정 창, 알림, 로그인 항목, 팝오버를 닫은 뒤 CPU)를 확인한 뒤 PR #3을 `main`에 머지(`7dfda7b`). Build Spec IMPLEMENTED. 다음: 2-4 릴리스 파이프라인(서명 · 공증 · Homebrew tap) 제안.

> 🏗️ **2-3 구현 완료 → 머지 대기 (2026-11-18, PR [#3](https://github.com/bingoring/tokens-are-running-out/pull/3)).** 메뉴 막대 앱(개발 빌드)이 동작한다: 곧 만료되는 세션 경고와 알림, 원인 분해(advisor 포함), 비용이 컸던 캐시 재구축과 근거, 설정 창, 영어·한국어. 테스트 170개, 기본값과 3만에서 세 기간 모두 프로토타입과 같음. 구현 후 화면 검토에서 HIGH 3건(넘침, 잘림, 밝은 모드 대비)을 고쳤고, 독립 리뷰의 MEDIUM 7건을 모두 반영했다. 메모리 최대 63MB. VoiceOver, 키보드, 알림 수신, 로그인 항목은 사용자 확인 대기.

> ✅ **2-3 승인 (2026-11-18).** 재구축 임계값 설정 제안도 함께 확정. 구현 착수 — 브랜치 `feature/2-3-menu-bar-app`.

> 📝 **2-3 메뉴 막대 앱 제안 (2026-11-18).** Build Spec READY(comprehensive), 승인 대기. 실행 세션 파일, 제목 출처, 앱 빌드 방식(SwiftPM + `xcodebuild`), 화면 렌더링 방식을 실제로 확인했다. advisor 비용은 별도 항목(8번째 버킷)으로 보여 준다(사용자 결정). 재구축 임계값도 설정할 수 있게 하는 것은 사용자 의견을 받은 AI 제안이고, 승인 게이트에서 확인한다(기본 5만). 형식 변화는 "호출이 되지 못한 assistant 줄의 비율"로 감지한다. 화면 시안은 better-interface 방식으로 구현 전에 검토해 HIGH 3건을 명세에 반영했다.

> ✅ **2-2 머지 (2026-11-18).** PR #2 CI 통과 후 `main`에 머지(`6635dcc`).

> 🏗️ **2-2 구현 완료 → 머지 대기 (2026-11-17, PR [#2](https://github.com/bingoring/tokens-are-running-out/pull/2)).** 테스트 110개, 세 기간과 합성 픽스처에서 프로토타입과 출력이 글자 단위로 같다. 7일 보고서 0.16초 이내. 실제 기록을 검증하다 비용 계산 결함을 찾아 고쳤다: advisor 단계의 비용이 빠져 있었고, 같은 메시지의 첫 줄 usage가 미완성인 경우가 있었으며, 호출 합계로는 가려지는 재구축이 있었다. 기준 기간 비용은 $616.33 → $807.63이고, 메뉴 막대 숫자는 23.9% → 18.2%다. advisor 비용을 따로 보여 줄지는 사용자 확인 대기([DECISIONS](DECISIONS.md)).

> ✅ **2-2 승인 (2026-11-17).** 구현 착수 — 브랜치 `feature/2-2-rebuild-analysis`.

> 📝 **2-2 재구축 분석 제안 (2026-11-17).** Build Spec READY, 승인 대기. 공식 가격표를 확인해 보니 캐시 읽기 단가가 모델마다 달라서(Opus 5.5는 0.05배, Fable은 0.025배), 모델별 가격표로 바꿨다(1-2 계약 정정). 기준 기간의 메뉴 막대 숫자는 17.0% → 23.9%, 줄일 수 있었던 양은 5.5% → 7.8%로 바뀐다.

> ✅ **2-1 머지 (2026-11-17).** PR #1 CI 통과 후 `main`에 머지(`2eed43c`).

> 🏗️ **2-1 구현 완료 → 머지 대기 (2026-11-17, PR [#1](https://github.com/bingoring/tokens-are-running-out/pull/1)).** 테스트 57개, 세 기간 기준값 일치, 1.7GB 첫 색인 10.5초·최대 메모리 61MB, 증분 반영 0.43초 이내. 독립 리뷰의 CRITICAL 1·HIGH 1·MEDIUM 6·LOW 5를 모두 채택해 회귀 테스트와 함께 수정.

> ✅ **2-1 승인 (2026-11-17).** 구현 착수 — 브랜치 `feature/2-1-reader-index`.

> 🔎 **터미널 세션 확인 (2026-11-17).** 터미널 대화형 세션도 메인 세션이 1시간 캐시를 쓰고, `claude -c`는 같은 파일에 이어서 기록한다. CLI 자동 업데이트 직후 캐시 일부를 다시 쓰는 것도 관찰했다. 분류 규칙은 그대로 둔다([DECISIONS](DECISIONS.md)).

> 📝 **2-1 기록 리더와 색인 제안 (2026-11-17).** Build Spec READY, 승인 대기. 같은 호출이 여러 기록 파일에 복사되는 것을 발견해서, 전체 기록 단위로 한 번만 세도록 1-2 계약을 확장했다(기준값은 그대로). 터미널 세션 TTL 확인은 CLI 로그인이 만료되어 뒤로 미뤘다가, 같은 날 사용자가 다시 로그인해서 확인했다.

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
| 2-1 기록 리더와 색인 | [01-reader-and-index.md](02-construction/01-reader-and-index.md) · [Build Spec](02-construction/reader-index/build-spec-index.md) IMPLEMENTED · PR [#1](https://github.com/bingoring/tokens-are-running-out/pull/1) 머지 `2eed43c` | HUMAN_APPROVED |
| 2-2 재구축 판정 · 원인 분류 · 비용 분해 | [02-rebuild-analysis.md](02-construction/02-rebuild-analysis.md) · [Build Spec](02-construction/rebuild-analysis/build-spec-index.md) IMPLEMENTED · PR [#2](https://github.com/bingoring/tokens-are-running-out/pull/2) 머지 `6635dcc` | HUMAN_APPROVED |
| 2-3 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림 | [03-menu-bar-app.md](02-construction/03-menu-bar-app.md) · [Build Spec](02-construction/menu-bar-app/build-spec-index.md) IMPLEMENTED · PR [#3](https://github.com/bingoring/tokens-are-running-out/pull/3) 머지 `7dfda7b` | HUMAN_APPROVED |
| 2-4 릴리스 파이프라인 (서명 · 공증 · Homebrew tap) | [04-release-pipeline.md](02-construction/04-release-pipeline.md) · [Build Spec](02-construction/release-pipeline/build-spec-index.md) READY | HUMAN_APPROVED (구현 완료, `v0.1.0-rc.1` 시험 대기) |

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
