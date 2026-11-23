# Frontend Components — 큰 세션 정리 안내

> Build Spec [`build-spec-index.md`](build-spec-index.md)의 아티팩트. 2-3의 [frontend-components](../menu-bar-app/frontend-components.md) 규칙(360pt 팝오버, 한 줄 제목과 툴팁, `monospacedDigit`, 문구는 모두 `Localizable.xcstrings`)을 그대로 따른다.

## 팝오버 순서
1. 상태 배너(색인 중, 형식 변화)
2. 곧 캐시가 만료되는 세션 → ② 안내 줄 확장
3. **큰 세션(신규)**
4. 사용량의 원인
5. 비용이 컸던 캐시 재구축

## ① `LargeSessionsSection`

```text
큰 세션
Refactor parser                                         [정리 프롬프트 복사]
컨텍스트 620K · 호출마다 다시 읽는 비용 약 $0.12
Write release notes for the next version…               [정리 프롬프트 복사]
컨텍스트 240K · 호출마다 다시 읽는 비용 약 $0.05
세션에 붙여 넣고 Return을 누르세요. 작업이 끝난 시점에 하면 요약이 가장 깔끔합니다.
```

| 요소 | 내용 |
|---|---|
| 제목 | `Large sessions` / `큰 세션`, `.body.weight(.semibold)`(다른 영역 제목과 같다) |
| `LargeSessionRow` | 1행: `SessionTitle`(기존, 한 줄, 툴팁), 오른쪽에 `CopyCompactPromptButton`. 2행: 수치, `.callout`, `.secondary`, `monospacedDigit` |
| 수치 문구 | 가격 있음: `Context %@ · re-reads about %@ per call` / `컨텍스트 %@ · 호출마다 다시 읽는 비용 약 %@`. 가격 없음: `Context %@ · re-reads an estimated %@ per call` / `컨텍스트 %@ · 호출마다 다시 읽는 비용 추정 %@` |
| 상태 `.unreadable` | 2행 끝에 기존 "상태 알 수 없음" 아이콘과 툴팁을 재사용한다 |
| 넘침 | 5개를 넘으면 `%lld more sessions` / `세션 %lld개 더 있음`(기존 문구 재사용) |
| 바닥 문구 | `Paste it into the session and press Return. It works best when a task is done.` / `세션에 붙여 넣고 Return을 누르세요. 작업이 끝난 시점에 하면 요약이 가장 깔끔합니다.` `.callout`, `.secondary` |

## ② `ExpiryWarningRow` 확장
기존 안내 문장(`showsAdvice`) 아래, BR-C14 조건일 때만 붙인다.

```text
Refactor parser                                                ⏱ 8분 남음
8분 안에 메시지를 보내면 재구축 없이 이어 갑니다. 이후에는 620K 토큰에서 캐시를 다시 만듭니다(약 $4.96).
떠나기 전에 정리해 두면, 돌아와서 다시 만드는 것은 요약뿐입니다.   [정리 프롬프트 복사]
```

| 요소 | 내용 |
|---|---|
| 문장 | `Compact it before you leave, and only the summary is rebuilt when you come back.` / `떠나기 전에 정리해 두면, 돌아와서 다시 만드는 것은 요약뿐입니다.` `.callout` |
| 버튼 | `CopyCompactPromptButton`(①과 같은 것) |
| 접근성 | 기존 줄은 `.accessibilityElement(children: .combine)`이다. 버튼이 합쳐져 사라지지 않도록, 버튼은 따로 초점을 받게 한다(`.contain`으로 바꾸고 줄 요약 레이블을 둔다) |

## `CopyCompactPromptButton`

| 항목 | 내용 |
|---|---|
| 모양 | `.bordered`, `.controlSize(.small)`. 팝오버의 다른 작은 버튼과 같다 |
| 레이블 | 기본: `Copy compact prompt` / `정리 프롬프트 복사`. 누른 뒤 2초: `Copied` / `복사됨`, 아이콘 `checkmark` |
| 접근성 이름 | `Copy compact prompt for %@` / `%@ 세션의 정리 프롬프트 복사`(세션 제목, 없으면 "제목 없는 세션") |
| 동작 | `model.copyCompactPrompt()` → 상태 `copied = true` → 2초 뒤 false. VoiceOver 알림: `Compact prompt copied` / `정리 프롬프트를 복사했습니다` |
| 움직임 | 레이블 교체만 한다. 애니메이션은 쓰지 않는다(빈번한 상호작용). |
| 도움말(툴팁) | `Copies a /compact command that keeps the goal, decisions, files, state and remaining work.` / `목표, 결정, 파일, 상태, 남은 작업을 남기는 /compact 명령을 복사합니다.` |

## 새 문구 목록(영어 원문 → 한국어)
- `Large sessions` → `큰 세션`
- `Context %@ · re-reads about %@ per call` → `컨텍스트 %@ · 호출마다 다시 읽는 비용 약 %@`
- `Context %@ · re-reads an estimated %@ per call` → `컨텍스트 %@ · 호출마다 다시 읽는 비용 추정 %@`
- `Paste it into the session and press Return. It works best when a task is done.` → `세션에 붙여 넣고 Return을 누르세요. 작업이 끝난 시점에 하면 요약이 가장 깔끔합니다.`
- `Compact it before you leave, and only the summary is rebuilt when you come back.` → `떠나기 전에 정리해 두면, 돌아와서 다시 만드는 것은 요약뿐입니다.`
- `Copy compact prompt` → `정리 프롬프트 복사`
- `Copied` → `복사됨`
- `Copy compact prompt for %@` → `%@ 세션의 정리 프롬프트 복사`
- `Compact prompt copied` → `정리 프롬프트를 복사했습니다`
- `Copies a /compact command that keeps the goal, decisions, files, state and remaining work.` → `목표, 결정, 파일, 상태, 남은 작업을 남기는 /compact 명령을 복사합니다.`
- 프롬프트 본문 한 개(domain-entities `CompactPrompt`)

## 스냅숏 상태(추가)
| 이름 | 내용 |
|---|---|
| `popover-large-sessions` | 큰 세션 2개, 만료 경고 없음 |
| `popover-large-expiring` | 첫 만료 경고가 큰 세션: ② 안내 줄과 버튼 |
| `popover-large-many` | 큰 세션 7개: 5개와 "세션 2개 더 있음" |
| `popover-large-unpriced` | 가격 없는 모델의 큰 세션 |

각 상태를 영어·한국어, 밝은·어두운 모드로 렌더링한다. 세션 제목은 기존 스냅숏처럼 가상의 값만 쓴다.
