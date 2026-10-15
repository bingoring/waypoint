---
build-spec: puzzle
stage: 02-construction/07-game-kit-puzzle
status: READY
depth: comprehensive
updated: 2026-10-15
---

# Build Spec — Game Kit + 조각보 블록 퍼즐

## §0. 개요 & 범위
- **목표(한 줄):** 코어 패키지 `factory_game_kit`(결정적 난수·최고점·저장·보상형·전환 광고·피드백·공유)과 그 첫 소비자인 8×8 블록 퍼즐 `apps/bojagi`(클래식·오늘의 판·레벨 100), ko·en.
- **SoT:** 1-1 §7(퍼즐·게임 키트), 1-2 §4·§10(퍼즐 placements), 1-3 A6(순수 Flutter)·§7(게임 예산), DECISIONS 2026-10-15(보류·장르·범위·효과음·레벨·이어하기·오늘의 판).
- **규모/제약:** 완전 오프라인, 서버 0원, 추가 권한 없음, 다운로드 ≤ 25MB, PSS ≤ 300MB(G1 게임).
- **깊이 티어 & 사유:** `comprehensive` — 새 코어 패키지와 게임 규칙·레벨 생성기·드래그 상호작용이 함께 들어간다(4개 아티팩트 + NFR).

## §1. 분해

| 단위 | 쪽 | 책임 |
|---|---|---|
| `packages/factory_game_kit` | 코어 | `SplitMix64`·`dailySeed`, `BestScores`, `SaveSlot`, `RewardGate`, `RoundAds`, `GameFeedback`, `ShareGrid` (화면 없음) |
| `apps/bojagi/lib/domain/` | 앱 | 판·조각 표·배분·놓기·지우기·점수·이어하기·레벨 목표 — 순수 Dart |
| `apps/bojagi/lib/data/` | 앱 | 게임 상태 JSON, 레벨 매니페스트 읽기, 레벨 진행·오늘의 판 기록 |
| `apps/bojagi/lib/ui/` | 앱 | 메뉴·게임판·결과·레벨 지도·설정, `BoardPainter`·`PieceWidget`·`QuiltMap`, 문구 ko·en |
| `apps/bojagi/tool/build_levels.dart` | 앱(오프라인) | 레벨 100 생성 + 봇 검사 → `assets/levels.json` |
| `apps/bojagi/tool/gen_sfx.dart` | 앱(오프라인) | 효과음 WAV 5개 합성 → `assets/sfx/` |

## §2. 아티팩트 인덱스

| 아티팩트 | 상태 | 링크 |
|---|---|---|
| research | ✅ | [`research-genre-2026-10-15.md`](research-genre-2026-10-15.md) |
| domain-entities | ✅ | [`domain-entities.md`](domain-entities.md) |
| business-rules | ✅ | [`business-rules.md`](business-rules.md) |
| business-logic-model | ✅ | [`business-logic-model.md`](business-logic-model.md) |
| frontend-components | ✅ | [`frontend-components.md`](frontend-components.md) |

## §3. 미해결 질문

- [x] 장르 → 블록 퍼즐 8×8 (2026-10-15)
- [x] 범위 → 클래식·오늘의 판·레벨, 공정 배분, 이어하기·다시 받기, 조각보 테마 (2026-10-15)
- [x] 효과음 켬, 레벨 100, 이름 「조각보 블록 퍼즐」 (2026-10-15)
- [x] 이어하기 = 가장 많이 찬 줄 3개, 오늘의 판 = 보조 없음·첫 판, 레벨 목표 3종 (2026-10-15)
- [x] 패키지 → `audioplayers` 6.8.1(2026-06-27) 정확히 고정(`flutter_soloud`는 5.2.x가 2주 미만이고 효과음 5개에 무겁다), `share_plus` 13.3.0
- [ ] (권장, READY를 막지 않음) 「조각보」 상표 KIPRIS 확인(9·41류) — 이름이 `app.yaml`·스토어에 들어가기 전
- [x] `READY` 승인 (2026-10-15)

## §4. 구현 체크리스트

- [ ] `factory_game_kit` 패키지 + 테스트(골든 난수·저장 버전·보상 게이트·전환) + `check_deps` 규칙
- [ ] `factory new bojagi --category game --name-ko "조각보 블록 퍼즐" --name-en "Bojagi Block Puzzle"` · `factory firebase bojagi`
- [ ] `app.yaml`: 시드 #A8432A, placements `banner_menu`·`interstitial_round_end`(everyN 2)·`rewarded_continue`·`rewarded_refresh`, keyAction `finish_round`, events
- [ ] domain: 판·조각 37개·배분·놓기·지우기·점수·이어하기·레벨 목표 + 골든·속성 테스트(BLM §1.3)
- [ ] `tool/gen_sfx.dart` → `assets/sfx/*.wav`
- [ ] `tool/build_levels.dart` → `assets/levels.json`(100, 모두 봇 클리어) + 결정성 테스트
- [ ] data: 상태 저장·복원(수마다), 레벨 진행, 오늘의 판 기록
- [ ] UI: 메뉴·게임판(끌어 놓기)·결과·레벨 지도·설정, ko·en
- [ ] 위젯 테스트: 끌어 놓기 → 줄 지우기 → 점수, 게임 끝 → 결과 → 이어하기, 다시 하기에서만 전면 광고 판정, 오늘의 판 보조 없음, 앱 재시작 뒤 판 복원, 누수 0
- [ ] store 문구(ko·en)·data-safety·개인정보처리방침 → `sync_site`
- [ ] 릴리스 리허설: 키·AAB·`size`·`validate --release`

## §5. 검증 계획
- [ ] 분석·포맷·의존 검사·`validate`, 코어 패키지 커버리지 게이트(라인 ≥ 90%)
- [ ] 규칙 골든·속성(공정 배분 1,000판), 오늘의 판 결정성, 레벨 100 봇 기록
- [ ] 에뮬레이터(재부팅·`-gpu host`): 전 화면 ko·en, 프롬프트 5단계 검사, 드래그 중 프레임(§6)
- [ ] G1 측정 절차: PSS ≤ 300MB, 콜드 스타트, 다운로드 ≤ 25MB
- [ ] 실기기(3-1): 드래그 손맛·지연, 효과음 지연

## §6. NFR

| 항목 | 목표 | 측정 |
|---|---|---|
| 드래그 프레임 | 끌기 중 프레임 ≤ 16ms(UI·래스터), 그림자 계산은 칸이 바뀔 때만 | 프로파일 빌드 `gfxinfo`(에뮬레이터 `-gpu host`), 실기기 3-1 |
| 메인 isolate | 한 수 처리 < 1ms, 16ms 넘는 작업 없음(레벨 검사는 오프라인 도구) | 단위 테스트 시간 상한 |
| 저장 | 수마다 저장, 강제 종료 뒤 그 수부터 복원 | 위젯 테스트 + 에뮬레이터 강제 종료 |
| 결정성 | 같은 시드·같은 수 → 같은 배분(버전 무관 난수) | 골든 테스트 |
| 메모리·시작 | PSS ≤ 300MB(게임), 콜드 스타트 ≤ 1.5초 | G1 측정 절차 |
| 크기 | 다운로드 ≤ 25MB(효과음·레벨 포함) | `factory size` |
| 오프라인 | 모든 모드가 네트워크 없이 동작(광고만 비어 있음) | 비행기 모드 수동 |
| 광고 정책 | 전면은 결과 → 다음 판에서만·2번에 1번, 보상은 버튼에 명시·거절 가능 | 위젯 테스트 + 5단계 검사 |

## §7. 편차 로그

| SoT | 실제 구현 | 사유 |
|---|---|---|
| 1-2 §10 퍼즐 `rewarded_hint` | `rewarded_refresh`(조각 다시 받기) | 블록 퍼즐에서 힌트보다 쓰임새가 분명하다(DECISIONS 2026-10-15) |
| 1-1 Q6 순서(물 마시기 → 퍼즐) | 퍼즐 먼저, 물 마시기 보류 | DECISIONS 2026-10-15 |
| 시드 색 | 생성기 제안 → #A8432A | FC §5 |
