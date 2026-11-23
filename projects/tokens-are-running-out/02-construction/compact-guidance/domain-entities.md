# Domain Entities — 큰 세션 정리 안내

> Build Spec [`build-spec-index.md`](build-spec-index.md)의 아티팩트. 금액 단위는 기존과 같이 nano-USD(`Int`)다.

## `LargeSession` (RunningOutCore, 신규)

| 필드 | 타입 | 뜻 |
|---|---|---|
| `sessionID` | `String` | 세션 ID |
| `title` | `String?` | 세션 제목, 없으면 레지스트리의 이름, 없으면 작업 폴더 이름. 만료 경고와 같은 규칙 |
| `contextTokens` | `Int` | 마지막 메인 호출의 입력 + 캐시 읽기 + 캐시 쓰기 토큰 |
| `readCost` | `Int` | 호출 한 번이 컨텍스트를 캐시에서 다시 읽는 정가 비용: `contextTokens × 캐시 읽기 단가`. 단가는 `PriceTable.lookup(model:promptTokens:)`로, 장문 구간이 있으면 그 구간을 쓴다 |
| `model` | `String` | 마지막 호출의 모델 |
| `priced` | `Bool` | 가격표에 있는 모델이면 true. 없으면 대체 모델 가격으로 계산했다는 뜻 |
| `status` | `LargeSession.Status` | `.running`(레지스트리에서 찾음), `.unreadable`(레지스트리를 읽을 수 없어 최근 호출로 추정) |

`Sendable`, `Equatable`.

## `LargeSessionFinder` (RunningOutCore, 신규)

```swift
public enum LargeSessionFinder {
    public static let defaultThresholdTokens = 200_000
    /// Largest context first, then by session ID.
    public static func sessions(
        registry: RegistryState, now: Double, thresholdTokens: Int, prices: PriceTable,
        lastCall: (String) throws -> LastCall?, sessionsWithCallsSince: (Double) throws -> [String]
    ) throws -> [LargeSession]
}
```
- `ExpiryCalculator.warnings`와 같은 모양의 의존성을 받는다. 그래서 같은 가짜 구현으로 시험할 수 있다.

## `IndexService` / `IndexServing` (기존 확장)

```swift
func largeSessions(registry: RegistryState, now: Double, thresholdTokens: Int) async throws -> [LargeSession]
```

## `AppModel` (기존 확장)

| 추가 | 뜻 |
|---|---|
| `public internal(set) var largeSessions: [LargeSession] = []` | 경고와 같은 시점에 갱신 |
| `public func copyCompactPrompt() -> Bool` | `CompactPrompt.text`를 클립보드에 쓰고, 성공 여부를 돌려준다. 실패하면 화면은 "복사됨"을 보이지 않는다 |
| 생성자 인자 `pasteboard: PasteboardWriting` | 기본값은 `SystemPasteboard()` |

## `PasteboardWriting` (RunningOutUI, 신규)

```swift
@MainActor public protocol PasteboardWriting: AnyObject { func write(_ text: String) -> Bool }
public final class SystemPasteboard: PasteboardWriting  // NSPasteboard.general: clearContents, then setString(.string)'s result
```

## `CompactPrompt`

`enum CompactPrompt { static var text: String }`. 앱 언어(`Bundle.module`의 현재 지역화)로 고른 문자열 하나다. 모든 문구를 `Localizable.xcstrings`에 두는 규칙에 따라, 키 하나(영어 원문)와 한국어 번역으로 둔다. 줄바꿈을 그대로 보존한다.

**한국어(시험한 A2, 글자 단위로 이대로):**
```text
/compact 이 대화를 다시 읽지 않고도 작업을 이어 갈 수 있게 요약해 줘. 다음은 정확히 남겨:
1. 목표: 사용자가 요청한 것과 완료 기준, 사용자의 표현 그대로.
2. 사용자 지시: 사용자가 직접 입력한 메시지에 나온 규칙, 제약, 선호만. 시스템 지시, 도구 규칙, CLAUDE.md 내용은 넣지 마.
3. 결정: 결정마다 이유, 버린 대안과 버린 이유.
4. 파일: 이어서 작업하는 데 필요한 파일을 저장소 루트 기준 경로로, 상태(완료, 일부, 다시 볼 것)와 함께.
5. 현재 상태: 브랜치, 커밋, push 여부, 실행 중인 것, 마지막으로 끝낸 단계.
6. 열린 문제: 아직 풀리지 않은 오류(메시지 원문)와, 지적했지만 아직 고치지 않은 문제.
7. 남은 작업: 아직 하지 않은 일 전체 목록과, 그중 바로 할 다음 행동.
도구 출력 원문, 다시 읽으면 되는 파일 내용, 바뀐 계획, 긴 코드, 이메일이나 계정 ID 같은 식별자는 넣지 마. 실패한 접근은 다시 시도하지 않게 한 줄씩만 남겨.
사용자가 쓰던 언어로 써.
```

**영어(번역, 시험하지 않음):**
```text
/compact Summarize this conversation so the work can continue without rereading it. Keep these exactly:
1. Goal: what the user asked for and what "done" means, in the user's words.
2. User instructions: only the rules, constraints and preferences in messages the user typed. Leave out system instructions, tool rules and CLAUDE.md content.
3. Decisions: the reason for each, and the alternatives rejected and why.
4. Files: the files needed to continue, with paths from the repository root and their state (done, partly done, to revisit).
5. Current state: branch, commits, whether they are pushed, anything running, and the last step finished.
6. Open problems: unresolved errors (exact message) and problems pointed out but not yet fixed.
7. Remaining work: everything not yet done, and which of it is the immediate next action.
Leave out raw tool output, file contents that can be reread, superseded plans, long code, and identifiers such as emails or account IDs. Keep one line per failed approach so it is not retried.
Write in the language the user has been using.
```

## `LastCall` (기존 확장)

| 추가 필드 | 타입 | 뜻 |
|---|---|---|
| `compactedAfter` | `Bool` | 같은 메인 기록에서 이 호출보다 뒤(`seq`가 큰)에 compact 표시가 있으면 true. `marks` 표에서 읽는다 |

## 기존 엔티티와의 관계
- `ExpiryWarning`의 모양은 바꾸지 않는다. 다만 `compactedAfter`인 세션은 만들지 않는다(BR-C18). ② 안내 줄은 화면에서 `warning.contextTokens >= LargeSessionFinder.defaultThresholdTokens`로 판단한다.
- 기준값은 `AppSettings`에 넣지 않는다. 고정값이고, 3-2에서 다시 본다.
