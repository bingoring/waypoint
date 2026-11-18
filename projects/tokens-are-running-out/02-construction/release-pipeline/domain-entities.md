---
artifact: domain-entities
build-spec: release-pipeline
status: READY
updated: 2026-11-18
---

# Domain & Entities — 릴리스 파이프라인 (서명 · 공증 · Homebrew tap)

> 앱 코드에는 새 엔티티가 없다. 이 문서는 릴리스 한 번이 만들고 읽는 값과 그 형식을 정한다.

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT 출처 |
|---|---|---|---|
| `ReleaseTag` | 릴리스를 시작하는 git 태그 | GitHub 저장소 | design 9장, DECISIONS 2026-11-18 |
| `AppVersion` | 앱 번들의 버전 값 | `Info.plist` | Apple 번들 키 규칙 |
| `ReleaseAsset` | 공증하고 티켓을 붙인 앱의 zip | GitHub Release 첨부 파일 | DECISIONS 2026-11-18(zip) |
| `Cask` | Homebrew cask 정의 | `bingoring/homebrew-tap`의 `Casks/tokens-are-running-out.rb` | design 9장, Homebrew Cask Cookbook |
| `ReleaseSecrets` | 서명·공증·tap 갱신에 쓰는 GitHub 비밀 값 | 앱 저장소의 Actions secrets | DECISIONS 2026-11-18(API 키) |
| `AppIcon` | 앱 아이콘 | `Resources/AppIcon.icns`(생성물, 생성 스크립트와 함께 커밋) | DECISIONS 2026-11-18(아이콘) |

## 2. 엔티티 상세

### `ReleaseTag`
- 형식: `v<major>.<minor>.<patch>`(정식) 또는 `v<major>.<minor>.<patch>-rc.<n>`(사전 릴리스).
- 예: `v0.1.0-rc.1`, `v0.1.0`.

### `AppVersion`
| 키 | 값 | 예 |
|---|---|---|
| `CFBundleShortVersionString` | 태그의 `<major>.<minor>.<patch>`(사전 릴리스 접미사 없이. 이 키는 숫자와 점만 받는다) | `0.1.0` |
| `CFBundleVersion` | 태그 커밋까지의 커밋 수(`git rev-list --count`). 늘 증가한다 | `57` |
| `CFBundleIconFile` | `AppIcon` | |

### `ReleaseAsset`
| 필드 | 값 |
|---|---|
| 파일 이름 | `TokensAreRunningOut-<태그에서 v를 뺀 값>.zip` (예: `TokensAreRunningOut-0.1.0-rc.1.zip`) |
| 내용 | 유니버설(arm64, x86_64) `TokensAreRunningOut.app` 하나. Developer ID로 서명, hardened runtime, 공증 티켓을 붙임 |
| 체크섬 | SHA-256. 릴리스 본문과 `<파일 이름>.sha256` 첨부 파일에 함께 적는다 |

### `Cask`
```ruby
cask "tokens-are-running-out" do
  version "0.1.0"
  sha256 "<ReleaseAsset의 SHA-256>"

  url "https://github.com/bingoring/tokens-are-running-out/releases/download/v#{version}/TokensAreRunningOut-#{version}.zip"
  name "Tokens Are Running Out"
  desc "Menu bar app that shows why Claude Code usage drained"
  homepage "https://github.com/bingoring/tokens-are-running-out"

  depends_on macos: ">= :sonoma"

  app "TokensAreRunningOut.app"

  zap trash: [
    "~/Library/Application Support/TokensAreRunningOut",
    "~/Library/Preferences/io.github.bingoring.TokensAreRunningOut.plist",
  ]
end
```
- `depends_on macos:`의 표기는 구현할 때 `brew style`과 `brew audit`로 확인한다(공식 문서 예시는 기호 하나 형식만 보여 준다).
- `zap`은 앱이 만드는 파일만 지운다. `~/.claude`는 Claude Code의 데이터라 절대 넣지 않는다.

### `ReleaseSecrets` (앱 저장소 Actions secrets, 사용자가 등록)
| 이름 | 내용 |
|---|---|
| `DEVELOPER_ID_P12_BASE64` | Developer ID Application 인증서와 개인 키를 내보낸 .p12의 base64 |
| `DEVELOPER_ID_P12_PASSWORD` | .p12의 암호 |
| `NOTARY_KEY_P8_BASE64` | App Store Connect API 팀 키(.p8)의 base64 |
| `NOTARY_KEY_ID` | API 키 ID |
| `NOTARY_ISSUER_ID` | API 발급자 ID(UUID) |
| `TAP_TOKEN` | `bingoring/homebrew-tap`에만 contents 쓰기 권한이 있는 fine-grained 토큰. 만료 기한이 있으므로, 만료되면 새로 만들어 다시 등록하고 `update-tap.yml`로 밀린 갱신을 처리한다 |

### `AppIcon`
- 1024pt 캔버스의 macOS 아이콘 격자: 824pt 둥근 사각형 본체(모서리 반경 약 185pt), 바깥 여백 100pt.
- 도형: 모래시계를 경로로 직접 그린다(SF Symbols는 Apple 약관상 앱 아이콘에 쓸 수 없다). 위쪽 모래가 거의 비고 아래쪽에 쌓인 모습으로 "토큰이 바닥나는" 뜻을 담는다.
- 크기: 16, 32, 128, 256, 512pt와 각 @2x를 `iconutil`로 `.icns` 하나로 묶는다.

## 3. 관계

| 좌 | 카디널리티 | 우 | 비고 |
|---|---|---|---|
| `ReleaseTag` | 1─1 | GitHub Release | 사전 릴리스 태그는 prerelease로 |
| GitHub Release | 1─2 | 첨부 파일 | zip과 .sha256 |
| 정식 `ReleaseTag` | 1─1 | `Cask` 갱신 커밋 | 사전 릴리스는 cask를 바꾸지 않는다 |
