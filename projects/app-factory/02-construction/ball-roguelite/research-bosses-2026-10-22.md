---
artifact: research
topic: 보스·적 기믹 (Peglin·Slay the Spire·언더테일·다크 소울·핀볼 테이블) → 우리 게임 적용안
updated: 2026-10-22
status: 조사 끝 — 설계서 v2 입력
---

# 보스·적 기믹 조사

> 오너 요청(2026-10-22): 이대로면 너무 쉬워질까 걱정 → 적·보스 종류와 기믹을 늘리자. 레딧 두 글(r/DMAcademy 「gimmicks to make boss fights more interesting」, r/JRPG 「favorite boss mechanics」), 다크 소울, 언더테일 참고, 창작 가능.
> 레딧 두 글은 www·old·.json·미러 모두 접근이 막혀 읽지 못했다 → 같은 주제의 다른 글(Bell of Lost Souls, Game Developer 「Creating Cool Boss Fights」, RPGHQ 토론)로 대신했다. [확인] = 원문 확인, [일반 지식] = 원문 미확인.

## 1. 보스 기믹 패턴 15가지

| # | 패턴 | 핵심 | 출처 |
|---|---|---|---|
| 1 | 페이즈 전환 | 체력 기준을 넘으면 규칙이 바뀌어 플레이 방식도 바뀜 | StS Champ·Awakened One [확인], Game Developer |
| 2 | 듀오 · 생존자 강화 | 하나를 쓰러뜨리면 남은 쪽이 회복·강화 → 처치 순서가 선택 | 다크 소울 온슈타인과 스모우 [확인] |
| 3 | 분할체 · 회전 | 여러 몸체가 버프·회복을 주고받고 위치가 돎 | Peglin Qaballistic Ruins [확인] |
| 4 | 약점 노출 | 보호물을 깨야 약점이 드러남, 넘어뜨리면 딜 타임 | 혼돈의 요람·아이언 골렘·메타톤 EX [확인] |
| 5 | 판·환경 변형 | 전장 자체를 바꿈 | Peglin Betsy·Super Sapper·Thesaurosus [확인] |
| 6 | 타이머 · 딜 체크 | 정해진 턴 안에 잡아야 함 | StS Hexaghost [확인], Peglin Minnie [확인], 네 명의 왕 [일반 지식] |
| 7 | 습관 처벌 | 자주 하는 행동을 세어 강해짐 | StS Gremlin Nob·Awakened One·Time Eater [확인], 샌즈 KARMA [확인] |
| 8 | 누적과 폭발 | 수치가 임계값을 넘으면 큰 한 방 후 리셋 | Peglin Shield Mage [확인] |
| 9 | 규칙·조작 반전 | 조작 방식 자체를 바꿈 | 언더테일 영혼 색(언다인 초록·머펫 보라·파피루스 파랑) [확인], 애덤스 패밀리 핀볼 「Thing Flips」 [확인], Peglin Slime Boss [확인] |
| 10 | 상태 비례 | 플레이어 현재 체력에 비례한 피해 | StS Hexaghost Divider [확인] |
| 11 | 대가 있는 보호물 | 부하를 죽이면 이득과 손해가 함께 | Peglin Pigment [확인] |
| 12 | 비폭력 해결 | 싸우지 않고 끝내는 길 | 토리엘·파피루스·머펫·메타톤 시청률 [확인] |
| 13 | 메타 · 턴 조작 | 선공, 거짓 자비, 턴을 끝내지 않기 | 샌즈 [확인] |
| 14 | 실력 보상 미터 | 잘한 플레이가 쌓이면 보상 모드 | 메타톤 시청률, 블랙 나이트 2000 King's Ransom [확인] |
| 15 | 공정성 원칙 | 단순한 기믹을 겹쳐 난이도를 만들고, 이미 배운 기믹을 강화해 씀. 가짜 공격은 예비동작으로 구분 | RPGHQ·Game Developer·itch 개발자 글 |

## 2. 적용안 (조사 에이전트 초안 — 설계서 v2에서 고르고 고침)

### 일반 적 14
숲: 딱다구리 정령(플리퍼를 칠 때마다 공격 +1 — 남용 처벌) · 덩굴 도깨비(페그 둘을 덩굴로 이음, 덩굴에 닿은 구슬은 잡혔다 떨어짐, 연결 페그를 맞히면 끊기고 피해) · 꽃가루 나방(다음 턴 조준선을 짧게) · 메아리 다람쥐(마지막에 맞힌 페그 3개가 도토리 페그로 먼저 재생, 맞히면 다람쥐 회복).
동굴: 수정 박쥐(범퍼에 매달려 아래로 튕기는 역범퍼로, 두 번 맞히면 떨어짐) · 실잣는 거미(가로 줄 — 닿으면 줄 따라 미끄러짐, 양 끝 앵커 페그로 끊음) · 광맥 두더지(페그를 흙 블록으로 덮어 피해 0) · 회전석 수호자(스피너가 돌 때마다 방어 +1).
성: 행군 고수(다음 행진 두 줄, 북 타깃 셋으로 취소) · 쇠뇌 저격병(세로줄 하나를 표시, 그 줄에 남은 페그 수 × 2 피해) · 성문 열쇠지기(게이트를 뒤집음, 열쇠 페그로 복구) · 대열 방패병(약한 피해면 자리를 바꿔 대신 맞음).
공용: 그림자 손(다음 턴 플리퍼 하나를 빼앗아 자동으로 침) · 거울 도깨비(지난 턴 조준각을 복사한 거울 구슬이 먼저 떨어져 그 길의 페그를 지움).

### 엘리트 6
잠든 장승(자는 동안 피해 ×1.5, 한 발에 플리퍼 3번이면 깸) · 쌍둥이 버섯술사(홍: 포자 페그로 구슬 감속 / 청: 매 턴 재생, 하나가 죽으면 남은 쪽이 둘 다 씀) · 울림수정 골렘(수정 수 × 5 방어, 100을 넘으면 폭발) · 모래시계 박쥐왕(플리퍼 8번마다 발 강제 종료 + 힘) · 감시 석상 셋(구역 셋, 구역마다 드롭 타깃 세트로 기절) · 분노의 창기사(특수 장치가 작동할 때마다 힘 +2).

### 보스 9 (지역마다 셋 중 하나)
숲: 고목 어미(좌우 수액 구슬 둘을 깨면 심장 옹이 페그 노출 ×5, 2페이즈 심장 이동) · 도깨비 형제(앞에 선 쪽만 피해, 2턴마다 자리 바꿈, 생존자 강화) · 산신령(비폭력: 매 턴 시험, 세 번 통과하면 축복으로 끝).
동굴: 모래울음(플리퍼 12번마다 발 종료 + 힘, 50%에서 한 번 되감기) · 사방석 수호상(네 모서리 핵 페그가 매 턴 회전, 색마다 역할) · 금비늘 용(발톱 뒤 판 섞기, 30%에서 보물 폭발 — 3턴 동안 멀티볼·받는 피해 ×2).
성: 철갑 거인(아래 좌우 드롭 타깃 = 발목, 화살비 턴 — 구슬 대신 떨어지는 화살을 플리퍼로 쳐 냄) · 가면극단장(관객 미터 — 랠리로 오름, 1만이면 비폭력 승리) · 재의 군주(0에서 부활, 2페이즈 첫 행동은 현재 체력 비례 심판).

## 3. 공정하게 어렵게 만드는 규칙
- 판 변형은 최소 1턴 전에 아이콘 + 남은 턴 + 대상 하이라이트로 예고. 구슬이 도는 도중에는 규칙이 바뀌지 않는다(적 턴에만).
- 횟수를 세는 처벌은 숫자를 실시간으로 보여 준다(습관 처벌은 경고가 보일 때만 공정).
- 한 전투에 새 기믹은 2개까지. 엘리트·보스는 이미 배운 기믹의 강화판.
- 모든 기믹은 기존 도구(조준선·플리퍼·타깃·멀티볼)로 풀린다.
- 원정 등급 후보: 예고 1턴 단축(최소 1) · 일반 전투 적 +1 · 플리퍼 횟수 임계값 −2 · 지역 기믹 강화 · 엘리트·보스가 기믹을 깔고 시작 · 생존자 회복 50→75% · 보스 2페이즈 체력 +20% · 아웃레인 넓힘 · 판 변형 범위 +1 · 비폭력 요구치 상향.

## 출처
belloflostsouls.net/?p=378196 · gamedeveloper.com/design/creating-cool-boss-fights · rpghq.org/forums/viewtopic.php?p=34811 · itch.io/post/10881051 · peglin.wiki.gg(Category:Bosses·Minibosses·Super_Sapper·Pigment_of_Imagination·Betsy_the_Leshy·Thesaurosus·Slime_Boss·Shield_Mage·Qaballistic_Ruins·Minnie_the_Minotaur) · slaythespire.wiki.gg(Bosses·Time_Eater·Gremlin_Nob·Awakened_One·The_Champ·Hexaghost) · undertale.wiki(Undyne·Sans·Muffet·Papyrus·Toriel /In_battle, Mettaton_EX) · pushsquare.com(Ornstein and Smough) · pockettactics.com/dark-souls/bosses · en.wikipedia.org(Black_Knight_2000, The_Addams_Family_(pinball)) · bmigaming.com black_knight_2000 rulesheet
