---
phase: 01-inception
stage: 03-architecture-decision
status: AI_PROPOSED
updated: 2026-11-17
---

# [Stage 1-3] Architecture Decision ⚠️

## 목적

구현 방식, 구성 요소, 데이터 흐름, 배포 방식을 정하고, 리뷰 게이트가 쓸 품질 기준선을 정의한다.

## 입력 (Inputs)

- 이전 스테이지: [`01-context-synthesis.md`](01-context-synthesis.md), [`02-domain-model.md`](02-domain-model.md)
- 설계 입력: [`../inputs/design.md`](../inputs/design.md) 3장(제약), 4장(접근 방식), 7장(구조), 8장(화면), 9장(배포), 10장(테스트), 13장(위험)

## 체크리스트

- [x] 구현 방식과 탈락한 대안을 문서화했다
- [x] 구성 요소와 데이터 흐름을 정했다
- [x] 리뷰 게이트의 품질 기준선을 정의했다
- [x] 비가역 게이트 체크리스트를 작성했다

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 결정
Swift 6 + SwiftUI 네이티브 메뉴 막대 앱(macOS 14 이상). 분석 코어는 별도 Swift 패키지로 분리한다. 사용자가 고른 방식이다([DECISIONS](../DECISIONS.md)).

### 구성 요소
| 구성 요소 | 역할 |
|---|---|
| `RunningOutCore` (Swift 패키지) | JSONL 증분 리더(파일별 오프셋·inode), 파서, 중복 제거, 재구축 판정, 원인 분류, 기간별 집계, SQLite 색인 |
| `running-out` (개발용 CLI) | `index`, `report`, `events`. 기준값 대조와 보정용. v1에서 사용자용으로 문서화하지 않음 |
| `TokensAreRunningOut.app` | `MenuBarExtra` 팝오버, 설정 창, 알림. FSEvents로 `~/.claude/projects`와 `~/.claude/sessions` 감시 |

### 데이터 흐름
1. FSEvents가 기록 파일의 변경을 알린다.
2. 리더가 저장해 둔 오프셋부터 새 줄만 읽는다. 파일이 잘리거나 교체되면 그 파일을 처음부터 다시 읽는다.
3. 파서가 ApiCall과 CompactionMark를 만들고, 판정기와 분류기가 Rebuild와 Cause를 붙인다.
4. 결과를 `~/Library/Application Support/TokensAreRunningOut/index.sqlite`에 쌓는다.
5. 화면은 색인을 기간별로 집계해서 보여주고, 세션 파일과 마지막 ApiCall로 만료 경고를 계산한다.

### 지키는 선
- 네트워크 코드를 넣지 않는다. 릴리스 페이지 열기는 브라우저에 맡긴다.
- `~/.claude` 아래에는 쓰지 않는다.
- 샌드박스는 쓸 수 없으므로(`~/.claude` 읽기), Mac App Store가 아니라 Developer ID 서명과 공증으로 배포한다.

### 리뷰 게이트의 품질 기준선 (R-1에서 리뷰어 지시에 넣는다)
- **정확성:** 개발용 CLI의 결과가 기준값(설계 입력 10장)과 **정확히** 같아야 한다. 픽스처 단위 테스트가 모든 Cause와 경계값(TTL 경계, 3시간 경계, 50k 임계값, 중복 줄, `<synthetic>`, 압축 경계)을 덮어야 한다.
- **보안·개인정보:** 네트워크 API 사용 0건, `~/.claude`에 쓰기 0건, 자격 증명 파일 접근 0건. 저장소에 실제 기록이나 세션 제목이 들어가지 않아야 한다.
- **성능 예산:** 첫 색인은 1.7GB 기준 2분 이내, 증분 반영은 1초 이내, 유휴 CPU는 거의 0, 메모리는 100MB 이하.
- **정적 분석:** Swift 6 strict concurrency, 경고 0건. 린터 도입 여부는 2-1에서 정한다.
- **화면:** better-interface 검토에서 HIGH 0건.

### 비가역 게이트 체크리스트
- [x] **번복 시 영향:** Swift를 다른 기술로 바꾸면 앱 전체와 릴리스 파이프라인을 다시 만들어야 한다. 코어 패키지와 CLI는 Swift 생태계에 묶인다. 기준값 대조 방식(프로토타입 스크립트)은 기술과 무관하게 남는다.
- [x] **대안과 탈락 이유:** Rust 코어 + Swift UI(빌드·배포 복잡, 출시 지연), Tauri나 Electron(무거움, 차별점과 충돌), Claude Code Mods(여러 세션에 걸친 분석과 쉬는 세션 경고에 맞지 않음).
- [x] **외부 의존성:**

| 의존성 | 내용 | 출처 | 조회일 | 확인 수준 |
|---|---|---|---|---|
| 개발 도구 | Xcode 26.4, Swift 6.3 | 개발자 기기 `xcodebuild -version`, `swift --version` | 2026-11-17 | 공식 확인 |
| `MenuBarExtra` | macOS 13 이상 SwiftUI API | Apple 개발자 문서 | 2026-11-17 | 추론(2-3 착수 전 재확인) |
| Claude Code 기록 형식 | 문서화되지 않은 내부 형식, 버전마다 바뀔 수 있음 | 개발자 기기 기록(2.1.293 ~ 2.1.325) | 2026-11-17 | 공식 확인(관찰), 안정성은 추론 |
| `~/.claude/sessions/<pid>.json` | 비공식 실행 상태 파일 | 개발자 기기 관찰 | 2026-11-17 | 공식 확인(관찰), 안정성은 추론 |
| 서명·공증 | Apple Developer Program(연 $99), `notarytool` | 사용자 확인(계정 있음) | 2026-11-17 | 공식 확인 |
| Homebrew 공식 cask 조건 | 인지도와 서명·공증 요구 | Homebrew 문서 | 2026-11-17 | 추론(3-1 착수 전 재확인) |
| API 단가와 캐시 배수 | 캐시 읽기 ×0.1, 5분 쓰기 ×1.25, 1시간 쓰기 ×2 | Anthropic 가격 문서 | 2026-11-17 | 2차 자료(2-2 착수 전 재확인) |

### 주요 위험
- 모든 수치가 데스크톱 앱 세션(1시간 TTL)만으로 얻은 것이다. 터미널 사용자 일부는 메인 세션이 5분 TTL이라는 보고가 있다(#46829, #45381). 2-1의 첫 작업으로 확인한다.
- 수요의 형태는 가설이다(1-1). 3-2에서 검증한다.

### 미해결 질문
없음.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [ ] 구성 요소와 데이터 흐름이 맞는가?
- [ ] 품질 기준선(정확성, 보안·개인정보, 성능, 정적 분석, 화면)에 동의하는가?
- [ ] 비가역 게이트 체크리스트 세 항목을 확인했는가?

### 승인 결과 (YYYY-MM-DD, 결정자)

> AI가 기록한다. 사람의 답이 AI 기본안과 다르면 어느 절을 대체하는지 명시한다(FRAMEWORK "승인 결과 기록").

| # | 답변 |
|---|------|

## 다음 단계

승인 후 → `STATUS.md`의 이 스테이지 상태를 `HUMAN_APPROVED`로 업데이트 → Construction 2-1(CLI 세션 확인 · 기록 리더와 색인) 스테이지 문서 작성
