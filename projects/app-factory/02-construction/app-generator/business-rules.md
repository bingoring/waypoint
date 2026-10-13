---
artifact: business-rules
build-spec: app-generator
status: DRAFT
updated: 2026-10-13
---

# Business Rules — App Generator

> `(AI)`는 이 Build Spec에서 AI가 정한 세부값이며 `READY` 승인 시 확정된다.

## 1. 규칙 표

| ID | 규칙 | 위반 시 |
|---|---|---|
| R-GEN-1 | `new <slug>`는 `apps/<slug>`가 이미 있으면 아무것도 쓰지 않고 실패한다 | 종료 코드 1 |
| R-GEN-2 | applicationId는 `app.smallmatter.<slug>`로 생성한다. 기존 앱의 applicationId와 겹치면 실패 | 종료 코드 1 |
| R-GEN-3 | 시드 색: 기존 앱들의 시드 색과 색상환 거리(hue) ≥ 30°인 값을 제안한다. 12번 시도해도 없으면 가장 먼 값을 쓰고 경고 `(AI)` | 경고 |
| R-GEN-4 | 생성기는 store 문구를 채우지 않는다(빈 파일). `validate --release`는 빈 문구를 실패로 본다 (P4) | 릴리스 검사 실패 |
| R-CG-1 | `codegen` 결과는 결정적이다: 같은 `app.yaml` → 바이트 단위로 같은 파일. 머리말에 "생성 파일, 수정 금지"와 원본 경로 | — |
| R-CG-2 | `validate`는 `app.yaml`로 다시 만든 결과와 커밋된 생성 파일을 비교해 다르면 실패한다("codegen을 다시 실행하라") | 종료 코드 1 |
| R-VAL-1 | `AppConfigValidator`(2-1) 전 항목 + YAML 스키마 오류(알 수 없는 키, 타입 불일치) | 종료 코드 1, 문제 전부 출력 |
| R-VAL-2 | `--release`: `admob.appId`와 모든 단위 ID가 채워져 있고, 테스트 게시자 ID(`ca-app-pub-3940256099942544`)가 없어야 한다 (R-ADS-3) | 실패 |
| R-VAL-3 | `--release`: `links.privacyPolicyUrl`이 `https://smallmatter.app/` 아래여야 한다 `(AI: 개인정보처리방침은 스튜디오 도메인에 앱별 페이지로 둔다)` | 실패 |
| R-PERM-1 | `--release`: 병합된 릴리스 매니페스트의 `uses-permission` ⊆ (기본 허용 ∪ 플러그인 허용 ∪ `app.yaml.permissions`) | 실패, 초과 권한 목록 출력 |
| R-PERM-2 | `SCHEDULE_EXACT_ALARM`·`USE_EXACT_ALARM`·`QUERY_ALL_PACKAGES`·`READ_PHONE_STATE`는 `app.yaml`에 선언해도 실패 (1-3 §7.3) | 실패 |
| R-SIZE | `size`: `bundletool get-size total`의 최대 다운로드 크기 ≤ 카테고리 예산 (DE §4) | 실패 |
| R-BLD-1 | 릴리스 빌드: `minifyEnabled`·`shrinkResources` true, Flutter `--obfuscate --split-debug-info=build/symbols/<slug>` | 템플릿으로 고정 |
| R-BLD-2 | 릴리스 서명은 `key.properties`(로컬) 또는 환경 변수(CI)로만 한다. 둘 다 없으면 **릴리스 빌드 실패**(디버그 키로 대체하지 않는다) | Gradle 실패 |
| R-BLD-3 | `android:allowBackup="false"`(앱 데이터는 로컬 설정·기록뿐이고 계정이 없다) `(AI)`, `usesCleartextTraffic` 금지(network security config) | 템플릿으로 고정 |
| R-VER | versionCode = GitHub Actions `run_number` + 1000 `(AI)`. 저장소 전체에서 단조 증가하며 앱별로 번호가 건너뛰어도 된다(Play는 증가만 요구). 로컬 빌드는 1 | — |
| R-KEY-1 | `keystore <slug>`: `~/.smallmatter/keys/<slug>.jks`가 이미 있으면 덮어쓰지 않는다. 비밀번호는 무작위 32자, 파일 권한 600 | 실패 |
| R-KEY-2 | 키·비밀번호를 표준 출력에 그대로 찍지 않는다. GitHub 시크릿 등록용 base64는 파일로 쓰고 경로만 출력한다 | — |
| R-REL-1 | 릴리스 태그 `<slug>-v<x.y.z>`의 버전은 `app.yaml.version`과 같아야 한다 | 워크플로 실패 |
| R-REL-2 | 업로드 트랙은 **internal만**. 프로덕션 승격은 사람이 Play Console에서 한다 (1-3 §6, P5) | lane에 트랙 인자 없음 |

## 2. 검증 규칙 (`app.yaml` 스키마)

| 입력 | 규칙 | 오류 코드 |
|---|---|---|
| 최상위 키 | 허용 목록 외 키 금지 | `YAML_UNKNOWN_KEY` |
| `placements[].id` | 2-1 R-ADS-1 | `CFG_PLACEMENT` |
| `design.seedColor` | `^#[0-9A-Fa-f]{6}$` | `CFG_DESIGN` |
| `events[]` | 문자열 배열, ≤ 10 | `CFG_EVENTS` |
| 그 밖 | 2-1 `AppConfigValidator` 오류 코드 그대로 | `CFG_*` |

## 3. 권한 / 접근

| 액션 | 허용 |
|---|---|
| Play 업로드 | CI의 `release.yml`만(서비스 계정 시크릿). 로컬 업로드는 `fastlane internal` 수동 실행 시 오너 자격 증명으로 |
| 업로드 키 접근 | 오너 로컬, GitHub 시크릿 `UPLOAD_KEY_<SLUG>_B64`·`UPLOAD_KEY_<SLUG>_PASSWORD` |

## 4. 불변식

- INV-GEN-1: 커밋된 모든 앱에서 `codegen` 결과 = 커밋된 생성 파일 (R-CG-2).
- INV-GEN-2: applicationId는 앱마다 유일하고 `app.smallmatter.` 접두사를 가진다.
- INV-GEN-3: 저장소에 `.jks`·`key.properties`·서비스 계정 JSON이 없다(gitleaks + `.gitignore`).

## 5. 엣지케이스

| 케이스 | 기대 동작 |
|---|---|
| 단위 ID가 비어 있는 새 앱의 디버그 빌드 | 디버그는 테스트 ID로 치환되므로 빌드·실행 가능. `validate`(비릴리스)는 통과, `--release`는 실패 |
| `app.yaml`에서 placement를 지웠는데 `admob.units`에 남음 | `CFG_UNITS_MISMATCH` (2-1 R-CFG-6) |
| `flutter create` 실패(네트워크·SDK) | 생성 중인 디렉터리를 지우고 실패 |
| 같은 날 같은 앱을 두 번 릴리스 | versionCode는 run_number 기반이라 충돌 없음 |
