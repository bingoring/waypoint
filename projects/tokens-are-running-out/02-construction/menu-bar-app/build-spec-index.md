---
build-spec: menu-bar-app
stage: 02-construction/03-menu-bar-app
status: READY
depth: comprehensive
updated: 2026-11-18
---

# Build Spec — 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림

## §0. 개요 & 범위
- **목표(한 줄):** 2-2의 분석 코어를 그대로 쓰는 메뉴 막대 앱 `TokensAreRunningOut.app`(개발 빌드, ad-hoc 서명)을 만든다. 팝오버는 만료가 다가오는 세션, 원인 분해(advisor 포함), 비용이 컸던 캐시 재구축과 그 근거를 보여 주고, 설정 창과 만료 전 알림을 갖춘다.
- **SoT(진실 공급원):**
  - [`../../inputs/design.md`](../../inputs/design.md) 2장(G2·G3), 5장, 6.5, 7장, 8.1 ~ 8.4
  - [`../../01-inception/03-architecture-decision.md`](../../01-inception/03-architecture-decision.md)의 구성 요소와 품질 기준선(화면: better-interface HIGH 0건)
  - [`../../DECISIONS.md`](../../DECISIONS.md) 2026-11-18 항목(advisor 별도 항목, 임계값 설정, 빌드 방식, 읽는 범위)
  - 2-2의 `UsageReport`·`RebuildEvent`, 2-1의 `Indexer`
- **규모/제약:**
  - 팝오버 1개(상태 5가지), 근거 팝오버 1개, 설정 창 1개, 알림 1종
  - 유휴 상태에서 CPU를 거의 쓰지 않고, 메모리 100MB 이하(설계 7장)
  - 네트워크 없음, `~/.claude`에 쓰기 없음, 샌드박스 없음(배포는 2-4)
- **깊이 티어 & 사유:** `comprehensive`. 화면, 시스템 연동(알림·로그인 항목·프로세스 확인), 상주 앱의 성능 예산이 함께 걸려 있다.

## §1. 분해 (Decomposition)

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `CostBucket.advisor`, 임계값 매개변수, `RebuildEvent.previousContextTokens` | 2-2 코어 확장(BR-B1 ~ BR-B4) | 2-2 | 기존 확장 |
| `drain.py`, 픽스처 기대 출력 | 같은 확장을 프로토타입에 반영, 기준값 갱신 | 2-2 | 기존 수정 |
| `Indexer` 스키마 v4, `health`, `lastCall`, 진행률 | BR-I1 ~ BR-I3, BR-H1 | 2-1 | 기존 확장 |
| `SessionRegistry` | 실행 세션 읽기와 생존 확인(BR-R1 ~ BR-R5) | Foundation, `sysctl` | 신규 |
| `ExpiryCalculator` | 경고 계산(BR-E1 ~ BR-E6) | `Indexer`, `PriceTable` | 신규 |
| `AppModel` | 상태, 감시, 캐시, 알림 맞추기(business-logic-model W1 ~ W6) | 위 전부, 시스템 프로토콜 | 신규 |
| `RunningOutUI` 화면 | frontend-components §1 ~ §7 | `AppModel` | 신규 |
| `TokensAreRunningOut` 앱 | `MenuBarExtra`, `Settings`, 알림·로그인 항목·URL 열기 구현 | `RunningOutUI` | 신규 |
| `scripts/build-app.sh` | `xcodebuild` 빌드, `.app` 조립, ad-hoc 서명 | Xcode | 신규 |
| `ui-snapshots` | 화면 상태 PNG(검토용) | `RunningOutUI` | 신규 |
| CI | 앱 빌드, 네트워크·쓰기 검사를 앱 소스로 확장 | | 기존 수정 |

## §2. 아티팩트 인덱스 (Manifest)

| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`./domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`./business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`./business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`./frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문 (Open Questions)

없음. advisor 별도 항목은 사용자가 정했다. 재구축 임계값 설정은 사용자의 의견(다른 사용자의 기록은 다를 수 있다)을 받아 AI가 제안했고, 승인 게이트에서 확인한다. 작성자 판단과 함께 [DECISIONS](../../DECISIONS.md) 2026-11-18에 기록했다.

## §4. 구현 체크리스트

- [ ] 2-2 확장: advisor 버킷, 임계값 매개변수(`--rebuild-threshold`), `previousContextTokens` — 앱·프로토타입·픽스처 기대 출력 함께
- [ ] 색인 스키마 v4(`read_stats`), `RecordParser`의 `.assistantWithoutCall`(BR-I4), `health(since:)`, `lastCall(ofSession:)`, `indexAll(progress:)`
- [ ] `SessionRegistry`(`<숫자>.json`만, 생존·PID 재사용 확인(`procStart`는 `ps lstart` 형식), `.unavailable`)
- [ ] `ExpiryCalculator`(BR-E1 ~ BR-E6)
- [ ] `AppModel`(W1 ~ W6, 보고서 캐시, 분 단위 갱신 조건)
- [ ] 알림 맞추기(`NotificationScheduling` 프로토콜과 가짜 구현으로 테스트)
- [ ] 화면: 메뉴 막대, 팝오버의 모든 상태, 근거 팝오버, 설정 창(`LSUIElement` 앱에서 `SettingsLink`로 열 때 창이 앞으로 오는지 확인하고, 아니면 앱을 활성화한 뒤 연다)
- [ ] String Catalog(en·ko) — frontend-components §7의 모든 문구
- [ ] `scripts/build-app.sh`, `Info.plist`, ad-hoc 서명
- [ ] `ui-snapshots`로 상태별 PNG(밝은·어두운 × en·ko)를 만들고 better-interface로 검토, HIGH 0건
- [ ] CI: 앱 빌드, 네트워크·쓰기 검사 범위 확장
- [ ] 성능 측정(§6)과 결과 기록
- [ ] 독립 리뷰와 그 반영
- [ ] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획
- [ ] 엄격 빌드(경고=오류), `swift format lint --strict`, 전체 테스트 통과
- [ ] 단위 테스트: business-rules §5의 경계마다 하나 이상(경고·알림·실행 세션·형식 변화·원인 행·임계값). 형식 변화는 `usage` 이름 변경, `message.id` 누락, 최상위 `type` 변경 픽스처가 모두 배너를 띄우고, `<synthetic>` 메시지만 있는 픽스처는 띄우지 않아야 한다
- [ ] 기준값: 기본 임계값에서 세 기간과 합성 픽스처의 `running-out report`가 `drain.py`와 글자 단위로 같다(advisor 버킷 반영 후 새 값). 다른 임계값 하나(예: 30,000)에서도 같다
- [ ] 화면: `ui-snapshots` PNG를 better-interface로 검토해 HIGH 0건. 결과를 스테이지 문서에 기록
- [ ] 실제 앱 확인(사용자 기기): 메뉴 막대 표시, VoiceOver 이름, 키보드만으로 모든 조작, 설정 창이 앞으로 오는지, 알림 권한 요청과 실제 수신(구현 시험에서는 설정 조회만 확인했다), 로그인 항목. 내가 확인할 수 없는 항목은 **Not verified**로 남기고 사용자에게 확인을 부탁한다
- [ ] 보안: 네트워크 API 0건, `~/.claude` 쓰기 0건, `*.key` 파일을 여는 코드 0건(테스트)
- [ ] PR 브랜치에 base merge 커밋 없음

## §6. NFR · 성능

| 항목 | 목표 | 측정 방법 |
|---|---|---|
| 유휴 CPU | 경고가 없고 팝오버가 닫혀 있을 때 타이머 0개, 10분 평균 CPU 0.1% 이하 | `top -l` 또는 Activity Monitor로 10분 관찰 |
| 메모리 | 상주 100MB 이하(첫 색인 중 최대값 포함) | `footprint`, `/usr/bin/time -l`(첫 색인) |
| 팝오버 열기 | 캐시된 값이 바로 보임(0.1초 이내) | 계측 로그 |
| 기간 바꾸기 | 1초 이내(2-2 측정 0.15초 + 화면) | 계측 로그 |
| 기록 변경 반영 | 파일 변경 후 2초 이내 메뉴 막대 갱신(FSEvents 지연 0.5초 포함) | `running-out watch`와 같은 방식 |
| 첫 색인 | 1.7GB 기준 2분 이내(2-2 측정 11.7초) | 앱 로그 |

## §7. 편차 로그 (Deviations) — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| design 7장 "처음 30일치를 먼저 처리해서 화면을 띄움" | 진행 막대만 보이고 끝나면 전체 결과 | 첫 색인이 11.7초라 나눠 처리할 이득이 없다(DECISIONS 2026-11-18). 구현 전 확정 |
| design 5장 세션 제목 출처 "데스크톱 메타데이터의 `title`" | 읽지 않음. `custom-title` → 실행 세션 `name` → 폴더 이름 | `custom-title`이 최근 세션 76개 중 74개를 덮고, 메타데이터가 더해 주는 것이 없다(DECISIONS 2026-11-18). 구현 전 확정 |
