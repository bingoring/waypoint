---
artifact: business-rules
build-spec: core-packages
status: DRAFT
updated: 2026-10-13
---

# Business Rules — Core Packages

> 1-2 계약과 1-3 §7 품질 기준을 결정적 규칙으로 옮긴다. `(AI)` 표시는 이 Build Spec에서 AI가 새로 정한 세부값이며 `READY` 승인 시 확정된다.

## 1. 규칙 표

### 1.1 광고 (R-ADS)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거 |
|---|---|---|---|---|
| R-ADS-1 | placement id는 `^(banner\|interstitial\|rewarded)_[a-z][a-z0-9_]{1,30}$` 또는 정확히 `app_open`. 접두사는 `format`과 일치 | `AdPlacement` | 생성자 `ArgumentError` | 1-2 §4 |
| R-ADS-2 | 디버그·프로필 빌드는 `AppConfig.adUnits`를 무시하고 Google 공식 테스트 단위 ID를 쓴다 | `factory_ads` | — | 1-2 §4 |
| R-ADS-3 | 릴리스 빌드에서 단위 ID가 테스트 ID(`ca-app-pub-3940256099942544/…`)이면 부트스트랩이 `StateError`로 실패 | 부트스트랩 | 앱 시작 실패(출시 전 발견) + 2-2 CI 검사 | 1-2 §4 |
| R-ADS-4 | `canRequestAds == false`이면 `AdGateway.initialize`·로드를 호출하지 않는다 | `AdService` | 모든 판정 `disabled` | 1-2 §7 |
| R-ADS-5 | 전면·앱 오프닝·보상형 표시 직후 `lastFullscreenAt = now` | `AdRuntimeState` | — | 1-2 §4 |
| R-ADS-6 | 전면 광고는 `onTransition`에서만 표시한다. 앱 코드가 전면 광고를 직접 띄우는 API는 없다 | `AdService` 공개 API | 컴파일 불가 | 1-2 §3 |
| R-ADS-7 | 보상형은 `showRewarded`(사용자 탭 핸들러)에서만 호출한다. 디버그 빌드에서 직전 500ms 안에 포인터 업 이벤트가 없으면 assert 실패 `(AI)` | `AdService` | 디버그 assert | 1-2 §4 |
| R-ADS-8 | 형식별 미리 로드 광고는 최대 1개. 표시 후 즉시 다음 1개를 로드한다 | `AdGateway` | — | 1-3 §7.4 |
| R-ADS-9 | 앱 오프닝 광고는 로드 후 4시간이 지나면 폐기하고 다시 로드한다 `(AI)` | `GoogleAdsGateway` | — | AdMob 앱 오프닝 가이드 |
| R-ADS-10 | 광고 요청 설정: `tagForChildDirectedTreatment=no`, `tagForUnderAgeOfConsent=no`, `maxAdContentRating=T` | `GoogleAdsGateway.initialize` | — | 1-2 §4 |
| R-ADS-11 | 앱이 외부 흐름(결제, 공유, 권한 요청, 외부 URL)을 시작하기 전 `suppressNextAppOpen()`을 호출한다. 코어의 결제·공유·리뷰 경로는 자동 호출 | `AdService` | 복귀 시 앱 오프닝 광고 미표시 | 1-2 §4 |

### 1.2 원격 설정 (R-RC)
| ID | 규칙 | 위반 시 동작 |
|---|---|---|
| R-RC-1 | 원격 값은 키의 `clamp`를 통과해야 쓰인다. 타입이 다르거나 범위를 벗어나면 **기본값**을 쓴다(범위로 자르지 않음) `(AI)` | 기본값 + 디버그 로그 |
| R-RC-2 | 클램프 범위 `(AI)`: `min_interval_sec` 30~3600, `session_max` 0~20, `grace_sessions` 0~10, `app_open_min_background_sec` 5~3600, `every_n` 1~20, `rating_min_positive_moments` 1~20, `rating_min_days_since_install` 0~60, `update_min_build` ≥ 0 | 기본값 |
| R-RC-3 | 앱은 `app_` 키만 읽을 수 있다. `RemoteConfig.get`에 `core_` 키를 넘기면 `ArgumentError` | 예외 |
| R-RC-4 | 실행 중에는 값이 바뀌지 않는다. 부트스트랩에서 `activateFetched()` 1회 후 스냅샷을 고정한다 | — |

### 1.3 분석 (R-AN)
| ID | 규칙 | 위반 시 동작 |
|---|---|---|
| R-AN-1 | 이벤트·매개변수 이름 `^[a-zA-Z][a-zA-Z0-9_]{0,39}$`, 접두사 `firebase_`·`google_`·`ga_` 금지 | 디버그 assert, 릴리스에선 이벤트 버림 + Crashlytics 비치명 로그 |
| R-AN-2 | 매개변수 ≤ 25개, 문자열 값 ≤ 100자 | 100자 초과는 잘라서 전송, 25개 초과는 R-AN-1과 동일 |
| R-AN-3 | 앱 이벤트 이름은 `CoreEvents` 이름과 겹칠 수 없다. 앱 이벤트는 앱당 10개 이하 | 부트스트랩 assert (+ 2-2 CI) |
| R-AN-4 | `key_action`의 `action` 값 = `AppManifest.keyAction`. 추가 매개변수 ≤ 5개 | assert |
| R-AN-5 | 코어는 `ad_impression`을 기록하지 않는다 | — |
| R-AN-6 | 개인 식별 정보 금지: 매개변수 값에 이메일 형식·10자리 이상 연속 숫자가 있으면 버린다 `(AI)` | 디버그 assert, 릴리스 버림 |

### 1.4 광고 제거·결제 (R-IAP)
| ID | 규칙 | 위반 시 동작 |
|---|---|---|
| R-IAP-1 | `purchased`·`restored` 업데이트 → `adFree = true` 저장 후 `complete`(acknowledge) 호출 | complete 실패 시 다음 실행에서 재시도 |
| R-IAP-2 | `pending` → 권리 변경 없음, 안내만 | — |
| R-IAP-3 | 권리 하향(`adFree=false`)은 **구매 내역 조회가 성공했고** 해당 상품이 없을 때만. 오프라인·오류 시 캐시 유지 | — |
| R-IAP-4 | 가격 표시는 스토어가 준 현지화 가격 문자열만 쓴다(₩2,500 하드코딩 금지, D1 가격은 스토어 콘솔에 설정) | — |
| R-IAP-5 | `core_iap_remove_ads_enabled == false`이면 구매 행을 숨기되 **복원 행은 항상 보인다** `(AI)` | — |

### 1.5 리뷰 요청 (R-RT)
| ID | 규칙 |
|---|---|
| R-RT-1 | 요청 조건: moments ≥ `core_rating_min_positive_moments` ∧ 설치 후 일수 ≥ `core_rating_min_days_since_install` ∧ `lastPromptAt`가 없거나 90일 경과 ∧ 최근 10초 안에 전면형 광고 없음 `(AI: 10초)` |
| R-RT-2 | 요청하면 `moments = 0`, `lastPromptAt = now`. 실제로 창이 떴는지는 OS가 알려주지 않으므로 호출 시점 기준 |
| R-RT-3 | 리뷰 요청 전에 별점을 묻거나 보상을 거는 UI를 제공하지 않는다 |

### 1.6 세션 (R-SES)
| ID | 규칙 |
|---|---|
| R-SES-1 | 콜드 스타트, 또는 백그라운드에 **30분 이상** 있다가 복귀하면 새 세션(`index + 1`) `(AI: Firebase 기본 세션 시간과 일치)` |
| R-SES-2 | 새 세션 시작 시 `sessionInterstitialCount = 0`. `transitionsSinceShown`은 유지 |

### 1.7 아키텍처 (R-ARCH) — `tool/check_deps.dart`로 검사
| ID | 규칙 |
|---|---|
| R-ARCH-1 | `factory_core`는 `flutter`·플러그인 패키지에 의존하지 않는다(pubspec·import 모두) |
| R-ARCH-2 | 어댑터(`ads`·`firebase`·`iap`)는 서로 의존하지 않는다. `runtime`과 `core`에만 의존 |
| R-ARCH-3 | `apps/*`·`examples/*`는 `google_mobile_ads`·`firebase_*`·`in_app_purchase`·`in_app_review`를 직접 import할 수 없다 |
| R-ARCH-4 | 앱끼리 의존 금지. 앱 `lib/domain/**`은 `package:flutter`를 import할 수 없다 |

## 2. 검증 규칙 (AppConfigValidator)

| 입력 | 규칙 | 오류 코드 |
|---|---|---|
| `slug` | DE §2.1 정규식 | `CFG_SLUG` |
| `displayName` | 모든 `locales`에 존재, 1~30자 | `CFG_NAME` |
| `defaultLocale` | `locales` 포함 | `CFG_LOCALE` |
| `androidApplicationId` | 정규식 + 마지막 세그먼트 = slug | `CFG_APP_ID` |
| `version` | `^\d+\.\d+\.\d+$` | `CFG_VERSION` |
| `admobAppId`·`adUnits` 값 | DE §2.1 정규식 | `CFG_ADMOB` |
| R-CFG-6 | `adUnits`의 키 집합 == `placements`의 id 집합 (정확히 일치. 빠진 키와 남는 키 모두 오류) | `CFG_UNITS_MISMATCH` |
| `remoteDefaults` | 키 `^app_[a-z0-9_]+$`, 값 타입 허용 목록 | `CFG_REMOTE` |
| `permissions` | `android.permission.` 접두사, 중복 없음 | `CFG_PERMISSION` |
| `links` | `https` URL, 이메일 형식 | `CFG_LINKS` |

검증기는 `List<ConfigIssue>`를 반환한다(첫 오류에서 멈추지 않음). 런타임은 디버그에서 비어 있지 않으면 assert 실패, CLI(2-2)는 전부 출력 후 종료 코드 1.

## 3. 권한 / 접근 규칙

| 액션 | 허용 조건 | 거부 시 |
|---|---|---|
| 원격 `core_` 키 읽기 | `factory_core` 내부만 | `ArgumentError` (R-RC-3) |
| 저장소 `core.` 네임스페이스 쓰기 | 코어 서비스만 (`ScopedStore`가 앱에는 `app.`만 줌) | 컴파일 시 접근 불가 |
| 전면 광고 표시 | `AdService.onTransition` 판정 통과 | 미표시 + `ad_show_attempt` 기록 |

## 4. 불변식

- **INV-ADS-1:** `adFree == true`이면 배너·전면·앱 오프닝 광고 표시 0회, 보상형은 광고 없이 `RewardOutcome.adFree`.
- **INV-ADS-2:** 어느 시점에도 형식별 로드된 광고 객체 ≤ 1.
- **INV-ADS-3:** 연속한 두 전면형 광고(전면·앱 오프닝·보상형) 표시 사이 간격 ≥ `interstitialMinInterval`. 단 사용자가 직접 누른 보상형은 예외(보상형 다음의 전면은 간격 적용).
- **INV-ADS-4:** 세션당 전면 광고 ≤ `interstitialSessionMax`, 세션 번호 ≤ `graceSessions`이면 전면·앱 오프닝 0.
- **INV-ADS-5:** 모든 `onTransition`·`showRewarded` 호출은 정확히 한 개의 분석 이벤트를 남긴다.
- **INV-RC-1:** 네트워크가 한 번도 연결되지 않아도 모든 키가 유효한 값을 돌려준다.
- **INV-IAP-1:** 오프라인 실행에서 `adFree`가 true → false로 바뀌지 않는다.

## 5. 엣지케이스 · 에러 매핑

| 케이스 | 조건 | 기대 동작 |
|---|---|---|
| 첫 실행 오프라인 | UMP 갱신 실패, 저장값 없음 | `canRequestAds=false` → 광고 없음, 기능 정상 |
| 동의 갱신 타임아웃 | 5초 초과 `(AI)` | 이전 값 사용, 백그라운드에서 계속 시도하지 않음(다음 실행) |
| 전면 표시 실패 | `failedToShow` | `lastFullscreenAt` 갱신 안 함, 카운터 유지, 이벤트 `not_loaded` |
| 보상형 로드 실패 | 5초 안에 로드 안 됨 `(AI)` | `grantOnUnavailable`에 따라 `unavailable` + 보상 지급/미지급 |
| 보상형 도중 앱 백그라운드 | SDK 콜백 순서 | `earnedReward` 콜백을 받았으면 `earned`, 아니면 `dismissed` |
| 구매 중 앱 종료 | 결제 완료 콜백 유실 | 다음 실행 `restore()`에서 회복 (R-IAP-1) |
| 원격 값 이상 | 예: `session_max = -1` | 기본값 5 (R-RC-1) |
| 시계 역행 | `now < lastFullscreenAt` | 간격 판정을 "충족 안 됨"으로 보고 `lastFullscreenAt = now`로 재설정 `(AI)` |
| Firebase 미설정 | `firebaseProjectId == null` | Noop 분석·기본값 원격 설정·Crashlytics 없음 |

## 6. 정적 분석 규칙 (`factory_lints`)

- `analyzer.language`: `strict-casts`, `strict-inference`, `strict-raw-types` = true
- `analyzer.errors`: 모든 lint를 `error` 수준으로 승격하지 않고, CI에서 `flutter analyze --fatal-infos --fatal-warnings`로 강제
- 포함 규칙(발췌): `package:lints/recommended.yaml` 전부 + `always_declare_return_types`, `avoid_dynamic_calls`, `avoid_print`,
  `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `unawaited_futures`, `prefer_const_constructors`,
  `prefer_const_declarations`, `prefer_final_locals`, `use_build_context_synchronously`, `implementation_imports`,
  `avoid_slow_async_io`, `use_key_in_widget_constructors`, `public_member_api_docs`(packages 한정), `require_trailing_commas`
