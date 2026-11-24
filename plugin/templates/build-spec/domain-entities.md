---
artifact: domain-entities
build-spec: <topic-slug>
status: DRAFT
updated: YYYY-MM-DD
---

# Domain & Entities — <제목>

> **무엇을 다루나:** 이 스테이지가 다루는 **엔티티·타입·데이터 shape·관계·상태·영속성**. 구현자가 타입을 추측하지
> 않도록 **구체 계약**으로. "규칙·검증"은 `business-rules.md`, "흐름·전이 로직"은 `business-logic-model.md`로 분리.
>
> **allowed-set 방침:** enum성 필드는 DB CHECK가 아니라 **코드 측 allowed-set**으로(확장성). 값 목록은 여기 명시.

## 1. 엔티티 개요
| 엔티티 | 설명 | 영속성(store/table/fixture/API) | SoT 출처 |
|---|---|---|---|
|  |  |  |  |

## 2. 엔티티 상세 (엔티티마다 반복)

### `<EntityName>`
| 필드 | 타입 | 필수 | 기본값 | 제약/allowed-set | 설명 |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

- **식별자/키:** <PK/유니크>
- **상태 필드(있으면):** 가능한 값 = `[...]` (전이 규칙은 business-logic-model §상태 전이)

## 3. 관계 (Relationships)
> 엔티티 간 참조·카디널리티·소유. (예: `User 1─* Session`, `Exercise *─* Tag`)

| 좌 | 카디널리티 | 우 | 비고(FK/삭제 전파) |
|---|---|---|---|

## 4. 열거형 / Allowed-set
> 코드 측 allowed-set으로 관리하는 값 집합. 확장 시 추가만.

| 이름 | 값 | 확장 규칙 |
|---|---|---|

## 5. SoT 매핑 (SoT → 타입)
> SoT의 데이터 요소를 위 엔티티/필드로 1:1 매핑. 라인 단위 대조 가능하게.

| SoT 요소 | 엔티티.필드 | 비고 |
|---|---|---|
