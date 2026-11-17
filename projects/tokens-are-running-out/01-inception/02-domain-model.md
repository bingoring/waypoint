---
phase: 01-inception
stage: 02-domain-model
status: HUMAN_APPROVED
updated: 2026-11-17
---

# [Stage 1-2] Domain Model

## 목적

앱이 다루는 대상(기록, 호출, 세션, 재구축, 원인)과 그 관계·불변식을 정해서, Construction 단계가 같은 말로 구현하게 한다.

## 입력 (Inputs)

- 이전 스테이지: [`01-context-synthesis.md`](01-context-synthesis.md)
- 설계 입력: [`../inputs/design.md`](../inputs/design.md) 5장(데이터 출처), 6장(핵심 계산)

## 체크리스트

- [x] 엔티티와 관계를 정했다
- [x] 원본 데이터와의 대응을 실제 기록으로 확인했다
- [x] 불변식과 판정 규칙을 정했다
- [x] 확인하지 못한 가정을 표시했다

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 엔티티

| 엔티티 | 뜻 | 원본 | 핵심 속성 |
|---|---|---|---|
| **Transcript** | 기록 파일 하나 | `~/.claude/projects/<인코딩된 cwd>/<sessionId>.jsonl`, 서브에이전트는 `<sessionId>/subagents/agent-<id>.jsonl` | 경로, inode, 읽은 바이트 오프셋, `kind`(main/subagent) |
| **Session** | 메인 세션 | 메인 Transcript 하나 | `sessionId`, 제목(`custom-title`), 폴더, 실행 상태(busy/idle/종료/확인 불가) |
| **ApiCall** | API 호출 한 번 | `type == "assistant"`인 줄, `message.id`로 중복 제거 | 시각, 모델, 버전, 입력·출력·캐시 읽기·캐시 쓰기 토큰, TTL(1h/5m) |
| **CompactionMark** | 압축 경계 | `type == "system"`, `subtype == "compact_boundary"` | 시각 |
| **Rebuild** | 캐시 재구축으로 판정된 ApiCall | 6.2의 판정 규칙 | 원인(Cause), 직전 호출과의 간격, 캐시 쓰기 토큰, 비용 |
| **Cause** | 재구축 원인(열거형) | 6.3의 분류 순서 | 세션 시작, 압축 직후, 모델 변경, 짧은 휴식 후 만료, 긴 휴식 후 만료, 업데이트 직후, 원인 불명 |
| **CostWeights** | API 정가 환산 가중치 | 앱에 포함하는 가격표 | 모델별 입력 단가, 출력 배수, 캐시 읽기 ×0.1, 5분 쓰기 ×1.25, 1시간 쓰기 ×2 |
| **ExpiryWarning** | 만료 임박 경고 | 실행 중인 idle 메인 세션의 마지막 ApiCall | 만료 시각, 남은 시간, 예상 재구축 토큰 |
| **Period** | 집계 기간 | 사용자 선택 | 최근 5시간, 오늘(로컬 자정 기준), 최근 7일 |

### 관계
- Session 1 : N Transcript(메인 1개 + 서브에이전트 0개 이상).
- Transcript 1 : N ApiCall, Transcript 1 : N CompactionMark.
- ApiCall 0..1 : 1 Rebuild. Rebuild는 정확히 하나의 Cause를 가진다.
- ExpiryWarning은 Session마다 최대 하나다.

### 불변식
1. 같은 `message.id`의 줄은 하나의 ApiCall이다. 중복 줄의 usage 값은 같았다(표본 중복 922건 모두 일치).
2. model이 `<synthetic>`인 메시지는 ApiCall이 아니다. 직전 호출을 찾을 때도 건너뛴다.
3. 한 ApiCall에는 TTL이 하나만 쓰인다(검증 기간 4,133건 중 혼합 0건). 메인 세션은 1시간, 서브에이전트는 5분이었다.
4. Rebuild 판정: 캐시 쓰기 ≥ 50,000이고 캐시 쓰기 > 캐시 읽기.
5. Cause는 정해진 순서로 처음 맞는 것 하나만 붙인다(설계 입력 6.3).
6. "세션 시작"은 같은 Transcript 안에 앞선 ApiCall이 없는 경우뿐이다. 데스크톱 앱은 세션을 다시 열 때 같은 파일에 이어서 기록한다(확인함).
7. 재구축 호출의 캐시 쓰기 비용만 그 Cause에 배분하고, 나머지 비용은 "일반 작업"에 배분한다. 서브에이전트 Transcript의 비용은 모두 "서브에이전트"에 배분한다.
8. "줄일 수 있었던 양"은 짧은 휴식 후 만료 Rebuild에서만 계산한다.
9. 앱은 원본을 읽기만 한다. 파생 데이터(색인)는 언제든 지우고 다시 만들 수 있다.

### 확인하지 못한 가정
- 터미널 세션의 메인 TTL이 1시간인지 5분인지.
- 터미널의 `--resume`이 같은 파일에 이어서 기록하는지.
- 이 두 가지는 2-1에서 확인한다. 결과에 따라 불변식 3과 6을 고친다.

### 미해결 질문
없음.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] 원인 분류(Cause)와 비용 배분 규칙이 납득되는가?
- [x] "줄일 수 있었던 양"을 짧은 휴식만으로 계산하는 데 동의하는가?

### 승인 결과 (2026-11-17, 사용자)

> AI가 기록한다. 사람의 답이 AI 기본안과 다르면 어느 절을 대체하는지 명시한다(FRAMEWORK "승인 결과 기록").

| # | 답변 |
|---|------|
| 1 | 채팅으로 "승인". AI 제안대로 확정한다. |

## 다음 단계

승인 후 → `STATUS.md`의 이 스테이지 상태를 `HUMAN_APPROVED`로 업데이트 → [`03-architecture-decision.md`](03-architecture-decision.md)
