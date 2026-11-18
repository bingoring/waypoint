---
artifact: business-logic-model
build-spec: menu-bar-app
status: READY
updated: 2026-11-18
---

# Business Logic Model — 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림

## 1. 모듈 구조

| 타깃 | 종류 | 내용 | 의존 |
|---|---|---|---|
| `RunningOutCore` | 라이브러리(기존) | 2-1·2-2에 더해 `SessionRegistry`, `ExpiryCalculator`, `Indexer.health`·`lastCall`·진행률, advisor 버킷, 임계값 매개변수 | Foundation, SQLite3 |
| `RunningOutUI` | 라이브러리(신규) | SwiftUI 화면, `AppModel`(`@MainActor @Observable`), 표시용 계산(`PopoverPresentation`), String Catalog(`Localizable.xcstrings`, en·ko). 시스템 서비스는 프로토콜(`NotificationScheduling`, `LoginItemControlling`, `URLOpening`)로만 쓴다 | `RunningOutCore`, SwiftUI |
| `TokensAreRunningOut` | 실행 파일(신규) | `@main` App: `MenuBarExtra(.window)`, `Settings` 장면, 프로토콜의 실제 구현(`UNUserNotificationCenter`, `SMAppService`, `NSWorkspace`) | `RunningOutUI` |
| `ui-snapshots` | 개발용 실행 파일(신규, `Tools/ui-snapshots`) | 합성 데이터로 화면 상태를 PNG로 그림(밝은·어두운 모드, en·ko). 배포하지 않음 | `RunningOutUI` |
| `running-out` | 개발용 CLI(기존) | `--rebuild-threshold` 추가 | `RunningOutCore` |

- **빌드:** `scripts/build-app.sh`가 `xcodebuild`로 패키지를 빌드하고(`swift build`는 String Catalog를 컴파일하지 않는다), `TokensAreRunningOut.app`을 조립해 ad-hoc 서명한다. `Info.plist`: `CFBundleIdentifier = io.github.bingoring.TokensAreRunningOut`, `LSUIElement = true`, `CFBundleLocalizations = [en, ko]`, `LSMinimumSystemVersion = 14.0`. 정식 서명과 공증은 2-4에서 한다. `--snapshots`를 주면 `UISnapshots.app`도 같은 방식으로 만든다.

## 2. 워크플로 (Workflows)

### W1. 앱 시작
1. `AppSettings`를 읽는다.
2. `IndexService`를 연다. 실패하면 `AppState.indexError`.
3. `~/.claude/projects`가 없으면 `AppState.noTranscripts`. 폴더가 생기는지 부모 폴더를 감시한다.
4. 기록 감시(`~/.claude/projects`)와 실행 세션 감시(`~/.claude/sessions`)를 **먼저** 시작한다(2-1 결정과 같은 이유).
5. `indexAll(progress:)`를 백그라운드에서 실행한다. 색인이 비어 있었으면 `AppState.indexing(progress)`를 보이고, 아니면 이전 결과를 보인 채 갱신한다.
6. 끝나면 `ready`. 오늘 보고서(메뉴 막대), 선택한 기간의 보고서, 경고, `IndexHealth`를 계산하고 알림을 맞춘다(W6).

### W2. 기록이 바뀜 (FSEvents 묶음, 0.5초 지연)
1. `IndexService.update(paths:)`.
2. 읽은 파일이 있으면 보고서 캐시의 세대를 올리고, 오늘 보고서와 경고를 다시 계산한다. 선택한 기간의 보고서는 팝오버가 열려 있을 때만 바로, 아니면 열 때 계산한다.
3. W6.

### W3. 실행 세션 파일이 바뀜
1. `SessionRegistry.load()` → `RegistryState`.
2. 경고를 다시 계산하고 W6.

### W4. 분 단위 갱신
- 경고가 하나 이상 있거나 팝오버가 열려 있을 때만 다음 분의 경계에 맞춰 동작한다. 그 밖에는 타이머가 없다(NFR).
- 할 일: 실행 세션 파일 다시 읽기(BR-R5), 만료된 경고 빼기, 메뉴 막대 표시 갱신.

### W5. 사용자 조작
| 조작 | 처리 |
|---|---|
| 기간 바꿈 | 캐시(`(기간, 임계값, 세대)` 키)에 있으면 바로, 없으면 계산 |
| "모든 원인 보기" | 이미 계산한 보고서에서 목록만 다시 거름 |
| "근거 보기" | 그 `RebuildEvent`로 근거 팝오버를 엶 |
| 재구축 임계값 바꿈 | 캐시 전부 무효화, 오늘·선택 기간 다시 계산 |
| 경고 임계값 바꿈 | 경고 다시 계산, W6 |
| 알림 토글 켬 | 권한을 요청한 적이 없으면 요청(BR-N4), W6 |
| 알림 시점 바꿈 | W6 |
| 로그인할 때 열기 | `SMAppService.mainApp.register()` / `unregister()`, 상태를 다시 읽음 |
| 날짜가 바뀜(`NSCalendarDayChanged`) | 오늘 보고서 다시 계산 |
| 잠자기에서 깨어남 | 실행 세션 다시 읽기, 경고 다시 계산, W6 |
| 다시 시도(색인 오류) | W1의 2단계부터 |

### W6. 알림 맞추기 (reconcile)
```
desired = warnings
  .filter { settings.notifyBeforeExpiry && authorized && $0.ttl == .oneHour }   # BR-N1
  .map { ScheduledExpiryNotification(id: "expiry.\($0.sessionID).\(Int($0.expiresAt))",
                                     fireAt: $0.expiresAt - lead * 60, ...) }
  .filter { $0.fireAt > now }                                                 # BR-N3
pending = scheduler.pendingIdentifiers(prefix: "expiry.")
scheduler.remove(pending − desired.ids)                                       # BR-N2
scheduler.add(desired where id ∉ pending)                                     # 시간 간격 트리거
```

## 3. 알고리즘 (Algorithms)

### 3.1 경고 계산
```
warnings(registry, now, settings, prices):
  candidates = switch registry
    .available(sessions): sessions.filter(alive && status != busy)            # BR-E1, BR-R2
                                  .map { ($0, indexer.lastCall(ofSession: $0.sessionID), known: $0.status == idle) }
    .unavailable: indexer.mainFilesWithCalls(since: now - 3600)               # TTL 안일 수 있는 파일
                         .map { (nil, indexer.lastCall(of: $0), known: false) }
  for (session, last, known) in candidates where last != nil:
    context = last.contextTokens                                              # BR-E2
    expiresAt = last.timestamp + last.ttl.seconds                             # BR-E3
    guard context >= settings.warningContextTokens, now < expiresAt
    price = prices.lookup(last.model, promptTokens: context)                  # BR-E4
    cost = context * (last.ttl == .oneHour ? price.cacheWrite1h : price.cacheWrite5m)
    emit ExpiryWarning(..., displayTitle: last.title ?? session?.name ?? lastPathComponent(session?.cwd) ?? "Untitled session")
  sort by expiresAt                                                            # BR-E5
```

### 3.2 형식 변화
```
health(since: now - 7d):
  SELECT SUM(candidate_lines), SUM(parse_failures) FROM files WHERE read_at >= ?
  formatChanged = failures >= 20 && failures > candidates * 0.01               # BR-H1
```

### 3.3 메뉴 막대 표시
```
label(warnings, today):
  if let first = warnings.first: "\(remainingMinutes(first)) min"             # BR-E7, BR-E8
  elif today.totalCost == 0: icon only
  else: percent(today.idleRebuildShare, 0 decimals)
```

### 3.4 원인 행 (BR-U1, BR-U2)
```
rows(report):
  normal, short, long, subagents, advisor = report.bucketCosts[...]
  other = sessionStartAndCompaction + modelChangeAndUpdate + unknown
  share(x) = x / total → "<1%" if 0 < share < 0.005 else rounded integer %
```

## 4. 상태 전이 (State Transitions)

| 현재 상태 | 이벤트 | 다음 상태 | 액션 |
|---|---|---|---|
| (시작) | 색인을 열지 못함 | `indexError` | 다시 시도 버튼 |
| (시작) | 기록 폴더 없음 | `noTranscripts` | 부모 폴더 감시 |
| (시작) | 색인이 비어 있음 | `indexing` | 진행률 표시 |
| (시작) | 색인이 있음 | `ready` | 이전 결과를 보이며 갱신 |
| `noTranscripts` | 기록 폴더가 생김 | `indexing` | W1의 4단계부터 |
| `indexing` | 색인 끝 | `ready` | W1의 6단계 |
| `indexing`, `ready` | 색인 쓰기 실패 | `indexError` | 감시는 유지 |
| `indexError` | 다시 시도 성공 | `ready` 또는 `indexing` | |

## 5. 시퀀스 / 상호작용 (Sequence)

1. FSEvents 콜백 → 메인 액터의 `AppModel` → `IndexService`(actor)에서 색인·분석 → 결과를 메인 액터로 돌려 상태를 바꾼다. 분석은 메인 스레드에서 하지 않는다.
2. 팝오버를 열 때는 이미 계산한 값을 바로 보이고, 계산 중이면 직전 값 위에 작은 진행 표시를 둔다(값을 지우지 않는다).
3. 알림은 시스템이 보낸다. 앱이 잠자기 상태여도 예약된 알림은 울린다.

## 6. 통합 지점 (Integration Points)

| 대상 | 호출 시점 | 요청/응답 요지 | 실패 처리 |
|---|---|---|---|
| FSEvents | 시작 시 | 두 폴더의 변경 묶음 | 감시를 못 하면 1분마다 다시 읽음 |
| `kill(2)`, `sysctl(KERN_PROC_PID)` | 실행 세션 읽을 때 | 프로세스 생존, 시작 시각 | 실패하면 그 세션 제외 |
| `UNUserNotificationCenter` | W6, 토글 켤 때 | 권한, 대기 알림 목록, 추가·삭제 | 권한 거부면 예약 안 함(BR-N4) |
| `SMAppService.mainApp` | 설정에서 | 등록·해제·상태 | `requiresApproval`이면 안내와 "로그인 항목 설정 열기" |
| `NSWorkspace` | 링크 버튼, 깨어남 알림 | URL 열기 | 실패해도 앱은 계속 |
| 2-2 `UsageAnalyzer` | 보고서 계산 | `report(from:to:)`(임계값 매개변수) | 오류는 `indexError` |
