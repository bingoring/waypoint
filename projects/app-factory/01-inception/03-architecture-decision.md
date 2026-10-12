---
phase: 01-inception
stage: 03-architecture-decision
status: PENDING
updated: 2026-10-13
---

# [Stage 1-3] Architecture Decision ⚠️ 비가역 게이트

## 목적

App Factory의 기술 스택과 저장소 구조를 확정한다. 이 결정은 모든 Construction 스테이지와 앞으로 만들 모든 앱의 기반이 되므로,
번복하면 코어와 출시된 앱 전체를 다시 만들어야 한다.

## 입력 (Inputs)

- [`02-domain-model.md`](02-domain-model.md) (HUMAN_APPROVED 필요)
- [`01-context-synthesis.md`](01-context-synthesis.md) §2 외부 제약, §6 공통 모듈 요구사항
- [`../DECISIONS.md`](../DECISIONS.md) — 사용자 선호: Flutter + Melos

## 체크리스트

- [ ] 프레임워크: Flutter + Melos 확정 (React Native·Expo 대비 탈락 이유 문서화). 현재 안정 버전은 Context7·공식 문서로 확인
- [ ] 모노레포 구조: `packages/`(코어·게임 키트) / `apps/`(앱별 프로젝트) 경계
- [ ] 앱 분리 방식: 앱마다 독립 Flutter 프로젝트 vs 하나의 프로젝트 + flavor (포트폴리오 규칙 P3, 서명 키 분리, 빌드 시간 관점)
- [ ] 상태 관리 (Riverpod / Bloc / 기타)
- [ ] 게임 구현 방식: Flame 엔진 vs 순수 Flutter 위젯·CustomPainter
- [ ] 광고·동의·분석·원격 설정·인앱결제 라이브러리 선정과 버전
- [ ] 빌드·배포: fastlane / GitHub Actions / Codemagic 비교, 서명 키 보관 방식
- [ ] 각 결정의 대안 탈락 이유 문서화

## AI 제안 (AI Proposal)

> ⚠️ 이 섹션은 AI가 작성합니다. 사람이 직접 수정하지 마세요.

*[1-2 승인 후 작성]*

## 검토 게이트 (Human Gate)

### 기본 게이트
- [ ] 모든 기술 결정이 내려졌는가?
- [ ] 1-2 도메인 계약을 이 구조로 구현할 수 있는가?

### 비가역성 확인 ⚠️
- [ ] 이 결정을 번복할 경우 영향받는 파일/레이어 목록을 작성했는가?
- [ ] 대안 기술 스택을 검토하고 탈락 이유를 문서화했는가?
- [ ] 외부 의존성(AdMob·Firebase·스토어 계정) 및 비용 구조를 확인했는가?
- [ ] Flutter·Melos 생태계 lock-in을 수용할 수 있는가?

## 다음 단계

승인 후 → `STATUS.md`에서 1-3 상태를 `HUMAN_APPROVED`로 업데이트 → Phase 2 스테이지 목록 확정 → Construction 시작
