---
phase: 01-inception
stage: 02-domain-model
status: HUMAN_APPROVED
updated: 2026-10-13
---

# [Stage 1-2] Domain Model

## 목적

App Factory의 핵심 데이터 계약을 정의한다: 앱 설정 스키마, 기능 모듈 계약, 광고 정책 모델, 원격 설정 키, 분석 이벤트 스키마.
이 계약이 공통 코어와 개별 앱의 경계가 된다.

## 입력 (Inputs)

- [`01-context-synthesis.md`](01-context-synthesis.md) (HUMAN_APPROVED 필요) — §5 포트폴리오 규칙, §6 공통 모듈 요구사항, §7 Wave 1
- [`../prd.md`](../prd.md)
- [`../DECISIONS.md`](../DECISIONS.md)

## 체크리스트

- [x] `AppConfig` 스키마: 앱 ID, 이름, 패키지 ID, 지원 언어, 광고 단위 ID, 디자인 토큰, 기능 플래그 기본값
- [x] 기능 모듈 계약: 코어가 앱에 제공하는 것 / 앱이 코어에 제공하는 것
- [x] 광고 정책 모델: 형식별 노출 규칙, 빈도 제한, 광고 제거 상태, 디버그 테스트 ID 강제
- [x] 원격 설정 키 체계: 공통 키와 앱별 키의 네임스페이스, 내장 기본값
- [x] 분석 이벤트 스키마: 공통 이벤트, 앱별 이벤트 명명 규칙, 광고 수익 이벤트
- [x] 동의 상태 흐름: UMP·ATT 결과가 광고·분석 초기화에 미치는 영향
- [x] 광고 제거 인앱결제 상품 모델과 가격
- [x] Wave 1 앱 5개를 계약으로 표현할 수 있는지 매핑 검증

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 0. 경계 원칙 — 코어는 "보이지 않는 것"만 소유한다

1-1 P3(보이는 셸 비공유)을 계약 수준에서 강제하기 위해, 코어와 앱의 소유권을 다음처럼 나눈다.

| 구분 | 코어(`packages/`)가 소유 | 앱(`apps/<slug>/`)이 소유 |
|------|------------------------|--------------------------|
| 화면 | **없음.** 화면 단위 위젯(홈, 설정 페이지, 내비게이션)을 제공하지 않는다 | 홈·내비게이션·설정 페이지 레이아웃 전부 |
| 부품 | 의미 단위 위젯만 제공한다: 배너 슬롯, 광고 제거 행, 구매 복원 행, 언어 선택 행, 개인정보 옵션 행. 스타일은 앱 테마를 따른다 | 부품을 어디에 어떻게 배치할지 |
| 로직 | 광고·동의·분석·원격 설정·인앱결제·리뷰 요청·저장소·알림·공유의 초기화와 정책 | 앱 고유 기능, 앱 고유 데이터 |
| 데이터 | `core_*` 원격 설정 키, `core.*` 저장 키, 공통 분석 이벤트 | `app_*` 원격 설정 키, `app.*` 저장 키, 앱 이벤트 |

**결과:** 앱 생성기(2-2)는 "테마만 다른 같은 앱"이 아니라 **빈 홈 화면 + 코어 연결 + 설정 파일**을 만든다. 같은 화면 구조가
두 앱에 생기려면 사람이 의도적으로 복사해야 하므로, 반복 콘텐츠 위험이 구조적으로 줄어든다.

### 1. 엔티티 개요

```
AppConfig (빌드 시점, 앱당 1개, app.yaml)
 ├─ DesignTokens          ─ 앱 테마 생성 입력
 ├─ AdUnitMap             ─ placementId → 광고 단위 ID
 ├─ IapConfig             ─ remove_ads 상품
 └─ RemoteDefaults        ─ app_* 키 내장 기본값

AppDefinition (코드, 앱당 1개)  ──uses──▶  FactoryServices (코어가 주입)
 ├─ placements: AdPlacement[]                 ├─ AdService ── AdPolicy (core_ads_* 키로 조정)
 ├─ keyAction: 대표 행동 이벤트 이름          ├─ ConsentService ── ConsentState
 └─ buildApp(services) → 앱 자체 위젯 트리    ├─ EntitlementService ── Entitlement(ad_free)
                                               ├─ Analytics, RemoteConfig, RatingService
                                               └─ KeyValueStore, Notifications?, Share?
```

### 2. AppConfig — `apps/<slug>/app.yaml`

빌드 시점 설정이다. 앱 생성기가 만들고 사람이 채운다. **비밀 값은 넣지 않는다**(서명 키·스토어 API 키는 CI 시크릿, 1-3).
광고 단위 ID와 Firebase 설정 파일은 비밀은 아니지만 저장소가 비공개이므로(Q8) 함께 커밋한다.

| 필드 | 타입 | 제약 / 허용값 | 예 |
|------|------|--------------|----|
| `slug` | string | `^[a-z][a-z0-9_]{2,24}$`, 포트폴리오 내 유일, 바꾸지 않음 | `lotto` |
| `category` | enum | `game` · `fun` · `calculator` · `tool` · `tracker` (1-1 A~E) | `fun` |
| `displayName` | map<locale,string> | `locales`의 모든 언어에 필수, 30자 이하(Play 제목 한도) | `{ko: 로또 번호 생성기}` |
| `locales` | locale[] | `ko`, `en` 중 1개 이상. 한국 전용 앱은 `[ko]` (Q2) | `[ko]` |
| `defaultLocale` | locale | `locales`에 포함 | `ko` |
| `android.applicationId` | string | `<studioReverseDomain>.<slug>`, 출시 후 변경 불가 | `com.<studio>.lotto` |
| `ios.bundleId` | string? | iOS 확장 시 채움 (Q3) | — |
| `version` | semver | 사람 관리. 빌드 번호는 파이프라인이 자동 증가 | `1.0.0` |
| `admob.appId` | `{android, ios?}` | AdMob 앱 ID | `ca-app-pub-…~…` |
| `admob.units` | map<placementId, `{android, ios?}`> | `AppDefinition.placements`의 모든 ID가 키로 존재해야 함(빌드 검증) | §4 참조 |
| `iap.removeAds.productId` | string | 기본 `remove_ads` | `remove_ads` |
| `design` | DesignTokens | 아래 표 | |
| `links.privacyPolicyUrl` | url | 필수(스토어·UMP 요구) | |
| `links.supportEmail` | email | 필수(스토어 요구) | |
| `audience.minAge` | enum | `13` · `18`. 기본 `13`. **어린이 대상(Families 정책)으로 선언하지 않는다** | `13` |
| `remoteDefaults` | map<string,scalar\|json> | `app_` 접두사 키만 허용 | §5 참조 |

**DesignTokens** — 앱마다 다른 값을 강제하기 위해 시드 색 하나로 끝내지 않고 형태 요소까지 넣는다.

| 필드 | 허용값 |
|------|-------|
| `seedColor` | hex. 생성기가 기존 앱들과 색상환 거리 30° 이상 떨어진 값을 제안 |
| `brightness` | `light` · `dark` · `system` |
| `fontFamily` | 번들 폰트 허용 목록(1-3에서 확정, 한글 지원 필수) |
| `cornerRadius` | `0` · `8` · `16` · `28` |
| `density` | `compact` · `comfortable` |
| `iconStyle` | `outlined` · `rounded` · `sharp` |

### 3. 기능 모듈 계약

**코어 → 앱 (`FactoryServices`, 부트스트랩이 만들어 주입)**

| 서비스 | 앱이 쓰는 표면 | 비고 |
|--------|--------------|------|
| `AdService` | `bannerSlot(placementId)` 위젯 · `onTransition(placementId)` · `showRewarded(placementId) → RewardOutcome` | 노출 여부는 앱이 아니라 `AdPolicy`가 판단한다(§4). 앱은 "지금이 전환 지점이다"만 알린다 |
| `EntitlementService` | `adFree` 스트림 · `purchaseRemoveAds()` · `restore()` | |
| `Analytics` | `log(AppEvent)` · `keyAction(params)` | 앱 이벤트는 앱이 선언한 enum으로만 기록(§6) |
| `RemoteConfig` | `getBool/Int/Double/String/Json(appKey)` | `app_` 키만 접근 가능. `core_` 키는 코어 내부 전용 |
| `RatingService` | `positiveMoment()` | 요청 시점 판단은 코어가 한다 |
| `KeyValueStore` | `app.` 네임스페이스로 격리된 저장소 | |
| `Notifications` (선택) | 로컬 반복 알림 예약·취소, 권한 요청 | E·B 카테고리만 의존 |
| `ShareService` (선택) | 위젯을 이미지로 렌더링해 공유 | |
| 설정 부품 | `RemoveAdsTile` · `RestorePurchasesTile` · `LanguageTile` · `PrivacyOptionsTile` · `ContactTile` · `VersionTile` | 페이지가 아니라 행 단위 부품 |

**앱 → 코어 (`AppDefinition`)**

| 필드 | 설명 |
|------|------|
| `config` | 위 AppConfig를 코드 생성으로 읽은 값 |
| `placements` | `AdPlacement[]` (§4). `app.yaml`의 `admob.units` 키와 일치해야 한다 |
| `keyAction` | 이 앱의 **대표 행동** 하나(예: 번호 생성, 계산, 측정). 포트폴리오 비교 지표의 분자다(§6) |
| `events` | 앱 이벤트 enum 선언 |
| `buildApp(services)` | 앱 자체 위젯 트리(MaterialApp 등)를 반환한다. 테마는 `DesignTokens`로 만든 값을 쓴다 |

**부트스트랩 순서 (모든 앱 공통, 코어 소유)**

```
1. 저장소 열기 → 2. 원격 설정: 이전 실행에서 받아 둔 값 활성화(네트워크 대기 없음)
3. 동의(UMP) 정보 갱신 → 필요하면 동의 폼 → (iOS) ATT
4. canRequestAds = true 일 때만 광고 SDK 초기화 + 첫 광고 미리 불러오기
5. 구매 내역 조회 → Entitlement 갱신 (미확인 구매 acknowledge)
6. runApp(buildApp(services))
7. 백그라운드: 원격 설정 fetch (다음 실행에 활성화)
```
- 원격 설정을 실행 중에 바로 적용하지 않고 **다음 실행에 활성화**한다. 사용 중에 광고 빈도나 화면 데이터가 바뀌는 것을 막기 위해서다.
- 3~5단계가 실패해도 앱은 실행된다. 광고가 없을 뿐 기능은 모두 동작해야 한다(오프라인 동작, PRD §2.3).

### 4. 광고 정책 모델

**AdPlacement** `{ id, format, everyN? }`
- `id` 명명: `<format>_<where>` — `banner_home`, `interstitial_result`, `rewarded_hint`. 앱당 하나만 존재하는 앱 오프닝 광고만 예외로 `app_open` 단독 이름을 쓴다.
- 앱 오프닝 광고 사용 여부는 별도 플래그 없이 **`app_open` placement를 선언했는지**로 결정한다(단일 진실 공급원).
- `format`: `banner` · `interstitial` · `rewarded` · `app_open`. (보상형 전면 광고는 Wave 1 범위에서 제외)
- `everyN`: 전면 광고 전용. 해당 전환이 N번 일어날 때 한 번만 노출을 시도한다. 원격 키 `app_ads_<id>_every_n`으로 덮어쓴다.

**형식별 규칙**

| 형식 | 노출 조건 | 금지 |
|------|---------|------|
| banner | 화면당 최대 1개, 하단 고정 적응형 배너 | 버튼·입력 요소와 8dp 미만 간격, 콘텐츠를 가리는 배치, 스크롤 목록 중간 삽입(Wave 1) |
| interstitial | `onTransition` 호출 시 아래 **빈도 판정**을 모두 통과한 경우 | 앱 시작·종료 시점, 사용자가 입력 중일 때, 결과를 보여주기 **전**(결과 확인 → 다음 행동으로 넘어갈 때만) |
| rewarded | 사용자가 보상 내용을 보고 직접 누른 경우에만 | 자동 재생, 보상 없는 보상형 광고 |
| app_open | `app_open` placement를 선언했고, 백그라운드에서 `core_ads_app_open_min_background_sec` 이상 있다가 돌아온 경우 | 첫 세션, 광고·결제·공유·권한 화면에서 돌아온 경우, 콜드 스타트의 동의 폼 직후 |

**전면 광고 빈도 판정** (순수 함수로 구현하고 단위 테스트로 검증한다)

```
노출 시도 = core_ads_enabled
         ∧ ¬adFree
         ∧ sessionIndex > core_ads_interstitial_grace_sessions      (첫 세션 보호)
         ∧ now − lastInterstitialAt ≥ core_ads_interstitial_min_interval_sec
         ∧ sessionInterstitialCount < core_ads_interstitial_session_max
         ∧ (placement 전환 카운터 % everyN == 0)
         ∧ 광고가 미리 불러와져 있음
```
- `lastInterstitialAt`은 앱 오프닝 광고·보상형 광고를 본 시점으로도 갱신한다. 광고가 연달아 나오는 것을 막기 위해서다.
- 판정 결과는 모두 `ad_show_attempt` 이벤트로 남긴다(§6). 원격 설정으로 빈도를 조정할 때 근거가 된다.

**보상형 광고 실패 처리 (`RewardOutcome`)**: `earned` · `dismissed`(끝까지 보지 않음) · `unavailable`(불러오기 실패).
`unavailable`일 때 보상을 줄지는 앱이 placement마다 정한다 — 기본값은 **보상을 준다**(D3).

**광고 제거(adFree)의 효과**: 배너·전면·앱 오프닝 광고를 모두 끈다. 보상형 광고로 열리는 콘텐츠는 **광고 없이 바로 준다**
(구매자가 광고를 봐야 하는 상황을 만들지 않는다). 게임의 이어하기처럼 횟수가 의미 있는 보상도 동일하다.

**어린이·광고 콘텐츠 설정**: `tagForChildDirectedTreatment=false`, `tagForUnderAgeOfConsent=false`, `maxAdContentRating=T`.
`audience.minAge`를 13 이상으로 선언해 Play Families 정책 대상에서 벗어난다. 단, 캐릭터·색감이 어린이를 겨냥한 것처럼
보이면 Play가 대상 연령을 다르게 판단할 수 있으므로, 게임(A) 디자인 시 3-1 체크리스트에서 확인한다.

**디버그 테스트 ID 강제**
- 디버그·프로필 빌드에서는 `admob.units`를 무시하고 Google 공식 테스트 광고 단위 ID를 쓴다.
- 릴리스 빌드에서 테스트 ID가 쓰이거나, 반대로 실제 ID가 빠져 있으면 **빌드를 실패시킨다**(2-2 파이프라인 검증).
- 개발 기기는 테스트 기기로 등록한다. 본인 기기에서 실제 광고를 누르는 사고를 막기 위해서다(1-1 E4 무효 트래픽).

### 5. 원격 설정 키 체계

- **명명:** Firebase Remote Config 키는 영문·숫자·밑줄만 쓴다. 코어 키는 `core_`, 앱 키는 `app_` 접두사를 붙인다.
  JSON 값을 담는 키는 스키마 버전을 접미사로 붙인다(`_v1`). 스키마를 바꾸면 새 키를 만들고 이전 키는 그대로 둔다(구버전 앱 보호).
- **기본값:** 모든 키는 앱에 내장된 기본값을 가진다. 원격 값을 한 번도 받지 못해도 앱은 정상 동작해야 한다.
- **fetch 간격:** 릴리스 12시간, 디버그 0. 받은 값은 다음 실행에 활성화한다(§3).
- 앱마다 Firebase 프로젝트를 따로 둘지, 하나의 프로젝트에 여러 앱을 넣을지는 1-3에서 정한다. 접두사 규칙은 어느 쪽이든 그대로 쓸 수 있다.

**코어 키 (전 앱 공통)**

| 키 | 타입 | 기본값 | 용도 |
|----|------|-------|------|
| `core_ads_enabled` | bool | `true` | 광고 전체 비상 정지 |
| `core_ads_interstitial_min_interval_sec` | int | `90` | 전면 광고 최소 간격 (D2) |
| `core_ads_interstitial_session_max` | int | `5` | 세션당 전면 광고 최대 횟수 (D2) |
| `core_ads_interstitial_grace_sessions` | int | `1` | 처음 N개 세션은 전면 광고 없음 (D2) |
| `core_ads_app_open_min_background_sec` | int | `30` | 앱 오프닝 광고를 보여줄 최소 백그라운드 시간 |
| `core_iap_remove_ads_enabled` | bool | `true` | 광고 제거 상품 노출 여부 |
| `core_rating_min_positive_moments` | int | `3` | 리뷰 요청 전 필요한 긍정 순간 횟수 |
| `core_rating_min_days_since_install` | int | `2` | 설치 후 최소 경과 일수 |
| `core_update_min_build` | int | `0` | 이보다 낮은 빌드에 업데이트 권장 안내 표시 |

**앱 키 예시:** `app_ads_interstitial_result_every_n`(int), `app_salary_rates_v1`(json, §8), `app_fortune_daily_enabled`(bool).

### 6. 분석 이벤트 스키마

Firebase Analytics 제약: 이벤트 이름 40자 이하, 영문으로 시작하고 영문·숫자·밑줄만 사용, `firebase_`·`google_`·`ga_` 접두사 금지,
이벤트당 매개변수 25개 이하, 문자열 값 100자 이하, 사용자 속성 25개 이하. **개인 식별 정보는 기록하지 않는다.**

**광고 수익:** AdMob 앱을 Firebase에 연결하면 `ad_impression`(수익 포함)이 자동 수집되므로 코어는 이 이벤트를 **직접 기록하지 않는다**
(중복 집계 방지, 1-3에서 현재 동작 재확인). 코어는 수익이 아니라 **노출 판정 과정**을 기록한다.

**코어 공통 이벤트**

| 이벤트 | 매개변수 | 시점 |
|--------|---------|------|
| `ad_show_attempt` | `placement`, `format`, `result`: `shown` · `capped_interval` · `capped_session` · `grace` · `every_n` · `not_loaded` · `ad_free` · `disabled` | 노출 판정마다 |
| `reward_outcome` | `placement`, `outcome`: `earned` · `dismissed` · `unavailable` · `ad_free` | 보상형 광고 종료 시 |
| `consent_result` | `ump_status`, `att_status` | 동의 흐름 종료 시 |
| `remove_ads_view` | `source`: `settings` · `paywall` · `after_ad` | 광고 제거 안내 노출 |
| `remove_ads_result` | `result`: `purchased` · `cancelled` · `failed` · `restored` | 구매·복원 종료 |
| `rating_prompt` | `moment_count` | 리뷰 요청 API 호출 |
| `key_action` | `action`(앱 `keyAction` 이름) + 앱이 정의한 매개변수 최대 5개 | 앱의 대표 행동 |

- `key_action`은 모든 앱이 같은 이름으로 기록한다. 그래서 **"DAU당 대표 행동 수"를 앱끼리 같은 기준으로 비교**할 수 있다(3-2 판단 지표).
- 화면 조회는 내비게이터 관찰자가 라우트 이름으로 자동 기록한다(`screen_view`).

**앱 이벤트 규칙:** `동사_목적어` snake_case(`save_history`, `scan_qr`), 앱 접두사를 붙이지 않는다(앱마다 데이터 스트림이 분리됨).
앱당 10개 이하로 선언하고, 코어 이벤트 이름과 겹치면 빌드 검증에서 실패시킨다.

**사용자 속성:** `app_category`, `ad_free`(`true`·`false`), `app_locale`.

### 7. 동의 상태 흐름

| UMP 결과 | `canRequestAds` | 광고 | 분석 (Consent Mode) |
|----------|----------------|------|-------------------|
| 동의 불필요 (한국 등 EEA·UK 밖) | true | 맞춤 광고 | 전부 허용 |
| 동의함 | true | 맞춤 광고 | 사용자 선택에 따름 |
| 거부·일부 동의 | true | 비맞춤·제한 광고(UMP가 TCF 문자열로 SDK에 전달) | `ad_storage`·`analytics_storage` 등을 선택에 맞춰 거부 |
| 동의 정보 갱신 실패(오프라인) | 이전 실행의 값 | 이전 값이 true면 광고, 아니면 광고 없음 | 이전 값 유지 |

- 설정 부품 `PrivacyOptionsTile`은 UMP가 "개인정보 옵션 진입점 필요"를 반환한 경우에만 보인다(정책 요구).
- iOS ATT는 UMP 다음에 요청한다. Android 먼저 출시(Q3)이므로 Wave 1에서는 구현만 해 두고 iOS 확장 때 검증한다.

### 8. 광고 제거 인앱결제

**상품:** `remove_ads` · 일회성(비소비성) 상품 · 앱마다 같은 ID(상품 ID는 앱 단위로 분리되므로 충돌 없음).
**가격 기본안:** ₩3,900 / US$2.99 (D1). 국가별 가격은 스토어 자동 환산을 쓴다.

**Entitlement** `{ adFree: bool, source: 'purchase' | 'restore' | 'none', updatedAt }` — `core.entitlement` 키에 캐시한다.
- Play 결제는 **3일 안에 acknowledge**하지 않으면 자동 환불되므로, 부트스트랩 5단계에서 미확인 구매를 다시 확인한다.
- 서버 영수증 검증은 하지 않는다(서버 없음, PRD §3). 클라이언트 위변조로 광고가 꺼지는 위험은 수용한다. 매출 비중이 광고 대비 작기 때문이다.
- 환불·취소되면 다음 실행의 구매 내역 조회에서 `adFree=false`로 되돌린다.
- iOS는 "구매 복원" 버튼이 필수다(`RestorePurchasesTile`).

### 9. 리뷰 요청·저장소

**리뷰 요청:** `positiveMoment()` 누적 ≥ `core_rating_min_positive_moments` ∧ 설치 후 ≥ `core_rating_min_days_since_install`일 ∧
같은 전환에서 광고가 노출되지 않음 ∧ 마지막 요청 후 90일 경과 → OS 인앱 리뷰 API 호출. 보상을 걸거나 별점을 미리 묻는
필터링(별점 높을 때만 스토어로 보내기)은 하지 않는다(스토어 정책).

**저장소:** 키-값 저장소를 `core.*` / `app.*`로 나누고, `core.schemaVersion`·`app.schemaVersion`으로 마이그레이션한다.
관계형 데이터가 필요한 앱(E 트래커)만 로컬 DB를 추가한다(라이브러리는 1-3).

### 10. Wave 1 매핑 검증

| 앱 | placements (everyN) | `keyAction` | 앱 원격 키 | 선택 서비스 | 언어 |
|----|--------------------|-------------|-----------|-----------|------|
| 로또 번호 생성기 | `banner_home`, `banner_history`, `interstitial_generate`(3), `rewarded_analysis` | `generate_numbers` | `app_ads_interstitial_generate_every_n` | Share | ko |
| 연봉 실수령액 계산기 | `banner_result`, `interstitial_calculate`(3) | `calculate_salary` | `app_salary_rates_v1`(json: 연도, 국민연금·건강·장기요양·고용보험 요율, 간이세액표 버전, 출처, 기준일) | — | ko |
| 소음 측정기 | `banner_home`, `app_open` | `measure_noise`(10초 이상 측정 시) | — | (마이크 권한은 앱 소유) | ko, en |
| 물 마시기 알림 | `banner_home`, `banner_stats`, `interstitial_stats`(2) | `log_water` | `app_water_default_goal_ml` | Notifications, 로컬 DB | ko, en |
| 블록·숫자 퍼즐 | `banner_menu`, `interstitial_round_end`(2), `rewarded_continue`, `rewarded_hint` | `finish_round` | `app_ads_interstitial_round_end_every_n` | 게임 키트(2-7), Share | ko, en |

- 다섯 앱 모두 이 계약만으로 표현된다. 앱 고유 로직(번호 생성 알고리즘, 세액 계산, dB 변환, 기록 통계, 게임 규칙)은 계약 밖이며
  각 앱의 Build Spec(Phase 2)에서 정의한다.
- 로또 회차 번호는 서버 없이 날짜로 계산한다(1회 = 2002-12-07, 매주 토요일). 당첨 확인은 1-1 §7대로 QR → 공식 결과 페이지 연결이다.
- 연봉 계산기의 요율은 원격 JSON으로 관리하고, 앱에는 출시 시점 요율을 기본값으로 내장한다. 화면에 출처와 기준일을 표시한다.

### 11. 검증 계획 (→ 2-1 Build Spec)

- **자동화 테스트:** 전면 광고 빈도 판정(§4)의 각 조건별 경계, 보상형 실패 처리, adFree 효과, 원격 기본값 폴백, `app.yaml` 스키마 검증
  (placement ↔ 단위 ID 일치, 테스트 ID 금지, 이벤트 이름 규칙·충돌).
- **수동 확인:** UMP 폼(EEA 테스트 지역 강제 설정), 실제 결제 테스트 계정으로 구매·환불·복원, 앱 오프닝 광고 복귀 조건.

### 12. 미해결 질문

| # | 질문 | AI 기본안 |
|---|------|----------|
| D1 | 광고 제거 가격 | **₩3,900 / US$2.99.** 모든 앱 동일 |
| D2 | 전면 광고 기본 강도 | **보수적:** 최소 간격 90초, 세션당 5회, 첫 세션 없음. 출시 후 원격 설정으로 조금씩 올린다 |
| D3 | 보상형 광고를 불러오지 못했을 때 | **보상을 준다.** 광고 실패 때문에 사용자가 막히면 평점이 떨어진다 |

### 산출물

경계 원칙 + AppConfig 스키마 + 기능 모듈 계약 + 광고 정책 모델 + 원격 설정 키 + 분석 이벤트 + 동의 흐름 + IAP 모델 + Wave 1 매핑 →
**1-3 Architecture Decision ⚠️**(Flutter 패키지 구조, Firebase 프로젝트 분리 방식, 라이브러리 선정, 코드 생성 방식)과
**2-1 Core Packages Build Spec**의 입력.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] 모든 Wave 1 앱을 이 계약만으로 표현할 수 있는가?
- [x] 포트폴리오 규칙 P3(보이는 셸 비공유)이 계약에 반영되었는가?
- [x] 광고 정책 모델이 AdMob 정책(1-1 E4)을 위반하지 않는가?
- [x] 미해결 질문 D1~D3에 답했는가?

### 승인 결과 (2026-10-13, 오너)

계약은 제안대로 승인되었다. D1~D3 답변은 다음과 같다. 상세 근거는 [`../DECISIONS.md`](../DECISIONS.md)에 있다.

| # | 답변 |
|---|------|
| D1 | **₩2,500 / US$1.99** (기본안 ₩3,900과 다름 — §8의 가격은 이 값으로 대체한다). 모든 앱 동일 |
| D2 | 보수적으로 시작: 최소 간격 90초, 세션당 5회, 첫 세션 없음 |
| D3 | 보상형 광고를 불러오지 못하면 보상을 준다(앱이 placement마다 변경 가능) |

> 계약 확장: 2-1에서 `AdService`에 `prepareRewarded()`·`onAppBackground()`를 추가했다 → [`../02-construction/core-packages/build-spec-index.md`](../02-construction/core-packages/build-spec-index.md) §7
>
> 계약 확장: 1-3 §8에서 AppConfig에 `permissions`, `firebase.projectId` 필드를 추가했다 → [`03-architecture-decision.md`](03-architecture-decision.md) §8

## 다음 단계

승인 후 → `STATUS.md`에서 1-2 상태를 `HUMAN_APPROVED`로 업데이트 → `03-architecture-decision.md`로 이동
