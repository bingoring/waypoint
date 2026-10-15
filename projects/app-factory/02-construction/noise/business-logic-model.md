---
artifact: business-logic-model
build-spec: noise
status: DRAFT
updated: 2026-10-15
---

# Business Logic Model — 소음 측정기

## 1. dB 엔진 (`lib/domain/meter.dart`, 순수 Dart)

```
PCM16 청크(임의 크기) → A가중 IIR(48 kHz) → 6,000샘플 누적 → 블록 RMS → dBFS → + sourceOffset + calibration → Block
```
- `AWeighting`: IEC 61672의 아날로그 A가중(극점 20.6 Hz ×2, 107.7 Hz, 737.9 Hz, 12,194 Hz ×2)을 쌍일차 변환한 2차 구간 3개. 1 kHz에서 이득 0 dB로 정규화.
  - 구현 중 확정(2026-10-15): 단순 쌍일차 변환·주파수 미리 휘기 모두 8 kHz 이상에서 0.6~6 dB 어긋났다. 12,194 Hz 극점을 0.83배로, 차수 맞춤 영점을 z=−0.1에 두면(격자 탐색) 31.5 Hz~12.5 kHz 오차 ≤ 0.05 dB(아날로그 대비), 16 kHz +0.4 dB. 48 kHz 전용.
- `BlockAccumulator`: 필터 상태와 제곱합·샘플 수·최대 절댓값을 들고, 청크가 블록 경계를 넘으면 나눠 처리한다. 버퍼는 고정 크기 상태값뿐이다.
- `Stats`: 블록 dB를 받아 min·max·Leq(에너지 합 누적)·최근 240개 링(`Float32List`).
- `FloorMeter`: 블록을 받아 창(1분=480블록, 5분=2,400블록) 에너지를 누적하고, 창이 끝나면 Leq를 목록에 넣는다. Lmax 사건은 「기준 초과 시작 시각」만 지난 60분치 보관.

### 1.1 골든 테스트 (`test/meter_test.dart`)
| 입력 | 기대 |
|---|---|
| 1 kHz 정현파, 진폭 32,767 | dBFS −3.01 ±0.05 (가중 이득 0) |
| 옥타브 중심 정현파 31.5 Hz~8 kHz | A가중 표(−39.4, −26.2, −16.1, −8.6, −3.2, 0, +1.2, +1.0, −1.1) ±0.5 dB, 16 kHz는 ±1.5 (쌍일차 변환 왜곡) |
| 무음 | 하한 값(−∞ 대신 정해진 바닥, 예: 0 dB SPL) + `silent` 판정은 1초 뒤 |
| 블록 [60, 70] | Leq 67.4 ±0.05 |
| 같은 신호를 1샘플 청크와 10,000샘플 청크로 | 블록 값이 같다 |
| 진폭 32,767 사각파 | `clipped` |
| 창 경계·Lmax 사건 | 1초 간격 규칙, 60분 밖 사건 버림, 3회 판정, 주간·야간 경계(05:59→06:00, 21:59→22:00) |

## 2. 오디오 입력 (`lib/data/audio_source.dart`)

- 인터페이스 `PcmSource { Stream<Int16List> start(); Future<void> stop(); MeterSource get kind; }`.
- `RecordPcmSource`: `record` 7.1.1 `startStream(RecordConfig(encoder: pcm16bits, sampleRate: 48000, numChannels: 1, audioSource: unprocessed→voiceRecognition, autoGain: false, noiseSuppress: false, echoCancel: false))`.
- `DemoPcmSource`(`DEMO_AUDIO=quiet|speech|floor|loud|silent`): 시나리오별 합성 정현파·계단 신호. 에뮬레이터 마이크는 원하는 크기를 만들 수 없어 5단계 검사·위젯 테스트에 쓴다(N-DEV-1).
- 생명주기: 측정 화면이 보이고 앱이 앞에 있고 앱 오프닝 광고가 없을 때만 `start` (N-RUN-1). `AppLifecycleListener`·`Visibility`·`TickerMode`·코어 광고 표시 상태를 함께 본다.
- 화면 켜짐: `MethodChannel('app.smallmatter.noise/screen')` → `MainActivity`가 `FLAG_KEEP_SCREEN_ON` 켜고 끔(10줄, 의존성 없음).

## 3. 저장·내보내기

| 키 | 내용 |
|---|---|
| `noise.records.v1` | `Record` 최근 500개 JSON |
| `noise.calibration.v1` | `offsetDb` |
| `noise.pre2005.v1` | bool |

- CSV는 `getTemporaryDirectory()`(`path_provider`, `share_plus` 의존)에 쓰고 `SharePlus.instance.share(ShareParams(files: …))` 후 삭제. `share_plus` 13.3.0(2026-07-23) 정확히 고정.

## 4. 성능·메모리

- 48 kHz × 2바이트 = 96 KB/s 입력을 즉시 처리하고 버린다. 유지 메모리는 블록 값(30 s 링 240개, 창 누적값, 사건 시각)뿐이다 — 수 KB.
- 화면 갱신은 블록마다(8 Hz). 숫자는 고정폭, 계기판·그래프는 `RepaintBoundary`로 나눈다.
- 측정 화면 1분 유지 시 Dart 힙·PSS 증가 없음을 §5에서 잰다.

## 5. 실패·경계

| 상황 | 동작 |
|---|---|
| 권한 거부 | 계기판은 0에서 쉬고, 그 자리에 「마이크 허용」 + 한 줄 설명. 영구 거부면 앱 설정 열기 |
| 다른 앱이 마이크 사용 | `silent` 안내, 다시 시도 버튼 |
| 블록 클리핑 | 「측정 상한」 표시, 통계에는 넣되 표시 |
| 측정 중 전화·앱 전환 | 즉시 멈춤, 돌아오면 이어서(세션 통계 유지, 끊긴 시간 표시) |
