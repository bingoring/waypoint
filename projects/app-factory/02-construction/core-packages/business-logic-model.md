---
artifact: business-logic-model
build-spec: core-packages
status: DRAFT
updated: 2026-10-13
---

# Business Logic Model — Core Packages

## 1. 주요 워크플로

### 1.1 `Bootstrap` — `runFactoryApp(AppDefinition def)` (factory_runtime)
1. **트리거:** 앱 `main()`.
2. **단계:**
   1. `WidgetsFlutterBinding.ensureInitialized()`; `Stopwatch` 시작.
   2. 디버그: `AppConfigValidator.validate(def.config, def.placements)` → 오류 있으면 assert 실패. 릴리스: R-ADS-3 검사.
   3. 저장소 열기(`SharedPreferencesAsync`) → `ScopedStore('core.')`, `ScopedStore('app.')`.
   4. Firebase: `firebaseProjectId != null`이면 `Firebase.initializeApp()` + Crashlytics 에러 훅(`FlutterError.onError`, `PlatformDispatcher.onError`) 연결. 아니면 Noop.
   5. 원격 설정: `activateFetched()` → `RemoteSnapshot` 고정(R-RC-4). 실패해도 기본값.
   6. `SessionTracker.onColdStart()` → 세션 번호 증가.
   7. 동의: `ConsentGateway.gather(timeout: 5s)` → `ConsentState`; `AnalyticsSink.setConsent`; `consent_result` 기록.
   8. `EntitlementService.load()` (캐시) → `PurchaseGateway.restore()`는 **기다리지 않고** 시작(BLM §1.6).
   9. `canRequestAds && adsEnabled && !adFree`이면 `AdGateway.initialize()` 후 선언된 전면형 placement 미리 로드(기다리지 않음).
   10. 사용자 속성(`app_category`, `ad_free`, `app_locale`) 설정.
   11. `runApp(ProviderScope(overrides: [...services], child: def.buildApp(services)))`.
   12. 다음 프레임 이후: `RemoteConfigSource.fetchInBackground()`.
3. **결과:** 앱 첫 프레임. 2~10단계의 실패는 기능을 막지 않는다(각 단계 `try`·로그·폴백).
4. **적용 규칙:** R-ADS-3·4, R-RC-4, R-SES-1, INV-RC-1, NFR 부트스트랩 ≤ 400ms(7단계의 사용자 폼 시간 제외).

### 1.2 `Lifecycle` (factory_runtime, `AppLifecycleListener`)
- `onHide/onPause` → `SessionTracker.onBackground(now)`.
- `onResume` → `SessionTracker.onForeground(now)` → 새 세션이면 `AdService.onNewSession()`; 그다음 `AdService.onAppForeground(backgroundDuration)`(앱 오프닝 판정, §2.2).

### 1.3 `onTransition(placementId)` — 전면 광고
1. `placement = manifest.placement(id)` (없으면 assert).
2. `transitionsSinceShown[id] += 1`.
3. `decision = InterstitialPolicy.decide(...)` (§2.1).
4. `decision == shown` → `result = await gateway.showFullscreen(interstitial, unit)`.
   - `shown/dismissedAfterShow` → `lastFullscreenAt = now`, `sessionInterstitialCount += 1`, `transitionsSinceShown[id] = 0`, 다음 광고 로드.
   - `failedToShow` → decision을 `notLoaded`로 바꾸고 로드 재시도.
5. `ad_show_attempt{placement, format, result}` 기록 (INV-ADS-5).
6. 반환 `Future<AdDecision>` — 앱은 결과를 기다린 뒤 다음 화면으로 이동한다(광고가 닫힌 뒤 이동).

### 1.4 `showRewarded(placementId) → RewardOutcome`
1. `adFree` → `adFree` 반환(보상 지급은 앱이 `earned`와 동일 취급).
2. `!adsEnabled || !canRequestAds` → `unavailable`.
3. 미로드 → 로드 시도, 5초 대기 → 실패 시 `unavailable`.
4. 표시 → `earnedReward` 콜백 받았으면 `earned`, 아니면 `dismissed`. `lastFullscreenAt = now`. 다음 광고 로드.
5. `reward_outcome` 기록. 반환값과 `placement.grantOnUnavailable`로 앱이 보상 여부 결정: `RewardOutcome.grants(placement)` 헬퍼 제공
   (`earned`·`adFree` → true, `unavailable` → `grantOnUnavailable`, `dismissed` → false).

### 1.5 앱 오프닝 광고
- `onAppForeground(bg)` → `AppOpenPolicy.decide(...)`(§2.2) → `shown`이면 표시, `lastFullscreenAt = now`. `suppressNextAppOpen`은 판정 후 항상 false로 초기화.
- 콜드 스타트에서는 표시하지 않는다(1-2 §4: 콜드 스타트의 동의 폼 직후 금지 → Wave 1은 복귀 시에만).

### 1.6 광고 제거 결제 (`EntitlementService`)
- **구매:** `purchaseRemoveAds()` → `suppressNextAppOpen()` → `gateway.buy(productId)` → `updates` 스트림에서 결과 처리 → `remove_ads_result` 기록.
- **업데이트 처리:** §3.2 상태 기계. `purchased/restored` → 저장 → `complete()` → `adFree` 스트림 방출 → `AdService`가 미리 로드한 광고 `disposeAll()`, 배너 슬롯은 높이 0으로 접힘.
- **시작 시 동기화:** `restore()` 호출 → 응답 스트림이 **완료 신호** 안에 상품을 포함하지 않으면 R-IAP-3에 따라 하향. `in_app_purchase`의 restore는 완료 신호가 없으므로,
  Android는 `InAppPurchaseAndroidPlatformAddition.queryPastPurchases()` 결과(성공·목록)를 기준으로 판정한다 `(AI)`.

## 2. 알고리즘

### 2.1 `InterstitialPolicy.decide`
```
input: cfg: AdPolicyConfig, st: AdRuntimeState, session: SessionState,
       placement, adFree, canRequestAds, isLoaded, now
if !cfg.adsEnabled || !canRequestAds          -> disabled
if adFree                                      -> adFree
if session.index <= cfg.graceSessions          -> grace
if st.sessionInterstitialCount >= cfg.interstitialSessionMax -> cappedSession
if st.lastFullscreenAt != null:
   if now < st.lastFullscreenAt                -> (st.lastFullscreenAt = now) cappedInterval   # 시계 역행
   if now - st.lastFullscreenAt < cfg.interstitialMinInterval -> cappedInterval
n = cfg.everyNOverrides[placement.id] ?? placement.everyN
if st.transitionsSinceShown[placement.id] < n  -> everyN
if !isLoaded                                   -> notLoaded
return shown
```
- 판정 순서는 위 순서로 고정한다(분석 이벤트의 `result`가 결정적이도록).
- `everyN`은 "마지막 노출 이후 전환 수 ≥ N"이다. 다른 조건에 막히면 기회는 유지되고, 조건이 풀린 다음 전환에서 노출된다.

### 2.2 `AppOpenPolicy.decide`
```
if placement app_open 미선언                   -> (판정 없음, 이벤트 없음)
if !cfg.adsEnabled || !canRequestAds          -> disabled
if adFree                                      -> adFree
if st.suppressNextAppOpen                      -> (이벤트 없음, 억제 해제)
if session.index <= cfg.graceSessions          -> grace
if bg < cfg.appOpenMinBackground               -> (이벤트 없음)
if lastFullscreenAt 간격 < cfg.interstitialMinInterval -> cappedInterval
if !isLoaded                                   -> notLoaded
return shown
```

### 2.3 `RatingService.positiveMoment()`
```
moments += 1
if moments >= cfg.minMoments
   && daysSince(firstLaunchAt) >= cfg.minDays
   && (lastPromptAt == null || now - lastPromptAt >= 90d)
   && (lastFullscreenAt == null || now - lastFullscreenAt >= 10s)
   && await review.isAvailable():
      suppressNextAppOpen(); await review.requestReview()
      moments = 0; lastPromptAt = now; log rating_prompt{moment_count}
```

## 3. 상태 전이

### 3.1 세션
| 현재 | 이벤트 | 다음 | 액션 |
|---|---|---|---|
| (없음) | 콜드 스타트 | 세션 n+1 | 저장 `index`, `sessionInterstitialCount=0` |
| 활성 | 백그라운드 | 백그라운드 | `backgroundedAt = now` |
| 백그라운드 | 복귀, 경과 < 30분 | 활성(같은 세션) | 앱 오프닝 판정 |
| 백그라운드 | 복귀, 경과 ≥ 30분 | 세션 n+1 | `onNewSession`, 앱 오프닝 판정 |

### 3.2 광고 제거 권리
| 현재 | 이벤트 | 다음 | 액션 |
|---|---|---|---|
| `none` | `purchased` | `purchase` | 저장, complete, 이벤트 `purchased` |
| `none` | `restored` | `restore` | 저장, complete, 이벤트 `restored` |
| 임의 | `pending` | 동일 | 안내만 |
| 임의 | `error`/`canceled` | 동일 | 이벤트 `failed`/`cancelled` |
| `purchase`/`restore` | 과거 구매 조회 성공 & 상품 없음 | `none` | 저장, 광고 다시 허용(다음 세션부터) |
| `purchase`/`restore` | 조회 실패 | 동일 | — (INV-IAP-1) |

## 4. 시퀀스 — 첫 실행(EEA 사용자)

```
main → runFactoryApp → 저장소 → (Firebase) → 원격 activate → 세션 #1
     → UMP gather: 동의 폼 표시 → 사용자 선택 → ConsentState(canRequestAds=true)
     → Entitlement 캐시(none) → restore() 시작(비동기)
     → AdGateway.initialize → 전면·보상형 미리 로드(비동기)
     → runApp → 첫 프레임 → fetchInBackground
사용자: 결과 확인 → 다음 행동 → onTransition('interstitial_result')
     → decide: session 1 ≤ grace 1 → grace → ad_show_attempt{result: grace}
```

## 5. 통합 지점

| 대상 | 호출 시점 | 실패 처리 |
|---|---|---|
| UMP (`ConsentInformation.requestConsentInfoUpdate`, `ConsentForm.loadAndShowConsentFormIfRequired`) | 부트스트랩 7 | 5초 타임아웃 → 저장된 `canRequestAds` 사용 |
| `MobileAds.instance.initialize` | 부트스트랩 9 | 실패 로그, 광고 없음 |
| `InterstitialAd/RewardedAd/AppOpenAd.load` | 미리 로드, 표시 후 | 실패 시 지수 백오프 재시도 (10s·30s·60s, 최대 3회/세션) `(AI)` |
| Firebase Remote Config `activate`/`fetch` | 부트스트랩 5·12 | 기본값 |
| Firebase Analytics `logEvent` | 이벤트마다 | 오류 무시(로그) |
| Crashlytics | 에러 훅 | — |
| `in_app_purchase` `buyNonConsumable`/`restorePurchases`/`completePurchase` | 구매·시작 | §3.2 |
| `in_app_review` `requestReview` | §2.3 | 무시 |
