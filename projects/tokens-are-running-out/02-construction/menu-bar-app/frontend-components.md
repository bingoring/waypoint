---
artifact: frontend-components
build-spec: menu-bar-app
status: READY
updated: 2026-11-18
---

# Frontend Components — 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림

> 데이터 형태는 [domain-entities](domain-entities.md), 규칙은 [business-rules](business-rules.md), 흐름은 [business-logic-model](business-logic-model.md)을 따른다. 화면 요구 사항의 원본은 설계 입력 8.3(접근성, 레이아웃, 문구, 타이포그래피, 색, UI)이며, 여기서는 2-3에서 새로 정한 것만 적는다.

## 1. 컴포넌트 트리 (Hierarchy)
```
TokensAreRunningOutApp
├── MenuBarExtra(.window)
│   ├── MenuBarLabel                          — 아이콘 + 숫자, VoiceOver 이름
│   └── PopoverView (폭 360pt, 높이는 내용에 맞춤, 최대 화면 높이의 80%)
│       ├── StateBanner                       — indexing / noTranscripts / indexError / 형식 변화
│       ├── ExpiringSessionsSection           — 경고가 있을 때만
│       │   └── ExpiryWarningRow ×N
│       ├── BreakdownSection
│       │   ├── PeriodPicker                  — segmented Picker
│       │   ├── BreakdownSummary
│       │   └── BreakdownRow ×6 (+ OtherDisclosure의 세 하위 행)
│       ├── RebuildListSection
│       │   ├── ShowAllCausesToggle
│       │   └── RebuildRow ×N  ──(근거 보기)──▶ RebuildDetailPopover
│       └── FooterBar                         — 구분선 + Settings… + Quit
└── Settings
    └── SettingsView (Form, .formStyle(.grouped), 폭 460pt)
        ├── NotificationsSection
        ├── WarningsSection
        ├── RebuildsSection                   — 재구축 임계값
        ├── GeneralSection                    — 로그인할 때 열기
        └── AboutSection
```

## 2. 컴포넌트 상세

### `MenuBarLabel`
- **역할:** 메뉴 막대의 아이콘과 숫자(BR-E8).
- **props:** `warning: ExpiryWarning?`, `todayShare: Double?`
- **세부:** SF Symbol `hourglass` 하나만 쓴다(템플릿 이미지). 숫자는 `.monospacedDigit()`. 경고 상태에는 숫자 옆에 같은 기호를 유지하고 텍스트("8 min")로 상태를 알린다(색만으로 알리지 않음). `accessibilityLabel`은 §7의 문구.

### `ExpiryWarningRow`
- **props:** `warning: ExpiryWarning`, `showsAdvice: Bool`, `notificationsOn: Bool`, `now: Date`
- **세부:** 1행: 제목(한 줄, 잘리면 `.help`로 전체) + 오른쪽에 `clock` 기호와 남은 시간(시스템 주황, `.monospacedDigit()`). 2행(첫 경고만): 다음 행동 문장. 5분 TTL이고 알림이 켜져 있으면 "알림 없음" 이유 한 줄. `statusKnown == false`면 남은 시간 대신 "상태 확인 불가"와 `questionmark.circle`, `.help`로 이유.
- **갱신:** `TimelineView(.everyMinute)`. 접근성 알림을 따로 보내지 않는다.

### `PeriodPicker`
- `Picker("Period", selection:)` + `.pickerStyle(.segmented)` + `.labelsHidden()`(접근성 이름은 유지). 값: 5 hours / Today / 7 days.

### `BreakdownSummary`
- 그 기간의 총액과 호출 수, `idleRebuildShare` 문장. 임계값이 기본값이 아니면 한 줄 더(BR-U3).

### `BreakdownRow`
- **props:** `label`, `share: Double`, `cost: Int`, `note: String?`
- **세부:** 막대(`ProgressView(value:)`, `.tint(.secondary)`) + 레이블 + 정수 % + 금액. 텍스트로 값이 다 보이므로 막대는 접근성 트리에서 숨기고, 행 전체를 "레이블, %, 금액"으로 읽힌다. 짧은 휴식 행의 `note`("줄일 수 있었음")만 강조색. 다른 행에 색을 더하지 않는다.

### `OtherDisclosure`
- `DisclosureGroup("Other")`. 펼치면 세션 시작과 압축 / 모델 변경과 업데이트 / 원인 불명 세 행. 접힌 상태에서도 합계 %와 금액을 보인다.

### `RebuildRow`
- **props:** `event: RebuildEvent`
- **세부:** 시각(`.monospacedDigit()`) · 제목(한 줄, `.help`) / 2행: 원인 요약("62분 쉰 뒤", 긴 휴식이면 쉬기 시작할 때의 컨텍스트 크기) · 토큰 · 금액. 오른쪽에 `Button("Show Reason")` — 접근성 이름에 시각과 제목을 넣는다(§7).

### `RebuildDetailPopover`
- 원인 이름, 전체 제목, 시각, 근거 표(직전 호출 시각과 간격, 적용 TTL, 모델 변화, 버전 변화), 적용 규칙 한 문장, 비용(다시 쓴 토큰, 금액, 짧은 휴식이면 "이어서 했다면" 비용). Esc로 닫힌다(시스템 팝오버).

### `FooterBar`
- 하단 메뉴 위에만 `Divider`. `SettingsLink { Text("Settings…") }`(⌘,), `Button("Quit") { NSApp.terminate(nil) }`(⌘Q).

### `SettingsView`
| 구역 | 컨트롤 | 비고 |
|---|---|---|
| Notifications | `Toggle("Notify me before a cache expires")`, `Picker("Notify", 5/10/15/20 minutes before)` | 권한 거부면 상태 문장 + `Button("Open Notification Settings")`. 아래 설명: 5분 캐시 세션은 알리지 않음 |
| Warnings | `Picker("Warn about sessions with at least", 50K/100K/200K/500K tokens of context)` | |
| Cache rebuilds | `Picker("Count a call as a cache rebuild when it writes at least", 10K/20K/30K/50K/75K/100K tokens)` | 설명: 바꾸면 모든 기간을 다시 계산하고, 기본값(50K)이 기준값 대조와 같다 |
| General | `Toggle("Open at login")` | `requiresApproval`이면 안내 + `Button("Open Login Items Settings")` |
| About | 버전, 개인정보 문장, `Button("View Source on GitHub")` | 브라우저로 엶 |

## 3. 전역 · 공유 상태 (Shared State)

| 상태 | 소스 | 읽기/쓰기 컴포넌트 |
|---|---|---|
| `appState`, `todayReport`, `selectedReport`, `warnings`, `health`, `progress` | `AppModel`(`@Observable`, 메인 액터) | 읽기: 팝오버 전체, `MenuBarLabel` |
| `settings` | `AppModel` → `UserDefaults` | 읽기·쓰기: `SettingsView`, `PeriodPicker`, `ShowAllCausesToggle` |
| 알림 권한, 로그인 항목 상태 | `AppModel`(시스템에서 읽음) | `SettingsView` |

## 4. 화면 상태 (Screen States)

| 상태 | 트리거 | UI |
|---|---|---|
| 첫 색인(loading) | 색인이 비어 있음 | `StateBanner`: 진행 문장 + `ProgressView(value:)`. 다른 구역은 숨김 |
| 기록 없음(empty) | `~/.claude/projects` 없음 | `StateBanner`: 기록 없음 문장. 다른 구역 숨김 |
| 색인 오류(error) | 열기·쓰기 실패 | `StateBanner`: 원인과 복구 문장 + `Button("Try Again")` |
| 형식 변화(warning) | BR-H1 | `ready` 위에 `StateBanner`: 문장 + `Button("Open Releases Page")` |
| 정상(success) | `ready` | 경고 구역(있을 때), 원인 분해, 재구축 목록 |
| 기간에 사용 없음 | 총액 0 | 원인 행 대신 빈 상태 문장 |
| 재구축 없음 | 목록 비어 있음 | 빈 상태 문장(+ 모든 원인 보기 안내) |
| 계산 중 | 기간·임계값을 바꾼 직후 | 직전 값 유지 + 작은 `ProgressView()`(인디케이터) |

## 5. 상호작용 · 네비게이션
- 모든 조작은 키보드로 한다. Tab 순서: 기간 선택 → Other 펼침 → 모든 원인 보기 → 각 행의 근거 보기 → Settings… → Quit. Esc는 열린 근거 팝오버, 그다음 팝오버 자체를 닫는다.
- 팝오버를 열 때 등장 애니메이션이 없다. 막대가 차오르는 애니메이션도 없다. 시스템 "동작 줄이기"를 따른다(새 애니메이션이 없으므로 따로 할 일 없음).
- 목록이 길면 `ScrollView` 안에서 스크롤하고, 마지막으로 보이는 행이 16 ~ 32pt 걸쳐 보이도록 최대 높이를 정한다.
- 간격: 그룹 안 8pt, 그룹 사이 16pt, 바깥 여백 16pt. 구분선은 `FooterBar` 위에만.

## 6. 디자인 SoT 매핑 (디자인 요소 → 컴포넌트)

| SoT 디자인 요소 | 컴포넌트 | 데이터/props |
|---|---|---|
| design 8.1 메뉴 막대 표시 | `MenuBarLabel` | BR-E8 |
| design 8.1 곧 캐시가 만료되는 세션 | `ExpiringSessionsSection`, `ExpiryWarningRow` | `ExpiryWarning` |
| design 8.1 사용량의 원인 | `BreakdownSection` | `UsageReport.bucketCosts` → BR-U1 |
| design 8.1 "이 중 5% 줄일 수 있었음" | `BreakdownRow.note` | `UsageReport.reducibleShare` |
| design 8.1 비용이 컸던 캐시 재구축 | `RebuildListSection`, `RebuildRow` | `UsageReport.rebuilds`, BR-U4 |
| design 8.1 분류 근거 보기 | `RebuildDetailPopover` | `RebuildEvent` |
| design 8.1 설정 창 | `SettingsView` | `AppSettings` |
| design 8.2 상태별 화면 | `StateBanner`, 빈 상태 | `AppState`, `IndexHealth` |
| DECISIONS 2026-11-18 advisor 별도 항목 | `BreakdownRow`(Advisor) | `CostBucket.advisor` |

## 7. 문구 (String Catalog, 영어 기본 · 한국어)

> 문장은 조각으로 잇지 않고 자리 표시자가 있는 한 문장으로 둔다. 복수형은 String Catalog의 plural, 숫자·금액·시각은 `FormatStyle`(BR-U5). 용어는 "cache rebuild / 캐시 재구축", "could have saved / 줄일 수 있었던"으로 통일하고 "waste / 낭비"는 쓰지 않는다.

| 위치 | 영어 | 한국어 |
|---|---|---|
| 메뉴 막대 VoiceOver(평소) | Tokens Are Running Out: %@ of today's cost went to rebuilding caches after a break | Tokens Are Running Out: 오늘 비용의 %@가 쉬었다 돌아온 캐시 재구축에 쓰였습니다 |
| 메뉴 막대 VoiceOver(경고) | Tokens Are Running Out: a session's cache expires in %lld minutes | Tokens Are Running Out: %lld분 뒤 캐시가 만료되는 세션이 있습니다 |
| 메뉴 막대 VoiceOver(오늘 사용 없음) | Tokens Are Running Out: no usage today | Tokens Are Running Out: 오늘 사용 기록 없음 |
| 경고 구역 제목 | Caches expiring soon | 곧 캐시가 만료되는 세션 |
| 남은 시간 | %lld min left / Less than a minute left | %lld분 남음 / 1분 미만 남음 |
| 다음 행동 | To continue without a rebuild, send a message within %lld minutes. After that, the next message rebuilds the cache from %@ tokens (about %@). | 캐시를 다시 만들지 않고 이어 가려면 %lld분 안에 메시지를 보내세요. 그 뒤에는 다음 메시지가 %@ 토큰으로 캐시를 다시 만듭니다(약 %@). |
| 5분 캐시 | No notification: this session uses a 5-minute cache. | 이 세션은 5분 캐시를 써서 알림을 보내지 않습니다. |
| 상태 확인 불가 | Status unknown | 상태 확인 불가 |
| 상태 확인 불가 도움말 | Claude Code's running-session files can't be read, so this session may already be busy. | Claude Code의 실행 세션 파일을 읽을 수 없어, 이 세션이 이미 작업 중일 수도 있습니다. |
| 원인 구역 제목 | What used your tokens | 사용량의 원인 |
| 기간 | 5 hours · Today · 7 days | 5시간 · 오늘 · 7일 |
| 요약 1 | %@ at API list prices · %lld calls | API 정가 환산 %@ · 호출 %lld건 |
| 요약 2 | %@ went to rebuilding caches after a break. | %@가 쉬었다 돌아온 캐시 재구축에 쓰였습니다. |
| 요약 3(임계값 변경) | Counting cache rebuilds of %@ tokens or more (changed in Settings). | %@ 토큰 이상을 캐시 재구축으로 셉니다(설정에서 바꿈). |
| 원인 행 | Normal work · Cache rebuilt after a short break · Cache rebuilt after a long break · Subagents · Advisor · Other | 일반 작업 · 짧은 휴식 후 캐시 재구축 · 긴 휴식 후 캐시 재구축 · 서브에이전트 · Advisor · 기타 |
| 기타 하위 | Session start and compaction · Model change and update · Unknown cause | 세션 시작과 압축 · 모델 변경과 업데이트 · 원인 불명 |
| 줄일 수 있었던 양 | %@ could have been saved by continuing before the cache expired | 캐시가 만료되기 전에 이어 갔다면 %@ 줄일 수 있었습니다 |
| 사용 없음 | No usage in this period. | 이 기간에는 사용 기록이 없습니다. |
| 목록 제목 | Expensive cache rebuilds | 비용이 컸던 캐시 재구축 |
| 모든 원인 토글 | Show all causes | 모든 원인 보기 |
| 행 요약(짧은 휴식) | After %@ away · %@ tokens · %@ | %@ 쉰 뒤 · %@ 토큰 · %@ |
| 행 요약(긴 휴식) | After %@ away · context %@ tokens · %@ | %@ 쉰 뒤 · 컨텍스트 %@ 토큰 · %@ |
| 근거 버튼 | Show Reason | 근거 보기 |
| 근거 버튼 VoiceOver | Show the reason for the %@ rebuild in %@ | %@ %@ 세션의 재구축 근거 보기 |
| 재구축 없음 | No caches were rebuilt after a break in this period. | 이 기간에는 쉬었다 돌아온 캐시 재구축이 없었습니다. |
| 재구축 없음(보충) | Turn on Show all causes to see other rebuilds. | 다른 원인의 재구축은 "모든 원인 보기"를 켜면 보입니다. |
| 첫 색인 | Reading Claude Code history… %@ of %@ | Claude Code 기록을 읽는 중입니다… %@ / %@ |
| 기록 없음 | No Claude Code history found. Use Claude Code once, and your usage will appear here. | Claude Code 기록을 찾지 못했습니다. Claude Code를 한 번 쓰면 이곳에 사용량이 표시됩니다. |
| 색인 오류 | Unable to read the usage index. Check that your disk has free space, then try again. | 사용량 색인을 읽지 못했습니다. 디스크에 남은 공간이 있는지 확인한 뒤 다시 시도하세요. |
| 형식 변화 | Claude Code's history format may have changed: %@ of recent lines couldn't be read, so numbers may be low. Update Tokens Are Running Out to the latest version. | Claude Code 기록 형식이 바뀐 것 같습니다. 최근 줄의 %@를 읽지 못해 숫자가 실제보다 작을 수 있습니다. Tokens Are Running Out을 최신 버전으로 업데이트하세요. |
| 버튼 | Try Again · Open Releases Page · Settings… · Quit | 다시 시도 · 릴리스 페이지 열기 · 설정… · 종료 |
| 알림 제목 | Cache expires in %lld minutes | %lld분 뒤 캐시가 만료됩니다 |
| 알림 본문 | %@: send a message to keep the cache. Otherwise the next message rebuilds it from %@ tokens (about %@). | %@: 메시지를 보내면 캐시가 유지됩니다. 그렇지 않으면 다음 메시지가 %@ 토큰으로 캐시를 다시 만듭니다(약 %@). |
| 설정: 알림 권한 거부 | Notifications for Tokens Are Running Out are turned off in System Settings. | 시스템 설정에서 Tokens Are Running Out의 알림이 꺼져 있습니다. |
| 설정: 버튼 | Open Notification Settings · Open Login Items Settings · View Source on GitHub | 알림 설정 열기 · 로그인 항목 설정 열기 · GitHub에서 소스 보기 |
| 설정: 임계값 설명 | Changing this recalculates every period. The default, 50K, matches the project's reference results. | 바꾸면 모든 기간을 다시 계산합니다. 기본값 5만은 프로젝트의 기준값과 같습니다. |
| 설정: 개인정보 | Reads Claude Code's history without changing it and sends nothing over the network. | Claude Code 기록을 바꾸지 않고 읽기만 하며, 네트워크로 아무것도 보내지 않습니다. |

## 8. 구현 전 디자인 검토 (better-interface, 2026-11-18)

**범위:** 설계 입력 8.1 ~ 8.3의 시안과 이 문서 §1 ~ §7의 2-3 확장(상태 화면, 근거 팝오버, 설정 창, 알림 문구). 구현된 화면이 없는 텍스트 시안 검토다. 스택은 SwiftUI(`MenuBarExtra`, `Form`), 시스템 텍스트 스타일과 시스템 의미 색을 쓴다. 프로젝트의 화면 규약 문서는 설계 입력 8.3과 저장소 `CLAUDE.md`(디자인 스킬 사용)다.

| 영역 | 검토한 근거 | 결과 |
|---|---|---|
| Accessibility | 메뉴 막대 이름, 반복 버튼 이름, 키보드 경로, 자동 갱신, 막대의 접근성 | 2건(반영함) |
| Layout | 묶음 간격, 잘린 제목, 숨은 내용(기타), 스크롤 단서, 긴 문자열 | 1건(반영함) |
| Writing | 상태별 문구, 오류 복구, 용어, 토글 이름, 메뉴 막대 숫자의 뜻 | 4건(반영함) |
| Typography | 바뀌는 숫자, 글자 크기 단계, 굵기 | 1건(반영함) |
| Colors | 시스템 색, 주황 경고, 강조색 한 곳, 빨간색 금지, advisor 행 | Clear |
| UI | 애니메이션, SF Symbols 하나, 상태 변화의 흔적 | Clear |

| 심각도 | 영역 | 위치 | 이전 | 이후 | 이유 |
|---|---|---|---|---|---|
| HIGH | Writing | 색인 오류 상태 | 정의되지 않음 | 원인·복구 문장 + "다시 시도"(§4, §7) | 복구 방법이 없는 오류(즉시 HIGH) |
| HIGH | Writing | 설정: 알림 권한 거부 | 정의되지 않음. 토글이 켜져 있어도 알림이 오지 않음 | 상태 문장 + "알림 설정 열기"(BR-N4) | 사용자를 오도함 |
| HIGH | Layout | 원인 분해의 "기타" | 세 원인을 합쳐 보여 주고 내역을 볼 방법이 없음 | `DisclosureGroup`로 세 하위 행(BR-U1) | 내용에 닿을 방법이 없음 |
| MEDIUM | Accessibility | 재구축 행의 "근거 보기" | 모든 행이 같은 이름 | VoiceOver 이름에 시각과 제목(§7) | 목록에서 버튼 목적을 구분할 수 없음(WCAG 2.4.6) |
| MEDIUM | Writing | 메뉴 막대 숫자 | 눈으로 보는 사용자에게 뜻 설명이 없음 | 원인 구역 요약 2에 같은 숫자의 뜻(BR-U3) | 숫자의 의미를 알 수 없음 |
| MEDIUM | Writing | 재구축 임계값을 바꾼 상태 | 표시 없음 | 요약 3(BR-U3) | 바뀐 기준을 모른 채 숫자를 비교하게 됨 |
| MEDIUM | Writing | 상태 확인 불가 | 문구 없음 | 레이블 + 도움말(§7) | 경고를 믿어도 되는지 알 수 없음 |
| MEDIUM | Accessibility | 원인 막대 | 막대와 텍스트가 따로 읽힘 | 막대는 숨기고 행을 한 요소로 읽음(§2) | 같은 값을 두 번 읽음 |
| LOW | Typography | 금액·호출 수 | `.monospacedDigit()` 대상이 남은 시간·%뿐 | 바뀌는 모든 숫자로 넓힘 | 갱신할 때 폭이 흔들림 |

**검증:** 화면 밖 `NSHostingView` 렌더링 시험(2026-11-18)에서 segmented `Picker`, `ProgressView`, `Toggle`, `Button`이 밝은·어두운 모드 모두 정상으로 그려지는 것만 확인했다. 그 밖의 렌더링, 대비 측정, VoiceOver 읽기, 키보드 이동은 **Not verified**다. 구현 뒤 `ui-snapshots`의 PNG로 다시 검토하고, VoiceOver·키보드·알림 수신은 사용자 기기에서 확인한다.

**판정:** `Approve`(구현 착수). 위 HIGH 3건은 이 명세에 반영했다. 구현 뒤 실제 화면 검토에서 HIGH가 남으면 출시하지 않는다(설계 8.4 규칙).
