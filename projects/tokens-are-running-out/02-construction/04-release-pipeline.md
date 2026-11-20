---
phase: 02-construction
stage: 04-release-pipeline
status: HUMAN_APPROVED
updated: 2026-11-18
---

# [Stage 2-4] 릴리스 파이프라인 (서명 · 공증 · Homebrew tap)

## 목적

다른 사람의 Mac에서 내려받아 바로 실행되는 앱을 만든다. 태그를 올리면 유니버설 앱을 Developer ID로 서명·공증해 GitHub Release에 올리고, 정식 태그면 Homebrew tap의 cask를 갱신하는 파이프라인과 앱 아이콘이 산출물이다. 정식 첫 공개는 3-1에서 한다.

## 입력 (Inputs)

- 승인된 스테이지: [`../01-inception/03-architecture-decision.md`](../01-inception/03-architecture-decision.md)(서명·공증 배포, Mac App Store 아님), [`03-menu-bar-app.md`](03-menu-bar-app.md)(앱과 `scripts/build-app.sh`)
- 설계 입력: [`../inputs/design.md`](../inputs/design.md) 9장(배포)

## 체크리스트

- [x] 2-4와 3-1(첫 공개)의 경계를 그었다
- [x] Homebrew의 Gatekeeper 정책과 cask 문법을 공식 문서로 확인했다
- [x] `notarytool`·`stapler`·`codesign`의 현재 사용법을 설치된 도구로 확인했다
- [x] 유니버설 빌드와 hardened runtime 서명이 동작하는지 시험했다
- [x] 사용자 결정 네 가지를 물어 정했다
- [x] Build Spec(standard)을 썼다
- [x] 미해결 질문이 없다

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 범위
- **포함:** 앱 아이콘, 유니버설 Release 빌드, Developer ID 서명(hardened runtime), 공증과 티켓 붙이기, zip과 체크섬, 태그로 시작하는 GitHub Actions 릴리스, Homebrew tap 저장소와 cask 자동 갱신, 사전 릴리스(`v0.1.0-rc.1`)로 끝까지 시험, README 설치 안내
- **제외:** 정식 `v0.1.0` 공개와 `brew install` 확인, 소개 글 → 3-1. 자동 업데이트 → 넣지 않음(네트워크 금지, Homebrew가 업데이트를 맡음). 공식 `homebrew/cask` 등록 → 인지도 조건을 채운 뒤

### 2-4에서 확인한 사실
- **Homebrew와 Gatekeeper.** 공식 cask는 Gatekeeper 검사를 통과해야 하고, 통과하지 못하는 cask는 비활성화된 뒤 삭제된다(Acceptable Casks, Security and Supply Chain, 2026-11-18 조회, 공식 확인). Homebrew는 cask로 받은 파일에 quarantine 속성을 붙인다. 서드파티 tap은 "지원하지 않음"이라고만 적혀 있지만, quarantine 때문에 서명·공증이 없으면 처음 열 때 Gatekeeper에 막힌다. 2차 자료들은 Homebrew 5.0에서 `--no-quarantine`이 사라졌고 2026-09-01부터 Gatekeeper를 통과하지 못하는 cask를 막는다고 전한다(2차 자료, 추론).
- **공증 도구.** 설치된 `notarytool`(Xcode 26.4)은 App Store Connect API 키(`--key`, `--key-id`, `--issuer`)와 `--wait`을 지원한다. `stapler`는 디스크 이미지, 서명된 번들, pkg만 지원하고 zip은 지원하지 않는다. 그래서 zip을 제출해 공증받고, `.app`에 티켓을 붙인 뒤 다시 zip으로 묶는다(공식 확인: 도구 도움말).
- **빌드와 서명 시험.** `xcodebuild -destination 'generic/platform=macOS'`의 Release 빌드가 유니버설(x86_64, arm64)로 24초에 끝났다. 함께 넣을 동적 프레임워크는 없다. hardened runtime을 붙여 ad-hoc 서명한 앱이 `codesign --verify --strict --deep`을 통과했고 정상 실행되었다(메모리 24MB).
- **서명 인증서.** 이 기기에는 Apple이 발급한 서명 인증서가 없다(직접 만든 인증서 하나뿐). Developer ID Application 인증서를 새로 만들어야 한다.
- **아이콘.** Apple 약관상 SF Symbols는 앱 아이콘에 쓸 수 없다. 모래시계를 직접 그린다.
- **서명 주체.** Developer ID 인증서는 계정 소유자(Account Holder)만 만들 수 있고, 관리자는 클라우드 관리형 인증서만 쓸 수 있다. App Store Connect API 접근 요청도 계정 소유자만 한다([Apple: Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates), [App Store Connect role permissions](https://developer.apple.com/help/app-store-connect/reference/account-management/role-permissions/), 2026-11-18 조회, 공식 확인). 서명에는 팀의 법적 이름과 팀 ID가 들어가 모든 사본에 남고, 사용자가 `codesign`이나 Gatekeeper 대화상자에서 볼 수 있다.

### 결정 (사용자가 정함, DECISIONS 2026-11-18)
- 배포 형식은 **zip**.
- **릴리스가 tap을 자동 갱신**한다(`bingoring/homebrew-tap`, `TAP_TOKEN`).
- 앱 아이콘을 **지금 만든다**.
- 공증 자격 증명은 **App Store Connect API 키**.

### 작성자 판단
- 사전 릴리스 태그(`-rc.N`)는 GitHub prerelease로 만들고 cask는 바꾸지 않는다. 파이프라인 시험은 `v0.1.0-rc.1`로 한다.
- 유니버설 바이너리로 만든다(macOS 14를 쓰는 Intel Mac이 있다).
- 서명·공증 단계는 `scripts/release.sh`에 모아 로컬에서도 같은 순서로 돌릴 수 있게 하고, 워크플로는 그것을 부르기만 한다.

### 사용자 작업 (작업자가 대신할 수 없음)
1. **Developer ID Application 인증서:** Xcode ▸ Settings ▸ Apple Accounts(예전 Xcode에서는 Accounts) ▸ 팀 선택 ▸ Manage Certificates… ▸ + ▸ Developer ID Application. 키체인 접근에서 그 인증서를 개인 키와 함께 .p12로 내보내고 암호를 정한다.
2. **App Store Connect API 키:** App Store Connect ▸ Users and Access ▸ Integrations ▸ Team Keys ▸ +, 접근 권한 Developer. .p8은 한 번만 내려받을 수 있다. 키 ID와 발급자 ID를 적어 둔다.
3. **tap 토큰:** tap 저장소를 만든 뒤 GitHub ▸ Settings ▸ Developer settings ▸ Fine-grained tokens. 저장소는 `bingoring/homebrew-tap`만, 권한은 Contents 읽기·쓰기. 만료 기한이 있으므로 만료되면 새로 만들어 다시 등록한다.
4. **비밀 값 등록:** 저장소 폴더에서, 이 대화가 아니라 **사용자의 터미널**에서 실행한다(대화창에서 실행한 명령과 출력은 대화 기록에 남는다). 값은 파일에서 읽거나 입력을 물으므로 화면에 남지 않는다. `--body` 옵션은 쓰지 않는다. `<…>` 자리는 실제 파일 경로로 바꾼다.

```bash
base64 -i <내보낸 .p12> | gh secret set DEVELOPER_ID_P12_BASE64
```

```bash
gh secret set DEVELOPER_ID_P12_PASSWORD
```

```bash
base64 -i <내려받은 AuthKey_….p8> | gh secret set NOTARY_KEY_P8_BASE64
```

```bash
gh secret set NOTARY_KEY_ID
```

```bash
gh secret set NOTARY_ISSUER_ID
```

```bash
gh secret set TAP_TOKEN
```

### 구현 스펙
- Build Spec: [`release-pipeline/build-spec-index.md`](release-pipeline/build-spec-index.md) (status: READY, depth: standard)

### 검증 요약
- `release.sh --dry-run`(비밀 값 없이 ad-hoc): hardened runtime, 엄격 검증, 유니버설, 버전 키, 아이콘
- 생성한 cask가 `brew style` 통과
- 비밀 값 등록 뒤 `v0.1.0-rc.1`: 공증 Accepted, 내려받은 앱이 "source=Notarized Developer ID"로 판정되고 실행됨
- 아이콘을 better-ui·better-colors로 검토

### 미해결 질문
없음.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] 2-4 범위와 3-1(정식 첫 공개)의 경계가 맞는가?
- [x] 어느 팀(개인 또는 조직) 이름으로 서명할까? 그 팀의 계정 소유자(Account Holder)인가? (서명에 팀의 법적 이름과 팀 ID가 남는다)
- [x] 공개 저장소 `bingoring/homebrew-tap`을 만들어도 되는가?
- [x] 시험용 사전 릴리스 `v0.1.0-rc.1`을 공개 저장소에 올려도 되는가(prerelease로 표시됨)?
- [x] 사용자 작업 1 ~ 4(인증서, API 키, 토큰, 비밀 값 등록)를 해 줄 수 있는가?

### 승인 결과 (2026-11-18, 사용자)

> AI가 기록한다. 사람의 답이 AI 기본안과 다르면 어느 절을 대체하는지 명시한다(FRAMEWORK "승인 결과 기록").

| # | 답변 |
|---|------|
| 1 | 채팅으로 "승인". AI 제안대로 확정한다: 범위, 공개 tap 저장소 `bingoring/homebrew-tap` 생성, 시험용 사전 릴리스 `v0.1.0-rc.1` 공개, 사용자 작업 1 ~ 4. 서명 주체는 사용자가 인증서를 만드는 팀(사용자가 계정 소유자인 팀)이며, 서명에 그 팀의 이름과 팀 ID가 남는다는 점을 알렸다. |

## 구현 결과 (2026-11-18 ~ 20, PR [#4](https://github.com/bingoring/tokens-are-running-out/pull/4))

### 검증
| 항목 | 결과 |
|---|---|
| 앱 코드 | `Sources/`, `Tests/`, `Tools/`, `Package.swift` 변경 없음. 엄격 빌드, 테스트 170개, `swift format lint --strict` 통과 |
| 릴리스 빌드 | `build-app.sh --release 0.1.0-rc.1`: `x86_64 arm64`, `CFBundleShortVersionString` 0.1.0, `CFBundleVersion` 커밋 수, 아이콘 포함. 값이 없거나 형식이 틀린 버전은 거부 |
| 서명(dry-run) | ad-hoc 서명에 hardened runtime(`flags=0x10002(adhoc,runtime)`), `codesign --verify --strict --deep` 통과. 앱 버전과 다른 `--version`, 인자 누락은 거부 |
| 실행 | hardened runtime 빌드를 따로 실행해 6초 뒤 살아 있음을 확인(메모리 약 93MB, CPU 0.0%)하고 PID로 종료 |
| cask | `brew style` 통과(임시 로컬 tap에서 검사한 뒤 제거). `depends_on macos: ">= :sonoma"`는 거부되어 `:sonoma`로 바꿈. `brew info`가 이를 "macOS >= 14"로 읽음을 확인. Homebrew 7은 신뢰하지 않은 tap의 cask를 읽지 않지만, `brew install --cask bingoring/tap/…`처럼 tap 이름을 붙이면 그 cask를 자동으로 신뢰한다(`--dry-run`으로 확인, 신뢰 목록은 임시 폴더에 둠) |
| tap push | 로컬 사본(bare 저장소)으로 시험: 첫 실행은 커밋·push, 같은 버전은 아무것도 하지 않고 성공, 토큰이 없으면 실패, 사전 릴리스 버전과 잘못된 체크섬은 거부. 토큰은 클론의 `.git/config`에 남지 않음 |
| 워크플로 | 모든 `run` 블록의 셸 문법 확인. 태그와 입력 값은 `env`로만 넘김. PR CI에 `build-app.sh --release 0.0.0`과 `release.sh --dry-run` 단계를 더해 러너에서도 유니버설 빌드와 hardened runtime 서명을 확인한다 |
| 아이콘 | 같은 스크립트로 다시 만들면 바이트까지 같음. 모든 크기에서 캔버스 가장자리 알파 0. 그래픽 대비(렌더링 픽셀 측정): 흰 캡 9.50 ~ 12.23:1, 모래 5.48 ~ 7.06:1(기준 3:1) |

### 아이콘 검토 (better-ui · better-colors)
Finder가 쓰는 `NSWorkspace` 아이콘을 크기별로 렌더링해 확인했다.

| 심각도 | 위치 | 이전 | 이후 | 이유 |
|---|---|---|---|---|
| MEDIUM | `make-icon.swift` 바탕 모양 | 초타원(n=5). macOS 27 Finder가 회색 틀 안에 줄여 표시 | Apple 격자의 연속 곡률 둥근 사각형(824pt, 반경 185.4). 64px 이상에서 그대로 표시 | 아이콘이 작고 다른 앱과 달라 보인다. 모양 2가지 × 그림자 유무를 렌더링해 원인이 모양임을 확인 |
| MEDIUM | 그림자 | 256px 이하에서 그림자가 캔버스 가장자리에서 잘림(64px 아래 가장자리 알파 53/255) | 오프셋과 흐림을 캔버스 크기에 비례 | Core Graphics 그림자 값은 축소 변환을 따르지 않는다 |
| 남김 | 16·32px | macOS 27이 회색 테두리를 그림 | 그대로 | 설치된 다른 `.icns` 앱(Cursor, Slack, Obsidian, Figma)도 같다. 없애려면 Icon Composer 형식(`.icon`과 `actool`)이 필요해 이 스테이지 범위 밖이다 |

### 독립 리뷰 (FRAMEWORK "리뷰 게이트" 방식, 2026-11-18)
작성자와 컨텍스트를 공유하지 않는 서브에이전트(코드 리뷰어)가 `249ac47`까지를 검토했다. 리뷰어 세션에는 셸이 없어 코드를 읽고 판단했다. RL-1 ~ RL-13과 어긋나는 확정 버그는 없었고, 확신이 낮은 지적 6건과 문서 불일치 3건을 남겼다. 지적마다 직접 확인한 뒤 처리했다(`0b510bd`).

| 확신 | 지적 | 처리 |
|---|---|---|
| 약 40 | `TAP_TOKEN`이 git 프로세스 인자와 클론의 `.git/config`에 남는다 | **채택.** 토큰을 환경 변수(`GIT_CONFIG_*`)의 HTTP 헤더로 넘기고, Actions에서는 인코딩한 값도 마스킹한다. 클론 설정에 남지 않음을 확인 |
| 약 25 | 산출물 폴더 `.build/release`가 SwiftPM의 링크와 겹친다 | **채택.** 실제로 링크가 실제 폴더로 바뀌어 있었다. `.build/dist`로 옮김 |
| 약 30 | `--release`에 값이 없으면 사용법 없이 끝나거나, 빈 값이면 일반 빌드로 진행한다 | **채택.** 사용법을 출력하고 실패 |
| 약 25 | 다른 태그의 릴리스가 동시에 tap에 push하면 실패하고, 예전 태그로 `update-tap.yml`을 실행하면 cask가 내려간다 | **반영하지 않음.** 동시 push는 안전하게 실패하고 `update-tap.yml`로 다시 실행할 수 있다(RL-13). 수동 실행으로 예전 버전을 고르는 것은 의도한 되돌리기일 수 있다 |
| 약 15 | 리소스 번들 안의 실행 파일이 서명되지 않을 수 있다 | **해당 없음.** 리소스 번들에는 문자열 파일만 있고 Mach-O는 0개 |
| 약 15 | 타임스탬프 서버가 잠시 실패하면 재시도가 없다 | **반영하지 않음.** 릴리스가 생기기 전 단계라 워크플로를 다시 실행하면 된다 |
| 문서 | `update-cask.sh` 이름, `--verbose=2`·`-dvvv` 표기, 서명 ID를 이름 대신 SHA-1로 지정 | **채택.** Build Spec 편차 로그에 기록 |

### 사전 릴리스로 끝까지 시험 (2026-11-19 ~ 20)
사용자가 Developer ID Application 인증서, App Store Connect 팀 키(Developer), tap 토큰을 만들고 비밀 값 6개를 등록했다. 작업자는 값을 보지 않고 이름과 등록 시각만 확인했다.

| 태그 | 결과 | 원인과 조치 |
|---|---|---|
| `v0.1.0-rc.1` | 실패(릴리스 없음) | Developer ID 서명은 성공. 공증 제출에서 `notarytool`이 발급자 ID가 UUID가 아니라고 거부했다. 키 ID와 발급자 ID가 서로 바뀌어 등록되어 있었다. 두 값의 형식을 빌드 전에 확인하는 단계를 더했다(`0800075`) |
| `v0.1.0-rc.2` | 실패(릴리스 없음) | 처음 실행은 새 형식 검사가 키 ID를 잡아냈다. 사용자가 다시 등록한 뒤 재실행하니 업로드와 인증은 성공했지만, Apple이 30분 안에 검사를 끝내지 않아 시간 초과됐다. 이때 결과 JSON이 표준 오류로 나와 스크립트가 제출 ID를 놓쳤다. 고쳤다(`2a888c5`). 그 제출은 나중에 사용자가 `notarytool info`로 확인했을 때 Accepted였다. 새 Developer ID의 첫 공증이 오래 걸린 것으로 본다 |
| `v0.1.0-rc.3` | **성공**(약 2분) | 공증 Accepted, 티켓 부착, 워크플로 안의 Gatekeeper 판정 통과, GitHub 사전 릴리스 생성 |

`v0.1.0-rc.3`의 첨부 파일을 내려받아 확인한 결과:

| 항목 | 결과 |
|---|---|
| 릴리스 | prerelease, 첨부 파일 2개(zip 1.76MB, `.sha256`), 본문 첫 줄에 SHA-256 |
| 체크섬 | `shasum -a 256 -c` 통과. 본문, `.sha256`, 실제 파일이 같다(INV1) |
| 번들 | `x86_64 arm64`, 버전 0.1.0, 빌드 65 |
| 서명 | `codesign --verify --strict --deep` 통과. Authority는 Developer ID Application → Developer ID Certification Authority → Apple Root CA. hardened runtime, 보안 타임스탬프, `Notarization Ticket=stapled` |
| 티켓 | `stapler validate` 통과 |
| Gatekeeper | `spctl --assess --type execute`: accepted, **source=Notarized Developer ID**(INV2). `syspolicy_check distribution`: "ready for distribution" |
| 실행 | 따로 실행해 6초 뒤 살아 있음(메모리 약 108MB, CPU 0.0%), PID로 종료. 시험용 사본은 LaunchServices 등록을 해제하고 지웠다 |
| 로그 | 비밀 값이 든 줄은 모두 `***`. 개인 키나 인증서 PEM 표지 0건, 200자 넘는 base64 0건. `AUTHORIZATION` 줄은 `actions/checkout`의 기본 토큰이고 가려져 있다 |
| tap | `Casks/`에 `.gitkeep`만 있다(사전 릴리스는 cask를 바꾸지 않음, RL-7) |

- 릴리스 없이 태그만 남은 `v0.1.0-rc.1`과 `v0.1.0-rc.2`는 그대로 둔다. 태그를 옮기거나 지우지 않는다.

### Not verified
- **Intel(x86_64) 실행:** 이 기기에 Rosetta가 없다. 바이너리에 x86_64 조각이 있는 것만 확인했다.
- **브라우저로 내려받아 여는 흐름:** quarantine 속성이 붙은 상태에서 Finder로 여는 과정은 확인 대화상자가 사용자 화면에 뜨므로 작업자가 하지 않았다. 사용자 확인 항목으로 둔다.
- **`brew audit`:** Homebrew가 이 기기의 Xcode 26.4.1을 오래된 버전으로 보고 실행을 거부했다.
- **tap 인증:** 토큰을 HTTP 헤더로 넘기는 경로는 아직 한 번도 실행되지 않았다. 로컬 시험은 `file://` 원격이라 헤더를 쓰지 않으므로, 커밋·push 순서와 "토큰이 설정에 남지 않음"만 증명한다. 사전 릴리스는 tap 단계를 건너뛰므로 첫 실행은 정식 `v0.1.0`(3-1)이다.

### 남은 일
1. 사용자: `v0.1.0-rc.3` 릴리스 페이지에서 zip을 브라우저로 내려받아 압축을 풀고 열어 본다. "인터넷에서 내려받은 앱" 확인 대화상자 외의 경고 없이 실행되면 통과다.
2. 그 확인 뒤 Build Spec을 IMPLEMENTED로 바꾸고 PR을 머지한다.

## 다음 단계

승인 후 → `STATUS.md` 갱신 → 기능 브랜치 `feature/2-4-release-pipeline`에서 아이콘과 스크립트·워크플로 구현(비밀 값 없이 검증 가능한 부분 먼저) → 사용자 작업 뒤 사전 릴리스로 끝까지 시험 → 독립 리뷰 → PR
