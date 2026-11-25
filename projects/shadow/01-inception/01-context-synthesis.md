---
phase: 01-inception
stage: 01-context-synthesis
status: AI_PROPOSED
updated: 2026-07-10
---

# [Stage 1-1] Context Synthesis

## 목적

prd.md와 prd-tech.md를 분석하여 Shadow Engineer가 통합할 4각 툴(Notion/Confluence/Jira/Slack)의 역할, 데이터 가중치, 3-Layer 병합 전략을 명세한다.

## 입력 (Inputs)

- `../../prd.md` — 제품 요구사항 (섹션 1~3 중점)
- `../../prd-tech.md` — 기술 스택 및 아키텍처

## Shadow 전용 체크리스트

- [ ] 4각 툴 각각의 역할(Skeleton/Constraint/Pivot)과 데이터 가중치 정의
- [ ] 3-Layer 병합 전략 (Base→Scope→Adjustment) 구체적 로직 기술
- [ ] Conflict Resolution 예시 시나리오 최소 2개 작성
- [ ] 각 툴의 인증 방식(OAuth 등) 및 데이터 접근 방식 목록화
- [ ] MVP 단계에서 연동할 툴 우선순위 결정

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

### 0. 제품 컨텍스트 한 문장

**Shadow Engineer** = 개발자의 파편화된 협업 맥락(기획·명세·태스크·실시간 합의)을 4개 툴에서 수집·융합하여
**실행 가능한 IDE 아키텍처 플랜**으로 전환하고, 로컬(Tauri)에서 파일/브랜치 "수술"을 집도하는 로컬 퍼스트 AI 에이전트.
핵심 방아쇠는 **Jira 티켓의 `In Progress` 전환**이며, 최종 산출은 로컬 앱의 "Apply" 한 번으로 준비되는 브랜치·파일셋이다.

### 1. 4각 툴 역할 · 가중치 (PRD §1 표 준수)

| 툴 | 역할 | 컨텍스트 성격 | 가중치 | 병합 레이어 |
|----|------|--------------|--------|------------|
| **Notion / Confluence** | **Skeleton** | 서비스 전체 구조·도메인 모델·비즈니스 목표·공식 TDD(API 스키마·보안 규정) | **Low** (기본값) | Layer 1 (Base) |
| **Jira** | **Constraint** | 작업 범위(Scope)·마일스톤·수치 제약·AC | **Medium** | Layer 2 (Scope) |
| **Slack** | **Pivot** | 최신 의사결정·긴급 수정·실시간 예외 합의 | **High** (최신순) | Layer 3 (Adjustment) |

- Notion과 Confluence는 둘 다 Skeleton이나 **성격이 다르다**: Notion = 유연한 기획(UI/UX 변경안 등),
  Confluence = 보수적·정형 TDD(API 스키마·보안). 충돌 시 **Confluence(공식 명세) > Notion(기획 초안)**.
- 가중치는 **정적 우선순위가 아니라 "충돌 시 기본 신뢰도"**다. 최종 판정은 §3의 병합 로직에서 *가중치 × 최신성*으로 결정.

### 2. 3-Layer 병합 전략 (Base → Scope → Adjustment)

LLM에 넘기는 컨텍스트는 단순 concat이 아니라 아래 파이프라인으로 계층 조립한다 (PRD §3).

```
Layer 1 (Base·What)    Notion/Confluence  → 도메인 뼈대·API 스키마·보안 규정을 컨텍스트 루트에 적재
        │  (RAG: pgvector로 현재 티켓과 의미 연관 문서만 선별 주입)
        ▼
Layer 2 (Scope·Now)    Jira Issue Key      → [요구사항]·[Acceptance Criteria]에서 이번 작업 범위·수치 제약 추출
        │  → Base에서 "이번 스코프와 무관한 뼈대"를 프루닝하고 관련 도메인만 활성화
        ▼
Layer 3 (Adjustment·How) Slack 스레드       → 최신 결정(recency desc)으로 Layer1·2를 override/patch
        │  → 충돌 감지 시 §3.1 Conflict Resolution 로직 실행
        ▼
   Actionable Context  → LangGraph 아키텍트 노드로 전달 → Architecture Plan 산출
```

**구체 로직**
1. **수집:** Jira 트리거(`In Progress`) 시 티켓 Issue Key를 기준으로 4개 소스를 병렬 pull.
2. **선별(RAG):** Confluence/Notion 문서는 티켓 텍스트 임베딩으로 top-k 의미 검색(pgvector) — 전체가 아닌 관련 문서만.
3. **정규화:** 각 소스를 `{source, timestamp, weight, claim}` 클레임 단위로 분해.
4. **충돌 탐지:** 같은 주제(엔드포인트·스키마·기술선택)에 상반된 claim이 있으면 conflict set으로 묶음.
5. **판정:** conflict set 내에서 `점수 = weight × recency_factor`로 승자 결정. 단, 승자가 명세(Confluence)를
   뒤집는 "비가역/광범위 영향" 결정이면 **자동 확정하지 않고 Elicitation**(사용자에게 질문) — PRD §6 Week3~4 정렬.
6. **조립:** 승자 claim으로 Base 컨텍스트를 patch → 최종 Actionable Context.

### 3.1 Conflict Resolution 예시

**예시 A (PRD §4.1 원안 — API 포맷):**
- Confluence(2024·Low): "모든 API 응답은 XML로 처리."
- Jira(Medium): "이번 스프린트: REST API JSON 포맷 전환."
- Slack(High·최신): "대표님 회의 결론 — 특정 엔드포인트만 우선 JSON."
- **판정:** Jira+Slack(최신·상위 가중치)이 Confluence를 override. **범위는 Slack이 좁힘** → 해당 엔드포인트에
  한해 JSON 처리 로직 + DTO 생성, 나머지는 기존 유지. (자동 확정 가능 — 영향 국소적)

**예시 B (기술 선택 pivot — 알림 인프라):**
- Notion(Low): "푸시 알림은 Firebase(FCM) 사용."
- Slack(High·최신): "이번엔 Firebase 대신 자체 알림 서버를 테스트해보자."
- **판정:** Slack pivot이 Notion 뼈대를 override → "자체 알림 서버(Redis Queue + NestJS 서비스 레이어)" 설계.
  단, 인프라 교체는 **광범위 영향** → 자동 확정하지 않고 Elicitation("Firebase 완전 대체 vs 병행 A/B?")로 사용자 확인 후 확정.

**예시 C (명세 vs 명세 — Notion↔Confluence):**
- Notion 기획 초안: "회원가입에 소셜 로그인 3종."
- Confluence 공식 TDD: "OAuth2 provider는 Google 단일."
- **판정:** 동일 Skeleton 계층이면 **Confluence(공식) > Notion(초안)** 기본 규칙 적용, 단 Notion이 더 최신이면 Elicitation.

### 4. 인증 · 데이터 접근 방식

| 툴 | 인증 | 수집 방식 | 트리거/이벤트 |
|----|------|----------|--------------|
| **Jira** | Atlassian **OAuth 2.0 (3LO)** — Confluence와 단일 통합 공유 | REST API v3 (issue/description/AC) | **Webhook**: 상태 `→ In Progress` 감지 = 파이프라인 방아쇠 (PRD §5.2, 6 Week1~2) |
| **Confluence** | Atlassian **OAuth 2.0 (3LO)** (Jira와 동일 앱) | REST API v2 (space/page/버전) | 문서 버전 변경 이벤트(FR-5.2 변경 이력 매핑) |
| **Notion** | Notion **OAuth 2.0** (public integration) 또는 Internal Integration Token | Notion API (page/database) | (MVP는 pull 중심, 웹훅은 후속) |
| **Slack** | Slack **OAuth 2.0** + Bot Token(`xoxb`), scope: `channels:history`·`groups:history` 등 | **Events API**(웹훅) + conversations.history pull | 스레드/메시지 이벤트 실시간 수신 |

- **토큰 보관:** OAuth 토큰·리프레시 토큰은 PostgreSQL에 암호화 저장(PRD-tech §2, Prisma). 유저별 연동 계정 매핑.
- **웹훅 폭주 대비:** 모든 인바운드 이벤트는 우선 Redis + BullMQ 큐에 적재 후 순서보장·재시도 처리(PRD-tech §2).
- **효율:** Jira+Confluence는 **Atlassian 단일 OAuth 앱 하나**로 동시 확보 → MVP 인증 구현 부담 최소.

### 5. MVP 툴 우선순위 (PRD §6 Week1~2 정렬)

파이프라인 **방아쇠 → 뼈대 → 보정** 순으로 최소 기능 축을 세운다.

- **P0 (Week 1~2):** **Jira**(트리거의 시작점 — `In Progress` 웹훅이 전체 파이프라인을 발화) + **Confluence**
  (동일 Atlassian OAuth로 함께 확보되는 공식 명세). → PRD §6 "Atlassian OAuth" + "Jira 웹훅 핸들러"와 정확히 정렬.
- **P1 (Week 1~2 후반):** **Notion** — 기획 뼈대(Skeleton) 보강. PRD §6 "Notion API 연동".
- **P2 (Week 3~4):** **Slack** — Pivot(High) 레이어. 제품 가치의 핵심이나 Events API·스레드 파싱 복잡도가 높아
  3-Layer 오케스트레이션(Week3~4)과 함께 착수. **⚠️ 리스크:** Slack은 가중치 최상위인데 도입이 가장 늦음 →
  P0~P1 기간엔 Layer 3(Adjustment) 없이 Base+Scope만으로 플랜을 산출, Slack 합류 시 보정 활성화.

### 6. 미확정 · 리스크 (다음 스테이지로 이월)

- **Elicitation 임계값:** "광범위 영향" 판정 기준(자동 확정 vs 사용자 질문 경계)을 1-3 아키텍처에서 수치화 필요.
- **recency_factor 함수 형태:** 시간 감쇠 곡선 구체화는 2-3 LangGraph Agent 스테이지에서 결정.
- **LangGraph.js vs Python:** PRD-tech §3의 두 선택지(TS 통일 vs Hybrid) — 1-3 아키텍처 결정(⚠️ 비가역 게이트)에서 확정.
- **Slack 가중치 최상위 ↔ 도입 최후행** 긴장: P2 시점까지 pivot 부재를 감수할지, 순서 조정할지 사람 판단 필요.

## 검토 게이트 (Human Gate)

- [ ] 4각 툴의 역할과 가중치가 PRD 섹션 1의 표와 일치하는가?
- [ ] 3-Layer 병합 로직이 실제 구현 가능한 수준으로 구체화되었는가?
- [ ] Conflict Resolution 예시가 PRD 섹션 4.1의 예시를 포함하는가?
- [ ] MVP 우선순위가 PRD 섹션 6의 Week 1~2 태스크와 정렬되는가?

## 다음 단계

승인 후 → STATUS.md의 1-1을 `HUMAN_APPROVED`로 업데이트 → `02-domain-model.md`로 이동
