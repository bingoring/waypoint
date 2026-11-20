---
phase: 03-operations
stage: 01-first-release
status: HUMAN_APPROVED
updated: 2026-11-20
---

# [Stage 3-1] 첫 공개 (GitHub Releases · Homebrew tap)

## 목적

정식 `v0.1.0`을 공개하고, 다른 사람이 Homebrew나 GitHub Releases로 받아 설치하고 실행할 수 있음을 확인한다. 그다음 소개 글을 올리고, 3-2(반응 확인)에 넘길 기준선을 기록한다.

## 입력 (Inputs)

- 설계 입력: [`../inputs/design.md`](../inputs/design.md) 1장(성공의 모습, 외부 지표), 9장(배포), 13장(수요 가설)
- [1-3](../01-inception/03-architecture-decision.md) 외부 사실 표: Homebrew 공식 cask 조건("추론, 3-1 착수 전 재확인")
- [2-4](../02-construction/04-release-pipeline.md): 2-4와 3-1의 경계, Not verified(tap 인증, `brew audit`, Intel)
- [R-1](../0R-review/01-independent-review.md): 승인 결과, 승인 후 진행(rc.4 결과와 정식 태그에서 처음 실행되는 경로)
- [`DECISIONS.md`](../DECISIONS.md) 2026-11-20 항목(릴리스 검사, 릴리스 Environment)

## 체크리스트

- [x] 3-1 착수 전에 재확인하기로 한 외부 사실을 다시 조회했다
- [x] 정식 태그에서 처음 실행되는 경로를 찾고, 실패 지점별 대응을 정했다
- [x] 공개 전에 미리 시험할 수 있는 것과 없는 것을 나눴다
- [x] 사용자가 할 일과 AI가 할 일을 나눴다
- [x] 3-2에 넘길 기준선을 정했다

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 범위
- **포함:**
  1. 공개 전 정리: README 스크린숏, 이슈 템플릿, 미확인 환경 안내, 저장소 토픽(항목마다 게이트에서 정한다)
  2. cask 사전 시험(rc.4 자산으로)
  3. `v0.1.0` 태그와 릴리스, tap 갱신 확인
  4. 이 기기에서 Homebrew 설치 확인
  5. 릴리스 노트에 짧은 소개 붙이기
  6. 소개 글(Show HN, GeekNews Show GN) 초안. 게시는 사용자가 한다
  7. 3-2 기준선 기록
- **제외:** 공식 `homebrew/cask` 등록(아래 조건 미달), 자동 업데이트(설계 9장), 앱 코드 변경, 반응 분석과 기본값 재판단(3-2)

### 3-1 착수 전에 다시 확인한 외부 사실 (조회일 2026-11-20)

| 사실 | 출처 | 확인 수준 | 영향 |
|---|---|---|---|
| 공식 cask의 인지도 기준은 forks 30, watchers 30, stars 75 중 하나다. 저장소 소유자가 직접 제출하면 90, 90, 225다. 만든 지 30일이 안 된 저장소는 보통 받지 않고, 기준을 넘어도 등록이 보장되지는 않는다. 기준에 못 미치면 서드파티 tap으로 유지할 수 있다 | [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy) | 공식 확인 | 이 저장소는 2026-11-17에 만들었고 별이 0개다. 자체 tap을 유지하고, 공식 등록은 기준을 채운 뒤 다시 본다. 1-3의 "추론" 항목을 이 행으로 해소한다 |
| 공식 cask의 앱은 Homebrew의 Gatekeeper 검사를 통과해야 하고, Gatekeeper를 끄게 하면 안 된다 | [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks) | 공식 확인 | rc.4가 `spctl`에서 "Notarized Developer ID"로 통과했다 |
| Homebrew 6.0부터 비공식 tap은 명시적 신뢰가 필요하다. 전체 이름(`brew install --cask user/repository/cask`)으로 설치하면 그 항목만 신뢰하고 한 번에 설치된다 | [Tap Trust](https://docs.brew.sh/Tap-Trust) | 공식 확인 | README의 설치 명령이 이미 전체 이름이다. 이 기기의 Homebrew는 7.0.13이다 |
| Show HN은 다른 사람이 가입 없이 바로 써 볼 수 있어야 하고, 제목은 "Show HN"으로 시작한다. 친구에게 추천이나 댓글을 부탁하면 안 된다 | [Show HN 안내](https://news.ycombinator.com/showhn.html) | 공식 확인 | Homebrew 설치를 확인한 뒤에 올린다 |
| GeekNews Show GN은 직접 만들어서 써 볼 수 있는 프로젝트가 대상이다. 제목은 "프로젝트명 - 핵심 기능" 형식이고, Show 유형을 고르면 "Show GN:"이 붙는다. 같은 프로젝트는 일정 기간 다시 올릴 수 없고, 추천 부탁은 금지다 | [가이드라인](https://news.hada.io/guidelines), [Show GN 소개](https://news.hada.io/blog/show) | 공식 확인(서브에이전트가 한국어 원문을 요약해 옮겼다) | 준비가 끝난 뒤 한 번만 올린다 |

### 지금 상태 (2026-11-20)
- `main`은 `b8b05f6`(PR #5 머지)이고 CI가 통과했다. `v0.1.0-rc.4`(`6d5b554`)와 다른 것은 waypoint 포인터 하나뿐이다.
- Environment `release`에 비밀 값 6개가 있고, 저장소 수준 비밀 값은 0개다. `v*` 태그 ruleset이 켜져 있다.
- tap 저장소 `bingoring/homebrew-tap`의 `Casks/`는 비어 있다(`.gitkeep`만 있음).
- `scripts/update-tap.sh --only-newer`가 빈 tap에 cask를 새로 쓰는 것을 임시 폴더에서 확인했다(`--write-only`, push 없음). 이 경로는 CI가 시험하지 않는다.
- 지난 확인 때 사용자가 연 rc.3 사본이 이 기기에서 실행 중이다. cask를 설치하거나 지우면 `uninstall quit:`이 같은 번들 ID의 앱을 끄고, 두 사본은 같은 색인 폴더를 쓴다.

### rc.4의 증명을 깨지 않는 조건
- `v0.1.0` 전에는 릴리스 경로 파일(`.github/workflows/release.yml`, `scripts/`, `Sources/`, `Package.swift`, `Assets/`)을 바꾸지 않는다. 릴리스 노트는 워크플로를 고치지 않고, 공개 뒤 `gh release edit`로 다듬는다.
- 태그는 CI가 통과한 `main` 커밋에만 올린다. 릴리스 잡이 반목표 검사를 추적 파일 전체에 다시 돌리므로, 새로 넣는 그림이나 이슈 템플릿이 거기서 걸리면 서명 전에 멈춘다.

### 공개 순서
1. **공개 전 정리 PR:** 게이트 2 ~ 5에서 승인한 것만 이 브랜치(`feature/3-1-first-release`)에 넣는다. 사용자가 머지한다.
2. **cask 사전 시험(게이트 6):**
   - `update-tap.sh --write-only`로 쓴 cask의 버전만 `0.1.0-rc.4`로 바꿔 임시 로컬 tap에 넣는다.
   - `brew audit`과 `brew install --cask`로 rc.4 자산을 설치해 본다. 확인 대상은 주소, 체크섬, `app`, `uninstall`, `zap`, `depends_on`이다.
   - 끝나면 앱을 지우고 임시 tap과 신뢰 설정을 없앤다.
   - 2-4에서는 임시 tap으로 `brew style`만 돌렸다(`brew audit`은 Xcode 버전 때문에 거부됨). 정식 릴리스 전에 cask를 끝까지 확인하는 방법은 이것뿐이다.
3. **태그 전 확인:**
   - 태그를 올릴 `main` 커밋의 CI가 통과했다.
   - rc.4와 비교해 릴리스 경로 파일이 바뀌지 않았다.
   - Environment 비밀 값 6개가 있고, 저장소 수준 비밀 값은 0개다.
   - tap의 `Casks/`가 비어 있다.
4. **`v0.1.0` 태그 push(게이트 7):** 그 `main` 커밋에 annotated 태그를 올린다.
5. **승인 대기 확인과 사용자 승인:** 승인 클릭이 마지막 중단 지점이다. 승인하기 전에 3번이 모두 참이어야 한다.
6. **실행 결과와 검증:**
   - 모든 단계가 성공해야 한다. 이번에는 `main` 조상 확인과 cask 갱신 단계도 실행된다.
   - 내려받은 자산은 rc.4와 같은 방법으로 검증한다.
   - tap 저장소에 새 커밋이 생기고, cask의 버전이 0.1.0이며 체크섬이 릴리스의 `.sha256`과 같아야 한다.
7. **이 기기에서 설치 확인(게이트 8):**
   - `brew install --cask bingoring/tap/tokens-are-running-out`으로 설치한다.
   - AI는 설치 위치, quarantine 속성, `spctl`, `brew audit --cask`를 확인한다.
   - 처음 열 때의 확인 대화상자와 실제 화면 확인은 사용자가 한다.
   - 게이트 9에서 고르면 `brew uninstall --zap`으로 색인과 설정이 지워지는지 확인하고 다시 설치한다.
8. **릴리스 노트(게이트 10):** 자동 생성된 노트 위에 짧은 소개를 붙인다. SHA-256 줄과 자산은 그대로 둔다.
9. **기준선 기록:** 별 수와 릴리스별 다운로드 수를 적는다. AI와 사용자의 검증용 내려받기가 섞이므로, 검증을 마친 직후의 값을 3-2의 0점으로 삼는다.
10. **공개 뒤 기록 PR:** README 첫머리의 "Status: pre-release" 줄을 첫 정식 릴리스에 맞게 바꾸고, 3-1 결과를 기록한 문서 포인터를 올린다. README는 릴리스 경로 파일이 아니므로 공개 뒤에 바꿔도 된다. 태그 전에 바꾸면 릴리스가 없는 동안 README가 틀린 말을 한다.
11. **소개 글 게시(게이트 11, 사용자):** 7번 확인이 끝난 뒤에만 올린다.

### 실패 대응: 릴리스 생성 전과 후로 나뉜다

| 실패 지점 | 공개된 것 | 대응 |
|---|---|---|
| 승인 전에 문제를 발견 | 태그뿐 | 실행을 취소하고, 고친 뒤 태그를 지우고 다시 올린다(ruleset은 관리자만 우회한다) |
| 태그 검사, `main` 조상 확인, 빌드·테스트·반목표·바이너리 검사, 서명, 공증 | 태그뿐 | 위와 같다. 릴리스는 만들어지지 않는다 |
| 릴리스를 만든 뒤 tap 단계(`TAP_TOKEN`, push) | `v0.1.0` 릴리스 | 잡을 다시 실행하거나 태그를 다시 올리지 않는다. 워크플로는 이미 있는 릴리스를 교체하지 않으므로, 다시 실행하면 릴리스 생성 단계에서 멈춘다. 필요하면 토큰을 다시 등록하고, `main`에서 "Update Homebrew tap"을 `v0.1.0`으로 실행한다(승인 필요) |
| 복구 워크플로도 실패 | `v0.1.0` 릴리스 | 사용자가 자기 기기에서 `TAP_TOKEN=… scripts/update-tap.sh 0.1.0 <sha256>`을 실행한다. 이 경로도 아직 실행된 적이 없다 |
| 공개 뒤 앱 결함 발견 | 릴리스와 cask | `v0.1.1`로 고친다. 공개 릴리스는 교체하지 않는다. 소개 글은 고친 뒤로 미룬다 |

### 공개 뒤에도 남는 Not verified
- **Intel(x86_64) 실행:** 바이너리에 x86_64 조각이 있지만, 이 기기에 Rosetta가 없어 실행하지 못했다.
- **macOS 14 ~ 26:** 앱과 cask는 macOS 14 이상을 요구하지만, 실행을 확인한 곳은 이 기기(macOS 27, Apple silicon)뿐이다.
- README는 "Requires macOS 14 or later, on Apple silicon or Intel"이라고 적고 있다. 게이트 4에서 미확인 환경을 밝힐지 정한다.

### 공개 전 정리 제안
- **README 스크린숏(게이트 2):**
  - `Tools/ui-snapshots`로 만든 팝오버(밝은 모드, 어두운 모드) 1 ~ 2장을 `docs/images/`에 넣고 README 위쪽에 보인다.
  - 세션 제목은 도구에 들어 있는 가상의 값("Refactor parser" 등)이다.
  - 이 기기에 설치한 앱의 화면은 실제 세션 제목을 보여 주므로 찍지 않는다.
- **이슈 템플릿(게이트 3):**
  - 버그 보고에서 macOS 버전, 칩, 설치 방법을 묻는다.
  - 대화 내용과 세션 제목은 붙이지 말고 집계 수치만 적어 달라고 안내한다. 3-2에서 받을 보고의 질을 높이고, 사용자의 업무 정보가 공개 이슈에 남는 것을 막는다.
- **미확인 환경 안내(게이트 4):** README의 설치 요구 사항 옆과 릴리스 노트에 "지금까지 macOS 27, Apple silicon에서 확인했고, Intel과 macOS 14 ~ 26의 결과를 이슈로 알려 달라"고 적는다.
- **저장소 토픽(게이트 5, 저장소 설정):** `macos`, `menu-bar`, `claude-code`, `swiftui`, `homebrew`를 붙인다. 설명은 이미 있다.

### 소개 글
- 초안: [first-release/launch-posts.md](first-release/launch-posts.md)(Show HN 영어, GeekNews 한국어)
- 주장은 이미 확인한 사실만 쓴다: 공증, 바이너리에 네트워크 심볼 없음, `~/.claude`에 쓰지 않음, MIT 오픈소스.
- 본인 기록의 집계 수치(설계 입력 1장: 만료로 생긴 재구축이 API 정가 환산 비용의 17.0%)를 쓸지는 게이트 11에서 정한다. 초안에는 대괄호로 표시했다.
- 두 곳 모두 한 번만 올리고, 추천이나 댓글을 부탁하지 않는다.

### 사용자 작업
- 공개 전 정리 PR 머지
- 실행 중인 rc.3 사본 종료(cask 사전 시험 전에)
- Environment 승인 클릭
- 설치한 앱을 처음 열 때의 확인 대화상자와 화면 확인
- 소개 글 게시와 댓글 응대

### 3-2로 넘길 것
- 기준선(검증 직후의 별 수와 다운로드 수), 게시 날짜와 링크
- 관찰 기간과 판정 기준은 3-2에서 제안한다.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요. 대외 행동은 항목마다 따로 답할 수 있다.

- [x] 1. 범위, 공개 순서, 실패 대응에 동의하는가? 공식 cask 조건 재확인으로 1-3의 "추론" 항목을 해소하는 것에 동의하는가?
- [x] 2. README에 가상 데이터 스크린숏을 넣을까?
- [x] 3. 이슈 템플릿(개인정보 안내 포함)을 넣을까?
- [x] 4. Intel과 macOS 14 ~ 26이 미확인이라는 점을 README와 릴리스 노트에 적을까?
- [x] 5. 저장소 토픽을 붙일까?(저장소 설정)
- [x] 6. cask 사전 시험: 이 기기의 임시 tap에서 rc.4 자산을 설치했다가 지워도 되는가?
- [x] 7. 정식 `v0.1.0` 태그를 올릴까? 공개 릴리스는 교체할 수 없고, tap 저장소에 커밋이 생긴다.
- [x] 8. 공개 뒤 이 기기에 Homebrew로 설치해 확인하고, 그대로 둘까?
- [x] 9. `brew uninstall --zap`도 확인할까? 이 기기의 실제 색인과 설정이 지워진다(색인은 다시 만들어지고, 설정은 기본값으로 돌아간다).
- [x] 10. 릴리스 노트에 짧은 소개를 붙일까?
- [x] 11. 소개 글: 채널(Show HN, GeekNews), 문안, 본인 집계 수치를 쓸지

### 승인 결과 (2026-11-20, 사용자)

> AI가 기록한다. 사용자가 채팅에서 "권장안대로 승인"으로 답했다. 질문별로 AI가 채팅에서 제시한 권장안을 적는다.

| # | 답변 |
|---|------|
| 1 | 동의. 범위, 공개 순서, 실패 대응을 확정한다. 공식 cask 조건 재확인으로 1-3의 "추론" 항목을 해소한다. |
| 2 | 넣는다. 스냅숏 도구의 가상 데이터로 만든 팝오버 화면(밝은·어두운 모드)을 README에 넣는다. |
| 3 | 넣는다. 버그 보고 템플릿에 대화 내용과 세션 제목을 붙이지 말라는 안내를 넣는다. |
| 4 | 적는다. Intel과 macOS 14 ~ 26이 미확인이라는 점을 README와 릴리스 노트에 적는다. |
| 5 | 붙인다. `macos`, `menu-bar`, `claude-code`, `swiftui`, `homebrew` |
| 6 | 한다. 사용자가 실행 중인 rc.3 사본을 끈 뒤, 이 기기의 임시 tap에서 rc.4 자산으로 설치했다가 지운다. |
| 7 | 올린다. 태그 전 확인을 모두 통과한 `main` 커밋에 `v0.1.0`을 올린다. |
| 8 | 설치해서 그대로 둔다. |
| 9 | 확인한다. `--zap` 뒤 다시 설치한다. |
| 10 | 붙인다. |
| 11 | 승인. Show HN과 GeekNews에 한 번씩, 초안 문안을 쓴다. 대괄호 안의 본인 집계 수치는 사용자가 게시할 때 넣을지 정한다. |

## 다음 단계

승인 후 → `STATUS.md`의 3-1을 `HUMAN_APPROVED`로 → 공개 전 정리 PR → cask 사전 시험 → 태그 전 확인 → `v0.1.0` → 검증과 설치 확인 → 릴리스 노트 → 기준선 기록 → 사용자가 소개 글 게시 → 3-2 제안

## 진행 결과

### 공개 전 정리 (2026-11-20, PR [#6](https://github.com/bingoring/tokens-are-running-out/pull/6))
- 저장소 토픽 5개를 붙였다(게이트 5).
- README에 스냅숏 도구로 만든 팝오버 화면(밝은·어두운 모드)과 미확인 환경 안내를 넣었다(게이트 2, 4).
- 버그 보고 템플릿을 넣었다(게이트 3). 대화 내용, 세션 제목, 프로젝트 경로를 붙이지 말라고 먼저 안내한다.
- 릴리스 경로 파일은 바뀌지 않았다. `check-anti-goals.py`는 추적 파일 86개에서 위반 0건이다.

### cask 사전 시험 (2026-11-20, 게이트 6)
사용자가 실행 중이던 rc.3 사본을 끈 뒤에 했다. `update-tap.sh --write-only`로 쓴 cask의 버전만 `0.1.0-rc.4`로 바꿔, 신뢰 설정을 임시 폴더로 격리한 임시 로컬 tap에 넣었다.

| 항목 | 결과 |
|---|---|
| `brew style` | 위반 없음 |
| `brew audit` | 실행되지 않음. Homebrew가 이 기기의 Command Line Tools(16.2)를 오래된 버전으로 보고 거부했다. 업데이트에는 관리자 권한이 필요하다 |
| 설치 | 전체 이름으로 한 번에 설치됨(그 항목만 신뢰). rc.4 자산을 내려받아 체크섬을 확인하고 `/Applications`로 옮겼다 |
| 설치된 앱 | quarantine 속성 있음, `spctl` "accepted, source=Notarized Developer ID", `codesign --verify --strict --deep` 통과, 버전 0.1.0, 번들 ID `io.github.bingoring.TokensAreRunningOut` |
| cask 정보 | 요구 사항 "macOS >= 14", 설치 항목은 앱 하나 |
| 제거 | `brew uninstall --cask`가 앱과 Caskroom 항목을 지웠다. `--zap`이 아니므로 색인 폴더는 남았다. 앱을 열지 않아서 `uninstall quit:`은 끌 앱이 없었다 |
| 정리 | 임시 tap 제거, 받은 파일 캐시 삭제, `tap-new`가 켠 개발자 모드 끔, 임시 신뢰 설정 삭제. tap 목록은 시험 전과 같다 |

- **Not verified:** `brew audit`(Command Line Tools 업데이트 뒤 공개된 tap에서 다시 시도할 수 있다), 실행 중인 앱이 있을 때의 `uninstall quit:`.

### `v0.1.0` 공개 (2026-11-20, 게이트 7)

**태그 전 확인:** 모두 통과했다.
- PR #6 머지 커밋 `657aa4f`의 `main` CI가 통과했다.
- rc.4와 비교해 릴리스 경로 파일 변경이 없다(바뀐 것은 README, 그림 두 장, 이슈 템플릿, 문서 포인터).
- Environment 비밀 값 6개, 저장소 수준 0개, 보호 규칙이 활성이다.
- tap의 `Casks/`가 비어 있고, `v0.1.0` 태그와 릴리스가 없었다.

**릴리스 실행:** `657aa4f`에 annotated 태그를 올렸다. 실행이 승인 대기로 멈췄고, 사용자가 승인했다.
- 처음 실행된 `main` 조상 확인을 포함해, 서명·공증·릴리스 생성까지 모든 단계가 성공했다.
- 마지막 tap 단계만 실패했다(아래 사고).

**릴리스 검증:** 공개된 자산을 새 폴더로 내려받아 다시 검사했다.
- 체크섬이 일치한다.
- `codesign --verify --strict --deep`, `stapler validate`, `spctl` "Notarized Developer ID", `syspolicy_check distribution`, `check-binary.sh`를 모두 통과했다.
- 버전은 0.1.0(빌드 100), 아키텍처는 `x86_64 arm64`이다.

**사고: tap 단계 403**
- 로그: `Permission to bingoring/homebrew-tap.git denied to bingoring`
- 원인: 토큰은 유효했지만(사용자로 인증됨), 사용자가 다시 만든 fine-grained 토큰에 저장소 권한이 하나도 추가되어 있지 않았다. 공개 저장소라서 clone은 됐고, push에서 막혔다.
- 대응: 계획한 대로 잡을 다시 실행하거나 태그를 다시 올리지 않았다. 사용자가 토큰 편집 화면에서 Contents를 추가해 Read and write로 바꿨고, 토큰 값은 그대로다.
- 복구: `main`에서 "Update Homebrew tap"을 `v0.1.0`으로 실행했다. 승인 뒤 성공했고, tap에 커밋 `c26525c`("tokens-are-running-out 0.1.0")가 생겼다. cask의 버전은 0.1.0이고, 체크섬은 릴리스의 `.sha256`과 같다.
- 이로써 Environment의 `TAP_TOKEN`과 복구 워크플로의 `main` 실행이 처음으로 증명되었다. 릴리스 잡 안의 tap 단계(`--only-newer`로 push)는 아직 성공한 적이 없고, 다음 정식 릴리스에서 처음 성공을 확인한다.

**이 기기 설치(게이트 8, 9)**
- `brew install --cask bingoring/tap/tokens-are-running-out`이 한 번에 설치되었다.
- 설치된 앱: quarantine 속성 있음, `spctl` "Notarized Developer ID", 서명 검증 통과, 버전 0.1.0
- `brew uninstall --zap`: 앱, 색인 폴더, 설정 파일을 지웠다. Homebrew는 파일을 휴지통으로 옮긴다고 출력했다. 설정 도메인도 비었고, Caskroom 항목도 남지 않았다. 그 뒤 다시 설치해 그대로 두었다.
- 처음 열 때의 확인 대화상자와 화면 확인은 사용자 확인 항목이다.

**릴리스 노트(게이트 4, 10):** 자동 생성된 노트 위에 짧은 소개를 붙였다. 붙인 내용은 무엇을 하는지, 무엇을 하지 않는지, 설치 방법, 미확인 환경 안내다. SHA-256 줄과 자산은 그대로다.

**3-2 기준선 (2026-11-20T06:29Z):**
- 별 0, 포크 0, watcher 0
- `v0.1.0` zip 다운로드 2, `.sha256` 2
- 이 수치에는 검증용 내려받기(AI의 `gh` 1회, tap 워크플로 1회)가 들어 있다. 이 기기의 Homebrew 설치 1회는 집계가 늦어 나중에 더해질 수 있다. 소개 글을 올리기 직전의 값을 3-2의 0점으로 삼는다.

- **Not verified:**
  - Intel, macOS 14 ~ 26
  - `brew audit`: Command Line Tools가 오래되어 실행되지 않는다
  - 실행 중인 앱이 있을 때의 `uninstall quit:`
  - 릴리스 잡 안의 tap 단계 성공

### 첫 실행 확인과 결함: "로그인할 때 열기"를 켤 수 없음 (2026-11-20)

**첫 실행:** 사용자가 Homebrew 설치본을 열었다.
- 처음에는 앱이 App Translocation 임시 경로에서 실행되었고, 첫 실행 확인 대화상자도 뜨지 않았다.
- 설정의 "로그인할 때 열기" 토글도 비활성이었다.

**원인 1, 이 기기의 환경: 같은 번들 ID의 사본**
- 2-4 확인 때 내려받은 rc.3 사본이 다운로드 폴더에 남아 있었다.
- 로그인 항목 데몬(`backgroundtaskmanagementd`)이 설치본 대신 그 사본의 경로를 조회했다.
- Finder로 설치본을 옮겼다가 되돌려도 달라지지 않았다.
- 사용자의 승인을 받아 그 사본을 LaunchServices 등록에서 빼고 휴지통으로 옮겼다. 그러자 확인 대화상자가 떴고("Homebrew Cask가 다운로드…"), 앱이 `/Applications`에서 바로 실행되었다. quarantine 플래그도 `0181`에서 `01c1`로 바뀌었다.
- 메뉴 막대와 한국어 설정 창이 정상으로 나왔다. 이로써 Homebrew 설치 확인을 통과했다.

**원인 2, 앱 결함: 처음 설치하면 상태가 `.notFound`**
- 조회 경로가 바로잡힌 뒤에도 `SMAppService` 상태는 3(`.notFound`)이었고, 데몬은 "record not found"를 냈다.
- 개발자 포럼과 이슈 보고에 따르면 `.notFound`는 시스템이 그 앱의 기록을 아직 갖고 있지 않다는 뜻이다. 첫 `register()`는 정상으로 동작한다([Apple Developer Forums 760186](https://developer.apple.com/forums/thread/760186), [713830](https://developer.apple.com/forums/thread/713830), [LaunchAtLogin #100](https://www.github.com/sindresorhus/LaunchAtLogin/issues/100), 2026-11-20 조회, 2차 자료).
- 앱은 `.notFound`를 "사용 불가"로 바꿨고, 설정 화면은 그 값이면 토글을 비활성화했다. 그래서 처음 설치한 사용자는 이 기능을 켤 수 없었다.
- 2-3 확인 때 개발 빌드에서 켜졌던 것은, 그 경로에 예전 등록 기록이 있었기 때문으로 추정한다(확인하지 못함).

**수정(`v0.1.1`):**
- `.notFound`를 `.notRegistered`와 같이 "꺼짐"으로 다룬다.
- 상태 변환을 `LoginItemStatus.init(_:)`로 떼어 내고, 수정 전 코드에서 실패하는 회귀 테스트를 먼저 썼다.
- 검증: 엄격 빌드 경고 0건, 테스트 215개 통과, 린트, 반목표 검사 통과
- 독립 리뷰(작성 맥락이 없는 리뷰어): HIGH·MEDIUM 0건. 모든 상태 값의 처리가 맞고, 사용자가 시스템 설정에서 로그인 항목을 지워도 앱이 스스로 다시 등록하지 않는다. LOW 2건은 후속 후보로 둔다.
  - `register()`가 실패하면 토글이 화면 안내 없이 꺼짐으로 돌아간다. 이전부터 `.notRegistered`에도 있던 동작이다.
  - `.notFound`에서 켜기까지 이어지는 모델 수준의 테스트가 없다. 변환 테스트와 화면 조건(`.unavailable`일 때만 비활성)으로 보장한다.
- 소개 글은 `v0.1.1`을 공개한 뒤에 올린다(사용자 결정, 2026-11-20).

**기타:**
- 같은 로그에 이 앱 이름으로 손쉬운 사용과 Apple Events 권한 검사가 기록되었다. 앱 소스에는 그런 API를 부르는 코드가 없고, 같은 시각에 다른 앱(키 입력 도구)의 항목이 함께 나온다. 권한 요청 창은 뜨지 않았다. 후속 확인 후보로 둔다.
- 로그인 항목 기록을 직접 보려고 `sfltool dumpbtm`을 실행했다가, 응답이 없어 30초 뒤 중단했다.
