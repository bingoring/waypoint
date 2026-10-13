---
build-spec: core-packages
stage: 02-construction/01-core-packages
status: READY
depth: comprehensive
updated: 2026-10-13
---

# Build Spec — Core Packages

## §0. 개요 & 범위
- **목표(한 줄):** 1-2 계약과 1-3 품질 기준을 구현한 공통 코어 패키지 7개 + 저장소 골격 + CI 품질 게이트.
- **SoT:** [1-2 Domain Model](../../01-inception/02-domain-model.md) §0~§9(+ 승인 결과 D1~D3), [1-3 Architecture](../../01-inception/03-architecture-decision.md) §3·§4·§7·§8.
- **규모/제약:** 화면 없음(1-2 §0). 앱 30개 이상이 의존할 수 있으므로 공개 API는 작게 유지하고, 깨지는 변경은 워크스페이스 전체 빌드로 즉시 드러나게 한다.
- **깊이 티어 & 사유:** `comprehensive` — 모든 앱의 기반이며 광고·결제·동의는 정책 위반 시 계정 위험(1-1 E2·E4)이 있다.

## §1. 분해 (Decomposition)

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| 저장소 골격 | 루트 `pubspec.yaml`(workspace + `melos:`), `.fvmrc`, `analysis_options.yaml`, Melos 스크립트 | — | 신규 |
| `factory_lints` | 공통 정적 분석 규칙(1-3 §7.2) | `lints` | 신규 |
| `factory_core` | **순수 Dart.** AppConfig·DesignTokens·AdPlacement 모델과 검증기, 원격 키 정의, 분석 이벤트 스키마, 게이트웨이 인터페이스, 서비스 구현(AdService·EntitlementService·RatingService·SessionTracker), 정책 판정 | `meta` | 신규 |
| `factory_runtime` | 부트스트랩, Riverpod provider, `runFactoryApp`, 키-값 저장소(`SharedPreferencesAsync`), 앱 생명주기 → 세션 연결, 리뷰 요청 게이트웨이(`in_app_review`), 에러 수집 연결 | core, `flutter_riverpod`, `shared_preferences`, `in_app_review` | 신규 |
| `factory_ads` | `google_mobile_ads` 게이트웨이(전면·보상형·앱 오프닝 로드/표시, UMP 동의), `BannerSlot` 위젯 | core, runtime, `google_mobile_ads` | 신규 |
| `factory_firebase` | Analytics·Remote Config·Crashlytics 게이트웨이 | core, `firebase_*` | 신규 |
| `factory_iap` | `in_app_purchase` 게이트웨이 | core, `in_app_purchase` | 신규 |
| `factory_ui` | `DesignTokens → ThemeData`, 설정 행 부품 6종, 다국어 문자열(ko·en) | core, runtime | 신규 |
| `examples/core_demo` | 비출시 검증 앱: 부트스트랩·광고(테스트 ID)·광고 제거·설정 부품 통합 테스트. 1-3 §3 트리에 없던 `examples/` 디렉터리를 추가한다(릴리스 파이프라인 대상 아님, 의존 규칙은 `apps/`와 동일) | 위 전부 | 신규 |
| CI (`.github/workflows/ci.yml`) | 품질 게이트(§5) | — | 신규 |

## §2. 아티팩트 인덱스 (Manifest)
| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) — 화면은 없고 부품(배너 슬롯·설정 행)과 테마만 다룬다 |

## §3. 미해결 질문 (Open Questions)

- [x] Q1: 기준 기기 → **API 36 에뮬레이터(중급 사양)로 우선 측정**, 실기기가 정해지면 재측정. 에뮬레이터 수치는 참고값 → DECISIONS `2026-10-13 · 2-1 Build Spec READY`
- [x] Q2: `READY` 승인(2026-10-13, 오너) — `(AI)` 세부값과 §7 편차(동의를 첫 프레임 뒤로) 포함

> 기술적 세부(세션 기준 30분, 원격 값 클램프 범위, 타임아웃 등)는 AI가 정해 business-rules에 명시했다. 승인 시 함께 확정된다.

## §4. 구현 체크리스트

**골격**
- [x] 로컬 도구: Android cmdline-tools + platform 36 + API 36 에뮬레이터 이미지 설치
- [x] 루트 `pubspec.yaml`(workspace: `packages/*`, `examples/*`; `melos:` 스크립트 `analyze`·`test`·`format:check`·`coverage`·`deps:check`), `.fvmrc`(3.47.7), `analysis_options.yaml`
- [x] `factory_lints` 규칙 세트 (BR §6)
- [x] `tool/check_deps.dart`: 의존 방향·금지 import 검사 (BR R-ARCH-1~4)

**factory_core**
- [x] 모델: `AppConfig`·`DesignTokens`·`AdPlacement`·`AdUnitIds`·`IapConfig`·`Links` + `AppConfigValidator` (DE §2, BR §2)
- [x] 원격 키: `RemoteKey<T>`·`CoreKeys` + 클램프 (DE §2.6, BR R-RC-*)
- [x] 분석: `AnalyticsEvent`·`CoreEvents`·`EventNameRules` (DE §2.7, BR R-AN-*)
- [x] 게이트웨이 인터페이스 6종 + `Clock` (DE §2.9)
- [x] `SessionTracker` (BLM §3.1)
- [x] `InterstitialPolicy`·`AppOpenPolicy` 순수 판정 함수 (BLM §2.1·§2.2)
- [x] `AdService` (전환·보상형·앱 오프닝·억제) (BLM §1.3~§1.5)
- [x] `EntitlementService` (BLM §1.6, §3.2)
- [x] `RatingService` (BLM §2.3)
- [x] 단위 테스트: 분기 커버리지 ≥ 90%

**어댑터·런타임·UI**
- [x] `factory_runtime`: `runFactoryApp`, 부트스트랩(BLM §1.1), provider, 저장소, 생명주기 연결, 에러 수집 연결
- [x] `factory_ads`: `GoogleAdsGateway`, `UmpConsentGateway`, `BannerSlot`
- [x] `factory_firebase`: `FirebaseAnalyticsSink`, `FirebaseRemoteConfigSource`, `CrashlyticsReporter`, Firebase 미설정 시 no-op 모드
- [x] `factory_iap`: `StorePurchaseGateway`
- [x] `factory_ui`: `FactoryTheme.fromTokens`, 설정 행 6종, ko·en 문자열

**검증·CI**
- [x] `examples/core_demo` + 통합 테스트(에뮬레이터)
- [x] `.github/workflows/ci.yml` (§5 자동 항목 전부)

## §5. 검증 계획
- [x] `dart format --set-exit-if-changed` = 0, `flutter analyze` 경고·정보 0 — `public_member_api_docs` 포함 (2026-10-13)
- [x] 단위 테스트: `factory_core` 분기 커버리지 ≥ 90% (`melos run coverage`), 어댑터는 가짜 플랫폼 채널 없이 *매핑 로직*만 테스트 — core 84개, 라인 99.1% (분기는 §7 편차) · firebase 5 · iap 3
- [x] 위젯 테스트: `BannerSlot`(adFree 시 높이 0), 설정 행 부품, `FactoryTheme` 토큰 반영 + `leak_tracker` 누수 0 — runtime 12 · ads 7 · ui 9, 누수 0
- [x] 의존 방향·금지 import 검사 통과 (`melos run deps:check`) — 위반 7종을 넣은 가짜 저장소로 검출도 확인
- [x] 비밀 스캔(gitleaks), OSV 스캔(`pubspec.lock`) 통과 — gitleaks 8.30.1 유출 0, OSV 136개 패키지 취약점 0
- [x] 통합 테스트(`examples/core_demo`, Android 에뮬레이터 API 36): 부트스트랩 → 홈 → 전환 3회 → 전면 광고(테스트 ID) 판정 이벤트 확인 → 보상형 → 설정에서 광고 제거 행 표시
- [x] 수동: UMP 폼(EEA 디버그 지역 강제)이 뜨고, 거부 후에도 광고가 로드되는지(비맞춤) — 폼이 첫 화면 위에 표시됨, 거부 후 테스트 배너 로드, 설정에 개인정보 옵션 행 표시 (2026-10-13)
- [x] 수동(기기): 전면형 광고 표시 경로 — 세션 2에서 테스트 전면 광고 표시 → 닫기 후 `interstitial: shown`, 즉시 재시도 `capped_interval`.
  95초 백그라운드 후 복귀 시 테스트 앱 오프닝 광고 표시(백그라운드에서 로드). 설정의 개인정보 옵션 → UMP 옵션 폼 표시.
  `GoogleAdsGateway`의 표시·콜백 경로는 단위 테스트가 없고 이 확인이 유일한 기기 검증이다. 보상형 표시는 수동 확인 대기(테스트 영상 시청 필요)
- [x] NFR §6 측정값 기록(예제 앱 기준) — 아래 §6 측정 결과

## §6. NFR · 성능

| 항목 | 목표 | 측정 |
|---|---|---|
| 부트스트랩 지연 (runApp까지. 동의·광고 초기화는 첫 프레임 뒤라 포함되지 않음) | ≤ 400ms (기준 기기, 릴리스) | `Stopwatch` 계측 → 디버그 로그, 통합 테스트에서 상한 검사 |
| 코어가 추가하는 메모리 | 광고 미리 로드 포함 ≤ 60MB PSS (빈 Flutter 앱 대비) | `dumpsys meminfo` 비교 |
| 미리 로드 광고 수 | 전면 ≤ 1, 보상형 ≤ 1, 앱 오프닝 ≤ 1 (선언한 경우) | 단위 테스트(INV-ADS-2) |
| 네트워크 대기 | 첫 프레임 전에는 네트워크를 전혀 기다리지 않음. 동의 갱신은 첫 프레임 뒤 비동기(상한 5초) | BLM §1.1 순서 테스트 |
| 보안 | 코어는 개인 식별 정보 저장·전송 0, 평문 HTTP 0 | 코드 리뷰 + 분석 이벤트 매개변수 검증 |
| 공개 API | 앱이 import할 수 있는 라이브러리 진입점은 패키지당 1개(`package:<name>/<name>.dart`), `src/` 직접 import 금지 | lint(`implementation_imports`) |

### §6 측정 결과 (2026-10-13, API 36 에뮬레이터 Pixel 6 프로필, 프로파일 빌드, PSS는 실행 20초 후)

| 구성 | 콜드 스타트(중앙값) | PSS |
|---|---|---|
| 빈 Flutter 앱(기준선) | 987ms | 82MB |
| core_demo, 광고 없음(코어·결제·UI) | — | 118MB (+36MB) |
| + 광고 SDK 초기화만 | — | 162MB (+44MB) |
| + 배너 | — | 170MB |
| + 전면 1개 미리 로드 | — | 165MB |
| core_demo 전체(배너 + 전면) | 1,190ms | 173MB |

- **콜드 스타트:** 1,190ms ≤ 1.5초 ✅. 통합 테스트 첫 프레임 837ms(디버그).
- **메모리:** 1-3 §7.4 "유틸리티 ≤ 150MB"와 §6 "코어 추가분 ≤ 60MB"를 **넘는다** ❌. 측정상 원인은 광고 SDK 초기화 자체(+44MB, WebView)이고,
  코어가 통제하는 광고 객체는 +11MB, 광고 없는 코어 추가분은 +36MB(대부분 Dart VM·렌더러 영역 — 한글 글리프 캐시 추정, `추론`)다.
  미리 불러오기를 줄여 183MB → 173MB로 낮췄다. AdMob을 쓰는 한 150MB는 달성할 수 없으므로 **예산 조정을 오너에게 요청**한다(F3: "2-1 실측 후 조정").

## §7. 편차 로그 (Deviations) — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| 1-2 §3 부트스트랩: 동의·광고 초기화 → `runApp` | `runApp` → 첫 프레임 후 동의·광고 초기화 (BLM §1.1-5) | 1-3 §7.4 콜드 스타트 1.5초와 충돌. 동의 전 광고 요청 금지는 유지 — Build Spec 작성 시 승인 대상 |
| 1-3 §3 저장소 트리 | `examples/` 디렉터리 추가 | 비출시 검증 앱 위치 |
| §5 "분기 커버리지 ≥ 90%" | **라인** 커버리지 ≥ 90% 게이트 (`tool/coverage_gate.dart`). lcov에 분기 데이터가 생기면 분기도 자동 검사 | Dart 3.13 `dart test --branch-coverage`가 BRDA를 내놓지 않음(2026-10-13 확인). 현재 라인 99.1% |
| BR R-ADS-10 `tagForChildDirectedTreatment=no`, `tagForUnderAgeOfConsent=no` | `ageRestrictedTreatment: unspecified` + `maxAdContentRating: T` | `google_mobile_ads` 9.1.0에서 두 속성이 deprecated (소스 확인). 의도(어린이 대상 아님)는 동일 |
| FC §2 `getCurrentOrientationAnchoredAdaptiveBannerAdSize` | `AdSize.getLargeAnchoredAdaptiveBannerAdSize` | 9.1.0에서 deprecated |
| DE §2.9 `PurchaseGateway.restore()` | 제거하고 `queryPastPurchases()`로 대체 | BLM §1.6 결정대로 Android 과거 구매 조회가 복원과 하향 판정을 모두 맡는다. iOS는 확장 시 설계(그 전까지 조회 실패로 처리해 권리를 내리지 않음) |
| (신규) R-ADS-12 | 전면형 광고를 표시하는 동안에는 앱 오프닝 광고를 판정하지 않는다 | 구현 중 발견한 결함: 보상형 광고를 30초 넘게 보고 닫으면 복귀 이벤트가 표시 완료보다 먼저 와서 앱 오프닝 광고가 연달아 뜰 수 있었다. 회귀 테스트 추가(수정 전 실패 확인) |
| (신규) `FactoryServices.dispose()` | 동의 `ValueNotifier`·광고·결제 구독 해제, `FactoryRoot` 해제 시 호출 | leak_tracker가 미해제 `ValueNotifier`를 검출 |
| BR §5 동의 갱신 타임아웃 5초 | 타임아웃은 **동의 정보 갱신(네트워크)** 에만 적용, 동의 폼은 사용자 응답까지 대기 | 폼에도 5초를 걸면 사용자가 읽는 도중 판정해 그 세션 광고를 잃는다 |
| 1-2 §7 Consent Mode 표 | 동의함(`obtained`)이면 신호를 직접 설정하지 않고 Firebase가 UMP의 TCF 문자열을 읽게 둔다 | UMP 결과에는 목적별 동의가 없어 직접 매핑하면 부정확하다 |
| FC §2 `VersionTile` "버전·빌드 번호" | `AppConfig.version`만 표시 | 빌드 번호를 읽으려면 `package_info_plus` 의존성이 추가로 필요하다. 2-2 코드 생성에서 빌드 번호를 상수로 넣을 때 함께 표시 |
| 1-3 §4 라이브러리 목록 | `url_launcher` 추가 (factory_ui: 문의 메일·개인정보처리방침 열기) | Android 권한 추가 없음(`<queries>`만) — 1-3 §4 의존성 정책 (3) 충족 |
| BLM §1.1-10-2 "선언된 전면형 placement 미리 로드" | 시작 시 **전면 광고만** 미리 로드. 보상형은 `prepareRewarded()`·`showRewarded()`에서, 앱 오프닝은 `onAppBackground()`에서 로드하고 표시 후 바로 다시 불러오지 않음 | 메모리 예산(1-3 §7.4). WebView 6 → 4개, PSS 183 → 173MB |
| (신규) 판정 컨텍스트 | 광고 SDK 초기화 전·실패 상태의 전환은 `disabled`가 아니라 `grace`·`not_loaded` 등 실제 사유로 기록 | 통합 테스트가 발견: `disabled`(원격 정지·동의 없음)로 잘못 집계되어 빈도 조정 근거가 왜곡됨. 회귀 테스트 추가 |
| §5 통합 테스트 "전환 3회 → 전면 광고" | 자동 테스트는 첫 세션 유예(`grace`)·동의·배너 로드·설정 부품까지. 전면·보상형·앱 오프닝 **표시**는 수동 확인 | 실제 광고는 네이티브 화면이라 통합 테스트가 닫기 버튼을 누를 수 없다(표시 완료를 기다리면 멈춘다) |
