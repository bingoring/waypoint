---
build-spec: lotto
stage: 02-construction/03-lotto
status: IMPLEMENTED
depth: standard
updated: 2026-10-14
---

# Build Spec — 로또 번호 생성기

## §0. 개요 & 범위
- **목표(한 줄):** 로또 6/45 번호 생성(무작위·고정수·제외수) + 저장·당첨 확인 + 보상형 통계 추천 앱 `apps/lotto`.
- **SoT:** 1-1 §7(로또), 1-2 §10(매핑), DECISIONS 2026-10-14(기능 범위·당첨 데이터·QR 1.1).
- **규모/제약:** 오프라인 동작, 서버 0원, 권한 추가 없음, 한국어 전용(Q2), 다운로드 ≤ 15MB.
- **깊이 티어 & 사유:** `standard` + frontend-components — 화면 4개를 처음부터 설계하므로 화면 아티팩트를 둔다.

## §1. 분해

| 단위 | 책임 |
|---|---|
| `lib/domain/` | 번호 생성기, 회차 계산, 당첨 판정, 통계(빈도·가중 추첨) — 순수 Dart |
| `lib/data/` | 당첨 회차 저장소(에셋 ∪ 원격), 내 번호 이력 저장소, 통계 잠금 상태 |
| `lib/ui/` | 생성 · 내 번호 · 통계 · 설정 화면, 공 위젯 |
| `assets/draws.json` | 1~1245회 당첨 번호 (공식 결과 페이지 데이터 주소에서 1회 수집) |
| `tool/fetch_draws.dart` | 공식 결과 페이지 데이터 주소 → 회차 목록 (전체 수집·최신 회차) |
| `tool/add_draw.dart` | 새 회차 → Remote Config `app_lotto_draws_v1` 추가 (자동 작업이 호출, 수동 비상용 겸용) |
| `.github/workflows/lotto-draws.yml` | 매주 일요일 새벽 KST 자동 등록, 실패 시 워크플로 실패(메일) |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) — APP_DESIGN_PROMPT v1 첫 적용 |

## §3. 미해결 질문

- [x] 생성 방식 → 무작위 + 고정수·제외수 (2026-10-14)
- [x] 당첨 데이터 → ~~엑셀 1회 + 주 1회 CLI 입력~~ **공식 결과 페이지 데이터 주소로 자동 수집·매주 자동 등록** (2026-10-14 오너 승인)
- [x] 보상형 → 통계 추천 열기(그날 하루). 패턴 필터는 범위 밖 (AI 해석, READY 승인 시 확정)
- [x] QR 스캔 → 1.1
- [x] ~~동행복권 엑셀~~ 불필요해짐
- [x] 화면 설계를 APP_DESIGN_PROMPT v1로 다시 작성 (오너 「수정 후 승인」, 2026-10-14)
- [x] `READY` 승인 (2026-10-14)

## §4. 구현 체크리스트

- [x] `factory new lotto --category fun --name-ko "로또 번호 생성기"` → `app.yaml`(placements·이벤트·`audience.minAge: 18`·원격 기본값)
- [x] `factory firebase lotto` (첫 실제 실행)
- [x] domain: 생성기·회차·당첨 판정·통계 + 단위 테스트
- [x] data: 당첨 저장소(에셋 ∪ 원격)·이력 저장소·잠금 상태 + 단위 테스트
- [x] `tool/fetch_draws.dart` → `assets/draws.json` (1~1245회, 개수·연속성 검증)
- [x] `lotto-draws.yml` 자동 등록 워크플로 + 서비스 계정 시크릿(오너가 Firebase 콘솔에서 키 발급)
- [x] `tool/sync_draws.dart` (자동·수동 겸용, dry-run 검증) — ~~add_draw~~
- [x] UI: 생성·내 번호·통계·설정, 공 위젯, 하단 내비게이션
- [x] 위젯 테스트 (핵심 흐름)
- [x] store 문구(ko)·data-safety·개인정보처리방침 초안 — `apps/lotto/store/` (출시 전 오너 검토)
- [x] 릴리스 리허설: 서명 AAB → `validate --release`(AdMob ID 외 통과) → `size` — 남은 실패는 `REL_TEST_IDS`(AdMob 계정 필요)뿐, 10.28MB

## §5. 검증 계획
- [x] 분석·포맷·의존 검사·`validate` 통과
- [x] domain 테스트: 고정·제외 조합 경계, 결정적 시드로 분포, 회차 계산(KST 토요일 20:00 경계), 당첨 판정 5개 등수 + 보너스
- [x] 위젯 테스트: 생성 → 저장 → 내 번호에 표시, 통계 잠금 → 보상 → 열림, 누수 0 — 앱 테스트 30개
- [x] 에뮬레이터: 전 화면 수동 확인(스크린숏), 테스트 광고 표시 — FC §9, 보상형 광고 실제 시청·보상 지급 확인
- [x] 크기 ≤ 15MB, 콜드 스타트 ≤ 1.5초, PSS ≤ 200MB (2-1 G1) — 10.28MB · 콜드 스타트 1.30~1.54초(에뮬레이터 편차, 경계) · PSS 195~196MB(여유 4MB)

## §6. NFR
N/A (standard). 2-1 G1·1-3 §7.4 예산을 §5에서 측정한다.

## §7. 편차 로그

| SoT | 실제 구현 | 사유 |
|---|---|---|
| 1-2 §10 로또 placements `banner_history` | 유지 | — |
| BR L-UI·FC: 앱 문자열 | 한국어 전용 앱이라 화면 문자열을 코드에 직접 둠(ARB 없음) | Q2: 로또는 한국어 전용 |
| FC §3.3 통계 대표 버튼 | 막대 위 겹침 → 하단 고정, 잠긴 상태에 결과 자리 미리보기 | 프롬프트 5단계 검사에서 발견 |
| 시드 색 | 생성기 제안 #BF5677 → #2E3A59 | 공 다섯 색과 경쟁하지 않게 (FC §5) |
| 당첨 데이터 | 엑셀 → 공식 결과 페이지 데이터 주소, `add_draw` → `sync_draws` | 오너 승인(자동 등록) |
| `factory firebase` 첫 실제 실행 | 한글 표시 이름 거부 결함 발견·수정(생성기) | GCP 표시 이름은 한글 불가 |
| (신규, 코어) `BannerSlot` | 보이지 않는 탭(IndexedStack의 Visibility)·TickerMode 꺼짐에서는 배너를 불러오지 않고 해제 | 측정 중 발견: 숨은 「내 번호」 탭 배너가 함께 떠 있었다(WebView 5→4, PSS −3MB). 보이지 않는 광고 노출은 정책 위험. `factory_ads` 회귀 테스트 2개 |
| BLM §1.5 자동 등록 | 첫 실행에서 서비스 계정 권한 문제 확인, 실패 원인을 로그에 보이도록 개선 | 오너가 다른 GCP 프로젝트에서 서비스 계정을 만들었다(프로젝트 323637914615). smallmatter-lotto에서 다시 만들어야 한다 |
| 메모리 | 예제 앱(173MB)보다 +23MB | Firebase 제외 빌드도 같아 Firebase는 원인 아님(`추론`: UI·데이터·탭 3개 상주). 예산 안이라 1.1에서 다시 본다 |
