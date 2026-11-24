# tokens-are-running-out (내 토큰 어디 갔어?) — Waypoint Status

**Framework:** [Waypoint](https://github.com/bingoring/waypoint)  
**Repository:** [bingoring/tokens-are-running-out](https://github.com/bingoring/tokens-are-running-out)  
**Design input:** [inputs/design.md](inputs/design.md) (브레인스토밍 산출물, 2026-11-17)  
**Decisions (audit):** [DECISIONS.md](DECISIONS.md)  
**Last updated:** 2026-11-24

> 🔒 **공개 저장소:** 개발자 기기의 실제 Claude Code 기록, 세션 제목, 대화 내용은 커밋하지 않는다. 문서에는 집계 수치만 쓰고, 예시는 가상의 값으로 쓴다([DECISIONS](DECISIONS.md) 2026-11-17).

> ✅ **2-5 기기 확인 완료 (2026-11-24).** `v0.2.1`에서 팝오버 내용이 다시 보이고, 큰 세션 영역, 복사와 "복사됨", VoiceOver, 키보드 이동이 정상인 것을 사용자가 확인했다. Build Spec IMPLEMENTED. 데스크톱 앱에서의 붙여 넣기와 compact 뒤 목록 제외는 기기에서 확인하지 않았다. 다음: 3-1 소개 글 게시(사용자) → 3-2 제안.

> 🚀 **`v0.2.1` 공개 (2026-11-24).** 팝오버 회귀를 고친 `v0.2.1`을 공개했다. 릴리스 잡과 tap 갱신이 성공했고, 공개 자산의 서명·공증·Gatekeeper와 바이너리 검사가 통과했다. 이 기기는 `brew upgrade`로 0.2.1이 되었다. 남은 것: 사용자의 팝오버 확인 → 2-5 기기 확인 → Build Spec IMPLEMENTED → 3-1 소개 글 게시(사용자) → 3-2 제안.

> 🚑 **`v0.2.0` 공개와 회귀 → `v0.2.1` (2026-11-23).** `v0.2.0`을 공개했지만, 팝오버 내용이 사라지고 버튼만 보이는 회귀가 있었다. 높이 제한을 위해 넣은 스크롤 영역이 메뉴 막대 창의 작은 높이 제안을 그대로 받았다. 재현 테스트와 함께 고쳐 `v0.2.1`로 내보낸다.

> 🏗️ **2-5 붙여 넣기 확인 → 머지 대기 (2026-11-23).** 사용자와 함께 시험 세션에 붙여 넣어 봤다. 여러 줄 프롬프트와 1,070자 영어는 일반 메시지로 처리되었고, 한 줄 한국어(527자)와 줄인 영어(582자)는 `/compact`로 실행되었다. 프롬프트를 한 줄로 바꾸고 600자 제한 테스트를 더했다(PR #10). 남은 것: 머지 → `v0.2.0` → 기기 확인.

> 🏗️ **2-5 구현 완료 → 붙여 넣기 확인과 PR 대기 (2026-11-23).** 큰 세션 영역, 만료 경고의 정리 안내, compact 뒤 세션 제외, 시험한 프롬프트(한·영)를 구현했다. 테스트 238개, 엄격 빌드, 린트, 반목표·문구·바이너리 검사가 통과했다. 화면 검토에서 대비 문제 1건을, 브랜치 리뷰에서 팝오버 높이 제한 누락을 찾아 고쳤다. 남은 것: 사용자의 대화형 붙여 넣기 확인(머지 전 필수) → PR → `v0.2.0` → 기기 확인.

> ✅ **2-5 승인 (2026-11-23).** 사용자가 권장안대로 승인했다. 두 위치, 20만 토큰 고정, 시험한 A2와 영어 번역, compact 뒤 세션 제외(2-3 계약 확장), 독립 리뷰 뒤 `v0.2.0`. 3-1 소개 글 게시는 `v0.2.0` 공개 뒤로 미룬다. 다음: 구현 계획 → 대화형 붙여 넣기 확인 → 구현.

> 📝 **2-5 큰 세션 정리 안내 제안 (2026-11-23).** 실제 기록으로 분석을 다시 확인했다. 분석은 정확했지만, 캐시 만료는 비용의 8분의 1이고 가장 큰 "일반 작업"의 68%가 큰 컨텍스트를 호출마다 다시 읽는 비용이었다. 사용자와 정한 방향은 두 가지다. 큰 세션에 붙여 넣을 `/compact` 프롬프트를 복사해 주고, 떠나기 전 정리를 안내한다. 프롬프트는 세션 복제본으로 시험해 블라인드 평가 1위였던 A2를 쓴다. Build Spec READY, AI_PROPOSED, 승인 대기. 3-1 소개 글 게시는 이 게이트에서 시점을 정한다.

> 🚀 **`v0.1.1` 공개 (2026-11-20).** 첫 실행에서 "로그인할 때 열기"를 켤 수 없는 결함을 찾았다. 처음 설치하면 상태가 `.notFound`로 나오는데, 앱이 이를 "사용 불가"로 다룬 것이 원인이었다. 회귀 테스트와 함께 고쳐 `v0.1.1`로 내보냈다. 릴리스 잡 안의 tap 단계가 처음으로 성공해, 정식 릴리스 경로가 끝까지 통과했다. `brew upgrade`로 받은 앱에서 켜기가 동작했다(상태 1). 남은 것: 사용자의 소개 글 게시 → 3-2 제안.

> 🚀 **`v0.1.0` 공개 (2026-11-20).** 정식 릴리스가 서명·공증되어 올라갔다. tap 단계는 토큰 권한 부족(403)으로 실패했다. 사용자가 권한을 고친 뒤 "Update Homebrew tap"으로 복구했고, `brew install --cask bingoring/tap/tokens-are-running-out`으로 설치되는 것을 확인했다. `--zap`도 확인했다. 릴리스 노트에 소개를 붙였고, 기준선은 별 0, 다운로드 2(검증용)다. 남은 것: 사용자의 첫 실행 확인, README 상태 줄 갱신 PR, 사용자의 소개 글 게시 → 3-2 제안.

> ✅ **3-1 승인 (2026-11-20).** 사용자가 권장안대로 승인했다. 공개 전 정리(README 스크린숏, 이슈 템플릿, 미확인 환경 안내, 토픽) → cask 사전 시험 → `v0.1.0` → 설치 확인 → 릴리스 노트 → 기준선 기록 → 사용자가 소개 글 게시 순서로 진행한다.

> 📝 **3-1 첫 공개 제안 (2026-11-20).** 정식 `v0.1.0`의 공개 순서와 실패 대응, 공개 전 정리(README 스크린숏, 이슈 템플릿, 미확인 환경 안내, 토픽), cask 사전 시험, 이 기기에서의 Homebrew 설치 확인, 소개 글 초안(Show HN, GeekNews)을 제안했다. 공식 `homebrew/cask`는 인지도 기준(자체 제출 stars 225 등)과 30일 조건에 못 미쳐 자체 tap을 유지한다. AI_PROPOSED, 승인 대기.

> ✅ **R-1 머지 (2026-11-20).** PR #5를 `main`에 머지했다(`b8b05f6`). Construction → Operations 게이트를 통과했다. 다음: 3-1 첫 공개(`v0.1.0`, Homebrew 설치 확인). 정식 태그 전용 단계와 Environment의 `TAP_TOKEN`은 그때 처음 실행된다.

> ✅ **R-1 후속: 릴리스 경로 재시험 (2026-11-20).** 릴리스 비밀 값을 Environment `release`로 옮기고(저장소 수준 0개) `v*` 태그 보호를 걸었다. `v0.1.0-rc.4`는 승인 대기로 멈췄다가, 사용자가 승인한 뒤 모든 검사와 서명·공증을 통과했다. 내려받은 앱은 `spctl`에서 "Notarized Developer ID"로 받아들여졌다. 남은 것: PR #5 머지. 다음: 3-1 첫 공개(`v0.1.0`, Homebrew 설치 확인).

> ✅ **R-1 승인 (2026-11-20).** 사용자가 권장안대로 승인했다. 리뷰 판정과 수정을 확정하고, 릴리스 비밀 값은 GitHub Environment `release`(실행마다 사용자 승인, `v*` 태그와 `main`만 사용)로 옮기고 `v*` 태그를 보호한다. 러너는 `macos-latest`를 유지하고, README에 알림에 세션 제목이 보인다고 적었다. 남은 것: 사용자의 Environment·태그 규칙 설정과 비밀 값 재등록 → `v0.1.0-rc.4` 재시험 → PR #5 머지 → 3-1 첫 공개(`v0.1.0`).

> 🔍 **R-1 독립 코드 리뷰 제안 (2026-11-20).** 작성 세션과 분리된 다른 모델의 리뷰어 3명이 2-1 ~ 2-4 전체를 검토했다(CRITICAL·HIGH 0, MEDIUM 10). 수정 중 삭제 경로를 한 번 더 리뷰해 HIGH 2건(남의 DB 테이블 삭제, 링크로 root 안에 색인 생성)을 더 찾아 고쳤다. 테스트 170 → 213개, 실제 기록 네 기간 × 임계값 두 개가 프로토타입과 글자 단위로 같다. 반목표 검사는 스크립트와 바이너리 심볼 검사로 바꿨고, 릴리스는 서명 전에 CI와 같은 검사를 거친다. 바뀐 릴리스 경로는 `v0.1.0-rc.4`로 다시 시험해야 한다. AI_PROPOSED, 승인 대기.

> ✅ **2-4 머지 (2026-11-20).** PR #4를 `main`에 머지(`629b33f`). 태그를 올리면 서명·공증된 유니버설 앱이 GitHub Release에 올라가고, 정식 태그면 Homebrew tap이 갱신된다. 다음: R-1 독립 코드 리뷰(Construction → Operations 게이트), 이어서 3-1 첫 공개(`v0.1.0`, Homebrew 설치 확인).

> ✅ **2-4 사용자 확인 (2026-11-20).** 사용자가 `v0.1.0-rc.3`을 브라우저로 내려받아 경고 없이 열리는 것을 확인했다. Build Spec IMPLEMENTED. 남은 것: PR #4 머지. 다음: R-1 독립 코드 리뷰, 3-1 첫 공개(`v0.1.0`, Homebrew).

> 🏗️ **2-4 사전 릴리스 시험 통과 → 사용자 확인·머지 대기 (2026-11-20, PR [#4](https://github.com/bingoring/tokens-are-running-out/pull/4)).** 사용자가 인증서·API 키·tap 토큰을 만들고 비밀 값 6개를 등록했다. `v0.1.0-rc.3`에서 서명, 공증 Accepted, 티켓, GitHub 사전 릴리스까지 성공했고, 내려받은 앱이 "source=Notarized Developer ID"로 판정되어 실행됐다. 로그에 비밀 값 노출 없음. rc.1(키 ID·발급자 ID가 바뀌어 등록됨)과 rc.2(새 Developer ID의 첫 공증이 30분을 넘김)의 실패에서 형식 검사와 공증 결과 읽기를 고쳤다. 남은 것: 사용자가 브라우저로 내려받아 열어 보기, 머지.

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
| 2-4 릴리스 파이프라인 (서명 · 공증 · Homebrew tap) | [04-release-pipeline.md](02-construction/04-release-pipeline.md) · [Build Spec](02-construction/release-pipeline/build-spec-index.md) IMPLEMENTED · PR [#4](https://github.com/bingoring/tokens-are-running-out/pull/4) 머지 `629b33f` | HUMAN_APPROVED |
| 2-5 큰 세션 정리 안내 (compact 프롬프트 · 시점 안내) | [05-compact-guidance.md](02-construction/05-compact-guidance.md) · [Build Spec](02-construction/compact-guidance/build-spec-index.md) IMPLEMENTED · PR [#10](https://github.com/bingoring/tokens-are-running-out/pull/10) 머지 `58836ba` · 회귀 수정 PR [#11](https://github.com/bingoring/tokens-are-running-out/pull/11) 머지 `d232c66` | HUMAN_APPROVED |

## Phase R — Independent Code Review 🔍 (Construction → Operations 게이트)

> 작성자와 **컨텍스트가 분리된** 독립·적대적 리뷰어가 코드를 검토한다. FRAMEWORK "리뷰 게이트" 참조.

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| R-1 Independent Code Review | [01-independent-review.md](0R-review/01-independent-review.md) · PR [#5](https://github.com/bingoring/tokens-are-running-out/pull/5) 머지 `b8b05f6` | HUMAN_APPROVED |

## Phase 3 — Operations (Ship)

| 스테이지 | 문서 | 상태 |
|---------|------|------|
| 3-1 첫 공개 (GitHub Releases · Homebrew tap) | [01-first-release.md](03-operations/01-first-release.md) · [소개 글 초안](03-operations/first-release/launch-posts.md) | HUMAN_APPROVED |
| 3-2 반응 확인 (수요 가설 검증) | (예정) | PENDING |

---

## AI 진입점

> AI는 위 테이블에서 `PENDING` 또는 승인 대기가 풀린 가장 앞 스테이지부터 작업을 시작하세요.
> 규칙: `FRAMEWORK.md` 참조
