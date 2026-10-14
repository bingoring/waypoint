---
phase: 02-construction
stage: 03-lotto
status: AI_PROPOSED
updated: 2026-10-14
---

# [Stage 2-3] 로또 번호 생성기

## 목적

Wave 1의 첫 실제 앱. 로또 6/45 번호를 만들고(무작위·고정수·제외수), 저장한 번호의 당첨을 확인하며, 보상형 광고로 여는 통계 추천을 제공한다.
`factory new`로 만들고 2-2 파이프라인으로 출시 직전까지 준비해, 생성기의 "2번째 앱부터 3일 이하" 가정을 처음으로 검증한다.

## 입력 (Inputs)

- [`../01-inception/01-context-synthesis.md`](../01-inception/01-context-synthesis.md) §7 Wave 1(로또), §5 포트폴리오 규칙
- [`../01-inception/02-domain-model.md`](../01-inception/02-domain-model.md) §10 Wave 1 매핑(로또 행)
- [`02-app-generator.md`](02-app-generator.md) — 생성기·파이프라인
- [`../DECISIONS.md`](../DECISIONS.md) — 2026-10-14 로또 기능 범위·당첨 데이터

## 체크리스트

- [x] 기능 범위 질문 (2026-10-14): 생성 방식, 당첨 데이터, 보상형, QR
- [x] Build Spec 작성 — [`lotto/build-spec-index.md`](lotto/build-spec-index.md) (standard + frontend-components)
- [x] Build Spec `READY` 승인 (2026-10-14, 화면 명세는 APP_DESIGN_PROMPT v1 적용)
- [x] 구현 (Build Spec §4) — 저장소 커밋 `d0b68b9`까지
- [x] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **무료 핵심 + 보상형 고급 기능.** 무작위·고정수·제외수 생성과 저장·당첨 확인은 무료다. 통계 추천은 보상형 광고 1회로 그날 하루 연다(1-2 §4 보상형 규칙).
2. **당첨 데이터는 서버 없이.** 1~1245회는 공식 결과 페이지의 데이터 주소에서 한 번 받아 앱 에셋으로 넣고, 이후 회차는 GitHub Actions가 매주 자동으로 Remote Config에 추가한다(승인 결과 참조).
   앱은 에셋 ∪ 원격 회차를 합쳐 쓴다. 갱신을 빼먹어도 통계·당첨 확인이 한 주 늦을 뿐 앱은 동작한다.
3. **오해를 부르는 표현 금지.** 통계 추천은 "과거 출현 빈도를 보여 줄 뿐 당첨 확률을 높이지 않는다"를 화면에 명시한다(Play 기만 행위 정책·평점 보호).
   대상 연령은 18세로 둔다(국내 복권 구매 연령 19세, 1-2 `audience.minAge` 허용값 중 가장 높은 값).
4. **QR 스캔은 1.1.** 1.0은 카메라 권한 없이 출시한다.

### 구현 결과 요약 (2026-10-14)

- 화면 4개(뽑기·내 번호·통계·설정)를 APP_DESIGN_PROMPT v1로 설계·구현, 5단계 검사 통과([스크린숏](lotto/screens/)).
- 당첨 데이터 1~1245회 수집·검증, 매주 자동 등록 스크립트·워크플로. 앱 테스트 30개, 누수 0.
- 릴리스 리허설: 서명 AAB 10.28MB, `validate --release`의 남은 실패는 AdMob 단위 ID(계정 필요)뿐.
- 찾아서 고친 결함: 담기 애니메이션 해제 누락(누수), 통계 대표 버튼 위치, 숨은 탭 배너 로드(코어), `factory firebase` 한글 표시 이름(생성기).
- 출시 전 남은 일(3-1): AdMob 앱·단위 생성, 서비스 계정 재발급(smallmatter-lotto), 개인정보처리방침 게시(GitHub Pages), 스토어 문구 오너 검토, 「맞은 공 채우기」 화면 확인(1246회 추첨 후).

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec이 `READY`로 승인되었는가?
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

승인 후 → 2-4 연봉 실수령액 계산기
