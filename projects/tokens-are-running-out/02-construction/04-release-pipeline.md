---
phase: 02-construction
stage: 04-release-pipeline
status: AI_PROPOSED
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
1. **Developer ID Application 인증서:** Xcode ▸ Settings ▸ Accounts ▸ 팀 선택 ▸ Manage Certificates… ▸ + ▸ Developer ID Application. 키체인 접근에서 그 인증서를 개인 키와 함께 .p12로 내보내고 암호를 정한다.
2. **App Store Connect API 키:** App Store Connect ▸ Users and Access ▸ Integrations ▸ Team Keys ▸ +, 접근 권한 Developer. .p8은 한 번만 내려받을 수 있다. 키 ID와 발급자 ID를 적어 둔다.
3. **tap 토큰:** tap 저장소를 만든 뒤 GitHub ▸ Settings ▸ Developer settings ▸ Fine-grained tokens. 저장소는 `bingoring/homebrew-tap`만, 권한은 Contents 읽기·쓰기.
4. **비밀 값 등록:** 저장소 폴더에서 아래를 실행한다. 값은 파일에서 읽거나 입력을 물으므로 화면과 대화에 남지 않는다.

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

- [ ] 2-4 범위와 3-1(정식 첫 공개)의 경계가 맞는가?
- [ ] 공개 저장소 `bingoring/homebrew-tap`을 만들어도 되는가?
- [ ] 시험용 사전 릴리스 `v0.1.0-rc.1`을 공개 저장소에 올려도 되는가(prerelease로 표시됨)?
- [ ] 사용자 작업 1 ~ 4(인증서, API 키, 토큰, 비밀 값 등록)를 해 줄 수 있는가?

## 다음 단계

승인 후 → `STATUS.md` 갱신 → 기능 브랜치 `feature/2-4-release-pipeline`에서 아이콘과 스크립트·워크플로 구현(비밀 값 없이 검증 가능한 부분 먼저) → 사용자 작업 뒤 사전 릴리스로 끝까지 시험 → 독립 리뷰 → PR
