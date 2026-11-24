---
build-spec: compact-guidance
stage: 02-construction/05-compact-guidance
status: IMPLEMENTED
depth: standard
updated: 2026-11-24
---

# Build Spec — 큰 세션 정리 안내

## §0. 개요 & 범위
- **목표(한 줄):** 실행 중인 큰 세션을 팝오버에 보여 주고, 사용자가 그 세션에 붙여 넣을 `/compact` 프롬프트를 복사하게 한다. 곧 만료되는 큰 세션에는 "떠나기 전에 정리"를 안내한다.
- **SoT:**
  - [`../05-compact-guidance.md`](../05-compact-guidance.md)의 AI 제안(범위, 지키는 선, 시험한 프롬프트)과 승인 결과
  - 2-3 Build Spec: [`../menu-bar-app/frontend-components.md`](../menu-bar-app/frontend-components.md)(팝오버 구조, 문구 규칙), [`../menu-bar-app/business-rules.md`](../menu-bar-app/business-rules.md)(만료 경고 BR-E)
  - 시험한 프롬프트: [domain-entities `CompactPrompt`](domain-entities.md#compactprompt)
- **규모/제약:**
  - 앱 코드만 바꾼다. 릴리스 파이프라인은 바꾸지 않는다.
  - 새로 읽는 데이터는 없다. 만료 경고가 이미 쓰는 "세션의 마지막 호출"(`LastCall`)과 실행 중인 세션 목록만 쓴다.
- **깊이 티어 & 사유:** `standard`. 화면 하나와 규칙 몇 가지이고, 흐름은 기존 경고 갱신에 붙는다.

## §1. 분해

| 단위 | 책임 | 의존 | 신규/기존 |
|---|---|---|---|
| `LastCall.compactedAfter`, `Indexer.lastCall`, `ExpiryCalculator`(RunningOutCore) | 마지막 호출 뒤 compact 여부. 만료 경고에서 그 세션을 뺀다(2-3 계약 확장) | `marks` 표(이미 색인됨) | 기존 수정 |
| `LargeSession`, `LargeSessionFinder`(RunningOutCore) | 실행 중인 세션 중 큰 세션을 골라 크기와 호출당 다시 읽는 비용을 계산 | `RegistryState`, `LastCall`, `PriceTable` | 신규 |
| `IndexService.largeSessions(...)`, `IndexServing` | 앱에서 부르는 진입점 | `Indexer.lastCall`, `mainSessions(withCallsSince:)` | 기존 확장 |
| `AppModel.largeSessions`, `copyCompactPrompt()` | 경고와 같은 시점에 갱신, 복사 동작 | `IndexServing`, `PasteboardWriting` | 기존 확장 |
| `PasteboardWriting`, `SystemPasteboard`(RunningOutUI) | 클립보드 쓰기. 시험에서 바꿔 끼운다 | `NSPasteboard` | 신규 |
| `CompactPrompt`(RunningOutUI) | 앱 언어의 프롬프트 문자열 | `Localizable.xcstrings` | 신규 |
| `LargeSessionsSection`, `LargeSessionRow`, `CopyCompactPromptButton` | ① 큰 세션 영역 | 위 모델 | 신규 |
| `ExpiryWarningRow` | ② 안내 줄에 "떠나기 전에 정리"와 복사 버튼 | `CopyCompactPromptButton` | 기존 수정 |
| `Tools/ui-snapshots` | 새 상태의 스냅숏 | 미리보기 데이터 | 기존 수정 |

### 흐름 (business-logic-model 인라인)
1. **갱신:** `AppModel.refreshWarnings()`가 레지스트리를 한 번 읽는다(`registry.load()`). 그 상태로 `expiryWarnings`와 `largeSessions`를 차례로 부르고, 두 결과를 함께 바꾼다. 따라서 큰 세션 목록은 경고와 같은 때(세션 파일 변경, 기록 변경, 팝오버 열기, 시계 틱)에 갱신된다.
2. **고르기:** `LargeSessionFinder.sessions(...)`
   - 레지스트리를 읽을 수 있으면, 실행 중인 모든 세션을 상태와 무관하게 세션 ID로 하나씩만 남긴다. 작업 중인 세션도 포함한다.
   - 레지스트리를 읽을 수 없으면, 최근 1시간 안에 호출이 있는 메인 세션을 쓴다. 만료 경고와 같은 대체 경로다.
   - 각 세션의 `LastCall`을 읽고, `contextTokens >= 200_000`인 것만 남긴다.
   - 컨텍스트가 큰 순서로 정렬하고, 같으면 세션 ID 순서로 정렬한다.
3. **복사:** 버튼을 누르면 `AppModel.copyCompactPrompt()`가 `CompactPrompt.text`를 클립보드에 쓴다. 버튼은 2초 동안 "복사됨"을 보이고, VoiceOver에 복사되었다고 알린다.
4. **안내 줄:** 만료 경고의 첫 줄(안내 문장이 붙는 줄)이 상태 `.idle`이고 `contextTokens`가 기준 이상이면, 그 아래에 "떠나기 전에 정리" 문장과 복사 버튼을 붙인다.
5. **compact 뒤:** `Indexer.lastCall`이 마지막 호출 뒤에 compact 표시가 있는지 함께 돌려준다(`LastCall.compactedAfter`). 그 세션은 큰 세션 목록과 만료 경고에서 모두 빠진다(BR-C17, BR-C18).

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 / N/A 사유 |
|---|---|---|
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | N/A | 흐름이 짧아 위 §1 "흐름"에 인라인으로 적었다 |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문
- 없음. 기준값, 위치, 프롬프트, 버전은 2-5 검토 게이트에서 승인되었다(2026-11-23).

## §4. 구현 체크리스트
- [x] **붙여 넣기 확인:** 2026-11-23에 사용자와 함께 했다. 여러 줄은 일반 메시지로 처리되어 BR-C20의 한 줄 형식으로 바꿨고, 영어판은 길이 제한 때문에 582자로 줄였다(§7)
- [x] `LastCall.compactedAfter`와 `ExpiryCalculator`의 제외 규칙, 테스트(compact 뒤 경고 없음, 다음 호출 뒤 다시 판단)
- [x] `LargeSession`, `LargeSessionFinder`와 단위 테스트(기준 경계, 작업 중인 세션 포함, 중복 세션, 레지스트리 없음, 가격 없는 모델, 정렬)
- [x] `IndexService.largeSessions`와 `IndexServing` 확장, 시험용 가짜 구현 갱신
- [x] `PasteboardWriting`, `SystemPasteboard`, `AppModel.largeSessions`·`copyCompactPrompt()`와 테스트(갱신 시점, 복사 내용)
- [x] `CompactPrompt`와 문구: 한국어가 시험한 A2와 글자 단위로 같은지 확인하는 테스트
- [x] `LargeSessionsSection`, `LargeSessionRow`, `CopyCompactPromptButton`
- [x] `ExpiryWarningRow`의 안내 줄 확장
- [x] `Localizable.xcstrings` 영어·한국어
- [x] 미리보기 데이터와 스냅숏(큰 세션 있음, 큰 세션이 만료 직전, 큰 세션 6개 이상, 한·영, 밝은·어두운 모드)
- [x] better-interface 검토와 반영
- [x] README의 "What it does"에 한 줄 추가

## §5. 검증 계획
- [x] `swift build --build-tests -Xswiftc -warnings-as-errors` 경고 0건, `swift test`, `swift format lint --strict`
- [x] `scripts/check-anti-goals.py`(네트워크 없음, 쓰기는 색인뿐), 릴리스 빌드의 `check-binary.sh`
- [x] PR 브랜치에 base merge 커밋 없음
- [x] 단위 테스트: `LargeSessionFinderTests`, `CompactPromptTests`, `AppModel` 갱신·복사 테스트
- [x] 스냅숏 검토: 문구 잘림 없음, 360pt 폭, 큰 글씨에서도 버튼이 보임
- [x] 실제 앱(사용자 기기, `v0.2.1` 설치 뒤, 2026-11-24): 큰 세션 영역, 복사와 2초 동안의 "복사됨", 복사된 한 줄 프롬프트, VoiceOver 이름과 알림, 키보드 이동을 사용자가 확인했다. 붙여 넣은 프롬프트의 `/compact` 실행은 대화형 터미널에서 확인했다(2026-11-23). 데스크톱 앱에 붙여 넣는 경우와, compact 뒤 목록에서 빠지는 동작은 기기에서 확인하지 않았다(후자는 단위 테스트로 확인)
- [x] 독립 리뷰(작성 맥락이 없는 리뷰어)

## §6. NFR · 성능
N/A(standard). 참고: 레지스트리의 세션 수만큼 `lastCall`을 한 번씩 더 조회한다. 만료 경고가 이미 같은 조회를 하므로, 결과를 나눠 쓰지 않아도 실행 중인 세션 수(보통 10개 미만)만큼의 색인 조회가 늘 뿐이다.

## §7. 편차 로그
| SoT | 실제 구현 | 사유 |
|---|---|---|
| frontend-components ①: 수치 줄과 바닥 문구를 `.secondary`로 | 기본 글자색 | 화면 검토에서 밝은 모드 대비가 3.10:1로 측정되어 4.5:1에 못 미쳤다. 기본색으로 12.49:1(어두운 모드 11.55:1). 기존 화면도 글자는 모두 기본색이다 |
| frontend-components ②: 줄의 접근성을 `.contain`으로 바꾸고 요약 레이블 | 기존 줄은 그대로 묶고, 안내 문장과 버튼만 묶음 밖에 둔다 | 기존 VoiceOver 읽기를 유지하면서 버튼이 따로 초점을 받는다. 읽는 순서는 기기 확인에서 본다 |
| frontend-components ①: 상태 확인 불가 아이콘의 툴팁을 만료 경고와 같이 | 새 문구 "…이 세션은 이미 끝났을 수도 있습니다" | 만료 경고의 "이미 작업 중일 수도"는 큰 세션에 맞지 않는다 |
| §4 첫 항목: 붙여 넣기 확인을 구현 전에, 프롬프트는 여러 줄 | 구현 뒤 확인. 여러 줄은 대화형 세션에서 일반 메시지로 처리되어(compact 없음) 한 줄로 바꿨다. 한 줄 한국어(527자)와 한 줄 영어(582자)는 `/compact`로 실행되었고, 한 줄 영어 1,070자는 일반 메시지가 되었다. 그래서 영어판을 7개 항목을 유지한 채 582자로 줄이고, "600자 이하" 테스트를 더했다 | 붙여 넣은 `/compact`는 한 줄이고 일정 길이 이하일 때만 명령으로 실행된다(2026-11-23 확인). 한국어판 단어는 그대로다 |
| 구현 계획 작업 5의 수동 실행 확인 | `v0.2.0` 설치 뒤 사용자 기기에서 | Homebrew 설치본이 실행 중이라, 같은 번들 ID의 사본을 띄우면 3-1에서 찾은 "사본 두 개" 문제를 다시 만든다 |
| README 스크린숏: 2-5 범위 밖 | 큰 세션이 보이는 상태(`popover-large-expiring`)로 교체 | 새 기능을 소개 글과 README에서 보이기 위해. 값은 모두 스냅숏 도구의 가상 값 |
| 범위 밖 | `scripts/check-strings.py`가 Xcode 27의 빌드 폴더 이름(`RunningOutUI-t.build`)도 찾는다 | 옛 이름만 찾아 오래된 Debug 빌드를 읽고 있었다 |
| §5 실제 앱 확인: `v0.2.0` 설치 뒤 | `v0.2.1` 설치 뒤 | `v0.2.0`에서 팝오버 내용이 사라지는 회귀가 있었다. 스크롤 영역이 메뉴 막대 창의 작은 높이 제안을 그대로 받았기 때문이다. 스크롤 영역을 내용 높이로 고정하고(`fixedSize`) 최대 높이에서만 멈추게 고쳤다. 작은 제안 높이를 재현하는 테스트를 더했다 |
| 2-3 frontend-components §1 "최대 화면 높이의 80%"(강제하는 코드 없었음) | 내용은 스크롤 영역에 넣고, 팝오버 높이를 화면 높이의 80%로 제한한다. 설정·종료 버튼은 고정. 스냅숏은 제한 없이 그리고 `popover-capped`(700pt)를 더했다 | 브랜치 리뷰에서 지적: 이번 기능으로 팝오버가 1,125pt까지 길어져 14인치 화면에서 버튼이 밀릴 수 있었다 |
