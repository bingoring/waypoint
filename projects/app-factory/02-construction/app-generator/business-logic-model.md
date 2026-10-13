---
artifact: business-logic-model
build-spec: app-generator
status: DRAFT
updated: 2026-10-13
---

# Business Logic Model — App Generator

## 1. 워크플로

### 1.1 `factory new <slug> --category <c> --name-ko <이름> [--name-en <name>]`
1. slug 형식·중복 검사(R-GEN-1·2). `--name-en`이 없으면 `locales: [ko]`.
2. 임시 디렉터리에서 `flutter create --org app.smallmatter --project-name <slug> --platforms android --no-pub`.
3. 템플릿(`templates/app/`)을 덮어쓴다: `{{slug}}`·`{{category}}`·`{{nameKo}}`·`{{nameEn}}`·`{{seedColor}}` 치환. 템플릿에 없는 `flutter create` 산출물은 지운다(`test/widget_test.dart`, `analysis_options.yaml`, `README.md`).
4. 시드 색 선택(§2.1).
5. `codegen` 실행(§1.2) → `apps/<slug>`로 이동.
6. 안내 출력: 다음 할 일(홈 화면 설계, store 문구 작성, AdMob 앱·단위 생성 후 `app.yaml` 기입, `keystore`, Firebase 연결(Q1)).

### 1.2 `factory codegen <slug | --all>`
1. `app.yaml` 파싱 → 스키마 검사(BR §2) → `AppConfig`·`AppManifest` 값.
2. `lib/generated/app_config.g.dart` 생성: `AppManifest` 생성자 호출 코드를 키 순서 고정으로 출력 → `dart format` 적용 → 내용이 같으면 쓰지 않는다.
3. `android/factory.properties`: `applicationId=…`, `admobAppId=…`(비었으면 Google 테스트 앱 ID — 디버그용), `versionName=…`.

### 1.3 `factory validate <slug | --all> [--release]`
1. codegen 결과와 커밋 파일 비교(R-CG-2).
2. `AppConfigValidator` + 스키마.
3. `--release`: R-VAL-2·3, store 문구 비어 있지 않음(R-GEN-4), 병합 매니페스트 권한 검사(R-PERM-1·2) — 매니페스트는
   `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`(없으면 "릴리스 빌드 후 실행" 안내와 함께 실패).
4. 결과: 문제 목록 + 종료 코드.

### 1.4 `factory keystore <slug>`
`keytool -genkeypair -alias upload -keyalg RSA -keysize 4096 -validity 10000 -storetype PKCS12` → `~/.smallmatter/keys/<slug>.jks`(600),
`apps/<slug>/android/key.properties`(gitignore) 작성, `~/.smallmatter/keys/<slug>.b64`에 base64 저장, 시크릿 이름 2개를 안내.

### 1.5 `factory size <slug>`
`bundletool build-apks --bundle=… --output=…apks` → `get-size total --apks=…` → 최대값과 예산 비교(R-SIZE).

### 1.6 `factory firebase <slug>`
1. `firebase --version`, `firebase login:list`로 CLI·로그인 확인(R-FB-2).
2. `app.yaml.firebase.projectId`가 없으면 `firebase projects:create <id> --display-name "<이름>"`(R-FB-1), 있으면 3으로.
3. `firebase apps:list ANDROID --project <id>`에 `app.smallmatter.<slug>`가 없으면 `firebase apps:create ANDROID "<이름>" --package-name app.smallmatter.<slug> --project <id>`.
4. `firebase apps:sdkconfig ANDROID <appId> --project <id> -o apps/<slug>/android/app/google-services.json`.
5. `app.yaml`에 `firebase.projectId` 기입 → `codegen`.
6. 안내: AdMob 앱을 이 Firebase 프로젝트에 연결(AdMob 콘솔, 수동), 프로젝트 수가 5개를 넘으면 Blaze 전환(1-3 §5).

## 2. 알고리즘

### 2.1 시드 색 선택
```
hues = 기존 apps/*/app.yaml의 seedColor → HSV hue
for k in 0..11: cand = (해시(slug) * 37 + k * 30) mod 360
   if min_distance(cand, hues) ≥ 30 → return HSV(cand, 0.55, 0.75)
return 가장 먼 cand (+경고)
```
거리 = `min(|a-b|, 360-|a-b|)`. 결정적이어야 한다(같은 slug·같은 기존 앱 → 같은 색).

## 3. 릴리스 시퀀스 (`release.yml`)

```
push tag lotto-v1.0.0
 → slug·버전 추출, app.yaml.version 일치 확인 (R-REL-1)
 → Flutter 설치(.fvmrc), pub get, factory codegen lotto, factory validate lotto
 → 업로드 키 복원(시크릿 → $RUNNER_TEMP, key 값은 환경 변수)
 → flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/lotto
     --build-number=$((1000 + run_number))
 → factory validate lotto --release, factory size lotto
 → (firebase 설정 시) Crashlytics 심볼 업로드
 → fastlane internal app:lotto  → Play 내부 테스트 트랙
 → 아티팩트로 AAB·심볼 보관(30일)
```

## 4. 통합 지점

| 대상 | 시점 | 실패 처리 |
|---|---|---|
| `flutter create` | new | 생성 디렉터리 삭제 후 실패 |
| `keytool` | keystore | 실패, 부분 파일 삭제 |
| `bundletool` | size | 미설치면 설치 안내와 함께 실패 |
| Play Developer API (fastlane supply) | release | 실패 시 워크플로 실패, 재시도는 수동 |
| Firebase CLI(심볼 업로드) | release | `firebase.projectId`가 없으면 건너뜀 |
