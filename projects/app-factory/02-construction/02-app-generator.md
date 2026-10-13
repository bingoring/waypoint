---
phase: 02-construction
stage: 02-app-generator
status: IN_PROGRESS
updated: 2026-10-13
---

# [Stage 2-2] App Generator + Release Pipeline

## 목적

`app.yaml` 하나로 새 앱 프로젝트를 만들고(`factory_cli new`), 설정을 코드·Gradle 값으로 생성하며(`codegen`), 출시 전 검사(`validate`·크기·권한)를 거쳐
서명된 AAB를 Play 내부 테스트 트랙에 올리는 파이프라인(fastlane + GitHub Actions)을 만든다. 1-1 성공 기준 "2번째 앱부터 제출까지 3일 이하"의 기반이다.

## 입력 (Inputs)

- [`../01-inception/02-domain-model.md`](../01-inception/02-domain-model.md) §0 경계 원칙, §2 AppConfig (+ 1-3 §8 계약 확장)
- [`../01-inception/03-architecture-decision.md`](../01-inception/03-architecture-decision.md) §3 구조, §6 빌드·배포·서명, §7 품질 기준 (+ 승인 결과 F1~F3, 2-1 G1)
- [`01-core-packages.md`](01-core-packages.md) — 2-1 산출물(`AppConfigValidator`, `examples/core_demo` 구성)
- [`../DECISIONS.md`](../DECISIONS.md) — 스튜디오명 Smallmatter, 앱 ID `app.smallmatter.<slug>`

## 체크리스트

- [x] Build Spec 작성 — [`app-generator/build-spec-index.md`](app-generator/build-spec-index.md) (standard)
- [ ] Build Spec 미해결 질문 해소 → `READY` 승인
- [ ] 구현 (Build Spec §4)
- [ ] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

설계의 큰 틀은 1-2·1-3에서 승인되었다. 이 스테이지의 핵심 선택은 다음과 같다(상세는 Build Spec).

1. **`app.yaml`이 유일한 진실 공급원이다.** `codegen`이 Dart 상수(`lib/generated/app_config.g.dart`)와 Gradle 값(`android/factory.properties`: applicationId,
   AdMob 앱 ID, 버전)을 함께 만든다. 사람이 Gradle이나 매니페스트에 ID를 직접 쓰지 않으므로 두 곳이 어긋날 수 없다.
2. **생성기는 "빈 앱 + 코어 연결"만 만든다** (1-2 §0, P3). 홈 화면은 빈 자리표시자, 설정 화면은 부품만 배치한 최소 예시이며, 레이아웃은 앱마다 사람이 새로 짠다.
   스토어 등록 문구도 **빈 골격**만 만든다(P4: 템플릿 치환 금지).
3. **실제 업로드는 3-1에서 처음 실행한다.** Play 조직 계정이 아직 없으므로 2-2의 검증은 "서명된 릴리스 AAB 생성 → 권한·크기·테스트 ID 검사 → fastlane 업로드 직전"까지다.
4. **앱별 비밀 값은 저장소 밖에 둔다.** 업로드 키는 `~/.smallmatter/keys/`(로컬)와 GitHub 암호화 시크릿, 원본은 오너의 비밀번호 관리자에 둔다(1-3 §6).

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec이 `READY`로 승인되었는가? (구현 착수 승인)
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

승인 후 → `STATUS.md`에서 2-2 상태를 `HUMAN_APPROVED`로 업데이트 → 2-3 로또 번호 생성기
