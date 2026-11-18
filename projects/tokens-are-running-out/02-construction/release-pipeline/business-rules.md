---
artifact: business-rules
build-spec: release-pipeline
status: READY
updated: 2026-11-18
---

# Business Rules — 릴리스 파이프라인

## 1. 규칙 표 (Rules)

| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| RL-1 | 릴리스는 `ReleaseTag` 형식의 태그 push로만 시작한다. 형식이 다르면 아무것도 만들지 않는다 | `release.yml` | 워크플로 실패 | design 9장 |
| RL-2 | 이 저장소(`bingoring/tokens-are-running-out`)에서만 실행한다. 포크에서는 비밀 값이 없으므로 실행하지 않는다 | `release.yml` | 건너뜀 | GitHub Actions 비밀 값 규칙 |
| RL-3 | 앱은 `generic/platform=macOS`로 Release 빌드한 유니버설 바이너리다(arm64, x86_64) | `build-app.sh` | 실패 | 2-4 확인(`lipo -archs`) |
| RL-4 | 서명은 "Developer ID Application" 인증서로, `--options runtime --timestamp`를 붙인다. 엔타이틀먼트는 없다. 서명 뒤 `codesign --verify --strict --deep`이 통과해야 한다 | `release.sh` | 실패 | Apple 공증 요건(hardened runtime, 보안 타임스탬프). 2-4에서 hardened runtime으로 실행 확인 |
| RL-5 | 공증은 `notarytool submit <zip> --key --key-id --issuer --wait`로 하고, 상태가 Accepted여야 한다. 아니면 `notarytool log`를 출력하고 실패한다 | `release.sh` | 실패(로그 출력) | 설치된 `notarytool` 도움말(Xcode 26.4) |
| RL-6 | 티켓은 `.app`에 붙인다(`stapler`는 zip을 지원하지 않는다). 붙인 뒤 `stapler validate`와 `spctl --assess --type execute`가 통과해야 하고, 그 앱을 다시 zip으로 묶어 첨부한다 | `release.sh` | 실패 | 설치된 `stapler` 도움말 |
| RL-7 | 사전 릴리스 태그는 GitHub prerelease로 만들고 cask를 바꾸지 않는다. 정식 태그만 cask의 `version`과 `sha256`을 바꿔 tap에 push한다 | `release.yml` | | DECISIONS 2026-11-18 |
| RL-8 | 비밀 값은 출력하지 않는다. 키와 인증서 파일은 `$RUNNER_TEMP`에만 쓰고, 임시 키체인과 함께 마지막 단계(`if: always()`)에서 지운다 | `release.yml` | | 공개 저장소 원칙 |
| RL-9 | 워크플로 권한은 `contents: write`(릴리스 생성)만 준다. tap 저장소에는 `TAP_TOKEN`으로만 쓴다 | `release.yml` | | 최소 권한 |
| RL-10 | 같은 태그로 이미 릴리스가 있으면 덮어쓰지 않고 실패한다 | `release.yml` | 실패 | 재현성 |
| RL-11 | 아이콘은 `scripts/make-icon.swift`로 만들고, 그 결과 `Resources/AppIcon.icns`를 커밋한다. SF Symbols를 쓰지 않는다 | 아이콘 | | Apple SF Symbols 약관 |
| RL-12 | 앱 자체에는 여전히 네트워크 코드가 없다. 네트워크는 CI와 사용자의 Homebrew만 쓴다 | 앱 | CI 검사 | 반목표 3 |

## 2. 검증 규칙

| 입력 | 규칙 | 실패 메시지 |
|---|---|---|
| 태그 | `^v\d+\.\d+\.\d+(-rc\.\d+)?$` | "Tag must look like v1.2.3 or v1.2.3-rc.1" |
| 비밀 값 | 다섯 개(사전 릴리스) 또는 여섯 개(정식, `TAP_TOKEN` 포함)가 모두 있다 | 없는 이름을 출력하고 실패 |
| 서명 ID | 가져온 키체인에 "Developer ID Application" 인증서가 정확히 하나 있다 | 실패 |

## 3. 권한 / 접근 규칙

- 인증서, API 키, 토큰을 만드는 일과 GitHub 비밀 값을 등록하는 일은 사용자가 한다. 작업자(AI)는 비밀 값을 보거나 입력하지 않는다.
- `bingoring/homebrew-tap` 공개 저장소 생성은 승인 게이트에서 사용자가 확인한 뒤 한다.

## 4. 불변식

- INV1: 첨부한 zip의 SHA-256 = 릴리스 본문의 값 = (정식이면) cask의 `sha256`.
- INV2: 첨부한 앱은 `spctl`에서 "source=Notarized Developer ID"로 판정된다.
- INV3: 같은 커밋에서 다시 빌드한 앱의 `CFBundleShortVersionString`과 `CFBundleVersion`은 같다.

## 5. 엣지케이스

| 케이스 | 기대 동작 |
|---|---|
| 공증 거절(Invalid) | 로그를 출력하고 릴리스를 만들지 않음 |
| 공증이 오래 걸림 | `--timeout 30m`에서 실패. 다시 실행해도 같은 태그로 진행 가능(릴리스가 아직 없으므로) |
| `TAP_TOKEN` 없음(정식 태그) | 릴리스는 만들고 cask 단계에서 실패해 알림 |
| 사전 릴리스 | prerelease, cask 그대로 |
| Intel Mac | 유니버설이라 실행됨(실기 확인은 하지 않음) |
