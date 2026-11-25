---
artifact: frontend-components
build-spec: <topic-slug>
status: DRAFT
updated: YYYY-MM-DD
---

# Frontend Components — <제목>

> **조건부 아티팩트** — UI를 산출하는 스테이지만. 없으면 인덱스 §2에 `N/A + 사유`.
> **무엇을 다루나:** **컴포넌트 트리·props·상태·상호작용·데이터 연결·화면 상태·디자인 SoT 매핑**. 데이터 형태는
> `domain-entities.md`, 검증/권한은 `business-rules.md`, 흐름은 `business-logic-model.md`를 참조(중복 서술 금지, 링크).

## 1. 컴포넌트 트리 (Hierarchy)
```
<ScreenOrRoot>
├── <Child A>
│   └── <Grandchild>
└── <Child B>
```

## 2. 컴포넌트 상세 (컴포넌트마다 반복)

### `<ComponentName>`
- **역할:** <한 줄>
- **props:**

  | prop | 타입 | 필수 | 설명 |
  |---|---|---|---|

- **로컬 상태:** <state 필드·초기값>
- **이벤트/콜백:** <onX → 무엇>
- **소비 데이터:** domain-entities `<Entity>` / API `<endpoint>`

## 3. 전역 · 공유 상태 (Shared State)
> store/context 연결. 무엇을 읽고 무엇을 dispatch 하나.

| 상태 | 소스(store/context) | 읽기/쓰기 컴포넌트 |
|---|---|---|

## 4. 화면 상태 (Screen States)
> 각 상태의 UI. **빈/로딩/에러를 빠뜨리지 말 것.**

| 상태 | 트리거 | UI |
|---|---|---|
| loading |  |  |
| empty |  |  |
| error |  |  |
| success |  |  |

## 5. 상호작용 · 네비게이션
> 진입/이탈, 사용자 액션 → 결과(로직 호출은 business-logic-model 워크플로 참조).

## 6. 디자인 SoT 매핑 (디자인 요소 → 컴포넌트)
| SoT 디자인 요소 | 컴포넌트 | 데이터/props |
|---|---|---|
