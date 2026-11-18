---
artifact: business-rules
build-spec: menu-bar-app
status: READY
updated: 2026-11-18
---

# Business Rules — 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림

## 1. 규칙 표 (Rules)

### 실행 중인 세션 (Registry)
| ID | 규칙 (결정적 서술) | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-R1 | `~/.claude/sessions/`에서 이름이 `<숫자>.json`인 파일만 읽고, domain-entities `RunningSession`의 키만 해석한다. 해석하지 못한 파일은 건너뛴다 | `SessionRegistry` | 그 파일 무시 | design 5장, 2-3 관찰 |
| BR-R2 | 살아 있는 세션: `kill(pid, 0)`이 성공하거나 `EPERM`이고, `processStart`가 있으면 `sysctl`로 얻은 그 프로세스의 시작 시각과 2초 이내로 같다. 아니면 남은 파일로 보고 무시한다 | `SessionRegistry` | 그 세션 제외 | design 6.5, PID 재사용 대비 |
| BR-R3 | 그 폴더의 다른 파일(예: `<pid>.<hash>.key`)은 열지 않는다. 그 폴더에 쓰지 않는다 | `SessionRegistry` | 테스트로 막음 | 반목표 1·4, 2-3 관찰 |
| BR-R4 | 폴더가 없거나 읽을 수 없거나, `<숫자>.json`이 있는데 하나도 해석되지 않으면 `.unavailable` | `SessionRegistry` | BR-E1의 대체 경로 | design 6.5 |
| BR-R5 | 폴더를 FSEvents로 감시하고, 경고가 있는 동안에는 1분마다 다시 읽는다(파일 변화 없이 프로세스가 끝난 경우) | `AppModel` | | design 6.5 |

### 만료 경고 (Expiry)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-E1 | 경고 대상: 메인 세션이고, `contextTokens ≥ warningContextTokens`이고, `now < expiresAt`이며, (실행 세션 파일을 읽을 수 있으면) 살아 있고 `status == idle`이다. `status == other`이면 `statusKnown = false`로 포함한다. 파일을 읽을 수 없으면(`.unavailable`) 마지막 호출이 TTL 안에 있는 메인 세션을 `statusKnown = false`로 포함한다. `busy`는 제외한다 | `ExpiryCalculator` | | design 6.5 |
| BR-E2 | `contextTokens` = 마지막 호출의 마지막 본 모델 단계(`kind == message`)의 입력 + 캐시 읽기 + 캐시 쓰기. 같은 메시지의 마지막 줄 usage를 쓴다(2-2 R16) | `ExpiryCalculator` | | design 6.5, 2-2 |
| BR-E3 | `expiresAt` = 마지막 호출 시각 + TTL. TTL은 그 호출의 TTL, 없으면 같은 파일에서 가장 최근에 확인된 TTL, 그것도 없으면 1시간 | `ExpiryCalculator` | | design 5장 "TTL 갱신 규칙", 2-2 R5 |
| BR-E4 | `rebuildCost` = `contextTokens` × 그 TTL의 쓰기 단가. 모델 일치와 장문맥 구간은 2-2 R10(구간은 `contextTokens`로 판단). 가격 미확인 모델이면 대체 가격으로 계산하고 금액 앞에 "약"을 붙인다 | `ExpiryCalculator` | | design 6.5 |
| BR-E5 | 경고는 `expiresAt` 오름차순. 첫 경고에만 다음 행동 문장을 보인다 | `ExpiringSessionsSection` | | design 8.1 |
| BR-E6 | 표시 제목: 색인의 `custom-title` → 실행 세션의 `name` → `cwd`의 마지막 경로 요소 → "Untitled session" | `ExpiryCalculator` | | 2-3 관찰(제목 76개 중 74개가 `custom-title`) |
| BR-E7 | 남은 분 = `ceil((expiresAt − now) / 60)`. 60초 미만이면 "1분 미만". 화면은 분이 바뀔 때 다시 그리고, VoiceOver로 따로 알리지 않는다 | `ExpiryWarningRow` | | design 8.3 |
| BR-E8 | 메뉴 막대: 경고가 있으면 가장 이른 경고의 남은 분, 없으면 오늘의 `idleRebuildShare`(정수 %). 오늘 비용이 0이면 숫자 없이 아이콘만 | `MenuBarLabel` | | design 8.1 |

### 알림 (Notifications)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-N1 | 예약 조건: `notifyBeforeExpiry`가 켜져 있고, 알림 권한이 허용되어 있고, 경고의 TTL이 1시간이고, `fireAt = expiresAt − notifyLeadMinutes × 60`이 지금보다 뒤다 | `NotificationScheduler` | 예약하지 않음 | design 6.5 |
| BR-N2 | 식별자는 `expiry.<sessionID>.<expiresAt 정수 초>`. 경고를 다시 계산할 때마다, 지금 조건을 만족하는 식별자만 남기고 이 앱이 예약한 나머지 대기 알림을 지운다 | `NotificationScheduler` | | design 6.5 "한 번만" |
| BR-N3 | 이미 지난 `fireAt`으로는 예약하지 않는다(늦은 알림 없음). 그래서 한 번 울린 알림은 다시 예약되지 않는다 | `NotificationScheduler` | | design 6.5 "한 번만" |
| BR-N4 | 토글을 켤 때 처음으로 권한(알림, 소리)을 요청한다. 거부되면 토글은 켜 둔 채 설정 창에 상태와 "알림 설정 열기"를 보인다 | `SettingsView` | | better-writing, better-accessibility |
| BR-N5 | 알림을 눌러도 특정 세션으로 이동하지 않는다(비목표) | | | design 2장 비목표 |

### 비용 버킷과 임계값 (2-2 확장)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-B1 | advisor 단계의 비용은 메인·서브에이전트 모두 `advisor` 버킷에 넣는다. 메인 재구축 호출의 `normalWork`는 (호출 비용 − 재구축한 단계의 쓰기 비용 − advisor 비용), 서브에이전트 호출의 `subagents`는 (호출 비용 − advisor 비용) | `UsageAnalyzer` | | DECISIONS 2026-11-18(사용자 결정) |
| BR-B2 | CLI와 프로토타입의 버킷 순서: normal work, rebuild after short break, rebuild after long break, session start & compaction, subagents, advisor, model change & update, unknown. 2-2의 "advisor (in buckets)" 줄은 `advisor calls       N, input=…, output=…`로 바꾼다(N > 0일 때만) | `ReportText`, `drain.py` | | 같음 |
| BR-B3 | 재구축 임계값은 매개변수다(기본 50,000). 분석기, `running-out report --rebuild-threshold`, `drain.py --rebuild-threshold`가 같은 값을 받는다 | `RebuildClassifier`, `UsageAnalyzer` | | DECISIONS 2026-11-18(AI 제안, 승인 게이트에서 확인) |
| BR-B4 | `RebuildEvent`에 `previousContextTokens`(직전 호출의 BR-E2 값)를 더한다. 긴 휴식 행에 보인다 | `UsageAnalyzer` | | design 8.1 |

### 색인 (2-1 확장)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-I1 | 스키마 v4: `read_stats` 표(domain-entities). 파일을 읽을 때마다 그날의 행에 더한다. 처음 열 때 색인을 다시 만든다 | `Indexer` | | BR-H1 |
| BR-I4 | 2-1 R1 확장: `"assistant"`가 들어 있는 줄은 `"usage"`가 없어도 해석한다. 최상위 `type`이 `assistant`인데 2-1 R2를 만족하지 못하면 `.assistantWithoutCall`(새 결과)로 돌려준다. 호출 판정은 바뀌지 않는다 | `RecordParser` | | BR-H1 |
| BR-I2 | `indexAll(progress:)`: 읽을 바이트 합(`bytesTotal`)과 읽은 바이트(`bytesRead`)를 최대 0.1초 간격으로 알린다 | `Indexer` | | design 8.2, 2-1 편차 |
| BR-I3 | `lastCall(ofSession:)`: `kind == main`이고 `session_id`가 같은 파일(여럿이면 가장 늦게 만든 파일)의 마지막 호출 | `Indexer` | 없으면 nil | BR-E1 |

### 형식 변화 (Health)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-H1 | 최근 7일의 `read_stats`로 판단한다. ① `assistantLines ≥ 50`이고 `assistantWithoutCall / assistantLines > 5%`이면 `unreadableLines`. ② ①이 아니고 `mainLines ≥ 200`인데 `mainCalls == 0`이면 `noCalls`(최상위 `type` 자체가 바뀐 경우). 그 밖은 `none` | `Indexer.health(since:)` | 배너 표시 | design 8.2, 10장, 2026-11-18 측정 |

### 화면 계산 (UI)
| ID | 규칙 | 적용 대상 | 위반 시 동작 | 근거/출처 |
|---|---|---|---|---|
| BR-U1 | 원인 행: Normal work(`normalWork`), Cache rebuilt after a short break(`shortBreakRebuild`), Cache rebuilt after a long break(`longBreakRebuild`), Subagents, Advisor, Other(`sessionStartAndCompaction` + `modelChangeAndUpdate` + `unknown`). Other는 펼치면 세 항목을 보인다. 0%여도 행을 둔다(배치가 흔들리지 않게) | `BreakdownSection` | | design 8.1, 디자인 검토 |
| BR-U2 | 비율은 정수 %. 0보다 크고 0.5% 미만이면 "<1%" | `BreakdownRow` | | |
| BR-U3 | 요약: 그 기간의 정가 환산 총액, 호출 수, `idleRebuildShare` 문장. 재구축 임계값이 기본값이 아니면 그 사실을 한 줄 더 보인다 | `BreakdownSection` | | 디자인 검토, BR-B3 |
| BR-U4 | 재구축 목록: 기본은 만료(짧은 휴식·긴 휴식)만. "모든 원인 보기"를 켜면 압축 직후, 모델 변경, 업데이트 직후, 원인 불명을 더한다. 세션 시작과 서브에이전트는 넣지 않는다. 비용 내림차순, 같으면 시각 내림차순, 최대 50행 | `RebuildListSection` | | design 8.1 |
| BR-U5 | 토큰 수는 로캘의 축약 표기(`720K`, `72만`), 금액은 USD 통화 형식(소수 둘째 자리), 시각은 오늘이면 시:분, 아니면 월·일과 시:분 | 모든 화면 | | design 8.3 현지화 |

## 2. 검증 규칙 (Validation)

| 입력 | 규칙 | 경계/형식 | 실패 메시지·코드 |
|---|---|---|---|
| `AppSettings` 값 | domain-entities의 허용 값만 | 그 밖이면 기본값으로 읽음 | 없음 |
| `running-out report --rebuild-threshold` | 1 이상의 정수 | | 종료 코드 2 |
| `drain.py --rebuild-threshold` | 1 이상의 정수 | | argparse 오류 |
| 실행 세션 파일 | BR-R1의 키, `pid`와 파일 이름 일치 | | 그 파일 무시 |

## 3. 권한 / 접근 규칙 (Authz)

- 앱이 읽는 곳: `~/.claude/projects/**`(2-1과 같음)와 `~/.claude/sessions/<숫자>.json`. 그 밖의 `~/.claude` 파일과 Claude 데스크톱 앱의 데이터 폴더는 읽지 않는다(DECISIONS 2026-11-18).
- 앱이 쓰는 곳: 색인 데이터베이스와 `UserDefaults`뿐이다.
- 네트워크를 쓰지 않는다. 링크(릴리스 페이지, 소스 코드)는 `NSWorkspace.open`으로 브라우저에 넘긴다.

## 4. 불변식 (Invariants)

- INV1: 버킷 비용의 합 = `totalCost`(advisor 포함, 나노달러 정수로 정확히 같음).
- INV2: 한 세션에 대기 중인 만료 알림은 많아야 하나다.
- INV3: 같은 기간·같은 임계값에서 팝오버의 숫자와 `running-out report`의 숫자는 같은 코어에서 나온다(따로 계산하지 않는다).
- INV4: `Sources/`에 네트워크 API 0건, `~/.claude`에 쓰기 0건(CI 검사를 앱 대상까지 넓힌다).
- INV5: 2-2의 INV4(프로토타입과 글자 단위로 같음)는 기본 임계값과 다른 임계값 모두에서 성립한다.

## 5. 엣지케이스 · 에러 매핑

| 케이스 | 조건 | 기대 동작 |
|---|---|---|
| 경고 임계값 경계 | 컨텍스트 = 100,000 / 99,999 | 경고 / 없음 |
| 만료 경계 | `now == expiresAt` | 경고 없음(이미 만료) |
| 남은 시간 1분 미만 | 남은 59초 | "1분 미만" |
| busy 세션 | `status == busy` | 경고 없음 |
| 모르는 상태 | `status == "waiting"` 등 | `statusKnown = false`로 경고 |
| 남은 실행 세션 파일 | 프로세스가 끝났거나 PID가 재사용됨 | 그 세션 무시 |
| `.key` 파일 | 같은 폴더의 `<pid>.<hash>.key` | 열지 않음 |
| 실행 세션 폴더 없음 | 오래된 Claude Code | `.unavailable`, TTL 안의 메인 세션을 "상태 확인 불가"로 경고 |
| 5분 TTL 세션 | 마지막 호출의 TTL이 5분 | 화면에만 표시, 알림 없음(알림이 켜져 있으면 그 이유를 한 줄로) |
| 알림 시점이 지남 | 앱을 `fireAt` 뒤에 실행 | 알림 없음, 화면에는 표시 |
| 새 호출로 만료 연장 | 같은 세션의 `expiresAt`이 바뀜 | 이전 알림 삭제, 새 식별자로 예약 |
| 알림 권한 거부 | 사용자가 시스템 대화상자에서 거부 | 예약하지 않음, 설정 창에 상태와 복구 버튼 |
| 경고 없음 | 대상 세션 0개 | 구역을 숨김 |
| 기록 없음 | `~/.claude/projects`가 없음 | "기록 없음" 상태 |
| 첫 색인 | 색인이 비어 있음 | 진행 막대, 끝나면 보고서 |
| 색인 오류 | 데이터베이스를 열거나 쓸 수 없음(디스크 가득, 권한) | 오류 상태와 "다시 시도" |
| 형식 변화: `usage` 이름이 바뀜 | assistant 줄에 `usage`가 없음 | `unreadableLines` 배너(BR-H1 ①) |
| 형식 변화: `message.id`가 없어짐 | assistant 줄이 R2 불충족 | `unreadableLines` 배너 |
| 형식 변화: 최상위 `type`이 바뀜 | 메인 파일에 줄은 늘지만 호출 0건 | `noCalls` 배너(BR-H1 ②) |
| 평소의 `<synthetic>` 메시지 | 0.1% 미만 | 배너 없음 |
| 재구축 없음 | 목록이 비어 있음 | 빈 상태 문구(모든 원인 보기가 꺼져 있으면 켜는 방법 안내) |
| 비용 0인 기간 | 호출 0건 | 원인 행 대신 "이 기간에는 사용 기록이 없습니다" |
| 긴 제목 | 한 줄을 넘음 | 한 줄로 자르고 도움말과 근거 화면에서 전체 표시 |
| 임계값을 바꿈 | 30,000으로 설정 | 모든 기간 재계산, 요약에 바뀐 값 표시 |
| 가격 미확인 모델 | 표에 없는 모델 | 금액 앞에 "약", 근거 화면에 모델 이름 |
