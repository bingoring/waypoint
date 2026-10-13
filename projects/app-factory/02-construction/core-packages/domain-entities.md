---
artifact: domain-entities
build-spec: core-packages
status: DRAFT
updated: 2026-10-13
---

# Domain & Entities — Core Packages

> 모든 타입은 `factory_core`(순수 Dart)에 둔다. 불변 값 객체이며 `==`/`hashCode`를 구현한다(`@immutable`).
> 규칙·검증은 [`business-rules.md`](business-rules.md), 흐름은 [`business-logic-model.md`](business-logic-model.md).

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT 출처 |
|---|---|---|---|
| `AppConfig` | 앱 빌드 설정 | 코드 상수(2-2 코드 생성) | 1-2 §2, 1-3 §8 |
| `DesignTokens` | 앱 테마 입력 | `AppConfig` 내부 | 1-2 §2 |
| `AdPlacement` | 광고 노출 위치 선언 | `AppDefinition` 코드 | 1-2 §4 |
| `AdPolicyConfig` | 원격 조정 가능한 광고 정책 값 | 원격 설정 → 메모리 | 1-2 §5 |
| `SessionState` | 세션 번호·시각 | 키-값 저장소 `core.session.*` | 1-2 §4 (grace) |
| `AdRuntimeState` | 마지막 전면 노출 시각, 세션 내 횟수, placement별 전환 카운터, 앱 오프닝 억제 | 메모리(프로세스 수명) | 1-2 §4 |
| `Entitlement` | 광고 제거 권리 | `core.entitlement` | 1-2 §8 |
| `ConsentState` | 동의 결과 | 메모리 + `core.consent.canRequestAds` | 1-2 §7 |
| `RatingState` | 긍정 순간 횟수, 마지막 요청 시각 | `core.rating.*` | 1-2 §9 |
| `RemoteKey<T>` | 타입이 있는 원격 설정 키 | 코드 | 1-2 §5 |
| `AnalyticsEvent` | 분석 이벤트 | 전송만(저장 안 함) | 1-2 §6 |
| `AppDefinition` | 앱이 코어에 제공하는 정의 | 코드 | 1-2 §3 |

## 2. 엔티티 상세

### 2.1 `AppConfig`
| 필드 | 타입 | 필수 | 기본값 | 제약 | 설명 |
|---|---|---|---|---|---|
| `slug` | `String` | ✓ | — | `^[a-z][a-z0-9_]{2,24}$` | 앱 식별자 |
| `category` | `AppCategory` | ✓ | — | §4 | |
| `displayName` | `Map<AppLocale, String>` | ✓ | — | `locales` 전부 존재, 각 1~30자 | |
| `locales` | `List<AppLocale>` | ✓ | — | 1개 이상, 중복 없음 | |
| `defaultLocale` | `AppLocale` | ✓ | — | `locales`에 포함 | |
| `androidApplicationId` | `String` | ✓ | — | `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`, 마지막 세그먼트 = `slug` | |
| `iosBundleId` | `String?` | | `null` | | iOS 확장 시 |
| `version` | `String` | ✓ | — | semver `x.y.z` | |
| `admobAppId` | `PlatformValue<String>` | ✓ | — | `ca-app-pub-\d{16}~\d{10}` | |
| `adUnits` | `Map<String, PlatformValue<String>>` | ✓ | — | 키 = placement id, 값 `ca-app-pub-\d{16}/\d{10}` | |
| `iap` | `IapConfig` | ✓ | `IapConfig()` | | |
| `design` | `DesignTokens` | ✓ | — | | |
| `links` | `Links` | ✓ | — | | |
| `audienceMinAge` | `int` | ✓ | `13` | `{13, 18}` | |
| `permissions` | `List<String>` | ✓ | `[]` | `android.permission.` 접두사 | 1-3 §8 |
| `firebaseProjectId` | `String?` | | `null` | `null`이면 Firebase 비활성(예제·테스트) | 1-3 §8 |
| `remoteDefaults` | `Map<String, Object>` | ✓ | `{}` | 키는 `app_` 접두사, 값은 `bool·int·double·String` (JSON은 문자열) | |

- `PlatformValue<T> { T android; T? ios; }` — 현재 플랫폼 값은 `resolve(TargetPlatform)`으로 얻는다. iOS 값이 없으면 iOS에서 해당 기능 비활성.
- `IapConfig { String removeAdsProductId = 'remove_ads'; }`
- `Links { Uri privacyPolicy; String supportEmail; }` — `privacyPolicy`는 `https`만.

### 2.2 `DesignTokens`
| 필드 | 타입 | 제약 |
|---|---|---|
| `seedColor` | `int` (ARGB) | 알파 0xFF |
| `brightness` | `ThemePreference` | `light`·`dark`·`system` |
| `fontFamily` | `String?` | `null` = 플랫폼 기본(한글 지원). 번들 폰트는 2-2에서 허용 목록 확정 |
| `cornerRadius` | `double` | `{0, 8, 16, 28}` |
| `density` | `UiDensity` | `compact`·`comfortable` |
| `iconStyle` | `IconStyle` | `outlined`·`rounded`·`sharp` |

### 2.3 `AdPlacement`
| 필드 | 타입 | 필수 | 기본값 | 제약 |
|---|---|---|---|---|
| `id` | `String` | ✓ | — | BR R-ADS-1 |
| `format` | `AdFormat` | ✓ | — | §4 |
| `everyN` | `int` | | `1` | 전면만 의미 있음, 1~20 |
| `grantOnUnavailable` | `bool` | | `true` | 보상형만 의미 있음 (D3) |

### 2.4 `AdPolicyConfig` (원격 값을 클램프한 결과)
| 필드 | 타입 | 원격 키 | 기본 |
|---|---|---|---|
| `adsEnabled` | `bool` | `core_ads_enabled` | `true` |
| `interstitialMinInterval` | `Duration` | `core_ads_interstitial_min_interval_sec` | 90초 |
| `interstitialSessionMax` | `int` | `core_ads_interstitial_session_max` | 5 |
| `graceSessions` | `int` | `core_ads_interstitial_grace_sessions` | 1 |
| `appOpenMinBackground` | `Duration` | `core_ads_app_open_min_background_sec` | 30초 |
| `everyNOverrides` | `Map<String,int>` | `app_ads_<placementId>_every_n` | placement 값 |

### 2.5 상태 엔티티
- **`SessionState`** `{ int index; DateTime startedAt; DateTime? backgroundedAt; }` — `index`는 1부터. 저장 키 `core.session.index`, `core.session.lastActiveAt`.
- **`AdRuntimeState`** `{ DateTime? lastFullscreenAt; int sessionInterstitialCount; Map<String,int> transitionsSinceShown; bool suppressNextAppOpen; }` — 프로세스 수명. 새 세션 시작 시 `sessionInterstitialCount = 0`.
- **`Entitlement`** `{ bool adFree; EntitlementSource source; DateTime updatedAt; }` — 저장 키 `core.entitlement` (JSON 문자열).
- **`ConsentState`** `{ ConsentStatus ump; AttStatus att; bool canRequestAds; bool privacyOptionsRequired; }`
- **`RatingState`** `{ int positiveMoments; DateTime? lastPromptAt; DateTime firstLaunchAt; }` — 저장 키 `core.rating.moments`, `core.rating.lastPromptAt`, `core.install.firstLaunchAt`.

### 2.6 `RemoteKey<T>`
`{ String name; T defaultValue; T Function(T) clamp; }` — `CoreKeys`에 §2.4의 코어 키 9개(1-2 §5 표 전체)를 정적 상수로 정의한다.
앱 키는 `RemoteKey.app('app_...', default)`로 만들며, 생성자가 `app_` 접두사를 검사한다.

### 2.7 `AnalyticsEvent`
`{ String name; Map<String, Object> params; }` — 값은 `String`·`int`·`double`만. `CoreEvents`에 1-2 §6의 7개 이벤트를 팩토리로 정의한다
(`CoreEvents.adShowAttempt(placement, format, AdDecision)` 등). 앱 이벤트는 `AppEvent` 인터페이스(`String get name`)를 구현한 enum으로 선언한다.

### 2.8 `AppDefinition`
```dart
abstract interface class AppDefinition {
  AppConfig get config;
  List<AdPlacement> get placements;
  String get keyAction;                 // 예: 'generate_numbers'
  List<AppEvent> get events;
  Widget buildApp(FactoryServices services);   // runtime 레이어 타입 (core는 Widget을 모름 → runtime에 정의)
}
```
> `AppDefinition`은 Flutter `Widget`을 반환하므로 **`factory_runtime`에 정의**한다. `factory_core`에는 Flutter에 의존하지 않는
> `AppManifest { config, placements, keyAction, events }`를 두고, `AppDefinition`이 이를 포함한다.

### 2.9 게이트웨이 인터페이스 (`factory_core`, 어댑터가 구현)
| 인터페이스 | 메서드 | 구현 |
|---|---|---|
| `AdGateway` | `Future<void> initialize()`, `Future<bool> loadFullscreen(AdFormat, String unitId)`, `bool isLoaded(AdFormat, String unitId)`, `Future<FullscreenResult> showFullscreen(AdFormat, String unitId)`, `void disposeAll()` | factory_ads |
| `ConsentGateway` | `Future<ConsentState> gather({Duration timeout})`, `Future<void> showPrivacyOptions()` | factory_ads (UMP) |
| `AnalyticsSink` | `Future<void> log(AnalyticsEvent)`, `Future<void> setUserProperty(String, String?)`, `Future<void> setConsent(ConsentState)` | factory_firebase / `NoopAnalyticsSink` |
| `RemoteConfigSource` | `Future<void> activateFetched()`, `Future<void> fetchInBackground()`, `Object? getRaw(String key)` | factory_firebase / `DefaultsOnlyRemoteConfig` |
| `PurchaseGateway` | `Stream<PurchaseUpdate> get updates`, `Future<StoreProduct?> queryProduct(String id)`, `Future<void> buy(String id)`, `Future<void> restore()`, `Future<void> complete(PurchaseUpdate)` | factory_iap |
| `ReviewGateway` | `Future<bool> isAvailable()`, `Future<void> requestReview()` | factory_runtime (`in_app_review`) |
| `KeyValueStore` | `get/set String·int·bool`, `remove` — 네임스페이스는 `ScopedStore('core.' | 'app.')`가 강제 | factory_runtime |
| `Clock` | `DateTime now()` | `SystemClock` / 테스트 `FakeClock` |

`FullscreenResult`: `shown` · `dismissedAfterShow` · `earnedReward` · `failedToShow`.

## 3. 관계

| 좌 | 카디널리티 | 우 | 비고 |
|---|---|---|---|
| `AppDefinition` | 1─1 | `AppManifest` | |
| `AppManifest` | 1─* | `AdPlacement` | id 유일 |
| `AdPlacement` | *─1 | `AppConfig.adUnits` 항목 | id로 1:1 일치 (BR R-CFG-6) |
| `AdService` | 1─1 | `AdRuntimeState` | 소유 |
| `EntitlementService` | 1─1 | `Entitlement` | 소유, `AdService`가 구독 |

## 4. 열거형 / Allowed-set

| 이름 | 값 | 확장 규칙 |
|---|---|---|
| `AppCategory` | `game`, `fun`, `calculator`, `tool`, `tracker` | 추가만 |
| `AppLocale` | `ko`, `en` | 추가 시 `factory_ui` 문자열 동반 |
| `AdFormat` | `banner`, `interstitial`, `rewarded`, `appOpen` (`id` 문자열은 `app_open`) | 추가 시 정책 판정 추가 |
| `AdDecision` | `shown`, `cappedInterval`, `cappedSession`, `grace`, `everyN`, `notLoaded`, `adFree`, `disabled` | 분석 값은 snake_case (`capped_interval` …) |
| `RewardOutcome` | `earned`, `dismissed`, `unavailable`, `adFree` | |
| `EntitlementSource` | `none`, `purchase`, `restore` | |
| `ConsentStatus` | `unknown`, `notRequired`, `required`, `obtained` | UMP 값 매핑 |
| `AttStatus` | `notApplicable`, `notDetermined`, `restricted`, `denied`, `authorized` | Android는 `notApplicable` |
| `ThemePreference` | `light`, `dark`, `system` | |
| `UiDensity` | `compact`, `comfortable` | |
| `IconStyle` | `outlined`, `rounded`, `sharp` | |

## 5. SoT 매핑

| SoT 요소 | 엔티티.필드 | 비고 |
|---|---|---|
| 1-2 §2 `slug`…`remoteDefaults` | `AppConfig.*` | `admob.units` → `adUnits`, `links.*` → `Links` |
| 1-2 §2 `audience.minAge` | `AppConfig.audienceMinAge` | |
| 1-3 §8 `permissions`, `firebase.projectId` | `AppConfig.permissions`, `firebaseProjectId` | |
| 1-2 §4 AdPlacement `{id, format, everyN}` | `AdPlacement` | + `grantOnUnavailable`(1-2 §4 "앱이 placement마다 정한다") |
| 1-2 §5 코어 키 표 | `CoreKeys`, `AdPolicyConfig` | |
| 1-2 §6 코어 이벤트 표 | `CoreEvents` | |
| 1-2 §8 Entitlement | `Entitlement` | |
| 1-2 §3 FactoryServices | runtime `FactoryServices` 조립 | 서비스 구현은 core |
