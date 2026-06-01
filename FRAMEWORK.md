# Waypoint Framework Rules

> 이 문서는 AI가 Waypoint 프레임워크 안에서 동작할 때 반드시 따라야 하는 계약서다.

## 세션 시작 프로토콜

AI가 새 세션을 시작할 때 반드시 아래 순서를 따른다:

1. `projects/{project-name}/STATUS.md`를 읽는다
2. `PENDING` 상태인 가장 앞 스테이지를 찾는다
3. 해당 스테이지 문서를 열고 `Inputs` 섹션에 명시된 파일을 모두 읽는다
4. `AI Proposal` 섹션을 작성하고 status를 `AI_PROPOSED`로 변경한다
5. 사람에게 리뷰를 요청하고 대기한다

## 절대 규칙

- `HUMAN_APPROVED` 없이는 다음 스테이지로 진행하지 않는다
- `AI Proposal` 섹션은 AI 전용이다. 사람이 직접 수정하면 안 된다
- 비가역 게이트(`⚠️` 표시)에서는 추가 체크리스트 항목을 반드시 확인한다
- STATUS.md의 상태 표는 항상 실제 문서 상태와 동기화되어야 한다

## 상태 생애주기

```
PENDING → IN_PROGRESS → AI_PROPOSED → HUMAN_APPROVED
```

| 상태 | 설명 |
|------|------|
| `PENDING` | 시작 전. 이전 스테이지가 APPROVED되지 않으면 진입 불가 |
| `IN_PROGRESS` | AI가 현재 작업 중 |
| `AI_PROPOSED` | AI 제안 완료. 사람의 검토 대기 |
| `HUMAN_APPROVED` | 사람이 승인. 다음 스테이지 언락 |

## 비가역 게이트 추가 체크리스트

`⚠️` 표시가 있는 스테이지는 아래 항목을 추가로 확인해야 승인 가능하다:

- [ ] 이 결정을 번복할 경우 영향받는 파일/레이어 목록을 작성했는가
- [ ] 대안을 검토하고 탈락 이유를 문서화했는가
- [ ] 외부 의존성(API, 라이브러리, 비용)을 확인했는가

## STATUS.md 업데이트 규칙

스테이지 상태가 변경될 때마다 STATUS.md의 테이블을 함께 업데이트한다.
