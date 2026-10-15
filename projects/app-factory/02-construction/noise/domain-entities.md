---
artifact: domain-entities
build-spec: noise
status: DRAFT
updated: 2026-10-15
---

# Domain Entities — 소음 측정기

> 소리(PCM)는 계산 즉시 버린다. 저장하는 것은 125 ms 블록 값(dB)과 그 통계뿐이다(N-PRIV-1).

| 엔티티 | 필드 | 비고 |
|---|---|---|
| `Block` | `db`(double, dB(A) SPL), `clipped`(bool), `silent`(bool) | 125 ms(Fast) 하나. 엔진의 유일한 출력 |
| `MeterSource` | `unprocessed` · `voiceRecognition` · `demo` | 기기가 지원하는 첫 소스. `demo`는 `--dart-define=DEMO_AUDIO`일 때만 (N-DEV-1) |
| `Calibration` | `offsetDb`(double, −20.0~+20.0, 0.5 단위, 기본 0) | 소스 기본 오프셋 위에 더하는 사용자 값 (N-CAL) |
| `LiveStats` | `current`, `min`, `max`, `leq`(세션 전체), `elapsed`, `recent`(최근 30 s 블록 240개 링) | 측정 화면 |
| `FloorKind` | `impact`(직접충격: 발소리) · `airborne`(공기전달: TV·음악) | 층간소음 모드 토글 |
| `FloorLimits` | `leq1min` 39/34, `lmax` 57/52, `leq5min` 45/40, `pre2005`(+2, 직접충격만) | 법정 기준 (조사 §1) |
| `FloorSession` | `kind`, `start`, `windowLeqs`(1분 또는 5분 창 Leq 목록), `maxWindowLeq`, `lmaxEvents`(초과 시작 시각 목록) | 층간소음 모드 결과 |
| `Record` | `id`, `start`, `end`, `mode`(general·floor), `kind?`, `leq`, `lmax`, `min`, `maxWindowLeq?`, `lmaxExceed?`(지난 1시간 초과 횟수), `verdict?`, `night`(bool), `memo`, `offsetDb` | 기기에만 저장, 최대 500개 |
