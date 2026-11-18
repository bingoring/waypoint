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

- [x] 2-2 확장: advisor 버킷, 임계값 매개변수(`--rebuild-threshold`), `previousContextTokens` — 앱·프로토타입·픽스처 기대 출력 함께
- [x] 색인 스키마 v4(`read_stats`), `RecordParser`의 `.assistantWithoutCall`(BR-I4), `health(since:)`, `lastCall(ofSession:)`, `indexAll(progress:)`
- [x] `SessionRegistry`(`<숫자>.json`만, 생존·PID 재사용 확인(`procStart`는 `ps lstart` 형식), `.unavailable`)
- [x] `ExpiryCalculator`(BR-E1 ~ BR-E6)
- [x] `AppModel`(W1 ~ W6, 보고서 캐시, 분 단위 갱신 조건)
- [x] 알림 맞추기(`NotificationScheduling` 프로토콜과 가짜 구현으로 테스트)
- [x] 화면: 메뉴 막대, 팝오버의 모든 상태, 근거 팝오버, 설정 창(`LSUIElement` 앱에서 `SettingsLink`로 열 때 창이 앞으로 오는지 확인하고, 아니면 앱을 활성화한 뒤 연다)
- [x] String Catalog(en·ko) — frontend-components §7의 모든 문구
- [x] `scripts/build-app.sh`, `Info.plist`, ad-hoc 서명
- [x] `ui-snapshots`로 상태별 PNG(밝은·어두운 × en·ko)를 만들고 better-interface로 검토, HIGH 0건
- [x] CI: 앱 빌드, 네트워크·쓰기 검사 범위 확장
- [x] 성능 측정(§6)과 결과 기록
- [x] 독립 리뷰와 그 반영
- [x] PR 브랜치에 base merge 커밋 없음

## §5. 검증 계획
- [x] 엄격 빌드(경고=오류), `swift format lint --strict`, 전체 테스트 통과
- [x] 단위 테스트: business-rules §5의 경계마다 하나 이상(경고·알림·실행 세션·형식 변화·원인 행·임계값). 형식 변화는 `usage` 이름 변경, `message.id` 누락, 최상위 `type` 변경 픽스처가 모두 배너를 띄우고, `<synthetic>` 메시지만 있는 픽스처는 띄우지 않아야 한다
- [x] 기준값: 기본 임계값에서 세 기간과 합성 픽스처의 `running-out report`가 `drain.py`와 글자 단위로 같다(advisor 버킷 반영 후 새 값). 다른 임계값 하나(예: 30,000)에서도 같다
- [x] 화면: `ui-snapshots` PNG를 better-interface로 검토해 HIGH 0건. 결과를 스테이지 문서에 기록
- [ ] 실제 앱 확인(사용자 기기): 메뉴 막대 표시, VoiceOver 이름, 키보드만으로 모든 조작, 설정 창이 앞으로 오는지, 알림 권한 요청과 실제 수신, 로그인 항목, 팝오버를 닫으면 분 단위 갱신이 멈추는지. **Not verified** — PR에서 사용자에게 확인을 부탁한다(구현 측 확인: 앱 실행·색인·종료, 메모리·CPU 측정)
- [x] 보안: 네트워크 API 0건, `~/.claude` 쓰기 0건, `*.key` 파일을 여는 코드 0건(테스트)
- [x] PR 브랜치에 base merge 커밋 없음

## §6. NFR · 성능

| 항목 | 목표 | 측정 결과 (2026-11-18, 개발자 기기, release) |
|---|---|---|
| 유휴 CPU | 경고가 없고 팝오버가 닫혀 있을 때 타이머 0개, 10분 평균 CPU 0.1% 이하 | 기록 변경이 없는 20초 동안 0.0%. 10분 관찰은 하지 못했다(이 작업 세션이 계속 기록을 쓴다). 작업 중인 세션이 매초 쓰는 동안은 평균 1.9%였고, 그 뒤 갱신 간격을 늘렸다(편차 로그) |
| 메모리 | 상주 100MB 이하(첫 색인 중 최대값 포함) | `footprint` 기준 유휴 22 ~ 29MB, 첫 색인 중 최대 63MB, 기존 색인으로 시작할 때 최대 50MB |
| 팝오버 열기 | 캐시된 값이 바로 보임(0.1초 이내) | 계측하지 않음(Not verified). 열 때 다시 계산하는 보고서는 7일 기준 0.15초 이내(2-2 측정) |
| 기간 바꾸기 | 1초 이내 | 보고서 계산 0.14 ~ 0.16초(CLI, 프로세스 시작 포함)로 추정 |
| 기록 변경 반영 | 파일 변경 후 2초 이내 메뉴 막대 갱신 | 조용하던 뒤의 첫 변경은 FSEvents 0.5초 + 2초. 변경이 계속되면 팝오버가 닫혀 있을 때 최대 30초, 열려 있을 때 최대 10초 간격(편차 로그) |
| 첫 색인 | 1.7GB 기준 2분 이내 | 앱에서 약 15초(CLI 11.5초). 기존 색인으로 시작하면 CPU 0.84초 |

## §7. 편차 로그 (Deviations) — 구현 후

| SoT | 실제 구현 | 사유 |
|---|---|---|
| design 7장 "처음 30일치를 먼저 처리해서 화면을 띄움" | 진행 막대만 보이고 끝나면 전체 결과 | 첫 색인이 11.7초라 나눠 처리할 이득이 없다(DECISIONS 2026-11-18). 구현 전 확정 |
| design 5장 세션 제목 출처 "데스크톱 메타데이터의 `title`" | 읽지 않음. `custom-title` → 실행 세션 `name` → 폴더 이름 | `custom-title`이 최근 세션 76개 중 74개를 덮고, 메타데이터가 더해 주는 것이 없다(DECISIONS 2026-11-18). 구현 전 확정 |
| domain-entities `procStart`: `ps lstart` 형식의 로컬 시각 | UTC로 읽고, 로컬로 읽은 값도 함께 받아들인다 | 실행 중인 세션 4개 모두 `ps -o lstart`보다 정확히 9시간(이 기기의 UTC 오프셋) 빨라 UTC로 확인했다. 명세가 틀렸다. 독립 리뷰가 "형식이 바뀌면 경고가 조용히 꺼진다"고 지적해 두 해석을 모두 받는다 |
| `RunningSession.Status`: busy/idle/other | `waiting`을 더하고 idle처럼 경고한다 | 실제 기기에서 `waiting`(사용자 답을 기다림)을 확인했다. 호출이 없으니 캐시가 만료를 향해 간다 |
| domain-entities `read_stats(lines, assistant_lines, assistant_without_call, calls)`, 모두 읽은 날 기준 | assistant 줄과 호출이 되지 못한 줄은 **그 줄의 날짜**로, `lines_appended`·`calls_appended`는 읽은 날로 쌓고 첫 전체 색인에서는 세지 않는다 | 읽은 날 기준이면 첫 실행 때 몇 달치 기록이 전부 "오늘 읽은 줄"이 되어 옛 형식의 줄이 잘못된 경고를 띄울 수 있다 |
| BR-H1 ① "최근 7일", ② "7일 합계 200줄·호출 0건" | ①은 정확히 7개 UTC 날짜, ②는 최근 이틀을 **날짜별로** 판단. `<synthetic>` 메시지는 분자·분모 모두에서 뺀다(파서가 `.rejected`로 돌려줌) | 독립 리뷰 MEDIUM 2건: 앞선 호출 하나가 ②를 최대 7일간 가렸고, 한도에 자주 걸리는 사용자에게 `<synthetic>` 때문에 거짓 배너가 떴다 |
| BR-I4 `.assistantWithoutCall` | `.assistantWithoutCall(timestamp:)` | 줄의 날짜로 쌓기 위해 |
| business-logic-model W1.3 "부모 폴더 감시" | 부모 폴더를 감시하고, 팝오버를 열 때도 다시 확인 | 구현 중 한때 빠졌다가 독립 리뷰 LOW로 복구 |
| BR-E6 "Untitled session"을 코어가 채움 | 코어는 nil, 화면이 현지화된 "Untitled session"을 쓴다 | 현지화 문구는 UI 라이브러리에만 둔다 |
| BR-N2 식별자 `expiry.<sessionID>.<expiresAt>` | `expiry.<sessionID>.<expiresAt>.<알림 시점(분)>` | 독립 리뷰 MEDIUM: 알림 시점을 바꿔도 같은 식별자라 다시 예약되지 않았다 |
| W2 "선택한 기간의 보고서는 팝오버가 열려 있을 때만 바로" | 보고서 캐시는 같은 분 안에서만 재사용하고, 팝오버를 열 때마다 다시 계산. 늦게 끝난 다른 기간의 결과는 버린다 | 독립 리뷰 MEDIUM 2건: 이동 창이 오래된 값으로 남았고, 기간 전환 경쟁으로 다른 기간의 숫자가 보였다 |
| W2 갱신 시점, NFR "2초 이내" | 조용하던 뒤의 첫 변경은 2초 뒤. 변경이 계속되면 팝오버가 닫혀 있을 때 30초, 열려 있을 때 10초 간격 | 작업 중인 세션은 매초 기록을 쓴다. 10초 간격일 때 평균 CPU 1.9%였다 |
| frontend-components `RebuildRow`의 `Button("Show Reason")`, §7 "After %@ away", "context %@ tokens" | 정보 아이콘 버튼(접근성 이름·도움말 "근거 보기"), 요약 문구 "62 min away", "context 1.1M" | 렌더링 검토 HIGH: 텍스트 버튼 때문에 요약이 잘려 비용이 보이지 않았다 |
| design 8.3 "만료 경고: 시스템 주황색, 아이콘과 텍스트", 강조색은 "줄일 수 있었음" 글자에 | 주황과 강조색은 아이콘에만, 글자는 primary. 정보를 담은 글자에서 `.secondary`를 뺐다 | 렌더링 검토 HIGH: 밝은 모드 실측 대비가 주황 글자 2.31:1, 강조색 글자 4.02:1, 보조 회색 3.95:1로 본문 기준 4.5:1에 못 미쳤다 |
| frontend-components `OtherDisclosure`(직접 만든 펼침) | 시스템 `DisclosureGroup` | 직접 만든 버튼은 비활성 창에서 레이블이 흐리게 그려졌다. 플랫폼 컨트롤이 초점 표시와 키보드 조작을 제공한다 |
| frontend-components §1 "팝오버 최대 화면 높이의 80%" | 경고는 최대 5개와 "N개 더", 재구축 목록은 4.5행 스크롤 | 높이를 직접 재지 않고 각 목록의 길이를 묶어 같은 효과를 낸다(독립 리뷰 LOW) |
| frontend-components §7 문구 | 문구 113개. 원인별 요약과 TTL별 규칙 문장을 각각 한 문장 키로, 가격 미확인 안내 문장 추가, 진행 표시와 메뉴 막대 상태별 VoiceOver 이름 추가 | 독립 리뷰 LOW: 문장 조각 이어 붙이기, 이름 없는 진행 표시 |
| (명세 없음) | 개발용 CLI `running-out health`, `running-out sessions`(제목 없이 숫자만), 화면 스냅숏 도구 `ui-snapshots`, `scripts/check-strings.py`(키·한국어·자리 표시자 대조) | 실제 기록에서의 확인과 CI 검증용 |
