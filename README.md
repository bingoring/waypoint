# Waypoint

AI 제안 → 사람 승인 게이트 기반의 Markdown 문서 중심 개발 라이프사이클 프레임워크.

## 개념

각 개발 단계는 하나의 Markdown 문서로 표현된다. AI가 문서를 작성하면 사람이 검토·승인해야 다음 단계로 진행된다. 문서 자체가 단일 진실 공급원(Single Source of Truth)이다.

## 구조

```
waypoint/
├── FRAMEWORK.md          ← AI 규칙·컨벤션 계약서
├── STATUS.template.md    ← 프로젝트 대시보드 템플릿
├── _templates/           ← 범용 문서 골격
└── projects/
    └── {project-name}/   ← 프로젝트별 스테이지 문서
```

## 새 프로젝트에 적용하기

```bash
# 1. 프로젝트 레포에서
git submodule add https://github.com/bingoring/waypoint docs/dlc

# 2. Waypoint 레포에 프로젝트 디렉토리 생성
cd docs/dlc
mkdir -p projects/myapp/01-inception
mkdir -p projects/myapp/02-construction
mkdir -p projects/myapp/03-operations
cp STATUS.template.md projects/myapp/STATUS.md
# 이후 _templates/stage-template.md를 참고해 스테이지 문서 작성
```

## 3단계 라이프사이클

- **Phase 1 — Inception (What):** 기획, 도메인 모델, 아키텍처 결정
- **Phase 2 — Construction (How):** 레이어별 구현 계획
- **Phase 3 — Operations (Ship):** 배포 및 운영
