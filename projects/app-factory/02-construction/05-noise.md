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
- [ ] Build Spec `READY` 승인
- [ ] 구현 (Build Spec §4)
- [ ] 검증 (Build Spec §5) → `IMPLEMENTED`

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

1. **dB 엔진을 직접 만든다.** `record`로 원시 PCM을 받아 A가중 → 125 ms RMS → SPL로 바꾸고, Leq는 에너지 평균으로 계산한다. 기존 패키지 값은 SPL도 A가중도 아니라 법정 지표를 낼 수 없다. 엔진은 A가중 표·Leq 골든 테스트로 고정한다.
2. **층간소음 모드가 차별점.** 1분(공기전달 5분) 등가소음도와 최고소음도 초과 횟수를 법령 별표 그대로 판정하고, 그래프에 기준선을 그린다. 결과 옆에 「참고용, 공식 측정은 이웃사이센터」를 고정한다(공단 측정기 결과도 법적 효력이 없다).
3. **마이크 신뢰.** 화면이 켜져 있을 때만 재고, 소리는 녹음·저장·전송하지 않는다. 권한 요청 바로 옆에 이 한 줄을 둔다. Data safety에는 오디오를 「수집하지 않음」으로 신고한다.
4. **부정확 불만에 대비.** 기기별 보정, 「측정 상한」·「다른 앱이 마이크 사용 중」 상태를 숫자 대신 보여 준다.
5. **검사 가능성.** 에뮬레이터 마이크로는 원하는 소리 크기를 만들 수 없어 `DEMO_AUDIO` 합성 입력을 두고, 릴리스 빌드에서는 막는다.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] Build Spec이 `READY`로 승인되었는가?
- [ ] 구현 후: Build Spec §5 검증을 통과해 `IMPLEMENTED`가 되었는가?

## 다음 단계

승인 후 → 2-6 물 마시기 알림
