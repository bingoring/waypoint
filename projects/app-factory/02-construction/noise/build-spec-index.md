---
build-spec: noise
stage: 02-construction/05-noise
status: IMPLEMENTED
depth: standard
updated: 2026-10-15
---

# Build Spec — 소음 측정기

## §0. 개요 & 범위
- **목표(한 줄):** 실시간 dB(A)·최소·평균(Leq)·최대 + (ko) 층간소음 법정 기준 판정 + 기록·CSV 내보내기 + 보정 앱 `apps/noise`, ko·en.
- **SoT:** 1-1 §7, 1-2 §10(소음 행), 1-3 §4(소음 측정 패키지는 2-5에서 결정), DECISIONS 2026-10-14·15.
- **규모/제약:** 오프라인, 서버 0원, 권한 `RECORD_AUDIO` 하나(화면이 켜져 있을 때만 측정, 포그라운드 서비스 없음), 소리 저장·전송 없음, 다운로드 ≤ 15MB.
- **깊이 티어 & 사유:** `standard` + frontend-components. dB 엔진을 직접 만들어 BLM에 수식과 골든 테스트를 고정한다.

## §1. 분해

| 단위 | 책임 |
|---|---|
| `lib/domain/meter.dart` | A가중 IIR, 125 ms 블록, Leq·Lmax·통계, 층간소음 창·사건·판정 — 순수 Dart |
| `lib/data/audio_source.dart` | `PcmSource` 인터페이스, `record` 구현(소스 폴백), `DEMO_AUDIO` 합성 구현 |
| `lib/data/records.dart` | 기록 저장(500개), 보정·옵션 저장, CSV 생성 |
| `lib/ui/` | 측정 · 층간소음(ko) · 기록 · 설정, `ArcGauge`·`NoiseGraph`·`WindowRing` |
| `lib/l10n/` | `app_ko.arb`·`app_en.arb` + `flutter gen-l10n` (이 프로젝트 첫 2개 언어 앱) |
| `android/.../MainActivity.kt` | 화면 켜짐 유지 채널 |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 |
|---|---|---|
| research | ✅ | [`research-2026-10-14.md`](research-2026-10-14.md) |
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문

- [x] 기능 범위 → 실시간 + 층간소음 모드 + 기록, 화면 켜져 있을 때만, 배너 + 앱 오프닝 (2026-10-14)
- [x] 영어 → 층간소음 모드는 ko만, en은 청력 기준·Leq (2026-10-15)
- [x] 보정 → 이번에 넣음 (2026-10-15)
- [x] 내보내기 → 공유 시트 CSV (2026-10-15)
- [x] 패키지 → `record` 7.1.1(2026-06-29, 7.1.2는 2주 미만) · `share_plus` 13.3.0(2026-07-23), 정확히 고정. `noise_meter`는 SPL·A가중이 아니라 탈락(조사 §5). 화면 켜짐은 패키지 없이 채널
- [x] `READY` 승인 (2026-10-15)

## §4. 구현 체크리스트

- [x] `factory new noise --category tool --name-ko "소음 측정기" --name-en "Noise Meter: dB Sound Level"` · `factory firebase noise` (커밋 `e0a5731`)
- [ ] (오너, 3-1 전) Firebase `smallmatter-noise` GA 사용 설정 → AdMob 앱·`banner_home`·`app_open` 단위 → AdMob↔Firebase 연결
- [x] `app.yaml`: 시드 #5B45A6, `permissions: [RECORD_AUDIO]`, placements `banner_home`·`app_open`, keyAction `measure_noise`, events(`start_floor`·`save_record`·`export_records`·`calibrate`)
- [x] domain: dB 엔진 + 골든 테스트(BLM §1.1), 층간소음 판정 테스트 — 23개
- [x] data: `PcmSource`(record·demo), 기록·CSV + 테스트
- [x] l10n: ko·en 문구 — ARB 대신 코어와 같은 손으로 쓴 클래스(편차 로그)
- [x] UI: 측정·층간소음·기록·설정, 권한 흐름, 화면 켜짐
- [x] 위젯 테스트(데모 소스): 권한 거부·허용, 측정 → 저장 → 기록, 층간소음 판정, 숨은 탭에서 마이크 닫힘, en에서 층간소음 탭 없음, 누수 0 — 앱 테스트 34개
- [x] store 문구(ko·en)·data-safety·개인정보처리방침 → `tool/sync_site.dart` (https://smallmatter.app/noise/privacy/, 초안)
- [x] 릴리스 리허설: 키·AAB·`size`·`validate --release` — 11.23MB, 남은 실패는 `REL_TEST_IDS`(AdMob 단위 대기)뿐. `DEMO_AUDIO`는 릴리스 모드에서 시작 차단. 업로드 키 `~/.smallmatter/keys/noise.*`

## §5. 검증 계획
- [x] 분석·포맷·의존 검사·`validate`
- [x] 엔진 골든: A가중 표 ±0.2 dB(16 kHz ±0.6), Leq·청크 독립성·클리핑·무음
- [x] 층간소음: 기준표·주야 경계·pre2005·창 최고값·Lmax 3회 규칙
- [x] 에뮬레이터(`DEMO_AUDIO`): 전 화면 스크린숏 ko·en, 프롬프트 5단계 검사(FC §9). 앱 오프닝 광고 중 마이크 정지는 3-1 실기기
- [x] 실제 마이크: 에뮬레이터 마이크로 스트림·dB 계산·무음 전환 확인(24~30 dB 뒤 가상 마이크 0 → 무음 안내). **절대 정확도는 3-1 실기기**
- [x] 크기 ≤ 15MB ✅ 11.23MB · PSS·콜드 스타트 ⚠️ 상대값만 (G1 절차, 2026-10-15)
  - 에뮬레이터가 14시간째 켜져 부하 2.9~23 — 부하 기준을 3으로 완화해도 측정 중 계속 올랐다. 기준 앱부터 214~228MB·콜드 6.5~8.3초라 절대값은 판정하지 않는다.
  - PSS(KB, 같은 부팅 3회): 기준 앱 227,508 / 214,156 / 216,956 · 로또 첫 화면 233,396 / 229,295 / 226,416, 탭 뒤 243,562 / 241,278 / 239,817 · 소음 첫 화면 231,273 / 233,397 / 233,588, 탭 뒤 230,933 / 252,320 / 253,797.
    → 소음은 로또와 같은 수준. 기준 앱 중앙값 대비 첫 화면 +16MB, 탭 뒤 +36MB(코어·UI 40MB 안, 경계).
  - 측정 화면 유지(실제 마이크): 시작 233,820 → 1분 240,666 → 이후 1분 간격 243,262 / 244,953 / 248,371 / 245,409KB. 첫 1분은 배너 로드 등 초기 증가, 이후 오르내리며 일정 → 누수 아님.

## §6. NFR
N/A (standard). 2-1 G1 측정 절차를 따른다.

## §7. 편차 로그

| SoT | 실제 구현 | 사유 |
|---|---|---|
| 1-3 §4 소음 패키지 후보 `noise_meter` 6.0.0 또는 `record` | `record` 7.1.1 + 자체 dB 엔진 | `noise_meter`는 DEFAULT 소스 고정, SPL·RMS·A가중이 아니고 상한 약 90 dB(조사 §5) |
| 생성기 템플릿(앱 문자열) | 앱에 ARB·gen-l10n을 직접 추가 | 템플릿에 2개 언어 앱 문자열 체계가 없다. 결과를 보고 생성기에 넣을지 2-6에서 정한다 |
| 시드 색 | 생성기 제안 → #5B45A6 | FC §5 |
| BLM §1.1 A가중 설계 | 쌍일차 변환 + 48 kHz 고주파 보정(극점 0.83배, 영점 z=−0.1) | 단순 변환은 8 kHz −0.6 dB·16 kHz −6.5 dB 오차. 보정 뒤 공칭값 0.2 dB 이내 |
| 생성기 템플릿(앱 문자열) | ARB·gen-l10n 대신 `lib/ui/strings.dart`(추상 클래스 + ko·en 구현) | 코어 `FactoryLocalizations`와 같은 방식, 빠뜨린 문구는 컴파일 오류, 의존성(`intl`) 추가 없음 |
| 생성기 템플릿(`app.dart`) | `localeResolutionCallback`: 지원하지 않는 언어는 영어로 | 템플릿은 첫 항목(ko)으로 떨어져 일본어 등 해외 기기에서 한국어가 보인다. 2-6 전에 템플릿에 반영 |
| BR N-DEV-1 「`validate --release`가 실패」 | 릴리스 모드에서 `DEMO_AUDIO`가 있으면 `main`이 시작하지 않는다 | 빌드할 때 넣는 값이라 `validate`가 알 수 없다 |
| BR N-RUN-1 「앱 오프닝 광고가 떠 있으면」 | 별도 신호 없이 생명주기 `onHide`로 처리 | 광고는 별도 Activity라 Flutter가 숨김을 알린다. 코어에 광고 표시 상태 API를 만들지 않았다 |
| BLM §3 CSV 임시 파일 | `share_plus`의 `XFile.fromData`(라이브러리가 캐시에 쓰고 정리) | `path_provider` 직접 의존을 늘리지 않는다 |
| BLM §2 권한 흐름 | `record.hasPermission` 대신 `MainActivity` 채널(`micPermission`·`requestMic`·`openAppSettings`) | `record`는 영구 거부를 구분하지 못한다 |
| (구현 중 발견) 세션 정지 순서 | 입력 정지·화면 켜짐 해제·「멈춤」 표시를 구독 취소보다 먼저 | 위젯 테스트: 구독 취소가 늦게 끝나 숨은 탭에서도 입력이 돌았다 |
| FC §3.1 측정 화면 | 바늘을 띠 안쪽 짧은 막대로, 띠 이름을 아크 밖으로, 사례 이름은 왼쪽·기준선 이름은 오른쪽, 그래프가 남는 높이를 채움(작은 화면은 스크롤) | 5단계 검사(바늘이 숫자를 가림·이름 겹침·아래 빈 공간)와 테스트(800×600 넘침) |
| FC §3.2 층간소음 화면 | 링 170dp, 그래프 120dp 고정(스크롤), 최고소음도 줄은 이름·규칙 두 줄 | 5단계 검사: 배너가 뜨면 그래프가 납작해졌고 줄이 어색하게 줄바꿈 |
