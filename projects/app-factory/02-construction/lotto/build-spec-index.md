---
build-spec: lotto
stage: 02-construction/03-lotto
status: QUESTIONS_OPEN
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
| `assets/draws.json` | 1~1245회 당첨 번호 (엑셀 변환) |
| `tool/import_draws.dart` | 엑셀 → `assets/draws.json` |
| `tool/add_draw.dart` | 새 회차 → Remote Config `app_lotto_draws_v1` 추가 |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 |
|---|---|---|
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) — APP_DESIGN_PROMPT v1 첫 적용 |

## §3. 미해결 질문

- [x] 생성 방식 → 무작위 + 고정수·제외수 (2026-10-14)
- [x] 당첨 데이터 → 엑셀 1회 + 주 1회 CLI 입력 (비공식 조회 주소가 막혀 있음 확인)
- [x] 보상형 → 통계 추천 열기(그날 하루). 패턴 필터는 범위 밖 (AI 해석, READY 승인 시 확정)
- [x] QR 스캔 → 1.1
- [ ] 동행복권 회차별 당첨번호 엑셀 파일 (오너 다운로드)
- [x] 화면 설계를 APP_DESIGN_PROMPT v1로 다시 작성 (오너 「수정 후 승인」, 2026-10-14)
- [ ] `READY` 승인

## §4. 구현 체크리스트

- [ ] `factory new lotto --category fun --name-ko "로또 번호 생성기"` → `app.yaml`(placements·이벤트·`audience.minAge: 18`·원격 기본값)
- [ ] `factory firebase lotto` (첫 실제 실행)
- [ ] domain: 생성기·회차·당첨 판정·통계 + 단위 테스트
- [ ] data: 당첨 저장소(에셋 ∪ 원격)·이력 저장소·잠금 상태 + 단위 테스트
- [ ] `tool/import_draws.dart` → `assets/draws.json` (1~1245회, 개수·연속성 검증)
- [ ] `tool/add_draw.dart` (Remote Config 갱신)
- [ ] UI: 생성·내 번호·통계·설정, 공 위젯, 하단 내비게이션
- [ ] 위젯 테스트 (핵심 흐름)
- [ ] store 문구(ko)·data-safety·개인정보처리방침 초안
- [ ] 릴리스 리허설: 서명 AAB → `validate --release`(AdMob ID 외 통과) → `size`

## §5. 검증 계획
- [ ] 분석·포맷·의존 검사·`validate` 통과
- [ ] domain 테스트: 고정·제외 조합 경계, 결정적 시드로 분포, 회차 계산(KST 토요일 20:00 경계), 당첨 판정 5개 등수 + 보너스
- [ ] 위젯 테스트: 생성 → 저장 → 내 번호에 표시, 통계 잠금 → 보상 → 열림, 누수 0
- [ ] 에뮬레이터: 전 화면 수동 확인(스크린숏), 테스트 광고 표시
- [ ] 크기 ≤ 15MB, 콜드 스타트 ≤ 1.5초, PSS ≤ 200MB (2-1 G1)

## §6. NFR
N/A (standard). 2-1 G1·1-3 §7.4 예산을 §5에서 측정한다.

## §7. 편차 로그

| SoT | 실제 구현 | 사유 |
|---|---|---|
| 1-2 §10 로또 placements `banner_history` | 유지 | — |
