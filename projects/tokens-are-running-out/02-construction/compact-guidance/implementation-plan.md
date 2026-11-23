# 큰 세션 정리 안내 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실행 중인 큰 세션(컨텍스트 20만 토큰 이상)을 팝오버에 보이고 `/compact` 프롬프트를 복사하게 하며, compact 뒤의 세션은 만료 경고와 목록에서 뺀다.

**Architecture:** 코어(`RunningOutCore`)에 `LargeSessionFinder`를 두고, 만료 경고와 같은 의존성(`RegistryState`, `LastCall`, `PriceTable`)으로 큰 세션을 고른다. `LastCall`에 "마지막 호출 뒤 compact 여부"를 더해 두 계산이 함께 쓴다. 앱(`RunningOutUI`)은 경고를 갱신할 때 큰 세션도 함께 갱신하고, 복사는 바꿔 끼울 수 있는 클립보드 프로토콜로 한다.

**Tech Stack:** Swift 6.4, SwiftUI(macOS 14+), Swift Testing, SQLite(기존 색인), `Localizable.xcstrings`

**Spec:** [`../05-compact-guidance.md`](../05-compact-guidance.md)(승인 결과 포함), [`build-spec-index.md`](build-spec-index.md), [`domain-entities.md`](domain-entities.md), [`business-rules.md`](business-rules.md), [`frontend-components.md`](frontend-components.md)

## Global Constraints

- 큰 세션 기준: `200_000` 토큰, 이상(`>=`). 상수 `LargeSessionFinder.defaultThresholdTokens`. 설정으로 만들지 않는다.
- 호출당 다시 읽는 비용: `contextTokens × prices.cacheRead`(nano-USD). 단가는 `PriceTable.lookup(model:promptTokens: contextTokens)`.
- 최대 5줄, 넘치면 기존 문구 `%lld more sessions` 재사용.
- 프롬프트는 domain-entities `CompactPrompt`의 두 문자열과 글자 단위로 같다. 한국어가 시험본이다.
- 네트워크, `~/.claude` 쓰기, 대화 본문 읽기를 늘리지 않는다. 앱은 `/compact`를 실행하지 않는다.
- "아낄 수 있다" 같은 금액 단정 문구를 쓰지 않는다.
- 새 문구는 모두 `Localizable.xcstrings`에 영어 원문과 한국어 번역으로 둔다. 문구는 frontend-components "새 문구 목록" 그대로다.
- 엄격 빌드(`-warnings-as-errors`), `swift format lint --strict`, 커밋 메시지는 conventional commit 한 줄, 공동작업 트레일러 금지.
- 테스트와 스냅숏의 세션 제목은 가상의 값만 쓴다.

## Review Focus

1. **compact 직후 같은 세션이 다시 메시지를 보낸 경우:** 새 호출이 compact 표시보다 뒤이므로 `compactedAfter == false`가 되고, 새 크기로 다시 판단해야 한다 → Task 1의 `callAfterCompactionCounts`.
2. **한 세션을 두 프로세스가 연 경우:** 큰 세션 목록에 한 번만 보여야 한다 → Task 2의 `duplicateSessionOnce`.
3. **클립보드 쓰기 실패:** 다른 앱이 클립보드를 잡고 있어 실패하면 "복사됨"을 보이면 안 된다 → Task 4의 `failedCopyIsNotConfirmed`.
4. **긴 제목, 큰 글씨, 한국어 문구:** 360pt 폭에서 버튼이 잘리거나 겹치면 안 된다 → Task 6의 스냅숏 검토 기준.
5. **버튼을 2초 안에 다시 누름:** 마지막으로 누른 때부터 2초 동안 "복사됨"이 유지되고, 앞의 타이머가 그 상태를 일찍 지우면 안 된다 → Task 5의 수동 확인 항목.

---

### Task 0: 대화형 붙여 넣기 확인 (사용자와 함께, 코드 없음)

**Files:** 없음(결과는 Task 7에서 Build Spec §7에 기록)

- [ ] **Step 1:** 시험용 복제 세션 하나(예: 기존 시험 복제본)를 사용자가 자기 터미널에서 대화형으로 연다. 원래 세션의 작업 폴더에서 `claude --resume <복제본 ID>`를 실행한다.
- [ ] **Step 2:** AI가 domain-entities의 한국어 프롬프트를 `pbcopy`로 클립보드에 넣는다. 사용자는 붙여 넣고 Return을 누른다.
- [ ] **Step 3:** 복제본 기록 끝에 `compact_boundary`(trigger `manual`)와 요약 메시지가 생겼는지, 요약이 A2 구조(목표, 사용자 지시, 결정 …)를 따르는지 AI가 확인한다. 집계만 출력한다.
- [ ] **Step 4:** 실패하면 BR-C20에 따라 프롬프트를 한 줄 형식으로 바꾸고(같은 단어, 항목 사이는 공백) Step 2~3을 다시 한다. 결과는 Task 7에서 편차 로그에 적는다.

### Task 1: compact 뒤 세션 표시와 만료 경고 제외

**Files:**
- Modify: `Sources/RunningOutCore/Indexer.swift`(`LastCall`, `lastCall(ofSession:)`)
- Modify: `Sources/RunningOutCore/ExpiryCalculator.swift`(`warnings`)
- Test: `Tests/RunningOutCoreTests/IndexerTests.swift`, `Tests/RunningOutCoreTests/ExpiryCalculatorTests.swift`

**Interfaces:**
- Produces: `LastCall.compactedAfter: Bool`, 생성자 인자 `compactedAfter: Bool = false`(기존 호출부는 그대로 컴파일된다)

- [ ] **Step 1: 실패하는 테스트 작성**
  - `IndexerTests.compactionAfterLastCall`: `Fixture.call(id: "m1", …, session: "s1", read: 250_000)` 뒤에 `Fixture.compact(at:)`를 둔 기록 → `lastCall(ofSession: "s1")?.compactedAfter == true`
  - `IndexerTests.callAfterCompactionCounts`: 호출, compact, 다시 호출(`read: 20_000`) 순서 → `compactedAfter == false`, `contextTokens == 20_000`
  - `ExpiryCalculatorTests.compactedSessionHasNoWarning`: `last("s1", ago: 600, context: 620_000)`에 `compactedAfter: true` → `warnings(.available([running("s1")]), …)`가 빈 배열
- [ ] **Step 2: 실행해서 실패 확인**
  Run: `swift test --filter "IndexerTests|ExpiryCalculatorTests"`
  Expected: 새 테스트 3개가 `compactedAfter` 미정의로 컴파일 실패
- [ ] **Step 3: 구현**
  - `lastCall`이 마지막 호출의 `seq`도 읽는다.
  - `SELECT EXISTS(SELECT 1 FROM marks WHERE file_id = ? AND seq > ?)`로 `compactedAfter`를 채운다.
  - `ExpiryCalculator.warnings`는 `last.compactedAfter`이면 건너뛴다.
- [ ] **Step 4: 실행해서 통과 확인**
  Run: `swift test --filter "IndexerTests|ExpiryCalculatorTests"`
  Expected: PASS(기존 테스트 포함)
- [ ] **Step 5: 커밋** `fix(core): drop compacted sessions from expiry warnings`

### Task 2: 큰 세션 찾기

**Files:**
- Create: `Sources/RunningOutCore/LargeSessionFinder.swift`
- Modify: `Sources/RunningOutCore/IndexService.swift`
- Test: Create `Tests/RunningOutCoreTests/LargeSessionFinderTests.swift`

**Interfaces:**
- Consumes: `LastCall.compactedAfter`(Task 1)
- Produces:
  - `public struct LargeSession: Sendable, Equatable { sessionID: String; title: String?; contextTokens: Int; readCost: Int; model: String; priced: Bool; status: Status }`, `enum Status { case running, unreadable }`
  - `public enum LargeSessionFinder { static let defaultThresholdTokens = 200_000; static func sessions(registry: RegistryState, now: Double, thresholdTokens: Int, prices: PriceTable, lastCall: (String) throws -> LastCall?, sessionsWithCallsSince: (Double) throws -> [String]) throws -> [LargeSession] }`
  - `IndexService.largeSessions(registry: RegistryState, now: Double = Date().timeIntervalSince1970, thresholdTokens: Int = LargeSessionFinder.defaultThresholdTokens) throws -> [LargeSession]`

- [ ] **Step 1: 실패하는 테스트 작성**(`ExpiryCalculatorTests`의 `running`, `last` 도우미 모양을 따른다. 모델 `claude-opus-5-5`, 캐시 읽기 단가 200 nano/token)
  - `thresholdBoundary`: 199,999는 없고 200,000은 있다
  - `busySessionIncluded`: 상태 `.busy`도 포함, `status == .running`
  - `duplicateSessionOnce`: 같은 세션 ID의 프로세스 두 개 → 한 번
  - `unreadableRegistryUsesRecentCalls`: `.unavailable` → `sessionsWithCallsSince(now - 3600)`의 세션, `status == .unreadable`
  - `compactedSessionExcluded`: `compactedAfter: true` → 없음
  - `readCostIsContextTimesCacheRead`: 620,000 → `readCost == 620_000 * 200`
  - `unpricedModelIsMarked`: 모르는 모델 → `priced == false`
  - `sortedByContextThenID`: 컨텍스트 내림차순, 같으면 세션 ID 오름차순
  - `titleFallsBackLikeWarnings`: 제목 없음 → 레지스트리 이름 → 폴더 이름
  - `sessionWithoutCallsHidden`: `lastCall`이 nil인 실행 중 세션 → 없음(BR-C4)
- [ ] **Step 2: 실행해서 실패 확인** — Run: `swift test --filter LargeSessionFinderTests`, Expected: 컴파일 실패(타입 없음)
- [ ] **Step 3: 구현** — 후보 수집과 제목 대체는 `ExpiryCalculator.warnings`와 같은 규칙이되, 상태 필터(`!= .busy`)와 만료 조건은 없다. 두 계산이 공유할 수 있는 후보 수집 부분은 작은 private 함수로 빼도 된다.
- [ ] **Step 4: 실행해서 통과 확인** — Run: `swift test --filter "LargeSessionFinderTests|ExpiryCalculatorTests"`, Expected: PASS
- [ ] **Step 5: 커밋** `feat(core): find running sessions with a large context`

### Task 3: 프롬프트 문자열

**Files:**
- Create: `Sources/RunningOutUI/CompactPrompt.swift`
- Modify: `Sources/RunningOutUI/Resources/Localizable.xcstrings`
- Test: Create `Tests/RunningOutUITests/CompactPromptTests.swift`

**Interfaces:**
- Produces: `enum CompactPrompt { static var text: String }`. 키는 영어 원문 전체이고, 한국어 번역을 둔다.

- [ ] **Step 1: 실패하는 테스트 작성**
  - `catalogHoldsTheTestedPrompts`: 테스트가 `#filePath` 기준으로 `Sources/RunningOutUI/Resources/Localizable.xcstrings`를 JSON으로 읽는다. 영어 키가 domain-entities의 영어 원문과 같고, `ko` 값이 한국어 원문(시험본)과 글자 단위로 같아야 한다. 두 원문은 테스트 파일에 상수로 둔다.
  - `startsWithCompactCommand`: 두 문자열 모두 `/compact `로 시작하고 `\r`이 없다
  - `runtimeTextIsOneOfThem`: `CompactPrompt.text`가 두 원문 중 하나다
- [ ] **Step 2: 실행해서 실패 확인** — Run: `swift test --filter CompactPromptTests`, Expected: FAIL(키 없음)
- [ ] **Step 3: 구현** — `String(localized:bundle: .module)`로 읽는다. 줄바꿈은 `\n`으로 보존한다.
- [ ] **Step 4: 실행해서 통과 확인** — Run: `swift test --filter CompactPromptTests`, Expected: PASS
- [ ] **Step 5: 커밋** `feat(app): add the tested compact prompt in English and Korean`

### Task 4: 앱 모델의 큰 세션과 복사

**Files:**
- Modify: `Sources/RunningOutUI/AppModel.swift`(`IndexServing`, 생성자, `refreshWarnings`, 새 속성·메서드)
- Modify: `Sources/RunningOutUI/SystemServices.swift`(`PasteboardWriting`, `SystemPasteboard`)
- Modify: `Sources/RunningOutUI/PreviewSupport.swift`(`PreviewServices`가 `PasteboardWriting`을 따르고, `preview(…, largeSessions: [LargeSession] = [])`)
- Modify: `Tests/RunningOutUITests/AppModelRecoveryTests.swift`(가짜 `IndexServing`에 `largeSessions`)
- Test: `Tests/RunningOutUITests/AppModelTests.swift`

**Interfaces:**
- Consumes: `IndexService.largeSessions`(Task 2), `CompactPrompt.text`(Task 3)
- Produces:
  - `IndexServing.largeSessions(registry: RegistryState, now: Double, thresholdTokens: Int) async throws -> [LargeSession]`
  - `@MainActor public protocol PasteboardWriting: AnyObject { func write(_ text: String) -> Bool }`, `SystemPasteboard`(`clearContents` 후 `setString(_:forType: .string)`의 결과를 돌려준다)
  - `AppModel.largeSessions: [LargeSession]`(`public internal(set)`), `AppModel.copyCompactPrompt() -> Bool`, 생성자 인자 `pasteboard: PasteboardWriting = SystemPasteboard()`

- [ ] **Step 1: 실패하는 테스트 작성**(`AppModelTests`의 기존 준비 방식)
  - `largeSessionsRefreshWithWarnings`: 실행 중인 세션 파일 `s1`과 컨텍스트 250,000인 호출 → 시작 뒤 `model.largeSessions.map(\.sessionID) == ["s1"]`
  - `copyWritesThePrompt`: 가짜 클립보드 → `copyCompactPrompt() == true`, 쓴 문자열이 `CompactPrompt.text`
  - `failedCopyIsNotConfirmed`: `write`가 false를 돌려주는 가짜 → `copyCompactPrompt() == false`
- [ ] **Step 2: 실행해서 실패 확인** — Run: `swift test --filter AppModelTests`, Expected: 컴파일 실패
- [ ] **Step 3: 구현** — `refreshWarnings`는 `registry.load()`를 한 번만 부르고, 같은 상태로 `expiryWarnings`와 `largeSessions`를 차례로 받는다. 둘 중 하나라도 실패하면 기존과 같이 `indexFailed`로 간다.
- [ ] **Step 4: 실행해서 통과 확인** — Run: `swift test`, Expected: 전체 PASS
- [ ] **Step 5: 커밋** `feat(app): refresh large sessions and copy the compact prompt`

### Task 5: 화면 (① 큰 세션 영역, ② 안내 줄)

**Files:**
- Create: `Sources/RunningOutUI/Views/LargeSessionsSection.swift`(`LargeSessionsSection`, `LargeSessionRow`, `CopyCompactPromptButton`)
- Modify: `Sources/RunningOutUI/Views/PopoverView.swift`(배치, `ExpiryWarningRow`)
- Modify: `Sources/RunningOutUI/Presentation.swift`
- Modify: `Sources/RunningOutUI/Resources/Localizable.xcstrings`(frontend-components의 새 문구 10개)
- Test: `Tests/RunningOutUITests/PresentationTests.swift`

**Interfaces:**
- Consumes: `AppModel.largeSessions`, `AppModel.copyCompactPrompt() -> Bool`(Task 4)
- Produces:
  - `Presentation.showsCompactHint(_ warning: ExpiryWarning, isFirst: Bool) -> Bool`: `isFirst && warning.status == .idle && warning.contextTokens >= LargeSessionFinder.defaultThresholdTokens`
  - `Presentation.largeSessionDetail(_ session: LargeSession, locale: Locale = .current) -> String`: 가격 있음/없음 두 문구

- [ ] **Step 1: 실패하는 테스트 작성**
  - `compactHintOnlyOnFirstLargeIdleRow`: (첫 줄, idle, 200,000) → true. 첫 줄이 아님, `.unknownStatus`, 199,999 → 각각 false
  - `largeSessionDetailText`: 620,000, readCost `620_000 * 200`, `en_US` → `"Context 620K · re-reads about $0.12 per call"`. 가격 없음 → `"Context 620K · re-reads an estimated $0.12 per call"`
- [ ] **Step 2: 실행해서 실패 확인** — Run: `swift test --filter PresentationTests`, Expected: 컴파일 실패
- [ ] **Step 3: 구현**
  - 배치: `LargeSessionsSection`은 `ExpiringSessionsSection`과 같은 조건 분기 안에서 그 바로 아래에 둔다. 따라서 오류, 기록 없음, 첫 색인 중에는 보이지 않는다(BR-C15). 큰 세션이 없으면 영역 전체를 그리지 않는다.
  - 버튼: `CopyCompactPromptButton(title: String?)`은 자기 `@State copied`를 가진다.
    - `model.copyCompactPrompt()`가 true일 때만 `copied = true`로 하고 `AccessibilityNotification.Announcement`를 보낸다.
    - 2초 뒤 되돌리는 `Task`는 다시 누르면 취소하고 새로 시작한다.
    - 애니메이션은 쓰지 않는다.
  - `ExpiryWarningRow`: `Presentation.showsCompactHint`가 true면 안내 문장 아래에 문장과 버튼을 둔다. 버튼이 따로 초점을 받도록 줄의 접근성 묶음을 `.contain`으로 바꾸고, 줄에는 요약 레이블을 둔다.
- [ ] **Step 4: 실행해서 통과 확인** — Run: `swift test`, Expected: 전체 PASS
- [ ] **Step 5: 수동 확인** — `scripts/build-app.sh` 후 앱을 PID로 실행해 VoiceOver 이름, Tab 이동, 2초 안에 다시 누르기를 확인하고 PID로 종료한다.
- [ ] **Step 6: 커밋** `feat(app): show large sessions with a copy button for the compact prompt`

### Task 6: 스냅숏과 화면 검토

**Files:**
- Modify: `Tools/ui-snapshots/main.swift`(frontend-components의 스냅숏 상태 4개, 가상 제목)

- [ ] **Step 1:** 상태 4개(`popover-large-sessions`, `popover-large-expiring`, `popover-large-many`, `popover-large-unpriced`)를 추가하고 `scripts/build-app.sh --snapshots` 뒤 영어·한국어로 렌더링한다.
- [ ] **Step 2: 검토 기준** — 360pt 폭에서 제목이 한 줄로 잘리고 툴팁이 있다. 버튼과 수치가 겹치지 않는다. 한국어 문구가 줄바꿈되어도 버튼이 보인다. 밝은·어두운 모드 대비가 기존과 같다.
- [ ] **Step 3:** better-interface로 스냅숏을 검토하고, HIGH가 남지 않을 때까지 고친다.
- [ ] **Step 4: 커밋** `test(ui): snapshot the large-session states`

### Task 7: 마무리

**Files:**
- Modify: `README.md`("What it does"에 한 줄: 큰 세션을 보여 주고 compact 프롬프트를 복사한다)
- Modify: waypoint Build Spec(§4 체크, §7 편차, 상태 IMPLEMENTED는 사용자 확인 뒤)

- [ ] **Step 1:** 엄격 빌드, `swift test`, `swift format lint --strict`, `python3 -I scripts/check-anti-goals.py`가 모두 통과한다.
- [ ] **Step 2:** `scripts/build-app.sh --release 0.2.0` 뒤 `scripts/check-binary.sh`가 통과한다.
- [ ] **Step 3:** README와 waypoint 기록을 커밋한다(문서는 waypoint에서 먼저 커밋·push한 뒤 포인터).

PR, 독립 리뷰, `v0.2.0` 릴리스, Homebrew 업그레이드와 사용자 확인은 이 계획 뒤에 2-5 문서의 "다음 단계"대로 한다.
