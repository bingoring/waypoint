---
phase: 01-inception
stage: 03-architecture-decision
status: AI_PROPOSED
updated: 2026-10-13
---

# [Stage 1-3] Architecture Decision ⚠️ 비가역 게이트

## 목적

App Factory의 기술 스택과 저장소 구조를 확정한다. 이 결정은 모든 Construction 스테이지와 앞으로 만들 모든 앱의 기반이 되므로,
번복하면 코어와 출시된 앱 전체를 다시 만들어야 한다.

## 입력 (Inputs)

- [`02-domain-model.md`](02-domain-model.md) (HUMAN_APPROVED 필요)
- [`01-context-synthesis.md`](01-context-synthesis.md) §2 외부 제약, §6 공통 모듈 요구사항
- [`../DECISIONS.md`](../DECISIONS.md) — 사용자 선호: Flutter + Melos

## 체크리스트

- [x] 프레임워크: Flutter + Melos 확정 (React Native·Expo 대비 탈락 이유 문서화). 현재 안정 버전은 공식 문서로 확인(FRAMEWORK "외부 사실 표기")
- [x] 모노레포 구조: `packages/`(코어·게임 키트) / `apps/`(앱별 프로젝트) 경계
- [x] 앱 분리 방식: 앱마다 독립 Flutter 프로젝트 vs 하나의 프로젝트 + flavor (포트폴리오 규칙 P3, 서명 키 분리, 빌드 시간 관점)
- [x] 상태 관리 (Riverpod / Bloc / 기타)
- [x] 게임 구현 방식: Flame 엔진 vs 순수 Flutter 위젯·CustomPainter
- [x] 광고·동의·분석·원격 설정·인앱결제 라이브러리 선정과 버전
- [x] 빌드·배포: fastlane / GitHub Actions / Codemagic 비교, 서명 키 보관 방식
- [x] 각 결정의 대안 탈락 이유 문서화
- [x] **품질 기준(리뷰 기준선):** 코드 구조 규칙, 정적 분석, 보안·개인정보, 메모리·크기·안정성 예산 (오너 요구, 2026-10-13: "스토어 심사·보안 검토 기준이 더 엄격해졌으므로 코드를 더 체계적이고 메모리 효율적으로")

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

> 외부 사실은 모두 **2026-10-13 조회**다. 버전은 pub.dev API의 latest 값이다. 확인 수준을 표기하지 않은 항목은 `공식 확인`이다.

### 1. 결정 요약

| # | 영역 | 결정 | 주요 탈락 대안 |
|---|------|------|--------------|
| A1 | 프레임워크 | **Flutter 3.47.7 (Dart 3.13.5)**, 저장소에서 버전 고정 | React Native + Expo, 네이티브, Unity |
| A2 | 모노레포 | **Dart pub workspace + Melos 8.9** (설정은 루트 `pubspec.yaml`의 `melos:` 키) | Melos 구버전 방식(`melos.yaml`), 저장소 분리 |
| A3 | 앱 분리 | **앱마다 독립 Flutter 프로젝트** (`apps/<slug>/`), 공통은 패키지로 공유 | 한 프로젝트 + flavor |
| A4 | 코어 분할 | **기능별 패키지로 쪼갬.** 앱은 쓰는 패키지만 의존 → 쓰지 않는 권한·SDK가 앱에 들어가지 않음 | 단일 `core` 패키지 |
| A5 | 상태 관리 | **Riverpod 3** (`flutter_riverpod` 3.4.3), 코드 생성 없이 수동 provider | Bloc, Provider, GetX |
| A6 | 게임 | Wave 1 퍼즐은 **순수 Flutter**(위젯·CustomPainter·암시적 애니메이션). 실시간 루프가 필요한 게임에서만 Flame 1.38 도입 | 처음부터 Flame |
| A7 | Firebase | **앱마다 Firebase 프로젝트 1개** | 포트폴리오 공용 프로젝트 1개 |
| A8 | CI/CD | **GitHub Actions(Linux) + fastlane `supply`** → Play 내부 테스트 트랙 업로드. 프로덕션 승격은 사람이 Play Console에서 수행 | Codemagic, 수동 업로드 |
| A9 | 서명 | **Play App Signing + 앱별 업로드 키** | 키 하나를 전 앱 공유 |
| A10 | 품질 | §7 품질 기준을 CI 게이트로 강제(실패 시 병합·업로드 불가) | 리뷰 시 수동 확인 |

### 2. 프레임워크 (A1) — Flutter 확정

| 기준 | Flutter | React Native + Expo | 네이티브 |
|------|---------|--------------------|---------|
| 게임(A) 렌더링 | 자체 렌더러, CustomPainter·Flame | 별도 엔진 필요(Skia 바인딩 등) | 최상 |
| AdMob | 공식 `google_mobile_ads` 9.1.0, UMP 내장(Android UMP 4.0.0) | 커뮤니티 라이브러리 | 공식 |
| 한 코드로 두 OS | 예 | 예 | 아니오(작업량 2배) |
| 오너 익숙도 | 낮음(학습 필요) | 높음(forin) | 중 |
| 여러 앱 대량 생산 | 패키지 공유 + 독립 앱 | `app.config.js`로 쉬움 | 어려움 |

- **탈락 이유:** Expo는 오너가 익숙하고 EAS 배포가 편하지만, 1-1에서 우선순위로 둔 게임 성능과 공식 AdMob 지원에서 밀린다. 네이티브는 "빠르게 찍어내기"와 맞지 않는다. Unity는 유틸리티 앱(B~E)에 과하다.
- **버전 고정:** 루트 `.fvmrc`(FVM)로 3.47.7을 고정하고, CI도 같은 버전을 쓴다. 모든 패키지의 `environment.sdk`는 `^3.12.0`(Riverpod 3·`in_app_purchase_android` 0.5.3 요구치)으로 맞춘다.
- **최소 요구 충족 확인:** `google_mobile_ads` 9.1.0은 Flutter ≥3.38.1, `noise_meter` 6.0.0과 `in_app_purchase_android` 0.5.3은 Flutter ≥3.44을 요구한다 → 3.47.7로 모두 충족.

### 3. 저장소 구조 (A2·A3·A4)

```
app-factory/                      (비공개, Q8)
├─ pubspec.yaml                   workspace: [packages/*, apps/*, tools/*] + melos: 스크립트
├─ pubspec.lock                   ← 워크스페이스 전체가 lock 하나를 공유 → 모든 앱이 같은 의존성 버전
├─ .fvmrc                         Flutter 3.47.7
├─ analysis_options.yaml          → factory_lints 포함
├─ packages/
│  ├─ factory_lints/              공통 정적 분석 규칙 (§7.2)
│  ├─ factory_core/               순수 Dart: AppConfig 모델, AppDefinition, AdPolicy 판정, 이벤트 스키마, 원격 키 정의
│  ├─ factory_runtime/            Flutter: 부트스트랩, FactoryServices 조립, Riverpod provider, 저장소
│  ├─ factory_ads/                google_mobile_ads + UMP 어댑터, 배너 슬롯
│  ├─ factory_firebase/           analytics·remote_config·crashlytics 어댑터
│  ├─ factory_iap/                in_app_purchase 어댑터, Entitlement
│  ├─ factory_ui/                 DesignTokens → ThemeData, 설정 행 부품(1-2 §3)
│  ├─ factory_notifications/      (선택) 로컬 알림 — E·B 앱만 의존
│  ├─ factory_share/              (선택) 이미지 카드 공유
│  └─ factory_game_kit/           (2-7) 점수·최고점·이어하기
├─ apps/
│  └─ <slug>/                     독립 Flutter 앱: app.yaml, lib/, android/, ios/, store/(등록 정보 원본)
├─ tools/
│  └─ factory_cli/                Dart CLI: new(앱 생성), validate(app.yaml·권한·이벤트 검증), codegen
├─ fastlane/                      공용 lane (앱 경로를 인자로 받음)
├─ .github/workflows/             ci.yml(검증), release.yml(앱별 업로드)
└─ docs/dlc/                      waypoint 서브모듈
```

**의존 방향 규칙** (CI에서 검사): `factory_core`는 Flutter·플러그인에 의존하지 않는다(순수 Dart, 단위 테스트가 빠름) →
어댑터 패키지(`ads`·`firebase`·`iap`·…)는 `core`의 인터페이스를 구현한다 → `runtime`이 조립한다 → 앱은 `runtime`과 필요한 선택 패키지만 의존한다.
앱끼리는 서로 의존할 수 없다.

**앱별 독립 프로젝트(A3) 근거**
- Flutter 공식 문서는 flavor를 "한 앱의 변형(스테이징·프로덕션)"으로 설명한다. 서로 다른 앱을 flavor로 만들면 AndroidManifest·권한·네이티브 의존성이 합쳐져, **쓰지 않는 권한과 SDK가 모든 앱에 들어간다.** 이는 심사(권한 사유 요구)와 보안 검토, 앱 크기에 모두 불리하다.
- 앱마다 `applicationId`, 서명 키, Firebase 설정, 버전이 독립적이다. 한 앱의 설정 실수가 다른 앱 빌드에 번지지 않는다.
- 단점은 `android/`·`ios/` 보일러플레이트 중복이다 → `factory_cli new`가 생성하고, 공통 Gradle 설정은 생성 템플릿에서 관리한다.

### 4. 라이브러리 (A5·A6 포함)

| 용도 | 패키지 | 버전 | 사용 패키지 | 비고 |
|------|-------|------|-----------|------|
| 광고·동의 | `google_mobile_ads` | 9.1.0 | factory_ads | UMP 포함. 앱 오프닝 광고 지원. minSdk 24 (`2차 자료` — 메인 브랜치 기준, 2-1에서 9.1.0 태그로 재확인) |
| Firebase | `firebase_core` / `firebase_analytics` / `firebase_remote_config` / `firebase_crashlytics` | 4.15.0 / 12.6.0 / 6.7.0 / 5.4.0 | factory_firebase | Crashlytics는 1-2에 없던 추가: §7.4 안정성 지표 때문 |
| 인앱결제 | `in_app_purchase` | 3.3.1 | factory_iap | Android 구현이 Play Billing Library 8.0.0 사용 → Play의 PBL 8 요구 충족 |
| 상태 관리 | `flutter_riverpod` | 3.4.3 | runtime, 앱 | 코드 생성(`riverpod_generator`)은 쓰지 않는다: build_runner 시간을 앱마다 반복하지 않기 위해 |
| 키-값 저장 | `shared_preferences` | 2.5.6 | runtime | `SharedPreferencesAsync` API만 사용(공식 권장) |
| 로컬 DB | `drift` | 2.35.2 | E 앱만 | Isar는 사실상 유지보수 중단(`추론`: 3.1.0이 2023년, Dart 3 미지원) → 탈락 |
| 로컬 알림 | `flutter_local_notifications` | 22.3.2 | factory_notifications | **정확 알람 권한을 쓰지 않는다**(§7.3) |
| 리뷰 요청 | `in_app_review` | 2.0.12 | runtime | |
| 공유 | `share_plus` | 13.3.1 | factory_share | |
| QR | `mobile_scanner` | 7.4.2 | 로또 앱 | |
| 소음 측정 | `noise_meter` 6.0.0 또는 `record` 7.1.2 | | 소음 측정기 | 2-5 Build Spec에서 결정 |
| 아이콘·스플래시 | `flutter_launcher_icons` / `flutter_native_splash` | 0.14.4 / 2.4.8 | 앱(dev) | launcher_icons는 16개월째 릴리스 없음 → 문제 시 `factory_cli`가 직접 생성 |
| 게임 | Flame | 1.38.2 | (보류) | A6: Wave 1 퍼즐은 턴 기반이라 위젯·CustomPainter로 충분하다 |

**의존성 정책:** 새 패키지는 (1) pub.dev에서 최근 12개월 안에 릴리스, (2) 공식(Google·Flutter·Firebase) 또는 널리 쓰이는 패키지,
(3) 추가하는 권한·네이티브 SDK를 PR에 명시, 세 조건을 만족해야 추가한다. 의존성 갱신은 월 1회 묶어서 하고, 워크스페이스 lock 하나로 전 앱에 반영한다.

### 5. Firebase (A7) — 앱마다 프로젝트 하나

- **근거:** Firebase 공식 문서는 한 프로젝트의 앱들이 "같은 앱의 변형"이어야 한다고 안내한다. 한 프로젝트의 앱은 Analytics 속성 하나를 공유하므로 서로 다른 앱의 지표가 섞인다. 원격 설정·Crashlytics 대상 지정도 복잡해진다.
- **비용·한도:** Spark 요금제의 프로젝트 수 한도는 "보통 5~10개"이고, Blaze 결제 계정이 있으면 늘릴 수 있다. 우리가 쓰는 Analytics·Remote Config·Crashlytics는 Blaze에서도 무료다.
  → 6번째 앱 전에 **Blaze 전환 + 예산 알림(예: 월 $1)** 을 설정하고, 필요하면 한도 증가를 요청한다.
- **AdMob 연결:** AdMob–Firebase 연결은 앱 단위이므로(`2차 자료`) 앱마다 연결한다. 연결 후 `ad_impression`에 수익이 들어오는지 DebugView로 확인한다(1-2 §6 재확인 항목, 3-1 체크리스트).

### 6. 빌드·배포·서명 (A8·A9)

| 후보 | 비용 | 판단 |
|------|------|------|
| **GitHub Actions(Linux) + fastlane supply** | 비공개 저장소 월 2,000분 무료. Linux 러너는 macOS 대비 약 10배 저렴 | **채택.** Android 먼저(Q3)라 macOS 러너가 필요 없다. fastlane 2.241은 활발히 유지되고, supply가 AAB와 등록 정보를 함께 올린다 |
| Codemagic | 개인 무료 월 500분(macOS M2), 동시 1개 | iOS 확장 시 재검토 |
| `r0adkll/upload-google-play` 액션 | 무료 | 커뮤니티 액션, 등록 정보 업로드 미지원 → 탈락 |

**흐름**
```
PR → ci.yml: format · analyze · test · factory_cli validate · 크기 예산 검사 (모든 앱)
태그 <slug>-v1.2.0 → release.yml: 해당 앱만 빌드(AAB, 난독화) → 디버그 심볼을 Crashlytics에 업로드
                    → fastlane supply → Play "내부 테스트" 트랙
사람: 내부 테스트 기기로 확인 → Play Console에서 프로덕션으로 승격 (P5 출시 속도는 사람이 관리)
```

**서명:** Play App Signing을 쓴다(앱 서명 키는 Google이 보관). 업로드 키는 **앱마다 따로** 만들어, 키 하나가 유출되어도 영향이 한 앱에 그친다.
업로드 키와 Play 서비스 계정 JSON은 GitHub Actions 암호화 시크릿에 두고, 원본은 오너의 비밀번호 관리자에 백업한다. 저장소에는 절대 커밋하지 않는다(§7.3 검사).

### 7. 품질 기준 (A10) — 리뷰 기준선

> 오너 요구(2026-10-13): 스토어 심사·보안 검토가 엄격해졌으므로 코드를 더 체계적이고 메모리 효율적으로 짠다.
> 이 절은 FRAMEWORK "리뷰 기준선"이다. R-1 독립 리뷰는 이 기준으로 판정한다.

**7.1 코드 구조**
- 앱 내부는 `lib/domain/`(순수 Dart: 계산·규칙·모델) · `lib/data/`(저장·원격 설정 접근) · `lib/ui/`(위젯) 3층으로 나눈다. `domain`은 Flutter를 import하지 않는다.
- 상태는 Riverpod provider로만 공유한다. 전역 싱글턴·전역 가변 변수를 금지한다.
- 광고·결제·분석은 반드시 `FactoryServices`를 거친다. 앱이 `google_mobile_ads` 등을 직접 import하면 CI가 실패한다.

**7.2 정적 분석** (`factory_lints`)
- `strict-casts`·`strict-inference`·`strict-raw-types` 활성화, 경고 0개(경고도 CI 실패).
- `dart format` 위반, `print` 사용, 처리하지 않은 `Future`, 닫지 않은 `StreamSubscription`·`AnimationController`를 금지하는 규칙을 켠다.

**7.3 보안·개인정보·권한**
- **권한 허용 목록:** `app.yaml`에 `permissions:`를 선언하고, CI가 병합된 AndroidManifest의 실제 권한과 비교해 목록에 없는 권한이 있으면 실패시킨다.
  (1-2 AppConfig 계약 확장 — 아래 "1-2 계약 확장")
- 정확 알람(`SCHEDULE_EXACT_ALARM`·`USE_EXACT_ALARM`)은 쓰지 않는다. Android 14부터 기본 거부이고, `USE_EXACT_ALARM`은 알람·캘린더 앱 전용이다 → 물 마시기 알림은 부정확 반복 알림으로 충분하다.
- 릴리스 빌드: R8 축소, `--obfuscate --split-debug-info`, `android:allowBackup` 범위 지정, 평문 HTTP 금지(network security config), 디버그 로그 제거.
- 비밀 검사: 서명 키·서비스 계정 파일·`.env`가 커밋되면 CI가 실패한다(gitleaks 등 비밀 스캐너).
- 개인정보: 개인 식별 정보를 수집하지 않는다(1-2 §6). 앱마다 Play **데이터 보안 양식** 답변을 `apps/<slug>/store/data-safety.md`로 관리하고, SDK가 수집하는 항목(광고 ID, 기기 정보, 진단 정보)을 포함한다. iOS 확장 시 `PrivacyInfo.xcprivacy`를 추가한다.
- 대상 API: Play 요구사항에 따라 **targetSdk 36**(2026-08-31부터 신규 앱·업데이트 필수, 연장 시 2026-11-01).
- 의존성 취약점: CI에서 OSV 스캐너로 `pubspec.lock`을 검사한다.

**7.4 메모리·크기·안정성 예산** (중급 Android 기기 기준, 2-1에서 기준 기기 확정)

| 항목 | 유틸리티·트래커(B~E) | 게임(A) | 측정 방법 |
|------|-------------------|--------|----------|
| 콜드 스타트(첫 화면까지) | ≤ 1.5초 | ≤ 2.0초 | 릴리스 빌드, `adb shell am start -W` |
| 메모리(PSS, 일반 사용) | ≤ 150MB | ≤ 250MB | `adb shell dumpsys meminfo`, DevTools |
| 다운로드 크기 | ≤ 15MB | ≤ 25MB | `bundletool get-size total` — CI에서 초과 시 실패 |
| 사용자 체감 비정상 종료율 | < 0.5% | < 0.5% | Play Vitals (Play "나쁜 동작" 기준선 1.09%보다 엄격하게 — `2차 자료`, 3-1 전 재확인) |
| ANR율 | < 0.2% | < 0.2% | Play Vitals (기준선 0.47% — `2차 자료`) |

**메모리 규칙** (코드 리뷰 체크 항목)
- 광고 객체: 미리 불러 둔 광고는 형식마다 최대 1개(전면 1 + 보상형 1). 화면을 벗어난 배너는 `dispose`한다. 광고 객체는 `factory_ads`만 보유한다.
- 이미지: 표시 크기에 맞춰 디코딩(`cacheWidth`/`cacheHeight`), 큰 원본 에셋 금지(에셋 총량도 크기 예산에 포함).
- 목록은 `ListView.builder` 등 지연 생성만 사용하고, `const` 생성자를 기본으로 한다.
- 컨트롤러·구독·타이머는 반드시 해제한다 — 위젯 테스트에서 `leak_tracker`로 누수를 검사한다.
- 메인 isolate에서 16ms를 넘는 계산(예: 퍼즐 해 탐색, 대량 통계)은 `Isolate.run`으로 옮긴다.

**7.5 테스트 범위**
- `factory_core`: 광고 빈도 판정·보상형 처리·adFree 효과·원격 기본값 폴백 — 분기 커버리지 90% 이상.
- 앱 `domain`: 계산 로직은 기준값 표로 테스트(예: 연봉 실수령액은 공식 간이세액표의 샘플 값과 대조).
- 앱마다 최소 1개의 통합 테스트(부트스트랩 → 홈 → 대표 행동 → 결과)를 에뮬레이터에서 실행한다.

### 8. 1-2 계약 확장

1-2 AppConfig에 다음 필드를 추가한다(FRAMEWORK "승인 결과 기록"의 계약 확장 규칙).

| 필드 | 타입 | 제약 |
|------|------|------|
| `permissions` | string[] | Android 권한 허용 목록. 광고 SDK의 `AD_ID`·`INTERNET`은 코어가 자동 포함 |
| `firebase.projectId` | string | A7: 앱마다 다른 값이어야 함(검증) |

### 9. 번복 영향 (⚠️ 비가역)

| 결정 | 번복 시 영향받는 것 | 번복 비용 |
|------|------------------|----------|
| A1 Flutter | 코어 패키지 전부, 출시된 모든 앱, CI | 전면 재작성 — 최고 |
| A2 workspace + Melos | 루트 pubspec, CI 스크립트 | 낮음(도구 교체 수준) |
| A3 독립 앱 | `factory_cli new` 템플릿, 출시 앱의 프로젝트 구조 | 중 — 출시된 앱의 `applicationId`는 유지 가능 |
| A5 Riverpod | runtime과 모든 앱의 상태 코드 | 중~높음 |
| A7 앱별 Firebase | 출시 후 프로젝트를 합치거나 나누면 **Analytics 이력이 이어지지 않음** | 높음(데이터 손실) |
| A9 업로드 키 | Play App Signing이므로 업로드 키는 분실해도 재설정 가능 | 낮음 |
| `applicationId` (1-2) | 바꾸면 스토어에서 다른 앱이 됨 | 불가 |

### 10. 외부 의존성·비용

| 항목 | 비용 | 비고 |
|------|------|------|
| Google Play 개발자 계정(조직) | 1회 $25 | 사업자등록 → D-U-N-S 선행. 조직 계정의 개발자 인증 요건은 3-1 전 Play Console 안내로 재확인(`미확인`) |
| Apple Developer | 연 $99 | iOS 확장 시점부터 |
| Firebase | Spark 무료 → 6번째 앱 전 Blaze(사용량 기준, 예상 $0) | 예산 알림 필수 |
| GitHub | 비공개 저장소 Actions 월 2,000분 무료 | Android 빌드 1회 약 10분 가정 시 월 약 200회 |
| AdMob | 무료 | 수익 지급 기준액·세금 정보 입력 필요(3-1) |
| Play 정책 기한 | targetSdk 36, PBL 8 | 둘 다 위 선택으로 충족 |

### 11. Phase 2 스테이지 확정안

| 스테이지 | 내용 | Build Spec 티어 |
|---------|------|---------------|
| 2-1 Core Packages | 저장소 생성, workspace·Melos·lint·CI 골격(§7 게이트 포함), `factory_core`~`factory_ui` | comprehensive |
| 2-2 App Generator + Release Pipeline | `factory_cli new/validate`, fastlane lane, release.yml, 첫 내부 테스트 업로드(빈 앱) | standard |
| 2-3 로또 번호 생성기 | | standard |
| 2-4 연봉 실수령액 계산기 | 요율 원격 JSON, 세액 검증 표 | standard |
| 2-5 소음 측정기 | 마이크 권한·dB 변환 | standard |
| 2-6 물 마시기 알림 | `factory_notifications`, drift | standard |
| 2-7 Game Kit + 퍼즐 | `factory_game_kit` | comprehensive |

### 12. 미해결 질문

| # | 질문 | AI 기본안 |
|---|------|----------|
| F1 | Firebase 프로젝트를 앱마다 둘까, 하나로 공유할까? | **앱마다.** 지표가 섞이지 않고, 나중에 합치거나 나누면 Analytics 이력이 끊긴다 |
| F2 | CI/CD 도구 | **GitHub Actions(Linux) + fastlane.** iOS 확장 시 Codemagic 재검토 |
| F3 | §7.4 예산 수치(메모리 150/250MB, 크기 15/25MB, 콜드 스타트 1.5/2.0초) | 제안 수치로 시작하고, 2-1에서 기준 기기로 실측한 뒤 조정 |

## 검토 게이트 (Human Gate)

### 기본 게이트
- [ ] 모든 기술 결정이 내려졌는가?
- [ ] 1-2 도메인 계약을 이 구조로 구현할 수 있는가?
- [ ] §7 품질 기준(코드 구조·정적 분석·보안·메모리·크기·안정성 예산)에 동의하는가?
- [ ] 미해결 질문 F1~F3에 답했는가?

### 비가역성 확인 ⚠️
- [ ] 이 결정을 번복할 경우 영향받는 파일/레이어 목록을 작성했는가?
- [ ] 대안 기술 스택을 검토하고 탈락 이유를 문서화했는가?
- [ ] 외부 의존성(AdMob·Firebase·스토어 계정) 및 비용 구조를 확인했는가?
- [ ] Flutter·Melos 생태계 lock-in을 수용할 수 있는가?

## 다음 단계

승인 후 → `STATUS.md`에서 1-3 상태를 `HUMAN_APPROVED`로 업데이트 → Phase 2 스테이지 목록 확정 → Construction 시작
