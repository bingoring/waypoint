# 「구르는 영웅」 짧은 런 시제품 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 숲 한 지역 13마디(일반 전투 8 · 이벤트 2 · 상점 · 쉼터 · 보스)를 영웅 둘 · 튕겨 나가기 규칙으로 끝까지 해 볼 수 있는 웹 시제품을 만든다.

**Architecture:** 골프 시제품의 결정적 물리(`golf-sim.js`)를 복사해 `hero-sim.js`로 넓히고(부딪힘 = 튕겨 나감, 영웅 특성, 적, 유물), 판 틀은 `hero-boards.js`, 마디 · 보상 · 상점 · 이벤트는 `hero-run.js`(DOM 없음)에 둔다. `hero.html`은 그림과 입력만 맡는다. 봇(`hero-bot.js`)이 같은 코드를 화면 없이 돌려 판이 깨지는지와 런 길이를 잰다.

**Tech Stack:** 순수 JavaScript(UMD: 브라우저 `window.*`, node `module.exports`), `node --test`, 캔버스 180×320.

**Spec:** [`hero-run-2026-11-13.md`](hero-run-2026-11-13.md) (조사: [`research-run-structure-2026-11-13.md`](research-run-structure-2026-11-13.md))

## Global Constraints

- 작업 위치: app-factory 워크트리 `~/private/app-factory-golf`, 브랜치 `ball-roguelite/hero-run`(`ball-roguelite/golf-proto` 위). 파일은 `prototypes/ball-roguelite/` 아래.
- `golf-sim.js` · `golf.html` · `index.html` · `lab/`는 고치지 않는다(비교용으로 남김). 골프 시험 23개는 계속 통과해야 한다.
- 물리는 결정적이다: `DT = 1/240`, 같은 입력이면 같은 결과. 무작위는 런의 시드 RNG(mulberry32)로만.
- 커밋 메시지에 `Co-Authored-By` · `Generated with Claude Code` 트레일러를 넣지 않는다(waypoint CLAUDE.md, 훅이 거부).
- waypoint를 먼저 커밋 · 푸시하고, 그다음 app-factory의 `docs/dlc` 포인터를 커밋한다. 푸시 전 `git pull --rebase`.
- 화면 글은 한국어. 대가가 있는 버튼은 대가를 버튼 글에 적는다.

## Review Focus

1. **튕김이 끝나지 않는 경우:** 두 적 사이나 적과 벽 사이에 끼어 계속 부딪히는 공 — 샷은 `MAX_T`(15초) 안에 반드시 끝나야 하고, 같은 적은 떨어졌다가 다시 닿아야만 또 맞는다.
2. **분신과 끝내기:** 본체가 먼저 멈추고 분신이 아직 구를 때, 분신이 마지막 적을 쓰러뜨릴 때, 분신이 물에 빠질 때 — 샷은 모든 공이 멈춰야 끝나고, 영웅은 늘 본체 자리에 선다.
3. **영웅 칸이 찼을 때 새 영웅:** 보상 · 상점 · 이벤트 어디서 얻든 내보낼 칸을 고르거나 받지 않을 수 있어야 하고, 지금 고른 영웅을 내보내도 다음 샷이 다른 칸으로 넘어가야 한다.
4. **보상이 비는 경우:** 남은 유물이 셋보다 적거나 모든 영웅이 Lv2일 때 — 카드 수가 줄어도 멈추지 않고, 「건너뛰기」가 늘 있다.
5. **금화 부족 · 체력 대가:** 상점과 이벤트에서 금화나 체력이 모자라면 그 버튼은 눌리지 않는다. 체력 대가로 체력이 0이 되는 선택은 막는다.

---

### Task 1: `hero-sim.js` 바탕 — 샷 셋 · 튕겨 나가기 · 끝내기

**Files:**
- Create: `prototypes/ball-roguelite/hero-sim.js`, `prototypes/ball-roguelite/hero-sim.test.js`

**Interfaces:**
- Produces: `Hero = { W, H, DT, BALL_R, START_POWER, SHOTS, GROUND, ENEMY, HEROES, makeFight(spec), clone(s), terrainAt(s,x,y), startShot(s, input, mods), step(s, sh), runShot(s, input, mods), preview(s, input, mods), enemyTurn(s) }`.
  - `input = { shot: 'roll'|'dash'|'leap', angle, power, hero: { kind, lv } }`, `mods = { relics: string[], startBonus: number }`(생략하면 빈 값).
  - `makeFight(spec)` 상태: `{ ball:{x,y}, hero:{hp,maxHp}, walls, zones, trees, crystals, rings, jars, enemies:[{id,kind,x,y,hp,maxHp,r,h,z0?}], over:null, shots:0, spawnTurn:0 }`.
  - `runShot` 반환: `{ events, end:{x,y}, splash, kills, hits, power }`. 이벤트 종류: `land · wall · tree · crystal · ring · jar · hit{id,dmg,dead,x,y} · clone · explode · splash · stop · win`.

- [ ] **Step 1: 실패하는 시험 쓰기** — `SHOTS`가 굴러가기 0° · 180, 돌진 18° · 240 · 0.85 · 0.3, 뛰어오르기 55° · 200 · 0.6 · 0.12. 슬라임 정면으로 굴러가기 → `hit` 이벤트 피해 3, 적 체력 5, 영웅 속도 30% 줄고 반대쪽으로 튕김, 멈춰도 `explode` 없음. 같은 적에 붙은 채 두 번 맞지 않음. 슬라임 둘 사이에 끼워도 15초 안에 끝남. 마지막 적이 쓰러지면 `win` 이벤트로 바로 끝나고 `s.over === 'win'`. 물에 빠지면 친 자리로, 준 피해는 남고 결정은 되살아남. 결정 +1 · 고리 ×2 · 단지 ×3은 골프와 같음.
- [ ] **Step 2: 돌려서 실패 확인** — Run: `node --test hero-sim.test.js` / Expected: FAIL(`Cannot find module './hero-sim.js'`).
- [ ] **Step 3: 구현** — `golf-sim.js`를 복사해 공을 `sh.balls[]` 배열로 바꾸고, 적 닿음을 「피해 → 원 법선 반사(반발 1) → 속도 ×(1 − 0.3) → `touching` 집합에 적 id 넣기(떨어지면 뺌)」로 바꾼다. 멈춤 = `stop` 이벤트만.
- [ ] **Step 4: 통과 확인** — Run: `node --test hero-sim.test.js golf-sim.test.js` / Expected: 모두 PASS.
- [ ] **Step 5: 커밋** — `prototype(ball-roguelite): 구르는 영웅 물리 바탕 — 샷 셋 · 튕겨 나가기`

### Task 2: 영웅 여섯

**Files:** Modify `hero-sim.js`, `hero-sim.test.js`

**Interfaces:**
- Produces: `HEROES[kind] = { name, loss, crystal, vmul, leapMul, startBonus(lv), ... }` — kind는 `knight · mushroom · acorn · anchor · frog · bomb`.

- [ ] **Step 1: 실패하는 시험** — 기사 Lv2 시작 힘 4. 버섯 튕김 뒤 속도 0.9배(Lv2 0.95). 도토리: 첫 닿음에 `clone` 이벤트 하나, 분신 힘 = 시작 힘, 분신은 들어온 방향 ±35°, 속도 0.8배, 분신은 갈라지지 않음, Lv2는 두 번째 닿음에서 하나 더. 샷 끝에 `s.ball`은 본체가 멈춘 자리. 분신이 마지막 적을 쓰러뜨려도 `win`. 닻: 결정 +2(Lv2 +3), 세기 ×0.85, 튕김 손실 0.55. 개구리: 뛰어오르기 vmax ×1.2, 물 = 풀숲 감속으로 빠지지 않음, Lv2 단지 배율 +1. 폭탄: 닿음 피해 올림(힘/2), 멈추면 반경 24(Lv2 32) `explode`.
- [ ] **Step 2: 실패 확인** — Run: `node --test hero-sim.test.js` / Expected: 새 시험 FAIL.
- [ ] **Step 3: 구현** — 영웅 표를 `HEROES`에 두고 `startShot`이 `input.hero`로 공의 성질을 정한다.
- [ ] **Step 4: 통과 확인** — Expected: PASS.
- [ ] **Step 5: 커밋** — `prototype(ball-roguelite): 구르는 영웅 — 영웅 여섯(기사 · 버섯 · 도토리 분신 · 닻 · 개구리 · 폭탄)`

### Task 3: 적 다섯 · 적 턴

**Files:** Modify `hero-sim.js`, `hero-sim.test.js`

- [ ] **Step 1: 실패하는 시험** — `ENEMY` 값은 설계 §7 그대로. 말벌은 높이 6~24에서만 닿음(굴러가기는 아래로 지나감, 뛰어오르기 중간에 맞음). 멧돼지는 닿을 때마다 피해 −2(최소 1). 적 턴: 슬라임 12 다가와 16 안 때림 2 · 사수 80 안 3 · 말벌 20 날아와 14 안 2 · 멧돼지 18 다가와 18 안 4 · 왕 슬라임 8 다가와 24 안 4, 짝수 턴마다 슬라임 둘(살아 있는 슬라임 6이 상한, 자리는 왕 양옆으로 정해진 값). 체력 0이면 `over = 'lose'`.
- [ ] **Step 2 ~ 4:** 실패 확인 → 구현 → `node --test hero-sim.test.js` PASS.
- [ ] **Step 5: 커밋** — `prototype(ball-roguelite): 구르는 영웅 — 적 다섯(말벌 · 투구 멧돼지 · 왕 슬라임)`

### Task 4: 유물 효과(물리 쪽) · 조준 미리보기

**Files:** Modify `hero-sim.js`, `hero-sim.test.js`

**Interfaces:**
- Produces: `preview(s, input, mods)` → `{ land: {x,y}|null, path: [{x,y,z}] (처음 0.5초), firstHit: enemyId|null }`. 화면은 가진 조준 유물(`scope` 망원경 · `firefly` 반딧불 등 · `stars` 별자리 지도)에 따라 골라 그린다.
- 유물 키: `scope · firefly · stars · medal · chain · rubber · goldbag · jarlid · whetstone · magnet`(medal · goldbag은 런 쪽에서 셈).

- [ ] **Step 1: 실패하는 시험** — `chain`: 닿을 때마다 힘 +1(다음 닿음부터 반영). `rubber`: 튕김 손실 절반. `jarlid`: 단지 ×4. `whetstone`: 고리 ×3. `magnet`: 결정을 먹는 거리 +3. `preview`는 상태를 바꾸지 않고, 실제 `runShot`의 첫 착지 · 첫 닿은 적과 같다(결정성).
- [ ] **Step 2 ~ 4:** 실패 확인 → 구현 → PASS.
- [ ] **Step 5: 커밋** — `prototype(ball-roguelite): 구르는 영웅 — 유물 물리 효과 · 조준 미리보기`

### Task 5: 판 틀 `hero-boards.js`

**Files:** Create `prototypes/ball-roguelite/hero-boards.js`, `hero-boards.test.js`

**Interfaces:**
- Produces: `HeroBoards = { LAYOUTS (4), BOSS, groupFor(depth, kind:'fight'|'elite'|'boss'), makeBoard(layoutIndex, depth, kind, rng) → spec }`. `spec`는 `Hero.makeFight`가 받는 모양. `depth`는 전투 번호(1~9), 적 체력 ×1.06^(depth−1)(반올림).

- [ ] **Step 1: 실패하는 시험** — 판마다 적은 물 · 나무 · 단지 안에 서지 않고, 시작 자리(아래 가운데)에서 반경 40 안에 적이 없음. 깊이 1~2 슬라임 셋, 3~5 슬라임 + 사수, 6~8 말벌 포함, 엘리트는 멧돼지 + 슬라임 둘, 보스는 왕 + 슬라임 둘. 같은 rng 상태면 같은 판.
- [ ] **Step 2 ~ 4:** 실패 확인 → 구현(틀: 숲길 · 연못 · 갈림 숲 · 단지 마당 + 보스 공터) → PASS.
- [ ] **Step 5: 커밋** — `prototype(ball-roguelite): 구르는 영웅 — 판 틀 넷 · 보스 판 · 깊이별 적 무리`

### Task 6: 런 `hero-run.js`

**Files:** Create `prototypes/ball-roguelite/hero-run.js`, `hero-run.test.js`

**Interfaces:**
- Consumes: `Hero.makeFight`, `HeroBoards.makeBoard`, `HEROES`, 유물 키.
- Produces: `HeroRun = { ROUTE, RELICS, EVENTS, newRun(seed), view(run), chooseDoor(run,i), startFight(run) → fightState, mods(run), endFight(run, fightState, log), pick(run, cardIndex|'skip', replaceSlot?), shopBuy(run, itemIndex, replaceSlot?), shopReroll(run), leave(run), eventChoose(run, buttonIndex, arg?), restChoose(run, 'heal'|'upgrade', slot?), setActive(run, slot) }`.
  - `run.phase`: `'door' | 'fight' | 'reward' | 'shop' | 'event' | 'rest' | 'over'`. `run.result`: `'win' | 'lose' | null`.
  - `log = { shotsByHero: {kind:n}, shots, killsByShot: number[] }`.

- [ ] **Step 1: 실패하는 시험** — 시작: 기사 하나, 체력 20, 금화 0. 1번 보상은 영웅 카드 셋. 마디 순서가 설계 §6 표와 같다. 문 마디는 문 둘에 보상 종류가 보임, 7 · 10번 엘리트 규칙(둘 다 안 나오면 10번에 반드시). **어떤 시드 50개 · 어떤 문 선택으로도 일반 전투가 6번 이상**(모든 문 조합을 따라가 셈). 금화: 처치 +3, 한 샷 둘째부터 +2(금화 자루면 +4), 꾸러미 +25, 엘리트 +15. 일반 전투 승리 체력 +2(최대 넘지 않음). 훈장 주머니: 처치 5마다 `startBonus +1`. 상점 값 §6.2, 다시 굴리기 5 → 10 → 15, 금화 모자라면 거절. 이벤트 넷의 대가와 결과, 체력 대가로 0이 되면 거절. 쉼터 회복 = 최대 체력 30%(올림). 영웅 칸이 찼을 때 교체 · 거절. 같은 영웅을 또 얻으면 Lv2. 보상 카드가 셋보다 적어도 동작.
- [ ] **Step 2 ~ 4:** 실패 확인 → 구현 → `node --test hero-run.test.js` PASS.
- [ ] **Step 5: 커밋** — `prototype(ball-roguelite): 구르는 영웅 — 숲 13마디 런(문 · 보상 · 상점 · 이벤트 · 쉼터)`

### Task 7: 봇 · 측정 · 값 맞추기

**Files:** Create `prototypes/ball-roguelite/hero-bot.js`(node 전용 측정 스크립트)

- [ ] **Step 1:** 최선 봇(영웅 둘 × 샷 셋 × 방향 36 × 세기 5를 훑어 「준 피해 + 처치 × 10 − 다음 적 턴 피해 × 3」이 가장 큰 샷)과 흔들린 봇(같은 선택에 ±4° · ±0.05)으로 시드 20개 런을 돌린다. 보상 · 상점 · 이벤트는 간단한 규칙(영웅 먼저, 유물, 체력 낮으면 회복)으로 고른다.
- [ ] **Step 2:** 결과 표: 런 클리어 · 전투당 샷 · 영웅별 샷 비율 · 진 마디 · 금화 흐름. Expected 목표(제안): 최선 봇 클리어 90% 이상, 흔들린 봇 30~70%, 전투 하나 4~6샷.
- [ ] **Step 3:** 목표에서 벗어나면 적 체력 배율 · 판 틀 · 금화 값을 고치고 다시 잰다. 바꾼 값은 모두 ledger에 Ruling으로 적는다.
- [ ] **Step 4: 커밋** — `prototype(ball-roguelite): 구르는 영웅 — 봇 측정 · 값 맞춤`

### Task 8: 화면 `hero.html`

**Files:** Create `prototypes/ball-roguelite/hero.html`

- [ ] **Step 1:** 골프 화면의 그리기 · 입력 · 시간 기준 재생(`PLAY = 1.25`)을 가져와, 위 마디 띠 · 체력 · 금화 · 시작 힘 · 유물, 아래 영웅 두 칸 · 샷 셋, 패널(문 · 보상 · 상점 · 이벤트 · 쉼터 · 결과)을 만든다. 영웅 여섯은 색과 모양으로 구분(깡통 기사 = 둥근 투구). 분신은 반투명. 조준 유물이 있을 때만 미리보기를 그린다.
- [ ] **Step 2:** 결과 화면: 영웅별 샷 수 · 전투별 샷 수 · 걸린 시간. 시험용 「○번 마디부터」 · 시드 고정(`?seed=`).
- [ ] **Step 3: 브라우저 확인(375px)** — 13마디를 끝까지 지나가기(콘솔 `heroAuto()`로 봇이 치게 해도 됨), 콘솔 오류 없음, 스크린샷.
- [ ] **Step 4: 커밋** — `prototype(ball-roguelite): 구르는 영웅 짧은 런 화면`

### Task 9: 기록 · 푸시

- [ ] waypoint `15-ball-roguelite.md` §38에 구현 결과 · 측정 · 거친 점을 적고, STATUS를 고친다. waypoint 커밋 · 푸시 → app-factory `docs/dlc` 포인터 커밋 → `ball-roguelite/hero-run` 푸시.
