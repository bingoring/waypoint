---
phase: 02-construction
stage: 05-noise
status: AI_PROPOSED
updated: 2026-10-15
---

# [Stage 2-5] 소음 측정기

## 목적

Wave 1의 세 번째 앱이자 첫 센서 앱·첫 2개 언어(ko·en) 앱. 마이크로 지금 소리 크기를 dB(A)로 보여 주고, 한국어에서는 층간소음을 법정 기준과 비교해 기록한다.

## 입력 (Inputs)

- [`../01-inception/01-context-synthesis.md`](../01-inception/01-context-synthesis.md) §7(소음 측정기)
- [`../01-inception/02-domain-model.md`](../01-inception/02-domain-model.md) §10(소음 행: `banner_home`·`app_open`, `measure_noise`, ko·en)
- [`../01-inception/03-architecture-decision.md`](../01-inception/03-architecture-decision.md) §4(소음 측정 패키지)
- [`../DECISIONS.md`](../DECISIONS.md) — 2026-10-14·15 소음 측정기 범위

## 체크리스트

- [x] 기능 범위 질문 (2026-10-14·15)
- [x] 근거 조사 — [`noise/research-2026-10-14.md`](noise/research-2026-10-14.md)
- [x] Build Spec 작성 — [`noise/build-spec-index.md`](noise/build-spec-index.md)
- [x] Build Spec `READY` 승인 (2026-10-15)
- [x] 구현 (Build Spec §4) — 저장소 커밋 `ab5aea0`까지
- [x] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **dB 엔진을 직접 만든다.** `record`로 원시 PCM을 받아 A가중 → 125 ms RMS → SPL로 바꾸고, Leq는 에너지 평균으로 계산한다. 기존 패키지 값은 SPL도 A가중도 아니라 법정 지표를 낼 수 없다. 엔진은 A가중 표·Leq 골든 테스트로 고정한다.
2. **층간소음 모드가 차별점.** 1분(공기전달 5분) 등가소음도와 최고소음도 초과 횟수를 법령 별표 그대로 판정하고, 그래프에 기준선을 그린다. 결과 옆에 「참고용, 공식 측정은 이웃사이센터」를 고정한다(공단 측정기 결과도 법적 효력이 없다).
3. **마이크 신뢰.** 화면이 켜져 있을 때만 재고, 소리는 녹음·저장·전송하지 않는다. 권한 요청 바로 옆에 이 한 줄을 둔다. Data safety에는 오디오를 「수집하지 않음」으로 신고한다.
4. **부정확 불만에 대비.** 기기별 보정, 「측정 상한」·「다른 앱이 마이크 사용 중」 상태를 숫자 대신 보여 준다.
5. **검사 가능성.** 에뮬레이터 마이크로는 원하는 소리 크기를 만들 수 없어 `DEMO_AUDIO` 합성 입력을 두고, 릴리스 빌드에서는 막는다.

### 구현 결과 요약 (2026-10-15)

- 화면 4개(측정·층간소음(ko)·기록·설정)를 APP_DESIGN_PROMPT v1로 구현, 5단계 검사 통과([스크린숏](noise/screens/), FC §9).
- dB 엔진: A가중이 IEC 공칭값과 0.2 dB 이내(단순 쌍일차 변환은 8 kHz 이상에서 어긋나 48 kHz 고주파 보정을 찾아 넣음). 층간소음 판정은 법령 별표 그대로(창 최고값·최고소음도 1시간 3회).
- 앱 테스트 34개(엔진 23 · 데이터·흐름 11), 누수 0. 릴리스 리허설: AAB 11.23MB, 남은 실패는 AdMob 단위(계정 작업 대기)뿐.
- 찾아서 고친 결함: 숨은 탭·멈춤에서 마이크·화면 켜짐이 늦게 닫힘(테스트), 작은 화면 넘침(테스트), **다른 앱이 마이크를 쓸 때 0 dB 표시**(5단계 검사), 바늘·이름 겹침 등 화면 5건. 공통: 생성기 앱 이름 콜론 결함, 템플릿 언어 대체(영어).
- 메모리: 같은 부팅에서 로또와 같은 수준(기준 앱 대비 탭 뒤 +36MB), 측정 3분 유지에도 증가 없음. 에뮬레이터 부하가 높아 절대값·콜드 스타트는 판정하지 않음.
- 출시 전 남은 일(3-1): ~~AdMob 앱·단위·Firebase 연결~~(2026-10-15 완료, `validate --release` 통과), ~~업로드 키 시크릿~~(완료), GA 측정 설정 경고 재확인, 영어 개인정보처리방침, 실기기 정확도(조용한 방 30~40 dB·대화 60 dB)·앱 오프닝 광고 중 마이크 정지 확인, 스토어 문구 검토.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] Build Spec이 `READY`로 승인되었는가?
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

승인 후 → 2-6 물 마시기 알림
