---
artifact: frontend-components
build-spec: adaptive
status: DRAFT
updated: 2026-10-16
---

# Frontend Components — 공통 적응형 난이도 `factory_adaptive`

> 이 패키지의 화면 요소는 설정 한 줄뿐이다. 판 화면은 게임이 소유한다.

## 1. `AdaptiveTile` (설정 부품, `factory_ui` 설정 타일과 같은 모양)
- **역할:** 「판을 내 플레이에 맞추기」 스위치 + 바로 아래 한 줄 「끄면 모든 사람과 같은 난이도로 진행돼요」 (A-UI-1).
- **props:** `director`(Director), 문구는 `factory_ui` 지역화(ko·en)에 추가.
- **상태:** `AdaptiveState.enabled` 읽기·쓰기. 바꾸면 다음 판부터 적용(진행 중인 판은 그대로).
- **위치:** 각 게임 설정 화면에서 효과음·진동 스위치 아래.

## 2. 화면 상태
| 상태 | UI |
|---|---|
| 켬(기본) | 스위치 켬 |
| 끔 | 스위치 끔, 문구 그대로 |

## 3. 게임 쪽 책임 (참고)
- 판 로딩은 미리 만들어 두므로 보통 대기가 없다. 만약 생성이 늦으면 게임이 짧은 전환 연출(하품 릴레이: 열차가 역으로 들어오는 움직임) 안에서 기다린다. 「불러오는 중」 표시는 쓰지 않는다.
