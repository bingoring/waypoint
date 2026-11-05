# 빌드 계열 · 런 구조 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 확정된 빌드 계열 설계(계열 17 · 단계 2/4/6 · 계열 잇기 · 지역 상성 · 4지역 런 구조)를 프로토타입에 단계별로 넣는다. 이 문서는 전체 순서(10덩어리 — 2026-11-04 P1b · P7b 추가)와 첫 덩어리 **P1 런 구조**의 상세 작업을 담는다.

**Architecture:** 한 파일 프로토타입 `prototypes/ball-roguelite/index.html`(약 3,300줄, 순수 JS + 캔버스)에 진형 규칙(`S.foe === 'rank'`)에서만 켜지는 경로로 넣는다. 이전 규칙(v1)은 그대로 두고 같은 시드 봇 지문으로 확인한다(§24~§27 방식). 시험은 `lab/*.js`(Node, `lab/load.js`가 스크립트를 화면 없이 띄움).

**Tech Stack:** 순수 JavaScript(브라우저 · Node 24), 캔버스 2D, 외부 의존 없음.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) — 특히 §2(세는 방식·단계·보상 끌림), §3(계열 17), §5-1(런 구조), §5-2(고르는 머리), §7(정한 것).

## Global Constraints
- 새 규칙은 모두 `S.foe === 'rank'`에서만. 이전 규칙 봇 지문 `FOE=v1 PICK=mixed` 40런 = `fdf868b7bc18e2e04d7e176a25b21310e2286ac3`(21승)이 바뀌면 안 된다.
- `selfTest()` 17조합은 결정성(`same`·`angleDiffers`)이 유지되어야 한다.
- 커밋 메시지에 `Co-Authored-By`·`Generated with Claude Code` 트레일러 금지(훅이 거부). 문서는 waypoint(`docs/dlc`) 먼저 커밋·푸시 → 앱 저장소에서 서브모듈 포인터. 작업 시작·푸시 전 `git pull --rebase`.
- 커밋 메시지 형식: `prototype(ball-roguelite): …` / `docs: waypoint 서브모듈 갱신(…)`.
- 화면 글은 한국어, 구슬·유물 이름은 지금 것 그대로.
- 런 구조(§5-1): 지역 하나 = 일반 → 일반 → 갈림길 → 엘리트 → 일반 → 쉼터 → 보스. 보상: 일반 = 구슬·강화·복제·유물을 섞은 무작위 3장 중 하나, 엘리트 = 유물 3장 중 하나, 보스 = 구슬 하나 + 유물 하나(마지막 보스 제외).

## Review Focus
- **시험용 「○부터」 버튼과 진형 후보 버튼(`restart(i)`·`restartPickR(i, j)`)** — 진형에서는 마디(node) 번호가 바뀐다. 갈림길·쉼터 마디부터 시작해도 멈추지 않고 그 마디 화면이 떠야 한다. (P1 Task 1·3 시험)
- **유물 더미가 3장보다 적을 때**(유물을 거의 다 가진 런) — 보상이 2장·1장이어도, 0장이면 「건너뛰기」만 떠도 멈추지 않아야 한다. (P1 Task 2 시험)
- **쉼터 「버리기」로 가방을 비우는 경우** — 4칸 가방은 늘 4칸이 차 있어야 하므로 버린 칸은 조약돌이 된다. 조약돌만 남은 가방에서 버리기는 고를 수 없다. (P1 Task 3 시험)
- **봇이 새 마디(갈림길·쉼터·보스 두 번 고르기)를 만나도 런을 끝까지 돈다** — `UI.fork`·`UI.rest`·두 번째 보상을 봇이 덮어쓰지 않으면 런이 그 자리에서 멈춘다. (P1 Task 4 시험)
- **조합별 패배 집계(`lab/foebot.js`의 `combos`)** — `FIGHTS` 이름으로 세던 것을 마디 이름으로 바꾸지 않으면 새 전투가 집계에서 빠진다. (P1 Task 4)

---

## 전체 순서 (10덩어리 — 덩어리마다 따로 계획을 쓰고, 끝날 때마다 플레이 가능)
| # | 덩어리 | 끝나면 되는 것 | 설계 절 |
|---|---|---|---|
| **P1** | **런 구조**(이 문서) | 3지역 × 7마디(21마디 · 18전투), 갈림길·쉼터, 섞인 보상, 엘리트 유물, 보스 구슬 + 유물, 봇이 끝까지 돎 | §5-1 |
| **P1b** | **고르는 머리 바탕** | 구슬 순서 고르기(한 바퀴 안에서 남은 칸 중 고름 · 화면 버튼 · 봇은 지금의 섞인 순서를 기본으로) · 「아끼는 구슬」 유물 · 페그 늘리기(장치 판 페그 약 60 → 100~120, 작은 크기를 진형 기본으로) + 적 체력·한 발 시간 다시 맞춤 · 단지 복사본 힘 나누기 실험 설정(기본 꺼짐) | §5-2 가 · 다 · 라 |
| **P2** | **계열 틀**(2026-11-05 계획) | 계열 17 표 · 아이템마다 계열 · 개수 세기 · 단계 2/4/6 갈고리 · 계열 고르게 뽑기 · 보상 끌림 1.5/2.5배 · 열쇠 없는 보상 막기 · 갈림길 「계열 문」 · 계열 봇(`PICK=family`) · 화면에 계열 단계 · 이전 태그/변신은 v1에만 | §2 · §3-1 · §7 |
| P3 | 판을 바꾸는 계열 | 기계 · 화상 · 얼음 · 페그 밭(씨뿌리개 구슬) | §3 |
| P4 | 상태이상 · 공격 모양 | 독 · 출혈 · 레이저(착지 가로 레이저) · 폭탄 · 거대·무게 | §3 |
| P5 | 구슬 수 · 표적 | 물량 · 다시 발동 · 크리 · 처형·사냥 · 보물 | §3 |
| P6 | 생존·대가 · 계열 잇기 | 소환 · 수호 · 피의 대가 · 디버프 종류 보너스 · 듀오 유물 · 변환 · 복사 · 확률 두 배 · 비움 보상 | §3 · §4 |
| P7 | 심연 지역 | 네 번째 지역(적·판·보스, 사서·살덩이 옮김) → 4지역 × 7마디 | §5 · §5-1 |
| **P7b** | **방해 적** | §5-2 나의 후보에서 지역마다 2~3종(예고 아이콘 · 잡으면 보상 카드 +1 · 처형 전리품) · 이미 있는 판 방해를 네 원칙으로 점검 · 숲 엘리트 뒤부터 | §5-2 나 |
| P8 | 균형 | 숲 엘리트부터 적 체력(벽) · 무작위 봇 거의 0 · 계열 봇 · 한 구슬 봇 대부분 클리어 · 최상의 덱 보스 1~3발 · 단지 힘 나누기 실험을 켤지 | §6 |

P1b는 P2보다 먼저 한다 — 페그 수가 바뀌면 계열 수치(페그 밭 · 화상 · 얼음 등)를 다시 재야 하므로, 판을 먼저 굳힌다(2026-11-04 오너 「고르는 머리 쪽으로 · 세 가지 다 반영」). P7b는 계열 효과(P3~P6)가 있어야 「괴롭히는 계열 · 푸는 계열」을 잴 수 있어 그 뒤에, P8 앞에 둔다. P2가 P3~P6의 바탕이다(계열 개수·단계 갈고리). P3~P6은 서로 독립이라 순서를 바꿔도 된다. P7은 P1 뒤 언제든, P8은 맨 끝.

---

## P1. 런 구조

**Files:**
- Modify: `prototypes/ball-roguelite/index.html` — `FIGHTS`(약 420줄) 아래에 진형 마디 표, `startFight`(약 480줄)·`winFight`(약 2730줄)·`UI`(약 2737줄)·`rewardCards`(약 2666줄) 옆에 진형 보상, `botRun`(약 3195줄), 설정 → 시험용 버튼(약 3095줄 `restart`·`restartPickR`).
- Create: `prototypes/ball-roguelite/lab/route.js` — 런 구조 시험(Node, `lab/formation.js`와 같은 `check()` 형식).
- Modify: `prototypes/ball-roguelite/lab/foebot.js` — 조합 집계를 마디 기준으로.

### Task 1: 진형 마디 표와 마디 진행

**Interfaces:**
- Produces:
  - `ROUTE_R`: 배열, 마디 `{ region, name, kind: 'fight' | 'fork' | 'rest', ...fightFields }`. `kind === 'fight'`인 마디는 `FIGHTS` 항목을 펼친 것(`pick`·`pickR`·`elite`·`boss`·`region`)에 `name`·`hpMul`(없으면 1)을 덧씌운다.
  - `route()` → `S.foe === 'rank' ? ROUTE_R : FIGHTS`
  - `curNode()` → `route()[RUN.fight]`
  - `enterNode()` — 지금 마디에 따라 `startFight()` · `UI.fork(node)` · `UI.rest(node)`를 부른다.
- 기존 코드에서 `FIGHTS[RUN.fight]`·`FIGHTS.length`를 쓰는 곳(482 · 1468 · 2730~2732 · 2759 · 2769 · 3222 · 3234줄 근처)은 `curNode()`·`route().length`로 바꾼다. v1에서는 `route() === FIGHTS`라 결과가 같다.

- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`

```js
// 런 구조 시험 (node lab/route.js)
const { load } = require('./load');
const c = load('index.html', ['ROUTE_R', 'route', 'curNode']), a = c.api;
let fail = 0; const check = (name, ok, got) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${ok ? '' : ' — ' + got}`); if (!ok) fail++; };
a.S = { ...a.S_DEFAULT, foe: 'rank' };
const R = a.ROUTE_R, kinds = R.map(n => n.kind === 'fight' ? (n.boss ? 'boss' : n.elite ? 'elite' : 'fight') : n.kind);
check('진형 마디 21개', R.length === 21, R.length);
check('지역마다 일반 · 일반 · 갈림길 · 엘리트 · 일반 · 쉼터 · 보스', kinds.join(',') === Array(3).fill('fight,fight,fork,elite,fight,rest,boss').join(','), kinds.join(','));
check('지역 순서 숲 → 동굴 → 성', R.filter(n => n.boss).map(n => n.region).join() === 'forest,cave,castle', R.filter(n => n.boss).map(n => n.region).join());
check('다섯 번째 일반 전투는 체력 ×1.2', R.filter((n, i) => i % 7 === 4).every(n => n.hpMul === 1.2), R.map(n => n.hpMul));
a.S = { ...a.S_DEFAULT, foe: 'v1' };
check('이전 규칙은 FIGHTS 12개 그대로', a.route() === a.FIGHTS && a.FIGHTS.length === 12, a.route().length);
console.log(fail ? `실패 ${fail}` : '모두 통과'); process.exitCode = fail ? 1 : 0;
```

- [ ] **Step 2: 시험이 실패하는지 확인** — Run: `node lab/route.js` / Expected: `ROUTE_R`가 없어 `TypeError`(또는 FAIL).
- [ ] **Step 3: `ROUTE_R`·`route()`·`curNode()`·`enterNode()`를 `FIGHTS` 바로 아래에 만들고, 위 줄들을 바꾼다.** 지역 하나의 마디는 그 지역 `FIGHTS` 넷(1 · 2 · 3(엘리트) · 보스)에서: 일반1 = 1, 일반2 = 2, 갈림길 = 갈림길 마디(문을 고른 뒤 싸울 전투는 2를 펼친 것), 엘리트 = 3, 일반5 = 2를 펼치고 `hpMul: 1.2`, 쉼터, 보스. 이름은 `숲 1`~`숲 5`·`숲 갈림길`·`숲 쉼터`·`숲 엘리트`·`숲 보스`. `hpMul`은 `startFight`에서 적 체력 계산(483줄의 곱)에 곱한다. `winFight`에서 다음 전투를 `startFight()` 대신 `enterNode()`로.
- [ ] **Step 4: 시험 통과 확인** — Run: `node lab/route.js && node lab/formation.js` / Expected: 둘 다 `모두 통과`.
- [ ] **Step 5: 커밋** — `git add prototypes/ball-roguelite/index.html prototypes/ball-roguelite/lab/route.js && git commit -m "prototype(ball-roguelite): 런 구조 1 — 진형 마디 21(지역마다 일반 · 일반 · 갈림길 · 엘리트 · 일반 · 쉼터 · 보스)"`

### Task 2: 섞인 보상 · 엘리트 유물 · 보스 구슬 + 유물

**Interfaces:**
- Consumes: `curNode()`(Task 1)
- Produces:
  - `rewardCardsR(r, kind)` → 카드 배열(최대 3장). `kind`: `'mixed'`(구슬·강화·복제·유물 한 더미에서 무작위 3장, 겹치지 않게) · `'orb'`(구슬 쪽만 3장: 새 구슬 · 가진 구슬 강화 · 복제) · `'relic'`(유물만 3장, 선택의 두루마리면 4장) · `'up'`(가진 구슬 강화만, 레벨 끝이면 복제). 카드 모양은 지금 `rewardCards`와 같다(`{ t: 'orb' | 'up' | 'copy' | 'relic', … }`).
  - `UI.reward(cards, f, next)` — 세 번째 인자 `next`(없으면 `enterNode`)를 받는다. 카드가 0장이면 「건너뛰기」만.
  - 진형 `winFight`: 일반 → `rewardCardsR(r, RUN.door?.reward || 'mixed')`, 엘리트 → `'relic'`, 보스 → 합성(지금처럼) → `'orb'` 고르기 → `'relic'` 고르기. 마지막 보스는 보상 없이 `UI.end(true)`.
- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`에 덧붙인다.

```js
a.S = { ...a.S_DEFAULT, foe: 'rank' }; a.newRun(1, 0);
const firsts = new Set(); for (let s = 1; s <= 200; s++) { const cs = c.rewardCardsR(a.rng(s), 'mixed'); firsts.add(cs[0].t === 'relic' ? 'relic' : 'orb'); if (cs.length !== 3) { check('섞인 보상 3장', false, cs.length); break; } }
check('섞인 보상: 첫 카드가 구슬 쪽으로 고정되지 않음', firsts.has('relic') && firsts.has('orb'), [...firsts]);
check('엘리트 보상: 유물만 3장', c.rewardCardsR(a.rng(7), 'relic').every(x => x.t === 'relic'), c.rewardCardsR(a.rng(7), 'relic').map(x => x.t));
check('같은 시드 = 같은 카드', JSON.stringify(c.rewardCardsR(a.rng(9), 'mixed')) === JSON.stringify(c.rewardCardsR(a.rng(9), 'mixed')), '');
for (const k of Object.keys(a.RELICS)) a.RUN.relics.add(k);
check('유물을 다 가지면 유물 카드 0장(멈추지 않음)', c.rewardCardsR(a.rng(3), 'relic').length === 0, c.rewardCardsR(a.rng(3), 'relic').length);
// 보스: 구슬 고르기 → 유물 고르기 두 번 (UI를 가로채 순서를 적는다)
a.S = { ...a.S_DEFAULT, foe: 'rank' }; a.newRun(1, 0); a.RUN.fight = 6; const seen = [];
const UIo = { ...c.UI }; c.UI.synth = n => n(); c.UI.reward = (cs, f, next) => { seen.push(cs.every(x => x.t === 'relic') ? 'relic' : 'orb'); (next || (() => {}))(); };
c.enterNode = () => seen.push('next'); c.winFight(); Object.assign(c.UI, UIo);
check('보스: 구슬 하나 → 유물 하나 → 다음 마디', seen.join() === 'orb,relic,next', seen.join());
```

- [ ] **Step 2: 실패 확인** — Run: `node lab/route.js` / Expected: `rewardCardsR is not a function`.
- [ ] **Step 3: `rewardCardsR`를 `rewardCards` 바로 아래에, 진형 `winFight` 분기와 `UI.reward`의 `next` 인자를 넣는다.** 이전 규칙의 `rewardCards`·`winFight` 경로는 건드리지 않는다(`S.foe !== 'rank'`면 예전 그대로). `'mixed'` 더미: 구슬 쪽 후보(새 구슬 하나 · 가진 구슬 강화 · 복제 — 지금 `rewardCards`의 4칸 가방 규칙으로 만든 것) + 유물 후보 전부를 한 배열에 넣고 `shuffle(…, r)` 뒤 앞 3장. 보상 화면 문구의 「쉼터에서 체력을 모두 회복했다」는 진형에서 빼고(쉼터 마디가 따로 있음), 보스를 이긴 뒤 체력 전부 회복도 진형에서는 +8로 바꾼다.
- [ ] **Step 4: 통과 확인** — Run: `node lab/route.js && node lab/formation.js` / Expected: `모두 통과`.
- [ ] **Step 5: 커밋** — `git commit -am "prototype(ball-roguelite): 런 구조 2 — 섞인 보상 3장 · 엘리트 유물 · 보스 구슬 + 유물"`

### Task 3: 갈림길과 쉼터

**Interfaces:**
- Consumes: `enterNode()`·`curNode()`(Task 1), `rewardCardsR(r, kind)`(Task 2)
- Produces:
  - `forkDoors(r)` → 문 2~3개 `[{ reward: 'orb' | 'relic' | 'up' | 'elite' }]`. 늘 서로 다른 보상, `'elite'`는 30% 확률로 셋째 문.
  - `UI.fork(node)` — 문 카드(보상 종류 이름: 「구슬」·「유물」·「강화」·「엘리트 — 유물 2장 고르기」)를 보여 주고, 고르면 `RUN.door = door` 뒤 그 지역 「2」 전투(엘리트 문이면 그 지역 엘리트 전투를 펼친 것)로 `startFight()`. 전투를 이기면 `winFight`가 `RUN.door.reward`로 보상(엘리트 문은 `'relic'`을 두 번), 그 뒤 `RUN.door = null`.
  - `UI.rest(node)` — 셋 중 하나: 「회복」(최대 체력 30%) · 「구슬 강화」(가진 구슬 하나 Lv +1, `LV_MAX()`까지) · 「버리기」(구슬 칸 하나를 조약돌로, 또는 유물 하나 삭제). 고르면 `RUN.fight++` → `enterNode()`.
- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`에 덧붙인다: (1) `forkDoors`가 시드 1~100에서 늘 2~3개, 보상이 겹치지 않음. (2) 갈림길 마디(인덱스 2)에서 `UI.fork`를 가로채 `'relic'` 문을 고르면 그 전투 승리 뒤 보상이 유물만. (3) 쉼터 마디(인덱스 5)에서 회복을 고르면 체력이 `+round(maxHp × 0.3)`(최대 체력까지), 마디가 6(보스)으로. (4) 버리기: 조약돌이 아닌 칸 하나가 조약돌이 되고 가방은 4칸 그대로, 조약돌만 있으면 버리기 선택지가 없음. (5) `restart(2)`·`restart(5)`(진형)가 갈림길·쉼터 화면을 띄운다(`UI.fork`·`UI.rest` 호출 여부로 확인).
- [ ] **Step 2: 실패 확인** — Run: `node lab/route.js` / Expected: `forkDoors is not a function`.
- [ ] **Step 3: `forkDoors`·`UI.fork`·`UI.rest`를 만들고, 설정 → 시험용의 `restart(i)`가 진형에서는 `route()` 마디를 쓰고 `enterNode()`로 들어가게 한다.** 버튼 줄은 진형이면 `ROUTE_R` 이름으로(「숲 갈림길부터」 등). `restartPickR(i, j)`는 `FIGHTS[i]` 기준을 유지하되, 진형에서는 그 `FIGHTS` 항목과 같은 이름의 첫 전투 마디로 들어간다.
- [ ] **Step 4: 통과 확인** — Run: `node lab/route.js && node lab/formation.js` / Expected: `모두 통과`.
- [ ] **Step 5: 브라우저 확인** — `preview_start ball-prototype` → 설정 → 시험용 「숲 갈림길부터」 · 「숲 쉼터부터」 → 문 카드·쉼터 카드가 뜨고, 고른 뒤 다음 마디로 넘어가며 콘솔 오류 없음. 휴대폰 폭(375px)에서 카드가 화면 안.
- [ ] **Step 6: 커밋** — `git commit -am "prototype(ball-roguelite): 런 구조 3 — 갈림길(보상 종류가 보이는 문 · 엘리트 문) · 쉼터(회복 · 강화 · 버리기)"`

### Task 4: 봇 · 측정 도구 · 기록

**Interfaces:**
- Consumes: Task 1~3 전부
- Produces: `botRun`이 진형 마디 21개를 끝까지 돈다. `UI.fork`(봇): `mixed` = 무작위 문, `focus` = 주력 구슬이 있으면 `'up'` 문 아니면 `'orb'` 문. `UI.rest`(봇): 체력 50% 미만이면 회복, 아니면 구슬 강화. 보스 두 번 고르기는 `UI.reward`의 `next`를 부른다. `lab/foebot.js`의 `combos`는 `route()` 마디 이름으로 센다.
- [ ] **Step 1: 실패하는 시험 쓰기** — `lab/route.js`에 덧붙인다: `c.botRun(s, { opts: { foe: 'rank' }, pick: 'mixed' })`를 시드 1~3으로 돌려 예외 없이 끝나고, `r.pf.split(' ').length === 21`, 이긴 런이면 `r.reached === '성 보스'`.
- [ ] **Step 2: 실패 확인** — Run: `node lab/route.js` / Expected: 봇이 갈림길에서 멈춰 `maxShots`까지 돌거나 `pf` 길이가 12.
- [ ] **Step 3: `botRun`의 `UI.fork`·`UI.rest`·`UI.reward(…, next)`를 위 규칙으로 덮어쓰고, `pf`를 `route().map(() => 0)`으로. `lab/foebot.js` 조합 집계를 `a.route()`로.**
- [ ] **Step 4: 통과 · 회귀 확인**
  - Run: `node lab/route.js && node lab/formation.js` / Expected: `모두 통과`
  - Run: 이전 규칙 지문 — 스냅샷을 `_curN.html`로 링크하고 `FILE=_curN.html FOE=v1 PICK=mixed` 40런(scratchpad `batch.sh`) / Expected: `fp` = `fdf868b7bc18e2e04d7e176a25b21310e2286ac3`, 21승
  - Run: `selfTest()` 비교(이전 스냅샷 대 지금) / Expected: BAD 없음
  - Run: 진형 40런 무작위 · 몰기 / Expected: 숫자를 기록만(전투가 18개로 늘어 이기는 수가 바뀜 — 균형은 P8)
- [ ] **Step 5: 기록** — waypoint `15-ball-roguelite.md`에 §28(런 구조: 마디 표 · 보상 · 봇 숫자 · 한 런 발 수와 예상 시간), 체크리스트, STATUS. waypoint 커밋·푸시 → 앱 저장소 서브모듈 포인터 커밋.
- [ ] **Step 6: 커밋 · PR** — `git commit -am "prototype(ball-roguelite): 런 구조 4 — 봇이 갈림길 · 쉼터 · 보스 두 번 고르기를 돎 · 조합 집계를 마디로"` → 브랜치를 푸시하고 PR(본문에 트레일러·AI 서명 없음).

## P1b. 고르는 머리 바탕 (2026-11-04)

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §5-2 가(구슬 순서 고르기) · 다(페그 늘리기) · 라(단지 힘 나누기 실험), §7 11·13·14. 브랜치 `ball-roguelite/choose`(#17 위).

**측정한 출발점(2026-11-04, `makeBoard` 직접):** 장치 판 15장의 보이는 일반 페그 — 지금 크기 22~78(평균 약 55) · 작게 24~112 · 아주 작게 28~135. 작게는 판마다 고르지 않다(점 개수를 정해 찍는 `pts`·`castleRow`·`solo` 무늬는 늘지 않음) → 「작게」만으로는 목표 100~120에 못 미치는 판이 많아, **작게 + 빈자리 채우기**로 간다.

**Review Focus(P1b):**
- 구슬 가두기(적이 가방에서 구슬을 삼킴)로 고른 칸이 사라질 때 — 고른 것이 풀리고 남은 칸의 첫 구슬이 나가야 한다. 돌려받은 칸은 이번 바퀴에 아직 안 쓴 칸으로 돌아온다. (Task 1 시험)
- 가방이 조약돌뿐이거나 칸이 하나뿐일 때 — 바퀴가 늘 한 칸 이상이고 멈추지 않아야 한다. (Task 1 시험)
- 아끼는 구슬로 정한 구슬을 쉼터에서 버리거나 합성으로 바꾼 뒤 — 유물이 죽지 않고 가방에서 가장 많은 구슬로 저절로 옮겨 간다. (Task 2 시험)
- 성 행진 판 — 채운 페그도 행진 층을 따라 숨었다 나타나고, 보이는 수가 목표 안이어야 한다. (Task 3 시험)
- 이전 규칙(v1) — 새 설정 둘(페그 · 단지 힘)은 진형에서만 듣는다. 봇 지문 `fdf868b7…` 그대로. (Task 5)

### Task 1: 구슬 순서 고르기
**Files:** `index.html`(`currentOrb` 약 554줄 · 발 끝 `B.bagIdx++` 약 2402줄 · 마지막 한 방 약 2136줄 · 구슬 가두기 약 2543·2580줄 · HUD `#area` 약 3162줄) · 새 시험 `lab/choose.js`
**Interfaces (Produces):** `cycleLeft(): number[]`(이번 바퀴에 남은 칸 번호, 가방 순서) · `B.used: number[]`(이번 바퀴에 쓴 칸) · `B.sel: number|null`(고른 칸) · `pickOrb(slot)`(화면 버튼) · `chooseOn(): boolean`(= `S.foe === 'rank'`)
- [x] 시험: 진형에서 고르지 않으면 쏘는 순서가 지금과 같다(`B.bag` 순서, 한 바퀴 뒤 다시 처음) · `pickOrb`로 고른 칸이 나가고 그 칸은 이번 바퀴에 다시 안 나옴 · 다 쓰면 모든 칸이 돌아옴 · 같은 구슬 두 칸이면 한 바퀴에 두 번 · 마지막 한 방은 `cycleLeft().length === 1`일 때 · 가둔 칸을 골라 두었으면 고른 것이 풀림 · 이전 규칙은 `bagIdx` 그대로
- [x] 구현 → `node lab/choose.js && node lab/route.js && node lab/formation.js` 통과
- [x] 화면: 조준 중(`MODE === 'aim'`) 진형이면 `#area` 「다음 구슬」 자리에 남은 칸을 작은 버튼으로(고른 것 강조, 같은 구슬 여러 칸은 「×2」처럼 묶음). 고르면 `B.ver++`(조준선 다시 계산). 375px에서 판을 가리지 않는지 확인
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 1 — 구슬 순서 고르기(한 바퀴 안에서 남은 칸 중 고름)`

### Task 2: 「아끼는 구슬」 유물
**Files:** `index.html`(`RELICS` · `applyCard` · `pickCard` 흐름 약 2811줄 · `UI`) · `lab/choose.js`
**Interfaces:** Consumes `cycleLeft`. Produces `RELICS.favorite`(`rank: true`) · `RUN.fav`(구슬 `kindKey`) · `favSlot(): number|undefined` · `UI.favorite(next)`
- [x] 시험: 유물이 있으면 바퀴가 칸 수 + 1(아끼는 구슬의 첫 칸이 끝에 한 번 더) · 얻을 때 기본값은 가방에서 칸이 가장 많은 구슬(같으면 레벨 높은 것, 그다음 앞 칸) · 그 구슬이 가방에서 사라지면 같은 규칙으로 옮겨 감 · 조약돌만 있으면 더하지 않음 · 이전 규칙 보상 더미에 나오지 않음
- [x] 구현: 보상에서 고르면 「어느 구슬을 아낄까」 창(가방의 구슬 종류마다 버튼), 봇·설정의 유물 받기는 기본값
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 2 — 아끼는 구슬 유물`

### Task 3: 페그 늘리기
**Files:** `index.html`(`S_DEFAULT` · `SCALES` 쓰는 곳 515·523·528·2517·2587·3227줄 · `makeBoard` 끝 · 설정 화면) · 새 측정 `lab/pegs.js`
**Interfaces:** Produces `S.peg: 'dense' | 'now'`(기본 `dense`) · `scaleKey(): string`(진형 + dense면 `'small'`, 아니면 `S.scale`) · `DENSE_TARGET = 110` · `DENSE_HP[판 이름]`
- [x] 측정 도구 `lab/pegs.js`: 장치 판 15장 × (now · dense)의 보이는 일반 페그 수, 첫 발 평균 피해(당김 41 × 시드 6), 한 발 최장 시간
- [x] 시험: dense에서 판마다 보이는 일반 페그 95~125(성은 행진 위치 8곳 평균) · 채운 페그가 장치·관문 자리를 비움(`devBlock` 뒤에 셈) · 같은 시드 같은 판 · v1과 `S.peg: 'now'`는 지금과 같은 판
- [x] 구현: `makeBoard`에서 무늬를 다 찍은 뒤(dense일 때만) 엇갈린 격자 간격을 16에서 0.5씩 줄이며 「보이는 일반 페그 ≥ 110」이 되는 첫 간격으로 빈자리를 채움(좌우 대칭, 기존 페그와 7px 이상, 장치 자리 제외 — 행진 판은 층 높이로 나눠 층마다 같은 비율). 난수는 쓰지 않는다(뒤의 특수 페그 시드 흐름 유지)
- [x] 적 체력: `DENSE_HP[판] = dense 첫 발 평균 ÷ now 첫 발 평균`을 `SCALE_HP` 대신 곱함(판마다 「한 발 피해 대비 체력」 유지) · 한 발 시간이 장치 쉼(10초) 안인지
- [x] 설정 「페그 수」: 촘촘하게(진형 기본, 작은 페그 약 110개) / 이전
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 3 — 페그 늘리기(작은 페그 + 빈자리 채우기, 판마다 약 110)`

### Task 4: 단지 힘 나누기 실험 설정
**Files:** `index.html`(`multiply` 약 2210줄 · 설정) · `lab/choose.js`
**Interfaces:** Produces `S.share: 'copy' | 'half'`(기본 `copy`, 진형에서만 들음)
- [x] 시험: half면 단지·보라 열매·관문이 늘린 구슬의 힘이 원래 구슬 힘의 절반(반올림, 최소 1), 원래 구슬은 그대로 · copy와 v1은 지금과 같음
- [x] 구현 · 설정 「늘어난 구슬의 힘」: 그대로 복사(지금) / 절반(실험 — 한 구슬 덱 비교용)
- [x] 커밋 `prototype(ball-roguelite): 고르는 머리 4 — 단지 힘 나누기 실험 설정`

### Task 5: 확인 · 봇 · 기록
- [x] `node lab/choose.js && node lab/route.js && node lab/formation.js` · 이전 규칙 봇 지문 `fdf868b7…`(21승) · `selfTest()` 결정성
- [x] 진형 봇 40런(무작위 · 몰기): 페그 dense · now 각각, half 한 번 — 숫자는 기록만(균형은 P8). 한 런 발 수
- [x] 브라우저 375px: 구슬 버튼 · 아끼는 구슬 창 · 촘촘한 판 모양, 콘솔 오류 없음
- [x] 기록 `15-ball-roguelite.md` §30 · 체크리스트 · STATUS → waypoint 커밋·푸시 → 서브모듈 포인터 → 브랜치 푸시 · PR(#17 위)

## P2. 계열 틀 (2026-11-05)

**Goal:** 진형에서 아이템마다 계열이 붙고, 개수·단계(2/4/6)를 세며, 보상이 계열 고르게 뽑기 · 보상 끌림 · 열쇠 규칙을 따른다. 갈림길에 계열 문이, 봇에 계열 몰기가 생긴다. 계열 효과(단계마다 하는 일)는 P3~P6이 `famStage()`에 걸어 넣는다.

**Spec:** [`build-families-2026-11-03.md`](build-families-2026-11-03.md) §2(세는 방식 · 보상 끌림 · 계열 고르게 뽑기) · §3(계열마다 「열쇠」 줄) · §3-1(아이템 배치 — 오너 확정 2026-11-05 「46개 그대로」) · §5-1(갈림길 문) · §6(계열 봇) · §7 3·4·8·9. 브랜치 `ball-roguelite/families`(`ball-roguelite/choose` 위, PR 기준도 그 브랜치).

**범위:** 지금 있는 구슬 40 · 유물 76만 계열에 넣는다. 새 아이템 46은 P3~P6에서 각 계열 효과와 함께 넣는다. 그래서 P2가 끝나도 계열 크기는 §3-1 「있는 구슬 · 있는 유물」 열 그대로다(보물 1 · 출혈 2 …). 6단계에 닿는 계열은 아직 일부뿐이다.

**계획에서 정한 것(설계서가 비워 둔 자리 — 구현자 판단, §32에 적는다):**
1. **계열 키**(코드 안 이름, 화면은 한국어): `mech` 기계 · `fire` 화상 · `ice` 얼음 · `field` 페그 밭 · `poison` 독 · `bleed` 출혈 · `laser` 레이저 · `bomb` 폭탄 · `mass` 거대·무게 · `swarm` 물량 · `resound` 메아리 · `crit` 크리 · `hunt` 처형·사냥 · `loot` 보물 · `summon` 소환 · `guard` 수호 · `blood` 피의 대가. 공용은 `common`(아이템에 `fam`이 없음). `ORBS`·`RELICS` 키와 겹치지 않게 골랐다(`echo`·`heavy`·`weight`는 이미 구슬·유물 키).
2. **열쇠·보상:** 구슬은 모두 열쇠(§7 8). 유물은 §3 계열마다 「열쇠」 줄에 이름이 있는 것만 열쇠, 나머지는 보상. 두 계열에 걸친 유물은 한 계열에서라도 열쇠면 열쇠다(벌집: 소환 열쇠 → 독에서도 열쇠).
3. **선택의 두루마리는 임시 열쇠.** 보물에는 P5 전까지 다른 아이템이 없다. 보상으로 두면 진형에서 영영 나오지 않으므로, P5에서 행운의 금박이 들어올 때 보상으로 바꾼다.
4. **세기는 늘 지금 가진 것으로.** 쉼터 버리기 · 합성으로 열쇠가 빠지면 개수·단계가 내려가고, 그 계열의 보상 유물이 다시 막힌다. 이미 가진 보상 유물은 계속 듣는다. 융합 구슬(레시피 없는 합성)은 두 재료의 계열을 모두 받는다(같은 계열이면 1).
5. **고르게 뽑기는 새 구슬 카드와 유물 카드에만.** 가진 구슬의 강화 · 복제 카드는 지금 그대로 섞는다(계열을 고르는 카드가 아니라서).
6. **계열 문:** 갈림길 문 후보가 「구슬 · 유물 · 강화」에서 「구슬 · 유물 · 강화 · 계열」로 넷이 된다(그중 둘 + 30% 엘리트, 지금과 같음). 계열 문의 계열 = 가진 개수가 가장 많은 계열(같으면 `FAM` 순서) 중 보상에 나올 카드가 3장 이상인 것. 그런 계열이 없으면 「보상 카드 3장 이상」인 계열 가운데 무작위. 그것도 없으면 계열 문을 후보에서 뺀다. 빈 문은 생기지 않는다.
7. **계열 봇:** 몰 계열 = `fam` 인자(`FAM` 환경 변수) → 없으면 첫 보상에서 공용이 아닌 첫 카드의 첫 계열. 고르는 순서는 그 계열 구슬의 복제·강화 → 그 계열 새 구슬 → 그 계열 유물 → 아무 강화 → 공용 유물 → 첫 카드. 갈림길은 그 계열 문 → (주력 구슬이 있으면) 강화 문 → 구슬 문 → 첫 문.

**Review Focus(P2):**
- **이전 규칙(v1)이 쓰는 함수** — `relicCands` · `rewardCards` · `checkTrans` · `cardHtml`은 v1도 쓴다. 계열 거르기 · 고르게 뽑기를 여기 넣으면 v1 지문 `fdf868b7…`이 깨진다. 진형 경로(`rewardCardsR`)에만 넣고, v1 결과가 같은지 시험으로 고정한다. (Task 2 · 3 시험, Task 5 지문)
- **후보가 모자랄 때** — 유물을 거의 다 가졌거나 열쇠 없는 보상이 다 빠져서, 뽑을 수 있는 카드가 3장보다 적거나 0장이어도 뽑기가 멈추지 않고 있는 만큼만 낸다. (Task 2 시험)
- **열쇠를 잃을 때** — 쉼터에서 계열의 하나뿐인 구슬을 버리면 단계가 내려가고, 그 계열 보상 유물이 더미에서 빠지되 이미 가진 것은 남는다. (Task 1 · 2 시험)
- **갈림길 문을 부르는 두 곳**(`UI.fork` · 봇 `UI.fork`) — 같은 시드 · 같은 가방이면 같은 문(계열까지 같음). 계열 문 보상은 늘 3장. (Task 4 시험)
- **375px 화면** — 카드의 계열 표시(계열 둘 + 열쇠/보상)와 HUD 계열 줄이 판과 버튼을 가리지 않는다. (Task 3 브라우저 확인)

### Task 1: 계열 자료 · 세기 · 단계
**Files:** `index.html`(`ORBS` 143~187줄 · `RELICS` 235~328줄 · `TAGS` 옆 330줄 · `applyCard` · `doSynth` · `restPick`) · 새 시험 `lab/family.js`(`lab/choose.js`와 같은 `check()` 형식)
**Interfaces (Produces):**
- `FAM`: `{ mech: '기계', fire: '화상', …, blood: '피의 대가' }`(위 「정한 것 1」 순서 그대로 17개)
- 아이템 자료: 계열이 있는 `ORBS[k].fam: string[]` · `RELICS[k].fam: string[]` · 열쇠 유물 `RELICS[k].key: true`. `tags`는 그대로 둔다(v1과 구슬 능력 `orbRole`이 씀).
- `famsOf(o): string[]` — 구슬 객체(융합은 재료 합집합) · 유물 키 문자열 모두 받음. 공용이면 `[]`
- `famCount(f): number` — 가진 구슬 **종류**(`kindKey` 기준, 조약돌 제외) 중 f가 붙은 것 + 가진 유물 중 f가 붙은 것
- `famStage(f): 0 | 2 | 4 | 6` · `famKeyed(f): boolean`(f가 붙은 구슬이 가방에 있거나 f가 붙은 열쇠 유물이 있음) · `isPayoff(k): boolean`(유물이고 `key`가 없고 `fam`이 있음)
- `famCheck()`: 진형에서만, 단계가 오른 계열마다 `FX.texts`에 「{계열} {단계}단계」(봇이면 생략). `RUN.famSeen = { [f]: 최고 단계 }`로 오름만 알림. `applyCard` · `doSynth` 끝의 `checkTrans()` 옆에서 부른다.

**자료(§3-1 「있는」 열 + §3 「열쇠」 줄 — 이대로 넣는다):**
| 계열 | 구슬 | 열쇠 유물 | 보상 유물 |
|---|---|---|---|
| mech | bolt, storm | rubber, drill, drumstick, cement | wandergate, gatekey, wideframe, doubledoor, secretmap, gatebell, goggles |
| fire | ember, cauldron, volcano | — | tinder, brazier, firewick |
| ice | frost, storm | icebell | bindchain |
| field | seed, ghost, moss, bell, garden, redring | — | rain, rebirth, hourglass, dance, clover, crystalseed |
| poison | sting, brew, cauldron | sporepouch, hive | — |
| bleed | briar, rose | — | — |
| laser | prism, redring | — | hunter |
| bomb | sticky, hammer, volcano | arsenal, powder, fuse | — |
| mass | heavy, giant, twins | weight | lead, bedrock, pierce, glove |
| swarm | twin, egg, cricket, frogking, echo, twins | dandelion, starsplit | dew, arrow, swarmflag, voidmaw, revolving |
| resound | boomer, swirl, echo | — | memory |
| crit | dagger, rose | whet, gardener | gambler, marksman, midas, goldhinge |
| hunt | scythe, chainweight, rift | horn, crookhook | axe, vinewrap |
| loot | — | scroll(임시) | — |
| summon | hornet | flies, hive | — |
| guard | holywater, catclaw, yarn | halo, mantle, holyflask | shell, spring, catbell, herb |
| blood | — | laststand, crown | leash, ninecat, fist |

공용(`fam` 없음): 구슬 stone · bouncy · firefly, 유물 spyglass · starmap · favorite · pioneer · soy · mushroom · antidote · lantern · cateye · fullpod · podfield.

- [ ] 시험 `lab/family.js`:
  - 계열마다 붙은 아이템 수 = 위 표: `{ mech: 13, fire: 6, ice: 4, field: 12, poison: 5, bleed: 2, laser: 3, bomb: 6, mass: 8, swarm: 13, resound: 4, crit: 8, hunt: 7, loot: 1, summon: 3, guard: 10, blood: 5 }`
  - 공용이 위 목록과 정확히 같다(`fam` 없는 구슬 3 · 유물 11, 이름으로 비교) · `FAM` 키가 `ORBS`·`RELICS` 키와 겹치지 않는다 · `fam`의 값은 모두 `FAM`에 있다
  - 가방 `[bolt, bolt, stone, stone]` + 유물 rubber → `famCount('mech') === 2`(복제는 세지 않음), `famStage('mech') === 2`
  - 가방에 storm 하나 → mech · ice 둘 다 1 · 융합 구슬 `{ kind: 'fusion', parts: ['ember', 'sting'] }` → fire · poison 각 1, `{ parts: ['ember', 'volcano'] }` → fire 1
  - 4 · 6 경계: mech 아이템 3개 → 2단계, 4개 → 4단계, 5개 → 4단계, 6개 → 6단계
  - 계열의 하나뿐인 구슬을 `restPick('drop', i)`로 버리면 `famCount`가 1 줄고 `famKeyed`가 거짓이 된다(ember 하나 + brazier: 버리기 전 fire 2 · 열쇠 있음 → 뒤 1 · 열쇠 없음, brazier는 `RUN.relics`에 남음)
  - `famCheck`: 진형에서 mech를 1 → 2로 올리는 `applyCard` 뒤 `FX.texts`에 「기계 2단계」, 같은 단계로 다시 오르면(버렸다 다시 얻음) 알리지 않음, v1에서는 아무것도 안 함
- [ ] 실패 확인: `node lab/family.js` / Expected: `FAM is not defined`류로 실패
- [ ] 구현 → `node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js` 모두 통과
- [ ] 커밋 `prototype(ball-roguelite): 계열 틀 1 — 계열 17 자료 · 세기 · 단계(2/4/6)`

### Task 2: 보상 — 계열 고르게 뽑기 · 보상 끌림 · 열쇠 없는 보상 막기
**Files:** `index.html`(`relicCands` 옆 · `rewardCardsR` 2788줄) · `lab/family.js`
**Interfaces:**
- Consumes: `famsOf` · `famCount` · `famKeyed` · `isPayoff`
- Produces:
  - `FAM_PULL = [[4, 2.5], [2, 1.5]]` · `famPull(f): number`(`common`은 1)
  - `famWeights(cands: { fams: string[] }[]): number[]` — 아래 식
  - `famPick(cands, r, n): cand[]` — 무게대로 하나 뽑고 빼고 무게를 다시 계산하기를 n번(후보가 바닥나면 거기까지)
  - `relicCandsR(): string[]` = `relicCands()`에서 `isPayoff(k) && !famsOf(k).some(famKeyed)`인 것을 뺀 것(진형 전용, `relicCands`는 손대지 않음)
  - `rewardCardsR(r, kind, fam?)` — 새 구슬 카드는 `famPick(fresh, r, 3)`, 유물 카드는 `famPick(relicCandsR(), r, 4)`로 순서를 정한다. 그 밖(구슬 40% · 유물 60% 칸 고르기, 강화·복제 카드, `relic`·`orb`·`up` 종류)은 지금 그대로

무게 식(§2): 후보 i의 계열 목록 `F_i`(빈 배열이면 `['common']`), 계열 f에 걸친 지금 후보 수 `n_f`라 하면
`w_i = Σ_{f ∈ F_i} famPull(f) / (|F_i| × n_f)`

- [ ] 시험(`lab/family.js`에 덧붙임):
  - `famWeights` 고정값: 가진 것 없이 `[mech, mech, fire]` → `[0.5, 0.5, 1]` · `[fire, fire+poison]` → `[0.5, 0.75]` · 공용 하나 → `[1]` · mech 개수 2일 때 `[mech, mech, fire]` → `[0.75, 0.75, 1]` · 4일 때 `[1.25, 1.25, 1]`
  - 결정성: 같은 시드 `rng`로 `rewardCardsR` 두 번 → 같은 카드
  - 끌림 빈도: 가방 `[bolt, ember, stone, stone]` + 유물 rubber(mech 2 · fire 1, 둘 다 열쇠 있음)로 `rewardCardsR(rng(s), 'relic')`을 시드 1~5000 → **첫 카드만** 세어 (mech 유물 횟수) ÷ (fire 유물 횟수) = 1.5 ± 0.25(계열 무게 1.5 대 1, 표준오차 약 0.1)
  - 열쇠 없는 보상 막기: 가방이 조약돌뿐이면 `relicCandsR()`에 tinder·brazier·firewick(fire 보상)이 없다 · ember를 넣으면 셋 다 있다 · scroll은 아무것도 없어도 있다 · 진형에서 ember를 버리면 다시 빠진다
  - v1은 그대로: `S.foe = 'v1'`에서 `relicCands()`에 tinder가 있다(이 함수는 계열을 보지 않음)
  - 모자랄 때: 유물을 다 가진 런(`RUN.relics`에 `relicCandsR()` 전부)에서 `rewardCardsR(r, 'relic')`이 `[]`, `'mixed'`가 구슬 쪽만으로 3장 이하 · `famPick([], r, 3)`이 `[]`
- [ ] 실패 확인 → 구현 → `node lab/family.js && node lab/route.js && node lab/choose.js && node lab/formation.js` 통과(`route.js`가 특정 카드를 고정해 두었다면 기대값을 새 뽑기에 맞춰 고치고 커밋 메시지에 적는다)
- [ ] 커밋 `prototype(ball-roguelite): 계열 틀 2 — 보상을 계열 고르게 뽑기 · 끌림 1.5/2.5배 · 열쇠 없는 보상 막기`

### Task 3: 이전 태그 · 변신은 v1에만 + 화면에 계열
**Files:** `index.html`(`trans` · `checkTrans` 344~357줄 · `cardHtml` 2827줄 · 승리 화면 `tagLine` 2886줄 · 런 끝 2921줄 · HUD `#area`) · `lab/family.js`
**Interfaces:**
- Consumes: `FAM` · `famsOf` · `famCount` · `famStage` · `isPayoff`
- Produces: `famLine(max = 3): string` — 개수 1 이상인 계열을 많은 순(같으면 `FAM` 순)으로 `max`개, `기계 4·4단계 · 화상 1` 꼴(단계 0이면 개수만)
- 진형이면 `checkTrans()`가 아무것도 하지 않고 `trans(t)`가 늘 거짓. v1은 한 글자도 바꾸지 않는다. 변신이 진형에서 하던 일(`TRANS_R`)은 P3~P6에서 계열 단계로 옮긴다(§7 4). 구슬의 `tags`로 정하는 능력(칼날 처형 · 벌집의 벌레 구슬 등)은 그대로 둔다.

- [ ] 시험:
  - 진형: `tags`에 `'blade'`가 있는 구슬·유물 3개를 가진 뒤 `checkTrans()` → `RUN.trans`가 비어 있고 `trans('blade') === false` · v1에서 같은 일 → `trans('blade') === true`
  - `cardHtml`: 진형 유물 카드 tinder에 「화상 보상」, rubber에 「기계 열쇠」, storm 구슬 카드에 「기계·얼음」, 공용 카드에는 계열 글이 없고, 진형 카드에 `[칼날` 같은 태그 글이 없다. v1 카드는 지금과 같은 문자열(태그 글 있음)
  - `famLine()`: mech 4 · fire 1 · crit 2 → `'기계 4·4단계 · 크리 2·2단계 · 화상 1'`
- [ ] 구현: 진형이면 카드의 태그 글 자리에 계열(+ 유물이면 「열쇠」·「보상」), 승리 화면 「변신:」 줄 자리에 「계열: {famLine(17)}」, 런 끝 요약에 「계열:」 줄, HUD `#area`에 `famLine(3)`(진형 · 조준 중, P1b 구슬 버튼 위 한 줄)
- [ ] 통과: `node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js`
- [ ] 브라우저: `preview_start ball-prototype` → 진형 새 런 → 보상 카드 · 승리 화면 · HUD 계열 줄이 보이고, 375px에서 카드 글이 넘치지 않으며 HUD가 판을 가리지 않음, 콘솔 오류 없음
- [ ] 커밋 `prototype(ball-roguelite): 계열 틀 3 — 태그·변신은 이전 규칙에만 · 카드 · 승리 화면 · HUD에 계열 단계`

### Task 4: 갈림길 「계열 문」
**Files:** `index.html`(`forkDoors` 473줄 · `DOOR_NAME` 474줄 · `UI.fork` 2890줄 · `winFight` 2853~2856줄) · `lab/family.js`
**Interfaces:**
- Consumes: `famCount` · `famPick` · `relicCandsR` · `rewardCardsR`
- Produces:
  - `famDoorFam(r): string | null` — 「정한 것 6」 규칙. 「보상에 나올 카드」 = 그 계열이 붙은 새 구슬(가방에 없는 기본 구슬) + `relicCandsR()` 중 그 계열
  - `forkDoors(r)` → 문 객체 배열, 계열 문은 `{ reward: 'family', fam }`
  - `doorName(d): [string, string]` — 계열 문이면 `[FAM[d.fam], `${FAM[d.fam]} 카드 3장 중 하나`]`, 아니면 `DOOR_NAME[d.reward]`
  - `rewardCardsR(r, 'family', fam)` → 그 계열 후보에서 `famPick` 3장(새 구슬 + 유물을 한 후보 목록으로)
  - `winFight`가 `d?.fam`을 `rewardCardsR`에 넘긴다
- [ ] 시험:
  - 같은 시드 · 같은 가방이면 `forkDoors` 두 번이 같은 문(계열까지)
  - 가방에 bolt · rubber · drill(mech 3), ember(fire 1) → 계열 문이 나오면 그 계열은 `mech`
  - mech 아이템을 다 가져 mech 후보가 3장 미만이면 계열 문은 다른 계열(후보 3장 이상)
  - 모든 계열의 후보가 3장 미만인 런(가진 것을 크게 늘린 시험 상태)에서는 계열 문이 없고 문은 늘 2개 이상
  - `rewardCardsR(r, 'family', 'mech')` → 3장, 모두 `famsOf`에 `mech`가 있음
  - 시드 1~200에서 계열 문이 한 번 이상 나온다(문 후보 넷 중 둘)
- [ ] 구현 → `node lab/family.js && node lab/route.js` 통과(`route.js`가 문 종류를 `orb · relic · up · elite`로 고정해 두었다면 `family`를 더하고 커밋 메시지에 적는다)
- [ ] 브라우저: 시험용 「숲 갈림길부터」 → 계열 문 카드 글 · 고른 뒤 그 계열 보상 3장, 375px
- [ ] 커밋 `prototype(ball-roguelite): 계열 틀 4 — 갈림길 계열 문(가장 많이 가진 계열의 카드 3장)`

### Task 5: 계열 봇 · 측정 · 기록
**Files:** `index.html`(`botRun` 3348줄) · `lab/foebot.js` · `lab/family.js` · waypoint `15-ball-roguelite.md` · `STATUS.md`
**Interfaces:**
- Consumes: Task 1~4 전부
- Produces: `botRun(seed, { …, pick: 'family', fam: string | null })` — 「정한 것 7」 규칙, 결과에 `fam`(몬 계열) · `fams`(끝났을 때 `famCount` 1 이상인 계열, `mech:5,fire:1` 꼴) 추가. `lab/foebot.js`는 `PICK=family`와 `FAM=<계열 키>`를 받는다.
- [ ] 시험: `botRun(s, { opts: { foe: 'rank' }, pick: 'family', fam: 'mech' })` 시드 1~3 → 예외 없이 끝남 · `pf`가 21마디 · 결과 `fams`에서 mech가 가장 크다 · `fam` 없이 → `fam`이 `FAM` 키 하나로 정해짐
- [ ] 회귀:
  - `node lab/family.js && node lab/choose.js && node lab/route.js && node lab/formation.js` → `모두 통과`
  - v1 지문: 스냅샷을 `_curN.html`로 링크하고 `FILE=_curN.html FOE=v1 PICK=mixed` 40런(scratchpad `batch.sh`) → `fp` = `fdf868b7bc18e2e04d7e176a25b21310e2286ac3`, 21승
  - `selfTest()` 이전 스냅샷 대 지금 → BAD 없음(`same` · `angleDiffers`)
- [ ] 측정(기록만 — 균형은 P8): 진형 40런 × `PICK=mixed` · `focus` · `family`(계열 자동). 승수 · 진 곳 · 끝났을 때 가장 큰 계열의 단계 분포(0/2/4/6). 그리고 `PICK=family FAM=<17개 각각>` 4런씩 → 계열마다 닿은 최고 단계. 지금 아이템이 6개 미만인 계열(ice 4 · bleed 2 · laser 3 · resound 4 · loot 1 · summon 3 · poison 5 · blood 5)은 6단계에 못 닿는 것이 맞다(P3~P6에서 채움)
- [ ] 기록: `15-ball-roguelite.md` §32(계열 틀: 「정한 것」 1~7 · 자료 표 요약 · 고르게 뽑기 식 · 계열 문 · 봇 숫자 · 변신이 진형에서 빠져 생긴 차이), 체크리스트, STATUS → waypoint 커밋·푸시 → 앱 저장소 서브모듈 포인터
- [ ] 커밋 · PR: `git commit -am "prototype(ball-roguelite): 계열 틀 5 — 계열 봇(PICK=family · FAM) · 측정"` → `ball-roguelite/families` 푸시 → PR(기준 `ball-roguelite/choose`, 본문에 트레일러·AI 서명 없음). 병합 순서는 #16 → #17 → #18 → 이 PR

## 다음 계획
P2가 끝나면 P3(판을 바꾸는 계열: 기계 · 화상 · 얼음 · 페그 밭 + 새 아이템 8) 계획을 같은 형식으로 쓴다. P3부터는 계열마다 §3 단계 효과를 `famStage(f)`에 걸고, §3-1 표의 새 아이템을 그 덩어리에서 넣는다. 적 체력은 P3 뒤에 「무작위 덱 4~6발 · 계열 덱 2~3발」을 기준으로 맞춘다(§31).
