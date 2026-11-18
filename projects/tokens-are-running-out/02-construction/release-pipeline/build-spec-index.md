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

- [ ] 아이콘 생성 스크립트와 `.icns`, `build-app.sh`가 아이콘을 넣음. 아이콘을 better-ui·better-colors로 검토
- [ ] `build-app.sh --release <version>`(유니버설, 버전 키)
- [ ] `release.sh`(서명·검증·공증·티켓·zip·체크섬). 비밀 값 없이 ad-hoc으로 도는 `--dry-run`
- [ ] `update-cask.sh`와 cask 템플릿. `brew style`로 문법 확인
- [ ] `release.yml`(형식 확인, 키체인, 정리 단계 포함)
- [ ] README 설치·릴리스 안내
- [ ] (사용자) Developer ID Application 인증서, App Store Connect API 키, tap 토큰을 만들고 비밀 값 등록
- [ ] (사용자 확인 후) `bingoring/homebrew-tap` 생성
- [ ] 사전 릴리스 `v0.1.0-rc.1`로 끝까지 시험: 공증 Accepted, 첨부 zip을 받아 `spctl`·`stapler validate`·실행
- [ ] 독립 리뷰와 반영
- [ ] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획

- [ ] 엄격 빌드, 린트, 전체 테스트(앱 코드 변경 없음을 확인)
- [ ] `release.sh --dry-run`: ad-hoc 서명에 hardened runtime, `codesign --verify --strict --deep` 통과, 유니버설(`lipo -archs`), 버전 키, 아이콘 포함
- [ ] 생성한 cask가 `brew style`을 통과
- [ ] `v0.1.0-rc.1` 사전 릴리스: 워크플로 성공, 공증 Accepted, 내려받은 앱이 `spctl`에서 "source=Notarized Developer ID", `stapler validate` 통과, 실행됨. cask는 바뀌지 않음
- [ ] 워크플로 로그와 저장소에 비밀 값이 나타나지 않음
- [ ] 정식 `v0.1.0` 릴리스와 `brew install --cask`는 3-1(첫 공개)에서 한다

## §6. NFR

N/A(standard). 릴리스 한 번이 30분 안에 끝나면 된다(공증 대기 포함).

## §7. 편차 로그 — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
