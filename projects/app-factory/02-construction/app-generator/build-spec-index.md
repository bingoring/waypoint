---
build-spec: app-generator
stage: 02-construction/02-app-generator
status: READY
depth: standard
updated: 2026-10-13
---

# Build Spec — App Generator + Release Pipeline

## §0. 개요 & 범위
- **목표(한 줄):** `factory_cli`(new·codegen·validate·keystore·size·firebase) + fastlane lane + `release.yml`로, 새 앱 생성부터 Play 내부 테스트 업로드 직전까지 자동화한다.
- **SoT:** 1-2 §0·§2(AppConfig), 1-3 §3·§6·§7·§8, 2-1 Build Spec(`AppConfigValidator`, `core_demo`의 Gradle·매니페스트 구성), DECISIONS(Smallmatter, `app.smallmatter.<slug>`).
- **규모/제약:** 앱 수십 개. 생성·검증은 오프라인으로 동작해야 하고, 업로드만 네트워크·자격 증명이 필요하다. Play 계정이 없는 지금은 업로드를 실행할 수 없다.
- **깊이 티어 & 사유:** `standard` — 도구 코드이며 런타임 위험은 낮다. 다만 applicationId·서명은 비가역이므로 규칙(BR)을 촘촘히 둔다.

## §1. 분해

| 단위 | 책임 | 의존 | 신규 |
|---|---|---|---|
| `tools/factory_cli` | Dart CLI. `new`·`codegen`·`validate`·`keystore`·`size` 명령 | factory_core(검증기 재사용), `yaml`, `args` | 신규 |
| 앱 템플릿 | `tools/factory_cli/templates/app/` — pubspec, main, 빈 홈, 설정 예시, Gradle·매니페스트, store 골격 | — | 신규 |
| `fastlane/Fastfile` | `internal` lane: AAB + 등록 정보 → Play 내부 테스트 트랙 | fastlane `supply` | 신규 |
| `.github/workflows/release.yml` | 태그 `<slug>-v<semver>` → 해당 앱만 빌드·검사·업로드 | factory_cli, fastlane | 신규 |
| `ci.yml` 확장 | 모든 앱 `validate` + 생성기 테스트 | factory_cli | 기존 수정 |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | N/A | 화면을 만들지 않는다. 템플릿의 홈·설정은 자리표시자이며 2-1 부품을 배치만 한다 |

## §3. 미해결 질문

- [x] Q1: Firebase 프로젝트 생성 → **firebase CLI 자동화**(`factory firebase <slug>`, 오너가 `firebase login` 1회). AI 기본안(콘솔 수동)과 다름 → DECISIONS
- [x] Q2: 개인정보처리방침 → **GitHub Pages + `smallmatter.app`**(공개 저장소, 설정은 3-1). R-VAL-3 유지
- [x] Q3: `READY` 승인 (2026-10-13, 오너)

## §4. 구현 체크리스트

- [ ] 로컬 도구: fastlane, bundletool 설치 (Homebrew)
- [ ] `tools/factory_cli` 패키지 + `bin/factory.dart` + workspace 등록(`tools/*`)
- [ ] `app.yaml` 파서 → `AppConfig`·`AppManifest`용 값 (DE §2) + 스키마 오류 보고
- [ ] `codegen`: `lib/generated/app_config.g.dart`, `android/factory.properties` (BLM §1.2)
- [ ] `new`: 템플릿 복사·치환, 시드 색 제안(색상환 30° 규칙), `flutter create`로 android 골격 생성 후 패치 (BLM §1.1)
- [ ] `validate`: 검증기 + 테스트 ID·권한·이벤트·store 골격 검사 (BR §1, BLM §1.3)
- [ ] `keystore`: 앱별 업로드 키 생성, 저장소 밖 저장, base64 출력 (BLM §1.4)
- [ ] `size`: bundletool로 다운로드 크기 측정, 예산 비교 (BR R-SIZE)
- [ ] `firebase`: 프로젝트 생성·앱 등록·`google-services.json`·`app.yaml` 갱신 (BLM §1.6, BR R-FB)
- [ ] 템플릿 Gradle: `google-services.json`이 있을 때만 google-services·Crashlytics 플러그인 적용
- [ ] 템플릿 Gradle: `factory.properties` 읽기, R8, 서명 설정, 난독화 (BR R-BLD)
- [ ] `fastlane/Fastfile` `internal` lane
- [ ] `release.yml`, `ci.yml` 확장
- [ ] 단위 테스트: 파서·codegen·validate·시드 색·버전 코드
- [ ] 생성 리허설: `factory new sandbox` → 릴리스 AAB → validate·size 통과 → 삭제(커밋하지 않음)

## §5. 검증 계획

- [ ] `melos run analyze`·`format:check`·`deps:check` 통과(생성된 앱 포함)
- [ ] 단위 테스트(`tools/factory_cli/test`)
- [ ] 리허설: 생성 → `codegen` → `flutter build appbundle --release --obfuscate --split-debug-info` → `validate --release` → `size` 통과
- [ ] 생성 직후 앱이 2-1 의존 규칙(R-ARCH)과 권한 허용 목록을 통과
- [ ] 음성 테스트: 테스트 광고 ID가 남은 릴리스, 허용 목록에 없는 권한, 크기 초과 → 각각 `validate`·`size`가 실패
- [ ] fastlane `internal` lane은 **자격 증명 없이 실행했을 때 업로드 전 단계에서 명확한 오류**로 멈춘다(실제 업로드는 3-1)

## §6. NFR · 성능
N/A (standard 티어). 성능 목표는 1-3 §7.4·2-1 G1을 생성 앱의 `size` 검사로 집행한다.

## §7. 편차 로그 — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
|  |  |  |
