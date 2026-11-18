---
build-spec: release-pipeline
stage: 02-construction/04-release-pipeline
status: READY
depth: standard
updated: 2026-11-18
---

# Build Spec — 릴리스 파이프라인 (서명 · 공증 · Homebrew tap)

## §0. 개요 & 범위
- **목표(한 줄):** 태그를 올리면 유니버설 앱을 Developer ID로 서명하고 공증해 GitHub Release에 zip으로 올리고, 정식 태그면 Homebrew tap의 cask를 갱신하는 파이프라인과 앱 아이콘을 만든다.
- **SoT:**
  - [`../../inputs/design.md`](../../inputs/design.md) 9장(배포)
  - [`../../01-inception/03-architecture-decision.md`](../../01-inception/03-architecture-decision.md)의 "지키는 선"과 외부 의존성 표(서명·공증, Homebrew)
  - [`../../DECISIONS.md`](../../DECISIONS.md) 2026-11-18 2-4 항목
  - 공식 자료: Homebrew Acceptable Casks, Homebrew Security and Supply Chain, Cask Cookbook(2026-11-18 조회), 설치된 `notarytool`·`stapler`·`codesign` 도움말(Xcode 26.4)
- **규모/제약:** 비밀 값 여섯 개는 사용자가 만들고 등록한다. 앱 코드는 바꾸지 않는다(아이콘과 `Info.plist`만).
- **깊이 티어 & 사유:** `standard`. 화면이 없고, 순서와 규칙이 핵심이다.

## §1. 분해

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `scripts/make-icon.swift`, `Resources/AppIcon.icns` | 앱 아이콘 | Core Graphics, `iconutil` | 신규 |
| `scripts/build-app.sh` | `--release <version>`: 유니버설 Release 빌드, 버전·아이콘 | Xcode | 기존 수정 |
| `scripts/release.sh` | 서명·공증·티켓·검증·패키징 | Xcode 도구 | 신규 |
| `scripts/update-cask.sh`, cask 템플릿 | cask 갱신 | | 신규 |
| `.github/workflows/release.yml` | 태그 → 릴리스 → tap | 위 스크립트, 비밀 값 | 신규 |
| `.github/workflows/update-tap.yml` | 이미 있는 릴리스로 tap만 다시 갱신 | `update-cask.sh`, `TAP_TOKEN` | 신규 |
| `bingoring/homebrew-tap` | 공개 tap 저장소(`Casks/`, README) | | 신규(사용자 확인 후 생성) |
| README | 설치 방법(Homebrew, 직접 내려받기), 릴리스 방법 | | 기존 수정 |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`./domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`./business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`./business-logic-model.md`](business-logic-model.md) |
| frontend-components | N/A | 화면이 없다. 아이콘의 도형은 domain-entities `AppIcon`과 business-logic-model §3에 둔다 |

## §3. 미해결 질문

없음. 사용자가 정한 네 가지(zip, tap 자동 갱신, 아이콘 지금 제작, API 키)는 [DECISIONS](../../DECISIONS.md) 2026-11-18에 기록했다.

## §4. 구현 체크리스트

- [x] 아이콘 생성 스크립트와 `.icns`, `build-app.sh`가 아이콘을 넣음. 아이콘을 better-ui·better-colors로 검토
- [x] `build-app.sh --release <version>`(유니버설, 버전 키)
- [x] `release.sh`(서명·검증·공증·티켓·zip·체크섬). 비밀 값 없이 ad-hoc으로 도는 `--dry-run`
- [x] `update-cask.sh`와 cask 템플릿. `brew style`로 문법 확인(이름은 `update-tap.sh`, §7)
- [x] `release.yml`(형식 확인, 빌드 전 비밀 값 확인, 키체인, 정리 단계 포함)과 `update-tap.yml`
- [x] README 설치·릴리스 안내
- [ ] (사용자) Developer ID Application 인증서, App Store Connect API 키, tap 토큰을 만들고 비밀 값 등록
- [x] (사용자 확인 후) `bingoring/homebrew-tap` 생성
- [ ] 사전 릴리스 `v0.1.0-rc.1`로 끝까지 시험: 공증 Accepted, 첨부 zip을 받아 `spctl`·`stapler validate`·실행
- [x] 독립 리뷰와 반영
- [x] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획

- [x] 엄격 빌드, 린트, 전체 테스트(앱 코드 변경 없음을 확인)
- [x] `release.sh --dry-run`: ad-hoc 서명에 hardened runtime, `codesign --verify --strict --deep` 통과, 유니버설(`lipo -archs`), 버전 키, 아이콘 포함
- [x] 생성한 cask가 `brew style`을 통과
- [x] x86_64 쪽도 한 번 실행(`arch -x86_64`, Rosetta가 있을 때). 없으면 Intel은 Not verified로 남긴다 → Rosetta가 없어 **Not verified**
- [x] 시험용 앱은 사용자가 띄워 둔 앱과 따로 실행하고, 앱 이름이 아니라 PID로 종료한다
- [ ] `v0.1.0-rc.1` 사전 릴리스: 워크플로 성공, 공증 Accepted, 내려받은 앱이 `spctl`에서 "source=Notarized Developer ID", `stapler validate` 통과, 실행됨. cask는 바뀌지 않음
- [ ] 워크플로 로그와 저장소에 비밀 값이 나타나지 않음
- [ ] 정식 `v0.1.0` 릴리스와 `brew install --cask`는 3-1(첫 공개)에서 한다

## §6. NFR

N/A(standard). 릴리스 한 번이 30분 안에 끝나면 된다(공증 대기 포함).

## §7. 편차 로그 — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| §1 `Resources/AppIcon.icns` | `Assets/AppIcon.icns` | 저장소 최상위의 `Resources/`는 SwiftPM 대상의 리소스 폴더(`Sources/*/Resources`)와 헷갈린다 |
| §1·RL-13 `scripts/update-cask.sh`와 cask 템플릿 | `scripts/update-tap.sh` 하나. cask 내용은 스크립트 안에 있고, tap 저장소 받기·커밋·push까지 한다(`--write-only DIR`은 파일만 쓴다) | 두 워크플로가 같은 단계를 그대로 공유하고, 로컬 사본으로 push 경로를 시험할 수 있다 |
| domain-entities `Cask` `depends_on macos: ">= :sonoma"` | `depends_on macos: :sonoma`. 그리고 `livecheck`(github_latest), `uninstall quit:`, `zap`(색인 폴더, 설정 파일)을 더함 | `brew style`이 앞의 표기를 거부한다(Homebrew/OSDependsOn). 나머지는 제거와 갱신 확인을 위한 표준 항목 |
| business-logic-model §2.7 `--generate-notes` | 릴리스 본문 맨 앞에 zip의 SHA-256을 넣고 그 뒤에 자동 노트 | 불변식 INV1(본문의 값)을 지키기 위해 |
| business-logic-model §2.6 `--sign "Developer ID Application: …"`, `--verbose=2`, `-dvvv` | `--sign <SHA-1>`(키체인에 하나뿐임을 확인한 ID), `codesign --verify --strict --deep`, `-dvv`로 runtime 플래그 확인 | 이름 문자열보다 해시가 정확하다. 확인에 쓰는 출력은 같다 |
| business-logic-model §2.8 `TAP_TOKEN`으로 tap 저장소를 받음 | 토큰을 URL이 아니라 환경 변수(`GIT_CONFIG_*`)의 HTTP 헤더로 전달하고, Actions에서는 인코딩한 값도 마스킹 | 독립 리뷰: 프로세스 인자와 클론의 `.git/config`에 토큰이 남지 않게 |
| (명시 없음) 산출물 위치 | `.build/dist/` | `.build/release`는 SwiftPM이 만드는 링크라서 겹치면 링크를 덮어쓴다(독립 리뷰, 실제로 확인) |
| RL-13 `.sha256`에서 읽음 | `update-tap.yml`은 zip도 함께 받아 `shasum -c`로 맞는지 확인한 뒤 갱신 | 체크섬 파일만 믿지 않는다 |
| RL-6 `spctl` 통과 | 판정 결과는 실패할 때만 출력 | 성공한 로그를 짧게 둔다(서명자 이름은 비밀 값이 아니다) |
| business-logic-model §3 "둥근 사각형" | SwiftUI `RoundedRectangle(cornerRadius: 185.4, style: .continuous)`(Apple 아이콘 격자). 처음 만든 초타원(n=5)은 버렸다 | macOS 27에서 초타원 바탕은 Finder가 회색 틀 안에 줄여 넣었다. 시스템 모양과 같은 둥근 사각형은 그대로 표시됐다(그림자 유무와 무관, 실측) |
