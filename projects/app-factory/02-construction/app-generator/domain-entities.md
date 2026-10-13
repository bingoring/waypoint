---
artifact: domain-entities
build-spec: app-generator
status: DRAFT
updated: 2026-10-13
---

# Domain & Entities — App Generator

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT |
|---|---|---|---|
| `app.yaml` | 앱 설정 원본 | `apps/<slug>/app.yaml` (커밋) | 1-2 §2, 1-3 §8 |
| `app_config.g.dart` | `AppManifest` 상수 코드 | `apps/<slug>/lib/generated/` (커밋, 수정 금지 머리말) | BLM §1.2 |
| `factory.properties` | Gradle이 읽는 값 | `apps/<slug>/android/factory.properties` (커밋) | BLM §1.2 |
| `key.properties` | 업로드 키 위치·비밀번호 | `apps/<slug>/android/key.properties` (**gitignore**) | 1-3 §6 |
| 업로드 키 | 앱별 `.jks` | `~/.smallmatter/keys/<slug>.jks` (저장소 밖) | 1-3 §6 |
| store 골격 | 등록 정보 원본 | `apps/<slug>/store/` (커밋) | 1-1 P4, 1-3 §7.3 |

## 2. `app.yaml` 스키마

1-2 §2 표의 필드명을 YAML 키로 그대로 쓴다. 앱 코드에서 정하는 값(placement·대표 행동·이벤트)도 이 파일에 둬서 `codegen`이 `AppManifest`를 통째로 만든다.

```yaml
slug: lotto                       # ^[a-z][a-z0-9_]{2,24}$
category: fun                     # game | fun | calculator | tool | tracker
displayName: {ko: 로또 번호 생성기}
locales: [ko]
defaultLocale: ko
version: 1.0.0                    # versionCode는 파이프라인이 붙인다 (BR R-VER)
android:
  applicationId: app.smallmatter.lotto   # 생성기가 slug로 채운다. 출시 후 변경 금지
ios:
  bundleId: null
admob:
  appId: {android: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX}
  units:                          # 키 = placement id. 생성 직후에는 비어 있고 출시 전 채운다
    banner_home: {android: ca-app-pub-…/…}
placements:                       # AdPlacement 선언
  - {id: banner_home}
  - {id: interstitial_generate, everyN: 3}
  - {id: rewarded_analysis, grantOnUnavailable: true}
keyAction: generate_numbers
events: [save_history, scan_qr]   # 앱 이벤트 (≤ 10)
iap: {removeAdsProductId: remove_ads}
design: {seedColor: "#3F51B5", brightness: system, cornerRadius: 16, density: comfortable, iconStyle: rounded}
links:
  privacyPolicyUrl: https://smallmatter.app/lotto/privacy
  supportEmail: help@smallmatter.app
audience: {minAge: 13}
permissions: []                   # 광고 SDK의 INTERNET·AD_ID·ACCESS_NETWORK_STATE는 자동 허용 (BR R-PERM-2)
firebase: {projectId: null}       # null이면 Firebase 비활성 (Q1)
remoteDefaults: {}
```

- `placements[].format`은 쓰지 않는다. id 접두사(`banner_`·`interstitial_`·`rewarded_`·`app_open`)에서 유도한다(1-2 §4 명명 규칙).
- `design.seedColor`는 `#RRGGBB` 문자열로 받아 ARGB `0xFFRRGGBB`로 바꾼다.

## 3. 생성 결과 파일

| 파일 | 내용 | 생성 명령 | 사람이 수정? |
|---|---|---|---|
| `pubspec.yaml` | `resolution: workspace`, factory_* 의존, `flutter_localizations` | new | 의존성 추가만 |
| `lib/main.dart` | `runFactoryApp(App(), adapters: …)` | new | 아니오 |
| `lib/app.dart` | `AppDefinition` 구현, `MaterialApp`, 테마·지역화·라우트 관찰자 연결 | new | 예 |
| `lib/ui/home_page.dart` | 빈 자리표시자 + `BannerSlot` | new | 예(앱마다 새로 설계) |
| `lib/ui/settings_page.dart` | 설정 부품 6종 배치 예시 | new | 예 |
| `lib/domain/`, `lib/data/` | 빈 디렉터리(`.gitkeep`) | new | 예 |
| `lib/generated/app_config.g.dart` | `final AppManifest appManifest = AppManifest(...)` | codegen | **아니오** |
| `android/factory.properties` | `applicationId`, `admobAppId`, `versionName` | codegen | **아니오** |
| `android/app/build.gradle.kts` | properties 읽기, SDK 24/36, R8, 서명 | new | 드물게 |
| `android/app/src/main/AndroidManifest.xml` | AdMob 앱 ID placeholder, `allowBackup` 설정 | new | 권한 추가 시 |
| `android/app/src/main/res/xml/network_security_config.xml` | 평문 HTTP 금지 | new | 아니오 |
| `store/listing/{ko,en}/` | `title.txt`·`short_description.txt`·`full_description.txt` **빈 파일** | new | 예(필수) |
| `store/data-safety.md` | 데이터 보안 양식 답변 골격(SDK 수집 항목 미리 기재) | new | 예 |
| `test/app_smoke_test.dart` | 부트스트랩 → 홈 렌더링 | new | 예 |

## 4. 열거형 / Allowed-set

| 이름 | 값 |
|---|---|
| CLI 명령 | `new`, `codegen`, `validate`, `keystore`, `size` |
| 기본 허용 권한 (광고·네트워크) | `android.permission.INTERNET`, `android.permission.ACCESS_NETWORK_STATE`, `com.google.android.gms.permission.AD_ID` |
| 플러그인이 추가하지만 허용하는 권한 | `android.permission.WAKE_LOCK`(Firebase), `com.android.vending.BILLING`(결제). 그 밖의 권한은 `app.yaml.permissions`에 선언해야 한다(목록은 구현 시 실제 병합 매니페스트로 확정하고 편차 로그에 기록) |
| 크기 예산 (다운로드) | 카테고리 `game` 25MB, 그 외 15MB (1-3 §7.4) |
