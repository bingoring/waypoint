---
artifact: domain-entities
build-spec: menu-bar-app
status: READY
updated: 2026-11-18
---

# Domain & Entities — 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림

> 2-3의 엔티티는 대부분 계산 결과다. 영속하는 것은 사용자 설정(`UserDefaults`), 예약된 알림(시스템), 색인 스키마 v4의 표 하나(`read_stats`)뿐이다. 금액 단위는 2-2와 같은 나노달러 정수다.

## 1. 엔티티 개요

| 엔티티 | 설명 | 영속성 | SoT 출처 |
|---|---|---|---|
| `RunningSession` | 실행 중인 Claude Code 세션 하나 | 없음(`~/.claude/sessions/<pid>.json`에서 매번 읽음) | design 5장·6.5, 2-3 관찰 |
| `RegistryState` | 실행 세션 파일을 읽은 결과 | 없음 | design 6.5 "상태 확인 불가" |
| `LastCall` | 세션의 마지막 API 호출과 만료 계산 재료 | 없음(색인에서 계산) | design 6.5 |
| `ExpiryWarning` | 만료가 다가오는 세션 하나에 대한 경고 | 없음 | design 6.5, 8.1 |
| `IndexHealth` | 최근 7일 동안 읽은 줄 가운데 호출이 되지 못한 assistant 줄의 비율 | 색인 `read_stats`(스키마 v4) | design 8.2 "형식 변화 감지" |
| `IndexProgress` | 첫 색인 진행률 | 없음 | design 8.2 "첫 색인 중", 2-1 편차(부분 결과 신호) |
| `AppSettings` | 사용자 설정 | `UserDefaults` | design 8.1 설정 창, DECISIONS 2026-11-18 |
| `ScheduledExpiryNotification` | 예약된 만료 알림 하나 | `UNUserNotificationCenter`(시스템) | design 6.5 알림 |
| `AppState` | 앱 전체의 화면 상태 | 없음 | design 8.2 |
| `CostBucket.advisor` | 2-2 `CostBucket`의 8번째 값 | 없음 | DECISIONS 2026-11-18 |

## 2. 엔티티 상세

### `RunningSession`
| 필드 | 타입 | 필수 | 출처 키 | 설명 |
|---|---|---|---|---|
| `pid` | Int32 | ✅ | `pid` | 파일 이름의 숫자와 같아야 한다 |
| `sessionID` | String | ✅ | `sessionId` | 기록 파일 이름(`<sessionId>.jsonl`)과 같다 |
| `name` | String? | | `name` | 세션 이름. 제목이 없을 때 쓴다 |
| `status` | `busy` / `idle` / `other` | ✅ | `status` | 모르는 값은 `other` |
| `statusSince` | Double? | | `statusUpdatedAt`(밀리초) | 초 단위로 바꿔 저장 |
| `cwd` | String? | | `cwd` | 제목도 이름도 없을 때 폴더 이름을 쓴다 |
| `processStart` | Double? | | `procStart`(`ps lstart` 형식의 로컬 시각, 예: `Tue Nov 17 21:03:11 2026`, `en_US_POSIX`의 `EEE MMM d HH:mm:ss yyyy`로 해석. 2026-11-18 확인) | PID 재사용 확인용. 해석하지 못하면 nil이고, 그때는 `kill`만으로 판단한다 |

- 위 키 말고는 읽지 않는다. 같은 폴더의 `*.key` 파일은 **열지 않는다**(BR-R3).

### `RegistryState`
- `.available([RunningSession])`: 폴더를 읽었고, 살아 있는 프로세스의 세션만 담는다.
- `.unavailable`: 폴더가 없거나, 읽을 수 없거나, `*.json`이 하나도 해석되지 않았다(형식 변화).

### `LastCall`
| 필드 | 타입 | 설명 |
|---|---|---|
| `sessionID` | String | |
| `file` | URL | 그 세션의 메인 기록 파일 |
| `timestamp` | Double | 마지막 호출 시각 |
| `ttl` | `CacheTTL` | 그 호출의 TTL. 없으면 그 파일에서 가장 최근에 확인된 TTL, 그것도 없으면 1시간(2-2 R5) |
| `model` | String | |
| `contextTokens` | Int | 마지막 본 모델 단계의 입력 + 캐시 읽기 + 캐시 쓰기(BR-E2) |
| `title` | String? | 색인의 `custom-title`(2-1 R11) |

### `ExpiryWarning`
| 필드 | 타입 | 설명 |
|---|---|---|
| `sessionID` | String | |
| `displayTitle` | String | 제목 → 세션 이름 → 폴더 이름 순(BR-E6) |
| `expiresAt` | Double | `timestamp + ttl` |
| `ttl` | `CacheTTL` | |
| `contextTokens` | Int | |
| `rebuildCost` | Int | 나노달러. `contextTokens` × 그 TTL의 쓰기 단가(모델·구간은 2-2 R10) |
| `statusKnown` | Bool | 실행 세션 파일로 idle임을 확인했으면 true |
| `notifies` | Bool | 알림 대상인가(1시간 TTL이고 알림이 켜져 있음) |

### `IndexHealth`
| 필드 | 타입 | 설명 |
|---|---|---|
| `assistantLines` | Int | 최근 7일 동안 읽은 줄 가운데 최상위 `type`이 `assistant`인 줄과, `"assistant"`가 들어 있지만 JSON이 깨진 줄의 수 |
| `assistantWithoutCall` | Int | 그중 API 호출이 되지 못한 줄(2-1 R2 불충족 + 깨진 줄). 평소에는 `<synthetic>` 메시지뿐이다(2026-11-18 측정: 89,765줄 중 68줄, 0.076%) |
| `mainLines`, `mainCalls` | Int | 최근 7일 동안 메인 기록 파일에서 새로 읽은 줄 수와 새로 생긴 호출 수 |
| `kind` | `none` / `unreadableLines(share)` / `noCalls` | BR-H1 |

### `read_stats` (색인 스키마 v4)
| 열 | 타입 | 설명 |
|---|---|---|
| `file_id`, `day` | INTEGER | 기본 키. `day`는 UTC 기준 `floor(읽은 시각 / 86400)` |
| `lines`, `assistant_lines`, `assistant_without_call`, `calls` | INTEGER | 그날 그 파일에서 새로 읽은 값의 합 |

- 30일보다 오래된 행은 전체 색인 때 지운다. 파일이 다시 읽히면(잘림·교체) 그 파일의 행도 지운다.

### `IndexProgress`
| 필드 | 타입 | 설명 |
|---|---|---|
| `bytesRead` | Int64 | 이번 색인에서 읽은 바이트 |
| `bytesTotal` | Int64 | 이번 색인에서 읽어야 할 바이트(새로 읽을 부분의 합) |
| `isInitial` | Bool | 색인이 비어 있는 상태에서 시작했는가 |

### `AppSettings` (`UserDefaults`, 키는 `tokensAreRunningOut.` 접두사)
| 키 | 타입 | 기본값 | 허용 값 |
|---|---|---|---|
| `notifyBeforeExpiry` | Bool | false | |
| `notifyLeadMinutes` | Int | 10 | 5, 10, 15, 20 |
| `warningContextTokens` | Int | 100,000 | 50,000, 100,000, 200,000, 500,000 |
| `rebuildThresholdTokens` | Int | 50,000 | 10,000, 20,000, 30,000, 50,000, 75,000, 100,000 |
| `selectedPeriod` | `ReportPeriod` | `today` | 2-2 `ReportPeriod` |
| `showAllRebuildCauses` | Bool | false | |

- "로그인할 때 열기"는 `UserDefaults`에 두지 않고 `SMAppService.mainApp.status`를 그대로 읽고 쓴다(BR-S4).
- 허용 값 밖의 값이 저장되어 있으면 기본값으로 읽는다.

### `ScheduledExpiryNotification`
| 필드 | 타입 | 설명 |
|---|---|---|
| `identifier` | String | `expiry.<sessionID>.<expiresAt를 정수 초로>` — 같은 세션·같은 만료 시각에 하나 |
| `fireAt` | Double | `expiresAt − notifyLeadMinutes × 60` |
| `title`, `body` | String | frontend-components §7의 문구 |

### `AppState`
`indexing(IndexProgress)` · `noTranscripts` · `indexError(String)` · `ready`. 형식 변화(`IndexHealth.formatChanged`)는 `ready` 위에 겹쳐 보이는 배너다. 화면은 frontend-components §4.

## 3. 관계 (Relationships)

| 좌 | 카디널리티 | 우 | 비고 |
|---|---|---|---|
| `RunningSession` | 1─0..1 | `LastCall` | `sessionID`로 메인 기록 파일을 찾는다 |
| `LastCall` | 1─0..1 | `ExpiryWarning` | BR-E1의 조건을 만족할 때만 |
| `ExpiryWarning` | 1─0..1 | `ScheduledExpiryNotification` | `notifies`일 때만 |
| `UsageReport`(2-2) | 1─* | 팝오버의 원인 행 | frontend-components §6 |

## 4. 열거형 / Allowed-set

| 이름 | 값 | 확장 규칙 |
|---|---|---|
| `CostBucket`(2-2 확장) | 기존 7개 + `advisor` | 화면 행과 CLI 출력 순서를 함께 바꾼다 |
| `RunningSession.status` | `busy`, `idle`, `other` | 새 값은 `other`로 읽는다 |
| `AppState` | `indexing`, `noTranscripts`, `indexError`, `ready` | |

## 5. SoT 매핑 (SoT → 타입)

| SoT 요소 | 엔티티.필드 | 비고 |
|---|---|---|
| design 6.5 "남은 시간" | `ExpiryWarning.expiresAt` | |
| design 6.5 "다시 써야 할 토큰 양" | `ExpiryWarning.contextTokens`, `rebuildCost` | |
| design 6.5 "상태 확인 불가" | `RegistryState.unavailable`, `ExpiryWarning.statusKnown` | |
| design 6.5 "같은 세션에 같은 만료 시점으로는 한 번만" | `ScheduledExpiryNotification.identifier` | |
| design 8.1 설정 창 | `AppSettings` | 재구축 임계값 포함(DECISIONS 2026-11-18) |
| design 8.2 상태별 화면 | `AppState`, `IndexHealth`, `IndexProgress` | |
