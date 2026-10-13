---
build-spec: app-generator
stage: 02-construction/02-app-generator
status: IMPLEMENTED
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

- [x] 로컬 도구: fastlane, bundletool 설치 (Homebrew)
- [x] `tools/factory_cli` 패키지 + `bin/factory.dart` + workspace 등록(`tools/*`)
- [x] `app.yaml` 파서 → `AppConfig`·`AppManifest`용 값 (DE §2) + 스키마 오류 보고
- [x] `codegen`: `lib/generated/app_config.g.dart`, `android/factory.properties` (BLM §1.2)
- [x] `new`: 템플릿 복사·치환, 시드 색 제안(색상환 30° 규칙), `flutter create`로 android 골격 생성 후 패치 (BLM §1.1)
- [x] `validate`: 검증기 + 테스트 ID·권한·이벤트·store 골격 검사 (BR §1, BLM §1.3)
- [x] `keystore`: 앱별 업로드 키 생성, 저장소 밖 저장, base64 출력 (BLM §1.4)
- [x] `size`: bundletool로 다운로드 크기 측정, 예산 비교 (BR R-SIZE)
- [x] `firebase`: 프로젝트 생성·앱 등록·`google-services.json`·`app.yaml` 갱신 (BLM §1.6, BR R-FB)
- [x] 템플릿 Gradle: `google-services.json`이 있을 때만 google-services·Crashlytics 플러그인 적용
- [x] 템플릿 Gradle: `factory.properties` 읽기, R8, 서명 설정, 난독화 (BR R-BLD)
- [x] `fastlane/Fastfile` `internal` lane
- [x] `release.yml`, `ci.yml` 확장
- [x] 단위 테스트: 파서·codegen·validate·시드 색·버전 코드
- [x] 생성 리허설: `factory new sandbox` → 릴리스 AAB → validate·size 통과 → 삭제(커밋하지 않음)

## §5. 검증 계획

- [x] `melos run analyze`·`format:check`·`deps:check` 통과(생성된 앱 포함)
- [x] 단위 테스트(`tools/factory_cli/test`) — 22개
- [x] 리허설: 생성 → `codegen` → `flutter build appbundle --release --obfuscate --split-debug-info` → `validate --release` → `size` 통과 — sandbox 앱: 분석 0·스모크 테스트 통과, 서명 AAB 생성, 다운로드 크기 10.11MB/15MB, 권한 검사 통과. `validate --release`는 의도한 미완성 항목(테스트 ID·빈 문구·자리표시자)만 보고 (2026-10-13)
- [x] 생성 직후 앱이 2-1 의존 규칙(R-ARCH)과 권한 허용 목록을 통과
- [x] 음성 테스트: 테스트 광고 ID가 남은 릴리스, 허용 목록에 없는 권한, 크기 초과 → 각각 `validate`·`size`가 실패 — 단위 테스트 + 리허설(실제 `FOREGROUND_SERVICE` 검출), 업로드 키 없는 릴리스 빌드 실패(R-BLD-2) 확인
- [x] fastlane `internal` lane은 **자격 증명 없이 실행했을 때 업로드 전 단계에서 명확한 오류**로 멈춘다(실제 업로드는 3-1)

## §6. NFR · 성능
N/A (standard 티어). 성능 목표는 1-3 §7.4·2-1 G1을 생성 앱의 `size` 검사로 집행한다.

## §7. 편차 로그 — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| DE §4 허용 권한 목록 | 실제 병합 매니페스트로 확정: INTERNET·ACCESS_NETWORK_STATE·WAKE_LOCK·AD_ID·ACCESS_ADSERVICES_{AD_ID,ATTRIBUTION,TOPICS}·BILLING·BIND_GET_INSTALL_REFERRER_SERVICE·`<applicationId>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | 리허설 빌드의 병합 매니페스트에서 확인 |
| (신규) 템플릿 매니페스트 | 광고 SDK가 끌어오는 `androidx.work:work-runtime:2.7.0`의 `FOREGROUND_SERVICE` 권한과 `SystemForegroundService`를 `tools:node="remove"`로 제거 | 쓰지 않는 포그라운드 서비스 때문에 Play 포그라운드 서비스 신고 대상이 되는 것을 막는다(1-3 §7.3). 리허설에서 권한 검사가 검출 |
| (신규) 화면 자리표시자 검사 | 템플릿 홈 화면에 `FACTORY_PLACEHOLDER` 표식, `validate --release`가 남아 있으면 실패 | P3: 생성된 빈 화면이 그대로 출시되는 것을 막는다 |
| (신규) `admob` 빈 값 | 비어 있으면 Google 테스트 ID로 채워 디버그 빌드가 되게 하고, `--release`에서 `REL_TEST_IDS`로 실패 | 새 앱은 AdMob 단위를 만들기 전에도 개발할 수 있어야 한다 |
| BLM §3 Crashlytics 심볼 업로드 | `release.yml`에 아직 없음. 심볼은 아티팩트로 30일 보관 | Firebase 프로젝트가 생긴 뒤(2-3) 업로드 단계를 추가한다 |
| R-KEY-2 | `keytool` 비밀번호를 명령줄 인자가 아니라 `-storepass:env`로 전달 | 실행 중 프로세스 목록에 비밀번호가 보이지 않게 한다 |
| (참고) 빌드 경고 | 일부 플러그인이 AGP 9 내장 Kotlin을 아직 지원하지 않는다는 경고(빌드는 성공) | 플러그인 갱신 시 사라질 경고. 월간 의존성 갱신 때 확인 |
| §5 `factory firebase` 실제 실행 | 단위 테스트로만 검증. 실제 실행은 2-3(로또 앱의 실제 프로젝트 생성) | 리허설용 프로젝트가 Firebase 프로젝트 한도를 쓰지 않게 한다. 오너의 `firebase login` 필요 |
