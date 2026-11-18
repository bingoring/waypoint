---
artifact: business-logic-model
build-spec: release-pipeline
status: READY
updated: 2026-11-18
---

# Business Logic Model — 릴리스 파이프라인

## 1. 구성

| 파일 | 역할 |
|---|---|
| `scripts/build-app.sh` | (기존) `--release <version>`이면 `generic/platform=macOS`로 Release 유니버설 빌드, `Info.plist`에 버전과 아이콘을 넣는다. 서명은 ad-hoc 그대로(실제 서명은 다음 단계) |
| `scripts/release.sh` | 서명 → zip → 공증 → 티켓 붙이기 → 검증 → 최종 zip과 체크섬. 로컬에서도 같은 순서로 실행할 수 있다(`--identity`, `--notary-key` 등 인자) |
| `scripts/make-icon.swift` | Core Graphics로 아이콘을 그려 `.iconset`을 만들고 `iconutil`로 `Resources/AppIcon.icns`를 만든다 |
| `scripts/update-cask.sh` | 버전과 SHA-256으로 cask 파일을 다시 쓴다(tap 저장소의 작업 사본에서) |
| `.github/workflows/release.yml` | 태그 push에서 위 스크립트를 순서대로 실행하고 GitHub Release를 만든 뒤, 정식 태그면 tap을 갱신 |
| `.github/workflows/update-tap.yml` | 수동 실행(입력: 태그). 이미 있는 릴리스의 `.sha256`에서 버전과 체크섬을 읽어 tap만 갱신(RL-13) |

## 2. 워크플로 (`release.yml`)

1. `on: push: tags: ['v*']`. 저장소가 포크면 종료(RL-2). 태그 형식 확인(RL-1).
2. 비밀 값이 모두 있는지 이름으로만 확인(값은 출력하지 않음). 정식 태그는 `TAP_TOKEN`까지 여섯 개를 빌드 전에 확인한다.
3. 임시 키체인을 만들고(.p12를 `$RUNNER_TEMP`에 base64로 풀어) 가져온다. `security set-key-partition-list`로 `codesign`이 묻지 않고 쓰게 한다. "Developer ID Application" ID가 하나인지 확인.
4. .p8 키를 `$RUNNER_TEMP`에 풀어 쓴다(권한 600).
5. `scripts/build-app.sh --release <version>` → 유니버설 앱.
6. `scripts/release.sh`:
   1. `codesign --force --options runtime --timestamp --sign "Developer ID Application: …" TokensAreRunningOut.app`
   2. `codesign --verify --strict --deep --verbose=2`, `codesign -dvvv`에 `runtime` 플래그 확인
   3. `ditto -c -k --keepParent` → 제출용 zip
   4. `xcrun notarytool submit <zip> --key <p8> --key-id <id> --issuer <issuer> --wait --timeout 30m --output-format json` → 상태가 Accepted인지 확인, 아니면 `notarytool log <id>` 출력 후 실패
   5. `xcrun stapler staple TokensAreRunningOut.app` → `xcrun stapler validate`
   6. `spctl --assess --type execute -vv TokensAreRunningOut.app` → "source=Notarized Developer ID"
   7. 최종 zip(`TokensAreRunningOut-<version>.zip`)과 `.sha256`
7. `gh release create <tag> <zip> <sha256 file> --title "<tag>" --generate-notes` (+ 사전 릴리스면 `--prerelease`). 이미 있으면 실패(RL-10).
8. 정식 태그면: `TAP_TOKEN`으로 tap 저장소를 받아 `scripts/update-cask.sh`로 cask를 고치고 커밋·push(커밋 메시지 `tokens-are-running-out <version>`). 이 단계만 실패하면 `update-tap.yml`로 다시 실행한다.
9. `if: always()`: 임시 키체인 삭제, `$RUNNER_TEMP`의 키·인증서 삭제(RL-8).

## 3. 아이콘 생성 (`make-icon.swift`)

```
for size in [16, 32, 128, 256, 512], scale in [1, 2]:
  canvas = size × scale 픽셀, 1024 격자를 비율로 축소
  본체: 824/1024 둥근 사각형, 위아래 그라데이션(짙은 남색 → 보라)
  모래시계: 위·아래 유리(흰색 92% 불투명), 위쪽 모래 조금, 아래쪽 모래 많이(호박색), 가운데 가는 흐름
  16·32pt는 흐름과 세부를 생략해 형태만
write AppIcon.iconset/icon_<size>x<size>[@2x].png → iconutil -c icns
```

## 4. 상태 전이 (릴리스 한 번)

| 현재 | 이벤트 | 다음 |
|---|---|---|
| 태그 push | 형식·비밀 값 확인 통과 | 빌드 |
| 빌드 | 성공 | 서명 |
| 서명 | 검증 통과 | 공증 |
| 공증 | Accepted | 티켓·검증 |
| 티켓·검증 | 통과 | 릴리스 생성 |
| 릴리스 생성 | 정식 태그 | tap 갱신 |
| 어느 단계든 | 실패 | 정리 후 종료(릴리스 없음 또는 cask 미갱신) |

## 5. 통합 지점

| 대상 | 시점 | 요지 | 실패 처리 |
|---|---|---|---|
| Apple 공증 서비스 | 6.4 | zip 제출, 결과 대기 | 로그 출력 후 실패 |
| GitHub Releases | 7 | 릴리스와 첨부 파일 | 실패 |
| `bingoring/homebrew-tap` | 8 | cask 갱신 커밋 | 실패(릴리스는 남음, 수동 갱신 가능) |
| Homebrew(사용자) | 설치 | cask가 zip을 받아 `/Applications`에 설치, quarantine 속성을 붙임 | Gatekeeper가 공증을 확인 |
