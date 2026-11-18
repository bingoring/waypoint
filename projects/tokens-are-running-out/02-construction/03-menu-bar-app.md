---
phase: 02-construction
stage: 03-menu-bar-app
status: HUMAN_APPROVED
updated: 2026-11-18
---

# [Stage 2-3] 메뉴 막대 앱 화면 · 만료 경고 · 실행 중인 세션 · 알림

## 목적

2-2의 분석 코어 위에 사용자가 실제로 쓰는 메뉴 막대 앱을 만든다. 산출물은 개발 빌드 `TokensAreRunningOut.app`(ad-hoc 서명)이다. 이 앱은 쉬고 있는 세션의 캐시 만료를 미리 알려 주고(G2), 사용량의 원인과 비용이 컸던 캐시 재구축을 근거와 함께 보여 준다(G1, G3).

## 입력 (Inputs)

- 승인된 스테이지: [`../01-inception/03-architecture-decision.md`](../01-inception/03-architecture-decision.md)(구성 요소, 화면 품질 기준선), [`02-rebuild-analysis.md`](02-rebuild-analysis.md)(`UsageReport`, `RebuildEvent`)
- 설계 입력: [`../inputs/design.md`](../inputs/design.md) 5장, 6.5, 7장, 8장
- 이월 항목: 2-1 편차 로그의 "부분 결과 준비 신호와 변경 알림", 2-2의 "advisor 비용 표시"(사용자 결정 대기였음)
- 디자인 기준: 사용자가 설치한 better-* 스킬(better-interface가 나머지 여섯 개를 묶어 검토)

## 체크리스트

- [x] 2-3 범위를 정하고 2-4(서명·공증·배포)와 경계를 그었다
- [x] 실행 세션 파일과 제목 출처를 실제 기기에서 확인했다
- [x] 앱 번들 빌드 방식(String Catalog, 알림, 화면 렌더링)을 시험했다
- [x] 재구축 임계값의 민감도를 실제 기록으로 측정했다
- [x] 사용자 결정이 필요한 질문 두 개를 물었다(하나는 결정, 하나는 사용자 의견을 받아 제안으로 정리)
- [x] 화면 시안을 better-interface 방식으로 구현 전에 검토했다
- [x] Build Spec(comprehensive)을 썼다
- [x] 미해결 질문이 없다

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 범위
- **포함:**
  - 메뉴 막대 표시, 팝오버(만료가 다가오는 세션, 원인 분해, 비용이 컸던 캐시 재구축), 근거 팝오버, 설정 창
  - 실행 중인 세션 확인과 만료 경고, 만료 전 알림(사용자가 켰을 때만)
  - 상태별 화면(첫 색인, 기록 없음, 색인 오류, 형식 변화)
  - 2-2 코어 확장: advisor 별도 버킷, 재구축 임계값 매개변수
  - 영어·한국어 문구, 개발용 앱 빌드 스크립트, 화면 검토용 스냅숏 도구
- **제외:**
  - Developer ID 서명, 공증, GitHub Releases, Homebrew tap → 2-4
  - 세션으로 이동하는 딥 링크, 공식 한도 % → 비목표(설계 2장)

### 2-3에서 새로 확인한 사실
- **실행 세션 파일.** `~/.claude/sessions/<pid>.json`에 `pid`, `sessionId`, `name`, `status`(`idle`/`busy`), `statusUpdatedAt`(밀리초), `cwd`, `procStart`(`ps lstart` 형식의 로컬 시각)가 있다. 확인한 4개는 모두 데스크톱 앱 세션(`entrypoint: claude-desktop`)이고, 기록 파일과 모두 연결됐다. 같은 폴더에 `<pid>.<hash>.key` 파일이 있다. 인증 키일 수 있으므로 앱은 이 파일을 **열지 않는다**.
- **세션 제목.** 최근 30일에 쓴 메인 세션 76개 중 74개가 기록 안에 `custom-title`을 갖고 있다. 데스크톱 앱 메타데이터의 제목은 이 범위를 넓히지 않는다. 그래서 그 폴더를 읽지 않는다.
- **앱 빌드.** `swift build`는 String Catalog를 컴파일하지 않는다(시험 결과 번역이 적용되지 않음). `xcodebuild`로 같은 패키지를 빌드하고 `.app`으로 조립하면 한국어·영어 선택, 영어 복수형, 알림 센터 접근이 모두 동작했다. Xcode 프로젝트 파일 없이 SwiftPM과 스크립트로 간다.
- **형식 변화 감지 신호.** 처음 쓴 규칙(파싱 실패 비율)은 형식 변화를 잡지 못한다. 필드 이름이 바뀐 줄은 "깨진 줄"이 아니라 "후보 아님"이나 "거부"로 분류되기 때문이다(advisor 검토에서 지적). 대신 "호출이 되지 못한 assistant 줄의 비율"을 쓴다. 최근 7일 기준 89,765줄 중 68줄(0.076%, 모두 `<synthetic>` 메시지)이라 5%를 기준으로 삼는다. 최상위 `type`까지 바뀌는 경우에 대비해 "메인 기록에 줄은 늘었는데 호출이 0건"도 함께 본다.
- **화면 확인.** `ImageRenderer`는 AppKit 기반 컨트롤(구간 선택기, 진행 막대)을 그리지 못한다. 화면 밖 창의 `NSHostingView`를 캡처하면 밝은·어두운 모드 모두 제대로 그려졌다. 구현 뒤 이 방식으로 상태별 PNG를 만들어 디자인 검토에 쓴다.
- **재구축 임계값의 민감도.** 10월 1일부터 11월 17일까지의 실제 기록으로 측정했다.

| 임계값 | 재구축(전체) | 메인 세션의 만료 재구축 | 압축 직후 | 메뉴 막대 숫자 |
|---|---|---|---|---|
| 1만 ~ 3만 | 725 ~ 745건 | 251건 | 39건 | 14.4% |
| 5만(기본) | 686건 | 251건 | 30건 | 14.4% |
| 7.5만 | 404건 | 241건 | 1건 | 14.3% |
| 10만 | 389건 | 229건 | 0건 | 14.2% |
| 15만 | 330건 | 201건 | 0건 | 13.7% |

  - 5만은 설계 문서에 근거가 적혀 있지 않은 기본값이었다. 이 기록에서는 1만 ~ 5만 사이에서 핵심 숫자가 변하지 않았고, 그보다 높이면 압축 직후와 서브에이전트 재구축이 빠졌다.
  - 다만 이 결과는 개발자 한 사람의 기록이다. 시작 컨텍스트가 큰 사용자, 압축을 자주 하는 사용자, 5분 캐시를 쓰는 터미널 사용자는 다를 수 있다. 그래서 사용자가 임계값을 바꿀 수 있게 한다(결정 참고).

### 결정
- **advisor 비용은 별도 항목으로 보여 준다(사용자 결정).** 코어에 8번째 버킷 `advisor`를 두고, 메인·서브에이전트 모두 advisor 단계의 비용을 그곳에 넣는다. 프로토타입과 기준값도 함께 바꾼다.
- **재구축 임계값과 경고 임계값을 모두 설정할 수 있다(AI 제안, 이 게이트에서 확인).** 사용자는 "다른 사람들은 다를 수 있다"고 의견을 냈고, AI는 그 지적이 맞다고 보고 설정 가능하게 제안한다. 재구축 임계값의 기본값은 5만으로 둔다. 기본값에서 바꾸면 모든 기간을 다시 계산하고, 팝오버 요약에 바뀐 값을 표시한다.
- **알림은 켜야 동작한다.** 처음에는 꺼져 있고, 켤 때 권한을 요청한다. 같은 세션·같은 만료 시각에는 한 번만, 늦게 보내지 않는다. 5분 캐시 세션에는 보내지 않는다(설계 6.5).
- **첫 색인은 진행 막대만 보인다.** 설계의 "최근 30일치 먼저"는 하지 않는다. 첫 색인이 11.7초라 나눠 처리할 이득이 없다.
- **앱이 읽는 범위를 줄인다.** `~/.claude/projects/**`와 `~/.claude/sessions/<숫자>.json`만 읽는다.
- **빌드는 SwiftPM + `xcodebuild` + 조립 스크립트.** 정식 서명과 공증은 2-4에서 한다.

### 화면 시안

숫자와 제목은 예시다(실제 기록이 아님).

```
메뉴 막대:  [모래시계] 18%          (만료가 다가오는 세션이 있으면  [모래시계] 8 min)

Caches expiring soon
  Refactor parser                                    ◷ 8 min left
    To continue without a rebuild, send a message within 8 minutes.
    After that, the next message rebuilds the cache from 720K tokens (about $5.76).
  Write release notes                                ◷ 41 min left

What used your tokens                    [ 5 hours | Today | 7 days ]
  $807.63 at API list prices · 4,133 calls
  18% went to rebuilding caches after a break.
  ▇▇▇▇▇▇▇▇▇░░░░░░░░░░░  Normal work                         44%   $352.44
  ▇░░░░░░░░░░░░░░░░░░░  Cache rebuilt after a short break    6%    $49.10
     6% could have been saved by continuing before the cache expired
  ▇▇░░░░░░░░░░░░░░░░░░  Cache rebuilt after a long break    12%    $98.03
  ▇▇▇░░░░░░░░░░░░░░░░░  Subagents                           13%   $103.38
  ▇▇▇▇▇░░░░░░░░░░░░░░░  Advisor                             23%   $188.28
  ░░░░░░░░░░░░░░░░░░░░  ▸ Other                              2%    $16.40

Expensive cache rebuilds                                 [ ] Show all causes
  13:02  Refactor parser                                     [Show Reason]
         After 62 min away · 720K tokens · $5.76
  09:40  Write release notes                                 [Show Reason]
         After 14 h away · context 1.1M tokens · $8.80
─────────────────────────────────────────────
Settings…                                                         Quit
```

- 화면 요소, 상태별 화면, 설정 창, 알림, 영어·한국어 문구 전체는 [frontend-components](menu-bar-app/frontend-components.md)에 있다.

### 구현 전 디자인 검토 (better-interface)
- 여섯 개 영역 스킬(접근성, 레이아웃, 문구, 타이포그래피, 색, UI)의 기준으로 설계 8장 시안과 2-3 확장을 검토했다.
- HIGH 3건(색인 오류의 복구 방법 없음, 알림 권한 거부 상태 없음, "기타"의 내역에 닿을 방법 없음)과 MEDIUM 5건, LOW 1건을 찾아 모두 명세에 반영했다.
- 판정은 `Approve`(구현 착수)다. 다만 렌더링·대비·VoiceOver·키보드는 구현 전이라 확인하지 못했다. 상세 기록은 [frontend-components §8](menu-bar-app/frontend-components.md)에 있다.

### 구현 스펙
- Build Spec: [`menu-bar-app/build-spec-index.md`](menu-bar-app/build-spec-index.md) (status: READY, depth: comprehensive)

### 검증 요약
- 경계값 단위 테스트(경고, 알림, 실행 세션, 형식 변화, 원인 행, 임계값)를 둔다.
- 기본 임계값과 다른 임계값 하나에서 `running-out report`가 프로토타입과 글자 단위로 같아야 한다(advisor 버킷 반영 후 새 기준값).
- 상태별 화면 PNG를 better-interface로 다시 검토해 HIGH 0건을 만든다.
- 유휴 CPU, 메모리, 반영 시간을 측정해 기록한다.
- VoiceOver, 키보드 조작, 알림 수신, 로그인 항목은 사용자 기기에서 확인을 부탁한다.

### 미해결 질문
없음.

## 검토 게이트 (Human Gate)

> 아래 항목을 확인 후 frontmatter의 status를 `HUMAN_APPROVED`로 변경하세요.

- [x] 2-3 범위와 2-4의 경계가 맞는가?
- [x] advisor 별도 항목과, 알림을 켜야 동작하는 방식에 동의하는가?
- [x] 재구축 임계값도 설정할 수 있게 하는 제안(기본 5만, 바꾸면 팝오버에 표시)에 동의하는가? 아니면 5만으로 고정할까?
- [x] 화면 시안과 문구(영어 기본, 한국어 제공)가 맞는가?

### 승인 결과 (2026-11-18, 사용자)

> AI가 기록한다. 사람의 답이 AI 기본안과 다르면 어느 절을 대체하는지 명시한다(FRAMEWORK "승인 결과 기록").

| # | 답변 |
|---|------|
| 1 | 채팅으로 "승인". "임계값은 5만 고정" 선택지 대신 승인을 골랐으므로, 재구축 임계값을 설정할 수 있게 하는 AI 제안을 그대로 확정한다. 나머지도 AI 제안대로 확정한다. |

## 다음 단계

승인 후 → `STATUS.md` 갱신 → 기능 브랜치 `feature/2-3-menu-bar-app`에서 Build Spec §4 체크리스트대로 구현 → 독립 리뷰 → PR
