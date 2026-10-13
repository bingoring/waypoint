---
artifact: frontend-components
build-spec: core-packages
status: DRAFT
updated: 2026-10-13
---

# Frontend Components — Core Packages

> 1-2 §0에 따라 코어는 **화면을 제공하지 않는다.** 이 문서는 앱이 배치하는 부품과 테마 생성만 다룬다.

## 1. 컴포넌트 목록

| 컴포넌트 | 패키지 | 역할 |
|---|---|---|
| `BannerSlot` | factory_ads | 적응형 하단 배너 1개 |
| `FactoryTheme.fromTokens` | factory_ui | `DesignTokens` → 라이트·다크 `ThemeData` |
| `RemoveAdsTile` | factory_ui | 광고 제거 구매 |
| `RestorePurchasesTile` | factory_ui | 구매 복원 |
| `LanguageTile` | factory_ui | 앱 언어 선택(`locales`가 2개 이상일 때만 표시) |
| `PrivacyOptionsTile` | factory_ui | UMP 개인정보 옵션(필요할 때만 표시) |
| `ContactTile` | factory_ui | 문의 메일 + 개인정보처리방침 링크 |
| `VersionTile` | factory_ui | 앱 버전·빌드 번호 |

## 2. 상세

### `BannerSlot`
- **props:** `placementId: String` (필수, `banner_` 접두사).
- **상태:** `loading` → `loaded`(배너 표시) / `failed`(높이 0) / `hidden`(adFree·광고 비활성 → 높이 0).
- **크기:** `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width)`. 로드 전에는 **높이 0**(자리 예약 없음 — 빈 공간이 생기지 않게). 로드되면 위에 8dp 여백을 포함해 펼친다(R: 버튼과 8dp 이상 간격).
- **수명:** 위젯 `dispose`에서 `BannerAd.dispose()`. 다른 라우트가 위에 올라와 가려지면 `RouteAware`(`factory_runtime`이 `RouteObserver`를 제공하고 앱의 `navigatorObservers`에 등록)의 `didPushNext`에서 dispose하고, `didPopNext`에서 새로 로드한다(1-3 §7.4 메모리 규칙).
- **이벤트:** 배너는 `ad_show_attempt`를 기록하지 않는다(노출마다 기록하면 이벤트가 과다) `(AI)`.
- **배치 규칙(문서화, 코드로 강제 불가):** 화면당 1개, `Scaffold.bottomNavigationBar` 또는 본문 하단 고정. 스크롤 목록 안 금지.

### `FactoryTheme.fromTokens(DesignTokens t) → (ThemeData light, ThemeData dark, ThemeMode mode)`
- `ColorScheme.fromSeed(seedColor, brightness)`; `cornerRadius` → 카드·버튼·입력·다이얼로그 모양; `density` → `VisualDensity.compact/standard`;
  `fontFamily` → `textTheme`. `iconStyle`은 `FactoryIcons.of(context)`로 노출(앱이 아이콘 집합을 고를 때 사용).
- Material 3 사용. 앱은 결과를 `copyWith`로 추가 조정할 수 있다.

### 설정 행 6종 (공통)
- 모두 `ListTile` 기반 `StatelessWidget`/`ConsumerWidget`이며 앱 테마를 그대로 따른다. 섹션 제목·순서·구분선은 **앱이 정한다.**
- `RemoveAdsTile`: 가격은 스토어 현지화 문자열(R-IAP-4). 상태 `loadingPrice` · `available(price)` · `owned`(체크 표시, 비활성) · `unavailable`(숨김). 탭 → `purchaseRemoveAds()`, 진행 중에는 비활성.
- `RestorePurchasesTile`: 탭 → `restore()` → 결과 스낵바(`복원되었습니다` / `복원할 구매가 없습니다`). 항상 표시(R-IAP-5).
- `PrivacyOptionsTile`: `ConsentState.privacyOptionsRequired`가 true일 때만 렌더링.
- `ContactTile`: `mailto:` 실행 전 `suppressNextAppOpen()`.

## 3. 문자열 (ko·en)

`factory_ui`가 `FactoryLocalizations`(gen-l10n ARB)로 위 부품 문자열만 제공한다. 앱 문자열은 앱이 자체 ARB로 관리한다.
키: `removeAds`, `removeAdsOwned`, `restorePurchases`, `restoreDone`, `restoreNothing`, `language`, `privacyOptions`, `contact`, `privacyPolicy`, `version`, `purchasePending`, `purchaseFailed`.

## 4. 화면 상태

화면이 없으므로 N/A. 부품별 상태는 §2에 기술했다.
